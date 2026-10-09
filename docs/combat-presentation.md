# Combat and presentation contract

Implemented by RC-003/RC-004 and extended by RC-007's accepted production rules on October 9, 2026. The model/controller/presentation boundary and historical fixtures remain intact while normal gameplay follows the [production specification](production-rules-spec.md), with [validated setup](content-definitions.md). Production animation and run/save systems remain unimplemented.

**October 9, 2026 — RC-007 production:** snapshots expose detached `production` options, selected `kit` (`id`, `weight`, four `totals`), all four available quantities, `encounter_number` and `can_advance`. The view never selects kits or mutates stock. Rejected commands emit no accepted action/events; feedback may explain rejection. Legacy setup/snapshot shapes and experimental event ordering are preserved.

Production Cast records payment in `cast`, then one `damage` event even for zero. `amount` is requested damage; `applied` is actual clamped HP loss. If the enemy survives, player `shield` and enemy `retaliation` events follow; lethal spell damage suppresses both. Pass records `passed` then retaliation without spell/shield. Next come ascending-cell `effect_consumed` (each permanent UID to discard once), `temporary_expired` (deleted), and `board_piece_cleared` events. `turn_cleanup` describes old-hand discard/expiry and Undo clearing. A terminal action ends with `battle_ended`, with no next geometry, kit, energy refresh, hand or random consumption. Otherwise `endpoints_changed` follows endpoint mutation, `kit_changed` follows supply replacement, `turn_started` follows turn/energy refresh, then actual `reshuffled`/`card_drawn` events. Initial setup emits no action batch.

The configured production `next_encounter` command is guarded and argument-free. Its one `encounter_transition` event describes the committed new generation, carried HP/max, old/new content IDs, board, kit/stock, energy, turn, old zones, UID-sorted collection and shuffled new draw pile; actual opening draw events follow. Permanent identity/catalog/ownership checks finish before reconciliation. Action IDs remain monotonic across transition/Restart. A repeated/ineligible transition cannot reconcile twice.

Production Exact replay disposes the old controller under a replacement/teardown guard, then constructs a fresh controller/model from the cached validated initial setup. Old completions and cancellation reentry cannot mutate or unlock the new model. Ordinary Restart instead resets the existing model, increases its generation and continues all three RNG streams. Event playback consumes detached values only; it cannot apply damage, clear cards or reroll resources. Placeholder presentation remains immediate.

## Responsibilities and command flow

- `scripts/core/content_loader.gd` reads and validates definitions before battle construction. Failed validation returns diagnostics and no setup. It does not partially initialize combat or substitute training content.
- `scripts/core/combat.gd` is a `RefCounted` model. It receives validated setup and owns rules, authoritative state, RNG, editing/undo, payment, damage, cleanup and draws. It performs no file access and runs without scene nodes, audio, timers or animation. `circuit.gd` remains the pure circuit evaluator.
- `scripts/ui/combat_controller.gd` owns the model and a presentation adapter. It accepts commands, guards input, exposes detached snapshots, and coordinates presentation completion/cancellation. Its `is_busy()` is independent of the model's `playing`, `victory` and `defeat` state.
- `scripts/ui/combat_presentation.gd` supplies the immediate adapter: `present(result, completed)` immediately calls the completion callback. `cancel()` is currently a no-op. The controllable adapter in `tests/delayed_presentation.gd` retains batches/callbacks until explicitly completed; production has no artificial delay.
- `scripts/ui/main.gd`, attached to `scenes/main.tscn`, composes these objects and builds the existing controls. It owns selection/help, navigation and the existing sound preference/tone. `board_cell.gd` and `arena.gd` draw view data. The screen's `game` dictionary is a detached snapshot, not the combat model.

Player intent → guarded screen handler → `controller.command(name, arguments)` → `model.execute(name, arguments)` → final model state and detached result → presentation → completion → unlocked controls. The model has already finished before presentation starts. A consumer never pays, damages, expires or draws anything.

