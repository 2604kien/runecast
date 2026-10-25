# RC-028 — Versioned local save and resume

October 23, 2026 (Australia/Sydney). RC-028 implements persistence for the approved run/rune contract. One local run and permanent definition unlocks survive application restarts. Missing production enemies, services and the separate final guardian still prevent a complete production tower. Store currency/payment, purchases, catalogue, accounts, perks and other item families remain unresolved under RC-024A; this work invents no save rules for them.

## Player behavior and manual restart checks

Normal launch remains `C:\Dev\RuneCast\tools\godot.ps1 -Action run`. With no save, Home explains why Continue is unavailable. New Run saves the original eight-card, 30/30, zero-Gold/no-relic start and its unvisited route before opening Map. Close and relaunch the application; Continue opens the same route. Missing opening content remains unavailable without consuming a visit.

For actual combat, rewards and restart inspection, use the separate excluded RC-028 manual fixture:

```powershell
Set-Location -LiteralPath 'C:\Dev\RuneCast'
$rc028Engine = 'C:\Dev\RuneCast\.tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe'
& $rc028Engine --path . --script res://tests/persistence_manual.gd
```

This fixture uses the existing two Wisp encounters and the explicitly labelled reward-enabled test route: fixed seed 42, three distinct run-card offers, optional Choose/Skip and 7 configured Gold. It does not manufacture earlier victories, implement missing enemies or alter the production route. Its stable save is `C:\Dev\RuneCast\output\qa\rc-028\manual\runecast-save.json`; its settings are beside it in `settings.cfg`. The RC-026 reward-free fixture and RC-027 reward-enabled fixture remain separate.

1. Choose New Run, enter a supported node and play several actions, including Conjure. Close the process and repeat the same command. Continue replays the exact saved entry: same run/route/node/visit, selected enemy/board/configuration, entry health, permanent UIDs, allocator and card/endpoint/kit streams. Partial damage, board preparation and generated cards from the interrupted attempt do not carry.
2. During a surviving battle, Menu → Resume Combat and Map-over-Combat → Resume retain the same scene/controller/model and current preparation. They do not reload the entry. Confirmed Quit to Home deliberately returns to entry replay; it does not abandon the run.
3. Win, close before acknowledging the result and relaunch. Continue opens the committed result without replaying combat. Acknowledge while leaving rewards pending, close and relaunch: Continue opens the retained offering. Resolve rune and Gold in either order, restarting between claims; the second component remains pending and the first cannot be granted again. Skip adds no owned instance. The next supported encounter contains an awarded UID exactly once.
4. New Run asks for replacement confirmation. Cancel preserves the previous run. A failed replacement save also preserves it. Successful replacement keeps permanent unlocks and Options, starts the unchanged eight-card collection and assigns a new run identity.
5. For a recovery exercise, first make at least two successful fixture checkpoints so `.previous` exists. Close the process, copy the fixture's current file aside, then deliberately truncate **only that isolated fixture file**. Relaunch: Continue and New Run are unavailable; Save recovery explains the error. Recover previous save is offered only if the previous copy passes all validators. The original damaged bytes are retained in a distinct `.unreadable-<random>` file. Without a validated previous copy, the UI offers Retry loading after external repair and preserves the file.

Every save failure says **Progress was not saved**, offers **Retry saving** for the same staged action, and retains the previous checkpoint. Returning Home retains the pending in-memory retry; closing the process loses only that uncommitted action. If another writer changed the slot, explicit **Reload saved progress** discards the stale candidate and loads the newer state. Old receipts and restored outcomes never replay acquisition or result audio.

## Location and version-one contracts

Production uses `user://runecast-save.json`, resolved with `ProjectSettings.globalize_path`. Godot owns the platform-specific writable directory. On this Windows setup it resolves under `%APPDATA%\Godot\app_userdata\Rune Cast`. The pinned engine was verified to honor the tests' redirected APPDATA, resolving to `C:\Dev\RuneCast\output\qa\rc-028\regression\appdata\Godot\app_userdata\Rune Cast` ([probe](../output/qa/rc-028/userdata-probe.log)). Use `OS.get_user_data_dir()` or the injected path when diagnosing a particular launch. Settings retain the existing independent ConfigFile location and are never embedded in this save.

`application_shell.save_path` is injectable before `_ready`; tests use task-local paths. Trusted test code may also inject `persistence_context`; production uses an empty context. Save data cannot select a test policy, callback, object, script or resource path.

