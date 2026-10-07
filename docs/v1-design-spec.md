# Rune Cast first-release design specification

RC-002 design baseline, October 8, 2026. This document defines the bounded release to build; it does not claim those features exist. The current product is one playable training encounter. See the [content roster](content-roster.md), [task plan](project-plan.md), and [implemented gameplay rules](gameplay-rules.md).

## Authority and scope

**Owner-approved direction:** Rune Cast; Godot; Android and iOS; portrait 4 by 4 circuit play; connected Begin and End; Split/Join amplification; deckbuilding with techniques and generated free runes; and the four October 8 [Home, Combat, Map and Menu visual references](visual-reference.md). Their composition supersedes earlier mockups. Visual approval does not approve the illustrative numbers, enemy rank labels, economy or screen behavior.

**Proposed working defaults:** every new scope quantity, content name, numeric value, flow and policy below. These are coherent recommendations for implementation planning, not unanswered questions represented as owner approval. RC-006 still owns the six core experiments. RC-036/RC-045 tune numbers within this budget; expanding content families requires an explicit scope revision.

## Player experience and principles

Build a spell, understand why it works, and adapt it to an announced threat. A short tower descent should combine satisfying spatial construction with a few meaningful collection and route choices. The player wins by defeating one guardian before health reaches zero.

- Connections, energy and enemy intent must be readable before committing a turn.
- Branches occupy real cells; amplification should compete with defense and board space.
- Free editing, undo and safe inspection invite experimentation. Inspection must never play a technique accidentally.
- Rewards change later decisions without requiring a large catalogue or a new status system.
- Favor clear single-enemy encounters and distinct attack rhythms over mechanical volume.
- Phone readability and resuming a short session matter as much as content count.

## Platform and product contract

Ship a single-player, offline Android and iOS game in English. Windows is a development preview, not a third promised release. No network login, backend, telemetry dependency or download is needed to complete a run. Store installation/distribution is outside the offline gameplay contract. Keep text in maintainable UI/content definitions for later translation; translated production content is deferred.

Use portrait presentation with the existing 720 by 1600 design canvas as the layout reference, responsive safe areas and scrolling where necessary. Do not lock acceptance to the 450 by 1000 desktop preview. Exact minimum OS versions, device models, performance budgets and tablet support are **unselected**, to be established in RC-021/RC-022 and verified in RC-044/RC-048/RC-049. Phone support is the working default; landscape and a separate tablet UI are deferred. Platform setup tasks must consult current official requirements when executed.

## Bounded release budget

| Family | Recommended quantity and boundary | Delivery owners |
| --- | --- | --- |
| Player and tower | One spellcaster/loadout; one tower theme, Ashen Crypt (working name); no rendered player actor | RC-024, RC-036 |
| Run | Default nine visited rooms, including guardian; retain the 8–10 planning envelope | RC-025, RC-036, RC-045 |
| Enemies | Five designs: three normal including Shadeling, one elite, one guardian | RC-034; packs RC-014, RC-037–RC-040 |
| Boards | Four 4 by 4 layouts, introductory through guardian; no assumed obstacles/alternate ports before RC-006 | RC-009 |
| Permanent definitions | Twelve total runes/techniques, including `spark`, `shield`, `focus`, `conjure` | RC-004, RC-035 |
| Generated definitions | One additional `free_spark`; excluded from twelve and from permanent ownership | RC-007, RC-035 |
| Progression | Six unique relics; four authored events; eight single-rank rune upgrades | RC-031, RC-035, RC-036 |
| Room types and services | Six room types; two recovery options; four shop service types; one run-only currency, Gold | RC-029, RC-030, RC-036 |
| Environment | One layered crypt, with base/recovery/guardian lighting variants reusing the same geometry; one separate Home tower illustration | RC-015 |
| UI and identity | Reusable theme/icons, parchment map treatment, Home logo, dialogs, rewards/results; one app icon family | RC-012, RC-013, RC-041, RC-051 |
| Motion and sound | Five character packs sharing idle/attack/hit/defeat contracts; core spell/UI effects and SFX; two music loops (Home/exploration and combat), one crypt ambience bed | RC-017–RC-020, RC-037–RC-042 |