Construction is `ContentLoader.load_setup(path)` → check `ok` → `Combat.new(result.setup)` → `Controller.new(combat, presenter)`. An optional integer second argument to `Combat.new` overrides the configured seed for headless callers. The constructor copies the setup, and Reset rebuilds active collections from a separate retained copy. It preserves the selected configuration and continues the applicable RNG streams. The scene handles a failed load with visible diagnostics and disabled gameplay before constructing any model/controller.

| Command | Arguments | Presentation |
| --- | --- | --- |
| `cast`, `pass` | None | Ordered batch; waits for completion |
| `next_encounter` | None; requires eligible victory and validated successor | Ordered batch; waits for completion |
| `technique` | `uid` | Same ordered-batch/completion boundary |
| `place_wire` | `index`, `kind` (`straight`, `corner`, `split`, `join`, `erase`) | Immediate snapshot refresh |
| `place_rune` | `index`, `uid` | Immediate snapshot refresh |
| `rotate`, `flip` | `index` | Immediate snapshot refresh |
| `undo` | None | Immediate snapshot refresh |

The controller returns an acceptance boolean. All edits are guarded in controller logic as well as the view handlers; disabled buttons are only feedback. Restart is `controller.restart()`, with the cancellation policy below. Legacy model entry points preserve their original return types: bool for Cast, technique, placements and Rotate; void for Pass, Flip, Undo and Reset. New consumers use `execute` for results. Existing direct model fields remain available for compatibility and core test fixtures; views receive no model reference and must not use those fields for gameplay.

## Data ownership and result envelope

`snapshot()`, `execute()` and `last_result()` return deep copies of nested dictionaries/arrays. Recording an event also copies its payload immediately, before later cleanup/draws can change it. Mutating a view snapshot, a presenter batch, a prior result, or a copy from `last_result()` cannot change authoritative board/hand/catalog/piles or the model's retained outcome. Results remain unchanged after later commands and Reset. These values are detached, not language-enforced immutable objects: a consumer can edit its own copy.

A snapshot includes `encounter_id`, board, hand, draw/discard piles, catalog, encounter definition, health, energy, turn, battle state, `log_text`, intent, forecast, stock and undo count. RC-004 adds `encounter_content_id`, `encounter_title`, `encounter_help_text`, `player_max_hp`, `enemy_max_hp`, `enemy_name`, `energy_per_turn`, `draw_per_turn`, `owned_cards` and `stock_totals` for presentation. `stock` means available quantities; `stock_totals` includes installed pieces. Production exposes all four connector quantities and the metadata described above. The view binds labels, tooltips and help to these values.

Board cells are zero-based indices 0–15. Cards have definition `id` and instance `uid`; installed runes use `rune_id` and `uid`. The explicit historical training opening contains Free Spark UID 0; production allocates its eight permanent cards as UIDs 0–7. `player` and `enemy` identify the only two combatants. `encounter_content_id` (also `encounter.id`) is the stable content identity, such as `training_shadeling` or `dev_calibration`; `encounter_id` remains the generation counter. There is no speculative multi-target schema.

| Result field | Meaning |
| --- | --- |
| `accepted` | Whether this command applied its gameplay mutation |
| `command` | Requested command name |
| `encounter_id` | Model-local generation; increments on every Reset and accepted encounter transition |
| `action_id` | Model-local monotonically increasing accepted-command ID; continues across Reset, including edits; 0 for rejection |
| `turn` | Turn at command entry |
| `before`, `after` | Detached snapshots at entry and after complete resolution |
| `events` | Ordered consequence records; empty for rejected commands and preparation edits |

Every event adds `type`, zero-based contiguous `sequence`, `action_id` and `encounter_id`. Identify a card in a snapshot by generation plus UID and an event by action plus sequence within this model's lifetime. Transition events bridge the old/new generations while conserving permanent UIDs. These are presentation identities, not a persistent save/replay format or globally unique session IDs. Reset preserves RNG continuation while restarting card UIDs.

