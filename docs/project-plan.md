# Rune Cast project plan

Planning baseline: October 7, 2026. This is the master task list for taking the existing Godot sandbox to a first Android and iOS release. It includes design, implementation, asset preparation, integration, testing, and delivery.

Each `RC-###` is intended to become a separate chat prompt. Tasks should be rechecked against the repository when their prompts are requested; implementation begins with those later task requests.

## Current starting point

The repository already contains a playable single training encounter, not a tower run. Preserve this work and extend it.

| Foundation already present | Evidence and limits |
| --- | --- |
| Godot portrait project and local launch tooling | Pinned Godot 4.7.2 Standard/GDScript, Compatibility renderer, 720 by 1600 design canvas. |
| Circuit construction and evaluation | 4 by 4 board; Begin/End; straight/corner wires; Split/Join; rotation, flip, erase, undo; validity and energy checks. |
| Training combat and hand management | Spark, Shield, Focus, Conjure Spark, generated Free Spark; one Shadeling encounter; temporary expiry; cast/pass/restart. |
| Prototype interface | Code-drawn enemy, environment, board and controls; Menu, Guide, Sound; Map is a placeholder. Only sound preference is saved. |
| Approved art direction | Four final references approved October 8, 2026: [Home](../output/imagegen/approved/home.png), [Combat](../output/imagegen/approved/combat.png), [Map](../output/imagegen/approved/map.png), and [Menu](../output/imagegen/approved/menu.png). These supersede older mockups, including v5, and are references rather than layered runtime artwork. |
| Desktop verification | The [verification record](verification.md) preserves October 7 evidence and records the October 8 RC-001 rerun: version/import passed, 23 core checks and 11 UI checks passed, and a fresh Windows capture was visually inspected. Android build-tools configuration remains outstanding. |
| Mobile export presets | Present with placeholder identifiers. No installable Android/iOS build or physical-device acceptance is recorded. |
| Version control | RC-001 started on `master` with no commits, tracked files, or remotes. The reviewed baseline is staged (70 files); a later `project.godot` change is preserved unstaged. Commit remains pending because the owner will configure the missing Git author name after this task. RC-001 remains partial. |

Source documents: [game design](game-design.md), [gameplay rules](gameplay-rules.md), [decisions](decisions.md), [art direction](art-direction.md), [visual reference](visual-reference.md), [asset inventory](asset-inventory.csv), and [setup](setup.md).

## Proposed first-release scope

Existing direction stays: portrait mobile play, a 4 by 4 circuit, one centered enemy without a visible player character, cartoon fantasy art, branching tower progression, and runs targeting 15–25 minutes. Preserve compact rune choices, the substantial enemy arena, bottom Menu/Map/Guide/Sound navigation, and no separate forecast bar above Cast.

The following quantities are **planning proposals**, not previously approved requirements. RC-002 should confirm or revise them before content production:

| Area | Small first-release target |
| --- | --- |
| Playable setup | One spellcaster/loadout and one tower theme; tutorial plus a repeatable complete run. |
| Route | Approximately 8–10 visited rooms per run, including the guardian; alternate branches include normal combat, elite combat, shop, recovery and events. Adjust room count to measured run time. |
| Enemies | Five distinct designs: three normal, one elite, one guardian. Assign Shadeling a role in RC-002; its reference appearance does not force it to be the guardian. |
| Boards | Four authored board layouts, including an accessible introductory layout. Variations depend on RC-006 decisions. |
| Runes and techniques | Twelve permanent card definitions in total, including the four current permanent definitions; generated Free Spark is additional and not a collection card. |
| Progression content | Six relics, four events, and a bounded upgrade set for the chosen runes. |
| Presentation | One layered crypt environment with inexpensive room/lighting variants; five character packs; complete UI/icon kit; core effects and sound cues; two looping music tracks plus ambience. |
| Product | Offline, single-player, English first release with local saves. Keep UI text maintainable for later translation. |

Multiple simultaneous enemies, online accounts/cloud saves, multiplayer, ads/IAP, daily challenges, endless modes, extra characters/biomes, and translation production are deferred unless scope changes explicitly add them. No backend is needed for the proposed release.

No calendar estimates are assigned: availability, asset iteration, device access, and playtest results are not known. Dependencies and milestone evidence determine the order.

## How to use this plan across separate chats

Follow [the development workflow](development-workflow.md) for Git inspection, shared-checkout coordination, validation, and checkpoints. RC-001's handoff below records the remaining checkpoint prerequisite.

