# RC-025 — Branching routes and the Map

**October 25 RC-034 integration:** ordinary New Run now binds all real production enemies, including both normal/board alternatives, depth-six Shadeling and separate final Bell Keeper. Exact registration rejects mismatches before entry. Genuine older all-planned routes validate original history/signatures before narrow reference hydration; graph/visit identities, edges, choices and RNG remain. Terminal old graphs remain untouched. [Current route behavior, compatibility and real playthroughs](rc-034-verification.md). The original structural/missing-content evidence below remains historical.

**October 23 persistence update:** [RC-028](rc-028-verification.md) now persists the authoritative raw graph, visit history, choice locks and random state. The snapshots described below remain presentation APIs, not restoration formats. Original structural evidence is retained.

**October 21 superseding integration:** [RC-026](rc-026-verification.md) adds real handlers for supported validated encounters, transactional scene entry and visit-scoped result/replay ownership. Missing production opening enemies and service rooms remain explanatory and non-mutating. Two genuine Wisp victories are demonstrated only in its excluded, reward-free integration fixture. The original structural evidence below is retained.

October 20, 2026 (Australia/Sydney). **Complete for route topology, navigation state/interfaces and live Map, with structural traversal verified through isolated test adapters.** This is not a complete playable tower. RC-024 permanent-progression integration remains pending RC-024A, RC-022 remains deferred, RC-023 remains pending human/device acceptance, and both music tracks remain unavailable.

**October 21 visual correction:** the current Map follows the approved composition with generated parchment, live node decoration and framed Menu/Map/Guide/Sound navigation. [Reference comparisons and fresh validation](rc-025-map-match-verification.md) supersede the initial visual captures below; the original implementation evidence is retained.

One initial read-only `git status --short` was mistakenly dispatched in parallel with reading the attached request, before its prohibition was known. It produced no changes. No subsequent Git commands, worktree actions or intentional Git-metadata changes were performed.

## Launch and inspect

From `C:\Dev\RuneCast`:

```powershell
.\tools\godot.ps1 -Action run
```

Home → **New Run** opens a fresh route with 30/30 health, zero Gold, no relics, the accepted eight owned cards and zero visits. Tap any node to inspect. An available entry offers **Enter → confirmation**; confirming currently reports unavailable room content and leaves the route unchanged. Close the sheet to return to Map, then Close to Home. **Continue** reopens the same graph, content references and choices. New Run asks before replacing the session; Cancel preserves it.

To play the retained encounter and exercise Map over actual Combat:

```powershell
.\tools\godot.ps1 -Action run -Encounter res://data/production_encounter.json
```

Place a connector or select a card, scroll to the bottom navigation, then tap **Map**. It explicitly identifies the standalone Shadeling encounter, without invented tower visits. **Resume room / Close** returns to the same scene, controller, model, card identities, preparation, selection and scroll. Busy presentation blocks Map opening. Existing explicit `--encounter`, `--board-example`, `--experiment` and `--capture` launch paths remain separate from route creation.

The retained run-managed battle boundary still supports Menu Resume and confirmed Quit → session Continue entry replay. Automated shell tests inject that standalone boundary directly; normal New Run no longer enters it. RC-026 will connect it to selected route encounters. Closing the process loses the session. No route/run data is written into sound settings.

## Model, schema and ownership

`scripts/core/run_state.gd` owns `scripts/core/route_state.gd`. `RunState.new(validated_setup, seed, true)` creates a route; the existing two-argument constructor remains an explicitly standalone encounter. Construction generates and validates the graph once.

| Field / identity | Contract |
| --- | --- |
| Version / route ID | `rc025_route_v1`; deterministic `rc025_route_v1-<seed>`. Route and node IDs are scoped by the distinct session `run_id`; equal seeds reproduce the graph without sharing session ownership. |
| Route RNG | Dedicated `RandomNumberGenerator`, `seed XOR 0x52435254`, bounded seed 0–2147483647. Store its post-generation `route_rng_state`; do not advance card, endpoint or kit streams. |
| Graph | `path_length: 9`, explicit `entry_node_ids`, `nodes` and `edges {from,to}`. Thirteen authored alternatives form eight legal paths. |
| Node | Stable `id`, depth/lane, `next_ids`, `room_id`/`room_type`, `room_reference`, `enemy_id`, `board_id`, `encounter_id`, `encounter_role`, display name and content availability. |
| Visit | Run/route/node identity plus unique `visit_id`, status, outcome, pending and completed choice IDs. Visit identity, not encounter definition, owns completion. |
| Detached presentation | `RunState.snapshot().route` / `route_snapshot()` include current/available/visited/locked node states/reasons, visits, active visit, completion count, entered count and revision. Nested data is copied. |