| Contract | Authoritative contents |
| --- | --- |
| `LocalSave` envelope `rc028_local_v1` | Exact decimal revision string, schema ID, UTF-8 JSON body string and SHA-256 of those exact body bytes. File limit 4 MiB; model nesting limit 64. |
| Integer encoding | Every native integer in the body is tagged as `{ "__rc_i64__": "<canonical signed decimal>" }`. Signed 64-bit extremes, large seeds, RNG states, UIDs and counters never pass through a JSON floating-point number. Invalid/overflowing/noncanonical tags reject. StringName keys are normalized to strings. |
| Profile v1 | Explicit definition-unlock ownership, policy `rc027_owner_2026_10_22`, and unique implemented unlocked IDs. Production requires all four initial definitions; malformed/unknown/temporary/duplicate IDs reject rather than being filtered or defaulted. |
| Run v1 | Collision-resistant 128-bit random run identity, nonnegative int64 seed, phase, selected encounter/board IDs and registered-content signature; committed HP/max HP, Gold, owned `{id, uid}` instances, `next_uid`, three battle streams and independent reward stream; exact entry checkpoint; battle generation/candidate counters; completed encounters, pending result and retained reward records. |
| Route v1 | Raw versioned graph, graph-generation RNG state, nodes/edges, ordered visits, active visit, last completed node, revision and required/completed choices. Derived inspection/presentation fields are not the restore format. |
| Reward records | Visit/choice identity, policy/kind, original eligible/offered IDs, rune/Gold/unlock component resolution, selected ID/UID, receipts and transaction IDs. Exhausted milestones retain an explicit no-award receipt. |

`RunState.snapshot()` and `RouteState.snapshot()` remain detached presentation APIs. `export_save()` deliberately reads committed values; it never takes mid-battle HP, allocator or random streams from the live snapshot. Temporary-generated UID gaps carry at completed outcome boundaries. A saved battle phase becomes `replay_pending` without creating a replacement Combat model until Continue prepares it.

Restore constructs empty owners, validates all structure and cross-owner invariants, resolves fixed registered content IDs, and only then publishes owners. It neither regenerates the route nor draws offers, reallocates owned cards or reruns transactions. Content signatures bind selected configuration; unsupported or changed content requires an explicit future compatibility decision. Current relic references must be empty because no implemented relic contract exists. Generic unsupported service-room states are rejected in production.

Validation checks starter conservation, unique UIDs below the allocator, route connectivity/identity/revision/history, selected-content ownership, entry resources, outcome/health/acknowledgement, required-choice locks, historical eligible pools, receipt identities/components, total configured Gold and awarded instances. Production cannot restore the development route/reward policies. Fixture capabilities are supplied by excluded test code, never deserialized.

This is the **first** local save schema. No older run/profile format shipped, so no migration from a fictional predecessor is claimed or implemented. Unknown envelope/model/policy/route versions and incompatible content are rejected with useful status. Future supported migrations must validate an old schema, transform a detached candidate and use the same durable commit/recovery path; they must preserve original evidence until success.

## Transaction ordering and actual durability

The shell stages a detached run/route/profile clone while retaining the existing live Combat reference where necessary. Scene entry follows **prepare → attach hidden/inert scene → commit candidate model → validate/write candidate file → publish owners → activate scene**. Failed construction/attachment does not consume a visit. A failed disk write disposes only the staged scene; Retry retains the exact candidate and attaches it again before saving.

New Run, selected entry/replay, terminal outcome plus pending rewards, Choose/Skip/Gold/unlock, exhausted milestones, required-choice completion, result acknowledgement and confirmed battle Quit all use the same boundary. Reward card grant, allocator, receipt, route advancement and profile unlock are in one payload. Result acknowledgement stays independent of reward completion. Terminal records remain nonplayable after acknowledgement; a pending terminal result may be reviewed without reopening completed rewards.

`clone_for_transaction`, `publish_transaction` and the shell's `_commit_transaction` form the bounded integration seam for later approved systems. Future room/item owners must extend validated model schemas and stage all participating owners before using this seam. A fallible write after mutating the live route/profile is not permitted.

The store:

1. Checks the expected revision and observed current-file hash, guards reentrancy, and acquires an atomic directory lock shared by cooperating processes. A dead recorded process lock can be reclaimed; a live or ownerless lock is reported, never guessed safe.
2. Writes `.temporary`, checks write/flush errors, closes and reads it back byte for byte, then validates the envelope and models again. Godot's `close()` has no returned error, so closed-file readback is the available verification.
3. Copies the still-current valid file through `.previous.next`, verifies it, and safely promotes it to `.previous`. Stale hash checks prevent an observed older revision from overwriting a newer committed state.
4. Renames the old target to `.replacing`, promotes the complete candidate and rolls back the old target if promotion fails. The validated previous copy remains available through an interrupted two-rename window. Only successful promotion advances the store revision and allows model/UI/audio success.