1. Start with RC-001 and RC-002. Ask for a prompt by ID, for example: **“Give me the prompt for RC-008.”**
2. Each future prompt should read the current plan, applicable repository instructions, prerequisite outcomes, and relevant design files. It should name one task, the files it owns, deliverables, exclusions, and completion checks.
3. Run core/UI/state-changing tasks sequentially in the same checkout. Separate chats do not automatically coordinate changes. Parallel art/audio tasks should use distinct asset folders and individual delivery notes; integrate their shared inventory updates afterward in one chat.
4. At completion, update the task checkbox and append a handoff entry below with changed files, decisions, validation, and remaining blockers. Preserve stable IDs; append new tasks or suffix a split task instead of renumbering completed work.
5. A task is complete only when its stated acceptance evidence exists. Record partial work and external blockers rather than checking it off. An asset file, desktop screenshot, or export preset alone does not prove in-game/device acceptance.

Dependency lists below name direct prerequisites; their prerequisites apply transitively. Lower task numbers are a useful reading order, not a requirement to finish every earlier row. `RC-012–RC-015` means all tasks in that range. All 60 tasks started unchecked; consult their current status and handoffs. The completed foundation above is not being recreated.

## Phase 1 — Scope, foundations, and core design decisions

| Status / ID | Task and deliverable | Depends on | Complete when |
| --- | --- | --- | --- |
| [ ] **RC-001** | **Establish the development baseline and task workflow.** Inspect the untracked project, confirm ignore rules, rerun existing checks, capture the starting screen, and create an initial local checkpoint when executing this task. Record the local branch/commit workflow for later chats; configure a remote only if requested. | Existing repository | The project can be restored to a known baseline, recorded checks have actual results, and future task handoffs can identify their starting and ending revisions. |
| [ ] **RC-002** | **Define the first-release design and content roster.** Confirm the scope proposals above; assign stable working names/roles to enemies, runes, relics, rooms, and boards. Define run structure, victory/defeat, starter collection, presentation needs, and exclusions. Record platform/device access and unresolved owner decisions. | RC-001 | A bounded v1 specification and content checklist exist. New proposals are distinguished from approved direction; unresolved mechanics are assigned to RC-006 rather than silently finalized. |
| [ ] **RC-003** | **Separate combat state from screen presentation.** Refactor the current large screen only as needed into reusable controls/presenters. Expose ordered combat events for cast, damage, shield, retaliation, expiry and battle end. Define input locking and animation completion without changing the current rules. | RC-001 | The training encounter behaves as before, existing checks pass, and a presentation consumer can observe ordered outcomes without applying combat effects twice. |
| [ ] **RC-004** | **Add validated content definitions and configurable battle setup.** Establish stable IDs and schemas for runes, boards, enemies/intents and encounter/loadout configuration. Inject player stats, owned cards, inventory and encounter settings; replace unchecked JSON assumptions and hardcoded UI maximums/names. | RC-002, RC-003 | The original encounter and a second test configuration load correctly. Invalid/missing content yields useful errors; unsupported effects cannot silently become Conjure. UI values come from state. |
| [ ] **RC-005** | **Build controlled circuit-design experiments.** Add a small experiment mode/configuration for persistent versus consumed effects and selected board/port variations. Add reproducible seeds and lightweight local observation notes or debug counters for edits, casts and turn duration. | RC-004 | Comparable scenarios can be replayed without changing production defaults. The experiment exposes layout repetition and useful-card depletion; it does not introduce an online analytics service. |
| [ ] **RC-006** | **Playtest and settle the core rules.** Compare the experiments with actual player observations. Decide effect lifetime, additional Split limits/costs, allowed port/board variations, one-hit versus multi-hit scope, temporary expiry geometry, and circuit reset between encounters. | RC-005 | Decisions and evidence are recorded in gameplay rules/decisions. The chosen approach gives a reason to reshape circuits; unresolved results trigger another focused iteration before content expansion. This requires human playtest participation. |
| [ ] **RC-007** | **Implement the selected production rules.** Apply RC-006, including configurable endpoints/blocked cells only where selected. Keep card ownership, replacement/undo, temporary cleanup and energy rules consistent. Remove or isolate experiment-only behavior. | RC-006 | Focused regression checks cover the selected rules, Split/Join edge cases, alternate boards and card conservation. Updated rules explain any changed opening-circuit result. |
| [ ] **RC-008** | **Make board editing and rune inspection work on touch.** Add long-press or explicit inspection, cost/behavior details, placement preview and failure feedback, selection/cancel states, usable rotate/flip/undo/erase controls, and scrolling for larger hands. | RC-007 | A player can inspect and edit without tooltips or hover. Inspection does not accidentally place/play a card; scroll/tap conflicts are addressed. Compact rune choices remain intact. |
| [ ] **RC-009** | **Author and validate the board set.** Create the four proposed layouts or the revised RC-002 count, with endpoints, obstacles/ports where approved, opening setup, difficulty intent, and known valid example solutions. | RC-004, RC-007 | Each layout is playable with its intended starter resources, cannot violate endpoint rules, and contributes a distinct spatial decision. Reference/tutorial setup remains available. |

