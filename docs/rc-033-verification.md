# RC-033 — Enemy action and intent framework

October 25, 2026 (Australia/Sydney). **RC-033 is complete for its bounded framework and desktop verification scope.** Deterministic repeating scalar attacks, one optional HP threshold/second sequence, authoritative touch inspection and ordered phase feedback are implemented. Current run v6, profile v1, `rc028_local_v1`, compact Store, Shadeling's 32 HP / 8–12–6 baseline and historical experimental hit behavior remain intact.

This is not production Bell Keeper delivery. RC-034 retains encounter definitions, boards, pools, final values and any separately decided dodge mechanic; RC-037–040 retain remaining character packs. Final tuning, accessibility and physical-device acceptance retain their existing owners. No defend, armour, statuses, summons, enemy healing, multiple targets, extra phases, random attack selection or general scripting engine was added. No new art/audio, native mobile build or signing work was performed.

Process exception: the first command batch mistakenly included read-only Git status and branch queries before the pasted prohibition was reviewed. This was disclosed immediately; no further Git operations or Git metadata reads were performed.

## Configuration and ownership

Enemy definitions keep their existing required fields. The only optional addition is:

```json
{
  "id": "dev_rc033_phase_probe",
  "name": "RC-033 Phase Probe",
  "max_health": 80,
  "intents": [8, 12, 16],
  "phase_two": {
    "health_threshold": 40,
    "intents": [12, 16, 20]
  }
}
```

`RuneContentLoader` validates all definitions before publishing setup. Both sequences contain 1–100 scalar integer values in 0–100,000; zero attacks remain valid. Maximum HP is 1–100,000. The threshold is a positive integer strictly below maximum HP. `phase_two` must be exactly one object with those two fields. Missing fields, null, empty/oversized arrays, nested/extra phases, unsupported actions/fields, incompatible types, booleans, fractional and nonfinite values reject with source/definition/field diagnostics. Mathematical integer JSON values normalize to integers under the existing loader rules.

Omitting `phase_two` does **not** insert an empty/default phase field into normalized configuration. Existing no-phase setups retain their shapes and fingerprints. Present phase configuration is copied into the normalized encounter and participates in the existing content signature. Battle code never replaces `encounter.intents` or mutates configuration to transition.

Combat owns `_enemy_phase`, `_enemy_sequence_index` and `_announced_attack` locally. `intent()` returns that announcement. Construction, reset, exact replay and supported successor entry initialize phase one/index zero. A nonterminal end turn advances the active sequence or performs the one transition; no enemy action cycling consumes any RNG stream. Turn modulo and current HP never recalculate an already announced action.

Detached `snapshot.enemy_action` contains:

| Field | Meaning |
| --- | --- |
| `kind`, `amount` | `attack` and the currently announced scalar damage |
| `phase`, `phase_count` | One-based active phase and total (1 or 2) |
| `sequence_index`, `sequence` | Zero-based position and active repeating sequence |
| `health_threshold`, `next_sequence` | Present only for a phased encounter; configured threshold and phase-two sequence |

The existing scalar `snapshot.intent` remains the same amount. Snapshots, inspection and events are detached deep copies.

## Exact resolution and presentation order

An accepted production Cast retains this order:

1. Resolve effective ranked cards and graph aggregation using RC-031's shared resolver. Each physical rune/connector pays once; Split/Join aggregation precedes once-per-Cast relic additions.
2. Pay energy and emit one aggregate enemy `damage`, including zero. Requested `amount` and actual clamped `applied` HP loss remain distinct.
3. If the enemy survives, emit shield and retaliate with the **old announced attack**, applying this Cast's shield. Enemy lethal damage suppresses both.
4. Perform the existing ascending board cleanup, temporary expiry, hand discard/expiry and Undo clearing, ending with `turn_cleanup`.
5. If either combatant died, emit the terminal result and stop. No phase change, next turn, draw, endpoints or kit work follows.
6. If phase one survived at/below its threshold, set phase two/index zero and emit committed **`enemy_phase_changed`** once. Otherwise advance/wrap the active sequence normally.
7. Keep existing endpoints → kit → `turn_started` → actual reshuffle/draw order. Phase-two later turns advance without restarting below the threshold.