`visit_count` counts accepted room entries, including the active visit; `completed_count` and `visited_node_ids` count only completed rooms. Depth displays entered visits, so a new route starts at zero. Inspection, selection, cancellation, failed entry and reopening do not mutate the graph or any random stream.

Graph validation rejects invalid versions/seeds, duplicate or empty IDs, unknown references, malformed edges/entries, self-links, backtracking, cycles, unreachable nodes, nonterminal dead ends and paths outside the nine-visit contract. All edges advance exactly one depth. Every path reaches the sole ninth-depth guardian and includes Shadeling and recovery. Unchosen branches become unavailable; completed rooms cannot replay.

## Provisional content contract

**normal → event → normal → normal → normal/elite choice → Shadeling boss → shop → recovery → guardian**

The boss replaces an earlier ordinary normal visit. It does not add a tenth mandatory room. Initial choices differ by planned normal actor/board and lead to seeded event alternatives; later alternatives reconverge, including the optional normal/elite choice.

Six room families remain: `room_normal`, `room_elite`, `room_event`, `room_shop`, `room_recovery`, `room_guardian`. Shadeling occupies the existing battle-room family `room_normal` with explicit `encounter_role: boss`; the screen displays **Boss**, not an ordinary normal encounter. This is a structural dispatch contract, not inheritance of normal rewards. The designated node retains `shadeling`, `training_shadeling` and `board_training`. Only `wickling` / `stone_sentinel` belong to ordinary pools. `chain_warden` is elite and `bell_keeper` is the separate guardian.

Future battle definitions are not fabricated: their `encounter_id` is empty while planned actor/board references remain stable. Event references use the four existing roster IDs. RC-034 supplies final encounters; RC-036 settles placement, Gold, rewards and balance. No permanent boss reward, healing, dodge, new phase or final Gold total is implemented.

## Entry and completion interfaces

| Interface | Behavior |
| --- | --- |
| `inspect_node(node_id)` | Detached information only, including ineligibility reason. |
| `request_room_entry(node_id)` | Checks availability and returns `{run_id, route_id, node_id, revision}` token without mutation. |
| `confirm_room_entry(token, handler)` | Revalidates the run/route/revision and connected node; asks a handler to prepare detached node/visit data; commits one active visit only after successful preparation. Reentrant, stale, duplicate and failed entry reject. The production shell supplies no unfinished handler, so it reports unavailable without consuming selection. |
| `resolve_room(run_id, node_id, visit_id, outcome, pending_choices)` | Accepts one matching active visit outcome (`completed` or `defeat`). Required choice IDs keep the room current and successors locked. Defeat ends continuation without unlocking or declaring victory. |
| `complete_room_choice(run_id, node_id, visit_id, choice_id)` | Accepts each required choice once. The final choice commits the visit and unlocks only its connected successors; guardian completion alone sets `tower_completed`. No choice grants content/resources itself. |

The shell owns the current Map instance and confirmation, binds callbacks to generations and clears pending entry on cancellation. Inspection is view-local. Route state remains authoritative in the model. Unsupported entry errors do not replace the run, consume the node or reroll anything.

Standalone battle `encounter_won` remains a distinct terminal fixture status. General combat initialization, terminal handoff into route completion, health/card/RNG transfer and replay routing are RC-026 integration work. The callable preparation interface is exercised only with adapters under `tests/`; none is reachable as a normal-game “complete room” action.

## Map, input and audio

`route_map.gd` uses the delivered theme, wordmark, fonts, frames and navigation assets over a separate generated blank parchment with crypt side architecture. `route_map_canvas.gd` draws live connections, `route_map_symbol.gd` supplies distinct room symbols, and `route_map_node.gd` draws rings, completed checks and the turquoise current star/ribbon. Available nodes/connections are gold; unchosen paths are subdued. `route_map_chrome.gd` reuses clean stone and bottom candles from the existing Combat backdrop and draws small ornaments. The title and subtitle sit inside the paper. There is no encounter legend strip or repeated ordinary-node text.

The route scrolls where needed while top Close, live health/Gold/depth and Menu/Map/Guide/Sound navigation remain reachable. Inspection bodies scroll above fixed Enter/Resume/Back actions. Locked nodes remain enabled for inspection despite unavailable styling. Menu retains the same Map and scroll; shared Options returns through Menu, and Quit to Home preserves the session. Store remains unavailable. Guide opens the route explanation, and the current node sheet provides Resume room. Closing a sheet returns to the same Map; closing Map returns to its caller.

Map overlays keep Combat alive beneath an opaque screen. `set_shell_modal()` blocks underlying edit paths and releases pointer holds. Map owns its touch router; the shell confirmation, Menu or Options owns input while above it. Android Back deduplication dismisses one top layer. Deferred Map deletion avoids removing children during a notification broadcast; generation guards also reject stale Menu and Sound callbacks. Combat-origin Menu returns to the existing Combat menu.