Use shared effects/cues wherever possible. Bound the effect work to circuit traversal, impact, shield, enemy attack telegraph, technique/temporary creation, expiry, victory and defeat families. Guardian intensity can reuse combat music and shared effects; no third music track, second biome, event character packs or separate shopkeeper actor is required. Home tower art is a separate composition, not a crop of the crypt. Detailed dimensions, animation frames, audio cue lists, provenance and complete manifest expansion belong to RC-010.

## Tutorial, collection and initial resources

Offer a short, skippable tutorial before the first run, using the reproducible `training_shadeling` fixture and its completed reference circuit. Teach intent, one cast, temporary expiry, repair/undo, energy, techniques, inspection and Pass turn. Then teach the route and one reward in the first real run. Tutorial time is excluded from the repeat-run duration target. Home Options provides tutorial replay; it uses separate practice state and does not replace an active run, grant Gold or transfer cards. RC-043 owns guided steps, skip/replay and local tutorial-completion preference.

Start each real run with 30/30 health, 3 energy per turn, draw 3 per turn, one Split and one Join, unlimited ordinary straight/corner wires, **zero Gold and zero relics**. The starting permanent collection has eight instances: two each of Spark (`spark`), Shield (`shield`), Focus (`focus`) and Conjure Spark (`conjure`). All twelve definitions are eligible content from the first run; there are no account unlocks, persistent currency or power progression between runs.

Retain the training opening hand (Spark, Shield, Conjure Spark) for onboarding. Later battle shuffles use the saved run seed/RNG state. Whether a real encounter starts with a prebuilt circuit or empty board remains subject to RC-006; do not duplicate installed cards into its hand. The training board's generated Free Spark is extra tutorial setup, not a ninth owned card or a promised free rune every encounter. Numeric starter values are prototype defaults carried forward for testing, not balance approval.

| Concept | Ownership and lifecycle contract |
| --- | --- |
| Permanent run collection | The authoritative multiset of card instances owned for this run, each with an instance identity and definition ID. Rewards add instances; removal deletes one; upgrades modify one. It is not a global metagame collection. This run-level model is new work. |
| Battle hand | Available normal instances plus separately marked temporary instances. A normal instance cannot simultaneously be in another battle zone. The foundation has no hand cap; use a scrolling hand before adding a retention/cap mechanic. |
| Draw and discard | Draw from shuffled normal instances; recycle discard when draw is empty. Unplayed normal hand cards discard at turn end. Techniques pay and move to discard immediately before resolution; ordinary technique play is not a discard-trigger mechanic. |
| Installed effects | A normal installed instance is absent from hand/draw/discard. Current effects persist between turns and replacement returns the instance to hand. RC-006 may change cast lifetime, but consumption must not silently delete permanent run ownership. |
| Temporary runes | Generated instances of `free_spark` cost zero and expire at turn cleanup even when unused/disconnected. Never enter permanent collection, draw/discard, upgrade/removal choices or future battles. Current installed expiry leaves a straight connector of the same rotation. |
| Encounter boundary | Reconcile owned instances exactly once, discard temporary instances, then prepare the next battle using the selected reset/retain policy. The collection survives either choice; board persistence is a separate RC-006 decision. |

## Complete run flow and pacing

Home → New Run or Continue → route → selected room → room outcome/reward → route → guardian victory or defeat → results → Home. Continue restores the last committed state, which may instead open a pending reward, unfinished service room or battle replay.

The default nine-room path is: normal → event → normal → normal → normal-or-elite branch → normal → shop → recovery → guardian. This gives four guaranteed normal fights, one normal/elite choice, one event, one shop, one recovery and the guardian. Placing the shop after the Gold-producing fights makes their rewards spendable before the climax. Alternate connected nodes can offer different enemies/boards or event IDs while preserving the path budget. Every path must reach a recovery before the guardian; no backtracking or entering an unconnected room. Map decorations and treasure-like symbols in the reference do not add a seventh room type or mandatory treasure room.