Pass emits no spell, enemy damage or shield; it uses the same announcement and subsequent cleanup/survival boundary. Rejected/unaffordable actions, cancelled Pass, busy/stale/duplicate callbacks and inspection do not advance phase, sequence, turn or RNG.

`enemy_phase_changed` includes detached `before`/`after` action objects, `enemy_hp`, `health_threshold`, `turn_after` and the ordinary `type`, encounter/action/sequence identity. `turn_started` also includes `enemy_action` so ordinary cycling stages consistently. Existing action identity makes the phase transition uniquely observable within its controller generation.

The presenter displays the old intent through enemy damage, old retaliation and cleanup, even though the full authoritative command has already resolved. The explicit phase step uses the existing 0.24-second interval and **Phase 2** text overlay, capped to 0.06 seconds in reduced motion. Its commit installs the supplied next action before the normal next-turn steps. It never publishes the final authoritative snapshot over unfinished old consequences. Cancellation/generation guards, exactly-once completion, detached payloads and no gameplay writes from callbacks remain intact.

Gameplay `enemy_phase_changed` is distinct from animation-clock `phase_started`. Phase audio is deliberately silent; the future catalogue alias is unbound. Existing actual damage/shield/attack/terminal mappings remain event-driven. There is no HP/forecast polling or new sound/pose asset.

## Touch inspection

The existing attack icon/value retain their geometry inside a compact outlined **i** tap/hold target (minimum 96×68 logical pixels). The shared navy/gold inspector explains the announced attack, active sequence/position, phase, threshold, second sequence and preserved current-turn retaliation. Long text scrolls independently above fixed Close. It uses only the detached announced-action data; Pass confirmation uses the same authoritative amount as actual retaliation.

Repeated open/refresh/close, held gestures, drag cancellation and Back preserve preparation, ownership, energy, all three RNG states and command history. Modal and busy guards prevent input underneath. A view-local inspector mode additionally rejects stale hidden Pass/confirm signals when the panel has become read-only intent. Production retains its disabled keyboard/right-click controls. Forecast remains display-only; board slots remain uninspectable; Incoming, BOSS and Pause remain absent. The compact Store layout is unchanged.

## Saves and run lifecycle

Run v6, profile/route v1 and the local envelope are unchanged. There is no new serialized phase field, profile ownership or mid-turn checkpoint. Live Resume keeps the same model, phase, announced action, hand, selected geometry and preparation. Quit/process restart uses the committed original entry; replaying the same actions reproduces the same phase progression and all RNG states. Existing setup fingerprint checks stay strict: altered phase thresholds/sequences fail; genuine unchanged no-phase saves restore without a new migration.

The focused lifecycle test enters an explicitly registered excluded encounter through ordinary RunState/EncounterResolver paths with the normal 30 HP/eight-card starter. Its separate validated **74 HP test threshold** lets a first legal 6-damage Cast reach phase two while retaining enough ordinary health to inspect preparation. Fifteen genuine controller commands are recorded and reproduced after Quit and in a second process. The required playable fixture below retains the roster's **40 HP threshold**. Production restoration rejects the excluded registration, and forged content signatures or added mid-turn save fields reject.

All 40 genuine predecessor/current specimens (v1–v6), Store receipts/limits, ranked ownership/relics, original room policies/offers, pending results, permanent unlocks, terminal/abandonment records and exact entry RNG pass restoration/recovery coverage. Store staged write/flush/close/backup/replace failure, identical Retry and restart behavior pass unchanged.

## Try the playable fixture

From `C:\Dev\RuneCast`:

```powershell
.\tools\rc033_fixture.ps1 -AtThreshold
```

