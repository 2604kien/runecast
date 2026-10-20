# Audio playback and SFX integration — RC-020

## October 18, 2026 — Current production ownership

The ordinary Combat scene now owns one [audio coordinator](../scripts/audio/audio_coordinator.gd), which subscribes to accepted controller outcomes and presentation milestones. It replaces the generated Cast tone, manages eight fixed SFX players, two music slots and one independently fading crypt player, and never applies gameplay consequences or completes presentation. The shipped [resource catalogue](../scripts/audio/audio_catalogue.gd) contains the 21 current r003 WAV paths and delivered crypt Ogg metadata; the coordinator lazily loads and owns available resources, then releases its cache on disposal. The documentation JSON is a development contract, not a runtime file dependency. Pending music entries are marked unavailable and are never loaded. Exported resource inclusion is verified independently of the source-only documentation.

`CombatController.command_resolved` carries the actual command, detached arguments, accepted result or explicit rejection. Accepted edits therefore play after confirmation even though they have no presentation events. UI handlers own separate dispatch IDs for actual selection/open/close and preflight rejection; passive refresh, hover, removed board inspection and internal clearing remain silent. The cross-reason rejection throttle is 250 ms.

`AnimatedPresentation.phase_started` and `contact_reached` carry detached event, action/encounter IDs, presentation generation, elapsed time and phase progress. Their source is `advance`, including ordered zero-duration steps and contact-boundary splitting for large deterministic advances. Contact reads the actor's `attack_contact` metadata (Shadeling 0.28). `event_presented` remains post-effect/post-commit and owns victory/defeat. The controller's `presentation_invalidated` and `presenter_changed`, plus presenter cancellation and scene disposal, invalidate obsolete subscriptions/batches. Exact replay binds a new audio session even when numeric action IDs repeat.

The existing cue map and reduced-motion policy below are implemented for current owners. Four future actors, reward/purchase/upgrade/heal and guardian-phase aliases remain unbound. An additional −6 dB SFX bus trim preserves measured headroom under the eight-voice rapid-edit stress; Music/ambience gain remains unchanged. Cue gains and priorities retain the catalogue defaults, with the specified player damage −5 dB and shield-gain −6 dB role overrides. Replacement uses an 8 ms sample-domain release envelope derived transiently from the active imported mono WAV; it is a bounded tail, not another shipped cue or a shortening of normal files. No obsolete cue is queued. The eight-voice ceiling includes tails; reduced mode has one foreground and at most one release tail. [Executed verification and limitations](rc-020-verification.md) distinguish technical playback from listening acceptance.

Menu → Options reuses the existing theme's sliders, toggles and modal. Music and SFX each have an independent 0–100% level and mute. Sound remains the master switch and retains both levels and individual mute choices. `[audio] enabled` remains the compatible master preference; absent levels default to 1.0 and absent individual mutes to false. `[accessibility] reduced_motion` retains its existing meaning. Loading/reopening is read-only; the next actual user change writes missing defaults while preserving unrelated keys/sections. Invalid values normalize safely, and an unreadable/corrupt existing file is not overwritten. [Settings service](../scripts/audio/audio_settings.gd), [reusable Options](../scripts/ui/audio_options.gd).

Application focus loss or suspension invalidates the pending SFX batch, stops effects and pauses loops; both focus and suspension state must allow playback before resuming. Mute also consumes pending effects and retains loop position. Resume/unmute does not replay skipped cues. These are desktop implementation and instrumented checks; real Android/iOS interruption acceptance remains with RC-021/RC-022/RC-047. RC-019 and the original full RC-020 task remain incomplete pending music and final acoustic acceptance.

## Retained source contract

October 17, 2026 source delivery. The [machine-readable catalogue](audio-cue-catalogue.json) defines 21 cues in 16 stable manifest families. The r003 revision uses Runway sources in the direction approved by the owner. [Editable sources](../source-assets/audio/sfx/delivery.md) retain original MP3s, exact generation records, deterministic processing settings, 24-bit working masters and provenance; the runtime exports are 48 kHz, 16-bit mono WAVs. Working-master bit depth does not imply lossless original fidelity. The [audition preview](../output/audio/rc-018/README.md) uses those real runtime files. The source revision preserves all timing, grouping, cancellation and future-only mappings below; the current implementation is recorded above.

## Existing interfaces and timing