Invalid, unaffordable, missing-card, terminal and unknown commands have `accepted = false`, `action_id = 0` and no events, including in `last_result()`. They preserve board, cards, stats, history and RNG. Existing model error feedback can change `log_text`; it is not a gameplay effect. Selection/help is view-local and never writes that field. A command rejected while the controller is busy never reaches the model or emits a batch. Model Reset clears `last_result()` to an empty dictionary.

## Consequence order and fields

The following records describe operations at their actual resolution point. Snapshot data supplies additional stable rendering context, including pre-cleanup board pieces/UIDs and catalog styling.

| Type | Payload and position |
| --- | --- |
| `cast` | `source`, resolved `spell` (damage, shield, cost, active-cell traversal order, validity/message), `energy_before`, `energy_after`. Emitted after paying the cast cost. |
| `damage` | `source`, `target`, requested `amount`, actual clamped HP loss `applied`, `health_before`, `health_after`. One aggregate enemy damage event, even for zero damage. |
| `shield` | `target`, `amount`. Only if the enemy survives a Cast, including amount 0. Shield is transient protection, not stored HP or a next-turn resource. |
| `retaliation` | `source`, `target`, raw `incoming`, `blocked`, remaining damage `amount`, clamped HP loss `applied`, `health_before`, `health_after`. Follows shield on surviving Cast; follows `passed` on Pass with `blocked = 0`. |
| `passed` | `source`. Starts Pass; no Cast, spell payment, damage-to-enemy or shield event is synthesized. |
| `effect_consumed` | Production board `cell`, permanent `card`, `before`, `after: {}`, `from = board`, `to = discard`. Includes every installed permanent, powered or disconnected, on Cast and Pass. |
| `temporary_expired` | Board `cell`, full piece `before` (including rune ID/UID/rotation), `after: {}` in production. All installed temporaries, including disconnected ones, expire in ascending cell order. The historical training profile replaces them with wires. |
| `board_piece_cleared` | Production connector `cell`, full `before`, `after: {}`; stock is derived from current occupancy. Board events interleave by ascending cell, not by event type. |
| `turn_cleanup` | Permanent hand cards `discarded` and temporary hand cards `expired`, each in hand order; `hand_after = []`, `undo_cleared` count. Follows board cleanup. Historical baseline installed permanents remain installed. |
| `battle_ended` | `state` (`victory`/`defeat`), `player_hp`, `enemy_hp`. After cleanup, enemy death is checked first. No new turn or draw follows. |
| `turn_started` | `turn_before`, `turn_after`, `energy_before`, `energy_after`, next `intent`. Only if both combatants live, after cleanup. |
| `endpoints_changed` | Production `before`/`after` layouts with pair ID and Begin/End cell/rotation; emitted immediately after the selected endpoint mutation, before kit/energy refresh. |
| `kit_changed` | Production `before`/`after` kit metadata, each containing `id`, `weight` and four `totals`; emitted after supply replacement and before turn/energy refresh. New totals are fully available on the cleared board. |
| `reshuffled` | Ordered `cards` in the newly shuffled draw pile, `from = discard`, `to = draw`. Only when a draw needs an empty pile refilled; not emitted for setup shuffles. |
| `card_drawn` | `card`, `from = draw`, `to = hand`, resulting `draw_remaining`, resulting `hand_size`. Emitted per actual draw; follows any required reshuffle. |
| `technique` | Played `card`, `cost`, `energy_before`, `energy_after`, `from = hand`, `to = discard`, `undo_cleared`. Records payment, card commitment and undo clearing before its effect. |
| `card_created` | Generated `card`, `to = hand`. Follows Conjure's technique event. |