No Map audio coordinator or additional playback listener is created. Combat's existing coordinator/player retains its identity and ambience start count. Home-origin Map uses Home's existing context, with no crypt ambience or substitute music. Sound toggles the owner's existing preference; opening/closing Map itself leaves settings unchanged.

The [October 21 correction](rc-025-map-match-verification.md) adds reusable generated parchment and live procedural Map decoration following the approved direction. RC-041/042 retain remaining content art and final integration/acceptance. The approved reference is neither shipped as a flattened interface nor cropped into a runtime background. Home and Combat layouts were not redesigned.

## Verification

The following table and captures retain the original October 20 evidence. Current validation after the visual correction is in [the October 21 verification](rc-025-map-match-verification.md). Pinned Godot **4.7.2.stable.official.ed1daf0bf**, Windows Compatibility renderer and existing Python tooling. Test settings/cache paths are task-local. Actual assertion totals and engine diagnostics were read.

| Automated coverage | Final result and evidence |
| --- | --- |
| Full core | **2,223 checks, 0 failures** — [log](../output/qa/rc-025/core-final/test.log). Includes 336 new route checks: 64 seeds/every legal path, malformed graph/reference cases, RNG isolation, snapshots, entry/visit/choice identities and locks. |
| Full existing UI | **1,171 checks, 0 failures** — [log](../output/qa/rc-025/ui-final/smoke.log). Updated old Map-dialog expectations to live Map; preserved alternate/malformed fixture navigation, busy guards and Back. Deliberate missing/invalid-content diagnostics are negative fixtures. |
| Application shell | **84 checks, 0 failures** — [log](../output/qa/rc-025/shell-tests.log), [assertions](../output/qa/rc-025/shell-tests.json). New Run/Continue/replacement/cancellation, pending entry, native finger inspection/drag, stale callbacks, actual Combat round trips and audio identity, preparation/selection/scroll, input locks, Quit/replay and defeat. |
| Audio | **428 checks, 0 failures** — [log](../output/qa/rc-025/audio-tests.log). Existing settings/playback/lifetime suite. |
| Presentation | **31 checks, 0 failures** — [log](../output/qa/rc-025/presentation-tests.log). Existing terminal/presentation/audio boundaries. |
| Rendered Map and battle scenes | **204 checks, 0 failures**, **48 PNGs** at 720×1600, 450×1000 and 360×640 — [assertions](../output/qa/rc-025/screenshots/results.json), [log](../output/qa/rc-025/map-capture.log). |
| Shell compatibility layouts | **81 checks, 0 failures**, **24 PNGs** — [assertions](../output/qa/rc-025/shell-screenshots/results.json), [log](../output/qa/rc-025/shell-capture.log). Home, Options, standalone battle replay/quit and replacement layouts remain reachable. |
| Production resource-only pack | **361 policy/integrity checks + 70 exact-payload desktop decode checks, 0 failures** — [audit](../output/qa/rc-025/resources/resource-audit.json), [decode log](../output/qa/rc-025/resources/ios-resource-probe.log). |
| Existing Python resource/workflow/transfer tests | **31 tests passed** — [log](../output/qa/rc-025/resources/tool-tests.txt). Local fixtures/resource audits only; no native setup/build. |

Automated structural traversal uses accepting test adapters to enter and complete all eight paths for four sample seeds, including every room type and guardian. It does not simulate real encounter difficulty, rewards, recovery services or a human full run. Production-scene observations exercise real Home/Map controls and the retained playable Combat model through scripted commands. Visual review inspects actual rendered screenshots; no physical device, human full-run or final art acceptance is claimed.

Resolved diagnostics included synchronous Map removal during Android Back, alternate standalone enemy labelling, an initial scroll offset applied before container layout, and overlapping role/state labels. Final visual review also found an inspection scroll offset hiding the first line when a sheet reopened; the reproduced regression is retained in [the pre-fix log](../output/qa/rc-025/map-capture-scroll-before.log). New node/help inspections reset their body scroll while the Map's route scroll remains intact. Old tests expecting the placeholder dialog were updated. Repeated pending-entry errors now replace their prior display instead of accumulating. Final logs distinguish intentionally invalid content from unexpected engine errors.

### Captures reviewed

