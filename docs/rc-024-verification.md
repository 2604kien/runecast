# RC-024 — Run-state model and application shell

October 19, 2026 (Australia/Sydney). **Independent run-state and shell groundwork is delivered. Permanent-progression integration remains pending RC-024A.** No Git operations were performed. RC-022 remains deferred, RC-023 remains pending human/device acceptance, and both music tracks remain unavailable.

## Try the implemented flow

From `C:\Dev\RuneCast`, run `.\tools\godot.ps1 -Action run`. Home uses the delivered tower illustration, wordmark and shared theme. **New Run** creates the scoped starter and enters the existing production Shadeling fixture. The initial run has 30/30 health, zero run Gold, no relics, and two each of Spark, Shield, Focus and Conjure Spark.

- **Menu → Resume** returns to the same battle and controller without resetting anything.
- **Menu → Options** and **Home → Options** share the existing Music/SFX/master/reduced-motion settings. Preferences persist using the established settings file.
- **Menu → Quit to Home** is unavailable during unsettled action presentation. Its confirmation explains that current battle progress is discarded. Confirming retains the original battle-entry checkpoint; **Continue** replays the same opening and subsequent random sequence. Cancel keeps the current run, battle, card identities and streams unchanged.
- **New Run** on Home confirms replacement of an existing session. The candidate run is constructed and validated before it replaces the old run.
- Terminal outcomes retain their committed health and ownership. Victory is **Encounter won**, with no full-tower victory or reward. Defeat ends this session's run. Return Home keeps the result; terminal runs cannot Continue this fixture again.

**Continue is session-only. Closing the application loses the run.** No run/profile data is written to settings and there is no recovery, migration, autosave or partial-turn disk format. Home says this explicitly. RC-028 owns future versioned persistence, atomic writes/recovery and migration; this private in-memory checkpoint is a model boundary, not a competing save system.

## State ownership and interfaces

| Owner | State and responsibility |
| --- | --- |
| `scripts/core/run_state.gd` | Stable session run ID/status; run-owned `{id, uid}` instances; current/max HP; Gold/relic references; seed and three RNG states; minimal fixture node/encounter and completion references; private battle-entry checkpoint; once-only outcome commit. Card identity is `(run_id, uid)`, never an implicit profile inventory. |
| `scripts/core/combat.gd` | Hand/draw/discard/installed zones, generated temporary instances, turn energy, shield resolution, finite connector supply, endpoints, editing history and ordered command outcomes. It borrows the run's original instance identities and reports verified boundary values. |
| Combat controller/presenter | Existing command lock, presentation generation, cancellation and staged display. An action resolves once before its presentation; scene ownership never re-applies result events. |
| `scripts/ui/application_shell.gd` | Home, replacement/Quit confirmations, shared Options, one active Combat scene, generation-bound callbacks and model entry/outcome calls. It does not read or mutate private Combat fields. |

`RunState.new(validated_setup, seed)` accepts the scoped production starter. `snapshot()` deeply detaches nested values. During a battle, verified live HP/RNG are reflected through the handoff, while private committed entry values remain available for explained replay. The run-owned collection remains authoritative; no generated Free Spark becomes owned or acquired across runs.

`enter_battle()` accepts only a ready session. `continue_battle()` returns the current battle unchanged or creates a fresh replay from the retained entry. `quit_to_home(battle)` accepts only the matching, consistent, nonterminal active battle, then detaches it without sampling RNG. `resolve_battle(battle)` accepts only the matching, fully cleaned terminal battle once. Statuses are `ready`, `battle`, `replay_pending`, `encounter_won`, `defeated` and invalid-input `invalid`. There is no terminal tower-victory transition in this scope.

`Combat.create_for_run(validated_setup, entry)` validates before construction. Its detached entry carries version, run/encounter identity, seed, current/max HP, original card instances, next temporary-instance ID and **card / endpoint / connector-kit stream states**. It uses the validated production board/content, UID ordering, ordinary shuffle/draw, endpoints-only start and existing finite-kit implementation. Health is carried without adopting an encounter's authored health defaults. `run_handoff()` checks content/identity compatibility, exact permanent-instance conservation, UID allocation, outcome/HP consistency and terminal cleanup before exposing detached values. Temporary cards in draw/discard and invalid or duplicate transitions reject without mutation.

