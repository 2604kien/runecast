# RC-025 — Shared Combat and Map navigation

**Current presentation:** the latest owner request removes the persistent blue Map highlight; the neutral-navigation and navy-modal subsection below supersedes the selected-tab treatment in the historical results.

October 21, 2026 (Australia/Sydney). Combat and Map now instantiate the same `scenes/ui/theme/navigation_bar.gd` component. Map's separate button, icon, label and frame layout has been removed. The bar retains Combat's four actions, artwork, padding, font treatment, frame scale and 82-pixel height. Only Map's selected-tab highlight differs.

This is a focused follow-up to the [Map reference correction](rc-025-map-match-verification.md). No new artwork, route/model rules, content, audio players or navigation destinations were added. No Git operations or native builds were performed.

## Follow-up — neutral navigation and navy modal backgrounds

Map now retains the same neutral bar as Combat, without a persistent blue tab fill or border. Shared `modal_panel.gd` / `modal_panel.tres` samples the navigation navy material for Guide, Menu, Options, rune/tool/pile Info, Pass, route help/inspection and shell confirmation bodies. Existing gold rims, controls, native title bars, keyboard focus and input ownership remain. Rune slots retain their own material. The [actual narrow contact sheet](../output/qa/rc-025-panel-backgrounds/contact-sheet.png) shows Guide, Info, Options and both neutral bars; [entry confirmation](../output/qa/rc-025-panel-backgrounds/panels/route-entry-confirmation-360x640.png) and [Combat Menu](../output/qa/rc-025-panel-backgrounds/panels/combat-menu-720x1600.png) show the same treatment.

- **142 panel/window checks, 0 failures**, 32 PNGs at 720×1600 and 360×640 — [log](../output/qa/rc-025-panel-backgrounds/panel-capture.log), [assertions](../output/qa/rc-025-panel-backgrounds/panels/results.json).
- **336 navigation checks, 0 failures**, 32 PNGs across four sizes and both Sound states — [log](../output/qa/rc-025-panel-backgrounds/navigation-capture.log).
- **97 shell checks, 0 failures** — [log](../output/qa/rc-025-panel-backgrounds/shell-tests.log). Runtime resource inventory was updated and **five Python pack-integrity tests passed**; these are local integrity fixtures, not a fresh exported-payload audit.

Visual review confirmed consistent navy centers, readable text and intact rims. Scoped interaction checks preserved route/Combat state, modal return paths, cancellation and audio ownership. The [capture helper](../output/qa/rc-025-panel-backgrounds/panel_background_capture.gd) remains QA evidence only; reproduce with that `res://output/qa/rc-025-panel-backgrounds/panel_background_capture.gd` script path, task-local settings, Dummy audio and a hidden engine. The existing navigation capture accepts `--qa-output=res://output/qa/rc-025-panel-backgrounds`. No broad suite, resource export/PCK decode, native build, device test or Git operation ran for this follow-up; earlier pack results predate it.

## Follow-up — outer navigation corners

The rectangular atlas sample included neighboring paint outside the navigation frame's upper corners. A navigation-only silhouette mask in `combat_surface.gd` now removes that square backing while retaining the measured gold bevel. Source artwork, shared bar dimensions, actions and Map selection are unchanged.

Focused validation produced **336 checks, 0 failures** and **32 PNGs** across the same four portrait sizes and both Sound states: [log](../output/qa/rc-025-navigation-corners/navigation-capture.log), [assertions](../output/qa/rc-025-navigation-corners/screenshots/results.json). Visual review inspected both actual screens at [841×1870](../output/qa/rc-025-navigation-corners/screenshots/screens-841x1870-sound-on.png) and [360×640](../output/qa/rc-025-navigation-corners/screenshots/screens-360x640-sound-on.png), plus their [wide](../output/qa/rc-025-navigation-corners/screenshots/bars-841x1870-sound-off.png) and [narrow](../output/qa/rc-025-navigation-corners/screenshots/bars-360x640-sound-on.png) bar comparisons. Scene background remains visible outside the beveled corners, including the narrow screen's candles.

The first mask candidate is retained under `output/qa/rc-025-navigation-corners/provisional`; final captures use the measured outline. The harness accepts `--qa-output=res://output/qa/rc-025-navigation-corners`, preserving earlier evidence. This correction ran only the focused render/input suite with task-local settings and Dummy audio. No broad regression suite, resource export or native build was repeated; the pack and broader results below predate this mask correction.

