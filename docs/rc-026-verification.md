# RC-026 — Encounter entry, results and collection transfer

**October 23 persistence update:** [RC-028](rc-028-verification.md) adds durable selected-entry replay, outcomes, acknowledgement, reward locks and profile ownership. Process closure no longer loses the committed run/rune state. The session-only limitations below are historical RC-026 evidence.

October 21, 2026 (Australia/Sydney). **Implemented and verified for supported encounter boundaries.** Two consecutive real Combat victories now pass through the shell's selected-node entry, result and return-to-Map flow. The production tower remains blocked by missing content. No Git operations were performed. RC-022 remains deferred, RC-023 remains pending human/device acceptance, both music tracks remain unavailable, and permanent progression remains with RC-024A.

## Try the integration

Normal `.\tools\godot.ps1 -Action run` still opens Home → New Run → an unvisited nine-visit Map. Inspecting and confirming an opening Wickling/Stone Sentinel node explains that its content is unavailable and consumes nothing. Shadeling remains the explicit boss at depth six, with Bell Keeper as the separate depth-nine guardian. There is no teleport or automatic service-room completion.

To play the explicit integration fixture, from `C:\Dev\RuneCast`:

```powershell
$engine = 'C:\Dev\RuneCast\.tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe'
& $engine --path . --script res://tests/encounter_integration_runner.gd -- --manual
```

The Map says **Reward-free integration fixture**. Its first two depths use the existing Calibration Wisp definition, honestly labeled as development content, on Gallery then Ossuary. The first uses the existing `dev_entry` loadout's four energy/two draws; the second uses the existing starter's three energy/three draws. Wisp retains 45 HP and intents `[3, 7, 5]`. Its artwork is unavailable; the scene does not display Shadeling as Wisp. The original encounter title `ENCOUNTER ENTRY FIXTURE 2` belongs to the reused definition, independently of its route visit number.

Choose an available fixture node → **Enter → Enter room**. Combat uses ordinary placement, Rotate, techniques, Cast and confirmed Pass. After a win, **Return to Map** acknowledges the result. Enter the connected second Wisp. The fixture retains nine depths, branches, depth-six Shadeling and the separate guardian; after two wins it correctly stops at the unavailable third-depth production enemy. No room history is fabricated.

Combat → Map → current-node **Resume room** returns to the same scene. Confirmed **Quit to Home → Continue** recreates that same visit's exact battle entry, discarding current battle progress as the confirmation explains. A replay-pending node also offers **Replay entry** on Map. Result **Return Home → Continue** reopens the pending result without replaying terminal Combat.

The automated runner proves both wins with fixed seed 42 and legal controller commands, without changing health, choosing favorable seeds, replacing endpoints, supplying cards or loading an authored witness. First victory leaves **21/30 HP**; the second carries that health and finishes at **14/30 HP**. All eight original permanent instances remain, generated temporary UIDs advance the allocator, and Gold/relics remain unchanged. This proves transfer, not production balance or a complete playable tower.

## Ownership and transaction interfaces

| Boundary | Responsibility |
| --- | --- |
| `ContentLoader.load_selected_encounter(path, board_id, loadout_id="")` | Validates selected references through the existing JSON/schema/rules loader. Resolves exactly one definition and rejects the old successor chain. Loadout override is used only by the excluded fixture resolver. |
| `EncounterResolver.resolve(node, entry)` | Bounded dispatch for `training_shadeling`/Shadeling/boss and `rc007_entry_probe_next`/Calibration Wisp/development. Validates enemy, role, board, rules and compatibility. Missing production IDs return explanations. |
| `RunState.prepare_route_battle(token)` | Revalidates the request's run/route/node/revision; resolves content and constructs `Combat.create_for_run()` from authoritative run-owned health, collection, allocator and RNG. Stores a candidate without consuming a visit or replacing the entry checkpoint. Resolver-returned resource values cannot override the owner. |
| Shell `_prepare_battle_scene()` | Constructs and attaches the real scene, controller and presenter hidden, with input blocked and audio deferred. Checks attachment/readiness/configuration before commit. Incompatible, missing or self-deleting scenes are disposed. |
| `commit_route_battle(candidate)` / `cancel_prepared_battle(candidate)` | Checks exact candidate model, configuration, identity and unchanged opening; revalidates route eligibility and commits one visit. Cancellation releases the prepared candidate while leaving the route usable. |
| Shell `_activate_battle_scene()` | Publishes the attached scene after commit, disposes the previous Home audio owner, then activates Combat audio/input. No second initial draw or scene construction occurs. |
| `resolve_battle(model)` | After presentation settles, validates terminal cleanup and exact active ownership, then commits run resources and route outcome without callbacks between the two owner updates. Rejection retains recoverable battle state. |
| `acknowledge_result(identity)` | Clears only the matching pending result. Returns to the route's actual ready/pending-choice/defeated/completed status. It grants no reward. |
| `prepare_continue_battle()` / `commit_continue_battle()` | Uses model-owned entry/setup data for exact replay, preparing the scene before committing the replacement model. Same run/route/node/visit, new battle generation. A failed attachment keeps replay recoverable. |