`Combat.snapshot()` remains presentation data and is never a restore format. Fresh setup/Exact replay and ordinary Restart retain their existing distinction in standalone Combat: the former reseeds; the latter continues streams. Run-managed Combat omits those development actions and uses the explicit Quit/Continue checkpoint policy instead. The old bounded `next_encounter` fixture remains available to isolated tests/development; the new shell cannot silently start that successor chain.

## Lifecycle and preserved entry points

`scenes/application.tscn` is the normal main scene. `scenes/main.tscn` remains an independently instantiable Combat scene for UI/audio/resource tests. Explicit `--encounter`, `--board-example`, `--experiment` and existing `--capture` launches bypass Home and preserve their former interfaces.

Combat accepts an injected model through `battle_model` with `run_managed`; `home_requested` routes to the shell. `set_shell_modal()` blocks underlying actions and releases pointer/hold ownership. `prepare_for_exit()` invalidates the controller/presenter, disconnects refresh/tree listeners and disposes audio before detachment. The shell also disconnects old battle callbacks and rejects stale generations, repeated confirmations and reentrant scene-change input. Terminal return waits for a successfully committed outcome; a rejected handoff retains the screen and state.

Home and Combat have sequential scene-owned audio coordinators. Old players/subscriptions stop before replacement; Home has no crypt ambience or substitute music. A disposed coordinator now disconnects its parent's visibility listener and safely ignores later notifications. This fixes the detached-parent callback found during integration.

RC-021 Back deduplication, interrupted pointer handling and native touch-to-mouse slider behavior remain. A shell-confirmation Back consumes only that dismissal, preventing the same broadcast from also opening Combat Menu. Actual Home native-input tests also cover first Music/SFX touches after captured controls and pause during a held New Run press.

The Combat artwork, layout, timing, display-only forecast, confirmed Pass, card/tool/pile inspection, endpoint rotation, connector selection, cleanup, reduced motion and sound policies remain. No board-slot inspection or feedback circles were restored. Run Menu Resume has a stable 50px hit area. Shared confirmations re-fit after text/container minimum-size changes, fixing a narrow Quit panel that initially grew beyond its intended height.

## Validation and evidence

Pinned Godot **4.7.2.stable.official.ed1daf0bf**, Windows Compatibility renderer (NVIDIA OpenGL) and the existing bundled Python were used. Process-local writable application-data folders isolate settings/cache writes. Logs were read for script/engine errors and actual assertion totals, rather than treating exit 0 as sufficient.

| Coverage | Result / evidence |
| --- | --- |
| Baseline core before implementation | **1,827 checks, 0 failures** — [log](../output/qa/rc-024/baseline/test.log). |
| Final core, including 60 new model assertions | **1,887 checks, 0 failures** — [log](../output/qa/rc-024/core/test.log). Defaults, detached snapshots, seeds/isolation, carried HP/UIDs, stream replay, temporary exclusion, malformed/duplicate/stale handoffs and encounter-victory distinction. |
| Existing complete UI suite | **1,171 checks, 0 failures** — [log](../output/qa/rc-024/ui/smoke.log). Includes production/legacy/experiment entry, animation, audio settings, touch, native slider and pause/Back checks. Missing/invalid-content diagnostics are deliberate negative fixtures. |
| New application-shell suite | **47 checks, 0 failures** — [assertions](../output/qa/rc-024/shell-tests.json), [log](../output/qa/rc-024/shell-tests.log). Cancellation, replacement, session Continue, Options, exact checkpoint, repeated input, stale completions, actual routed finger cancellation, native Home controls, interruption, terminal defeat and session closure. |
| Existing audio playback/settings/lifetime suite | **428 checks, 0 failures** — [log](../output/qa/rc-024/audio-tests.log). |
| Focused presentation suite | **31 checks, 0 failures** — [log](../output/qa/rc-024/presentation-tests.log). |
| Actual application layouts/captures | **78 checks, 0 failures**, **24 PNGs** at 720×1600, 450×1000 and 360×640 — [assertions](../output/qa/rc-024/screenshots/results.json), [log](../output/qa/rc-024/capture.log). |
| Production resource pack | **353 policy/integrity checks + 60 exact-payload desktop decode checks, 0 failures** — [final audit](../output/qa/rc-024/resources-final/resource-audit.json). |
| Existing iOS workflow/transfer/resource Python suites | **31 tests, all passed** — [final log](../output/qa/rc-024/resources-final/tool-tests.txt). No native build/device step. |