Cast order: Cast/payment → enemy damage → shield/retaliation **only if enemy survives** → board cleanup → hand/history cleanup → battle end **or** next playable entry. Production entry selects endpoints, replaces the kit, then refreshes turn/energy and draws; historical profiles retain their fixture order. Pass uses `passed` → retaliation → the same cleanup/terminal/next-turn sequence. A terminal turn retains its turn number and remaining energy.

Draw techniques use technique/payment/discard/undo commit → any required reshuffle → up to `value` actual draws (two for Focus). Their own card is already in discard and can be recycled by that draw. Conjure uses technique → `value` card creations of `generated_rune_id`, with no turn advancement. Only explicit `draw` and `conjure` dispatch is supported; an unknown effect cannot fall through to creation. No presentation code invokes RNG; the existing descending Fisher–Yates shuffle and end-of-pile draw order are preserved.

### Historical prefilled opening Cast

Explicit `res://data/encounter.json`, fresh model, seed 42, action 1, encounter generation 1, turn 1 (abbreviated payloads). Normal production opens empty and cannot perform this immediate 12-damage Cast:

```text
0 cast               damage 12, shield 0, cost 1; energy 3 → 2
1 damage             enemy HP 32 → 20; amount/applied 12
2 shield             player, amount 0
3 retaliation        incoming 8, blocked 0; player HP 30 → 22
4 temporary_expired  cell 1, free_spark UID 0 → straight rotation 0
5 turn_cleanup       discard spark 1, shield 2, conjure 3; empty hand
6 turn_started       turn 1 → 2; energy 2 → 3; next intent 12
7 card_drawn         focus UID 6
8 card_drawn         spark UID 4
9 card_drawn         conjure UID 8
```

The result's `after` snapshot has enemy HP 20, player HP 22, energy 3, turn 2 and that three-card hand. Animating or replaying these ten records leaves those values unchanged.

## Locking, completion and cancellation

The controller locks before invoking the model or emitting any external signal. Accepted Cast, Pass and techniques keep it busy until their completion callback runs; rejected commands release the lock immediately. Board edits finish synchronously. `changed` tells the view to refresh; `presentation_started` supplies a separate detached batch for the existing cast tone. The presenter receives its own batch copy. The placeholder view refreshes to final state while busy; an animation adapter can display intermediate visual values from the supplied `before` snapshot and events without changing the model.

Each completion closes over a monotonically increasing controller token and a weak reference to its owner. Only the current token can unlock; duplicate completions, completions after cancellation, and callbacks from an earlier encounter cannot unlock a newer action. The controller rechecks that token after external signals before starting presentation. A callback retained after the controller is freed is harmless and does not keep it alive.

Restart invalidates the token and cancels the adapter **before** model Reset. `cancel_presentation()` keeps the already-resolved state and releases input; it never rolls gameplay back. Both operations reject gameplay reentry while cancellation runs. Cancellation clears busy before calling external code, so teardown triggered inside `cancel()` cannot cancel twice. If cancellation disposes the controller, the outer operation cannot reset or emit another update.

`main._exit_tree()` calls `dispose()`: invalidate, cancel and permanently close command handling without a view update. Closed controllers do not restart. A replacement scene owns a new controller, and callbacks from the removed scene cannot reach it. Navigation/help and sound controls remain available during presentation; they do not alter combat. Restart remains available and uses the cancellation path.

## RC-008 inspection and gesture integration

The [touch interaction contract](touch-interactions.md) extends only the view layer. `scripts/ui/inspection_data.gd` reads detached snapshots to describe hand UIDs, board cells and tools, and to explain placement/edit availability. It has no controller or model reference. Descriptions use current catalog values, ports, stock and active production/experiment permissions; connector defaults absent from historical snapshots are obtained through the pure core evaluator. Its connectivity walk can identify powered upstream pieces and partially fed Joins while a circuit is incomplete. This does not replace the authoritative forecast or Cast validation.

