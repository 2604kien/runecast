# Combat and presentation contract

Implemented by RC-003 on October 8, 2026. This contract preserves the single training encounter and [current gameplay rules](gameplay-rules.md). It prepares RC-017's animation integration; it does not implement production animation, configurable encounters, content schemas or run/save systems.

## Responsibilities and command flow

- `scripts/core/combat.gd` is a `RefCounted` model. It owns rules, authoritative state, RNG, editing/undo, payment, damage, cleanup and draws. It loads the existing JSON definitions and runs without scene nodes, audio, timers or animation. `circuit.gd` remains the pure circuit evaluator.
- `scripts/ui/combat_controller.gd` owns the model and a presentation adapter. It accepts commands, guards input, exposes detached snapshots, and coordinates presentation completion/cancellation. Its `is_busy()` is independent of the model's `playing`, `victory` and `defeat` state.
- `scripts/ui/combat_presentation.gd` supplies the immediate adapter: `present(result, completed)` immediately calls the completion callback. `cancel()` is currently a no-op. The controllable adapter in `tests/delayed_presentation.gd` retains batches/callbacks until explicitly completed; production has no artificial delay.
- `scripts/ui/main.gd`, attached to `scenes/main.tscn`, composes these objects and builds the existing controls. It owns selection/help, navigation and the existing sound preference/tone. `board_cell.gd` and `arena.gd` draw view data. The screen's `game` dictionary is a detached snapshot, not the combat model.

Player intent → guarded screen handler → `controller.command(name, arguments)` → `model.execute(name, arguments)` → final model state and detached result → presentation → completion → unlocked controls. The model has already finished before presentation starts. A consumer never pays, damages, expires or draws anything.

| Command | Arguments | Presentation |
| --- | --- | --- |
| `cast`, `pass` | None | Ordered batch; waits for completion |
| `technique` | `uid` | Same ordered-batch/completion boundary |
| `place_wire` | `index`, `kind` (`straight`, `corner`, `split`, `join`, `erase`) | Immediate snapshot refresh |
| `place_rune` | `index`, `uid` | Immediate snapshot refresh |
| `rotate`, `flip` | `index` | Immediate snapshot refresh |
| `undo` | None | Immediate snapshot refresh |

The controller returns an acceptance boolean. All edits are guarded in controller logic as well as the view handlers; disabled buttons are only feedback. Restart is `controller.restart()`, with the cancellation policy below. Legacy model entry points preserve their original return types: bool for Cast, technique, placements and Rotate; void for Pass, Flip, Undo and Reset. New consumers use `execute` for results. Existing direct model fields remain available for compatibility and core test fixtures; views receive no model reference and must not use those fields for gameplay.

## Data ownership and result envelope

`snapshot()`, `execute()` and `last_result()` return deep copies of nested dictionaries/arrays. Recording an event also copies its payload immediately, before later cleanup/draws can change it. Mutating a view snapshot, a presenter batch, a prior result, or a copy from `last_result()` cannot change authoritative board/hand/catalog/piles or the model's retained outcome. Results remain unchanged after later commands and Reset. These values are detached, not language-enforced immutable objects: a consumer can edit its own copy.

A snapshot includes `encounter_id`, board, hand, draw/discard piles, catalog, encounter definition, health, energy, turn, battle state, `log_text`, intent, forecast, Split/Join stock and undo count. Board cells are zero-based indices 0–15. Cards have definition `id` and instance `uid`; installed runes use `rune_id` and `uid`. The opening Free Spark has UID 0. `player` and `enemy` identify the only two combatants; the encounter definition in the snapshots identifies the training fixture. There is no speculative multi-target schema.

| Result field | Meaning |
| --- | --- |
| `accepted` | Whether this command applied its gameplay mutation |
| `command` | Requested command name |
| `encounter_id` | Model-local generation; increments on every Reset |
| `action_id` | Model-local monotonically increasing accepted-command ID; continues across Reset, including edits; 0 for rejection |
| `turn` | Turn at command entry |
| `before`, `after` | Detached snapshots at entry and after complete resolution |
| `events` | Ordered consequence records; empty for rejected commands and preparation edits |