## Phase 2 — Asset preparation and the first polished encounter

Production art follows the approved reference, but must be delivered as separate usable assets. Do not crop the complete mockup into the game or bake live labels, health, energy, values, costs, or circuit paths into backgrounds.

| Status / ID | Task and deliverable | Depends on | Complete when |
| --- | --- | --- | --- |
| [ ] **RC-010** | **Create the asset manifest and production contracts.** Expand the inventory to cover the scoped roster and screens. Define source/runtime paths, naming, dimensions, enemy foot anchors, layer origins, alpha handling, icon geometry, scalable-frame margins, animation states, audio formats and initial memory budgets. | RC-002 | Every planned asset has an ID, task owner, game use, delivery specification and status. Records support source/creator, generation prompt where relevant, edits, licence/attribution and runtime path. Unknown specifications are resolved before affected production. |
| [ ] **RC-011** | **Produce and review a matching style pilot.** Prepare one Shadeling illustration, one Spark tile treatment and one button, previewed together at game scale against v5. Select the font direction and animation approach before mass production. | RC-010 | A chosen style set is recorded after visual review, reads at phone size, and has clean source files. This fulfills the art-direction checkpoint; it is not approval of every future asset. |
| [ ] **RC-012** | **Prepare typography and the core symbol library.** Deliver licensed fonts and editable SVGs for starter runes, temporary distinction, Begin/End, Split/Join, wires, editing controls, health/energy, initial intents, and bottom navigation including sound states. | RC-007, RC-011 | Symbols work at actual control sizes and in monochrome. Ports align exactly; wire geometry stays precise. Font licence and attribution are recorded, and imports are verified. |
| [ ] **RC-013** | **Prepare the reusable UI theme.** Create board sockets, rune frames, panels, bars, buttons and dialogs with normal, pressed, selected, disabled, focus, temporary and invalid states. Deliver editable sources, runtime exports and Godot theme resources. | RC-008, RC-011 | Frames scale without broken borders, text remains live, and a theme preview covers interaction states and short/tall portrait layouts. |
| [ ] **RC-014** | **Prepare the production Shadeling character pack.** Refine the pilot into a transparent full-body sprite with source master, foot anchor, consistent scale, and any separate parts/poses needed for idle, attack, hit and defeat. | RC-011 | Alpha edges and silhouette are clean; lantern/cloak/extremities fit the animation envelope; the pack has a preview and import settings. Role/name follows RC-002. |
| [ ] **RC-015** | **Prepare the layered crypt environment.** Produce aligned background and floor layers plus optional foreground and simple room lighting variants. Keep the centered enemy silhouette and intent/health areas readable. | RC-011 | Layers have source masters and tested runtime exports, cover intended portrait crops, and contain no character, UI, live text or circuit artwork. |
| [ ] **RC-016** | **Integrate the first encounter's production art.** Replace placeholder arena/UI imagery using reusable scenes/themes and asset references. Bind all values to game state while preserving the approved layout hierarchy. | RC-009, RC-012–RC-015 | Actual runtime captures show the imported assets, readable board connections and compact hand. The current approved circuit rules still pass; no unintended forecast strip or player character is added. |
| [ ] **RC-017** | **Add combat animation and spell feedback.** Consume ordered combat events for idle, cast traversal, hit, shield, attack, expiry, victory and defeat. Create editable Godot animations/effect scenes and a reduced-motion path. | RC-003, RC-007, RC-016 | Visual sequence matches actual outcomes, double taps cannot cast twice, lethal hits suppress retaliation, and transitions wait safely without obscuring actionable information. |
| [ ] **RC-018** | **Prepare the sound-effect library.** Deliver normalized source and runtime audio for UI, placement/editing, invalid action, technique, cast, impact/shield, enemy action, reward and battle results. Map each cue to an event. | RC-010, RC-011 | Cues have consistent levels, no clipping, traceable sources and a listening preview. Future-only cues remain clearly marked until integrated. |
| [ ] **RC-019** | **Prepare music and ambience.** Produce or source the scoped menu/exploration and combat loops plus crypt ambience, with loop points, source masters, runtime exports and credits information. | RC-010, RC-011 | Loops transition without audible seams, support the intended tone, and have documented usage rights and levels. A guardian variation is optional unless RC-002 includes it. |
| [ ] **RC-020** | **Implement audio playback and settings.** Add music/SFX buses, independent volume/mute persistence, event-driven cues, scene transitions and suspend/resume behavior. Connect RC-018/RC-019 and replace the temporary cast tone. | RC-017–RC-019 | Sound settings survive restart, cues are not duplicated, music does not stack across scenes, and mute/reduced volume work consistently. |

### Asset delivery checklist for every production task

