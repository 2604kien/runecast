# RC-017 Combat animation usage

**October 18, 2026 — RC-020 audio extension:** the existing presentation clock now emits detached `phase_started` and `contact_reached` notices, with generation/action/event identity and normalized actor-metadata contact. A large deterministic advance processes each crossed contact and ordered phase exactly once, checking cancellation after external notifications. `event_presented` remains after visual completion and staged consequence commit. These hooks preserve the durations and gameplay outcomes below; one audio coordinator consumes them without completing presentation. [Audio contract](audio-integration.md) and [verification](rc-020-verification.md).

The ordinary production `scenes/main.tscn` installs `AnimatedPresentation` through the existing controller injection API. The historical immediate `CombatPresentation` and controllable delayed test adapter retain their behavior. No gameplay model, rule, RNG stream, audio system or encounter data is added. [Verification](rc-017-verification.md) records executed checks and native motion evidence.

**October 17 owner follow-ups:** temporary feedback circles remain removed from cards, piles, stats, actor attachments and terminal/transition feedback. Enemy hit and attack each take 1.50 s in normal motion. Playing a technique visibly brightens, shrinks and fades its actual card over 1.00 s before its supplied draw/creation events. Each drawn or created card then fades in individually over 0.40 s in the fixed 146 px hand lane. Outcome text, actor poses and turquoise slot illumination remain; Begin/End artwork is unchanged. Earlier captures containing rings or shorter timings are historical.

## Playback and ownership

`present(result, completed)` takes detached before-state, ordered events and final after-state. The model is already finished. `controller.snapshot()` remains authoritative; `controller.display_snapshot()` supplies staged visual values to Combat. Before `present` begins, the controller's initial busy notification displays the before-state, so the final hand, health and board never flash and roll backward.

The adapter owns one sequence. `advance(seconds)` is the production clock and deterministic test seam; `finish()` drains it without waiting. A single input-transparent `combat_feedback.tscn` overlay supplies `_process` ticks; `automatic_timing = false` allows deliberate sampling. Automatic ticks advance by at most 1/30 s, so a stalled frame cannot swallow several short effects. Slow frames can therefore extend wall-clock completion. `visual_snapshot()` returns a deep copy. Each effect finishes and clears before its consequence commits and the next effect starts. `event_presented` fires after each ordered visual commit, including zero-duration structural events. `event_trace`, `phase`, `phase_progress`, `elapsed` and `duration` expose observation only.

An action/encounter high-water mark prevents duplicate playback. The controller still rejects duplicate input and guards completion with its token and weak owner. The adapter additionally invalidates a generation on cancel, checks it after external signals, and drops the completion, batch and step references. No timer, tween, deferred gameplay callback or animation callback applies a consequence. `cancel()` clears the overlay and restores actor state; the controller's subsequent refresh presents the already-committed result. Restart restores the new opening; Exact replay disposes the old adapter and constructs a new one. Scene exit disposes controller and adapter, stops idle, disconnects through node disposal and releases obsolete weak view references. Normal and reduced sequences call their one retained completion once. Cancellation does not call it.

## Event mapping

| Emitted event | Visual treatment and staged values |
| --- | --- |
| `cast` | The detached `spell.active` slots light in order over 0.90 s, using the same turquoise stone face and soft glow as connected Begin/End. The sweep completes at 70%, holds until 85%, then fades before the hit begins. Begin/End keep their existing appearance. Light renders below each slot's own symbols and wires; no added circles, spokes, arrowheads or reevaluation of the cleared board. Payment becomes visible when the phase commits. |
| `damage` | 1.50 s retained hit painting and text showing actual `applied` HP loss. Zero applied damage keeps the neutral actor without an enemy label, no-damage log notice or injury reaction. |
| `shield` | Positive supplied amount appears as text at the player health control for 0.35 s. Zero gain is ordered without a delay. |
| `retaliation` | 1.50 s foot-rooted anticipation/contact/recovery, with text for blocked amount and actual applied player HP loss. Fully blocked contact uses blue text. No visible player actor. |
| `passed` | Ordered log change, no synthetic Cast, payment, shield or enemy damage. |
| `effect_consumed` | Slot illumination fades over its own 0.18 s; actual permanent card enters displayed discard. |
| `temporary_expired` | Violet slot illumination fades over its own 0.18 s; supplied after-piece replaces the old piece. Production supplies an empty cell, never a replacement wire. |
| `board_piece_cleared` | Slot illumination fades over its own 0.18 s; displayed availability follows this actual clearance. No light tail survives into the next clearance. |
| `turn_cleanup` | Retains the scheduled 0.18 s per actual old-hand card. The supplied event commits once after that interval, clearing hand/undo and updating discard. The former card-circle overlays are removed. An empty hand adds no delay. |
| `endpoints_changed`, `kit_changed`, `turn_started` | Ordered immediate replacement from supplied geometry/kit/turn/energy/intent. Forecast uses the detached resolved result after the board transition. |
| `technique` | 1.00 s actual played-card animation: brighten, shrink toward its center (up to 12%) and fade out from 45% progress. Payment/discard becomes visible at the event boundary, followed by the actual draw/creation events. No circles. |
| `reshuffled` | Its own 0.24 s interval; the supplied draw/discard lists commit before the next card starts arriving. |
| `card_drawn`, `card_created` | Each supplied card fades from transparent to opaque over its own 0.40 s interval. Only the current event's UID is previewed; prior cards remain opaque and later arrivals wait. Hand/pile counts commit when that fade finishes. No circles, scale changes or invented draws. |
| `battle_ended` | 0.75 s enemy fade for player victory or stable player-defeat presentation. Terminal labels and health persist, idle stays stopped, no retaliation/next turn/reward is inferred. |
| `encounter_transition` | Supported configured successor uses a 0.24 s interval, committed encounter values and pre-draw zones, then its actual draw events. No map, phase, progression or reward simulation. |