Recovery revalidates `.previous` under the writer lock, preserves the unreadable current file byte for byte, writes the exact validated previous bytes to staging, revalidates the candidate and explicitly promotes it. It never promotes arbitrary `.temporary`/`.replacing` files or silently recovers/start-defaults on launch.

These guarantees cover checked I/O failures, competing cooperating writers and process interruption with an old-or-new coherent checkpoint or explicit validated recovery. `FileAccess.flush`, close/readback and same-directory rename do **not** expose a directory-fsync or storage-hardware power-loss guarantee. Device shutdown/power-loss reliability remains RC-047. An interruption before lock-owner metadata is written can leave an ownerless `.lock` directory; preserve/inspect it externally with all instances closed before removing that lock. It contains no player progress.

## Verification and captures

Pinned Godot **4.7.2.stable.official.ed1daf0bf**, Windows Compatibility renderer. Tests inject save/settings paths and isolate APPDATA/LOCALAPPDATA; normal user data is not used. Dummy audio is used for headless tests. Logs are checked for script/engine errors as well as assertion counts.

The reproducible commands are:

```powershell
$rc028Engine = 'C:\Dev\RuneCast\.tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe'
$env:APPDATA = 'C:\Dev\RuneCast\output\qa\rc-028\test-user'
$env:LOCALAPPDATA = 'C:\Dev\RuneCast\output\qa\rc-028\test-cache'
& $rc028Engine --headless --path . --audio-driver Dummy --script res://tests/local_save_runner.gd
& $rc028Engine --headless --path . --audio-driver Dummy --script res://tests/save_model_runner.gd
& $rc028Engine --headless --path . --audio-driver Dummy --script res://tests/persistence_audio_runner.gd
& $rc028Engine --headless --path . --audio-driver Dummy --script res://tests/persistence_shell_runner.gd
& 'C:\Users\nguye\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' tools/verify_persistence.py
```

| Coverage | Final result / evidence |
| --- | --- |
| Fresh OS-process restart and failed-write restart/retry | **625 checks, 0 failures across 105 launches**. Production route, exact interrupted entry after ordinary played cards/temporaries/RNG, result before/after acknowledgement, both partial-claim orders, Choose/Skip, exhausted milestone, fixture-only genuine unlock and New Run, awarded UID in next encounter, defeat and terminal guardian boundary. Five additional failure scenarios restart after write/flush/close/backup/replace failures and retry without a duplicate grant. [Per-process report/logs](../output/qa/rc-028/process/acb2790f29/results.json). |
| Profile without an active run | **18 additional checks, 0 failures across 4 launches**. Production and genuine-unlock fixture profiles are saved with an empty run record, loaded by another process and retained through New Run with the original eight-card starter. [Supplemental report](../output/qa/rc-028/process/profile-only-e20c27ac/results.json). The orchestrator includes these stages in future complete runs. |
| Explicit model restore/corruption | **1,582 checks, 0 failures**, including recursively substituted malformed field types, unsupported versions/content/policies, duplicate UIDs, bad visits/receipts, lost locks, historical pools, exact large counters and signed RNG states. [Log](../output/qa/rc-028/save-models.log). |
| Disk envelope/transaction/recovery | **53 checks, 0 failures**. Signed int64 extremes and seeds beyond 2^53, object/callback rejection, malformed tags/checksum/truncation/UTF-8, stale writers, process locks, reentrancy, five I/O failure points, rollback, invalid backup rejection, missing-primary recovery, original-byte preservation and previous-copy validation race. [Log](../output/qa/rc-028/local-save.log). |
| Shell persistence and UI | **77 headless / 133 rendered checks, 0 failures**. Replacement cancellation/all write failures; failed entry/restore attachment; no premature visits, grants or result/acquisition audio; stable retries; independent Gold/Choose/unlock/ack failures; stale/reentrant callbacks; Home/recovery and 14 configured-root captures. [Headless](../output/qa/rc-028/shell-persistence/results-headless.json), [rendered](../output/qa/rc-028/shell-persistence/results-capture.json). |
| Durable terminal audio | **10 checks, 0 failures**, covering suppression before save, once-only result cue, muted/interrupted/disposed owners and no delayed replay. [Log](../output/qa/rc-028/durable-audio.log). |
| Existing regressions | **2,354 core, 1,174 UI, 118 shell, 75 focused reward, 174 reward integration, 159 reward audio, 127 collection data, 32 collection lifecycle, 26 audio settings, 428 audio playback and 78 reward-free encounter integration checks**, all passing. [Final regression report](../output/qa/rc-028/regression/results-final.json). Two obsolete assertions were updated for persistent snapshots and expanded nonnegative int64 seeds; negative seed rejection and the unrelated geometry assertions remain. |
| Shared Menu | **143 checks, 0 failures** at configured 450×1000, 720×1600 and narrow 360×640 root windows; original instance/copy/caller and dimensions retained. [Report](../output/qa/rc-028/menu/results.json). |
| Absolute Combat reference | **257 checks, 15 documented baseline geometry failures**, unchanged; no weakened assertions/layout edits. [Report](../output/qa/rc-028/reference/results.json). |
| Fresh resource-only package | **388 policy/integrity, 109 isolated packaged-payload decode and 32 Python checks**, all passing. Explicit runtime inventory adds `local_save.gd`; test fixtures remain excluded. **196/196 current source hashes match**. [Audit](../output/qa/rc-028/resources/resource-audit.json), [source manifest](../output/qa/rc-028/resources/source-manifest.json), [Python log](../output/qa/rc-028/resources/python-tests.log). |