Every event adds `type`, zero-based contiguous `sequence`, `action_id` and `encounter_id`. Identify a card by generation plus UID and an event by action plus sequence within this model's lifetime. These are presentation identities, not a persistent save/replay format or globally unique session IDs. Reset preserves the existing RNG continuation while restarting card UIDs.

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
| `temporary_expired` | Board `cell`, full piece `before` (including rune ID/UID/rotation), connector `after`. All installed temporaries, including disconnected ones, expire in ascending cell order. |
| `turn_cleanup` | Normal hand cards `discarded` and temporary hand cards `expired`, each in hand order; `hand_after = []`, `undo_cleared` count. Follows board expiry; ordinary installed runes remain installed. |
| `battle_ended` | `state` (`victory`/`defeat`), `player_hp`, `enemy_hp`. After cleanup, enemy death is checked first. No new turn or draw follows. |
| `turn_started` | `turn_before`, `turn_after`, `energy_before`, `energy_after`, next `intent`. Only if both combatants live, after cleanup. |
| `reshuffled` | Ordered `cards` in the newly shuffled draw pile, `from = discard`, `to = draw`. Only when a draw needs an empty pile refilled; not emitted for setup shuffles. |
| `card_drawn` | `card`, `from = draw`, `to = hand`, resulting `draw_remaining`, resulting `hand_size`. Emitted per actual draw; follows any required reshuffle. |
| `technique` | Played `card`, `cost`, `energy_before`, `energy_after`, `from = hand`, `to = discard`, `undo_cleared`. Records payment, card commitment and undo clearing before its effect. |
| `card_created` | Generated `card`, `to = hand`. Follows Conjure's technique event. |

Cast order: Cast/payment → enemy damage → shield/retaliation **only if enemy survives** → board expiry → hand/history cleanup → battle end **or** next-turn refresh and actual draws. Pass uses `passed` → retaliation → the same cleanup/terminal/next-turn sequence. A terminal turn retains its turn number and remaining energy.

Focus uses technique/payment/discard/undo commit → any required reshuffle → up to two actual draws. Its own card is already in discard and can be recycled by that draw. Conjure uses technique → card creation, with no turn advancement. No presentation code invokes RNG; the existing descending Fisher–Yates shuffle and end-of-pile draw order are preserved.

### Concrete opening Cast

Fresh model, default seed 42, action 1, encounter generation 1, turn 1 (abbreviated payloads):

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

## Attaching RC-017 animation

Subclass the immediate adapter and override `present(result, completed)` and `cancel()`. Inject it with `controller.set_presenter(adapter)` while idle. Animate event order using only the batch's stable data; the authoritative model is already final. At the last visual step call `completed.call()` exactly once. A skipped/reduced-motion path should also complete. On cancellation, stop tweens/animation/audio owned by the adapter and release references to obsolete view nodes/callbacks. Controller token checks defend against late completion, but the adapter must also stop its own late visual writes. Do not queue gameplay commands or call model mutators from an animation callback. No production adapter, effects, reduced-motion settings or animation acceptance is claimed here.

## Verification entry points

Run the existing `tools/godot.ps1 -Action test` for original rules plus `tests/combat_presentation_tests.gd`, and `-Action smoke` for original UI coverage plus `tests/ui_presentation_tests.gd`. Tests explicitly release the delayed adapter; they do not sleep to simulate animation. They exercise event/state agreement, terminal/Pass/technique/expiry order, detached ownership, rejection, replay, baseline draw order, every guarded mutation, duplicate/stale callbacks, cancellation reentry and actual scene teardown. The smoke runner retains its existing short audio teardown wait; it is not used to prove locking.

See the dated [verification record](verification.md) and [project handoff](project-plan.md) for actual commands, counts, comparison captures and limitations.