Editable pacing/palette live in [combat_feedback_style.tres](../scenes/vfx/combat_feedback_style.tres), with defaults in [combat_feedback_style.gd](../scenes/vfx/combat_feedback_style.gd); the shared overlay, card controls and presentation adapter implement all seven VFX manifest IDs without duplicated scenes or textures. Actor curves and attachment coordinates are described in the [actor contract](actor-animation-contract.md). These timings implement the owner's later request for slower, sequential animation and supersede the original provisional 1.2 s routine-turn target. Total duration is the sum of the actual event intervals, including each cleared slot, each old-hand card and each supplied draw; it varies with the action. `presenter.duration` reports this nominal finish time. Zero-duration transitions retain strict event order.

Technique feedback resolves the supplied card UID in the live hand on every sample because normal refreshes rebuild the card controls. A weak reference tracks only the currently animated instance; original tint, scale and pivot are restored before rebinding, phase completion or cancellation. The animation changes neither container-owned position/size nor card identity. Its inward scale stays within the card's existing scroll area. `technique_shrink` and `technique_brightness` are editable in the same style resource.

Card arrivals use a detached `incoming_card()` descriptor alongside the staged snapshot. The UI adds one disabled, nonfocusable preview with its correct opacity before its first frame; it never inserts that card into the model or staged hand early. Refreshes recreate the preview at current progress, and sampling resolves only its marked UID. At completion the preview is removed and the original event commits the ordinary full-opacity card. Cancellation removes previews before the controller presents the settled hand. Deferred horizontal reveal resolves the current live card after layout without retaining obsolete controls or scrolling the page vertically. The shared 146 px minimum keeps the hand, forecast and Cast in place even when no cards remain. `draw_seconds` controls each arrival independently of `cards_seconds` for reshuffles/transitions.

## Reduced motion

Launch the pinned engine with the user argument:

```powershell
& .\.tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --path . -- --reduced-motion
```

Alternatively set `[accessibility] reduced_motion=true` in the existing Godot `user://settings.cfg`; sound toggling preserves that key. Embedded callers/tests can call `scene.set_reduced_motion(true)`. A settings-screen toggle remains later accessibility/settings work; no new menu is added here.

Reduced motion caps each timed effect at 0.06 s, including each individual hand-cleanup card and card arrival. It keeps the original event order and final snapshot, removes travel, transform motion and idle work, and uses stationary slot illumination, outcome text and actor colour or opacity feedback. Technique cards brighten/fade without scaling or pivot changes; arriving cards keep their opacity-only fade and fixed lane. Health loss, shield, expiry and terminal state remain distinguishable. The production SFX, crypt ambience and Sound preference are independent; reduced motion never mutes them. Audio applies its documented reduced foreground grouping while preserving the meaning of actual outcomes.

## Resource and interaction contract

There is one action overlay, zero emitters, zero particles and zero new effect textures. The overlay draws outcome text; board cells draw their existing ports and soft illumination. Effects ignore mouse input/focus and draw below in-page inspection; native dialogs remain above the canvas. Anchors are recomputed from live controls and actor markers, so page/hand scrolling and all three native widths use the actual target geometry. Off-page target centers are skipped. The detailed cards, live piles, display-only forecast, owner-approved header/status frame and normal navigation remain the existing controls.

Board illumination is drawn by `board_cell.gd` inside the existing cell hierarchy so page clipping, symbols and wires remain intact. Its temporary intensity blends amber rune faces to the exact connected-endpoint palette; it does not stack a colour wash over the glyphs. Completion/cancellation clears the temporary light. Both the setter and renderer exclude current Begin/End pieces, including endpoints relocated onto old cleanup cells. This October 16 owner-directed slot-light revision supersedes the board circles in the initial RC-017 motion evidence.

The actor warms only the approved-atlas neutral and two retained 512² paintings: 2 MiB of extra decoded RGBA8 pose data compared with neutral alone. No part-puppet textures are loaded. See the verification record for actual Godot counters and their scope; physical-device performance remains RC-048/RC-049.

Future actor packs implement the documented named attachment/pose contract. Future guardian phases, rewards and progression need their owning system's accepted events and their own mappings; none are inferred from HP or played speculatively here.