The active identity is `{run_id, route_id, node_id, visit_id, generation}` plus the exact model object. Encounter-definition IDs can repeat; they are not completion keys. `Combat.validate_run_entry()` and `run_handoff()` carry and validate that ownership. Run snapshots expose detached active identity and pending result; presentation snapshots are never restoration data.

`RunState._sync_route_status()` composes route status with active battle, replay checkpoint and pending result ownership. Rejected entry, room completion or choice callbacks cannot overwrite a battle/replay/result status. Candidate preparation also guards reentrant calls. Old scene/controller/presenter/audio callbacks are disconnected or invalidated during disposal.

At each new battle, original permanent instances are collected in ascending UID order before the ordinary continued shuffle/draw. Health/max HP never adopt the next loadout's authored defaults or heal. Card, endpoint and kit RNG streams continue; route RNG remains independent. Turn, energy/draw configuration, enemy health/intents, endpoints and kit initialize for the selected encounter. Old hand/discard/installed topology, shield, history, unused stock and generated temporary instances do not carry.

Live Map inspection keeps the exact scene/controller/model, card identities, preparation, selected tool/card/cell, scroll and audio coordinator/player. Quit/Continue instead reconstructs the stored entry and subsequent random sequence. Closing the process still loses the session; RC-028 owns disk persistence.

## Outcomes, choices and unavailable content

Production resolution retains the required `encounter_rewards` choice for RC-027. A victory can be recorded while the room remains current and all successors locked. Acknowledging the result does not complete that choice. The existing `complete_room_choice(run_id, node_id, visit_id, choice_id)` interface remains available to its future owner; normal play exposes no completion cheat or reward claim.

The excluded fixture resolver explicitly declares no required choices and a reward-free policy. Result text states that no Gold, rune, healing, relic, perk or permanent unlock was granted. Defeat commits zero HP, unlocks no successor and ends continuation after acknowledgement. Shadeling victory is one encounter outcome. Only valid completion of the separate guardian visit can complete the tower; existing route tests retain this distinction.

Wickling, Stone Sentinel, Chain Warden and Bell Keeper definitions remain unavailable. Event, shop and recovery handlers are also unavailable. Shadeling's supported node is still unreachable through normal play until its preceding rooms exist. No final enemy stats, phases, artwork, rewards or route pacing were invented.

## Validation

Pinned Godot **4.7.2.stable.official.ed1daf0bf**, Windows Compatibility renderer. Rendered tests use Dummy audio and isolated settings/cache directories. Diagnostics were inspected alongside assertion totals.

| Coverage | Actual result |
| --- | --- |
| Core, including existing run/route suites and 56 new integration assertions | **2,279 checks, 0 failures** — [log](../output/qa/rc-026-core-tests.log). |
| Existing UI suite | **1,171 checks, 0 failures** — [log](../output/qa/rc-026/ui-tests.log). Missing/malformed fixture messages are expected negative cases. |
| Existing application shell, extended candidate lifecycle checks | **106 checks, 0 failures** — [log](../output/qa/rc-026/shell-tests.log), [assertions](../output/qa/rc-026/shell-tests.json). |
| New shell integration, headless | **78 checks, 0 failures** — [log](../output/qa/rc-026/integration-tests.log). |
| Same integration with actual rendered captures | **130 checks, 0 failures; 26 PNGs** — [log](../output/qa/rc-026/integration-capture.log), [assertions and turn trace](../output/qa/rc-026/integration/results.json). |
| Audio catalogue/playback/settings/lifetime | **428 checks, 0 failures** — [log](../output/qa/rc-026/audio-final.log), [assertions](../output/qa/rc-026/audio/audio-tests.json). |
| Focused presentation | **31 checks, 0 failures** — [log](../output/qa/rc-026/presentation-final.log). |
| Shared navigation, native input and current neutral appearance | **336 checks, 0 failures; 32 PNGs** — [log](../output/qa/rc-026/navigation-capture.log), [assertions](../output/qa/rc-026/navigation/screenshots/results.json). |
| Unchanged absolute Combat-reference geometry | **257 checks, 15 pre-existing failures** — [current results](../output/qa/rc-026/combat-reference/results.json), [exact baseline comparison](../output/qa/rc-026/combat-reference-baseline-comparison.json). |
| Fresh resource-only PCK | **378 policy/integrity checks + 98 exact-payload decode checks, 0 failures** — [audit](../output/qa/rc-026/resources/resource-audit.json), [decode log](../output/qa/rc-026/resources/ios-resource-probe.log). |
| Python resource/workflow/transfer suites | **32 tests passed** — [log](../output/qa/rc-026/resources/tool-tests.txt). |