- Supply editable or high-resolution source masters separately from runtime files; record how generated assets were made/refined and retain relevant prompts.
- Use each asset's agreed ID, path, dimensions, origin/anchor, animation states and import settings. Do not assume a full-screen reference is production-ready.
- Provide a contact sheet, isolated preview or listening sample and an in-game scale preview as appropriate. Character alpha, SVG import and frame scaling must be checked.
- Keep text and numerical state in Godot controls. Distinguish gameplay states through shape/symbol as well as colour.
- Record provenance, licence/attribution and readiness. Use states such as `planned`, `source-ready`, `runtime-ready`, `integrated`, and `device-verified` so production and integration are not confused.

## Phase 3 — Early mobile builds and playable milestone

RC-021 and RC-022 can begin soon after scope is defined, in parallel with design/art work. Device access is an external prerequisite, not something a Windows preview can substitute for.

| Status / ID | Task and deliverable | Depends on | Complete when |
| --- | --- | --- | --- |
| [ ] **RC-021** | **Create the Android development build path.** Check the pinned engine's current official requirements, configure matching export templates/SDK/JDK, choose a development identifier, export a debug APK and document reproducible commands. | RC-001, RC-002; Android device/access | A build installs and launches on a physical device. Touch, font rendering, audio, safe areas, orientation and basic pause/resume have observed results; exact device/build details are recorded. |
| [ ] **RC-022** | **Create the iOS development build path.** Prepare the project on macOS with matching templates/Xcode, configure development signing and export/build the Xcode project. | RC-001, RC-002; Mac, Xcode, signing access and iOS device | A build installs and launches on a physical iOS device, with touch/layout/audio/lifecycle observations and reproducible setup notes. If access is unavailable, record the blocker and leave this task open. |
| [ ] **RC-023** | **Accept the first polished playable encounter.** Playtest the selected rules and finished first encounter on the supported platforms. Evaluate comprehension, circuit reshaping, touch comfort, phone readability and visual/audio feedback; fix milestone blockers. | RC-008, RC-009, RC-016, RC-017, RC-020–RC-022 | First-time players can complete the intended encounter, actual device evidence exists for both platforms, and serious usability/rule defects are resolved. Record the decision to proceed with the remaining content assets. |

**Milestone 1:** a polished, understandable encounter on Android and iOS. Run-system engineering below can advance while an external device prerequisite is pending; RC-023 and device-dependent content acceptance remain open until verified.

## Phase 4 — Complete run systems

| Status / ID | Task and deliverable | Depends on | Complete when |
| --- | --- | --- | --- |
| [ ] **RC-024** | **Build the run-state model and application shell.** Separate persistent run collection, health, currency, relics, seed/RNG state and node progression from battle-local state. Add title/new-run/basic navigation and explicit scene-transition contracts. | RC-004, RC-007 | A reproducible run can start, own its state and enter/leave a test battle without rebuilding everything from training defaults. New-run behavior is explicit. |
| [ ] **RC-025** | **Implement branching routes and the map.** Generate/author the scoped route, room types and guardian endpoint; show current, visited, available and locked nodes. Replace the Map placeholder. | RC-024 | Seeded routes are valid and completable, choices have consequences, inaccessible nodes cannot be entered, and the current room can be resumed from map inspection. |
| [ ] **RC-026** | **Implement encounter entry, results and collection transfer.** Initialize battles from run state and selected board/encounter, persist damage/results, and return to progression. Apply the agreed reset/retain rule. | RC-009, RC-024, RC-025 | Consecutive battles preserve intended health and owned cards exactly once. Installed effects are recovered appropriately; temporary generated cards never enter the permanent collection. |
| [ ] **RC-027** | **Implement rune rewards and collection inspection.** Add deterministic reward offerings, choose/skip flows and a collection viewer distinguishing permanent ownership from hand/draw/discard/installed battle state. | RC-026 | Rewards cannot be claimed twice, duplicate cards have unique identities where needed, and the selected reward is available in later encounters without losing existing cards. |
| [ ] **RC-028** | **Implement versioned local save and resume.** Define safe between-encounter checkpoints, atomic writes/recovery, schema version policy, RNG persistence and pending-node/reward transactions. Add Continue and explain any unfinished-battle replay policy. | RC-027 | Restart resumes the same route, collection, health and pending choice without reroll/duplicate claims. Corrupt/incompatible saves fail gracefully; new-run overwrite behavior and lack of mid-turn saving are explicit. |
| [ ] **RC-029** | **Implement shops and run currency.** Add deterministic stock, prices, purchases and the scoped removal/upgrade services; use persistent transactions and meaningful affordability feedback. | RC-027, RC-028, RC-031 | Spending/stock changes survive restart, cannot duplicate or overspend, and bought/removed/upgraded cards update the collection and later encounters correctly. |
| [ ] **RC-030** | **Implement recovery and event rooms.** Add the bounded recovery choices and declarative event choices/eligibility/outcomes, with placeholder content and support for transaction-safe room completion. Use RC-031 for any upgrade option. | RC-027, RC-028, RC-031 | Each room can resolve and return to the route, costs/rewards apply once, ineligible options are clear, and reopening/reloading cannot repeat a benefit. |
| [ ] **RC-031** | **Implement rune upgrades and relic hooks.** Define effect order, stacking/caps, acquisition, display and save representation. Implement the approved hook types without adding an unrestricted rules engine. | RC-007, RC-027, RC-028 | Representative upgrades/relics work through cast/turn/encounter boundaries and save/load. Split/Join, temporary effects and cost changes have focused interaction checks. |
| [ ] **RC-032** | **Complete end-to-end run navigation and results.** Connect guardian victory, defeat, run summary, new run, continue, abandon-run confirmation, Guide/Settings access and appropriate back behavior. Use a guardian fixture until final content arrives. | RC-026, RC-028–RC-031 | A fixture route enters, resolves and exits every room type. A run can finish or fail and safely return to title; completed saves cannot resurrect rewards, and abandoning a run does not happen through an accidental navigation tap. |