The former 0.1 s, 22050 Hz, 8-bit decaying 440 Hz Cast tone and its playback path are removed. One accepted Cast now reaches the coordinator through the actual Cast phase. RC-019 owns the still-incomplete two-music/one-ambience delivery; RC-042 binds future content.

`CombatController.command(name, arguments)` returns an acceptance boolean. Accepted edits have no presentation events and no `presentation_started` signal. For Cast, Pass, technique and next encounter, `presentation_started(result)` supplies the detached accepted result immediately before `presenter.present`. The model is already resolved; sounds must never apply a consequence. A busy/closed/terminal guard rejection may return false without a model result. Successful UI selection/modal changes also have no model event.

`AnimatedPresentation.event_presented(event)` fires **after** that event's effect has finished, effects have cleared, its staged consequence has been applied and the updated visual snapshot published. It is suitable for a consequence-commit or result sound; it is **not** a phase-start or attack-contact notification. `visual_changed` is a refresh signal and must not trigger audio on every emission.

The owner's latest RC-017 pacing is authoritative:

| Event or interval | Normal presentation seconds | Reduced motion |
| --- | ---: | ---: |
| Cast slot illumination | 0.90 | 0.06 |
| Enemy damage phase (including zero applied damage) | 1.50 | 0.06 |
| Positive shield gain | 0.35 | 0.06 |
| Zero shield gain | 0 | 0 |
| Enemy retaliation | 1.50 | 0.06 |
| Played technique card | 1.00 | 0.06 |
| Each actual drawn/created card | 0.40 | 0.06 |
| Each cleared board cell | 0.18 | 0.06 |
| Old-hand cleanup | 0.18 × actual discarded/expired card count | 0.06 × actual card count |
| Reshuffle / encounter transition | 0.24 each | 0.06 each |
| Battle result phase | 0.75 | 0.06 |
| Passed / endpoints / kit / turn-start structural event | 0 | 0 |

The attack pose enters contact at normalized progress **0.28** and recovery at **0.72**, from `assets/enemies/shadeling/motion.gd`. Current normal contact begins 0.42 presentation seconds into the 1.50 s phase; reduced logical contact is 0.0168 s into its 0.06 s phase despite the stationary reduced visual. Treat the fraction as actor metadata, not a hard-coded delay. Future actors must supply their own contact mapping.

The presenter advances its own clock, capping automatic increments at 1/30 s; frame stalls can extend wall-clock playback. RC-020 must emit phase-start/contact notifications from that clock, checking the active generation and threshold crossing exactly once. A single large `advance` may cross several boundaries: process ordered milestones, including zero-duration events, without scheduling a wall-clock timer per event. Audio files need not last for the entire visual phase. Do not extend animations to match their tails.

## Implemented boundaries and future owners

| Boundary | Current availability | RC-020 work |
| --- | --- | --- |
| Accepted presentation batch | Existing `controller.presentation_started(result)` | Use one subscriber for batch planning/deduplication; replace the old tone once |
| Accepted edit or successful UI change | `command_resolved` plus UI dispatch feedback | Capture success once; retain detached actual command arguments/target |
| User-facing rejection | Existing false return / `InspectionData` preflight rejection | Route only an explicit user attempt, not passive disabled-state refreshes |
| Phase start | `phase_started` from `_enter_step` | Detached event, generation, action/sequence and phase progress zero |
| Actor contact | `contact_reached` from `advance` | Publish once when active progress crosses the actor metadata contact fraction |
| Consequence commit / result | Existing `event_presented(event)` | Use as post-commit only; capture batch/session identity without consulting a later live model |
| Cancellation / replacement / teardown | Controller invalidation/presenter replacement and presentation cancellation signals; coordinator disposal | Invalidate pending audio before cancellation/replacement; release owned voices and subscriptions |
| Reward / service / phase transaction | No accepted event exists | RC-024–RC-034 systems define committed identifiers and payloads; RC-042 binds them |

These are presentation/audio hooks, not new gameplay event enums. RC-020 implements them through the existing controller/presenter and one coordinator; no second sound system is installed.

## Action mapping and deliberate silence