Commands executed from the workspace (each runner uses its named log):

```powershell
$engine = 'C:\Dev\RuneCast\.tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe'
$py = 'C:\Users\nguye\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
$env:APPDATA = 'C:\Dev\RuneCast\output\qa\rc-024\core-appdata'
.\tools\godot.ps1 -Action test -LogDirectory output/qa/rc-024/core
$env:APPDATA = 'C:\Dev\RuneCast\output\qa\rc-024\appdata'
.\tools\godot.ps1 -Action smoke -LogDirectory output/qa/rc-024/ui
& $engine --headless --path . --log-file C:/Dev/RuneCast/output/qa/rc-024/audio-tests.log --script res://tests/audio_playback_runner.gd
& $engine --headless --path . --log-file C:/Dev/RuneCast/output/qa/rc-024/presentation-tests.log --script res://tests/rc020_presentation_runner.gd
$env:APPDATA = 'C:\Dev\RuneCast\output\qa\rc-024\shell-appdata'
& $engine --headless --path . --log-file C:/Dev/RuneCast/output/qa/rc-024/shell-tests.log --script res://tests/application_shell_tests.gd
$env:APPDATA = 'C:\Dev\RuneCast\output\qa\rc-024\capture-appdata'
$env:LOCALAPPDATA = 'C:\Dev\RuneCast\output\qa\rc-024\capture-localappdata'
& $engine --path . --log-file C:/Dev/RuneCast/output/qa/rc-024/capture.log --script res://tests/application_shell_capture.gd
$env:APPDATA = 'C:\Dev\RuneCast\output\qa\rc-024\resources-final\user-data'
$env:LOCALAPPDATA = $env:APPDATA
& $engine --headless --path . --export-pack iOS builds/ios/rc-024-resource-final/RuneCast.pck --log-file C:/Dev/RuneCast/output/qa/rc-024/resources-final/export-engine.log
& $py tools/verify_ios_resources.py --pack builds/ios/rc-024-resource-final/RuneCast.pck --engine $engine --report output/qa/rc-024/resources-final/resource-audit.json
$env:RUNECAST_RESOURCE_TEST_PACK = 'C:\Dev\RuneCast\builds\ios\rc-024-resource-final\RuneCast.pck'
& $py -m unittest discover -s tests -p 'test_ios_*.py' -v
```

The final **resource-only** pack is `builds/ios/rc-024-resource-final/RuneCast.pck`: **10,333,948 bytes**, **340 entries**, SHA-256 **`9c6f87044c72db5b33cb20c2b02954902e7dd30d34559230e656d3ab2086049a`**. It is not a native iOS build, signed app, simulator run or device acceptance. The final export log has no engine errors; the existing Android Build Tools fallback notice is informational. For a future fresh resource audit, use a new output/evidence directory and set `RUNECAST_RESOURCE_TEST_PACK` to that pack.

Launch compatibility was also exercised through `tools/godot.ps1 -Action capture`, each with `-LogDirectory output/qa/rc-024/launch-<mode>` and a unique `-CapturePath res://output/qa/rc-024/launch-<mode>/screen.png`: production without extra arguments; historical `-Encounter res://data/encounter.json`; `-BoardExample board_training -ExampleStep built`; and `-Experiment -Scenario effects -Variant control -Seed 42`. All four saved actual screenshots successfully. An initial board capture reported shutdown resource leaks; the exact command rerun and four direct-Combat/four wrapper verbose captures did not reproduce them. [Clean command rerun](../output/qa/rc-024/launch-board-confirm-console.log), [direct comparison](../output/qa/rc-024/board-direct-1-console.log), [wrapper comparison](../output/qa/rc-024/board-wrapper-1-console.log). The original warning is retained in [its log](../output/qa/rc-024/launch-board/capture.log); no causal fix is claimed for that transient diagnostic.