**Milestone 2:** a complete playable run using temporary content where needed, with route choices, rewards, shops, recovery/events, upgrades/relics, local resume, victory and defeat.

## Phase 5 — Gameplay content and the remaining assets

RC-002 assigns the actual names to the four character packs below. Each task owns a distinct asset folder. If the roster changes, add or defer explicit tasks instead of hiding extra characters inside an existing task.

| Status / ID | Task and deliverable | Depends on | Complete when |
| --- | --- | --- | --- |
| [ ] **RC-033** | **Implement the enemy action and intent framework.** Support the approved attack/defend/special action types and guardian phase transitions with visible, inspectable intent. Extend ordered resolution only as required by the roster. | RC-004, RC-007 | Each action has explicit timing and correct preview/resolution. Supported statuses/hit semantics are documented and tested; no undefined effect or multi-target behavior is introduced implicitly. |
| [ ] **RC-034** | **Author the normal, elite and guardian encounters.** Build the scoped five-enemy roster's stats, intent patterns, phase behavior, board assignments and encounter pools. Keep the training scenario as a reproducible fixture. | RC-009, RC-023, RC-033 | Every encounter can be entered and completed, communicates its intended threat, and has at least one practical response with its expected loadout. Guardian transitions and lethal cases have checks. |
| [ ] **RC-035** | **Author the rune, technique, upgrade and relic set.** Fill the bounded content roster, descriptions and synergies using implemented effect types. Add a narrowly scoped effect implementation only when specified; validate ownership and interaction rules. | RC-023, RC-031, RC-033 | All scoped definitions validate and have meaningful uses. Content combinations cover offense, defense and circuit adaptation without unexplained effects or unbounded amplification. |
| [ ] **RC-036** | **Author events and tune the first complete economy.** Supply the scoped event choices/text, reward pools, rarity/weight rules, shop prices, recovery values, room distribution and difficulty curve. | RC-029, RC-030, RC-034, RC-035 | All room types have usable content, transaction checks pass, and a seeded complete run has a plausible resource/difficulty curve ready for human balance testing. |
| [ ] **RC-037** | **Produce additional character pack 1.** Deliver the first remaining roster actor's concept refinement, transparent source/runtime art, rig/poses and enemy-specific animation/effect pieces. | RC-014, RC-017, RC-034 | The pack matches the accepted style and its enemy behavior, shares the anchor/scale contract, and previews idle/attack/hit/defeat at phone size. Final shared-game integration belongs to RC-042. |
| [ ] **RC-038** | **Produce additional character pack 2.** Deliver the second remaining roster actor with its own readable silhouette, behavior-specific pieces and required motion previews. | RC-014, RC-017, RC-034 | Sources, exports, animation requirements, provenance and scale/alpha checks are complete; the design is distinguishable from the other actors. |
| [ ] **RC-039** | **Produce additional character pack 3.** Deliver the third remaining roster actor, including its distinctive telegraph and any approved elite/phase treatment appropriate to its assigned role. | RC-014, RC-017, RC-034 | The actor meets the same character contract and conveys its assigned threat without relying only on recolour. |
| [ ] **RC-040** | **Produce additional character pack 4.** Deliver the final roster actor, including the guardian's phase/defeat requirements if this is its assigned role. | RC-014, RC-017, RC-034 | All approved states fit the arena, sources/exports are complete, and previewed actions align with the implemented encounter design. |
| [ ] **RC-041** | **Prepare remaining content icons and progression art.** Add the final rune/relic/intent icons, map node symbols/connections, currency, shop/recovery/event art, rewards and result-screen treatments. Reuse the established theme; provide one asset per manifest entry. | RC-012, RC-013, RC-032, RC-036 | Every scoped content/screen ID has the required visual treatment and states, with readable symbols, scalable sources and no baked live values. Additional scene illustrations are limited to RC-002 scope. |
| [ ] **RC-042** | **Integrate the complete presentation set.** Connect roster sprites/animations, content icons, progression screens, room variations and audio cues. Add only missing encounter-specific effects/cues; reconcile the shared manifest. | RC-020, RC-032, RC-034–RC-041 | Every room/enemy/result can be viewed in game with correct art and sound. No required production slot points to a placeholder; screenshots and asset links identify what actually shipped into runtime. |