| Cue | Binding and moment | Grouping / exclusions |
| --- | --- | --- |
| `ui_confirm` | A successful visible selection, inspector/menu opening or confirmation, after UI success | One per UI dispatch. Actual placement/rotation/Remove uses its specific cue instead. Opening an inspector never triggers a technique. No hover, passive refresh, unavailable tool selection or board-inspection sound; board inspection is removed. |
| `ui_back` | An actually visible modal closes, active selection clears, or accepted back/cancel navigation completes | One after the state change. Internal `_clear_selection` or modal closure before Cast/Pass/technique is silent; avoid adding a second cue to an accepted action. Abandonment may reuse this quietly when its future flow exists. |
| `edit_place` | `command("place_wire", {index,kind}) == true` for a connector, or accepted `place_rune`, after acceptance | One per edit, targeted at the actual cell/UID. No cue merely from choosing a tool. |
| `edit_orient` | Accepted `rotate`, after acceptance | One per actual rotation. Production has no Flip binding. |
| `edit_restore` | Accepted Remove: `place_wire` with `kind="erase"`, after acceptance | Historical manifest ID `sfx_undo` remains stable; production has no Undo control. Refund is part of Remove, not another sound. |
| `action_rejected` | Explicit rejected command or explanatory preflight denial | Quiet feedback, at most once per 250 ms per UI owner across rejection reasons; no backlog. This input throttle is not a combat-phase timer. Guarded passive inputs and disabled-state refreshes are silent. |
| `cast` | Start of actual `cast` phase in an accepted Cast result | Exactly once per action, no per-slot/branch/rune/payment ping. |
| `damage` (enemy) | Start of `damage` phase, only `applied > 0`, target enemy | Current production is one aggregate hit. Never infer injury from requested `amount`, forecast, zero applied loss or the retained hit painting. |
| `shield` (gain) | Positive `shield.amount` at its phase start, target player | Normal gain uses −6 dB; mark shield feedback delivered for the action. Zero gain is silent. |
| One enemy variant | `retaliation` contact; resolve `before.encounter.enemy_id` through the exact actor map | Shadeling → spectral, Wickling → flame, Stone Sentinel → stone, Chain Warden → chain, Bell Keeper → bell. These files already contain a shared action base plus one accent; never layer the five. Unknown/development IDs have no implicit shipped actor binding. |
| `damage` (player) | Same retaliation contact, only `retaliation.applied > 0`, target player | Normal uses −5 dB, paired with one actor file at its normal −3 dB gain. One contact can have at most these two intentionally distinct cues. |
| `shield` (block) | Retaliation contact with `blocked > 0`, only if shield gain feedback has not already played for the action | −4 dB. In normal mode positive player HP loss has precedence over a third block layer; full block may pair actor + shield only if no gain cue already represented it. Do not trigger both a generic block alias and its underlying retaliation subscription. |
| `technique_draw` | First actual `card_drawn` phase in its action's arrival group | One shared cue for actual supplied UIDs. The 1.00 s played-technique animation is silent; no generic technique-start ping. Later 0.40 s arrivals remain silent. A reshuffle does not split the arrival audio group or add another cue. |
| `technique_conjure` | First actual `card_created` phase in its action's creation group | Same rule. No sound for predicted/missing cards. Do not create per-card variants. |
| `temporary_expired` | Start of first actual `effect_consumed`, `temporary_expired`, `board_piece_cleared`, or nonempty `turn_cleanup` in the action | One soft shared cleanup cue for the whole ordered board-and-hand cleanup. Later 0.18 s cells/cards stay silent. An empty `turn_cleanup` is not an audible group. |
| `victory` / `defeat` | `battle_ended` post-effect consequence commit, matching `state` | One result per encounter generation. No predicted lethal result, no fabricated reward, no next-turn cue. Future run results reuse the same outcome identity rather than replaying it. |
| `reward` | Future committed reward, purchase, upgrade or heal transaction | One per actual transaction ID, after mutation succeeds; failed/cancelled purchases, offer display, pickers and inspection are silent. Proposed aliases are not current events. |
| `guardian_phase_changed` | Future committed guardian phase event, once | Await the actual event and phase transition ID. Never infer from HP, the forecast, threshold crossing, art pose, or battle result. |

Next-turn and encounter-transition draws reuse `technique_draw` once at their first actual arrival, at lower priority 30. Initial model construction emits no action batch: do not synthesize opening-draw sounds from the initial snapshot. A technique with no actual additions has no addition cue. If a future technique needs a distinct non-arrival outcome, its owning contract must define it rather than guessing from a requested card count.

Pass contains `passed`, retaliation, actual cleanup and (if alive) the actual next-turn events. The zero-duration `passed` step is silent. Its successful confirmation can use one UI confirm, but must not synthesize Cast, payment, player shield or enemy damage. Lethal spell damage supplies neither shield nor retaliation; terminal action batches contain no next turn/draw. Use the supplied ordered batch rather than constructing those outcomes independently.