| State | Evidence |
| --- | --- |
| Fresh route, zero progress | [720×1600](../output/qa/rc-025/screenshots/fresh-route-720x1600.png), [360×640](../output/qa/rc-025/screenshots/fresh-route-360x640.png) |
| Inspection and entry confirmation | [inspection](../output/qa/rc-025/screenshots/node-inspection-360x640.png), [confirmation](../output/qa/rc-025/screenshots/entry-confirmation-360x640.png), [pending availability](../output/qa/rc-025/screenshots/room-pending-360x640.png) |
| Test-only current / visited / locked | [Map](../output/qa/rc-025/screenshots/fixture-current-visited-locked-450x1000.png), [current sheet](../output/qa/rc-025/screenshots/fixture-current-inspection-360x640.png), [visited sheet](../output/qa/rc-025/screenshots/fixture-visited-inspection-360x640.png), [locked sheet](../output/qa/rc-025/screenshots/fixture-locked-inspection-360x640.png) |
| Test-only completed / available boss | [Map](../output/qa/rc-025/screenshots/fixture-completed-available-450x1000.png) |
| Shadeling's distinct boss role | [boss inspection](../output/qa/rc-025/screenshots/fixture-boss-inspection-360x640.png) |
| Actual prepared Combat, Map, Resume | [prepared](../output/qa/rc-025/screenshots/battle-prepared-360x640.png), [Map](../output/qa/rc-025/screenshots/battle-map-360x640.png), [Resume sheet](../output/qa/rc-025/screenshots/battle-resume-inspection-360x640.png), [resumed](../output/qa/rc-025/screenshots/battle-resumed-360x640.png) |
| Narrow scrolling, both ends | [entry end](../output/qa/rc-025/screenshots/route-entry-end-360x640.png), [guardian end](../output/qa/rc-025/screenshots/route-guardian-end-360x640.png) |

### Reproduce local validation

```powershell
$engine = 'C:\Dev\RuneCast\.tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe'
$env:APPDATA = 'C:\Dev\RuneCast\output\qa\rc-025\recheck-appdata'
$env:LOCALAPPDATA = 'C:\Dev\RuneCast\output\qa\rc-025\recheck-localappdata'
.\tools\godot.ps1 -Action test -LogDirectory output/qa/rc-025/core-final
.\tools\godot.ps1 -Action smoke -LogDirectory output/qa/rc-025/ui-final
& $engine --headless --path . --log-file C:/Dev/RuneCast/output/qa/rc-025/shell-tests.log --script res://tests/application_shell_tests.gd
& $engine --headless --path . --log-file C:/Dev/RuneCast/output/qa/rc-025/audio-tests.log --script res://tests/audio_playback_runner.gd
& $engine --headless --path . --log-file C:/Dev/RuneCast/output/qa/rc-025/presentation-tests.log --script res://tests/rc020_presentation_runner.gd
& $engine --path . --log-file C:/Dev/RuneCast/output/qa/rc-025/map-capture.log --script res://tests/route_map_capture.gd
& $engine --path . --log-file C:/Dev/RuneCast/output/qa/rc-025/shell-capture.log --script res://tests/application_shell_capture.gd
```

### Production resource policy

All four new runtime scripts (`route_state`, `route_map`, `route_map_canvas`, `route_map_symbol`) join the explicit required application-resource inventory and existing script resource scan. The existing Android/iOS presets include these resources; no new JSON, remote dependency or save file is introduced. `tests/`, `tools/`, `output/` and development adapters remain excluded from production exports.

The final **resource-only** PCK is `builds/rc-025-resources/RuneCast.pck`: **10,372,892 bytes**, **348 entries**, SHA-256 **`571dc09cfed0103b2b981fe07ac9daa76072dc83c5b5b975eb7fe82da46f6de9`**. Its actual packaged resources were decoded from an empty project with no workspace fallback. This is neither a native build nor evidence of Android/iOS/device acceptance. The export log contains the existing SDK fallback informational message, with no engine errors.

```powershell
$py = 'C:\Users\nguye\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
& $engine --headless --path . --export-pack iOS builds/rc-025-resources/RuneCast.pck --log-file C:/Dev/RuneCast/output/qa/rc-025/resources/export-engine.log
& $py tools/verify_ios_resources.py --pack builds/rc-025-resources/RuneCast.pck --engine $engine --report output/qa/rc-025/resources/resource-audit.json
$env:RUNECAST_RESOURCE_TEST_PACK = 'C:\Dev\RuneCast\builds\rc-025-resources\RuneCast.pck'
& $py -m unittest discover -s tests -p 'test_ios_*.py' -v
```

## Integration handoff

RC-026 can use the guarded room token/visit boundary to initialize selected battle content, carry HP/card/RNG state, commit terminal outcomes and return to Map. It must supply real battle handlers and attach their scene only after successful entry preparation. Repeated encounter content must still complete by visit identity. Required rewards remain locked until RC-027 completes their choices.

RC-028 owns disk persistence/recovery/migration; these detached session snapshots are not a competing save format. RC-029/030 own shop, recovery and event handlers. RC-024A/029A own permanent progression and the separate menu Store; route shops do not implement that Store. RC-034/036 own final encounter content/placement/economy. RC-041/042 own finished art/integration. These remaining tasks do not block the delivered structural Map scope, and are not marked complete by its test traversal.