**Milestone 3:** the full scoped run is playable with its intended content, characters, environments, UI, animation and audio.

## Phase 6 — Teaching, balance, accessibility, and reliability

Implementation tasks must add meaningful checks as they change behavior. RC-046 expands coverage across systems; it is not permission to postpone all testing until the end.

| Status / ID | Task and deliverable | Depends on | Complete when |
| --- | --- | --- | --- |
| [ ] **RC-043** | **Build onboarding and the finished reference guide.** Teach connection direction, Split/Join, energy, techniques, temporary effects, inspection, undo, intent and route rewards in small guided steps. Include skip/replay and contextual help. | RC-008, RC-027, RC-042 | A first-time player can complete onboarding without an external explanation; guide text matches final rules, and returning players can skip/replay without corrupting a run. |
| [ ] **RC-044** | **Complete accessibility and responsive UI.** Check text size/contrast, shape-based state cues, touch targets, focus, safe areas, small/tall displays, readable dialogs and larger hands. Add useful reduced-motion/audio settings and consistent UI text handling. | RC-032, RC-042, RC-043 | Supported portrait sizes have no clipped/hidden essential controls. Readability and settings are verified in actual scenes; limitations are documented rather than implying unsupported accessibility features. |
| [ ] **RC-045** | **Playtest and balance complete runs.** Observe new and returning players; measure duration, losses, repetitive layouts, reward usefulness, shop/relic value and tutorial friction. Tune the smallest set of values/rules and repeat affected runs. | RC-036, RC-042–RC-044 | Recorded human runs support the 15–25 minute target and reveal viable choices across the intended content. Dominant/softlocked builds and major comprehension issues are resolved; remaining tradeoffs are explicit. |
| [ ] **RC-046** | **Add integrated regression and content validation.** Extend automated coverage for seeded routes, full-run progression, collection conservation, repeated reward/room transactions, save recovery, relic interactions, battle event sequencing and final UI flows. | RC-028–RC-036, RC-042, RC-043 | Tests catch meaningful cross-system failures and run reproducibly through the documented command path. Any CI setup follows the selected remote/workflow instead of assuming one exists. |
| [ ] **RC-047** | **Verify mobile lifecycle and save reliability.** Exercise pause/resume, background/termination, interruption during combat/animation/reward/save, Android back behavior, audio interruption and save-version recovery on real devices. | RC-021, RC-022, RC-028, RC-032, RC-042 | Documented device cases match the save/checkpoint policy and produce no duplicated purchases/rewards, lost completed-room progress or stuck input/audio. Discovered faults are fixed and retested. |
| [ ] **RC-048** | **Profile and optimize the finished game.** Measure frame pacing, input response, startup/load time, texture/audio memory, effect cost, package contents and extended-session behavior on the selected minimum devices. | RC-042, RC-044, RC-047 | Measured results meet budgets established from supported devices. Asset import/compression and effect fixes preserve readability; reference images and source masters are excluded from builds. |
| [ ] **RC-049** | **Run the supported-device acceptance matrix.** Cover Android/iOS OS/device targets selected in RC-002, screen ratios/safe areas, fresh install/update, offline play, complete runs, audio/settings and sustained sessions. | RC-045–RC-048 | Each supported matrix entry has an actual result, build ID and device details. Release blockers are fixed/retested; unavailable hardware remains an explicit unverified entry. |

**Milestone 4:** a balanced release candidate whose complete run, saves, performance and controls have passed recorded device checks.

## Phase 7 — Release assets, distribution, and launch

Platform requirements can change. Tasks that configure SDKs, sign builds or prepare submissions must consult current official engine/platform documentation when executed. The plan does not freeze today's store dimensions, policy answers or SDK versions.