## Actual rendered comparison

Each comparison is rendered in Godot from snapshots of the actual production Combat and fresh route Map viewports. Bar comparisons display those viewport regions at their actual size; they do not reconstruct the controls. The prepared Combat scene is retained with one real connector placed. No room traversal or fabricated progress is used.

| Viewport | Sound on | Sound off |
| --- | --- | --- |
| 841×1870 | [bars](../output/qa/rc-025-shared-navigation/screenshots/bars-841x1870-sound-on.png), [screens](../output/qa/rc-025-shared-navigation/screenshots/screens-841x1870-sound-on.png) | [bars](../output/qa/rc-025-shared-navigation/screenshots/bars-841x1870-sound-off.png), [screens](../output/qa/rc-025-shared-navigation/screenshots/screens-841x1870-sound-off.png) |
| 720×1600 | [bars](../output/qa/rc-025-shared-navigation/screenshots/bars-720x1600-sound-on.png), [screens](../output/qa/rc-025-shared-navigation/screenshots/screens-720x1600-sound-on.png) | [bars](../output/qa/rc-025-shared-navigation/screenshots/bars-720x1600-sound-off.png), [screens](../output/qa/rc-025-shared-navigation/screenshots/screens-720x1600-sound-off.png) |
| 450×1000 | [bars](../output/qa/rc-025-shared-navigation/screenshots/bars-450x1000-sound-on.png), [screens](../output/qa/rc-025-shared-navigation/screenshots/screens-450x1000-sound-on.png) | [bars](../output/qa/rc-025-shared-navigation/screenshots/bars-450x1000-sound-off.png), [screens](../output/qa/rc-025-shared-navigation/screenshots/screens-450x1000-sound-off.png) |
| 360×640 | [bars](../output/qa/rc-025-shared-navigation/screenshots/bars-360x640-sound-on.png), [screens](../output/qa/rc-025-shared-navigation/screenshots/screens-360x640-sound-on.png) | [bars](../output/qa/rc-025-shared-navigation/screenshots/bars-360x640-sound-off.png), [screens](../output/qa/rc-025-shared-navigation/screenshots/screens-360x640-sound-off.png) |

The shared width is 640 pixels at 841 and 720, 434 pixels at 450, and 344 pixels at 360. Height remains 82 pixels. Native button bounds, fitted glyph bounds, visible caption bounds, fonts, colours, atlas/mask resources, four frame divisions and frame scale match in both contexts. Combat remains in its scrolling page; Map keeps its bottom placement. The independent page layouts do not have to share the same vertical coordinate.

The first comparison exposed a half-pixel horizontal placement difference at width 841. Map now uses the same integer placement as Combat. The [pre-correction log](../output/qa/rc-025-shared-navigation/navigation-capture-centering-before.log) is retained. Final visual review checked both Sound states and the full narrow screens; frame and content match, with only the intended selected Map treatment.

## Input and ownership

Each screen wires the component's existing buttons to its own actions and touch router. Native mouse and finger events exercise Menu, Guide, Map and Sound. Map help and Menu block underlying navigation; the selected Map action preserves the same screen. Combat Map returns to the same prepared model and scroll position. Sound switches the existing owner preference and glyph without replacing the Combat audio coordinator or ambience player. Both input methods restore Sound successfully.

## Validation

Pinned Godot **4.7.2.stable.official.ed1daf0bf**, Windows Compatibility renderer. Task-local settings/cache paths and the Dummy audio driver isolate captures from user settings and audible playback.

