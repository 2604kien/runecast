# Rune Cast

Rune Cast is a portrait mobile roguelike about constructing spells on a 4 by 4 circuit board. Connect Begin to End, prepare effects, split a spell into branches, and rejoin them before casting. The project targets **Android and iOS**, with a Windows desktop development preview.

This repository contains a playable **single encounter sandbox** with validated production rules, a bounded encounter-entry development fixture and opt-in historical circuit experiments. Normal launch uses endpoints-only turns, player-rotatable random endpoints, normal rune draws and finite connector kits. The current screen uses simple vector placeholders; the approved artwork is preserved separately.

**RC-007, October 9, 2026:** the owner accepted all proposed defaults. The [production contract](docs/production-rules-spec.md) and [gameplay rules](docs/gameplay-rules.md) describe current behavior; [verification](docs/verification.md) and the [handoff](docs/project-plan.md) record actual checks and remaining tuning limits. This is not a complete tower run.

**RC-008 complete, October 9, 2026:** hold or use Inspect mode for safe rune/technique details, preview legal placements, cancel selection, and scroll the hand/page independently. Fresh verification passes 1063 core / 503 UI checks, plus 82 rendered interaction/capture checks. See [touch interactions](docs/touch-interactions.md) for controls and the pending physical-device checks.

**RC-009 complete, October 9, 2026:** all four stable board identities load under the unchanged random-endpoint rules. The [board catalog](docs/board-catalog.md) provides natural starter examples, exact commands and limits. Current verification passes **1363 core / 564 UI checks**, plus **80 rendered board checks**, all zero failures. RC-010 is the next numbered task; RC-024 and RC-033 are also ready under the [plan](docs/project-plan.md).

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

- Every playable turn starts with only Begin and End and fourteen empty cells. Select either endpoint and Rotate; Undo restores it. Endpoints can be adjacent or initially face outward.
- Tap a wiring tool or effect rune, then an eligible **+** board socket. An **x** marks a protected/unavailable target; legal incomplete construction remains allowed. Rotate changes orientation; Flip reverses ordinary wires. Endpoints cannot be erased or replaced. **Cancel selection** clears the active tool/card.
- A random ten-piece kit supplies Straight/Corner/Split/Join in counts **6/2/1/1**, **4/4/1/1** or **4/2/2/2**, with equal chances and repeats allowed. Labels show available/total; disconnected pieces count. Erase/replacement returns stock and Undo restores it.
- Hold a card, board piece or connector button to inspect live costs, ports, stock and cleanup. Or turn **Inspect: ON**, then tap any item safely. Close retains Inspect mode; Cancel selection turns it off. Drag the hand horizontally or the page vertically to scroll without using a card.
- Focus and Conjure Spark still resolve immediately on a normal short tap. A hold or an Inspect-mode tap only shows details and never activates them. See [touch interactions](docs/touch-interactions.md).
- Cast pays each powered physical rune once plus 1 per Split; Join costs 0. Damage is one aggregate hit. Shield applies to surviving-enemy retaliation only.
- Cast and Pass clear all non-endpoint pieces. Permanent runes enter discard; temporaries disappear. A surviving turn moves both endpoints, replaces the kit, refreshes energy and draws normally. Unused supply never accumulates; cards and kits may repeat.
- The starter has 3 energy and draws 3 cards, including the first turn. Victory/defeat clean up without generating an unused turn.
- **Details / Pass** explains the current circuit and offers a confirmed Pass even with an incomplete board or empty hand. Menu provides Pass, Restart with continuing RNG, and Exact replay of the original seed. Guide explains the controls and rules. Sound toggles the placeholder cast tone and saves the preference.
- Map currently describes the planned tower route; branching progression is not implemented.

## Board catalog

The [board catalog](docs/board-catalog.md) describes **First Circuit, Long Gallery, Ossuary Turn and Belfry Circuit**. These are four stable identities sharing the accepted random geometry and current placeholder art. Each has an executable construction witness using a natural starter draw; the identities do not introduce different mechanical difficulty.

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

The experiment panel selects scenarios/variants, displays rules and seed, provides **Exact replay**, **Next encounter**, and **Inspect / export** with local notes. Historical fixtures keep their original versions, semantics and fingerprints. Human records remain in `user://experiments/`; automated evidence uses unique QA destinations. See the [matrix and historical protocol](docs/circuit-experiments.md) and [RC-006 evidence register](docs/rc-006-playtest-results.md). H32 records the owner's acceptance of all remaining production defaults as a design choice; it does not add human playtest findings or a testing waiver. The three kit quantities and equal probabilities remain provisional tuning. RC-010 remains independently available; subsequent work follows the [current plan](docs/project-plan.md).
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