| Status / ID | Task and deliverable | Depends on | Complete when |
| --- | --- | --- | --- |
| [ ] **RC-050** | **Audit shipped assets, provenance and credits.** Reconcile actual runtime files with source/licence records; include final identity assets, fonts, music, SFX, code dependencies and required attribution. Create the credits screen/document and remove unused runtime imports where appropriate. | RC-042, RC-051 | Every shipped dependency/asset has a traceable source and resolved usage/attribution status. Credits are accessible, unresolved items are replaced or held out, and private/source-only files are not packaged. |
| [ ] **RC-051** | **Prepare final identity assets.** Refine the Rune Cast wordmark, final app icon and launch/title artwork; export the platform-specific variants required at execution time. Keep editable masters and provenance. | RC-011, RC-042 | Icons are distinct and readable at launcher sizes, launch/title assets work on supported screens, and production assets replace the prototype icon. |
| [ ] **RC-052** | **Finalize application identity and signing setup.** Confirm owner/studio identity, package/bundle IDs, release versioning, distribution accounts, signing access and secure backup procedures. Resolve the external account/device questions discovered earlier. | RC-002, RC-021, RC-022; owner credentials/account decisions | Production identifiers and packaging configuration are correct, required account access exists, and signing secrets stay outside source control. This can be scheduled earlier once identity is decided. |
| [ ] **RC-053** | **Produce and verify the Android release candidate.** Build the signed release artifact required for the chosen distribution path, verify runtime data/import inclusion and exclusions, and install through the internal-testing route. | RC-049–RC-052 | The distributed release build installs, updates and completes a run on target devices. Version/build ID, signing procedure and artifact location are recorded without exposing secrets. |
| [ ] **RC-054** | **Produce and verify the iOS release candidate.** Archive/sign the release build on macOS and deliver it through the selected Apple test distribution path. Verify release-only behavior and packaging. | RC-049–RC-052; Mac and distribution access | The distributed release build installs and completes a run on target devices, with reproducible archive/version information and no unresolved signing/export issue. |
| [ ] **RC-055** | **Run a limited external beta and triage feedback.** Prepare tester instructions and a reproducible bug-report format; gather real-device first-session and complete-run observations from the release candidates. | RC-053, RC-054; recruited testers | Feedback is categorized by severity, reproduction and affected build/device. Release blockers and actionable fixes have owners; any external invitations/distribution are performed only when requested. |
| [ ] **RC-056** | **Prepare store listings and marketing materials.** Capture honest gameplay screenshots from release builds; prepare descriptions, platform promotional graphics, support contact/page, credits links and required privacy/content-rating/data declarations from the actual shipped behavior. Prepare a trailer only if selected in RC-002. | RC-050–RC-054; owner business/contact information | Each platform has a reviewed listing package using current official requirements, accurate product claims and actual gameplay. Needed hosted support/privacy materials are ready before submission. |
| [ ] **RC-057** | **Fix beta blockers and freeze the release candidate.** Resolve beta/device/listing issues, rebuild affected platforms, rerun relevant checks, reconcile any replaced assets with the manifest/credits, and record release notes plus the exact versions/artifacts approved for release. | RC-055, RC-056 | No unresolved release blockers remain; final candidate builds and store materials agree, targeted regression and final asset audit pass, and the release decision is reviewable. |
| [ ] **RC-058** | **Submit and release on Android.** When requested, upload the final build/listing, complete review requirements, respond to feedback, and select the agreed rollout. | RC-057; owner release authorization | The desired release is approved and available through the chosen Android channel, with store link/build version recorded. Submission alone is recorded as pending, not released. |
| [ ] **RC-059** | **Submit and release on iOS.** When requested, submit the final archive/listing, address review feedback and perform the agreed release. | RC-057; owner release authorization | The desired iOS release is approved and available, with store link/build version recorded. External review delays remain visible blockers. |
| [ ] **RC-060** | **Verify launch and prepare the first maintenance cycle.** Check public install/update behavior and support feedback for both releases, document known issues and patch procedure, and create a prioritized post-release backlog. | RC-058, RC-059 | Public builds pass an installation/run smoke check, support and reproducible patch steps are in place, and the first follow-up review/patch scope is documented. Recurring monitoring is set up only if separately requested. |

**Milestone 5:** both mobile releases are available and maintainable. Store review timing, platform access and human playtests are external dependencies; they cannot be satisfied by code changes alone.

## Recommended working order and parallel work

- **Start:** RC-001, then RC-002. RC-003 can follow the baseline while scope is being settled.
- **Resolve gameplay early:** RC-004 through RC-009. Do not expand the rune roster before the persistence/layout decision.
- **Start art preparation alongside design:** RC-010 and RC-011, then independent environment/character/audio production. RC-012/RC-013 wait for their specified rules/control inputs.
- **Start device setup early:** RC-021 and RC-022. Treat missing Mac/device/account access as a tracked prerequisite while independent work continues.
- **Integrate one polished encounter:** RC-016, RC-017, RC-020, RC-023. After it passes, scale up content and character production.
- **Build run systems:** RC-024 through RC-028, then RC-031 before RC-029/RC-030, and RC-032 to integrate the flows. RC-033 can proceed after production combat rules are stable. Keep shared core/state edits sequential.
- **Complete content and assets:** RC-034 through RC-042. RC-037–RC-040 can run in parallel once actor specifications are frozen; their chats should not rewrite shared UI code or the same manifest file simultaneously.
- **Finish and release:** RC-043 through RC-060 according to dependencies. RC-051 identity assets precede RC-050's asset audit; RC-052 account/signing setup can overlap final QA once its inputs are stable. Store submission follows the verified final candidates.