| Room | Resolution and return to route |
| --- | --- |
| Normal combat | Win, keep remaining health, gain configured Gold and choose one of three permanent card offerings or Skip. Normal cards may be duplicates, but three displayed options should have distinct definition IDs when the pool permits. |
| Elite combat | Optional harder single enemy. Gold and the normal card choice plus choose one of two not-owned relics or Skip. No relic duplicates/stacking; if fewer remain, offer those available. |
| Guardian | Final fight; victory directly records terminal run success and opens results, without a reward that can affect a finished run. |
| Shop | Spend only run Gold on finite card/relic stock or bounded removal/upgrade services, then Leave. No purchase is mandatory to exit. |
| Recovery | Choose one eligible service (heal or upgrade) or Leave. It completes once; no repeat healing by reopening. |
| Event | One of four authored choice panels with explicit costs/outcomes and a free Leave option. An ineligible choice explains its reason and cannot charge the player. |

Target experienced runs at **15–25 minutes**, with normal/elite fights roughly 2–3 minutes, guardian 3–4 minutes and route/service/reward decisions roughly 3–5 minutes combined. These estimates are a hypothesis; six fights on the default path give about 16–24 minutes. RC-045 measures complete human runs, distinguishes reading/tutorial time, and adjusts health, encounter turns and room count within 8–10 before increasing scope. Each prototype content row has a purpose to test, not a promise that twelve definitions are already balanced.

