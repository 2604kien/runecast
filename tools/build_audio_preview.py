"""RC-018 review-only mixes and HTML player, from actual WAVs and Godot traces.

Run after audio_audition_trace.gd and the active audio renderer. Python 3 + NumPy.
Nothing here subscribes to gameplay or changes production timing/semantics.
"""
from __future__ import annotations

import hashlib
import html
import json
from pathlib import Path
import wave

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "output/audio/rc-018"
RATE = 48000
CROSSFADE = 0.010


def read_json(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def dump(path, value):
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def read_wav(path):
    with wave.open(str(path), "rb") as source:
        assert (source.getframerate(), source.getsampwidth(), source.getnchannels()) == (RATE, 2, 1), path
        return np.frombuffer(source.readframes(source.getnframes()), dtype="<i2").astype(np.float64) / 32768.0


def write_wav(path, samples):
    peak = float(np.max(np.abs(samples), initial=0))
    assert peak < 10 ** (-3 / 20), (path, "Preview exceeds -3 dBFS; investigate gains without normalizing", peak)
    with wave.open(str(path), "wb") as target:
        target.setnchannels(1)
        target.setsampwidth(2)
        target.setframerate(RATE)
        target.writeframes(np.clip(np.rint(samples * 32768), -32768, 32767).astype("<i2").tobytes())
    return {"duration_seconds": len(samples) / RATE, "sample_count": len(samples), "sample_peak_dbfs": float(20 * np.log10(max(peak, 1e-12)))}


def schedule(trace, cues, contact_fraction):
    reduced = trace["mode"] == "reduced"
    result = []
    gain_played = False
    cleanup_played = False
    addition_played = False
    technique = trace["command"] == "technique"

    def add(cue_id, step, moment, priority, reason, gain=None, decorative=False, target=None):
        when = step["start_seconds"]
        if moment == "contact":
            when += step["duration_seconds"] * contact_fraction
        elif moment == "consequence_commit":
            when = step["end_seconds"]
        result.append({"cue_id": cue_id, "start_seconds": when, "gain_db": cues[cue_id]["intended_gain_db"] if gain is None else gain,
                       "priority": priority, "event_sequence": step["event"]["sequence"], "event_type": step["event"]["type"],
                       "moment": moment, "reason": reason, "decorative": decorative,
                       "target": target or step["event"].get("target", "action")})

    for step in trace["steps"]:
        event = step["event"]
        kind = event["type"]
        if kind == "cast":
            add("cast", step, "phase_start", 70, "One accepted Cast; no per-slot or per-branch cues")
        elif kind == "damage" and event["applied"] > 0:
            add("damage", step, "phase_start", 80, "Actual positive enemy HP loss", target="enemy")
            if reduced and trace["command"] == "cast":
                result[-1]["grouping_suppressed"] = "Reduced Cast shares one action-start cue; separate enemy-damage restart omitted while visual outcome remains"
        elif kind == "shield" and event["amount"] > 0:
            if reduced and trace["command"] == "cast":
                add("shield", step, "phase_start", 75, "Positive gain", gain=-6, target="player")
                result[-1]["grouping_suppressed"] = "Reduced Cast shares action cue; actual blocking is reserved for retaliation contact"
            else:
                add("shield", step, "phase_start", 75, "Quiet positive gain; later duplicate block suppressed", gain=-6, target="player")
                gain_played = True
        elif kind == "retaliation":
            if reduced:
                if event["applied"] > 0:
                    add("damage", step, "contact", 80, "Reduced contact: HP-loss meaning takes priority; actor/block duplicates omitted", gain=-5, target="player")
                elif event["blocked"] > 0:
                    add("shield", step, "contact", 75, "Reduced contact: actual block replaces separate gain/actor layers", gain=-4, target="player")
                else:
                    add("spectral", step, "contact", 70, "Reduced contact: single Shadeling actor cue")
            else:
                add("spectral", step, "contact", 70, "Only Shadeling variant; contact at normalized 0.28")
                if event["applied"] > 0:
                    add("damage", step, "contact", 80, "Quieter positive player HP-loss accent", gain=-5, target="player")
                elif event["blocked"] > 0 and not gain_played:
                    add("shield", step, "contact", 75, "Actual block without earlier gain cue", gain=-4, target="player")
        elif kind in ("card_drawn", "card_created") and not addition_played:
            add("technique_conjure" if kind == "card_created" else "technique_draw", step, "phase_start", 60 if technique else 30,
                "First actual supplied arrival; remaining individual 0.40s arrivals silent; played technique itself silent",
                decorative=not technique)
            addition_played = True
        elif kind in ("effect_consumed", "temporary_expired", "board_piece_cleared", "turn_cleanup") and not cleanup_played:
            if kind != "turn_cleanup" or event["discarded"] or event["expired"]:
                add("temporary_expired", step, "phase_start", 20, "One grouped cleanup accent; all later cells/hand items silent", decorative=True)
                cleanup_played = True
        elif kind == "battle_ended":
            add(event["state"], step, "consequence_commit", 100, "Result after terminal visual and staged commit; no reward or next turn inferred")
    return sorted(result, key=lambda entry: entry["start_seconds"])


def render_sequence(trace, cues, audio, contact_fraction):
    candidates = schedule(trace, cues, contact_fraction)
    active = None
    accepted = []
    suppressed = []
    for candidate in candidates:
        start = candidate["start_seconds"]
        if "grouping_suppressed" in candidate:
            suppressed.append({**candidate, "suppression": candidate["grouping_suppressed"]})
            continue
        candidate["natural_end_seconds"] = start + len(audio[candidate["cue_id"]]) / RATE
        candidate["end_seconds"] = candidate["natural_end_seconds"]
        if trace["mode"] == "reduced":
            if active is not None and active["end_seconds"] > start:
                if candidate["decorative"] and active["priority"] > candidate["priority"]:
                    suppressed.append({**candidate, "suppression": "Higher-priority foreground still active; discard, never queue late"})
                    continue
                active["end_seconds"] = min(active["natural_end_seconds"], start + CROSSFADE)
                active["fade_out_start_seconds"] = start
                candidate["replacement_fade_in_seconds"] = CROSSFADE
            active = candidate
        accepted.append(candidate)
    end = max([trace["duration_seconds"]] + [sound["end_seconds"] for sound in accepted]) + 0.25
    mixed = np.zeros(int(np.ceil(end * RATE)))
    for sound in accepted:
        start = round(sound["start_seconds"] * RATE)
        count = max(0, round(sound["end_seconds"] * RATE) - start)
        samples = audio[sound["cue_id"]][:count].copy() * 10 ** (sound["gain_db"] / 20)
        if "fade_out_start_seconds" in sound:
            fade_at = max(0, round((sound["fade_out_start_seconds"] - sound["start_seconds"]) * RATE))
            samples[fade_at:] *= np.linspace(1, 0, len(samples) - fade_at)
        fade_in = min(len(samples), round(sound.get("replacement_fade_in_seconds", 0) * RATE))
        if fade_in:
            samples[:fade_in] *= np.linspace(0, 1, fade_in)
        mixed[start:start + len(samples)] += samples
    return mixed, accepted, suppressed


def sequential(ids, cues, audio, gap=0.45):
    length = 0.35 + sum(len(audio[cue_id]) / RATE + gap for cue_id in ids)
    samples = np.zeros(round(length * RATE))
    seconds = 0.35
    entries = []
    for cue_id in ids:
        cue = cues[cue_id]
        data = audio[cue_id] * 10 ** (cue["intended_gain_db"] / 20)
        start = round(seconds * RATE)
        samples[start:start + len(data)] += data
        entries.append({"cue_id": cue_id, "start_seconds": start / RATE, "end_seconds": (start + len(data)) / RATE,
                        "gain_db": cue["intended_gain_db"], "future_only": cue["future_only"]})
        seconds += len(data) / RATE + gap
    return samples, entries


def timecode(seconds):
    return f"{int(seconds // 60):02}:{seconds % 60:06.3f}"


def review_metadata(settings, cues, catalogue):
    revision = settings.get("revision", "unrecorded revision")
    generated = str(revision).startswith("r003") or "runway" in str(settings.get("source_type", "")).lower()
    source_note = (
        "Runway-generated sources edited into runtime WAVs. Original sources are MP3; WAV encoding and 24-bit working files do not restore lost source fidelity. The five-cue direction was approved; the complete library and final balance await owner listening."
        if generated else
        "Procedural sources rendered into runtime WAVs. See the source settings and provenance for the active revision."
    )
    evidence_path = OUT / "godot-playback.json"
    evidence = read_json(evidence_path) if evidence_path.exists() else {}
    recorded = {cue["cue_id"]: cue for cue in evidence.get("cues", [])}
    evidence_current = bool(evidence.get("passed")) and set(recorded) == set(cues) and all(
        recorded[key].get("runtime_sha256") == cue["runtime_sha256"] for key, cue in cues.items()
    ) and (OUT / "godot-mix-capture.wav").exists()
    return {
        "revision": revision,
        "source_type": settings.get("source_type", "See provenance"),
        "source_settings_url": "../../../" + catalogue["source_settings"].removeprefix("res://"),
        "source_renderer_url": "../../../" + catalogue.get("source_renderer", "source-assets/audio/sfx/generate_sfx.py").removeprefix("res://"),
        "source_note": source_note,
        "generation_record_url": "../../../source-assets/audio/sfx/revisions/r003-runway-library/generation.json" if generated else None,
        "review_status": "Automated sample/mix checks only. Full-library owner listening and final perceived balance remain pending; no assistant headphone/speaker review is claimed.",
        "godot_playback_current": evidence_current,
        "godot_status": (
            "Godot import/playback evidence matches all 21 current runtime file hashes. Internal mixer capture does not establish headphone/speaker acceptance."
            if evidence_current else
            "Godot playback evidence has not yet been refreshed for these runtime files. Earlier captures are not evidence for the current revision."
        ),
    }


def render_html(payload):
    data = json.dumps(payload, ensure_ascii=False).replace("</", "<\\/")
    replacements = {
        "__DATA__": data,
        "__REVISION__": html.escape(str(payload["revision"])),
        "__SOURCE_NOTE__": html.escape(payload["source_note"]),
        "__REVIEW_STATUS__": html.escape(payload["review_status"]),
        "__GODOT_STATUS__": html.escape(payload["godot_status"]),
        "__SOURCE_SETTINGS_URL__": html.escape(payload["source_settings_url"], quote=True),
        "__SOURCE_RENDERER_URL__": html.escape(payload["source_renderer_url"], quote=True),
        "__GENERATION_LINK__": (
            '<a href="' + payload["generation_record_url"] + '">Generation record and prompts</a> · '
            if payload["generation_record_url"] else ""
        ),
        "__GODOT_LINK__": '<a href="godot-playback.json">Current Godot playback evidence</a> · ' if payload["godot_playback_current"] else "",
        "__GODOT_CAPTURE_LINK__": ' · <a href="godot-mix-capture.wav">Current Godot mixer capture</a>' if payload["godot_playback_current"] else "",
    }
    document = HTML
    for key, value in replacements.items():
        document = document.replace(key, value)
    return document


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    catalogue = read_json(ROOT / "docs/audio-cue-catalogue.json")
    settings = read_json(ROOT / catalogue["source_settings"].removeprefix("res://"))
    traces = read_json(OUT / "presentation-traces.json")
    assert traces["passed"] and len(traces["scenarios"]) == 16
    assert abs(traces["attack_contact_fraction"] - 0.28) < 1e-6
    cues = {cue["cue_id"]: cue for cue in settings["cues"]}
    assert len(cues) == 21
    audio = {key: read_wav(ROOT / cue["runtime_path"].removeprefix("res://")) for key, cue in cues.items()}
    for key, cue in cues.items():
        cue["runtime_sha256"] = hashlib.sha256((ROOT / cue["runtime_path"].removeprefix("res://")).read_bytes()).hexdigest()
        cue["url"] = "../../../" + cue["runtime_path"].removeprefix("res://")
        cue["duration_seconds"] = len(audio[key]) / RATE
    sequences = []
    for trace in traces["scenarios"]:
        mixed, sounds, suppressed = render_sequence(trace, cues, audio, traces["attack_contact_fraction"])
        name = f"sequence-{trace['id']}-{trace['mode']}.wav"
        stats = write_wav(OUT / name, mixed)
        sequences.append({"id": trace["id"], "mode": trace["mode"], "url": name, **stats,
                          "presentation_duration_seconds": trace["duration_seconds"], "fixture_note": trace["fixture_note"],
                          "sounds": sounds, "suppressed": suppressed,
                          "events": [{"type": step["event"]["type"], "sequence": step["event"]["sequence"],
                                      "uid": step["event"].get("card", {}).get("uid"),
                                      "applied": step["event"].get("applied"), "blocked": step["event"].get("blocked"),
                                      "start_seconds": step["start_seconds"], "end_seconds": step["end_seconds"]} for step in trace["steps"]]})
    reel, reel_index = sequential(list(cues), cues, audio)
    reel_stats = write_wav(OUT / "listening-reel.wav", reel)
    dump(OUT / "listening-reel-index.json", {"url": "listening-reel.wav", **reel_stats, "cues": reel_index})
    groups = {
        "Quiet UI and stone editing": ["ui_confirm", "ui_back", "edit_place", "edit_orient", "edit_restore", "action_rejected"],
        "Magic and protection": ["technique_draw", "technique_conjure", "cast", "damage", "shield", "temporary_expired"],
        "One actor variant at a time — four future actors": ["spectral", "flame", "stone", "chain", "bell"],
        "Results and future transactions": ["victory", "defeat", "reward", "guardian_phase_changed"],
        "Repeated editing and draw comfort check": ["edit_place", "edit_orient", "edit_restore", "technique_draw"] * 3,
    }
    comparisons = []
    for index, (title, ids) in enumerate(groups.items()):
        samples, entries = sequential(ids, cues, audio, gap=0.35)
        name = f"comparison-{index + 1}.wav"
        comparisons.append({"title": title, "url": name, "cues": entries, **write_wav(OUT / name, samples)})
    payload = {"schema_version": 1, **review_metadata(settings, cues, catalogue), "cues": list(cues.values()), "sequences": sequences, "comparisons": comparisons,
               "reel": {"url": "listening-reel.wav", "cues": reel_index, **reel_stats},
               "reduced_policy": "One foreground voice, 10ms replacement crossfade; reduced Cast shares cast start and omits separate enemy-damage/shield-gain restarts, then contact uses damage OR shield OR actor (at most two mandatory starts plus actual result); Pass has contact only plus result; standalone technique first actual arrival mandatory. Lower-priority cleanup/ordinary-draw decoration dropped while foreground active, never queued late. No global muting for reduced motion.",
               "production_audio_integrated": False}
    dump(OUT / "preview-index.json", payload)
    lines = [f"# RC-018 listening reel — {payload['revision']}", "", payload["source_note"], "", "Current runtime WAVs at intended gain; 0.45s quiet gap. No additional preview normalization. Future cues are explicitly pending gameplay systems.", "", payload["review_status"], "", "| Start | End | Cue | Gain | Status |", "| --- | --- | --- | --- | --- |"]
    for entry in reel_index:
        lines.append(f"| {timecode(entry['start_seconds'])} | {timecode(entry['end_seconds'])} | {entry['cue_id']} | {entry['gain_db']:+g} dB | {'Future only' if entry['future_only'] else 'Current contract; RC-020 playback pending'} |")
    (OUT / "listening-reel-index.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    (OUT / "index.html").write_text(render_html(payload), encoding="utf-8")
    print(f"RC018 preview: {len(cues)} cues, {len(sequences)} actual-trace mixes, {len(comparisons)} comparisons; reel {reel_stats['duration_seconds']:.2f}s")


HTML = r'''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Rune Cast · RC-018 sound library</title><style>
:root{color-scheme:dark}*{box-sizing:border-box}body{margin:0;background:#101823;color:#e4e8ef;font:16px/1.5 system-ui,sans-serif}main{max-width:1180px;margin:auto;padding:32px 24px 80px}h1{font-size:40px;line-height:1.1;margin:12px 0}h2{margin-top:36px;color:#b8dfdb}p{max-width:940px;color:#b6c2d2}a{color:#96e4d5}button{font:inherit;border:1px solid #53706b;border-radius:8px;background:#173e3d;color:#e8fffa;padding:9px 14px;cursor:pointer}button:hover{background:#235651}button:focus-visible{outline:3px solid #ffcd83}small,.small{font-size:13px;color:#adc0d0}.bar{position:sticky;top:0;background:#101823f5;padding:14px 0;display:flex;gap:14px;align-items:center;flex-wrap:wrap;border-bottom:1px solid #354457;z-index:4}.tag{color:#e8bd81;font-size:12px;letter-spacing:.05em}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:12px}.card{background:#192534;border:1px solid #354558;border-radius:12px;padding:16px}.card p{font-size:14px}.card button{width:100%;margin-top:6px}table{border-collapse:collapse;width:100%;font-size:14px;margin-top:12px}td,th{text-align:left;padding:7px;border-bottom:1px solid #344154}details{margin:12px 0}summary{cursor:pointer;color:#bde6dc}audio{width:100%;max-width:560px}.active{color:#99f2d9;font-weight:600}.trace{max-height:310px;overflow:auto}.note{border-left:3px solid #bc965e;padding-left:14px}.eyebrow{letter-spacing:.15em;color:#9bcbbf;font-size:13px}.sequence{margin-bottom:14px}</style>
<main><div class="eyebrow">RUNE CAST / SOUND LIBRARY / RC-018 / __REVISION__</div><h1>Material, motion & magic</h1><p>21 sound effects in 16 manifest families. Individual buttons read the current runtime WAVs at intended relative gain. Sequences follow actual production controller events and the RC-017 presentation clock. This player is a separate review artifact.</p>
<div class="bar"><button id="stop">Stop playback</button><label>Review volume <input id="volume" type="range" min="0" max="1" value="0.5" step="0.01"></label><span id="status" role="status">Choose a cue or sequence</span></div>
<p class="note">__SOURCE_NOTE__</p><p class="small">__REVIEW_STATUS__ Future-only files await their gameplay systems.</p><p class="small">__GODOT_STATUS__</p>
<p><a href="../../../docs/audio-cue-catalogue.json">Cue catalogue</a> · <a href="__SOURCE_SETTINGS_URL__">Active source settings</a> · <a href="__SOURCE_RENDERER_URL__">Editable audio renderer</a> · <a href="../../../source-assets/audio/sfx/provenance.json">Source provenance</a> · __GENERATION_LINK__<a href="presentation-traces.json">Presentation traces</a> · __GODOT_LINK__<a href="r002/index.html">Approved five-cue direction vs archived r001</a></p>
<h2>Individual cues</h2><div id="cues" class="grid"></div>
<h2>Comparisons at intended gain</h2><p>No additional preview normalization is applied. The five enemy sounds play separately. Only spectral belongs to the current Shadeling.</p><div id="comparisons" class="grid"></div>
<h2>Normal and reduced motion</h2><p>Cast 0.90s; hit and retaliation 1.50s each; technique 1.00s; each actual arrival 0.40s; cleanup 0.18s per actual slot/hand item. Reduced motion caps each individual timed effect at 0.06s. Sound durations are independent of full visual phase duration.</p><p class="note">Reduced examples use one foreground voice with a 10ms replacement crossfade. Cast shares its action-start sound and omits separate enemy-damage/shield-gain restarts; visuals still show those outcomes. Retaliation contact uses positive HP loss, else actual block, else the actor cue. Thus Cast has at most two mandatory starts, Pass one, plus an actual result. Lower-priority cleanup/ordinary-draw decorations may be dropped while foreground audio is active; they are never queued late. Actual technique arrivals and results remain audible. A sound is not added for each card or cleared cell.</p><div id="sequences"></div>
<h2>Indexed listening reel</h2><p>All 21 cues, intended gains, 0.45s gaps. Click any timecode to jump to that cue. <a href="listening-reel.wav">WAV</a> · <a href="listening-reel-index.md">Printable index</a>__GODOT_CAPTURE_LINK__</p><div id="reel"></div>
<h2>Timing and scope</h2><p>Attack contact begins at normalized progress 0.28: 0.42s into the 1.50s normal phase, 0.0168s into the reduced phase. Zero applied damage produces no injury sound. Pass has no Cast, enemy damage or player gain cue. Lethal victory has no retaliation. Technique animation is silent; the first actual supplied arrival receives one shared draw/conjure cue. Result cues start after the terminal phase commits.</p><p><code>event_presented</code> fires after visual completion and staged consequence commit. It is not a phase-start/contact hook. RC-020 must add generation-safe presentation-clock hooks, cancellation, bus/voice management and accepted UI bindings. These offline examples use nominal presentation seconds; frame hitches can extend real wall time. The main scene and its existing tone remain unchanged.</p></main>
<script>
const D=__DATA__; let audio=new Audio(),base=1, selected=null; const $=id=>document.getElementById(id);const esc=x=>String(x).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c])); const t=x=>`${Math.floor(x/60).toString().padStart(2,'0')}:${(x%60).toFixed(3).padStart(6,'0')}`;
function play(url,label,gain=0,from=0){audio.pause();audio.src=url;base=Math.pow(10,gain/20);audio.volume=base*Number($('volume').value);audio.currentTime=from;audio.play().catch(e=>$('status').textContent='Playback unavailable: '+e.message);$('status').textContent=label;selected=url;}
$('stop').onclick=()=>{audio.pause();audio.currentTime=0;$('status').textContent='Stopped';};$('volume').oninput=()=>audio.volume=base*Number($('volume').value);audio.onended=()=>$('status').textContent='Playback complete';
for(const c of D.cues){let e=document.createElement('div');e.className='card';e.innerHTML=`<div class="tag">${c.future_only?'FUTURE ONLY':'CURRENT CONTRACT · RC-020 PENDING'}</div><strong>${esc(c.cue_id)}</strong><p>${esc(c.description)}</p><small>${esc(c.manifest_id)} · ${c.duration_seconds.toFixed(2)}s · ${c.intended_gain_db} dB</small><button>Play ${esc(c.cue_id)}</button><details><summary>Runtime file</summary><small>${esc(c.runtime_path)}<br>SHA-256 ${c.runtime_sha256}</small></details>`;e.querySelector('button').onclick=()=>play(c.url,c.cue_id,c.intended_gain_db);$('cues').append(e);}
for(const c of D.comparisons){let e=document.createElement('div');e.className='card';e.innerHTML=`<strong>${esc(c.title)}</strong><p>${c.cues.map(x=>esc(x.cue_id)+(x.future_only?' [future]':'')).join(' · ')}</p><button>Play comparison</button>`;e.querySelector('button').onclick=()=>play(c.url,c.title);$('comparisons').append(e);}
for(const id of [...new Set(D.sequences.map(s=>s.id))]){let box=document.createElement('div');box.className='card sequence';box.innerHTML=`<strong>${esc(id.toUpperCase())}</strong><div class="grid"></div>`;for(const s of D.sequences.filter(s=>s.id===id)){let e=document.createElement('div');e.innerHTML=`<button>Play ${s.mode} · ${s.presentation_duration_seconds.toFixed(2)}s presentation</button><details><summary>Events and sounds · ${s.sounds.length} cues${s.suppressed.length?', '+s.suppressed.length+' decorations suppressed':''}</summary><p>${esc(s.fixture_note)}</p><div class="trace"><table><thead><tr><th>Time</th><th>Actual event</th><th>Cue</th></tr></thead><tbody>${s.events.map(x=>`<tr><td>${x.start_seconds.toFixed(3)}–${x.end_seconds.toFixed(3)}</td><td>${esc(x.type)}${x.uid!==null?' UID '+x.uid:''}${x.applied!==null?' applied '+x.applied:''}</td><td>${s.sounds.filter(c=>c.event_sequence===x.sequence).map(c=>`${esc(c.cue_id)} @ ${c.start_seconds.toFixed(3)} (${c.gain_db} dB, ${esc(c.moment)})`).join('<br>')||'silent'}</td></tr>`).join('')}</tbody></table></div></details>`;e.querySelector('button').onclick=()=>play(s.url,`${s.id} / ${s.mode}`);box.querySelector('.grid').append(e);}$('sequences').append(box);}
let reel=document.createElement('table');reel.innerHTML='<thead><tr><th>Start</th><th>Cue</th><th>Gain</th><th>Status</th></tr></thead><tbody>'+D.reel.cues.map(c=>`<tr><td><button data-time="${c.start_seconds}">${t(c.start_seconds)}</button></td><td>${esc(c.cue_id)}</td><td>${c.gain_db} dB</td><td>${c.future_only?'Future only':'Current contract'}</td></tr>`).join('')+'</tbody>';$('reel').append(reel);for(const b of reel.querySelectorAll('button'))b.onclick=()=>play(D.reel.url,'Indexed cue reel',0,Number(b.dataset.time));
</script></html>'''


if __name__ == "__main__":
    main()