The [launcher](../tools/rc033_fixture.ps1) uses pinned Godot 4.7.2, isolated APPDATA/LOCALAPPDATA under `output/qa/rc-033/manual-environment`, and fixture settings under `output/qa/rc-033/manual`. Add `-Narrow` for an actual 360×640 window or `-ReducedMotion`; default is 450×1000. Omit `-AtThreshold` to start at the original entry and first attack. The underlying command is:

```powershell
& '.\.tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe' --path . --script res://tests/rc033_manual.gd -- --at-threshold
```

Explicit fixture resources: **400/400 player HP, 20 energy per turn, eight normal opening/turn draws, six Spark and two Shield**. Enemy: **80 HP, 8/12/16, threshold ≤40, then 12/16/20**. Normal random endpoints, connector kits and legal construction remain in force. The fixture intentionally has no delivered enemy artwork; it uses the existing arena and phase text. No production balance, Shadeling identity, encounter pool or full-route/Store fixture changes.

1. `-AtThreshold` executes two ordinary Passes and six legal single-Spark Casts, then builds a seventh legal circuit. It writes no HP/phase/board/hand/RNG state directly. The screen shows turn 9, enemy **44 HP**, player **308 HP**, announced attack **16** and forecast **6 damage / 0 shield / 2 cost**.
2. Tap the enemy attack. Read/scroll details, then Close. Cast the prepared circuit. Enemy becomes **38 HP** while **16** remains visible through retaliation. Player becomes **292 HP**. After cleanup/phase feedback, turn 10 announces **12**, phase two position one.
3. Confirm Pass three times to observe **16 → 20 → 12**. Phase two never retriggers. Inspect again or open Menu/Resume with a partly built circuit.
4. Build seven more single-Spark circuits. The last requests **6** against **2 HP**, applies **2**, and ends without retaliation or next-turn work. Menu **Exact replay** returns to the original entry.

From original entry, the same walkthrough is two Passes followed by seven one-Spark Casts before step three. The [recorded legal paths/commands](../output/qa/rc-033/ui/legal-walkthrough.json) identify zero-based row-major cells if exact construction guidance is useful. [Fixture registration/data](../tests/fixtures/rc033/README.md) remain excluded and explicitly loaded; no production restrictions were relaxed.

## Executed verification

All Godot runs use **4.7.2.stable.official.ed1daf0bf** and isolated saves/settings/environment directories. Counts overlap across reruns and should not be summed as unique tests.

| Check | Result | Evidence |
| --- | --- | --- |
| Focused configuration/Combat | 191 checks, 0 failures | [Core](../output/qa/rc-033/core/results.json) |
| Ordered normal/reduced presentation and silent phase audio | 159 checks, 0 failures | [Presentation](../output/qa/rc-033/presentation/results.json) |
| Touch/hold/drag, overlays, cancelled/stale Pass, repeated inspection | 48 checks headless and rendered, 0 failures | [Touch](../output/qa/rc-033/touch/results.json) |
| Legal actual-window journey, captures and exact replay | 127 rendered checks, 0 failures; earlier headless journey 95/0 | [UI](../output/qa/rc-033/ui/results-capture.json), [console](../output/qa/rc-033/ui/final-console.txt) |
| RunState phase Resume/Quit/disk/fresh-process replay | 74 checks across two processes, 0 failures | [Prepare](../output/qa/rc-033/lifecycle-01/prepare.json), [restart](../output/qa/rc-033/lifecycle-01/restart.json) |
| Existing content, Combat, UI, inspection, audio, run/save, rooms and RC-032 lifecycle/routes | 10,244 checks across 28 suites, 0 unresolved failures | [Consolidated provenance](../output/qa/rc-033/regression/results-final.json) |
| Additional Store model/shell | 667 checks, 0 failures | [Store](../output/qa/rc-033/store-regression/f2d594dbff/results.json) |
| Store durability/Retry/restart/recovery | 1,980 checks, 240 launches, 0 failures | [Process campaign](../output/qa/rc-033/store-process/a031f324a8/results.json) |
| Genuine v1–v6 compatibility/recovery | 3,547 checks, 40 specimens, 440 launches, 0 failures | [Migration campaign](../output/qa/rc-033/migrations/1223553dfa/results.json) |
| Rendered shared Menu / popup spacing | 164 / 393 checks, 0 failures | [Rendered regressions](../output/qa/rc-033/regression-rendered/ae8131673a/results.json) |
| Absolute Combat reference | 257 assertions; exactly the 15 documented baseline failures | [Full comparison](../output/qa/rc-033/reference/baseline-comparison.json) |
| Resource-only package / packaging tests | 406 integrity + 142 decode checks and 32 Python tests pass | [Audit](../output/qa/rc-033/resources/resource-audit.json), [tool tests](../output/qa/rc-033/resources/tool-tests.txt) |