If a task grows beyond a focused chat, split it before requesting implementation. For example, RC-034 can become RC-034a (normal encounters), RC-034b (elite), and RC-034c (guardian), with the parent complete only when all parts pass. Apply the same rule if RC-002 expands asset counts.

## Standard completion and handoff record

Each future task prompt should require a concise entry here (or a linked task note) in this format:

```text
Task ID / title:
Status: complete | partial | blocked
Starting revision / ending revision, if available:
Files and artifacts delivered:
Decisions made and documentation updated:
Checks actually run and their results:
Device/build details or asset preview location, where applicable:
Known limitations / external prerequisites:
Next ready task IDs:
```

For code, preserve existing behavior outside the task and run checks appropriate to changed rules/flows. For assets, provide source plus tested runtime deliveries and provenance. For playtests/devices, record observations rather than substituting automated checks. For every task, distinguish completed work from proposed or unverified work.

### Handoff history

- **October 7, 2026 — Planning:** Created this 60-task plan from repository design documents, source inspection and existing verification evidence. No game behavior, assets, build tools, accounts or distribution state were changed. Next tasks: RC-001 and RC-002.

### October 8, 2026 — RC-001: Establish the development baseline and task workflow

- **Status: partial.** Desktop verification, repository review, and documentation are complete. The required local commit is deferred: `user.email` exists, `user.name` is missing, and the owner chose to configure Git after this task. RC-001 remains unchecked until that checkpoint exists and is verified.
- **Starting / ending revision:** unborn `master` (no starting commit); no ending commit yet. Intended checkpoint subject: `chore: establish Rune Cast development baseline`. No remote, push, PR, or CI was added.
- **Deliverables:** `docs/development-workflow.md`; README validation/workflow links; narrow `.gitignore` additions for local QA output and signing formats; this plan's current-reference summary and handoff; appended `docs/verification.md` results; refreshed `output/qa/foundation-screen.png`; preserved October 7 capture at `output/qa/foundation-screen-2026-10-07.png`. The baseline retains the existing source, scenes, data, UIDs/import settings, runtime assets, documentation, all 14 reference images, and all 10 generation prompts.
- **Decisions:** retain `master`, use `codex/` for later task branches, serialize shared state/core/UI edits, and reserve separate asset folders for explicitly requested parallel work. Keep the two reviewed QA captures as intentional evidence; ignore other QA output. No gameplay, balance, screen behavior, or artwork changes were made.
- **Checks actually run:** pinned engine `4.7.2.stable.official.ed1daf0bf`; version exit 0; import exit 0 after resolving a sandbox user-data access error through normal local access; 23 core checks / 0 failures (exit 0); 11 UI checks / 0 failures (exit 0); capture exit 0 with `Screenshot saved: OK`. See [the dated record](verification.md#october-8-2026--rc-001-development-baseline) for attempts, evidence, and visual findings.
- **Staged review:** 70 files staged; diff, names, large files, ignore behavior, and local documentation links reviewed. No non-ignored untracked files remain. A later `project.godot` rewrite outside RC-001 edits is preserved unstaged; the tested configuration remains staged. Review that change before the eventual checkpoint. Default whitespace check reports only 28 existing extra blank lines at file ends; a command-local check excluding that category passes. Existing source formatting was preserved. Approved-image hashes are unchanged.
- **Visual evidence:** fresh 450 by 1000 Windows Compatibility-renderer capture, October 8 at 01:23:51 AEDT. Enemy, stats, 4 by 4 board, editing tools, rune choices, Cast, and all bottom controls are visible without obvious clipping. Placeholder presentation is unchanged.
- **Limitations / next action:** Android import warning `Unable to open Android 'build-tools' directory.` remains an export-configuration limitation. No mobile SDK installation, packaging, or device acceptance was attempted. The owner must configure Git identity; then review the staged files and later unstaged configuration change, rerun affected checks if including that change, create the intended checkpoint, verify its revision/status, and finish the RC-001 completion record.
- **Visual-plan follow-up:** synchronize remaining older wording (including RC-011's v5 pilot comparison) and relevant future screen/asset tasks with the approved Home, Combat, Map, and Menu references before that production work. This task corrects the current summary only; it does not redesign future tasks or implement the approved screens.
- **Next-ready task IDs:** RC-002 and RC-003 become ready once the RC-001 checkpoint is complete. Neither was implemented here.
