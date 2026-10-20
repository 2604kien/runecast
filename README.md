# Rune Cast

**RC-024 session flow:** normal launch now opens Home. Choose **New Run** to play the existing production Shadeling fixture. Menu **Resume** keeps the current battle; **Quit to Home** explains and confirms replay from the same battle-entry checkpoint. Home **Continue** works only while this application session remains open. Closing the app loses the run; Options preferences still persist. Replacing a session requires confirmation. Shadeling victory is one encounter, not tower completion. [Run ownership and verification](docs/rc-024-verification.md).

Launch with `.\tools\godot.ps1 -Action run`. Explicit `-Encounter`, `-BoardExample`, `-Experiment`, existing captures and direct `scenes/main.tscn` consumers retain isolated Combat behavior. RC-024A permanent progression, RC-025 routes, RC-026 full encounter integration and RC-028 saves remain separate work; RC-022 stays deferred and RC-023 acceptance stays pending.

**RC-020 available audio:** current SFX and continuous crypt ambience now use one production coordinator. Menu → Options offers independent Music/SFX levels and mutes; Sound remains the master shortcut. [Usage/settings](docs/audio-integration.md), [recorded playable review](output/qa/rc-020/demo/index.html), [verification](docs/rc-020-verification.md). Both music tracks and final music/full-mix listening remain pending, so RC-019 and the original full RC-020 task stay incomplete.

## October 16, 2026 — Combat animation and feedback

Normal production Combat now presents the detached ordered result through RC-017: circuit traversal, applied damage, shielding/retaliation, cleanup, actual cards and stable victory/defeat. The actor keeps its approved neutral and retained attack/hit artwork; clean hidden scenery removes residual silhouettes. Use `--reduced-motion` or the existing settings file's accessibility preference for stationary colour/opacity feedback, independently of sound. [Usage and event mapping](docs/combat-animation.md), [actor contract](docs/actor-animation-contract.md), [tests and native motion evidence](docs/rc-017-verification.md).

## October 16, 2026 — Unused resource cleanup