## Gains, priorities and reduced motion

Catalogue `intended_gain_db` is the mixer gain applied to the authored runtime WAV; it is not the file's measured peak. Use role-matched source levels plus these gains, then audition the production mix with music. Provisional priorities are: result 100; future phase 90; damage 80; shield/reward 75; Cast/actor 70; technique arrival 60; ordinary draw 30; edit 25; UI/cleanup 20; rejection 15. These are recommendations for RC-020, not active buses or acceptance claims about listening.

Normal mode keeps a maximum of two purposeful cues at one attack contact: the selected actor plus applied player damage, or an otherwise unrepresented full block. Shield gain already represented earlier in the action suppresses block repetition. Cleanup and arrival groups contain one cue each despite the sequential visuals. The broader production ceiling remains eight voices, including any overlap tails, with one owner per action and result.

Reduced motion retains semantic audio; it does not shorten the WAV itself to 0.06 s or mute sounds because motion is reduced. The audition demonstrates one foreground voice, with a release/crossfade of at most 10 ms when a new meaningful phase replaces the old tail (at most two voices during the release). This is amplitude smoothing, not a delay added to presentation. Do not queue old sounds after the animation has already moved on.

- Group an accepted Cast as one action: play Cast at its phase start, then suppress the separate enemy-damage and shield-gain pings in that same reduced action. Their actual HP/shield outcomes remain in the existing staged visuals. This avoids restarting three sounds at successive 0.06 s boundaries. Reserve the next mandatory cue for actual retaliation contact, if supplied. A standalone positive-damage or shield event outside a Cast group may retain its own phase cue when such an event is actually supplied.
- At reduced retaliation contact choose **one**: player impact when `applied > 0`; otherwise shield when `blocked > 0`; otherwise the actor variant. Partial block plus HP loss chooses impact, with the actual blocked amount still conveyed by the existing text. Do not layer actor, block and injury together.
- This permits at most two mandatory foreground starts per reduced Cast (Cast plus retaliation), one per reduced Pass, or one per technique; an actual terminal result may add one. A lethal Cast has no retaliation cue. Foreground replacement follows the later meaningful boundary even if its numeric priority is lower; ordinary WAV duration is unchanged, and the clock receives no additional delay.
- A technique's first actual draw/create arrival is meaningful and replaces the old tail; later arrivals stay silent. Ordinary next-turn draws and cleanup are decorative: drop them when a higher-priority foreground cue is still active, rather than delaying them or cutting an important outcome.
- Result and future committed phase cues take precedence and replace lower-priority tails. Silence from a missing event/UID, a zero outcome or deduplication is independent of the motion preference.

The preview's deterministic arbitration was the source recommendation. RC-020 implements that policy on the production clock; measured playback, voice/lifecycle tests and the still-pending final listening acceptance are recorded in its verification.

## Identity and cancellation

Combat deduplication keys include **audio-session identity + encounter generation + action ID + event sequence + cue role**. Event IDs are local to a model/controller; Exact replay creates fresh objects and can reuse numeric IDs, so `action_id` alone is insufficient. Cast deduplicates at action scope; shield representation and cleanup at action scope; arrival groups at action + event type with the actual supplied UID list; battle result at session + encounter + outcome. Retain event sequence when normal actor and consequence cues legitimately share a retaliation.

UI feedback uses a single dispatch token owned by its handler; a UI rebuild must not replay an action. Future transaction/phase aliases must provide stable committed transaction/transition IDs before binding. A future run result must carry the already-announced combat outcome identity if it reuses the same victory.

RC-020's audio coordinator owns subscriptions, deduplication, active voice handles and pending phase milestones. Controller cancellation/restart, Exact replay, encounter replacement, scene disposal, mute or audio interruption invalidates that owner's generation before any callback can emit another sound. Cancel pending cues immediately; stop/fade its existing voices within a small bounded click-safe release. Never let a retained completion, stale UI instance or queued timer address a new controller. Do not cancel the model's already-committed outcome or call presentation completion from audio playback. Music/ambience lifetime and resume policy remain RC-020/RC-047 work.

## Review and remaining integration

The source catalogue and isolated preview retain their RC-018 provenance and measurements in [RC-018 verification](rc-018-verification.md). Current production integration is recorded in [RC-020 verification](rc-020-verification.md), with measured internal playback separated from pending speaker/headphone approval, music-dependent final mixing, mobile acceptance and final rights review.

