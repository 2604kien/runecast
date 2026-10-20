"""Package recorded RC-020 engine output; no substitute audio is synthesized."""
from __future__ import annotations

import hashlib
import html
import json
from pathlib import Path
import wave

import numpy as np
from PIL import Image, ImageDraw, ImageOps

from validate_audio_library import db, true_peak

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / "output/qa/rc-020/demo"


def main() -> None:
    report = json.loads((DEST / "results.json").read_text(encoding="utf-8"))
    audio_path = DEST / "playable-mix.wav"
    with wave.open(str(audio_path), "rb") as reader:
        rate = reader.getframerate()
        channels = reader.getnchannels()
        data = np.frombuffer(reader.readframes(reader.getnframes()), dtype="<i2").reshape(-1, channels) / 32768.0
    metering = {
        "sample_rate": rate, "channels": channels, "seconds": len(data) / rate,
        "sample_peak_dbfs": db(np.abs(data).max()),
        "estimated_true_peak_dbtp": db(max(true_peak(data[:, channel]) for channel in range(channels))),
        "rms_dbfs": db(np.sqrt(np.mean(data * data))),
        "nonfinite_samples": int((~np.isfinite(data)).sum()),
        "clipped_samples": int((np.abs(data) >= 1.0).sum()),
        "true_peak_method": "Independent 8x / 96-tap Kaiser sinc estimate using the retained RC-018 meter, separately per channel. Not a certified meter or listening review.",
        "sha256": hashlib.sha256(audio_path.read_bytes()).hexdigest(),
    }
    (DEST / "mix-measurements.json").write_text(json.dumps(metering, indent=2) + "\n", encoding="utf-8")
    frames = report["frames"]
    selected = []
    for sequence in report["sequences"]:
        if "start_seconds" not in sequence:
            continue
        when = (sequence["start_seconds"] + sequence["end_seconds"]) / 2
        selected.append(min(frames, key=lambda item: abs(item["seconds"] - when)))
    sheet = Image.new("RGB", (250 * 5, 590 * 2), "#111725")
    draw = ImageDraw.Draw(sheet)
    for index, frame in enumerate(selected[:10]):
        x, y = index % 5 * 250, index // 5 * 590
        with Image.open(DEST / frame["image"]) as source:
            preview = ImageOps.contain(source.convert("RGB"), (244, 548))
            sheet.paste(preview, (x + (250 - preview.width) // 2, y + 36))
        label = frame["label"].replace("—", "/")
        draw.text((x + 6, y + 10), label, fill="#efdfb0")
    sheet.save(DEST / "contact.png", optimize=True)
    controls = []
    for sequence in report["sequences"]:
        if "start_seconds" in sequence:
            label = sequence["kind"].capitalize() + (" · reduced" if sequence["reduced_motion"] else " · normal")
            controls.append(f'<button data-start="{sequence["start_seconds"]:.3f}">{html.escape(label)}</button>')
    serialized = json.dumps(frames, ensure_ascii=False).replace("</", "<\\/")
    page = """<!doctype html>
<html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Rune Cast · RC-020 playable audio capture</title>
<style>body{background:#111725;color:#e6e5e2;font:16px system-ui;margin:24px auto;max-width:1100px;padding:0 16px}h1{font-size:25px;color:#eddaaa}main{display:flex;gap:24px;align-items:flex-start}img{width:min(45vw,450px);height:auto;border:1px solid #554d3d}aside{max-width:550px}button{background:#213d4c;color:#e5e8ea;border:1px solid #426579;border-radius:6px;padding:10px;margin:3px;cursor:pointer}audio{width:100%}small,p{line-height:1.5}.muted{color:#aeb8c4}#label{font-size:19px;color:#70d3cf}@media(max-width:700px){main{flex-direction:column}img{width:min(90vw,450px)}}</style>
<h1>RC-020 · Recorded playable-scene audio</h1>
<main><img id="frame" alt="Actual Rune Cast captured frame"><aside><p id="label"></p>
<audio id="audio" controls preload="metadata" src="playable-mix.wav"></audio>
<p class="muted">Real main scene, production automatic presentation clock, delivered SFX and crypt ambience. Images follow the captured Master-mix sample position; sparse images are review samples, not a full-frame-rate video.</p>
<div>__BUTTONS__</div><p>Measured PCM sample peak: <b>__PEAK__ dBFS</b>.<br>Estimated reconstructed peak: <b>__TRUEPEAK__ dBTP</b>.<br>Observed SFX voices including tails: <b>__VOICES__ / 8</b>.</p>
<p>Cast, partial shield, Pass, Focus, Conjure, reduced motion, victory and defeat use actual controls and outcomes. The terminal fixtures set current HP to one before resolution. The ending crypt-wrap probe explicitly seeks near the file boundary.</p>
<p class="muted">No delivered music exists. Music transitions use separate isolated tests. This internal recording is measured playback; no headphone, speaker or mobile-device listening acceptance is claimed. Five full ambience joins and the final music mix remain pending.</p>
<p><a href="results.json">Runtime trace and assertions</a> · <a href="mix-measurements.json">Independent meter</a> · <a href="playable-mix.wav">Recorded WAV</a> · <a href="contact.png">Frame overview</a></p></aside></main>
<script>const frames=__FRAMES__,audio=document.getElementById('audio'),image=document.getElementById('frame'),label=document.getElementById('label');let current=-1;function sync(){let i=0;while(i+1<frames.length&&frames[i+1].seconds<=audio.currentTime)i++;if(i!==current){current=i;image.src=frames[i].image;label.textContent=frames[i].label+' · '+frames[i].phase;}requestAnimationFrame(sync)}for(const b of document.querySelectorAll('button'))b.onclick=()=>{audio.currentTime=Number(b.dataset.start);audio.play()};sync();</script></html>"""
    page = (page.replace("__BUTTONS__", "".join(controls)).replace("__FRAMES__", serialized)
            .replace("__PEAK__", str(metering["sample_peak_dbfs"]))
            .replace("__TRUEPEAK__", str(metering["estimated_true_peak_dbtp"]))
            .replace("__VOICES__", str(report["max_sfx_voices"])))
    (DEST / "index.html").write_text(page, encoding="utf-8")
    print(json.dumps({"metering": metering, "frames": len(frames), "output": str(DEST / "index.html")}))


if __name__ == "__main__":
    main()