Removed 2,221 audited unused resources and obsolete QA files, freeing 1.28 GiB. Current game art, approved references, editable masters and required test inputs remain. The generator no longer emits unused pile/state assets. [Cleanup record](docs/asset-cleanup.md#october-16-2026--unused-resource-cleanup) and [verification](docs/verification.md#october-16-2026--unused-resource-cleanup).

## October 16, 2026 — Generated painted status frame

The Health/Energy/Turn bar now uses a complete painted PNG generated with the built-in image tool from the approved reference. This replaces the rejected flat, code-drawn border. [Updated screen](output/qa/rc-016/stats-generated-frame/normal-desktop.png), [before/after](output/qa/rc-016/stats-generated-frame/before-after.png), [asset and provenance](source-assets/ui/combat/reference/status-frame/provenance.json), and [verification](docs/verification.md#october-16-2026--generated-painted-status-frame). The existing row size, padding and live values remain. Earlier entries below are historical where superseded.

## October 16, 2026 — Drawn status border

The Health/Energy/Turn frame is now one directly drawn gold border with joined corners and straight dividers, replacing the rejected endcap patches. [Updated screen](output/qa/rc-016/stats-drawn-border/normal-desktop.png) and [closeup comparison (retired)](docs/asset-cleanup.md#october-16-2026--unused-resource-cleanup). The 54px row and existing content padding remain unchanged.

## October 16, 2026 — Status-bar end borders

The Health/Energy/Turn bar now has continuous gold borders at both ends. Its original source had separate upper/lower flares; matching gold divider artwork now joins them without changing row size, padding or live values. [Before/after (retired)](docs/asset-cleanup.md#october-16-2026--unused-resource-cleanup), [current screen (retired)](docs/asset-cleanup.md#october-16-2026--unused-resource-cleanup), and [verification](docs/verification.md#october-16-2026--status-bar-end-borders).

## October 15, 2026 — Full-screen reference polish

Combat now uses the approved neutral actor and visible crypt scenery, the original player-status rails, seven slate socket variants, full ribbon ends, and masked original navigation/resource icons. The 54 px status row contains a 36 px content well; tool and navigation art/text have separate padded lanes. Shared Combat font resources use normal width, with smaller card names and clearer live text. [Current screen (retired)](docs/asset-cleanup.md#october-16-2026--unused-resource-cleanup), [integration](docs/rc-016-integration.md#october-15-2026--full-screen-reference-polish) and [verification](docs/verification.md#october-15-2026--full-screen-reference-polish) describe this latest pass.

The owner's later changes remain: no Pause, BOSS, card-category row, Incoming row, Cast caption or hover tooltip; the forecast stays display-only, the card cost gem stays small, and circuit controls retain padding and confirmed Pass. This is not a claim of complete pixel identity: the reference typeface is unidentified, some glyphs remain generated fallbacks, and hidden painted areas still use clean source patches. Dated records below describe earlier implementations where superseded here.

## October 15, 2026 — Cast face continuity

The abrupt turquoise edge at Cast's right tip came from replacing only the rectangular center while retaining a darker face inside the end cap. Cast now maps one clean face across both pointed ends, with the approved gold rim and cyan bevel drawn separately. Its size, live cost, input and gameplay behavior are unchanged; no source PNG was modified.

[Current screen (retired)](docs/asset-cleanup.md#october-16-2026--unused-resource-cleanup), [integration](docs/rc-016-integration.md#october-15-2026--cast-face-continuity) and [verification](docs/verification.md#october-15-2026--cast-face-continuity) record this scoped correction.

## October 15, 2026 — Stats inner frame correction

The Health/Energy/Turn background now follows the frame's angled inner edge, with the original gold rim drawn above it. Earlier containment checks covered outer bounds and content padding but missed background paint crossing the inner bevel; the previous containment claim was incomplete. The 54 px row, padding, other UI and source artwork are unchanged.

The stats row also draws above the arena artwork so its bleed cannot cover the top rim; arena allocation and cropping are unchanged.

[Before (retired)](docs/asset-cleanup.md#october-16-2026--unused-resource-cleanup), [corrected bar (retired)](docs/asset-cleanup.md#october-16-2026--unused-resource-cleanup), [current screen (retired)](docs/asset-cleanup.md#october-16-2026--unused-resource-cleanup) and [verification](docs/verification.md#october-15-2026--stats-inner-frame-correction) record this scoped correction.

## October 15, 2026 — Display-only forecast and frame cleanup

The Damage/Shield/Cost bar above Cast is now display-only. Tapping or holding it opens no window, and it does not receive keyboard focus. Card Info, card/piece/connector inspection, pile inspection and Pass confirmation remain available.

The player stats strip now has a continuous closed frame with inset dividers. The stray gold line at the board's lower-right edge is removed by correcting both the board crop and the surrounding backdrop sample. Source PNGs remain unchanged.

[Current screen (retired)](docs/asset-cleanup.md#october-16-2026--unused-resource-cleanup), [integration](docs/rc-016-integration.md#october-15-2026--display-only-forecast-and-frame-cleanup) and [verification](docs/verification.md#october-15-2026--display-only-forecast-and-frame-cleanup) describe the latest revision. This overrides earlier instructions to activate the forecast for details; dated entries below retain their historical behavior.

## October 15, 2026 — Header order and connector rotation

The full-width header now places the approved Rune Cast wordmark on the left and the live floor name on the right. Split and Join retain their approved icon orientation when rotated; their logical ports and visible connection lines still rotate normally.

The exposed gap at the upper-left card frame is repaired by sampling the matching clean upper corner. Card dimensions and cost-badge padding are unchanged.

The original pile artwork and live counts remain, as do the smaller 25×29 card cost symbols and 20 px numbers. [Current screen (retired)](docs/asset-cleanup.md#october-16-2026--unused-resource-cleanup), [integration](docs/rc-016-integration.md#october-15-2026--header-order-and-connector-rotation) and [verification](docs/verification.md#october-15-2026--header-order-and-connector-rotation) supersede the earlier header order below. Original source artwork is retained.

## October 15, 2026 — Header and reference pile correction

The 52 px header now spans the full portrait viewport, with the floor name at the left and the approved Rune Cast wordmark at the right. Pause remains removed. Stats paint is clipped to its frame silhouette, and the stray line beside Pass is removed from the toolbar's source slice.

Draw and Discard now preserve their distinct approved stack bodies and emblems at a uniform scale, with live counts and captions. Compact card costs use a 25×29 symbol and 20 px number. No source PNG was added, modified or deleted. [Current screen (retired)](docs/asset-cleanup.md#october-16-2026--unused-resource-cleanup), [integration](docs/rc-016-integration.md#october-15-2026--header-and-reference-pile-correction) and [verification](docs/verification.md#october-15-2026--header-and-reference-pile-correction) supersede the earlier header and pile approaches below.

## October 15, 2026 — Mobile presentation corrections

The Combat header now shows the floor name at the left, with no Rune Cast wordmark or Pause button. The BOSS caption is removed. Stats and bottom navigation use explicit content lanes inside their painted frames; Pass and Cast exclude neighboring pixels outside their artwork silhouettes. Discard mirrors its stack artwork, while both pile symbols and upright counts are centered on the front card.

Production hover tooltips and the extra invalid/unavailable x/circle badges are suppressed. Tap/hold inspection, card Info, forecast details, confirmed Pass, focus cues and controller guards remain available. No source PNG was generated or modified. [Current screen (retired)](docs/asset-cleanup.md#october-16-2026--unused-resource-cleanup), [integration](docs/rc-016-integration.md#october-15-2026--mobile-presentation-corrections) and [verification](docs/verification.md#october-15-2026--mobile-presentation-corrections) record this correction. The dated entries below describe earlier revisions.

**Approved reference artwork adoption, October 15, 2026:** Combat now samples the approved painting's clean decorative regions and uses new GPT Image neutral-character, empty-arena and symbol assets. Live gameplay remains authoritative, including the later card/forecast/caption removals and padded circuit controls. [Current screen (retired)](docs/asset-cleanup.md#october-16-2026--unused-resource-cleanup), [source and limits](source-assets/ui/combat/reference/README.md), [integration](docs/rc-016-integration.md#october-15-2026--approved-reference-artwork-adoption) and [verification](docs/verification.md#october-15-2026--approved-reference-artwork-adoption) describe the result. Eighteen obsolete generated surfaces and their import/cache files were removed. Generated brushwork, reconstructed hidden textures and live font details still prevent a complete pixel-identical match; older “current” entries below describe their dated revisions.

**Full-screen reference alignment, October 15, 2026:** corrected relative text/icon scales and spacing across Combat, removed card category labels, and centered the three forecast totals without Incoming. [Side-by-side comparison (retired)](docs/asset-cleanup.md#october-16-2026--unused-resource-cleanup), [opening screen (retired)](docs/asset-cleanup.md#october-16-2026--unused-resource-cleanup), [active circuit (retired)](docs/asset-cleanup.md#october-16-2026--unused-resource-cleanup) and [verification](docs/verification.md#october-15-2026--full-screen-reference-alignment) show the current result. Earlier correction notes below are historical.

**RC-016 geometry and typography correction, October 15, 2026:** Combat now follows measured reference dimensions for its board, ribbon, cards, controls and text, with corrected visible glyph scale and asymmetric padding. The [normal desktop capture (retired)](docs/asset-cleanup.md#october-16-2026--unused-resource-cleanup), [reference measurements](output/qa/rc-016/geometry-correction/reference-layout.json) and [verification](docs/verification.md#october-15-2026--rc-016-reference-geometry-and-typography) record the correction. The full portrait composition fits, and the existing 18 image-generated PNGs remain unchanged. Earlier results below are historical; measured layout agreement does not imply pixel-identical painted details.

Rune Cast is a portrait mobile roguelike about constructing spells on a 4 by 4 circuit board. Connect Begin to End, prepare effects, split a spell into branches, and rejoin them before casting. The project targets **Android and iOS**, with a Windows desktop development preview.

This repository contains a playable **single encounter sandbox** with validated production rules, a bounded encounter-entry development fixture and opt-in historical circuit experiments. Normal launch uses undirected circuits, endpoints-only turns, player-rotatable random endpoints, normal rune draws and finite connector kits. Combat consumes the delivered painted crypt, full-body Shadeling, serif typography, symbols and reusable painted controls. The [RC-016 integration guide](docs/rc-016-integration.md) records the actual gameplay composition and its evidence boundaries.

**RC-016 image-generated-art rework, October 14, 2026:** Combat now uses **18 painted PNG surfaces generated with the built-in GPT Image tool**, replacing procedural decorative art. The original output pixels are preserved; Godot handles live content and interactions. [Source/provenance](source-assets/ui/combat/README.md), [normal desktop capture (retired)](docs/asset-cleanup.md#october-16-2026--unused-resource-cleanup) and [verification](docs/verification.md#october-14-2026--rc-016-image-generated-painted-ui-rework) record 1,453 core / 594 UI / 737 art / 157 geometry / 119 touch checks, all passing. Full-screen fit is preserved. Exact visual identity and owner acceptance remain separate. See the [cleanup ledger](docs/asset-cleanup.md#october-14-2026--image-generated-combat-rework-cleanup) for unused-art retirement; the tool does not expose its model/version.

**Historical RC-016 reference correction, October 13, 2026:** Combat restores the retained full-height crypt painting and uses distinct shared stat/navigation strips, a completion ribbon, parchment controls, gray deck stacks, slimmer painted sockets/cards, rounded glowing paths and a centered Cast. The live boss information is stacked below the actor. The [current integration guide](docs/rc-016-integration.md), [normal desktop capture — historical image retirement](docs/asset-cleanup.md#october-14-2026--image-generated-combat-rework-cleanup) and [branching example — historical image retirement](docs/asset-cleanup.md#october-14-2026--image-generated-combat-rework-cleanup) describe the result. Native narrow viewports retain intentional scrolling. Fresh core/UI/art/touch checks pass; [measured layout evidence](output/qa/rc-016/reference-match/measurements/results.json) is separate from exact visual matching and owner acceptance. Original character, environment and gameplay files remain preserved.

**Earlier height correction:** the [618-check fit suite](output/qa/rc-016/layout-correction/final/runtime-v2/results.json) established full-screen visibility but did not establish fidelity to the reference. The owner subsequently rejected that appearance. Its [capture — historical image retirement](docs/asset-cleanup.md#october-14-2026--image-generated-combat-rework-cleanup) and [verification](docs/verification.md#october-13-2026--rc-016-layout-correction) remain historical evidence.

**Historical RC-016 integration before the correction:** verification passed **1,453 core / 594 UI / 563 art integration / 119 touch and branch checks**. Its [desktop capture — historical image retirement](docs/asset-cleanup.md#october-14-2026--image-generated-combat-rework-cleanup) and [verification record](docs/verification.md#october-13-2026--rc-016-playable-combat-art-integration) are retained as evidence of the earlier layout, not acceptance of the full-screen composition. RC-017 owns event-driven animation.

**RC-007, October 9, 2026:** the owner accepted all proposed defaults. The [production contract](docs/production-rules-spec.md) and [gameplay rules](docs/gameplay-rules.md) describe current behavior; [verification](docs/verification.md) and the [handoff](docs/project-plan.md) record actual checks and remaining tuning limits. This is not a complete tower run.

**RC-008 historical delivery, October 9, 2026:** introduced safe inspection, placement feedback and independent hand/page scrolling. Its original Inspect/Cancel controls were superseded by RC-016A. Historical verification passed 1063 core / 503 UI checks, plus 82 rendered checks; those are not newly executed results. See [touch interactions](docs/touch-interactions.md) for current controls and pending physical-device checks.

**RC-009 complete, October 9, 2026:** all four stable board identities load under the unchanged random-endpoint rules. The [board catalog](docs/board-catalog.md) provides natural starter examples, exact commands and limits. Its runtime verification passed **1363 core / 564 UI checks**, plus **80 rendered board checks**, all zero failures; these checks were not rerun for the documentation-only RC-010 task.

**RC-010 complete, October 9, 2026:** the [asset manifest](docs/asset-inventory.csv), [consumer mapping and audit guide](docs/asset-manifest-guide.md), [production specification](docs/asset-production-spec.md) and [matching pilot brief](docs/style-pilot-brief.md) define the bounded asset set and separate production/integration ownership. Current task readiness lives in the [plan](docs/project-plan.md).

**RC-012 complete, October 11, 2026:** the [core symbol and typography library](docs/core-symbols-and-typography.md) provides editable source/runtime paths and isolated Godot verification for the clean-board visual contract. [RC-016A](docs/project-plan.md#rc-016a--undirected-evaluator-and-control-migration-gate) completed the undirected evaluator/control migration on October 13; RC-016 integrates the production composition while preserving those rules.

**RC-013–RC-015 production deliveries:** the [reusable UI theme](docs/ui-theme.md), [Shadeling boss pack](source-assets/characters/shadeling/delivery.md) and [layered crypt](source-assets/environments/crypt/delivery.md) are technically verified production resources. Shadeling's retained dodge-like hit pose remains artwork, with no dodge mechanic. Painted-art rights, owner acceptance of the reconstructed art and physical-device acceptance remain separate from technical integration. The separate Home illustration is delivered but Home/progression flows remain future work.

## Start the project

The pinned editor is **Godot 4.7.2 Standard with GDScript**, using the Compatibility renderer. No Blender or .NET dependency is required.

From PowerShell in this folder:

```powershell
.\tools\bootstrap-godot.ps1
.\tools\godot.ps1 -Action editor
```

Press **F6** to run the open main scene, or **F5** to run the project. To launch directly:

```powershell
.\tools\godot.ps1 -Action run
```

The bootstrap downloads the official Windows x64 portable editor and verifies its SHA-512 checksum. The engine lives in ignored `.tools/`; it does not change PATH. To use another compatible installation, set `GODOT_BIN` to its executable. Open `project.godot` directly from Godot on macOS or Linux.

## Play the sandbox

- Every playable turn starts with only Begin and End and fourteen empty cells. Select either endpoint and Rotate. Endpoints can be adjacent or initially face outward.
- Tap a wiring tool or effect rune, then an eligible **+** board socket. An **x** marks a protected/unavailable target; legal incomplete construction remains allowed. **Remove** and **Rotate** are the editing actions. Endpoints cannot be removed or replaced. Escape or tapping the active selection again clears it.
- A random ten-piece kit supplies Straight/Corner/Split/Join in counts **6/2/1/1**, **4/4/1/1** or **4/2/2/2**, with equal chances and repeats allowed. Labels show available/total; disconnected pieces count. Removing or replacing connectors returns their stock.
- Hold a card, board piece or connector button to inspect live costs, ports, stock and cleanup. Cards also have **Info**; keyboard **I** or right-click inspects a focused/targeted item. The Damage/Shield/Cost bar above Cast only displays the live forecast; tapping or holding it opens no window. Close restores focus after inspection. Drag the hand horizontally or the page vertically; details scroll independently.
- Focus and Conjure Spark resolve immediately on a normal short tap. Inspection never activates them. See [touch interactions](docs/touch-interactions.md).
- Cast pays each powered physical rune once plus 1 per Split; Join costs 0. Damage is one aggregate hit. Shield applies to surviving-enemy retaliation only.
- Cast and Pass clear all non-endpoint pieces. Permanent runes enter discard; temporaries disappear. A surviving turn moves both endpoints, replaces the kit, refreshes energy and draws normally. Unused supply never accumulates; cards and kits may repeat.
- The starter has 3 energy and draws 3 cards, including the first turn. Victory/defeat clean up without generating an unused turn.
- **Pass turn**, beside the connector tools, opens a confirmation showing incoming attack and cleanup even with an incomplete circuit or empty hand. Menu retains Restart with continuing RNG and Exact replay of the original seed. Guide explains controls and rules. Sound toggles the existing placeholder cast tone and saves the preference.
- Map currently describes the planned tower route; branching progression is not implemented.

## Board catalog

The [board catalog](docs/board-catalog.md) describes **First Circuit, Long Gallery, Ossuary Turn and Belfry Circuit**. These are four stable identities sharing the accepted random geometry and production socket/crypt resources. Each has an executable construction witness using a natural starter draw; the identities do not introduce different mechanical difficulty.

Open any development identity with an empty construction:

```powershell
.\tools\godot.ps1 -Action run -Encounter res://data/development/rc009_training_encounter.json
.\tools\godot.ps1 -Action run -Encounter res://data/development/rc009_gallery_encounter.json
.\tools\godot.ps1 -Action run -Encounter res://data/development/rc009_ossuary_encounter.json
.\tools\godot.ps1 -Action run -Encounter res://data/development/rc009_belfry_encounter.json
```

Reproduce the authored command sequences in the actual scene:

```powershell
.\tools\godot.ps1 -Action run -BoardExample board_training
.\tools\godot.ps1 -Action run -BoardExample board_gallery
.\tools\godot.ps1 -Action run -BoardExample board_ossuary
.\tools\godot.ps1 -Action run -BoardExample board_belfry
```

The default example stage is `built`, ready to Cast. Add `-ExampleStep opening` to inspect the natural starting resources, or `-ExampleStep cast` to execute the Cast and inspect cleanup/new turn. These are opt-in development witnesses; ordinary launch stays on `data/production_encounter.json`. Use `-LogDirectory output/qa/rc-009/<fresh-name>` and a fresh `-CapturePath` to preserve prior evidence.

## Validate

```powershell
.\tools\godot.ps1 -Action version
.\tools\godot.ps1 -Action import
.\tools\godot.ps1 -Action test
.\tools\godot.ps1 -Action smoke
.\tools\godot.ps1 -Action capture
```

The screenshot is saved to `output/qa/foundation-screen.png`. Logs also go to `output/qa/`.

To preserve an earlier screenshot, pass a fresh destination, for example `-Action capture -CapturePath 'res://output/qa/rc-007/implementation/review-production.png'`. Automated records use unique QA subdirectories; human records still use `user://experiments/`. Tests cover production configuration, ownership, cleanup, RNG, encounter transfer and 720 endpoint/kit geometry cases, alongside preserved historical fixtures. Smoke exercises the actual production screen, labels, Guide, construction, terminals, Restart/Exact replay and encounter entry.

To exercise the RC-004 development fixture in the actual scene:

```powershell
.\tools\godot.ps1 -Action run -Encounter 'res://data/dev_encounter.json'
.\tools\godot.ps1 -Action capture -Encounter 'res://data/dev_encounter.json' -CapturePath 'res://output/qa/rc-007/implementation/legacy-development.png'
```

This is an explicit historical configuration fixture. The original prefilled 12-damage training circuit is also preserved, with its original curated hand and unlimited basic wires:

```powershell
.\tools\godot.ps1 -Action run -Encounter 'res://data/encounter.json'
.\tools\godot.ps1 -Action run -Encounter 'res://data/production_transition_encounter.json'
```

The second command selects the bounded production encounter-entry fixture. After victory, Menu > Next encounter carries current/max health and permanent UIDs into one Calibration Wisp encounter, drawing normally with its four energy/two-card configuration. This fixture implements no map, rewards or saves. Normal launch uses `data/production_encounter.json`. Fresh same-seed setup and Exact replay reproduce the opening; ordinary Restart continues the separate card, endpoint and kit streams. Invalid content disables gameplay with diagnostics. See [content definitions](docs/content-definitions.md).

## Project documentation

RC-005 supplied six experiment families through nine bounded scenarios and 19 variants. Those original fixtures remain intact. RC-006 adds the opt-in `effects/full_reset`, `effects/moving_endpoints` and `effects/free_endpoints` follow-ups, bringing the current menu to nine scenarios and 22 variants. Launch the original matched pair with:

```powershell
.\tools\godot.ps1 -Action run -Experiment -Scenario effects -Variant control -Seed 42
.\tools\godot.ps1 -Action run -Experiment -Scenario effects -Variant treatment -Seed 42
```

The experiment panel selects scenarios/variants, displays rules and seed, provides **Exact replay**, **Next encounter**, and **Inspect / export** with local notes. Historical fixtures keep their original versions, semantics and fingerprints. Human records remain in `user://experiments/`; automated evidence uses unique QA destinations. See the [matrix and historical protocol](docs/circuit-experiments.md) and [RC-006 evidence register](docs/rc-006-playtest-results.md). H32 records the owner's acceptance of all remaining production defaults as a design choice; it does not add human playtest findings or a testing waiver. The three kit quantities and equal probabilities remain provisional tuning. Subsequent work follows the [current plan](docs/project-plan.md).
```powershell
.\tools\godot.ps1 -Action run -Experiment -Scenario effects -Variant full_reset -Seed 42
.\tools\godot.ps1 -Action run -Experiment -Scenario effects -Variant moving_endpoints -Seed 42
.\tools\godot.ps1 -Action run -Experiment -Scenario effects -Variant free_endpoints -Seed 42
```

- [Circuit experiments — opt-in matrix, replay, records and human protocol](docs/circuit-experiments.md)
- [RC-006 playtest results — preserved evidence and owner decisions](docs/rc-006-playtest-results.md)
- [Production rules specification — accepted contract and historical decisions](docs/production-rules-spec.md)
- [First-release design specification — scope, screen behavior and acceptance](docs/v1-design-spec.md)
- [Content roster — stable IDs, working defaults and task ownership](docs/content-roster.md)
- [Content definitions — schemas, validation, ownership and development fixtures](docs/content-definitions.md)
- [Board catalog — four identities, exact construction examples and launch commands](docs/board-catalog.md)
- [Game description](docs/game-design.md)
- [Gameplay rules](docs/gameplay-rules.md)
- [Touch interactions — inspection, selection, scrolling and placement feedback](docs/touch-interactions.md)
- [Combat/presentation architecture and animation contract](docs/combat-presentation.md)
- [Decisions and open questions](docs/decisions.md)
- [Art direction and asset production](docs/art-direction.md)
- [Final approved visuals — Home, Combat, Map, Menu](docs/visual-reference.md)
- [Godot and mobile setup](docs/setup.md)
- [Project plan — numbered tasks and dependencies](docs/project-plan.md)
- [Development workflow — separate chats and local checkpoints](docs/development-workflow.md)
- [Implementation roadmap](docs/roadmap.md)
- [Verification record](docs/verification.md)
- [Asset inventory](docs/asset-inventory.csv)
- [Asset consumers, readiness vocabulary and source audit](docs/asset-manifest-guide.md)
- [Asset production contracts and provisional budgets](docs/asset-production-spec.md)
- [RC-012 core symbols and typography — editable sources, shared fonts and actual Godot previews](docs/core-symbols-and-typography.md)
- [RC-013 reusable UI theme and wordmark — components, states and integration guide](docs/ui-theme.md)
- [RC-016 playable Combat integration — layout, resource reuse and evidence](docs/rc-016-integration.md)
- [RC-011 matching Shadeling, Spark and button pilot](docs/style-pilot-brief.md)

## Structure

```text
assets/           Runtime art, UI, audio, and future enemy/environment assets
data/             Validated rune, enemy, board, loadout and encounter definitions
docs/             Design, decisions, setup, and production planning
scenes/           Godot scene entry points
scripts/core/     Content validation, circuit evaluation and combat state
scripts/ui/       Guarded combat controller, presentation adapter and view controls
tests/            Headless rule checks and UI smoke checks
tools/            Portable engine setup and launch commands
output/imagegen/  Visual reference history and generation prompts
output/qa/        Local verification screenshots and logs
```

## Mobile delivery status

Android and iOS export presets are included with **development placeholder identifiers**. No APK, IPA, or App Store build is claimed. Android SDK/JDK and matching export templates must be configured for packaging; iOS export requires macOS, Xcode, and signing details. See [setup](docs/setup.md).

The intended product includes 15–25 minute runs and saving between encounters. Those systems remain on the roadmap; current local persistence covers the sound preference and opt-in experiment observation records.