Focused boundaries cover legacy first/wrapped scalar intent, HP just above/at/below threshold at all three phase-one positions, unchanged original retaliation, phase-two index zero/wrap/one-time transition, zero damage/attack, partial/full shields, enemy lethal/overkill/player lethal, rejected/unaffordable Cast, cancelled Pass, duplicate/busy/stale input, upgraded Spark/mixed Cinder Guard, Split/Join and relic additions, reset and both phased/nonphased successors. Configuration tests reject 30 malformed cases and verify detached inputs/outputs. Matching no-phase battles prove enemy cycling adds no random draws.

Initial findings remain visible in evidence. Render review found unsupported arrow glyphs; ordinary `/` separators fixed them, then all 20 final images were inspected. Adversarial input review found and fixed the hidden stale Pass callback above. The broad reward-audio suite passed all 159 assertions but reported a shutdown resource in use; its existing delay was moved to deferred completion after local references release. The targeted rerun is clean, runtime audio is unchanged, and both initial/final logs are linked in consolidated results. The two audio fixture intent overrides now configure attacks before Combat construction, respecting the announced-action contract. No reference assertion was weakened: all 257 measurements/assertions match the accepted baseline, normalizing only generated node IDs.

The final [resource PCK](../builds/rc-033-resources/RuneCast.pck) has **393 entries, 12,472,396 bytes**, SHA-256 `e5da2fa1c974b65053a01c7058fbd6b852293afb0daeb818a825c1a6e447ec06`. [Source manifest](../output/qa/rc-033/resources/source-manifest.json). Runtime files remain in the existing automatic inventory; the exported-payload probe checks read-only announced intent and excludes RC-033 fixtures/QA. This is an exported resource package, not a native iOS/Android build.

### Reproduce checks

Use an isolated environment; the Python campaign helpers create additional unique isolated subdirectories themselves:

```powershell
$rc033QA = 'C:\Dev\RuneCast\output\qa\rc-033\rerun-environment'
$env:APPDATA = Join-Path $rc033QA 'appdata'
$env:LOCALAPPDATA = Join-Path $rc033QA 'localappdata'
New-Item -ItemType Directory -Force -Path $env:APPDATA,$env:LOCALAPPDATA | Out-Null
$rc033Engine = 'C:\Dev\RuneCast\.tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe'
$rc033Python = 'C:\Users\nguye\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
& $rc033Engine --headless --path . --audio-driver Dummy --script res://tests/rc033_core_runner.gd
& $rc033Engine --headless --path . --audio-driver Dummy --script res://tests/rc033_presentation_runner.gd
& $rc033Engine --path . --audio-driver Dummy --script res://tests/rc033_touch_runner.gd
& $rc033Engine --path . --audio-driver Dummy --script res://tests/rc033_ui_runner.gd -- --capture-rc033
& $rc033Engine --headless --path . --audio-driver Dummy --script res://tests/rc033_lifecycle_runner.gd -- --stage=prepare --save-root=res://output/qa/rc-033/lifecycle-rerun
& $rc033Engine --headless --path . --audio-driver Dummy --script res://tests/rc033_lifecycle_runner.gd -- --stage=restart --save-root=res://output/qa/rc-033/lifecycle-rerun
& $rc033Python tools/verify_rc032_regressions.py --output-root output/qa/rc-033/regression-rerun
& $rc033Python tools/verify_rc032_regressions.py --render --only shared-menu,panel-spacing,reference --output-root output/qa/rc-033/rendered-rerun
& $rc033Python tools/verify_rc032_store_process.py --output-root output/qa/rc-033/store-process-rerun
& $rc033Python tools/verify_rc032_store_migrations.py --output output/qa/rc-033/migrations-rerun
& $rc033Engine --headless --path . --editor --export-pack 'iOS' builds/rc-033-resources/RuneCast.pck
& $rc033Python tools/verify_ios_resources.py --pack builds/rc-033-resources/RuneCast.pck --engine $rc033Engine --project-root . --report output/qa/rc-033/resources-rerun/resource-audit.json
```