`scripts/ui/touch_router.gd` captures one pointer stream and routes registered controls and scrolling before GUI button handling. A 450 ms hold opens inspection; movement of at least 18 logical pixels cancels both tap and hold and locks scrolling to the initial dominant axis. A hold suppresses its release tap. Secondary pointers and emulated device events cannot duplicate a gesture. Native fields/selectors/scrollbars retain GUI routing, while Guide/Menu suspend the router. Keyboard focus and Escape remain available. The constants and deterministic `advance_time` test seam live in the router.

`main.gd` keeps selected UID/tool/cell, Inspect mode and preview borders outside combat state. Explicit Inspect mode converts item taps to read-only inspection; normal technique short taps still invoke the guarded technique command. The inspector has no activation button or cached command arguments. It obtains a fresh snapshot when opening and restricts pointer targets to its own subtree. Its body scrolls independently. Close dismisses the panel while retaining Inspect mode; Cancel selection clears mode and selection. Details / Pass uses the same modal and requires a second explicit confirmation before sending Pass.

Every refresh cancels pending gestures. Changed snapshot/busy presentation closes the inspector and clears stale feedback; a consumed card UID is removed from selection. Turn/generation/battle-state changes, presentation start, Undo, Restart, Exact replay and experiment relaunch clear selection. Invalid startup disables gameplay and closes inspection. Focus loss, modal changes, presentation cancellation/refresh and teardown invalidate callbacks. The router increments its generation and clears pending callbacks while retaining ownership until release, preventing an old release from clicking through dismissal or targeting a replacement card. Scene teardown cancels the router before disposing the existing controller.

Eligibility previews never execute a mutation followed by Undo. They permit legal incomplete construction and report protected targets or unavailable stock. Guards remain layered: view handlers recheck availability and `controller.can_edit()`, while authoritative controller/model checks still reject invalid, duplicate, busy or stale gameplay commands. Existing command/event identities, ordering, cancellation tokens and presentation completion behavior are unchanged.

## Attaching RC-017 animation

Subclass the immediate adapter and override `present(result, completed)` and `cancel()`. Inject it with `controller.set_presenter(adapter)` while idle. Animate event order using only the batch's stable data; the authoritative model is already final. At the last visual step call `completed.call()` exactly once. A skipped/reduced-motion path should also complete. On cancellation, stop tweens/animation/audio owned by the adapter and release references to obsolete view nodes/callbacks. Controller token checks defend against late completion, but the adapter must also stop its own late visual writes. Do not queue gameplay commands or call model mutators from an animation callback. No production adapter, effects, reduced-motion settings or animation acceptance is claimed here.

## Verification entry points

Run the existing `tools/godot.ps1 -Action test` for original rules plus `tests/combat_presentation_tests.gd`, `content_loading_tests.gd` and `combat_configuration_tests.gd`; `-Action smoke` runs original UI coverage plus `tests/ui_presentation_tests.gd` and `ui_configuration_tests.gd`. Tests explicitly release the delayed adapter; they do not sleep to simulate animation. They exercise event/state agreement, terminal/Pass/technique/expiry order, detached ownership, rejection, replay, baseline draw order, every guarded mutation, duplicate/stale callbacks, cancellation reentry and actual scene teardown. Configuration tests add both setups, validation failures, input isolation, ownership, configured effects and invalid-screen guards. The smoke runner retains its existing short audio teardown wait; it is not used to prove locking.

Both runners also register RC-007 coverage: `production_rules_tests.gd`, `production_content_tests.gd`, `production_combat_tests.gd`, `connector_geometry_tests.gd` and `ui_production_tests.gd`. These exercise the selected profile, all 720 endpoint/kit geometry combinations, production event boundaries, UID reconciliation, RNG isolation, finite-stock editing and actual screen/Exact replay/entry behavior. Original assertions explicitly load their historical fixtures.