Focused checks cover selected enemy/board/configuration, permanent UID and temporary exclusion, continuing allocator/RNG, repeated definition across distinct visits, stale run/route/node/revision tokens, reentrant resolver calls, altered candidates, construction failure, incompatible scenes, failure after actual scene readiness, replay attachment failure, corrupt terminal handoff atomic rejection, duplicate/stale callbacks, pending choices, defeat, composed statuses, exact replay and live Resume.

The 15 absolute-reference failures match the historical shared-navigation baseline exactly in failed descriptions and measured values, ignoring engine-generated node IDs. The existing 13-pixel hand/forecast/Cast/navigation displacement remains. No geometry assertion was weakened or unrelated spacer/layout change introduced.

An initial integration assertion compared the entire audio-loop snapshot across elapsed time; playback clock/fade values naturally changed. The corrected assertion measures coordinator/player identity and ambience start count, matching the actual ownership requirement. Its diagnostic log is retained as [integration-audio-clock-before.log](../output/qa/rc-026/integration-audio-clock-before.log). Final integration logs contain no unexpected engine/script errors.

## Actual viewport review

The following are actual Godot screenshots. Review checked the reused gold/navy confirmation frame, reachable fixed actions, scrolling long result policy, selected Wisp label/stats, unchanged parchment/navigation, exact replay opening and carried Map health/depth. The narrow Combat page intentionally scrolls. Desktop rendering is not physical-device acceptance.

| State | Desktop 450×1000 | Narrow 360×640 |
| --- | --- | --- |
| Entry confirmation | [image](../output/qa/rc-026/integration/entry-confirmation-450x1000.png) | [image](../output/qa/rc-026/integration/entry-confirmation-360x640.png) |
| Actual Combat entry | [image](../output/qa/rc-026/integration/combat-entry-450x1000.png) | [image](../output/qa/rc-026/integration/combat-entry-360x640.png) |
| Prepared controls | [image](../output/qa/rc-026/integration/combat-prepared-450x1000.png) | [image](../output/qa/rc-026/integration/combat-prepared-360x640.png) |
| Live Map / Resume | [Map](../output/qa/rc-026/integration/live-map-450x1000.png), [Resume](../output/qa/rc-026/integration/live-resumed-450x1000.png) | [Map](../output/qa/rc-026/integration/live-map-360x640.png), [Resume](../output/qa/rc-026/integration/live-resumed-360x640.png) |
| Quit / exact replay | [Quit](../output/qa/rc-026/integration/quit-confirmation-450x1000.png), [replay](../output/qa/rc-026/integration/entry-replay-450x1000.png) | [Quit](../output/qa/rc-026/integration/quit-confirmation-360x640.png), [replay](../output/qa/rc-026/integration/entry-replay-360x640.png) |
| First result / full policy | [result](../output/qa/rc-026/integration/terminal-result-450x1000.png), [policy](../output/qa/rc-026/integration/terminal-result-policy-450x1000.png) | [result](../output/qa/rc-026/integration/terminal-result-360x640.png), [policy](../output/qa/rc-026/integration/terminal-result-policy-360x640.png) |
| Return to Map | [image](../output/qa/rc-026/integration/returned-map-450x1000.png) | [image](../output/qa/rc-026/integration/returned-map-360x640.png) |
| Second entry | [image](../output/qa/rc-026/integration/second-entry-450x1000.png) | [image](../output/qa/rc-026/integration/second-entry-360x640.png) |
| Second result / Map | [result](../output/qa/rc-026/integration/second-result-450x1000.png), [Map](../output/qa/rc-026/integration/second-map-450x1000.png) | [result](../output/qa/rc-026/integration/second-result-360x640.png), [Map](../output/qa/rc-026/integration/second-map-360x640.png) |

## Reproduce verification and package audit

Commands executed from the workspace:

```powershell
$engine = 'C:\Dev\RuneCast\.tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe'
$py = 'C:\Users\nguye\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
$env:APPDATA = 'C:\Dev\RuneCast\output\qa\rc-026\appdata'
$env:LOCALAPPDATA = 'C:\Dev\RuneCast\output\qa\rc-026\localappdata'
& $engine --headless --path . --log-file C:/Dev/RuneCast/output/qa/rc-026-core-tests.log --script res://tests/test_runner.gd
& $engine --headless --path . --log-file C:/Dev/RuneCast/output/qa/rc-026/ui-tests.log --script res://tests/ui_smoke.gd
& $engine --headless --path . --log-file C:/Dev/RuneCast/output/qa/rc-026/shell-tests.log --script res://tests/application_shell_tests.gd -- --qa-output=res://output/qa/rc-026
& $engine --headless --path . --log-file C:/Dev/RuneCast/output/qa/rc-026/integration-tests.log --script res://tests/encounter_integration_runner.gd
& $engine --headless --path . --audio-driver Dummy --log-file C:/Dev/RuneCast/output/qa/rc-026/audio-final.log --script res://output/qa/rc-026/audio_runner.gd
& $engine --headless --path . --audio-driver Dummy --log-file C:/Dev/RuneCast/output/qa/rc-026/presentation-final.log --script res://tests/rc020_presentation_runner.gd
Start-Process -FilePath $engine -ArgumentList @('--path','C:/Dev/RuneCast','--audio-driver','Dummy','--log-file','C:/Dev/RuneCast/output/qa/rc-026/integration-capture.log','--script','res://tests/encounter_integration_runner.gd','--','--capture-integration') -WindowStyle Hidden -Wait
Start-Process -FilePath $engine -ArgumentList @('--path','C:/Dev/RuneCast','--audio-driver','Dummy','--log-file','C:/Dev/RuneCast/output/qa/rc-026/navigation-capture.log','--script','res://tests/navigation_bar_capture.gd','--','--qa-output=res://output/qa/rc-026/navigation') -WindowStyle Hidden -Wait
Start-Process -FilePath $engine -ArgumentList @('--path','C:/Dev/RuneCast','--audio-driver','Dummy','--log-file','C:/Dev/RuneCast/output/qa/rc-026/reference-capture.log','--script','res://tests/ui_reference_match_capture.gd','--','--capture-directory=res://output/qa/rc-026/combat-reference') -WindowStyle Hidden -Wait
& $engine --headless --path . --export-pack iOS builds/rc-026-resources/RuneCast.pck --log-file C:/Dev/RuneCast/output/qa/rc-026/resources/export-engine.log
& $py tools/verify_ios_resources.py --pack builds/rc-026-resources/RuneCast.pck --engine $engine --report output/qa/rc-026/resources/resource-audit.json
$env:RUNECAST_RESOURCE_TEST_PACK = 'C:\Dev\RuneCast\builds\rc-026-resources\RuneCast.pck'
& $py -m unittest discover -s tests -p 'test_ios_*.py' -v
```

The task-local audio runner is the existing audio suite with only its JSON output destination changed, preserving earlier evidence. The reference runner intentionally exits with the recorded baseline failures.

Fresh pack: `builds/rc-026-resources/RuneCast.pck`, **12,259,176 bytes**, **365 entries**, SHA-256 **`9ae0681653b07357780dd5d86ecab202c5bc7918aa7210c49b395f1d0da8d110`**. [Source hashes](../output/qa/rc-026/resources/source-manifest.json) tie it to the final runtime. The probe decodes the actual payload from an empty project without a workspace fallback and checks the current 82-pixel navigation, corrected corners, navy modal surface and resolver. The existing SDK fallback notice is informational.

The explicit runtime inventory now requires `encounter_resolver.gd` and the current `combat_surface.gd`. Existing export exclusion rules keep tests, helper factories, legal-move player, capture tools, development adapters and output evidence outside production. Existing supported JSON definitions remain included for resolver/compatibility use; no new fixture JSON or runtime cheat was added. This was resource export only: no native build, SDK install, signing or RC-022 work.

## Remaining owners

RC-026 is complete for this bounded integration. **RC-024A** remains independently ready and is the next progression contract decision; **RC-033** remains ready for the enemy action/intent framework. **RC-027 now has its RC-026 prerequisite, but still requires RC-024A**. RC-028 retains its RC-027 dependency and owns persistent recovery. RC-029/030 own shop/event/recovery handlers, RC-034 the missing enemies and final encounter definitions, RC-036 pacing/economy, and RC-032 complete end-to-end results/navigation. No acceptance status for RC-022, RC-023, music, permanent progression or physical devices changes here.