| Coverage | Result |
| --- | --- |
| Focused rendered parity and native input | **336 checks, 0 failures**, **32 PNGs** — [log](../output/qa/rc-025-shared-navigation/navigation-capture.log), [assertions and geometry](../output/qa/rc-025-shared-navigation/screenshots/results.json) |
| Application shell | **97 checks, 0 failures** — [log](../output/qa/rc-025-shared-navigation/shell-tests.log), [assertions](../output/qa/rc-025-shared-navigation/shell-tests.json) |
| Existing UI | **1,171 checks, 0 failures** — [log](../output/qa/rc-025-shared-navigation/ui.log); malformed/missing fixture diagnostics are expected |
| Audio | **428 checks, 0 failures** — [log](../output/qa/rc-025-shared-navigation/audio.log) |
| Existing absolute Combat-reference layout | **257 checks, 15 existing failures** with both shared and pre-extraction navigation — [current results](../output/qa/rc-025-shared-navigation/combat-reference/results.json), [isolated old-navigation results](../output/qa/rc-025-shared-navigation/isolated-old-navigation/captures/results.json), [comparison](../output/qa/rc-025-shared-navigation/combat-reference-baseline-comparison.json) |
| Resource-only PCK | **372 policy/integrity checks and 74 exact-payload desktop decode checks, 0 failures** — [audit](../output/qa/rc-025-shared-navigation/resources/resource-audit.json), [decode log](../output/qa/rc-025-shared-navigation/resources/ios-resource-probe.log) |
| Python resource/workflow/transfer regressions | **32 tests passed** — [log](../output/qa/rc-025-shared-navigation/resources/tool-tests.txt) |

These are desktop rendering, interaction and resource checks. They do not establish physical-device or complete-tower acceptance. Earlier Map correction evidence remains unchanged in its own directory.

### Known existing Combat-reference baseline

The unchanged `ui_reference_match_capture.gd` also ran. Its expected absolute 720-pixel layout differs from the current Combat layout: hand, forecast, Cast and navigation are 13 pixels higher. For example, the actual navigation rectangle is `(40, 1501, 640, 82)` while that older expectation is `(40, 1514, 640, 82)`. An isolated QA copy reconstructed the prior inline navigation and produced the same 15 failed measurements; every evidence value matches exactly, and descriptions match after ignoring engine-generated node IDs. The [baseline log](../output/qa/rc-025-shared-navigation/isolated-old-navigation/baseline-reference.log) is retained. Production files were not changed during that baseline experiment. This existing reference drift remains open; the shared-component change does not add a spacer or weaken the older expectations.

## Packaged component

`scenes/ui/theme/navigation_bar.gd` joins the explicit required application inventory and exact-payload decode probe. The missing-runtime regression covers it. Production export still excludes test/capture code and output evidence. The actual pack was decoded from an empty project without a workspace fallback.

Resource-only pack: `builds/rc-025-shared-navigation-resources/RuneCast.pck`, **12,242,812 bytes**, **359 entries**, SHA-256 **`4aed0ebd98c09e046a47b7abfef5d8d39cd84fe78d04e351c21accb23e6b42c8`**. The [export log](../output/qa/rc-025-shared-navigation/resources/export-engine.log) retains the existing SDK-version fallback informational message; no unexpected engine errors occurred.

## Reproduce focused checks

From `C:\Dev\RuneCast`:

```powershell
$engine = 'C:\Dev\RuneCast\.tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe'
$py = 'C:\Users\nguye\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
$env:APPDATA = 'C:\Dev\RuneCast\output\qa\rc-025-shared-navigation\recheck-appdata'
$env:LOCALAPPDATA = 'C:\Dev\RuneCast\output\qa\rc-025-shared-navigation\recheck-localappdata'
Start-Process -FilePath $engine -ArgumentList @('--path','C:/Dev/RuneCast','--audio-driver','Dummy','--log-file','C:/Dev/RuneCast/output/qa/rc-025-shared-navigation/navigation-capture.log','--script','res://tests/navigation_bar_capture.gd') -WindowStyle Hidden -Wait
& $engine --headless --path . --log-file C:/Dev/RuneCast/output/qa/rc-025-shared-navigation/shell-tests.log --script res://tests/application_shell_tests.gd -- --qa-output=res://output/qa/rc-025-shared-navigation
& $engine --headless --path . --export-pack iOS builds/rc-025-shared-navigation-resources/RuneCast.pck --log-file C:/Dev/RuneCast/output/qa/rc-025-shared-navigation/resources/export-engine.log
& $py tools/verify_ios_resources.py --pack builds/rc-025-shared-navigation-resources/RuneCast.pck --engine $engine --report output/qa/rc-025-shared-navigation/resources/resource-audit.json
$env:RUNECAST_RESOURCE_TEST_PACK = 'C:\Dev\RuneCast\builds\rc-025-shared-navigation-resources\RuneCast.pck'
& $py -m unittest discover -s tests -p 'test_ios_*.py' -v
```