RC-008 adds `inspection_data_tests.gd`, `touch_router_tests.gd` and `ui_touch_tests.gd`, with `ui_touch_capture.gd` for separate rendered runs. Pure-helper tests check live values and state/RNG/history preservation; gesture tests use controlled timing; actual-scene tests inject synthetic touch/mouse events through viewport routing. These are synthetic interaction checks, not physical-device or manual native-input acceptance. See the [touch verification limits](touch-interactions.md#verification-and-remaining-device-work) and dated results below.

See the dated [verification record](verification.md) and [project handoff](project-plan.md) for actual commands, counts, comparison captures and limitations.

## RC-005 experimental commands, events and observations

The following study sections preserve their historical semantics; references to unchanged normal behavior or pending production approval describe that earlier stage. RC-007's accepted production contract is specified above.

The opt-in [experiment harness](circuit-experiments.md) uses this same model/controller boundary. Historical baseline content, snapshots and event ordering are unchanged. Experimental snapshots additionally expose detached `experiment`, `encounter_number` (1 or2) and `can_advance`. `next_encounter` is an ordered presentation command allowed only after eligible first victory; it resets or retains the board as configured. Nonempty transition arguments and duplicate/ineligible transitions fail. Its `encounter_transition` event records mode, old/new encounter numbers, carried HP and both boards; optional opening draws follow it. Generation increases and accepted action identity remains monotonic.

In consumed mode, `effect_consumed` occurs after enemy damage and any shield/retaliation, before temporary expiry/hand cleanup. Payload includes cell, card UID/ID, before/after piece and board-to-discard movement. Disconnected permanents and Pass are unaffected. Experimental temporary expiry can produce matching corner connectors or empty cells, with the same ordered `temporary_expired` event shape.

Multi-hit mode adds `spell.hits` and damage-event `hit_index`/`hit_count`. Positive contributions traverse deterministic Split/Join order, with one event per applied hit and lethal termination. Zero contributions yield no damage events. `amount` versus `applied` retains its existing meaning; shield/retaliation/cleanup ordering is unchanged. The development screen shows ordered hits and exposes complete outcomes through its record inspector; no production animation is introduced.

`ExperimentRecord` is optional on `Controller.new(combat, presenter=null, recorder=null)`. Recording occurs exactly once after authoritative execution and before external signals/playback. Busy/terminal/model rejections are classified independently; accepted action IDs deduplicate accidental re-recording. Exports and presentation callbacks do not increment counters or consume gameplay RNG. Records contain detached setup/snapshots/events, monotonic timing, notes and actual damage/cost/card summaries. `record_document`, `export_record`, `add_note` and `get_record` support the development UI. Write errors are returned visibly without changing combat.

Exact experiment replay saves the current record and constructs a fresh model/controller from the cached setup/seed, disposing the previous controller through existing cancellation guards. Menu Restart keeps RNG continuation and adds a recorder lifecycle entry. Normal launch constructs no recorder and shows no experiment controls. Existing RC-003 delayed-input, reentry, stale-callback and teardown tests remain; experiment tests extend them across replay and the two-encounter transition.

## RC-006 full-reset events

The opt-in `effects/full_reset` fixture (`rc006_full_reset_v1`, normalized `board_reset: "each_turn"`) and the later `effects/moving_endpoints` fixture below use this additional cleanup path. Both start with Begin0/End14 and no other installed pieces. The normal event contract and original 19 variants remain unchanged; these are study extensions, not RC-007 production implementation.

After an accepted Cast's damage and surviving-enemy shield/retaliation, or an accepted Pass's retaliation, board cleanup visits cells in ascending order and removes all nonendpoint pieces. The following detached events share the existing action/generation/sequence identities:

| Event | Full-reset payload and meaning |
| --- | --- |
| `effect_consumed` | `cell`, permanent `card` with unchanged UID/definition ID, `before`, `after: {}`, `from: "board"`, `to: "discard"`. Includes powered and disconnected installed permanents after Cast **and Pass**. |
| `temporary_expired` | `cell`, full temporary piece `before`, `after: {}`. Includes disconnected installed temporaries; no owned-card/pile movement. |
| `board_piece_cleared` | `cell`, full wire/Split/Join piece `before`, `after: {}`. No energy charge or ownership change. Split/Join availability recovers through the existing board-derived stock calculation. |

Begin and End emit no clear event. After board events, ordinary `turn_cleanup` discards unplayed permanent hand cards, expires hand temporaries and clears undo. Then `battle_ended` occurs, or `turn_started` and normal reshuffle/draw events follow. Terminal Cast/Pass still clears the board but never starts/draws a new turn. A rejected command, preparation edit or standalone technique does not trigger the board reset.

The model resolves this once; presentation only consumes the detached batch. `before` and each event preserve the removed geometry for later visuals. Existing input locking, cancellation and replay/recording boundaries continue to apply. See [fixture limits and actual verification](circuit-experiments.md#rc-006-full-reset-follow-up); experimental event timing is not final production approval.

## RC-006 moving-endpoint events

Only `effects/moving_endpoints` (`rc006_moving_endpoints_v1`, `endpoint_policy: "random_each_turn"`) adds **`endpoints_changed`**. Its payload is `before` and `after`, each containing `layout_id`, `begin: {cell, rotation}` and `end: {cell, rotation}`. For an accepted nonterminal Cast/Pass, the ordering is combat resolution → nonendpoint board cleanup → `turn_cleanup` → turn/energy advance → `endpoints_changed` → `turn_started` → normal draw/reshuffle events. No extra endpoint erasure/placement commands are synthesized.

Terminal Cast/Pass still clears nonendpoint pieces but emits no `endpoints_changed`, starts no turn and consumes no endpoint randomness. Rejected commands, edits, standalone techniques and Undo also emit no relocation. The prior fixed `full_reset` fixture never emits this event. The initial layout remains a fixed study control, and both endpoint positions change only when the new nonterminal turn starts.

The Latest readout reports **Begin / End moved** with the cleanup count where present. Raw event data remains available in Inspect/export; the rules tooltip omits catalog witness paths. Endpoint rendering reads the model's orientations so the displayed Begin direction matches its connecting port. Existing detached-result, locking, cancellation and replay boundaries remain authoritative; presentation does not select layouts. See [follow-up version, validation and limits](circuit-experiments.md#rc-006-moving-endpoint-follow-up).


## RC-006 free-endpoint events

The separate `effects/free_endpoints` (`rc006_free_endpoints_v1`) variant reuses full-reset cleanup and `endpoints_changed` at nonterminal turn boundaries. The payload retains `before`/`after` with `layout_id`, `begin: {cell, rotation}` and `end: {cell, rotation}`; generated layout IDs identify ordered position pairs as `pair_BB_EE`, and do not restrict player rotation. Combat resolution → nonendpoint cleanup → `turn_cleanup` → turn/energy advance → `endpoints_changed` → `turn_started` → normal draw/reshuffle remains the order. Terminal actions clear nonendpoint pieces without relocating endpoints or consuming endpoint randomness.

Initial setup samples endpoints before dealing and emits no gameplay action or relocation presentation batch; the actual state is available in `initial_state`. Exact replay reproduces that opening. Menu Restart generates a new opening while continuing both RNG streams and records the existing restart lifecycle. Player Rotate is an ordinary accepted preparation edit with before/after board values and Undo history; it does not emit `endpoints_changed` or consume randomness. A temporarily invalid/outward orientation is allowed while editing and remains subject to normal Cast validity checks. Endpoint Erase, placement/replacement and Flip stay rejected.

Existing locking, cancellation, detached recording and authoritative model rules apply. The prior `moving_endpoints` fixture keeps protected rotations and its fixed first turn; no old records are relabelled. See [the corrected follow-up](circuit-experiments.md#rc-006-free-endpoint-follow-up) for experimental limits and validation.
