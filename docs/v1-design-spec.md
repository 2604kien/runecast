# Rune Cast first-release design specification

RC-002 design baseline, October 8, 2026. This document defines the bounded release to build; it does not claim those features exist. The current product is one playable training encounter. See the [content roster](content-roster.md), [task plan](project-plan.md), and [implemented gameplay rules](gameplay-rules.md).

**October 9 RC-007 acceptance:** the owner answered **“Accept all default.”** to the consolidated proposal. The [accepted production contract](production-rules-spec.md#october-9-2026--accepted-rc-007-implementation-contract) now fixes full clearing, finite kits, random player-rotatable endpoints, straight effects/no blocked cells, Split1/Join0, aggregate hits, cleanup/terminal order and compatible encounter transfer. RC-007 is implemented and complete, with 1063 core / 333 UI and 52 rendered checks passing; see the final verification and handoff. This is a design selection, not new human evidence or a testing waiver. No content budget, new effect or later-task scope is added.

## Authority and scope

**Owner-approved direction:** Rune Cast; Godot; Android and iOS; portrait 4 by 4 circuit play; connected Begin and End; Split/Join amplification; deckbuilding with techniques and generated free runes; and the four October 8 [Home, Combat, Map and Menu visual references](visual-reference.md). Their composition supersedes earlier mockups. Visual approval does not approve the illustrative numbers, enemy rank labels, economy or screen behavior.

**Proposed working defaults:** scope quantities, content names, numeric values, flows and policies below remain recommendations unless explicitly identified as an RC-006 owner selection. The October 9 connector-kit choice is provisional owner direction, not validated balance. RC-006 still owns the six core experiments. RC-036/RC-045 tune numbers within this budget; expanding content families requires an explicit scope revision.

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
| Boards | Four stable 4 by 4 board IDs, introductory through guardian; random endpoints, no blocked cells and straight effects under the accepted contract | RC-009 |
| Permanent definitions | Twelve total runes/techniques, including `spark`, `shield`, `focus`, `conjure` | RC-004, RC-035 |
| Generated definitions | One additional `free_spark`; excluded from twelve and from permanent ownership | RC-007, RC-035 |
| Progression | Six unique relics; four authored events; eight single-rank rune upgrades | RC-031, RC-035, RC-036 |
| Room types and services | Six room types; two recovery options; four shop service types; one run-only currency, Gold | RC-029, RC-030, RC-036 |
| Environment | One layered crypt, with base/recovery/guardian lighting variants reusing the same geometry; one separate Home tower illustration | RC-015 |
| UI and identity | Reusable theme/icons, parchment map treatment, Home logo, dialogs, rewards/results; one app icon family | RC-012, RC-013, RC-041, RC-051 |
| Motion and sound | Five character packs sharing idle/attack/hit/defeat contracts; core spell/UI effects and SFX; two music loops (Home/exploration and combat), one crypt ambience bed | RC-017–RC-020, RC-037–RC-042 |

Use shared effects/cues wherever possible. Bound the effect work to circuit traversal, impact, shield, enemy attack telegraph, technique/temporary creation, expiry, victory and defeat families. Guardian intensity can reuse combat music and shared effects; no third music track, second biome, event character packs or separate shopkeeper actor is required. Home tower art is a separate composition, not a crop of the crypt. Detailed dimensions, animation frames, audio cue lists, provenance and complete manifest expansion belong to RC-010.

## Tutorial, collection and initial resources

Offer a short, skippable tutorial before the first run. RC-043 must teach the accepted endpoints-only opening, construction, endpoint Rotate, finite stock, one Cast, full cleanup/rebuilding, energy, techniques, inspection and Pass. Preserve the reproducible `training_shadeling` prebuilt circuit as an explicit historical reference fixture; it is not an approved production tutorial exception. Then teach the route and one reward in the first real run. Tutorial time is excluded from the repeat-run duration target. Home Options provides tutorial replay; it uses separate practice state and does not replace an active run, grant Gold or transfer cards. RC-043 owns guided steps, skip/replay and local tutorial-completion preference.

The working starter values are 30/30 health, 3 energy per turn, draw 3 per turn, **zero Gold and zero relics**. The starting permanent collection has eight instances: two each of Spark (`spark`), Shield (`shield`), Focus (`focus`) and Conjure Spark (`conjure`). All twelve definitions are eligible content from the first run; there are no account unlocks, persistent currency or power progression between runs.

**Selected circuit supply, provisional tuning values (RC-006 H31, confirmed by October 9 acceptance):** one randomly selected ten-piece kit at the start of each playable turn, independently of the normal rune-card hand. This supersedes unlimited ordinary wires and fixed one-pair production supply. RC-007 now implements this supply in normal gameplay; historical experiment fixtures retain their own semantics.

| Kit | Straight | Corner | Split | Join | Total |
| --- | --- | --- | --- | --- | --- |
| Extra straight pieces | 6 | 2 | 1 | 1 | 10 |
| Extra corner pieces | 4 | 4 | 1 | 1 | 10 |
| Extra branching pair | 4 | 2 | 2 | 2 | 10 |

Select each kit with equal probability. Split and Join arrive as matched pairs. Placing a connector uses the current supply; erasing or replacing it returns it to that supply, and Undo restores the corresponding counts. Rotation, erasing and Undo remain free. Unused connectors do not accumulate between turns; each new playable turn receives a fresh kit. Connector supply is separate from permanent card ownership and the ordinary rune draw/discard cycle. The kit counts, balance and integration with random endpoints and rebuilding remain untested with a player. Equal piece counts do not establish equal usefulness. Each powered physical Split costs 1 energy per Cast, Join 0; the selection introduces no new reward, relic or currency system.

Draw the first production hand normally from the shuffled permanent collection. Every production turn starts with only Begin and End, and accepted Cast/Pass sends all installed permanent cards, including disconnected ones, to discard before a fresh normal draw; repeats are allowed. First endpoint selection covers all 240 ordered distinct-cell pairs; later turns choose among 211 pairs moving both endpoints, with cross-swaps allowed and independent rotations 0–3. Players can Rotate/Undo endpoints. Card, endpoint and kit randomness use separate streams; fresh setup/Exact replay reseed, ordinary Restart continues them. Exact cleanup, event, terminal and encounter-transfer boundaries follow the [accepted contract](production-rules-spec.md#october-9-2026--accepted-rc-007-implementation-contract). The prebuilt training fixture and curated hand remain historical examples, not production prefills or onboarding exceptions. Generated Free Spark never counts as a ninth owned card. Other numeric starter values remain tuning defaults.

| Concept | Ownership and lifecycle contract |
| --- | --- |
| Permanent run collection | The authoritative multiset of card instances owned for this run, each with an instance identity and definition ID. Rewards add instances; removal deletes one; upgrades modify one. It is not a global metagame collection. This run-level model is new work. |
| Battle hand | Available normal instances plus separately marked temporary instances. A normal instance cannot simultaneously be in another battle zone. The foundation has no hand cap; use a scrolling hand before adding a retention/cap mechanic. |
| Draw and discard | Draw from shuffled normal instances; recycle discard when draw is empty. Unplayed normal hand cards discard at turn end. Techniques pay and move to discard immediately before resolution; ordinary technique play is not a discard-trigger mechanic. |
| Installed effects | A permanent installed instance is absent from hand/draw/discard; replacement returns it to hand. After accepted Cast/Pass, all installed permanents enter discard exactly once, including disconnected ones. Board cleanup precedes hand cleanup and normal draw; repeated cards are allowed. |
| Temporary runes | Generated `free_spark` costs zero and disappears at cleanup even when unused/disconnected, including terminal cleanup. No connector remains. Temporaries never enter permanent collection, draw/discard, upgrade/removal choices or future battles. |
| Encounter boundary | Once after victory, carry current/max HP without healing and reconcile compatible permanent instances exactly once in UID order before continued shuffle/normal draw. Delete temporaries; reset turn/energy/shield/Undo using the next configuration, with fresh first-turn endpoints/kit and continued RNG. Reject incompatible/repeated transfer without mutation. RC-024/RC-026 integrate this boundary into the later run model. |

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

This heading and the experiment plan below preserve the original RC-002 decision process. **The choices are now resolved by the owner's October 9 “Accept all default.” decision**, with full boundaries in the [accepted contract](production-rules-spec.md#october-9-2026--accepted-rc-007-implementation-contract). RC-007 is complete. Historical controlled alternatives remain reproducible; future changes require an explicit new decision. Owner acceptance is not a matched-comparison result or a testing waiver.

The following status paragraphs and experiment table are **historical, before that acceptance**. The roster retains bounded effects and IDs; no new content family follows from a fixture alternative.

**RC-006 status, October 9, 2026: partial.** The owner selected endpoints-only starts every turn after Cast/Pass, all installed permanent cards to discard (including disconnected ones), and fresh normal draws with repeats allowed. These choices remove topology carry/replacement connectors without guaranteeing a different hand. In the separate `effects/full_reset` follow-up, the owner confirms clearing works and the hand changes, corroborated by two recorded Casts. The owner reports rebuilding worthwhile and selects random Begin/End positions every turn at any two distinct cells, including adjacent cells, with normal player-controlled Rotate. The moving-endpoint feedback confirms clearing and corrects the facilitator's protected-rotation/eight-layout interpretation; the separate [free-endpoint follow-up](circuit-experiments.md#rc-006-free-endpoint-follow-up) is available. The owner confirms manual endpoint rotation works; S01-08 records seven accepted rotations across Begin and End. It contains no Cast, Pass, Undo or adjacent-position play, so those outcomes are not inferred. The played full-reset fixture uses fixed endpoints.

Both matched B1 stock variants have now been played, with one recorded Cast in each and retrospective “as expected” feedback. Their chosen circuits differ, so the results do not establish that one allowance is better. H31 provisionally selects the three random ten-piece kits above after the owner requested finite/random circuit supply; those kits have not been implemented or human-tested. Normal production rules remain unchanged. B2 Split/Join costs, remaining endpoint details/effect ports, hit semantics, exact production timing and encounter state remain unresolved. Literal endpoints-only starts also require explicit blocked-cell compatibility resolution. See [evidence and selections](rc-006-playtest-results.md) and the [pending production contract](production-rules-spec.md); RC-007 is not generally ready.

| Question | Current prototype default | Decision needed and affected content/systems | Experiment/evidence | Owner |
| --- | --- | --- | --- | --- |
| Persistent versus consumed effects | Ordinary installed effects persist between turns, outside draw/discard | Owner selected all installed permanents to discard after Cast/Pass, including disconnected ones, then normal draws with repeats allowed. Exact timing remains unresolved. Recheck installed roles, draw usefulness, conservation, upgrades and tutorial | Same seeded encounters/collection in persistence and consumed variants; observe editing frequency, empty/useless hands, comprehension and turn time. Historical variants do not implement the selected complete reset | RC-005 → RC-006; implementation RC-007 |
| Limited connectors and Split costs | Normal gameplay has unlimited straight/corner pieces and one Split/Join pair; each reachable Split costs 1 energy; Join 0 | H31 provisionally selects a fresh random ten-piece kit per playable turn: Straight/Corner/Split/Join counts 6/2/1/1, 4/4/1/1 or 4/2/2/2. B2 costs and integrated balance remain unresolved | Both original B1 variants were played; the new kits still need implementation and playtesting for useful limits, routing and amplification. No connector reward/relic or new currency is promised | RC-005 → RC-006; RC-007 |
| Alternate effect ports and board constraints | Fixed 4 by 4; Begin r1c1 and End r4c3; effect ports straight before rotation; no blocked cells | Owner selected random Begin/End positions each turn at any two distinct cells, including adjacent cells, with normal player-controlled Rotate. Initial orientation generation and first turn remain unresolved, as do obstacles and effect shapes; all four layouts, symbols and mobile editing are affected | Manual endpoint rotation is owner-confirmed and corroborated by seven accepted rotations in the free-endpoint follow-up; human turn/adjacency outcomes remain absent. Earlier moving-endpoint rotation is protected and the full-reset fixture uses fixed endpoints. Compare baseline-solvable layouts first, then isolated obstacle/port variants with known valid solutions; measure readability, bottlenecks and repeated layouts | RC-005 → RC-006; RC-007/RC-009 |
| Single-hit versus multi-hit | One aggregate damage event against one enemy; Split copies damage and shield totals | Keep aggregate or introduce hit semantics; combined rune payload, enemy defense, relic ordering and spell feedback | Compare equal-total casts and observe forecast comprehension/animation cost. Avoid adding on-hit content or multiple targets before decision | RC-005 → RC-006; RC-007/RC-033 |
| Temporary-rune expiry geometry | Every installed temporary, even disconnected, becomes straight wire with its rotation; hand temporaries vanish | Owner selected no replacement connector at the next-turn boundary. Exact cleanup sequence, generated hand/disconnected cases and geometry compatibility still need a complete contract | Repeated cast/pass/unused/disconnected cases and new-player repair attempts; inspect unexpected broken circuits | RC-005 → RC-006; RC-007 |
| Reset versus retain between encounters | No normal progression implemented; RC-005 has a provisional paired-encounter harness | Owner selected endpoints-only starts for every turn, excluding topology carry. Permanent-card reconciliation and remaining encounter state still need confirmation | Controlled back-to-back fixture encounters with reset and retain variants; measure setup time, repeated layouts and exact card conservation. Historical variants do not implement the selected complete reset | RC-005 → RC-006; RC-007 contract and RC-026 transfer |

RC-005 may use a small paired-encounter harness for the final experiment without requiring the later full route/save systems. This avoids a dependency cycle. If a choice fails testing, revise the affected row/values within the family budget before RC-035 content production; do not present this document as overriding RC-006.

## External prerequisites and owner inputs

Unknown access does not block this specification. These are tracked inputs to later tasks, not statements that hardware or accounts are absent. No credentials are requested or configured by RC-002.

| Prerequisite ID | Known state (October 8, 2026 baseline; later updates dated) | Responsible party / next task | Evidence needed later |
| --- | --- | --- | --- |
| `external_android` | Windows preview exists; Android preset is a placeholder; import reports unconfigured build-tools. Physical Android devices and SDK/JDK/templates availability beyond recorded checks are unknown | Owner identifies available devices; RC-021 establishes build/device baseline; RC-047–RC-049 verify | Actual device/OS/build identifiers, install/touch/lifecycle results, minimum-device proposal |
| `external_ios` | No recorded iOS build/test. Mac, Xcode and iPhone/iPad access unknown | Owner arranges access; RC-022 setup; RC-047–RC-049 acceptance | Mac/Xcode/toolchain and physical-device details, signing-capable development build and observations |
| `external_distribution` | Android signing/store and Apple developer/signing/store access unknown; no access inferred from Git configuration | Owner controls accounts; RC-021/RC-022 development access; RC-052 release identity/signing; RC-053/RC-054 packaging | Confirm access without recording secrets, signing procedure and distribution path |
| `external_identity` | Rune Cast name approved; studio/legal identity, support contact and final app IDs undecided. `com.example.runecast` remains development placeholder | Owner supplies identity choices; RC-052 identifiers; RC-051 art; RC-056 support/store materials | Agreed package/bundle IDs, credited publisher and support details before release configuration |
| `external_playtest` | October 9: one owner session `RC006-S01`, practice participant-reported, mouse confirmed. Treatment feedback reports predicted damage/new cards and requests complete board clearing. The full-reset relaunch has owner-confirmed clearing/changed hands and two corroborating Casts with different constructed circuits. The owner reports rebuilding worthwhile while requesting per-turn endpoint movement. Later moving-endpoint feedback confirms clearing and requests normal player rotation at unrestricted distinct positions, including adjacent cells; no enjoyment/readability finding is reported. The corrected free-endpoint control is owner-confirmed with seven accepted rotations on both endpoints; no Cast/Pass/Undo or adjacency attempt is recorded there. Both B1 stock variants were played, one Cast each, with retrospective expected-result feedback. H31 accepts provisional random finite kits; their balance and integration have no human evidence yet. See [RC-006 evidence and attribution](rc-006-playtest-results.md). “First game created” describes creation experience, not playing familiarity. No future availability inferred | Owner is the first RC-006 participant; retain the recorded familiarity limits and plan later balance/usability studies without reconfirming accepted choices. Owner arranges participation separately for RC-023 encounter, RC-045 full runs and RC-055 beta | Actual predictions, observations/preferences, records and device/input context; disclose owner familiarity and assistance. An owner-only desktop session does not establish first-time-player or mobile acceptance |

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

Multiple simultaneous enemies/target selection; poison/armour/status families; permanent meta unlocks; additional characters, biomes, generated-rune families or currencies; crafting/consumables; cloud saves/accounts; multiplayer; online analytics; ads/IAP/real-money shops; daily/endless modes; translation production; desktop release; landscape/separate tablet layouts; trailer and extra music tracks. Mid-turn disk resume is deferred in favor of the stated replay policy. Experimental alternatives above remain historical opt-in fixtures. Production follows the accepted RC-007 contract; those alternatives do not authorize extra mechanics or content.