Choose a fresh lifecycle directory for each prepare/restart pair. The reference command intentionally returns nonzero for the 15 known failures; compare them, do not waive or suppress them.

### Visual inspection

Twenty real renderer captures were individually reviewed: original entry, phase-one details at top/bottom, before threshold, old retaliation, phase text, next playable turn, phase-two details at top/bottom, and victory at each requested window size. [Visual review and image hashes](../output/qa/rc-033/ui/visual-review.json). Text wraps and scrolls without overlapping fixed Close. The attack target leaves surrounding geometry unchanged. A 360×640 configured window retains the existing 288×640 rendered content with side letterboxing; the capture saves that viewport image. These are actual configured-window captures, not resized mockups or physical-device acceptance.

| State | 450×1000 | 360×640 |
| --- | --- | --- |
| Phase-one intent | [Top](../output/qa/rc-033/ui/intent-phase-one-450x1000.png), [scrolled](../output/qa/rc-033/ui/intent-phase-one-scrolled-450x1000.png) | [Top](../output/qa/rc-033/ui/intent-phase-one-360x640.png), [scrolled](../output/qa/rc-033/ui/intent-phase-one-scrolled-360x640.png) |
| Before threshold | [44 HP / 16](../output/qa/rc-033/ui/before-threshold-450x1000.png) | [44 HP / 16](../output/qa/rc-033/ui/before-threshold-360x640.png) |
| Old retaliation | [38 HP / 16](../output/qa/rc-033/ui/old-retaliation-450x1000.png) | [38 HP / 16](../output/qa/rc-033/ui/old-retaliation-360x640.png) |
| Phase feedback | [Phase 2](../output/qa/rc-033/ui/phase-change-450x1000.png) | [Phase 2](../output/qa/rc-033/ui/phase-change-360x640.png) |
| Next playable turn | [38 HP / 12](../output/qa/rc-033/ui/after-threshold-450x1000.png) | [38 HP / 12](../output/qa/rc-033/ui/after-threshold-360x640.png) |
| Phase-two intent | [Top](../output/qa/rc-033/ui/intent-phase-two-450x1000.png), [scrolled](../output/qa/rc-033/ui/intent-phase-two-scrolled-450x1000.png) | [Top](../output/qa/rc-033/ui/intent-phase-two-360x640.png), [scrolled](../output/qa/rc-033/ui/intent-phase-two-scrolled-360x640.png) |

## RC-034 handoff

Author normal/elite/boss/guardian definitions through the existing validated enemy and encounter files. Use scalar `intents`; supply only the optional `phase_two` object when needed. Register actual enemy/role/board identities explicitly in EncounterResolver and compatible run restore context; preserve existing signatures/policy history when expanding content. Do not repurpose the development fixture as Bell Keeper or mutate live configuration to transition.

Consume `enemy_action` for truthful threat inspection and `enemy_phase_changed` for committed phase feedback. Keep animations/audio observational and avoid HP-derived phase inference. Current framework supports the roster's single threshold and deterministic cycles; any dodge or other new mechanic needs its own explicit decision/implementation. RC-034 can now author encounters against this interface, while remaining assets, final balancing and human/physical-device acceptance stay open.