The package is `builds/rc-028-resources/RuneCast.pck`, **12,343,180 bytes / 375 entries**, SHA-256 `d69f68660b78e9f6452bc2e4a658846c96463536b1e877fb9c4e130473c77722`. It was freshly created with pinned Godot `--headless --path . --editor --export-pack iOS builds/rc-028-resources/RuneCast.pck`, then audited with `tools/verify_ios_resources.py --pack builds/rc-028-resources/RuneCast.pck --engine .tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe --report output/qa/rc-028/resources/resource-audit.json`. Python regressions used `unittest discover -s tests -p test_ios*.py` with `RUNECAST_RESOURCE_TEST_PACK` pointing at that exact pack. This exports resources only and does not build a native iOS app.

An initial rendered capture logged a shader-cache-directory setup error despite passing assertions. The isolated application-data directories were prepared and the final capture rerun passed **133/0 with no engine/script errors**. The interrupted two-rename recovery window is simulated by removing the current slot while retaining its validated previous copy. I/O fault injection and process restarts are verified; a physical power-loss/forced-device-kill campaign is not claimed. The initial aggregate regression report retains intermediate failures and one capture-wrapper timeout; the linked final report and direct pinned capture reruns supersede them.

The configured-root captures include [empty Home](../output/qa/rc-028/shell-persistence/home-empty-450x1000.png), [saved Home](../output/qa/rc-028/shell-persistence/home-saved-450x1000.png), [invalid Home](../output/qa/rc-028/shell-persistence/home-invalid-450x1000.png), [narrow recovery](../output/qa/rc-028/shell-persistence/recovery-confirmation-360x640.png), [failed save Retry](../output/qa/rc-028/shell-persistence/save-failure-450x1000.png) and [recovered Home](../output/qa/rc-028/shell-persistence/home-recovered-450x1000.png). Normal and narrow Home/recovery captures were visually inspected; modal copy scrolls and fixed actions remain inside their existing gold/navy panels.

The October 23 shared Menu remains the same `route_menu` instance for Map, run-managed Combat and Map-over-Combat, with identical body copy and literal **Resume Combat**. Its configured 450×1000 panel remains **402×660 at (24,170)**, with Menu-local font/scaling, 68 px action minima, 14 px gaps and existing padding. At 360×640, the existing letterboxing and locally fitted 249.6×528 panel remain. [Map Menu](../output/qa/rc-028/menu/map-menu-450x1000.png), [Combat Menu](../output/qa/rc-028/menu/combat-menu-450x1000.png), [narrow Map-over-Combat Menu](../output/qa/rc-028/menu/combat-map-menu-360x640.png), [143-check measurements](../output/qa/rc-028/menu/results.json). Global stretch, Combat artwork, integrated parchment and neutral 82 px navigation are unchanged.

The absolute Combat-reference suite retains its **15 documented baseline geometry failures**; no assertions were weakened or unrelated layout changed. See [current 257-check report](../output/qa/rc-028/reference/results.json). The task's initial command mistakenly included one read-only `git status` before the pasted no-Git restriction was read; this was disclosed immediately. No subsequent Git operations occurred.

## Remaining scope

All four current ownable definitions start unlocked; current production milestone pools are therefore exhausted. Genuine unlock verification uses explicitly narrowed isolated fixtures. Spark, Shield, Focus and Conjure remain the unchanged starter eligibility; Free Spark and unimplemented definitions remain ineligible. Unlocks change future eligibility, not starter composition. Gold is awarded only by an explicit configured rule.

RC-024A Store/item/account/currency/purchase decisions, RC-029/030 room handlers, RC-031 effects, RC-034/035 missing content and RC-036 economy remain open. The terminal guardian fixture tests the completion lock and retirement boundary, not a delivered guardian or complete production tower. Both music tracks remain pending, RC-022 remains deferred, and RC-023 human/device acceptance remains open. No native mobile build, SDK installation or signing was performed.
