# Rune Cast

Rune Cast is a portrait mobile roguelike about constructing spells on a 4 by 4 circuit board. Connect Begin to End, prepare effects, split a spell into branches, and rejoin them before casting. The project targets **Android and iOS**, with a Windows desktop development preview.

This repository contains the project foundation and a playable **single encounter sandbox**, not a complete tower run. The current screen uses simple vector placeholders; the approved artwork is preserved separately.

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

- The opening circuit matches the reference: a temporary free Spark, one Split, two branches, one Join, and End.
- Tap a wiring tool or effect rune, then a board socket. Tap an installed piece to select it. Rotate changes orientation; Flip reverses a wire.
- Basic wires are unlimited. One Split and one Join are available, counting installed pieces.
- Focus and Conjure Spark are techniques and resolve immediately when tapped.
- Cast spends the circuit's energy and ends the turn. Surviving enemies retaliate.
- Menu provides Restart and Pass turn. Guide explains the rules. Sound toggles the placeholder cast tone and saves the preference.
- Map currently describes the planned tower route; branching progression is not implemented.

## Validate

```powershell
.\tools\godot.ps1 -Action version
.\tools\godot.ps1 -Action import
.\tools\godot.ps1 -Action test
.\tools\godot.ps1 -Action smoke
.\tools\godot.ps1 -Action capture
```

The screenshot is saved to `output/qa/foundation-screen.png`. Logs also go to `output/qa/`.

## Project documentation

- [First-release design specification — scope, screen behavior and acceptance](docs/v1-design-spec.md)
- [Content roster — stable IDs, working defaults and task ownership](docs/content-roster.md)
- [Game description](docs/game-design.md)
- [Gameplay rules](docs/gameplay-rules.md)
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
data/             Rune definitions and the training encounter
docs/             Design, decisions, setup, and production planning
scenes/           Godot scene entry points
scripts/core/     Circuit evaluation and combat state
scripts/ui/       Screen construction and placeholder drawing
tests/            Headless rule checks and UI smoke checks
tools/            Portable engine setup and launch commands
output/imagegen/  Visual reference history and generation prompts
output/qa/        Local verification screenshots and logs
```

## Mobile delivery status

Android and iOS export presets are included with **development placeholder identifiers**. No APK, IPA, or App Store build is claimed. Android SDK/JDK and matching export templates must be configured for packaging; iOS export requires macOS, Xcode, and signing details. See [setup](docs/setup.md).

The intended product includes 15–25 minute runs and saving between encounters. Those systems are on the roadmap; current persistence covers the sound preference only.