Gold, shop prices, combat payouts and event values live in the [roster's economy defaults](content-roster.md#economy-and-service-contract). Gold resets with a new run; no gems, crafting shards, keys, consumable stock or real-money currency. Reward and shop offers are seeded when first created, persisted and never rerolled by reopening or restarting.

## Saving, interruption and ending a run

**Proposed policy: one active local run slot, saved between encounters and at committed room transactions; interrupted battles replay from their saved entry.** Only sound preference currently persists. RC-028 implements atomic/versioned saves, recovery and transaction identity; RC-047 verifies device interruption behavior.

Before entering a battle, commit the selected node, collection, health, relics, board/encounter configuration and RNG state. Continue after process termination or Quit replays that same battle from its entry state and seed. It does not return to an unchosen route node, reroll the enemy or preserve partial combat damage. Temporary suspension in a surviving process can retain in-memory preparation; there is no promise of mid-turn disk saves. Explain replay before an intentional combat Quit. Repeated attempts after interruption are an accepted offline v1 tradeoff; no punitive anti-reload system is added.

Persist battle outcome and pending rewards together before showing claims. Persist each reward, purchase, event or recovery transaction atomically with its completion/remaining choices. Reload cannot repeat a granted benefit, reset shop stock or charge twice. On a write failure, show Retry and retain the last valid checkpoint; do not advance while displaying an uncommitted success as saved. RC-028 defines compatible migration or graceful rejection; use a recoverable previous valid copy without silently erasing the unreadable file.

| Exit or ending | Contract |
| --- | --- |
| Guardian victory | Atomically mark the run finished, store a concise result, retire Continue for that run, show victory result and Home/New Run actions. |
| Defeat | On committed health ≤ 0, mark terminal defeat and retire Continue; no automatic rescue or permanent loss outside this run. A failure before the outcome is committed falls under battle replay policy. |
| Quit from Menu | Confirm return to Home; preserve the active run/checkpoint. In battle explain that current battle progress will restart on Continue. Quit never means abandon and does not forcibly exit the mobile app. |
| Abandon | Separate secondary action in run details reached from Map's run header. Confirm destructive loss of this run, then mark it abandoned and return Home. Never overload Menu Quit. |
| New Run | With no active save, create fresh seed/collection/resources. With an active save, confirmation explicitly says it replaces progress; Cancel preserves it. Replace atomically only after new state is ready. Preserve settings and tutorial preference. |
| Finished save | Home has no resumable run; it may display the last result. Victory/defeat/abandonment cannot reopen rewards or restore a playable completed run. |

Results show outcome, visited rooms, defeated enemies and final collection/relics, with no new leaderboard, permanent reward or detailed analytics subsystem. New Run and Home are explicit actions; never start another run automatically.

## Approved screen composition and proposed behavior

Visual requirements in the second column are approved. Functional contracts in the third column are RC-002 proposals to implement and validate. All gameplay labels/numbers remain live UI text. See [visual references](visual-reference.md) for the originals.

| Screen | Approved visual requirement | Proposed functional contract and ownership |
| --- | --- | --- |
| Home | Moonlit tower, Rune Cast logo, Continue/New Run/Options; turquoise Continue when enabled | **No save:** keep Continue's slot, disabled with “No saved run”; New Run and Options enabled. **Valid active save:** Continue enabled and resumes its exact phase. **Invalid/incompatible save:** disable Continue, show readable recovery status with Recover previous save if validated; offer New Run with explicit replace confirmation, retaining diagnostic/recovery copy until replacement succeeds. No silent deletion or endless loading. RC-024/RC-028/RC-032 own states; RC-015 tower, RC-013 in-game logo/theme, RC-042 production integration, RC-051 distribution identity refinements. |
| Combat | Centered full-body enemy, substantial arena, 4 by 4 board, compact rune name/symbol/value, bottom Menu/Map/Guide/Sound. No player character or separate forecast strip | Tap selects; long-press or explicit Inspect opens a dismissible sheet with cost, ports, behavior and relevant totals. Separate Play action confirms a technique after inspection. Status banner explains invalid circuit/energy and highlights affected cells. Cast shows its own cost and is unavailable when invalid or resolving. A status/details sheet always exposes **Pass turn**, including with an empty hand or broken circuit, with enemy-action confirmation. Selected-piece details expose Flip/Erase without adding a permanent row. RC-008/RC-013/RC-016 own controls; RC-017 locks actions during resolution. |
| Map | Parchment route; turquoise current node, gold next choices, completed checks; bottom navigation; no encounter legend strip | Tap any node to inspect type, known threat/reward and state in a sheet; tapping is not entry. **Current:** Resume room. **Available:** connected next node after current resolution, Enter confirmation commits selection. **Locked:** inspect only with reason; includes unreachable branches. **Visited:** summary only, no replay/reclaim. During combat or pending rewards all future nodes are unavailable; close returns to the exact current screen. Use text/shape cues in addition to colors. RC-025 behavior, RC-013 states, RC-041 parchment/node art, RC-042 integration. |
| Menu | Dimmed gameplay; centered Resume, Options, Shop, Quit; turquoise Resume and matching navy other buttons | Resume/back closes without changing turn or room. Options opens shared settings. **Shop opens the current unresolved shop room only**; enabled there, disabled elsewhere with “Available in a shop room” inspection. It cannot jump ahead on the route, reopen departed stock, or access a real-money store. Quit follows the checkpoint policy above. Keep all four buttons and navy styling, with a readable disabled treatment. RC-013 presentation; RC-029 shop access; RC-032 behavior; RC-042 integration. |

The combat top pause control and bottom Menu open the same overlay. Map opened during battle is inspection only. Guide opens context help; Sound is a persistent master mute shortcut, visibly reflecting Options. Modal close/back returns to its caller without resetting scroll, selection or battle preparation. No overlay grants a turn, refreshes draws or repeats a service. If a transition or combat animation is applying state, lock actions until the transaction finishes; opening UI must not interrupt midway through damage application.

Home and Menu use the same Options component and preference store: independent music/SFX volume/mute (RC-020), reduced motion (RC-017/RC-044), and Guide access. Back returns to Home or the originating Menu. Tutorial replay is available from Home only; in-run Guide remains reference help. Do not add account, language-pack or payment settings for deferred features. RC-044 checks safe areas, touch targets, legible text, focus and shape-based states.

## Experiments deliberately left open

The roster describes roles and bounded effect payloads so these tests can change behavior without renaming IDs or expanding the content count. RC-005 supplies repeatable variants and local observation notes; **RC-006 owns decisions based on human evidence**, and RC-007 applies them. Current behavior remains documented in [gameplay rules](gameplay-rules.md), unchanged by RC-002.

| Question | Current prototype default | Decision needed and affected content/systems | Experiment/evidence | Owner |
| --- | --- | --- | --- | --- |
| Persistent versus consumed effects | Ordinary installed effects persist between turns, outside draw/discard | Whether and where an effect moves after casting; all installed rune roles, draw availability, instance conservation, upgrades and tutorial | Same seeded encounters/collection in persistence and consumed variants; observe editing frequency, empty/useless hands, comprehension and turn time | RC-005 → RC-006; implementation RC-007 |
| Additional Split limits and costs | One Split and one Join total, installed pieces count against allowance; each reachable Split costs 1 energy; Join 0 | Whether extra pieces exist at all, allowance/cost and multiplication limits; boards, energy, damage/shield balance | Compare one-pair baseline with a bounded extra-pair variant, checking cost, solvability and dominant pre-Split stacking. No Split reward/relic is promised in this roster | RC-005 → RC-006; RC-007 |
| Alternate effect ports and board constraints | Fixed 4 by 4; Begin r1c1 and End r4c3; effect ports straight before rotation; no blocked cells | Allowed endpoints, obstacles, effect shapes and accessible board variety; all four layouts, symbols and mobile editing | Compare baseline-solvable layouts first, then isolated obstacle/port variants with known valid solutions; measure readability, bottlenecks and repeated layouts | RC-005 → RC-006; RC-007/RC-009 |
| Single-hit versus multi-hit | One aggregate damage event against one enemy; Split copies damage and shield totals | Keep aggregate or introduce hit semantics; combined rune payload, enemy defense, relic ordering and spell feedback | Compare equal-total casts and observe forecast comprehension/animation cost. Avoid adding on-hit content or multiple targets before decision | RC-005 → RC-006; RC-007/RC-033 |
| Temporary-rune expiry geometry | Every installed temporary, even disconnected, becomes straight wire with its rotation; hand temporaries vanish | Straight replacement, retained connector shape or empty cell; generated runes, any alternate ports, undo and circuit repair | Repeated cast/pass/unused/disconnected cases and new-player repair attempts; inspect unexpected broken circuits | RC-005 → RC-006; RC-007 |
| Reset versus retain between encounters | No encounter transfer implemented. Existing planned default is reset board, retain collection; Restart only rebuilds the training fixture | What topology and installed instances transfer; run pacing, ownership, upgrades, board changes, saves/tutorial | Controlled back-to-back fixture encounters with reset and retain variants; measure setup time, repeated layouts and exact card conservation | RC-005 → RC-006; RC-007 contract and RC-026 transfer |

RC-005 may use a small paired-encounter harness for the final experiment without requiring the later full route/save systems. This avoids a dependency cycle. If a choice fails testing, revise the affected row/values within the family budget before RC-035 content production; do not present this document as overriding RC-006.

## External prerequisites and owner inputs

Unknown access does not block this specification. These are tracked inputs to later tasks, not statements that hardware or accounts are absent. No credentials are requested or configured by RC-002.

| Prerequisite ID | Known state on October 8, 2026 | Responsible party / next task | Evidence needed later |
| --- | --- | --- | --- |
| `external_android` | Windows preview exists; Android preset is a placeholder; import reports unconfigured build-tools. Physical Android devices and SDK/JDK/templates availability beyond recorded checks are unknown | Owner identifies available devices; RC-021 establishes build/device baseline; RC-047–RC-049 verify | Actual device/OS/build identifiers, install/touch/lifecycle results, minimum-device proposal |
| `external_ios` | No recorded iOS build/test. Mac, Xcode and iPhone/iPad access unknown | Owner arranges access; RC-022 setup; RC-047–RC-049 acceptance | Mac/Xcode/toolchain and physical-device details, signing-capable development build and observations |
| `external_distribution` | Android signing/store and Apple developer/signing/store access unknown; no access inferred from Git configuration | Owner controls accounts; RC-021/RC-022 development access; RC-052 release identity/signing; RC-053/RC-054 packaging | Confirm access without recording secrets, signing procedure and distribution path |
| `external_identity` | Rune Cast name approved; studio/legal identity, support contact and final app IDs undecided. `com.example.runecast` remains development placeholder | Owner supplies identity choices; RC-052 identifiers; RC-051 art; RC-056 support/store materials | Agreed package/bundle IDs, credited publisher and support details before release configuration |
| `external_playtest` | No human participant availability or observed human run results recorded | Owner recruits/arranges participants; RC-006 mechanics, RC-023 encounter, RC-045 full runs, RC-055 beta | Recorded first-time/returning participant observations and device context; actual access gates those tasks |

No unanswered product choice currently prevents a coherent draft. The owner can revise the proposed Menu Shop restriction, battle replay policy, no-metaprogression scope or counts before their owning implementation tasks. Minimum OS/device support and publisher identity remain later inputs, not invented approvals. Trailer production is deferred; RC-056 uses honest screenshots and store materials.

## Acceptance gates

### First polished encounter — RC-023

- Selected RC-006 rules are implemented, reproducible and described accurately; core and UI checks pass for changes actually made.
- The Shadeling encounter uses one accepted board and starter resources, production arena/character/UI, touch inspection, valid/invalid circuit feedback and accessible Pass turn. No extra forecast strip or player character appears.
- Ordered animation/audio match actual outcomes; double input cannot duplicate actions; lethal casts suppress retaliation. Settings and reduced motion work as scoped.
- First-time human players can understand intent, cast, repair after expiry and finish the encounter; observations and any remaining comprehension tradeoffs are recorded.
- Android and iOS physical-device evidence includes touch, text, safe areas, audio and basic lifecycle behavior. A desktop screenshot is insufficient. Missing access keeps RC-023 open while independent work proceeds.

### Complete first release — RC-042 through RC-060

- All roster families meet the bounded totals, stable IDs and task ownership; every new effect/hook has an implementation and validation, not just an unchecked JSON entry.
- New Run/Continue, all six room types, rewards, collection, services, guardian victory, defeat, abandon and results/Home complete end to end. No unreachable route or mandatory unaffordable choice can softlock a run.
- Permanent instance conservation and temporary exclusion hold across battles, upgrades, rewards, saves and interruption. Duplicate rewards/purchases and completed-run resurrection fail safely.
- Four approved screens appear in actual runtime with the defined no-save/invalid-save/locked/disabled/confirmation states. Production artwork and sound replace required placeholders and have provenance; references/source masters are excluded from builds.
- Human full-run evidence supports 15–25 minutes; RC-045 records tuning and unresolved tradeoffs. All four boards and five enemies have practical responses with intended collections.
- Offline fresh install/update, settings, atomic save recovery, background/termination and sustained play pass the selected physical-device matrix; performance and safe-area budgets are measured, not assumed.
- Signed release candidates, credits, application identity, accurate store material and external beta issues are resolved. Store submission/release occurs only in later authorized RC-058/RC-059 tasks; RC-060 records public acceptance.

### Explicit deferrals

Multiple simultaneous enemies/target selection; poison/armour/status families; permanent meta unlocks; additional characters, biomes, generated-rune families or currencies; crafting/consumables; cloud saves/accounts; multiplayer; online analytics; ads/IAP/real-money shops; daily/endless modes; translation production; desktop release; landscape/separate tablet layouts; trailer and extra music tracks. Mid-turn disk resume is deferred in favor of the stated replay policy. Experimental mechanics above are **undecided**, rather than categorically excluded.