Initial diagnostic runs using default/relative log or cache paths reported unwritable `user://` locations; final runs above use absolute log paths and task-local application data and have no such errors. These errors were inspected and corrected, not accepted merely because assertion counts passed.

### Visual review

Actual images were inspected for tower/wordmark composition, readable copy, full confirmation bounds, reachable controls and preserved Combat art/scrolling. Narrow Combat intentionally scrolls; its bottom capture proves hand/piles, connector controls, forecast, Cast and navigation remain available. Desktop/native logical rendering is not physical-device acceptance.

| State | Desktop 450×1000 | Narrow 360×640 |
| --- | --- | --- |
| Fresh Home | [image](../output/qa/rc-024/screenshots/home-450x1000.png) | [image](../output/qa/rc-024/screenshots/home-360x640.png) |
| New Run replacement confirmation | [image](../output/qa/rc-024/screenshots/new-run-confirmation-450x1000.png) | [image](../output/qa/rc-024/screenshots/new-run-confirmation-360x640.png) |
| Combat entry | [image](../output/qa/rc-024/screenshots/combat-entry-450x1000.png) | [image](../output/qa/rc-024/screenshots/combat-entry-360x640.png) |
| Combat controls | [image](../output/qa/rc-024/screenshots/combat-controls-450x1000.png) | [image](../output/qa/rc-024/screenshots/combat-controls-360x640.png) |
| Combat Menu | [image](../output/qa/rc-024/screenshots/combat-menu-450x1000.png) | [image](../output/qa/rc-024/screenshots/combat-menu-360x640.png) |
| Quit explanation | [image](../output/qa/rc-024/screenshots/quit-confirmation-450x1000.png) | [image](../output/qa/rc-024/screenshots/quit-confirmation-360x640.png) |
| Returned Home | [image](../output/qa/rc-024/screenshots/returned-home-450x1000.png) | [image](../output/qa/rc-024/screenshots/returned-home-360x640.png) |
| Shared Home Options | [image](../output/qa/rc-024/screenshots/home-options-450x1000.png) | [image](../output/qa/rc-024/screenshots/home-options-360x640.png) |

## Changed files and remaining work

Runtime: new `scripts/core/run_state.gd`, `scripts/ui/application_shell.gd`, `scenes/application.tscn`; updated `scripts/core/combat.gd`, `scripts/ui/main.gd`, `scripts/audio/audio_coordinator.gd`, `project.godot`; generated script UID sidecars. No balance, content-definition, artwork or audio-asset edits.

Tests/tools: new `tests/run_state_tests.gd`, `tests/application_shell_tests.gd`, `tests/application_shell_capture.gd` and UID sidecars; registered model tests in `tests/test_runner.gd`; updated `tools/verify_android_package.py`, `tools/verify_android_resources.gd`, `tools/verify_ios_resources.py`, `tests/test_ios_resource_audit.py`. Both existing export presets already include all runtime resources, so preset bytes and all native preparation remain unchanged. Resource policies explicitly require the shell, run model, isolated Combat, Home art and wordmark. The exact pack probe uses an empty project and fresh user data to prevent workspace fallback; it exercises standalone Combat and the Home/entry/replay flow.

Documentation: `README.md`, `docs/setup.md`, `docs/project-plan.md`, `docs/v1-design-spec.md`, `docs/decisions.md`, `docs/gameplay-rules.md`, `docs/production-rules-spec.md`, `docs/touch-interactions.md` and this report. Evidence is under `output/qa/rc-024`; resource-only PCKs are separate from retained RC-021/022 artifacts.

RC-024's full task remains unchecked for its explicitly unresolved permanent-progression portion. **RC-024A must still resolve permanent rune acquisition, qualifying milestones, duplicate policy, unlock/copy ownership, starter/reward/Store eligibility, currency and purchase lifetime.** No permanent rune is awarded by this fixture. There are no rewards, relic effects, Store, shop, complete Map/route, accounts or extra currencies.

**Next ready implementation: RC-025, branching routes and Map**, using this state groundwork and a fixture-based Shadeling encounter reference. RC-026 owns full route-to-encounter integration; RC-028 owns disk persistence. RC-022 Mac/signing/iOS-device work stays deferred; RC-023 and all physical-device, final music/mix, mobile performance and release acceptance remain open.
