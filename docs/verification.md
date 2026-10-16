# Rune Cast verification record

## October 16, 2026 — Unused resource cleanup

Removed the exact 2,221 project files in the [completed ledger](../output/qa/resource-cleanup-2026-10-16/deletion-manifest.json), totaling 1,370,344,711 bytes. A temporary validation raster created during the checks was also removed and recorded separately. The cleanup changed no live gameplay or rendered artwork: the 450×1000 opening screen is [pixel-identical before and after](../output/qa/resource-cleanup-2026-10-16/screen-comparison.json). [Post-cleanup screen](../output/qa/resource-cleanup-2026-10-16/normal-desktop.png).

| Executed check | Result |
| --- | --- |
| Pinned Godot import | Passed; existing Android build-tools warning remains. |
| Actual game integration | 2,578 checks, 0 failures; [results](../output/qa/resource-cleanup-2026-10-16/runtime/results.json). |
| Editable UI source and active exports | 241 checks, 0 failures; [report](../output/qa/resource-cleanup-2026-10-16/ui-source-validation.json). |
| Resource references/imports/preservation | 1,158 checks, 0 failures; [report](../output/qa/resource-cleanup-2026-10-16/resource-audit.json). |
| Exact cleanup and retained-file hashes | [Validation record](../output/qa/resource-cleanup-2026-10-16/cleanup-validation.json). |

The generator now omits the unused pile alias and eight non-node SVG exports, and rasterizes validation intermediates in memory. Source validation checks the state layers directly in their retained ORA instead of depending on scratch PNGs removed by an earlier cleanup. The source masters and visible state cues remain unchanged. Runtime retirement exceptions require the exact completed owner-authorized manifest, matching original hashes and absent files; unrelated missing assets still fail.

The broader legacy RC-010 [planning audit](../output/qa/resource-cleanup-2026-10-16/asset-plan-validation.json) still flags the existing Combat readiness classification and 14 gameplay/test files changed since its historical baseline. Those files are byte-identical to this cleanup's starting snapshot; their older changes were not part of this task. Current links, asset references and cleanup preservation are checked separately. No Git operation was used.

## October 16, 2026 — Generated painted status frame

The status bar now uses a complete painted PNG from the built-in image tool, replacing the rejected code-drawn outline. [Actual game screen](../output/qa/rc-016/stats-generated-frame/normal-desktop.png) and [before/after](../output/qa/rc-016/stats-generated-frame/before-after.png) were visually inspected. The original generated pixels and alpha are preserved, with generation [prompt/provenance](../source-assets/ui/combat/reference/status-frame/provenance.json) recorded. No specific model version was exposed by the tool.

| Executed check | Result |
| --- | --- |
| Generated frame continuity, source and containment | 47 checks, 0 failures: [results](../output/qa/rc-016/stats-generated-frame/focused/results.json). |
| Actual-scene integration | 2,578 checks, 0 failures: [results](../output/qa/rc-016/stats-generated-frame/runtime/results.json). |
| Resources and preservation | 1,230 checks, 0 failures: [report](../output/qa/rc-016/stats-generated-frame/resource-audit.json). |

All nine width/presentation combinations retain a connected gold enclosure; negative controls reject the earlier open-sided frame. An independent source-grid sampling oracle compares the real render to the generated texture across 68,332 samples (mean RGB error about 0.00256). Live content changes none of the 15,932 protected near-opaque gold pixels at 720/450/360 widths, and divider clearance remains 47/21/8px. Unlike the earlier separate-fill implementation, this PNG contains both frame and face, so source fidelity and live-content protection replace the obsolete red-fill injection test.

The imported texture is 768×305 (936,960 decoded bytes); the conservative ceiling audit rounds its height to 306 and totals 31.674 MiB including all retained poses and reserved VFX. Import/capture completed with the known Android build-tools warning; desktop checks passed. No source-art painting script or Git operation was used. Earlier entries below are superseded where they describe locally drawn borders.

## October 16, 2026 — Drawn status border

The owner rejected the patched ends and requested a proper drawn border. The status frame now has a continuous gold bezel, chamfered corners and straight separators, with unchanged row size/content padding. [Full screen](../output/qa/rc-016/stats-drawn-border/normal-desktop.png) and [comparison (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup) show the new implementation. Earlier endcap/source-equality evidence below describes the superseded renderer.

| Executed check | Result |
| --- | --- |
| Drawn border continuity and containment | 48 checks, 0 failures: [results](../output/qa/rc-016/stats-drawn-border/focused/results.json). |
| Actual-scene integration | 2,574 checks, 0 failures: [results](../output/qa/rc-016/stats-drawn-border/runtime/results.json). |
| Resources and preservation | 1,220 checks, 0 failures: [report](../output/qa/rc-016/stats-drawn-border/resource-audit.json). |

The focused test requires a connected gold enclosure on all four sides at native/0.625/0.5 presentation scales across three viewport layouts, and rejects the earlier open-sided artwork. Red-fill injection and live contents leave all7,188/4,728/3,828 protected gold pixels unchanged at720/450/360 widths. Only antialiased divider fringes, which blend with the fill, are excluded from the opaque-divider protection check; every bezel pixel stays protected. Original source PNGs remain unchanged, no new bitmap was introduced, and no Git operation ran.

## October 16, 2026 — Status-bar end borders

The owner identified the open left/right edges of the Health/Energy/Turn bar. The original source has disconnected corner flares, and prior source-equality checks preserved that defect. Both sides now use matching gold divider artwork to connect their upper and lower rails. [Before/after (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup), [full screen (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup), [native360 closeup (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup).

| Executed check | Result |
| --- | --- |
| Focused stats/endcap regression | 58 checks, 0 failures: [results](../output/qa/rc-016/stats-endcaps/focused/results.json). |
| Actual-scene integration and paint | 2,573 checks, 0 failures: [results](../output/qa/rc-016/stats-endcaps/runtime/results.json). |
| Resources, imports and preservation | 1,220 checks, 0 failures: [report](../output/qa/rc-016/stats-endcaps/resource-audit.json). |

The focused test requires connected visible gold from top to bottom at both ends, at all three native widths and presentation scales1/0.625/0.5. It rejects all three previous full-screen-polish skins, which have57 combined missing gold rows and no connected side path. Each width protects760 added-cap pixels against red-fill injection and live content, with zero changes and zero exterior opaque pixels. The untouched original corners retain515 source samples each (maximum RGB error0.00240). The existing row dimensions, content padding, dividers and live state bindings remain unchanged. No new bitmap, source PNG edit, gameplay change or Git operation. Tests use desktop-rendered viewports, not physical devices.

## October 15, 2026 — Full-screen reference polish

This pass reviews the complete production screen against the approved portrait at equal width. It adopts the original neutral actor and visible scenery, original stats rails with a contained 36 px well, seven clean socket-face variants, complete ribbon ends, normal-width Combat fonts and masked original navigation/resource icons. Tool and navigation content use separate padded lanes; Remove/Rotate are 36×36 at y10 with an 8 px interior gutter. The previous Cast face-continuity fix and all later owner UI exceptions remain. [Current screen (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup), [implementation details](rc-016-integration.md#october-15-2026--full-screen-reference-polish) and [QA directory](../output/qa/rc-016/full-screen-polish/) are the current evidence entry points. Earlier dated results below describe their respective implementations.

| Confirmed check | Result |
| --- | --- |
| UI smoke | 601 checks, 0 failures: [log](../output/qa/rc-016/full-screen-polish/smoke/smoke.log). |
| Focused player-status frame | 40 checks, 0 failures: [results](../output/qa/rc-016/full-screen-polish/stats-focused/results.json). |
| Surface sampling and containment | 35 checks, 0 failures: [results](../output/qa/rc-016/full-screen-polish/surface-probe.json). |
| Original actor/scenery rendering | 8 checks, 0 failures: [results](../output/qa/rc-016/whole-screen-art/arena-focused/results.json). |
| Core rules regression | 1,453 checks, 0 failures: [log](../output/qa/rc-016/full-screen-polish/core/test.log). |
| Actual-scene integration and paint | 2,573 checks, 0 failures, 115 captures: [results](../output/qa/rc-016/full-screen-polish/runtime/results.json). |
| Reference geometry and responsive layout | 257 checks, 0 failures, 11 captures: [results](../output/qa/rc-016/full-screen-polish/measurements/results.json). |
| Touch, keyboard and legal circuits | 146 checks, 0 failures: [results](../output/qa/rc-016/full-screen-polish/touch/results.json). |
| Cast face continuity | 78 checks, 0 failures: [results](../output/qa/rc-016/full-screen-polish/cast-focused/results.json). |
| Resources, imports and source preservation | 1,220 checks, 0 failures: [report](../output/qa/rc-016/full-screen-polish/resource-audit.json). |
| Original Begin marker and rotation | 44 checks, 0 failures: [results](../output/qa/rc-016/full-screen-polish/begin-proof-results.json). |

The actor and scenery recombination matches all 360,002 tested visible source pixels with zero RGB error, outside the four small live-label holes. The [pixel report](../output/qa/rc-016/whole-screen-art/actor-arena-pixel-proof.json), [recombined arena (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup) and [isolated actor (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup) establish that source-level result. Focused checks also cover neutral/attack restoration and preservation of the face, lantern, free hand and boots. This evidence does not assert whole-screen pixel identity.

Actual isolated Godot renders show masked [navigation (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup) and [resource icons (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup) against contrasting backgrounds, plus [compact cards and piles (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup). The [font/layout probe](../output/qa/rc-016/full-screen-polish/typography-fit.json) records fitting opening-card copy, the unchanged small cost glyphs and padded pile captions. The production icon helper updates texture and mask together, including clearing the mask for Sound off.

The [equal-width full-screen comparison (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup) shows the approved painting, normal opening and existing legal Belfry circuit. Different live values, hands and circuits are not forced to match the illustration. Final runs cover 720×1600, 450×1000 and 360×640 native layouts, including lower-page scrolling. The first integration pass caught stock-count line boxes extending 2 px below their inset and navigation content touching its padded well; a second pass found a 0.403 px native Sound-label overrun. Production line spacing and inset lanes were corrected, with Sound reduced to 16 px only below 400 px. Containment assertions were preserved. Failed reports remain alongside final evidence. Cast now uses a local weight850 variation with a 4 px outline while retaining its fitted size.

The exact raster typeface remains unidentified, generated Attack/Spark and board glyphs remain among the fallbacks, and paint hidden by original labels is reconstructed from clean source patches. Source PNGs were not repainted; the unused generated neutral's runtime/import/cache retirement is recorded in the [cleanup manifest](../output/qa/rc-016/whole-screen-art/actor-cleanup-manifest.json). No Git operations were performed. These desktop renders do not establish physical-device acceptance.

Begin also uses its original painted circle, sampled from source `(123,663,96,94)` into the unchanged endpoint glyph rectangle with a contour mask. Its caption remains live and its connection rotates independently. The [isolated render (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup) and [four-rotation proof (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup) find no baked gold-wire or white-caption contamination. End retains its SVG: the original gold wire crosses its top ring and baked END lettering overlaps the lower opening, so the complete clean glyph cannot be extracted from that flat source.

## October 15, 2026 — Cast face continuity

The owner's close-up showed a vertical colour break at the Cast button's right point. The generic nine-slice renderer replaced only the rectangular centre with a clean turquoise sample; the endcaps retained the darker original face. Those different samples met at source x191 and x649. This was a paint-sampling defect, independent of the existing whole-button unavailable tint.

Cast now has one continuous texture mapping through both pointed ends, clipped to its inner contour. The approved cyan bevel and gold rim draw separately. The face keeps the original middle slice's vertical alignment; a clean strip at the same source height replaces old crystal-tip and cost-shadow pixels along the lower rim. The first candidate exposed those baked fragments and is retained in the `first/` QA folder. The final contour and source rectangles are recorded in `source-assets/ui/combat/reference/regions.json`. Original PNGs, button dimensions, live label/cost, disabled safeguards and casting behavior are unchanged.

Actual final gameplay captures: [unavailable Cast (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup) and [ready Cast (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup). Independent visual review of both states and the isolated skin confirms the former endcap seam is gone, the cyan/gold rim remains visible, and no extra baked symbol remains. The resource/import/preservation audit passes 1,221 checks with no errors: [report](../output/qa/rc-016/cast-face-continuity/resource-audit.json). No new bitmap asset or Git operation was used.

| Executed check | Result |
| --- | --- |
| Focused Cast regression | 78 checks, 0 failures: [results](../output/qa/rc-016/cast-face-continuity/focused/results.json). Actual ready/unavailable buttons at 720×1600, 450×1000 and 360×640. |
| Existing actual-scene integration | 2,554 checks, 0 failures, 113 captures: [results](../output/qa/rc-016/cast-face-continuity/runtime/results.json). |
| Resources, imports and preservation | 1,221 checks, 0 failures: [report](../output/qa/rc-016/cast-face-continuity/resource-audit.json). |

The focused test independently samples the approved material at both former cap boundaries and across the full inner face. It rejects every retained pre-fix raster, checks the original rim and clean lower strip against the atlas, and injects a red face to prove the rim cannot be recoloured by the fill. Actual live tips match the isolated skin with the expected ready/unavailable tint. The first full run exposed an oracle rounding error: multiplying an already quantized white capture by the tint differed from tinting before GPU output. The test now renders its expected tint through the same GPU path; the tolerance was not widened and production code did not change. [Initial results](../output/qa/rc-016/cast-face-continuity/focused/pre-quantization-correction-results.json) retain that evidence.

Commands executed: pinned Godot `tests/ui_cast_face_capture.gd` and `tests/ui_art_integration_capture.gd`; `tools/godot.ps1 -Action capture` for opening and the built Belfry fixture; and `python tools/validate_combat_art.py --report output/qa/rc-016/cast-face-continuity/resource-audit.json`. The initial test launch could not open logs before the output folders existed; both suites completed and wrote their JSON reports, and the final focused rerun has a clean saved log. These are desktop-rendered viewport checks, not physical-device acceptance.

## October 15, 2026 — Stats inner frame correction

The owner's close-up identified the same Health/Energy/Turn bar's inner background. The preceding outer-silhouette and rail-continuity checks did not verify the diagonal inner bevel. The 27/11 source caps and rectangular center replacement cut through that bevel, leaving a thin outer rail while replacing some gold with navy material.

The stats renderer now separates its layers: the clean material is clipped to an eight-point inner recess, then the original painted rim is drawn over it as a ring. The 40/19 source caps preserve full corners at the uniform 54/79 height scale; only the long horizontal spans stretch. Clean recess samples remove the original Shield tip and Incoming descenders without replacing the upper gold rail. Dividers stay in the existing 30 px content well. The bar remains 54 px high with unchanged live icons, labels, values and padding. Other surfaces and gameplay are unchanged.

Reviewed actual live-row crops [before (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup) and [after (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup), plus the [full playable screen (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup). Independent visual review confirms intact inner gold corners and no residual source glyphs. The resource audit passes 1,221 checks with no errors: [report](../output/qa/rc-016/stats-inner-frame/resource-audit.json). Original source PNGs remain unchanged.

The live-row comparison then found an additional cause: at 720 px, the arena's full-width art bleed painted over the stats row's top three pixels. Its art/status layers use z20–22, while the stats row was at z0. Stats now draws at z30, below the inspector at z100, preserving arena crop, pose allocation and all layout dimensions. The [failed live comparison](../output/qa/rc-016/stats-inner-frame/focused/live-overlap-before-results.json) and [before image (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup) retain the evidence.

| Executed check | Result |
| --- | --- |
| Focused inner-frame regression | 34 checks, 0 failures: [results](../output/qa/rc-016/stats-inner-frame/focused/results.json). Actual live rows at 720×1600, 450×1000 and 360×640. |
| Existing actual-scene integration | 2,554 checks, 0 failures, 113 captures: [results](../output/qa/rc-016/stats-inner-frame/runtime/results.json). |
| Resources, imports and preservation | 1,221 checks, 0 failures: [report](../output/qa/rc-016/stats-inner-frame/resource-audit.json). |

The focused test injects a bright red face through the production renderer. All 27,159 protected rim pixels across the three widths remain exactly unchanged, while the face changes. An independent original-atlas corner comparison rejects the prior v4 raster, establishing that the new test catches the earlier failure. Live icons, text, Turn parchment and arena paint leave the protected rim unchanged within one 8-bit compositing step. [Native 360 closeup (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup) and [red-fill probe (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup) expose the protected boundary directly. Existing stats-content checks retain the 24/11/24/13 padding contract; their old cap-based well calculation and separator probes were updated to the corrected frame geometry.

Commands executed: pinned Godot `tests/ui_stats_frame_capture.gd`, `tests/ui_art_integration_capture.gd`, and the saved `output/qa/rc-016/stats-inner-frame/capture_live_stats.gd` witness; `tools/godot.ps1 -Action capture`; and `python tools/validate_combat_art.py --report output/qa/rc-016/stats-inner-frame/resource-audit.json`. Final renders complete without script or resource errors. Core rules, input behavior, source PNGs and RC-017 interfaces are unchanged; no Git operations or physical-device tests were performed.

## October 15, 2026 — Display-only forecast and frame cleanup

The Damage/Shield/Cost strip above Cast is now a nonfocusable, pointer-transparent `Control`. It has no button action, gesture registration, hover tooltip or details-window callback. Its three values still read the controller forecast; card/piece/tool inspection, pile inspection and confirmed Pass remain available. Guide text and current consumer contracts describe the display-only behavior.

The player-status artwork is rebuilt around a closed gold frame, using the approved forecast frame's clean rim and the original unmarked stats material. The previous stats crop shared its bottom rail with the board and used incompatible endcaps. The replacement retains the 54 px footprint and padded 30 px content well; both separators end inside the frame instead of repainting its rails. The board crop now ends at source y1255, excluding the adjoining toolbar corner. Its thin outside line also involved original border pixels leaking through the separately scaled page-edge background and a fractional seam exposing candle underpaint. The right background strip now samples clean rock at x824, with overlap under the live frame. An isolated board capture alone was insufficient to verify that defect.

Actual final captures: [opening (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup), [completed circuit (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup), [native 360 upper screen (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup), [native 360 lower screen (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup), [stats closeup (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup) and [cleaned right edge (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup). Earlier dated claims that the forecast opens details are superseded by this owner-requested change.

| Executed check | Result |
| --- | --- |
| UI smoke | 601 checks, 0 failures: [log](../output/qa/rc-016/mobile-polish-v4/smoke/smoke.log). |
| Rendered integration and paint | 2,554 checks, 0 failures, 113 captures: [results](../output/qa/rc-016/mobile-polish-v4/runtime/results.json). |
| Reference geometry/content | 257 checks, 0 failures, 11 captures: [results](../output/qa/rc-016/mobile-polish-v4/measurements/results.json). |
| Rendered touch/keyboard and built circuits | 146 checks, 0 failures: [results](../output/qa/rc-016/mobile-polish-v4/touch/results.json). |
| Resources, imports and preservation | 1,221 checks, 0 failures: [report](../output/qa/rc-016/mobile-polish-v4/resource-audit.json). 530 protected files unchanged, plus the two previously authorized resource-script amendments. |

Real input checks tap the forecast and each metric, hold it and right-click it in incomplete and valid circuits. They verify no inspector, button/focus/gesture target, gameplay mutation, random-stream change or selection change. Existing inspection, confirmed/cancelled Pass, casting, terminal and scrolling checks remain. Raster checks cover continuous stats rails, transparent outer corners, clean material and gaps above/below both dividers. Backdrop probes scan the former seam and original gold-fragment region at each actual page size, including narrow scrolling layouts.

The first runtime attempt found one test-coordinate error: the isolated surface preview used art scale 1 while production uses 720/841. The original divider-gap probes landed on the divider itself. [First results](../output/qa/rc-016/mobile-polish-v4/runtime/first-attempt-results.json) and [log](../output/qa/rc-016/mobile-polish-v4/runtime/first-attempt-capture.log) are retained. The corrected production-scale probes additionally require complete blue rows across both separator gaps; the final runtime rerun passes without a production-code change.

Commands executed: `tools/godot.ps1 -Action smoke`, normal and `board_belfry`/`built` captures; pinned Godot scripts `tests/ui_art_integration_capture.gd`, `tests/ui_reference_match_capture.gd` and `tests/ui_undirected_capture.gd` with their v4 output directories; and `python tools/validate_combat_art.py --report output/qa/rc-016/mobile-polish-v4/resource-audit.json`. Final gameplay captures and rendered suites have no script or missing-resource errors; deliberate invalid-startup fixtures retain their expected diagnostics. No new bitmap was generated or source PNG changed. No Git operation ran.

This verifies the requested presentation and input changes in desktop-rendered viewports. Physical-device acceptance and complete-screen pixel identity remain unclaimed. Core rules and RC-017 interfaces are unchanged; the previously recorded character-pose continuity work remains for animation integration.

## October 15, 2026 — Header order and connector rotation

The full-width header now places Rune Cast on the left and the right-aligned live floor name on the right, retaining 16 px outer padding and a 12 px gap. Split and Join keep their original operation symbols upright while their lines follow the rotated logical ports. The top-left card frame now samples a horizontally mirrored clean top-right corner, replacing the incorrectly oriented bottom-left sample and its below-frame background. All four card materials retain their footprint and 25×29 cost gems. [Opening (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup), [connected circuit (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup), [card-corner proof (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup).

| Executed check | Result |
| --- | --- |
| UI smoke | 595 checks, 0 failures: [log](../output/qa/rc-016/mobile-polish-v3/smoke/smoke.log). |
| Rendered integration, rotation and paint | 2,529 checks, 0 failures: [results](../output/qa/rc-016/mobile-polish-v3/runtime/results.json). Actual gameplay and native 720×1600, 450×1000 and 360×640 views remain covered. |
| Reference geometry/content | 250 checks, 0 failures: [results](../output/qa/rc-016/mobile-polish-v3/measurements/results.json). |
| Resources, imports and preservation | 1,221 checks, 0 failures: [report](../output/qa/rc-016/mobile-polish-v3/resource-audit.json). Original source PNGs and fonts are unchanged. |

The 32 connector renders cover both operation types, four rotations, lit/idle states and two cell sizes. Central glyph pixels remain invariant; independent edge samples and explicit clockwise port sets verify that wires change direction. Actual Rotate taps on installed Split/Join change authoritative orientation without spending resources. The foreground symbol and its lines remain separate layers; the evaluator and port definitions were not changed. Compare [Split before (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup) / [after (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup) and [Join before (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup) / [after (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup). Factory-card raster samples independently check the upper-left rim colour for damage, shield, technique and mixed cards, without changing or enlarging the cost symbol to cover the gap.

Commands executed: `tools/godot.ps1 -Action smoke`; normal and `board_belfry`/`built` captures; pinned Godot `tests/ui_art_integration_capture.gd` and `tests/ui_reference_match_capture.gd` with their v3 capture directories; `python tools/validate_combat_art.py --report output/qa/rc-016/mobile-polish-v3/resource-audit.json`; and the isolated card-corner render. The rendered integration suite exercises touch/keyboard behavior; the separate 119-check touch suite and legacy planning audit were not rerun for this presentation-only change. Final captures/logs contain no script or missing-resource errors. No Git operation was performed. Physical-device testing remains outstanding.

## October 15, 2026 — Header and reference pile correction

Restored the approved Rune Cast wordmark on the right, retained the live floor name on the left, and made the 52 px header span the viewport. A 12 px gap separates the floor label from the wordmark. [Opening (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup), [completed circuit (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup) and [native lower controls (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup) are actual final gameplay captures.

The remaining stats overlap was source backdrop outside its painted outline. The Pass-side line came from the toolbar's left slice including pixels from the reference WIRING label. Both sampling defects are corrected without changing the controls' padding. `ReferencePile` now uses each approved pile's distinct original body, compass/skull and plaque at uniform scale, with live counts/captions. The obsolete generic deck renderer was removed. Card cost gems are 25×29 with 20 px numerals, down from 34×38 with 26 px numerals. All source PNGs and fonts are unchanged.

| Executed check | Result |
| --- | --- |
| UI smoke | 595 checks, 0 failures: [log](../output/qa/rc-016/mobile-polish-v2/smoke/smoke.log). |
| Rendered integration and paint | 2,273 checks, 0 failures, 74 captures: [results](../output/qa/rc-016/mobile-polish-v2/runtime/results.json). Includes 720×1600, 450×1000, native 360×640, rebuilding, resizing and terminal states. |
| Reference geometry/content | 250 checks, 0 failures, 11 captures: [results](../output/qa/rc-016/mobile-polish-v2/measurements/results.json). |
| Rendered touch/keyboard and branching | 119 checks, 0 failures: [results](../output/qa/rc-016/mobile-polish-v2/touch/results.json). |
| Resource/import/preservation audit | 1,221 checks, 0 failures: [report](../output/qa/rc-016/mobile-polish-v2/resource-audit.json). 530 protected files unchanged plus the two previously authorized resource-script amendments. |
| Pile geometry/lifecycle | Correct original source mappings, live count padding, reduced card costs and 250 teardown cycles: [log](../output/qa/rc-016/mobile-polish-v2/pile-layout-probe.log). |

New checks examine actual paint, not only control rectangles. Stats exterior pixels are transparent; the Pass-side sample contains clean slate; the header paints both outer corners; and each pile emblem is compared against independently sampled original atlas pixels (mean RGB error below 0.001 from linear scaling). Close-up review caught 36 stray pixels from the original Discard caption: [before evidence](../output/qa/rc-016/mobile-polish-v2/runtime/caption-leak-before.json). The final silhouette excludes that row, and both gaps above the live captions contain zero opaque pixels. [Final isolated Discard (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup). Earlier test assumptions and the first attempted header construction are retained in the versioned QA folder; final gameplay captures have no script/resource errors.

Commands executed: `tools/godot.ps1 -Action smoke`, normal and `board_belfry`/`built` captures; pinned Godot scripts `tests/ui_art_integration_capture.gd`, `tests/ui_reference_match_capture.gd`, `tests/ui_undirected_capture.gd`; `python tools/validate_combat_art.py`; and `python tools/validate_asset_plan.py`, with reports under `output/qa/rc-016/mobile-polish-v2`. The legacy asset-plan validator still rejects the existing `integrated` reference-art record with unresolved rights and reports changed files against its RC-010-era preservation baseline; its [report](../output/qa/rc-016/mobile-polish-v2/asset-plan-validation.json) is not recorded as passing. The current RC-016 resource/preservation audit passes. Updated pile consumer mappings and all new local documentation links are checked separately.

No core rules changed or Git operation ran. No new bitmap was generated and no shared source asset was removed. Desktop render/interaction results do not establish physical-device acceptance or complete-screen pixel identity. RC-017 integration APIs remain available; the previously recorded pose-continuity work remains.

## October 15, 2026 — Mobile presentation corrections

Corrected the owner's marked mobile presentation issues in the playable Combat screen. [Opening capture (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup) and [completed circuit (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup) show the final result. The floor heading occupies the top left; the wordmark, Pause and BOSS label are absent. Stats content fits its 30 px interior. Pass parchment and Cast samples are clipped to their painted outlines. The x/slashed-circle state badges and hover tooltips are suppressed in production, while disabled-action guards, focus, selection, tap/hold inspection and confirmed Pass remain functional. Discard's artwork is mirrored; both pile symbols are centered on their front card, with upright live counts and captions.

Navigation separates icon and caption lanes inside the 82 px frame. The first/last segments use 26 px outer and 8 px inner horizontal padding to clear the sloped rails. Captions use 18 px type, or 17 px at native widths below 400. Visible font bounds, including descenders, retain at least 4 px clearance from the frame and 2 px from the icon. Existing circuit-control gutters remain at least 6 px.

| Executed check | Result |
| --- | --- |
| UI smoke | 595 checks, 0 failures: [final log](../output/qa/rc-016/mobile-polish/smoke-final/smoke.log). |
| Rendered integration and containment | 2,065 checks, 0 failures, 69 captures across 720×1600, 450×1000 and native 360×640 plus resizing: [results](../output/qa/rc-016/mobile-polish/runtime/results.json). |
| Reference geometry and content | 247 checks, 0 failures: [results](../output/qa/rc-016/mobile-polish/measurements/results.json). |
| Rendered touch/keyboard and branching | 119 checks, 0 failures: [results](../output/qa/rc-016/mobile-polish/touch/results.json). |
| Resources, imports and preservation | 1,219 checks, 0 failures: [report](../output/qa/rc-016/mobile-polish/resource-audit.json). 530 protected files are unchanged; the two previously authorized resource amendments remain hash-bound. No source PNG, font or gameplay data was changed. |
| Pile lifecycle | Geometry and 250 create/resize/text-change/free cycles pass: [probe log](../output/qa/rc-016/mobile-padding/pile-layout-probe.log). |

Verification caught and corrected a 1 px stats-height expansion, first/last navigation content reaching the outer rails at native 360, and deferred layout callbacks retaining freed controls. The [initial smoke log](../output/qa/rc-016/mobile-polish/smoke/smoke.log), [initial runtime log](../output/qa/rc-016/mobile-polish/runtime/first-attempt.log) and [second runtime results](../output/qa/rc-016/mobile-polish/runtime/second-attempt-results.json) preserve those failed attempts. Main surface callbacks now validate captured controls; pile layout resolves weak references, rejects deleted children and coalesces deferred fitting. The final suites complete without the earlier native crash or script errors. Deliberate invalid-startup fixtures still emit their expected diagnostic messages.

Commands executed: `tools/godot.ps1 -Action smoke`, normal and `board_belfry`/`built` captures; pinned Godot scripts `tests/ui_art_integration_capture.gd`, `tests/ui_reference_match_capture.gd` and `tests/ui_undirected_capture.gd` with capture directories under `output/qa/rc-016/mobile-polish`; and `python tools/validate_combat_art.py --report output/qa/rc-016/mobile-polish/resource-audit.json`. The core evaluator was unchanged, so its earlier recorded regression was not rerun for these presentation corrections. No Git operation was performed.

This is desktop render and interaction verification, not physical-device acceptance or a claim of pixel-identical artwork. No new bitmap assets were introduced. The full-pack dimensional estimate remains 31.777 MiB including the future 2 MiB VFX allowance; actual device residency was not measured. RC-017 may continue using the existing integration APIs, with character-pose visual continuity and device validation still outstanding as recorded in the preceding handoff.

## October 15, 2026 — Approved reference artwork adoption

The owner requested the remaining artwork differences be corrected. The playable screen now samples separable clean decoration from the unchanged approved painting and uses three new built-in GPT Image outputs for the neutral character, obscured arena center and painted icons. [Opening comparison (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup), [completed-circuit comparison (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup), and [visual review](../output/qa/rc-016/reference-art/visual-review.json) show the current result. These images are actual normal-game captures; source reconstruction and game-state differences remain visible and exact whole-screen equality is not asserted.

| Executed check | Result |
| --- | --- |
| Core/controller/content | 1,453 checks, 0 failures: [log](../output/qa/rc-016/reference-art/core/test.log). |
| UI smoke | 594 checks, 0 failures: [log](../output/qa/rc-016/reference-art/smoke/smoke.log). |
| Rendered integration and containment | 1,643 checks, 0 failures, 69 captures: [results](../output/qa/rc-016/reference-art/runtime/results.json). |
| Reference geometry and content | 247 checks, 0 failures: [results](../output/qa/rc-016/reference-art/measurements/results.json). |
| Rendered touch/keyboard and branching | 119 checks, 0 failures: [results](../output/qa/rc-016/reference-art/touch/results.json). |
| Resources, imports and preservation | 1,220 checks, 0 failures: [report](../output/qa/rc-016/reference-art/resource-audit.json). 530 protected files unchanged; two resource scripts have explicit hash-bound [owner-directed amendments](../source-assets/ui/combat/reference/authorized-resource-changes.json). |

The first integration run found a 2 px toolbar gutter shortfall, preserved in [first-attempt results](../output/qa/rc-016/reference-art/runtime/first-attempt-results.json). Final side insets are 32 logical pixels, with 7 px desktop / 5 px narrow inter-control gaps. The minimum 6 px painted-frame clearance remains independently checked. Full-width arena geometry is checked separately from status content geometry; BOSS sits between the boots as in the reference, while name and health remain below the feet. Card categories, Incoming and Cast caption remain absent, and forecast groups remain centered.

Final import limits are 512 px for the new neutral, 960 px for the generated arena center, 768 px for the icon sheet and 1024 px for the retained underpaint. All original PNG bytes remain unchanged. The actual rendered texture census is 20,467,784 RGBA8 bytes (19.52 MiB); the deliberately broader full-pack estimate including optional poses and a future 2 MiB VFX allowance is 31.777 MiB against the provisional 32 MiB subtotal. These are dimensional estimates, not measured device residency or frame time. The approved atlas stays at its full 841×1870 resolution.

Commands executed: `tools/godot.ps1 -Action import`, `-Action test`, `-Action smoke`, normal and `board_belfry`/`built` captures; pinned Godot scripts `tests/ui_art_integration_capture.gd`, `tests/ui_reference_match_capture.gd`, `tests/ui_undirected_capture.gd` with capture directories below `output/qa/rc-016/reference-art`; and `python tools/validate_combat_art.py --report output/qa/rc-016/reference-art/resource-audit.json`. Final import and captures have no missing-resource, script or shader errors. The host reports missing Android build-tools; no mobile export or physical-device test is claimed.

The [cleanup manifest](../output/qa/rc-016/reference-art/deletion-manifest.json) records removal of the 18 superseded generated surface PNGs, their imports and exact caches: 72 files / 24,856,901 bytes. Approved references, shared canonical source packs, fonts, retained hit/attack art and gameplay data remain. RC-017 can use the same APIs, but the newly referenced neutral and retained attack/hit paintings still need a visual continuity pass before production animation approval.

## October 15, 2026 — Full-screen reference alignment

Compared the entire game to the approved image at identical display dimensions, then corrected typography, icon sizes, positions and spacing while applying the owner's card-category and Incoming removals. [Interactive comparison (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup), [opening (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup) and [active circuit (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup).

| Executed check | Result |
| --- | --- |
| UI smoke | 594 checks, 0 failures: [log](../output/qa/rc-016/full-screen-alignment/smoke/smoke.log). |
| Rendered integration and content containment | 1,675 checks, 0 failures: [results](../output/qa/rc-016/full-screen-alignment/runtime/results.json). |
| Reference geometry and content | 247 checks, 0 failures: [results](../output/qa/rc-016/full-screen-alignment/measurements/results.json). |
| Rendered touch/keyboard and branching | 119 checks, 0 failures: [results](../output/qa/rc-016/full-screen-alignment/touch/results.json). |
| Resource/preservation audit | 1,352 checks, 0 failures; all 532 protected hashes unchanged: [report](../output/qa/rc-016/full-screen-alignment/resource-audit.json). |

New checks assert category-line absence, one card divider, complete opening copy, icon/title/effect separation, three centered forecast groups without Incoming, and endpoint containment/separation across all four rotations at three sizes. Existing 6 px toolbar gutter, full portrait visibility, live values and interaction assertions remain. The [first integration attempt](../output/qa/rc-016/full-screen-alignment/runtime/first-attempt-results.json) caught editing-feedback height growth, a narrow Straight title wrap and a narrow Damage group overflow; all were fixed without weakening bounds. Source artwork and font binaries remain unchanged. Visual comparison establishes the implemented proportions and intentional removals, not identical artwork or identification of the painting's original font.

## October 15, 2026 — Circuit button padding

The owner requested visible padding between the circuit buttons and the frame beyond merely clearing its border. The toolbar's top and bottom borders are lighter, side insets are 30 px, and desktop button separation is 8 px. Button height, text/glyph sizes and desktop section positions remain unchanged. [Current desktop view (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup).

Rendered integration passes **1,395 checks, 0 failures** ([results](../output/qa/rc-016/circuit-padding/runtime/results.json)); reference layout passes **247 checks, 0 failures** ([results](../output/qa/rc-016/circuit-padding/measurements/results.json)). The new assertion maps independently sampled slate bounds through the actual nine-slice transform and requires at least 6 px of visible gutter around every toolbar control. It covers normal and two-row layouts. Desktop visual comparison confirms visible space above/below the circuit slots and stable text size. No new bitmap assets were created.

## October 15, 2026 — Painted-frame containment

The follow-up screenshot exposed a gap in the prior checks: children could stay inside a Control rectangle while overlapping its painted gold rim. The corrected layout uses independently measured interior bounds for both stats and toolbar. [Final desktop view (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup).

| Executed check | Result |
| --- | --- |
| UI smoke | 594 checks, 0 failures: [log](../output/qa/rc-016/frame-containment/smoke/smoke.log). |
| Rendered integration and painted-content containment | 1,353 checks, 0 failures: [results](../output/qa/rc-016/frame-containment/runtime/results.json). |
| Reference geometry and content | 247 checks, 0 failures: [results](../output/qa/rc-016/frame-containment/measurements/results.json). |
| Rendered touch/keyboard and branching | 119 checks, 0 failures: [results](../output/qa/rc-016/frame-containment/touch/results.json). |
| Resource/preservation audit | 1,352 checks, 0 failures; all 532 protected hashes unchanged: [report](../output/qa/rc-016/frame-containment/resource-audit.json). |

The new assertions inspect full Label and TextureRect bounds, actual painted destinations, individual stats segments, padded Turn/Pass parchment, every toolbar input, stock title/glyph/count separation and editing icon/caption clearance. Native 720×1600, 450×1000 and 360×640 layouts and resize paths pass. The first two strengthened runs caught narrow-screen outer-edge and separator overflow; both reports are retained as [first pass](../output/qa/rc-016/frame-containment/runtime-first-pass.json) and [second pass](../output/qa/rc-016/frame-containment/runtime-second-pass.json). Final desktop and narrow captures were visually inspected. Existing board/card positions and production gameplay are preserved.

## October 15, 2026 — Annotated-area correction

The owner's highlighted screenshot exposed inner-content issues beyond the prior section-bound tests. The correction removes the production **Cast ends turn** label/strip, moves and enlarges intent/boss text, constrains the stats crystal, aligns toolbar content with its painted controls, enlarges pile plaques/counts and gives navigation more padding. [Final desktop view (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup).

| Executed check | Result |
| --- | --- |
| UI smoke | 594 checks, 0 failures: [log](../output/qa/rc-016/highlight-correction/smoke/smoke.log). |
| Rendered integration and highlighted content | 813 checks, 0 failures: [results](../output/qa/rc-016/highlight-correction/runtime/results.json). |
| Reference geometry with owner-requested caption/spacing revision | 247 checks, 0 failures: [results](../output/qa/rc-016/highlight-correction/measurements/results.json). |
| Rendered touch/keyboard and branching | 119 checks, 0 failures: [results](../output/qa/rc-016/highlight-correction/touch/results.json). |
| Resource/preservation audit | 1,352 checks, 0 failures; all 532 protected hashes unchanged: [report](../output/qa/rc-016/highlight-correction/resource-audit.json). |

New assertions verify caption absence, the energy icon's actual height and containment, count-label centering inside each plaque, non-overlapping pile captions and navigation icon padding. They caught a real 3 px count-label overflow and caption underflow; the final local font metrics and pile height resolve those failures without reducing visible numeral size. The old strict full-pose-envelope status assertion is replaced with clearance below the currently displayed neutral feet. Tests retain actor/crop/scale and live-value checks. Physical-device and exact artwork identity claims are not inferred from desktop results.

## October 15, 2026 — RC-016 reference geometry and typography

The owner's scale/font/spacing rejection led to an independent [reference measurement audit](../output/qa/rc-016/geometry-correction/reference-layout.json), followed by actual renderer assertions against those targets. The normal 720×1600 design canvas now checks the 137×122 sockets, 560×500 grid, 495×54 ribbon, 149×146 cards and centered 640 px forecast/navigation rows within 1–3 px of the normalized layout targets. Tests also cover visible icon content, asymmetric board padding, role-specific fonts, complete card text and zero portrait overflow. The source painting has irregular contours; these are layout tolerances rather than an image-similarity score.

| Check executed | Result and evidence |
| --- | --- |
| Core/controller/content | **1,453 checks, 0 failures**, [log](../output/qa/rc-016/geometry-correction/core/test.log). |
| Actual-scene UI | **594 checks, 0 failures**, [log](../output/qa/rc-016/geometry-correction/smoke/smoke.log). |
| Rendered art/gameplay integration | **750 checks, 0 failures**, [results](../output/qa/rc-016/geometry-correction/runtime/results.json). AtlasTexture wrappers count their full backing image once; card font roles are checked. |
| Measured reference geometry/content | **247 checks, 0 failures**, [results](../output/qa/rc-016/geometry-correction/measurements/results.json). [Opening (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup) and [legal branching circuit (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup) use real game states. |
| Final normal desktop and visual review | [450×1000 desktop (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup) and [inspection receipt](../output/qa/rc-016/geometry-correction/visual-review.json). Toolbar adjustment is complete; source-art differences and owner acceptance remain explicitly separate. |
| Touch/undirected branching | **119 checks, 0 failures**, [results](../output/qa/rc-016/geometry-correction/touch/results.json). |
| Resources/imports/preservation | **1,352 checks, 0 failures**, [report](../output/qa/rc-016/geometry-correction/resource-audit.json); all 532 protected hashes unchanged. |

The pre-existing broad socket aspect check was replaced by the measured reference ratio with a pixel-rounding tolerance; minimum input sizes and gameplay assertions remain. A Godot native Button with TOP icon alignment was reserving an extra text row after its native icon was removed. Clearing that alignment fixes the overflow without reducing visible text size. Opening card titles and descriptions are complete at the smaller 149×146 footprint.

The same 18 image-generated PNGs are retained unchanged. This pass changes layout, font resources, source-region sampling and live glyph presentation; it creates no new bitmap artwork. The conservative full-pack estimate remains 31.83918 MiB including the future 2 MiB VFX allowance. Reference source-art identity, physical-device behavior and owner visual acceptance are not inferred from these technical passes. Prior screenshot counts and October 14/13 statuses below remain historical.

## October 14, 2026 — RC-016 image-generated painted UI rework

**Historical October14 status:**18 generated painted surfaces were integrated and technical regressions passed. The owner's subsequent scale/typography rejection is addressed above.

The built-in GPT Image tool created the painted 2D surfaces. All 18 selected PNGs remain byte-identical to their tool outputs at `assets/ui/combat/generated/`; Godot samples normalized painted regions and applies import size limits. No local script repainted or regenerated those pixels. Godot still handles live text, icons, circuit connections, values, input and responsive layout. The tool does not expose its model/version, so a specific GPT Image release is not asserted. [Prompts](../source-assets/ui/combat/generated/prompts.json), [per-file provenance and hashes](../source-assets/ui/combat/provenance.json), [source notes](../source-assets/ui/combat/README.md) and the [normal 450×1000 desktop capture (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup) record the implemented approach.

| Check actually executed | Result and evidence |
| --- | --- |
| Core/controller/content | **1,453 checks, 0 failures**, [log](../output/qa/rc-016/image-rework/core/test.log). |
| Actual-scene UI | **594 checks, 0 failures**, [log](../output/qa/rc-016/image-rework/smoke/smoke.log). |
| Actual rendered art/gameplay integration | **737 checks, 0 failures; 69 listed captures**, [results](../output/qa/rc-016/image-rework/runtime/results.json). |
| Focused composition and live content | **157 checks, 0 failures; 11 listed captures**, [results](../output/qa/rc-016/image-rework/measurements/results.json). These are measured geometry/content assertions, not a pixel-identity score. |
| Touch and undirected branching | **119 checks, 0 failures; 18 listed main captures plus nine touch/detail images**, [results](../output/qa/rc-016/image-rework/touch-branch/results.json), [detail images](../output/qa/rc-016/image-rework/touch-branch/touch/). |
| Standard desktop entry and standalone surfaces | [450×1000 normal desktop after cleanup (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup), [18-role surface sheet (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup), [surface render log](../output/qa/rc-016/image-rework/surface-preview.log). |
| Image-generation identity | All **18 output PNG hashes** match the selected tool outputs in [provenance](../source-assets/ui/combat/provenance.json). The raw PNG and runtime path are the same retained file, avoiding a redundant duplicate source copy. |

The post-cleanup [resource audit](../output/qa/rc-016/image-rework/resource-audit.json) passes **1,343 checks**, with all **532 protected hashes** unchanged. Its conservative decoded full-pack estimate including the future 2 MiB VFX allowance is **31.83918 MiB** against the provisional 32 MiB subtotal.

The final narrow-screen visual check found and corrected overlap between forecast badges and Incoming text. At native narrow widths, the forecast now uses 82 pixels, a separate 32-pixel Incoming lane and 28-pixel icons; the normal 720-wide layout stays at 62 pixels. The final runtime suite adds explicit separation checks. Refreshed 360-wide opening and 450-wide unaffordable views show separated labels, while the normal desktop still fits the full screen.

The separately executed [legacy asset-plan validator](../output/qa/rc-016/image-rework/asset-plan-validation.json) retains its original RC-010 preservation guard. Its single error lists 14 authorized code/data changes from subsequent RC-016A/RC-016 work; structural, manifest and link checks succeed. The old guard was not modified or relabelled as passing. Current preservation is measured against the separate 532-file RC-016 resource baseline.

The sampled actual consumer texture estimate is **24,187,720 bytes / 23.06721 MiB**. Dimensional/import estimates exclude font atlases, engine/driver/framebuffer/cache overhead and transient allocations; they do not measure physical-device residency or frame time. The retained crypt/actor scale, production state, live target dimensions and normal full-screen fit are unchanged. Existing desktop synthetic input checks do not establish Android/iOS device acceptance.

Cleanup removed **1,264 files / 565,617,093 bytes** under the [path/hash-verified deletion manifest](../output/qa/rc-016/image-rework/deletion-manifest.json). The [retirement ledger](asset-cleanup.md#october-14-2026--image-generated-combat-rework-cleanup) replaces links to superseded screenshots. Compact older JSON/log records retain original counts and hashes. Earlier October 13 numbers below belong to the procedural version and must not be presented as new generated-art results.

## October 13, 2026 — RC-016 reference-fidelity follow-up

The owner rejected the appearance after the height correction. The earlier 618-check pass established full-screen bounds and interaction behavior; it did not establish fidelity to the approved reference. That result and its visual receipt are retained below as historical evidence.

The October 13 correction restores the full retained crypt backdrop and extends the existing theme with [editable decorative surfaces](../scenes/ui/theme/combat_surface.gd). Six retained r006 material copies have [recorded source hashes](../source-assets/ui/combat/provenance.json). Distinct recessed board/socket/card surfaces, a circuit ribbon, tool slots, parchment tabs, layered gray piles, shared stats/navigation strips, stacked boss labels and health, rounded glowing undirected connections, centered Cast and a caption band replace the mismatched generic treatment. The existing controller still owns all values and interactions. Compact cards are 164×168 with 14px descriptions and 44×44 inspection targets; the [Godot size probe](../output/qa/rc-016/reference-match/card-size-probe.log) confirms complete normal opening names and descriptions after eliminating scrollbar-driven wrapping.

| Follow-up check actually executed | Result and evidence |
| --- | --- |
| Core/controller/content regression | **1,453 checks, 0 failures**, [log](../output/qa/rc-016/reference-match/core/test.log). |
| Actual-scene UI regression | **594 checks, 0 failures**, [normal-access log](../output/qa/rc-016/reference-match/smoke-full-access/smoke.log). The initial sandbox-limited run is intermediate evidence, not the accepted result. |
| Native art/gameplay integration | **622 checks, 0 failures; 69 captures**, [results](../output/qa/rc-016/reference-match/runtime/results.json). Covers normal full-screen bounds, native narrow layouts, resize, live state and interaction behavior. |
| Touch and undirected branch regression | **119 checks, 0 failures; 27 captures**, [results](../output/qa/rc-016/reference-match/touch-branch/results.json). |
| Focused reference geometry and content checks | **150 checks, 0 failures; 11 captures**, [measurements](../output/qa/rc-016/reference-match/measurements/results.json). Refreshed after final decorative polish, title and Pause placement; these checks do not measure pixel identity. |
| Resource, imports and preservation | **1,229 checks, 0 failures**, [audit](../output/qa/rc-016/reference-match/resource-audit.json). All **532 protected files** remain unchanged; original assets, references, core and data are preserved. |
| Final visual comparison and normal desktop capture | [Reviewed final captures](../output/qa/rc-016/reference-match/visual-review.json), [normal desktop — historical image retirement](asset-cleanup.md#october-14-2026--image-generated-combat-rework-cleanup), and [branching example — historical image retirement](asset-cleanup.md#october-14-2026--image-generated-combat-rework-cleanup). Major composition defects are corrected; retained character/art differences remain explicit. |

The refreshed conservative decoded RGBA8 estimate is **24.9333 MiB** for the full delivered families, six combat material copies, backdrop, two crypt layers and neutral actor; **26.9333 MiB** with all three poses, or **28.9333 MiB** including the provisional 2 MiB future VFX allowance, against the provisional 32 MiB art subtotal. Sampled actual consumer resources total **21.6833 MiB** (**22,736,548 bytes**), including textures preloaded internally by the new surface renderer. These are dimensional estimates, excluding font atlases, engine/driver/framebuffer/cache/transient overhead; they are not measured physical-device residency or frame time.

The correction is a reference-guided reconstruction using retained paints and live controls. No exact pixel-identical match, new generated painting, owner visual approval, rights clearance or Android/iOS acceptance is claimed. The delivered Shadeling pose, actor scale and layered arena crop remain intact. No core/data changes, Git operations, animation or new progression flow are part of this follow-up.

## October 13, 2026 — RC-016 layout correction

**Historical correction, superseded by the reference-fidelity follow-up above.** The owner rejected the initial art integration's overly tall composition. Its checks showed that controls could be reached by scrolling; they did not establish that the agreed complete screen fit the normal viewport. The previous completion statement and results below are retained as historical evidence with that limitation.

The corrected normal 720×1600 design canvas fits arena, stats, board, toolbar, hand, forecast, Cast and navigation without page overflow, including its scaled 450×1000 desktop presentation. Native 450×1000 and 360×640 layouts retain scrolling as a narrow-screen fallback. The existing seven actions share one toolbar (seven columns at width ≥640, four below), board cells are rectangular (maximum 136×116, height at most 0.86 of width), compact cards are 168×188 with a separate 44px Info target, and the forecast uses 62px with incoming attack below its three values. Action log/editing help share a fixed line with full tooltips. Detailed invalid reasons remain inspectable, while insufficient-energy and conflict feedback is also visible in the banner. [Current integration usage](rc-016-integration.md) records the exact card typography and component contracts.

| Correction check actually executed | Result and evidence |
| --- | --- |
| Actual-scene art and gameplay suite | **618 checks, 0 failures**, [results](../output/qa/rc-016/layout-correction/final/runtime-v2/results.json), [log](../output/qa/rc-016/layout-correction/final/art-integration-v2.log). Adds normal full-screen bounds across ten gameplay states and live card-name checks to native/resizing/input coverage. |
| Headless actual-scene UI regression rerun | **594 checks, 0 failures**, [smoke log](../output/qa/rc-016/layout-correction/final/smoke-fixed/smoke.log), exit 0 after the stable hand-layout fix. |
| Touch and undirected branch rerun | **119 checks, 0 failures**, [results](../output/qa/rc-016/layout-correction/final/touch-branch/results.json), [log](../output/qa/rc-016/layout-correction/final/touch-branch.log). Includes the larger-hand case after the scrollbar-layout correction. |
| Resource and preservation audit | **1,153 checks, 0 failures**, [report](../output/qa/rc-016/layout-correction/final/resource-audit.json). All **532 protected files** remain unchanged. |
| Normal desktop launch | Corrected **450×1000** window using the project's 720×1600 canvas scaling, [capture — historical image retirement](asset-cleanup.md#october-14-2026--image-generated-combat-rework-cleanup), [log](../output/qa/rc-016/layout-correction/final/desktop/capture.log). |
| Visual review | [Receipt](../output/qa/rc-016/layout-correction/visual-review.json) records the approved reference, inspected iteration-three renders and three exact final captures: normal desktop plus full-screen opening and built. Hashes are recorded. This is a technical review, not owner aesthetic acceptance. |
| Documentation and manifest | [Correction audit](../output/qa/rc-016/layout-correction/documentation-audit.json) passes current links, final receipts and appended consumer evidence. The separate [asset-plan report](../output/qa/rc-016/layout-correction/asset-plan-validation.json) retains exactly the existing historical protected-file failure; no new manifest errors. |

The larger-hand regression initially triggered a repeatable engine crash: appearance of its horizontal scrollbar changed hand height, which changed page overflow/arena width and caused layout feedback. Production now suppresses the hand's horizontal scrollbar while retaining drag and focus scrolling; the corrected larger-hand touch and smoke runs pass. The delivered resources, crypt crop, full actor/lantern scale and gameplay model remain unchanged; default noncompact card consumers also remain unchanged. Core was not rerun for this presentation-only correction; its earlier 1,453-check result remains historical, with unchanged core/data verified by the preservation audit. No animation or new artwork is introduced. Existing rights and physical-device limitations remain open. Results from the original RC-016 integration below remain historical unless separately recorded above as correction reruns.

## October 13, 2026 — RC-016 playable Combat art integration

**Complete for the scoped technical integration. RC-017 is ready.** The ordinary [main scene](../scenes/main.tscn) now consumes the RC-012 fonts/icons, RC-013 painted theme/components, RC-014 Shadeling scene and RC-015 crypt scene. [Usage and geometry](rc-016-integration.md) describe the exact crop, proportional actor, responsive page and live bindings. The approved clean-board image was inspected; the later visible confirmed Pass decision remains authoritative. The shipped core/data, completed artwork and approved references are byte-identical to the RC-016 baseline.

| Check actually executed in RC-016 | Result and evidence |
| --- | --- |
| Pinned engine/import | Godot **4.7.2.stable.official.ed1daf0bf**; final [import](../output/qa/rc-016/final-checks/import.log) exits 0. The pre-existing Android build-tools configuration warning remains; no script/import/missing-resource failure. |
| Core/controller/content regression | **1,453 checks, 0 failures**, [test log](../output/qa/rc-016/implementation/test.log), executed during integration. Core/data remained unchanged through final presentation fixes; this count is from this task's run, not copied from RC-016A. |
| Final headless actual-scene UI regression | **594 checks, 0 failures**, [smoke log](../output/qa/rc-016/final-accepted/smoke.log), after all layout, focus and Menu fixes. Deliberately missing/invalid fixtures produce expected diagnostics. |
| Final native art/gameplay integration | **563 checks, 0 failures; 59 PNG captures**, [results](../output/qa/rc-016/runtime-accepted/results.json), [log](../output/qa/rc-016/runtime-accepted.log), [runner](../tests/ui_art_integration_capture.gd). Normal production entry in native 720×1600, 450×1000 and 360×640 SubViewports plus resize transitions. |
| Existing touch and undirected branch suite rerun | **119 checks, 0 failures; 27 PNG captures** (18 layout and 9 touch/detail), [results](../output/qa/rc-016/touch-branch-final/results.json), [log](../output/qa/rc-016/touch-branch-final.log). The runner's added destination argument preserves its earlier RC-016A evidence. |
| Normal desktop launch | Actual **450×1000 window**, 720-wide project canvas scaling, [capture — historical image retirement](asset-cleanup.md#october-14-2026--image-generated-combat-rework-cleanup), [log](../output/qa/rc-016/final-accepted/capture.log). Root inspected the rendered output after final changes; this is the normal entry path without a development encounter override. |
| Independent visual and code review | [Visual receipt](../output/qa/rc-016/visual-review.json): approved reference plus **22 exact final captures** actually viewed; all recorded image hashes match, no actionable sampled clipping/integration finding. Separate final read-only code review found no introduced state/focus/layout/resource blocker. Root inspected additional final native and desktop views. |
| Imports, dependencies, preservation and estimates | **1,153 checks, 0 failures**, [resource audit](../output/qa/rc-016/resource-audit.json), [validator](../tools/validate_combat_art.py). All **532 protected files** match the [pre-integration baseline](../output/qa/rc-016/preservation-baseline.json): source/runtime artwork, approved references, gameplay core and data. Checks cover local resources, texture recipes/cache, caps, filtering, fonts/licences and export exclusions. |
| Current documentation/manifests | [Scoped document audit](../output/qa/rc-016/documentation-links.json) checks updated links, final receipts and manifest evidence. The unchanged [RC-010 asset-plan validator](../output/qa/rc-016/asset-plan-validation.json) retains one historical protected-files failure for 14 authorized RC-016A/RC-016 gameplay/UI/test/data changes; its other schema/path/dependency/current-contract checks pass. The old baseline was not rewritten or weakened. |

The integration runner exercises actual selection and pointer/keyboard routes: connector place/rotate/remove/refund, complete/incomplete/conflicting circuits, live costs/counts/forecasts, insufficient energy, card Info/I/Escape and modal focus, cancelled Pass, confirmed Pass with an empty hand, Cast and next-turn rebuild/log/piles, victory/defeat, duplicate delayed commands and disabled/terminal controls. It checks visible target bounds, painted socket alignment, full actor/lantern envelope, fixed arena transforms, native Menu bounds, page/hand scrolling and explicit focus reveal. The only injected boundary states are energy, empty hand, terminal HP and a known conflict graph; ordinary opening draws/endpoints/kits and command-built valid circuits use existing production helpers. The separate branch suite renders the reproducible Belfry Split/Join witness. Historical profile coverage is retained in core/smoke; the earlier 22-fingerprint audit was not newly executed here.

Representative final captures: [720 opening — historical image retirement](asset-cleanup.md#october-14-2026--image-generated-combat-rework-cleanup), [450 opening — historical image retirement](asset-cleanup.md#october-14-2026--image-generated-combat-rework-cleanup), [360 board — historical image retirement](asset-cleanup.md#october-14-2026--image-generated-combat-rework-cleanup), [360 hand/forecast/Cast — historical image retirement](asset-cleanup.md#october-14-2026--image-generated-combat-rework-cleanup), [360 Pass — historical image retirement](asset-cleanup.md#october-14-2026--image-generated-combat-rework-cleanup), [360 details — historical image retirement](asset-cleanup.md#october-14-2026--image-generated-combat-rework-cleanup), [conflict — historical image retirement](asset-cleanup.md#october-14-2026--image-generated-combat-rework-cleanup), [unaffordable — historical image retirement](asset-cleanup.md#october-14-2026--image-generated-combat-rework-cleanup), [victory — historical image retirement](asset-cleanup.md#october-14-2026--image-generated-combat-rework-cleanup) and [defeat — historical image retirement](asset-cleanup.md#october-14-2026--image-generated-combat-rework-cleanup). The persistent forecast is an in-page component directly above Cast; intentional scrolling keeps typography and interaction targets usable on short screens. These are real Godot screenshots, not composited interface mockups.

Commands actually run from `C:\Dev\RuneCast` (sequential engine runs):

```powershell
.\tools\godot.ps1 -Action version
.\tools\godot.ps1 -Action import -LogDirectory output/qa/rc-016/final-checks
.\tools\godot.ps1 -Action test -LogDirectory output/qa/rc-016/implementation
.\tools\godot.ps1 -Action smoke -LogDirectory output/qa/rc-016/final-accepted
& '.\.tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe' --path . --script res://tests/ui_art_integration_capture.gd --log-file C:/Dev/RuneCast/output/qa/rc-016/runtime-accepted.log -- --capture-directory=res://output/qa/rc-016/runtime-accepted
& '.\.tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe' --path . --script res://tests/ui_undirected_capture.gd --log-file C:/Dev/RuneCast/output/qa/rc-016/touch-branch-final.log -- --capture-directory=res://output/qa/rc-016/touch-branch-final
.\tools\godot.ps1 -Action capture -CapturePath res://output/qa/rc-016/final-accepted/normal-desktop.png -LogDirectory output/qa/rc-016/final-accepted
& 'C:\Users\nguye\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' tools/validate_combat_art.py
& 'C:\Users\nguye\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' tools/validate_asset_plan.py --report output/qa/rc-016/asset-plan-validation.json
& 'C:\Users\nguye\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' output/qa/rc-016/audit-documents.py
```

Final GPU runs use OpenGL Compatibility on NVIDIA GeForce RTX 5070 Ti. Native viewport rendering and synthetic inputs are desktop checks, not phone measurements. Decoded RGBA8 estimates are **11.7823 MiB** for the runner's 33 sampled texture paths, **15.4073 MiB** for the full delivered icon/UI families plus crypt and neutral actor, **17.4073 MiB** with all three poses, or **19.4073 MiB** including the provisional 2 MiB future VFX allowance. Estimates exclude fonts, engine/driver/framebuffer/cache/transient overhead; no measured residency, device performance or new 32 MiB acceptance is claimed.

Intermediate logs/captures remain separate evidence. Initial sandboxed smoke exposed normal `user://` access limits and assertions for the replaced flattened labels; final runs used normal local access and asserted live child values. Render iteration fixed crypt z-order, label/pile wrapping, panel-skin inset geometry, compact card width, a repeated forecast-reason reorder that inflated page layout, offscreen keyboard focus and native Menu width. Intermediate failed result files are not final acceptance evidence. No source-art correction or regeneration was required. This task accidentally ran one initial read-only `git status --short` before reading the pasted prohibition and disclosed it immediately; **no subsequent Git operation or checkpoint occurred**.

The static neutral character keeps the established foot and `0.75 × W/841` scale, delivered crop and pose envelope. No player art, automatic motion study, dodge behavior or new event choreography is introduced. Shadeling remains one designated encounter's boss; release map placement/balance is unchanged. RC-017 owns outcome-driven animation, traversal, completion/cancellation and reduced motion. Inherited painted rights, owner aesthetic acceptance and physical Android/iOS usability/performance remain unresolved. No new audio, Store, map, save, progression, reward or Home flow, engine/SDK upgrade or mobile package is included. Historical entries below retain their original evidence and scope.

## October 13, 2026 — RC-016A undirected evaluator and control migration

**Complete for the gameplay migration gate. RC-016 is ready to proceed, not complete.** The [owner decision](decisions.md#october-13-2026--rc-016a-undirected-graph-and-controls-accepted) was recorded before dependent implementation. Split W/E/S and Join N/E/S have no port polarity; Begin–End flow determines their1→2/2→1 roles. Upstream Spark6 amplifies to12 across two branches; a shared downstream Spark6 contributes6 once. Each physical piece executes and pays once. Complete branch/rejoin loops are allowed; open powered ports, branches outside complete routes and conflicting edge directions reject deterministically. Historical directed profiles retain their own rules.

The owner replaced the proposed Menu ending with **Pass turn in the WIRING position**. It confirms the live unshielded enemy attack and cleanup before resolving, including incomplete circuits and empty hands. Remove/Rotate are the only production editing actions. Hold, separate card Info, I/right-click and forecast details preserve inspection; Escape/repeated selection clears. Board text is limited to BEGIN/END. Cards, pile/hand counts, energy, action log and the persistent in-page forecast bind live state; the forecast opens details and invalid/unaffordable Cast is disabled. RC-012 symbols and RC-013 cards/forecast are reused without changing their libraries.

| Check actually executed | Final result and evidence |
| --- | --- |
| Pinned Godot import and core/controller/content suites | Godot4.7.2 Standard, import successful; **1,453 checks,0 failures** in [test.log](../output/qa/rc-016a/final/test.log). [Import log](../output/qa/rc-016a/final/import.log) retains the pre-existing Android build-tools configuration warning. |
| Headless actual-scene UI regression | **594 UI checks,0 failures**, [smoke.log](../output/qa/rc-016a/final/smoke.log). Expected deliberately missing/invalid fixture diagnostics are test inputs, not unresolved startup failures. |
| Actual GPU-rendered scene/input checks | **119 checks,0 failures**, [results](../output/qa/rc-016a/final-ui/results.json) and [log](../output/qa/rc-016a/final/rendered-ui.log). OpenGL Compatibility, NVIDIA GeForce RTX5070Ti.18 named layout captures plus9 touch/detail captures cover native720×1600,450×1000 and360×640 viewports. |
| Established desktop launch/capture | Actual450×1000 window with the project's720-wide design scaling, [desktop capture](../output/qa/rc-016a/desktop-450x1000.png) and [capture log](../output/qa/rc-016a/desktop/capture.log). Native450/360 subviewports above separately test responsive layout. |
| Independent visual/code review | [Visual review](../output/qa/rc-016a/visual-review.json):14 actual images inspected,14 final hashes verified,0 issues. Final core/forecast/Pass review found no material blocker. Root also inspected actual board, hand, forecast, confirmation and desktop captures. |
| Historical contract preservation | All **22 fingerprints match**, [audit](../output/qa/rc-016a/fixture-fingerprint-audit.json), [final log](../output/qa/rc-016a/final/fixture-audit.log). Historical fixture values and reports were not converted. |
| Assets, references, data and prior evidence | [Preservation result](../output/qa/rc-016a/preservation-after.json):1,754 of1,755 baseline files byte-identical; the sole intended change is current production `data/board_examples.json`. Its exact prior file is retained as [RC-009 directed examples](../output/qa/rc-016a/rc009-board-examples-directed.json). All completed asset packs, approved references and protected historical QA remain unchanged. |
| Documentation, manifest and dependency audit | [Scoped audit](../output/qa/rc-016a/document-audit.json) passes:92 asset records,74 consumers, all60 original task IDs plus3 suffixed tasks; links/dependencies valid. The unchanged RC-010 asset-only validator correctly flags12 authorized gameplay/test/data edits under its historical no-code-change guard. Its [raw report](../output/qa/rc-016a/asset-plan-validation.json) retains that failure; the scoped audit checks the exact12 paths, rejects every other error and requires the separate preservation result. No old baseline is rewritten. |

The new [undirected suite](../tests/undirected_circuit_tests.gd) independently asserts reversed old input/output adjacency, all rotations, alternate Split/Join roles,12-vs6 amplification, unique charges, incomplete/dead/conflicting graphs, disconnected loops, deterministic invalid results and historical behavior. Actual Combat/controller cases cover Conjure, temporary Free Spark, permanent ownership/discard, affordability, preview/resolution payload agreement, delayed duplicate inputs, lethal/defeat outcomes and terminal immutability. The existing720 endpoint-pair/kit geometry cases now use rotations only. Updated UI tests exercise real synthetic touch/keyboard events, card Info without activation, I/right-click, selection clearing, Remove/refund/reinstall, Pass cancel/confirm, live counts/forecast, narrow scrolling and keyboard focus restoration after modal closure and hand rebuild.

Four command-built production examples migrate explicitly to `rc016a_board_examples_v1`: same IDs, seeds, natural draws and independently expected damage/shield/cost **6/0/2,6/5/3,6/0/2,12/5/2**. They remove obsolete Flip/Undo construction commands and update exact result ordering/`reached` metadata. They neither reroll hands nor guarantee normal opening solutions. The [board catalog](board-catalog.md) records replay sequences and historical evidence boundaries.

Reviewed final captures: [450 board and controls](../output/qa/rc-016a/final-ui/board-450x1000.png), [360 hand](../output/qa/rc-016a/final-ui/hand-360x640.png), [360 forecast](../output/qa/rc-016a/final-ui/forecast-360x640.png), [360 Pass confirmation](../output/qa/rc-016a/final-ui/pass-360x640.png), [360 unaffordable preview](../output/qa/rc-016a/final-ui/unaffordable-360x640.png), and [720 built top](../output/qa/rc-016a/final-ui/built-top-720x1600.png). Built captures use the reproducible Belfry witness; the unaffordable specimen deliberately sets QA energy1 without changing shipped data. At360 the page, hand and modal body scroll; modal action buttons stay accessible. The forecast is always present in the page above Cast, not fixed to the screen while scrolling. Active wire collars supplement color without arrowheads or labels. Review fixes included narrow navigation text, card Info gesture ownership and focus restoration. Earlier captures/logs in this task folder are intermediate evidence.

Reproduction commands, run separately: `tools/godot.ps1 -Action import`, `-Action test`, and `-Action smoke`, each with `-LogDirectory output/qa/rc-016a/final`; pinned Godot `--path . --script res://tests/ui_undirected_capture.gd --log-file C:/Dev/RuneCast/output/qa/rc-016a/final/rendered-ui.log`; pinned Godot `--path . --headless --script res://output/qa/rc-016a/fixture-audit.gd --log-file C:/Dev/RuneCast/output/qa/rc-016a/final/fixture-audit.log`; and `tools/godot.ps1 -Action capture -BoardExample board_belfry -CapturePath res://output/qa/rc-016a/desktop-450x1000.png -LogDirectory output/qa/rc-016a/desktop`. Test/smoke/capture runs are sequential. Existing source/import tools and cleanup guidance were consulted; no disposable art staging was required.

Baseline core passed1,363 checks. Initial sandboxed baseline smoke could not access normal `user://` preferences/temporary fixtures; rerunning with normal user-directory access passed564 UI checks. Final UI/render runs use that access. Intermediate implementation runs exposed a numeric historical-version comparison and a typed test-variable parse error; both were fixed before the clean final runs. This task accidentally ran one initial read-only `git status --short` before the pasted prohibition was read; it was disclosed immediately. **No subsequent Git operation or checkpoint was performed.**

The final document/manifest check runs with bundled Python: `output/qa/rc-016a/audit-documents.py`. It invokes the unchanged `tools/validate_asset_plan.py` with the task-specific report destination, checks all non-preservation findings and reconciles only this request's exact gameplay migration paths. An early documentation pass reported then-unwritten handoff anchors; the final pass resolves them.

These are automated desktop viewport/input checks, not a new human playtest, physical-device result or balance study. Full crypt/character/theme composition remains RC-016, and event-driven production animation remains RC-017. Shadeling remains one map encounter's boss; its retained hit pose is unchanged and no dodging is implemented. No map, Store, progression, rewards, new artwork, engine/SDK upgrade or mobile packaging was added. Painted rights and reconstructed-art approval limitations remain unchanged.

## October 13, 2026 — RC-015 shared crypt and separate Home illustration

**Pass for scoped asset production and isolated desktop verification.** [Crypt delivery](../source-assets/environments/crypt/delivery.md), [Home delivery](../source-assets/environments/home/delivery.md) and [preview overview](../output/art/rc-015/overview.png) provide the source, coordinate and usage contracts. Main gameplay and existing character/UI libraries were not modified.

| Evidence | Observed result |
| --- | --- |
| [Focused validator](../output/qa/rc-015/validation-report.json) |1,094 checks pass: two crypt/eight Home layers, ORA structure and exact recomposition, external layers/masks, exact source/export correspondence, dimensions/colour/alpha, painted overlap, crops/focal bounds, imports/staged identity, budgets and671 unchanged protected files |
| [Actual Godot run](../output/qa/rc-015/godot-render-results.json) |780 checks pass;40 PNGs rendered using Godot4.7.2 Standard, OpenGL Compatibility, NVIDIA GeForce RTX5070Ti.136 normal/reduced-motion samples retain texture-space union `[29,84,476,456)` |
| [Independent visual review](../output/qa/rc-015/visual-review.json) |23 actual renders,4 source images and3 references inspected with hashes; no final scoped blocker. Root additionally inspected source recomposition, lighting, narrow framing, attack/retained hit/defeat and Home specimens |
| [Manifest/plan audit](../output/qa/rc-015/asset-plan-validation.json) |92 stable records and74 consumer mappings retained; source/evidence paths and dependencies verified; five RC-015 rows reconciled |

Crypt source1682×1140 exports aligned841×570 background/floor, origin(0,0). Visible clean r006 paint is reused with newly painted hidden chamber coverage; no approved screenshot is sliced into production layers. Source coordinates are2× runtime. Default cropRect(0,60,841,450), uniformW/841, viewports720×385/450×241/360×193, foot(446,368) in crop coordinates and character texture scale0.75 before viewport scaling preserve RC-014. Overscan is0 horizontal/60 top/60 bottom. Art-onlyY0/Y120 stress crops prove opaque coverage, not alternate live layouts. Foreground is explicitly omitted. Exactly base cool, warm candle and dark presets share two textures and leave character/UI untinted.

Home source1440×3200 exports720×1600 opaqueRGB. Center-cover source rectangles are9:16 `(0,160,720,1280)`,9:20 full, and9:21.5 `(25.116279,0,669.767442,1600)`. All retain moon/tower. The old80px vertical tolerance is revised to160px for9:16. Six clean/composed Home captures use the unchanged RC-013 wordmark/theme and live controls. Editable semantic regions support repaint/recolour; hidden geometry for movable Home cutouts is not claimed.

Visual iteration fixed a compact crypt name/health overlap and a short-Home logo/tower-apex overlap. The final short Home deliberately partly covers the moon with the separate wordmark, following reference hierarchy; its clean crop keeps the whole painted moon. Feet, lantern and broad attack fit. Retained hit remains unchanged; no dodge behavior is added. Defeat includes the transparent endpoint. [Lighting/scale](../output/art/rc-015/lighting-and-scale.png), [motion](../output/art/rc-015/crypt-motion-contact.png) and overview are three derived sheets, with [source hashes/placements](../output/art/rc-015/contact-sheet-record.json), not extra engine renders.

ConservativeRGBA8 estimates: crypt3.6573MiB, Home4.3945MiB; Combat subtotal19.4073MiB includes three actor poses, full4.75MiB UI,6MiB glyphs and2MiB futureVFX allowance. Transition subtotal including Home/provisionalMap is27.7579MiB, below32/48MiB planning targets. These exclude fonts, engine/render buffers, caches and allocation overhead and are not device measurements.

Reproduction: `tools/preview_environments.ps1`, bundled Python `tools/validate_environments.py`, `tools/rc015_contact_sheets.py`, and `tools/validate_asset_plan.py --report output/qa/rc-015/asset-plan-validation.json`. Only the disposableRC-015 stage is recreated; only environment PNG import recipes are promoted. No unrelated gameplay suite was run. The engine log retains a host shader-cache-directory diagnostic, with no script/import/resource failures.

One initial read-only `git status --short` ran before the pasted prohibition was read and was disclosed immediately; no subsequent Git operation or checkpoint occurred. Model versions/seeds were not exposed; prompts/raw outputs are retained. Painted assets remain`source_ready` with unresolved inherited rights; original lighting code/settings are separately`runtime_ready`. Reference approval does not approve reconstructed assets. Physical-device acceptance, full responsive layout, gameplay binding and event-driven animation remain unverified and assigned downstream. **RC-016A is the next gameplay prerequisite before fullRC-016 acceptance.**

## October 13, 2026 — Project-wide unnecessary asset cleanup

At the owner's explicit whole-project request, removed2,685 exact audited files totaling150,959,491 bytes (143.97 MiB):227 superseded/duplicate previews,20 source raster intermediates,2,437 generated staging/cache files and one Python bytecode file. [Removal receipt](../output/qa/asset-cleanup-2026-10-13/deletion-manifest.json) records every path/hash/size/reason and documented replacements. No backup copies were kept. All authored masters, canonical layers, runtime assets, generation provenance, approved references, current previews and gameplay remain.

[Fresh post-cleanup checks](../output/qa/asset-cleanup-2026-10-13/validation.json) verify exact removals, retained hashes, source SVG dependencies and allowed documentation/tool updates. All403 guarded current assets/gameplay/reference/preview files remain byte-identical. [Current manifest checks](../output/qa/asset-cleanup-2026-10-13/asset-plan-validation.json) pass for92 assets and74 consumers. Before staging was removed, [UI evidence validation](../output/qa/asset-cleanup-2026-10-13/ui-retained-evidence-validation.json) passed1,813 checks and [Shadeling validation](../output/qa/asset-cleanup-2026-10-13/shadeling-retained-evidence-validation.json) passed359. These checked retained source/report/staging evidence, with no new Godot rendering or gameplay-suite run.

Current manifests and links now use the corrected Shadeling framing-360 set and menu-button-revert specimens; historical JSON/log/snapshot records remain unchanged and retired image links point to the cleanup receipt. Preview wrapper/source files and unique probe scripts remain. The [cleanup guide](asset-cleanup.md#october-13-2026--project-wide-follow-up-cleanup) documents restaging before focused validators or gallery use. No Git operation, runtime artwork change, source rebuild or gameplay change was performed. Prior task completion/rights/device limitations remain unchanged.

## October 12, 2026 — RC-014 proportional 360 preview correction

Corrected the 360 arena preview after the owner identified inconsistent framing. The previous360×280 specimen combined native actor coordinates with the main-composition background crop; its earlier visual framing acceptance is superseded. The corrected [360×193 preview](../output/art/rc-014/framing-360/arena-native-360.png) uses the same Rect(0,60,841,450) crop and uniform character/background mapping as [720](../output/art/rc-014/framing-360/arena-design-720.png) and [450](../output/art/rc-014/framing-360/arena-desktop-450.png). Live UI scales from the450-wide specimen to keep intent, BOSS, name and health separated. The legacy filename is retained; this is a proportional arena preview, not a full native-phone layout.

Fresh isolated Godot rendering and [focused source/import validation](../output/qa/rc-014/framing-360/validation-report.json) pass359 checks and194 scene behavior checks, plus136 full-pose and17 part-stress samples. [16 framing/preservation checks](../output/qa/rc-014/framing-360/framing-validation.json) verify actual scene transforms, rounded viewport proportions, metadata/builder agreement and output identity. Measured360 foot is(190.915573,157.526749), uniform scale0.321046382. Of102 PNG/GIF outputs,101 match the previous boss-follow-up outputs byte-for-byte; only the360 arena changed. [574 protected files](../output/qa/rc-014/framing-360/preservation-validation.json) remain unchanged, including source/runtime art, gameplay and earlier evidence. [Metadata/document checks](../output/qa/rc-014/framing-360/metadata-document-validation.json) pass. Root and independent reviewer inspected all three arena sizes: proportions and floor placement match, full body/lantern remain visible, and live labels do not overlap.

Commands: `tools/preview_shadeling.ps1 -QaDirectory output/qa/rc-014/framing-360 -ArtDirectory output/art/rc-014/framing-360`; bundled Python `tools/validate_shadeling.py --qa-dir output/qa/rc-014/framing-360 --art-dir output/art/rc-014/framing-360 --report output/qa/rc-014/framing-360/validation-report.json --package-gifs`. Production artwork, motion and runtime scene/API are unchanged; metadata and reproduction docs record the corrected preview mapping. No raster generation, source rebuild or Git operations. Host shader-cache/user-directory diagnostics remain; no script/import/resource failure. Physical-device acceptance and full Combat integration remain downstream. RC-014 stays complete; see the [corrected delivery](../source-assets/characters/shadeling/delivery.md#360-wide-framing-correction).

## October 12, 2026 — RC-014 boss and retained-pose follow-up

The later proportional360 correction above supersedes this review's acceptance of the360 framing; its role/pose decision, original test results and preserved outputs remain historical evidence.

**RC-014 remains complete; no artwork refinement was necessary.** Audited the existing pack against current contracts, approved Combat final-v2 and retained r006 composition. The owner explicitly keeps the dodge-looking hit pose. Corrected current role/roster/manifest wording and isolated scene metadata, documented possible RC-034 dodging with RC-017 outcome-presentation ownership, and added a live BOSS label to isolated arena previews. The four-state interface, source/export artwork, common anchor, r006 scale, stable IDs, fixture values and shared gameplay remain unchanged. Historical normal-role/no-BOSS and recoil-readability claims below and in original reports are explicitly superseded; their original evidence is preserved.

Freshly executed checks:

| Check | Result and fresh evidence |
| --- | --- |
| Focused source, export, import and evidence validator | **359 PASS**, [report](../output/qa/rc-014/followup-boss-dodge/validation-report.json). Actual layered masters, alpha/colour, anchors, retained input identity, imported texture settings/dimensions and staged identity checked. |
| Isolated Godot scene and motion | **194 behavior checks PASS**, [report](../output/qa/rc-014/followup-boss-dodge/godot-render-results.json).136 full-pose samples retain union[29,84,476,456);17 part samples retain[53,86,406,451). |
| Fresh visual review | Eight sheets and92 motion frames rendered, two GIFs packaged. All eight sheets inspected; [720](../output/art/rc-014/framing-360/arena-design-720.png), [450](../output/art/rc-014/framing-360/arena-desktop-450.png) and [native360 — retired during cleanup](asset-cleanup.md#october-13-2026--project-wide-follow-up-cleanup) retain complete character/lantern and readable live BOSS UI. Alpha edges and shoulder/neck underlaps remain sound in the tested envelope. [Audit](../output/qa/rc-014/followup-boss-dodge/audit.json) records reviewed image hashes;99 of102 PNG/GIF outputs are byte-identical to originals, with only the three arena images changed. |
| Preservation and metadata recipe | **462 protected files unchanged**, [SHA-256 report](../output/qa/rc-014/followup-boss-dodge/preservation-validation.json). This covers artwork/provenance, gameplay/fixtures, reference/pilot inputs and original RC-014 evidence. Assembly-script AST and role/feedback fields match metadata; the builder was not executed. |
| Documents and manifest | [Role-document checks](../output/qa/rc-014/followup-boss-dodge/role-document-validation.json) and [existing asset-plan validator](../output/qa/rc-014/followup-boss-dodge/asset-plan-validation.json) record current references, CSV structure and task/manifest consistency. |

Commands actually run: `tools/preview_shadeling.ps1 -QaDirectory output/qa/rc-014/followup-boss-dodge -ArtDirectory output/art/rc-014/followup-boss-dodge`; bundled Python `tools/validate_shadeling.py --qa-dir output/qa/rc-014/followup-boss-dodge --art-dir output/art/rc-014/followup-boss-dodge --report output/qa/rc-014/followup-boss-dodge/validation-report.json --package-gifs`; `tools/validate_asset_plan.py --report output/qa/rc-014/followup-boss-dodge/asset-plan-validation.json`. Original evidence destinations were not overwritten.

Fresh engine: pinned Godot4.7.2, OpenGL Compatibility, NVIDIA GeForce RTX5070Ti. Logs retain shader-cache/user-directory and root-certificate-store host diagnostics, with no script/import/resource failure. No raster generation, source rebuild, new animation state, shared gameplay changes, gameplay-suite rerun or Git operations. These are desktop-only arena specimens. Rights remain unresolved and general artwork approval/device acceptance are not inferred. RC-016/RC-017 own integration/sequencing, RC-025/RC-034 encounter/node/board/boss behavior, RC-036 route/economy/rewards and RC-024A permanent eligibility; possible dodging remains undecided behavior. See the [follow-up handoff](../source-assets/characters/shadeling/delivery.md#follow-up-audit--boss-role-and-retained-hit-pose).

## October 12, 2026 — RC-014 Shadeling character pack

Historical production evidence: the boss-role and retained-pose follow-up above supersedes this entry's no-BOSS context and earlier recoil-readability interpretation. Its original technical results, source work and outputs remain preserved.

**Complete for character production and isolated desktop verification.** [Delivery](../source-assets/characters/shadeling/delivery.md) supplies three genuine layered ORAs, three aligned512² poses, nine optional neutral parts, painted shoulder/neck repairs, generation/reuse provenance and the reusable [character scene](../assets/enemies/shadeling/character.tscn). The approved reference and retained r006 composition were inspected before production. No Git operation, main-game integration, gameplay change, engine upgrade or mobile packaging was performed.

| Check actually run | Result and evidence |
| --- | --- |
| Sources, exports and dependencies | **359 PASS**, [focused report](../output/qa/rc-014/validation-report.json): unique meaningful ORA layers, exact recomposition,1024² source/512² runtime canvases, sRGB/alpha, source→export identity, anchors, retained input hashes, imported dimensions/settings and staged texture identity. Neutral has9 layers, attack7, hit8. |
| Real Godot scene behavior | **194 PASS**, [Godot results](../output/qa/rc-014/godot-render-results.json): pose/state switching, deterministic sampling, stable foot, attachment updates, idle loop, one-shot completion, persistent defeat endpoint, reduced motion, lazy active texture and optional warm-cache behavior. |
| Actual rendered envelopes | **136 full-pose samples** cover normal/reduced idle/attack/hit/defeat, union[29,84,476,456). **17 part-stress samples** cover arm±4°, relative lantern±3°, hood±2°, union[53,86,406,451). Both stay within declared X24–488/Y32–480 all-alpha envelope. Significant attack alpha remains X32–474. No character shrink/canvas/anchor change was used to hide clipping. |
| Actual Godot visual review | Eight sheets plus46 normal and46 reduced-motion PNG frames. [Pose](../output/art/rc-014/framing-360/pose-sheet.png), [alpha](../output/art/rc-014/framing-360/alpha-backgrounds.png), [attachments](../output/art/rc-014/framing-360/anchor-envelope.png), [underlap stress](../output/art/rc-014/framing-360/part-underlap-stress.png), [motion comparison](../output/art/rc-014/framing-360/motion-comparison.png) and [visual record](../output/qa/rc-014/visual-review.json). Every runtime pose/part is shown on indigo, white/light gray, black, checkerboard and retained crypt. No background rectangle, dirty matte halo, clipped hood/lantern/feet or exposed seam remains in the tested range. |
| Actual-size composition | [720 design — retired during cleanup](asset-cleanup.md#october-13-2026--project-wide-follow-up-cleanup), [450 desktop — retired during cleanup](asset-cleanup.md#october-13-2026--project-wide-follow-up-cleanup), [360 native — retired during cleanup](asset-cleanup.md#october-13-2026--project-wide-follow-up-cleanup) arena-only crops retain painted crypt and live intent8/name/32HP overlays. No BOSS role or player art is introduced. The r006384² at(254,92) is correctly mapped from841×1870 composition space; the old0.46 scale/height ceiling is superseded in the production spec. |
| Preservation and manifest | [Asset-plan audit](../output/qa/rc-014/asset-plan-validation.json) and [217-file task preservation report](../output/qa/rc-014/preservation-validation.json) pass. Existing scripts, scenes, data, project/export settings, pilot sources and approved references remain unchanged. Only the owned Shadeling manifest/consumer delivery is promoted, with source_ready/reference_guided/unresolved rights. RC-017's shared animation asset is not marked delivered. |

Actual engine: pinned Godot4.7.2 Standard, OpenGL Compatibility on NVIDIA GeForce RTX5070Ti. [Import log](../output/qa/rc-014/godot-import.log) and [render log](../output/qa/rc-014/godot-render.log) have no missing-resource, script or import failure. The host emits shader-cache/user-directory and root-certificate-store diagnostics; those are retained, not suppressed. The render report confirms successful viewport outputs. No full gameplay suite rerun was necessary because shared gameplay files were unchanged.

The first stress render exposed shoulder/hood separation seams and a stranded chain fragment; source masks and painted underlaps were refined and rerendered. The wide attack's old lean was removed while that pose is active, keeping its footprint stable. Preview-only oversized intent glyph and health-bar clipping were corrected before final visual review. Root and independent reviewer inspected the final outputs. [Normal GIF](../output/art/rc-014/framing-360/motion.gif) and [reduced GIF](../output/art/rc-014/framing-360/reduced-motion.gif) are derived from actual Godot frames; PNG sequences and per-frame timing remain the authoritative motion evidence. GIF replay does not mean the scene automatically resurrects after defeat.

Decoded RGBA8 estimates are1MiB active full pose,3MiB warmed full poses,9MiB separate parts and12MiB deliberately retaining all. The default scene loads no part rig, and a pose swap may briefly overlap two textures. These are dimension-based estimates excluding engine/font/UI/environment buffers, not measured device memory.

Commands used: bundled Python `source-assets/characters/shadeling/build_pack.py`; `.\tools\preview_shadeling.ps1`; bundled Python `tools/validate_shadeling.py --package-gifs`; `tools/validate_asset_plan.py --report output/qa/rc-014/asset-plan-validation.json`. All previews run in the excluded separate staged project. The [runtime guide](../assets/enemies/shadeling/README.md) documents setup and named access.

Inherited generated-art rights remain unresolved, so successful technical imports do not qualify the pack for runtime_ready under the manifest's rights rule. Owner approval of the supplied reference does not approve these new poses. RC-016 binds the real arena and live overlays, RC-017 owns event timing/completion/cancellation/settings, and RC-016A retains its separate gameplay/control migration. Physical-device readability/performance, mobile memory and shipping rights remain unverified. **Next numbered task: RC-015, the layered crypt and separate Home tower illustration.**

## October 12, 2026 — Restore the previous menu buttons

The owner requested reverting the shared button-frame revision. Restored pointed turquoise Resume and navy Options, Store and Quit through the existing `action()` factory; the corrected `RCMenu`36px padding and centered title remain unchanged. The current appearance matches the [menu-padding baseline](../output/art/rc-013/menu-button-revert).

All six fresh [Godot renders](../output/qa/rc-013/menu-button-revert/godot-render-results.json) pass at720×1600,450×1000 and native360×640. They are SHA-256-identical to the corresponding menu-padding baselines in both Store states. [Revert validation](../output/qa/rc-013/menu-button-revert/validation.json) records33 content-bound checks with a minimum12px clearance beyond the painted border. Reproduction: `.\tools\preview_ui_theme.ps1 -EvidenceName menu-button-revert -MenuOnly`. Earlier evidence remains preserved. This revision does not integrate the theme into the main game. No Git operations were performed.

## October 12, 2026 — Shared menu button frame (superseded)

This historical revision applied the owner's request for consistent button borders to Resume, Options, Store and Quit. All four shared the existing secondary texture and identical slice geometry through a dedicated helper. Resume's turquoise face used a small shader preserving the warm gold frame, alpha and state modulation; production bitmap sources remained unchanged. The subsequent owner-requested revert removed that helper and shader and restored the previous button design.

All [six Godot renders](../output/qa/rc-013/menu-shared-frame/godot-render-results.json) pass text/input and33 border-clearance checks at720×1600,450×1000 and native360×640. Independent visual review confirms matching corners, rim weight and dimensions in both Store states, with the centered title and Quit still clear of the menu frame. [Correction validation](../output/qa/rc-013/menu-shared-frame/validation.json) records preservation and staged-source checks; [asset-plan validation](../output/qa/rc-013/menu-shared-frame/asset-plan-validation.json) passes.

The evidence destination `menu-shared-frame` is retained for historical review; running the current preview source produces the restored button design. This was isolated theme work; main-game integration and physical-device verification remain pending. No Git operations were performed.

## October 12, 2026 — Menu border clearance correction

Fixed the owner's reported MENU/Quit overlap with a reusable `RCMenu` StyleBox:36px content padding around24px painted caps, plus a centered live title. The prior20px inset encroached on the bevel. Store remains separate from shop-room navigation.

All [six Godot renders](../output/qa/rc-013/menu-padding/godot-render-results.json) pass at720×1600,450×1000 and native360×640, covering normal and unavailable Store. All33 content-bound checks have at least12px clearance beyond the bezel; whole-panel viewport containment, existing text/input checks and independent visual review of every image pass. The original outer-rectangle checks missed painted-border overlap, so their earlier PASS does not establish sufficient interior padding. See the [corrected native menu](../output/art/rc-013/menu-button-revert/menu-open-360x640.png).

Reproduction: `.\tools\preview_ui_theme.ps1 -EvidenceName menu-padding -MenuOnly`. [Correction validation](../output/qa/rc-013/menu-padding/validation.json) verifies exact staged-resource identity and all34 original render hashes; [asset-plan validation](../output/qa/rc-013/menu-padding/asset-plan-validation.json) also passes. Prior evidence is preserved in place. No main-game integration, gameplay changes, physical-device acceptance or Git operations are part of this correction.

## October 12, 2026 — Menu Store clarification

The owner clarified that the Menu entry is a separate **Store** for in-game items, while entering a shop room opens that room as the main screen. Updated the isolated Menu's live label and removed its shop-room-only explanation; no gameplay or transaction implementation changed. Permanent rune acquisition from map conquest or hard-boss victories is recorded as intended progression with design/implementation gates in the project plan.

The [six new Godot renders](../output/qa/rc-013/store-clarification/godot-render-results.json) pass layout/input checks at720×1600,450×1000 and native360×640. Normal Store and a generic unavailable visual example remain separate; the latter does not define eligibility, payments or connectivity. [Correction validation](../output/qa/rc-013/store-clarification/validation.json) confirms all34 original RC-013 renders remain byte-identical. [Asset-plan validation](../output/qa/rc-013/store-clarification/asset-plan-validation.json) passes92 assets,74 consumer records and63 acyclic task definitions. Approved reference images, production artwork, main gameplay and prior QA reports are unchanged. No Git operations were performed for this correction.

Reproduction: `.\tools\preview_ui_theme.ps1 -EvidenceName store-clarification -MenuOnly`. The new evidence destination preserves the original RC-013 delivery records and skips import-recipe promotion for this live-text-only correction.

**October 11 authorized art cleanup:** Current pilot sources/appearance, all six approved references and runtime/QA files are retained. Unused art and old preview files are deliberately removed through [the exact cleanup ledger](../output/art/rc-011/cleanup/deletion-manifest.json). Original baselines remain unchanged; current checks partition retained, retired and explicitly updated source metadata instead of claiming every old art file still exists. [Cleanup details](asset-cleanup.md).

**Latest reference approval:** The owner explicitly selected [final gameplay v2](../output/imagegen/approved/combat-final-v2-clean-board.png). [r005 adoption](../source-assets/pilot/revisions/r005/delivery.md) preserves the exact841×1870attachment, pixel-identical to the retained v10study but with distinct PNG bytes. Only Begin/End labels remain on the board; values/costs/TEMP are absent; Split/Join use the corrected fork/trident. Card/toolbar/pile/forecast data remain. [Reference preservation checks](../output/art/rc-011/r005/reference-validation.json) and [asset-plan checks](../output/art/rc-011/r005/asset-plan-validation.json) record this adoption. No new image generation, pilot rebuild, runtime change or Git operation is implied by this approval.

**Latest art verification:** [RC-011 r006 final-v2 pilot](../source-assets/pilot/revisions/r006/delivery.md), [artifact/source audit](../output/art/rc-011/r006/revision-validation.json), [asset-plan audit](../output/art/rc-011/r006/asset-plan-validation.json) and [independent visual review](../source-assets/pilot/revisions/r006/cross-screen-review.md). These cover the latest clean-board and corrected-symbol changes in actual editable sources and rendered previews, not Godot integration or owner/device acceptance. Historical runtime results below retain their original dates.

Verified on October 7, 2026 using Windows x64 and Godot 4.7.2.stable.official.ed1daf0bf.

## Results

| Check | Result |
| --- | --- |
| Portable editor download | Official GitHub release, SHA-512 matched official checksum file |
| Godot project import | Completed; scripts and SVG icon imported |
| Circuit and combat checks | 23 checks passed, zero failures |
| UI smoke checks | 11 checks passed, zero failures |
| Rendered runtime capture | Saved successfully and visually inspected |
| Visual reference preservation | All five reference versions and their generation prompts retained |
| Local version control | Initialized, no commits or remotes created |

## What the checks cover

Circuit evaluation verifies the reference doubling circuit, unfinished branches, a misoriented Join, disconnected effects, amplified shielding, directed-loop detection, energy limits, and immutable endpoints.

Combat checks verify casting, enemy retaliation, lethal damage preventing retaliation, temporary-rune expiry, persistent ordinary effects, three-card turn draws, techniques, defeat, finite special-piece inventory, and undo.

UI checks instantiate the main scene and exercise rune placement, Cast, branch removal, Undo, Menu, Map, Guide, persistent sound preference, and Restart through their callbacks. These are desktop/headless integration checks, not physical touchscreen tests.

The October 7 runtime image is preserved as [foundation-screen-2026-10-07.png](../output/qa/foundation-screen-2026-10-07.png) (archived during RC-001 before refreshing the capture). The enemy, environment, and interface are editable placeholders rather than finished artwork.

## Known setup limitations

The Android exporter reports that its build-tools directory is not configured. Android SDK/JDK and export templates were not installed in this foundation task. The preset exists, but no APK or AAB has been built.

The iOS preset has a placeholder identifier and no signing team. No Mac/Xcode export or iPhone/iPad testing has occurred.

A first sandboxed editor launch could not write normal Godot user-data/cache locations. Final checks were run with normal local access and completed; the remaining import message concerns the missing Android build tools.

## Product limitations

Only the training encounter is playable. Map navigation, encounter rewards, between-encounter saves, shops, relics, and final art/audio are not implemented. The prototype uses one combined damage event and a fixed intent sequence. Touch-device safe areas and rune inspection need device verification.

## October 8, 2026 — RC-001 development baseline

These checks were executed during RC-001 on Windows x64 / PowerShell. The October 7 record above is historical evidence, not a substitute for this run. The existing pinned engine at `.tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe` was used; `GODOT_BIN` was unset. No download, upgrade, or mobile SDK installation was needed. The previous archive checksum verification was not rerun.

| Command / attempt | Exit code | Actual result |
| --- | --- | --- |
| `.\tools\godot.ps1 -Action version` | 0 | `4.7.2.stable.official.ed1daf0bf` |
| `.\tools\godot.ps1 -Action import` — initial sandbox attempt | 0 | Import ran, but the object database profiler reported `Could not open 'user://' directory`. This attempt was not accepted as a clean import despite exit 0. |
| `.\tools\godot.ps1 -Action import` — normal local access | 0 | Import completed without the user-data error or script/import errors. Android build-tools warning remained, recorded separately below. |
| `.\tools\godot.ps1 -Action test` | 0 | **23 checks, 0 failures** |
| `.\tools\godot.ps1 -Action smoke` — normal local access | 0 | **11 UI checks, 0 failures**, including sound persistence and restoration |
| `.\tools\godot.ps1 -Action capture` — normal local access | 0 | `Screenshot saved: OK`; new desktop image visually inspected |

Each action was executed separately and its output inspected. Normal local access resolved the sandbox's restriction on Godot's standard user-data directory; no game/tooling change was necessary. UI smoke needed that directory to exercise saving/restoring the sound preference. Local logs are in `output/qa/import-sandbox-attempt.log`, `import.log`, `test.log`, `smoke.log`, and `capture.log`; logs are intentionally ignored.

### Capture evidence

The fresh [foundation-screen.png](../output/qa/foundation-screen.png) is 450 by 1000 pixels (72,418 bytes), written October 8, 2026 at **01:23:51 AEDT** (October 7 at 14:23:51 UTC). The capture used OpenGL 3.3 Compatibility on NVIDIA GeForce RTX 5070 Ti, driver 610.88. The successful capture output and updated file timestamp establish freshness. Its SHA-256 is `17f12203709ab5df2d6dc39900f5464ddac96369b3d328c5d6bd563176f13de2`, identical to the preserved earlier capture because the starting screen did not change.

Visual inspection found the full enemy and intent, enemy/player statistics, complete 4 by 4 board, wiring/editing controls, three rune cards, Cast with energy cost, and Menu/Map/Guide/Sound controls visible. No obvious clipping, missing controls, or missing placeholder assets appeared at this desktop size. This does not establish mobile touch/safe-area acceptance or production-art readiness.

### Repository and checkpoint review

- Initial Git state: unborn `master`, no history, no tracked/staged files, existing project untracked, and no configured remotes. No applicable `AGENTS.md` was found in the repository or its ancestor directories.
- Reviewed source, scenes, data, documentation, tooling and export settings. The large candidate files are intentional reference PNGs (roughly 1.75–2.66 MB each). Engine binaries/archive/settings/cache, `.godot/`, `.local/`, builds, and logs stay ignored. No unexpected binary or embedded signing secret was found among candidate files.
- Retain all seven `.gd.uid` files, the SVG import settings, runtime assets, all 14 reference PNGs (including the four approved images), and all 10 generation prompts. Approved-image SHA-256 values are recorded below for preservation checks.
- `.gitignore` now excludes additional signing formats (`.pfx`, `.p8`, `.provisionprofile`) and general QA output while retaining the two reviewed baseline PNGs as explicit evidence. Existing keystore/JKS/P12/mobileprovision and export-credential exclusions remain.
- Added [the separate-chat workflow](development-workflow.md) and README link. Corrected the plan's current-reference summary. Broader visual-plan synchronization remains a documented follow-up, including RC-011's older v5 wording.
- Staged and reviewed **70 files**, including the existing project and RC-001 deliverables. The index write initially encountered sandbox permission denial; staging succeeded with normal local access. No non-ignored untracked files remain. Ignore probes confirm cache/tool/build/log/credential exclusions and both intentional capture exceptions; all relative file links in the four edited Markdown files resolve. Approved-image hashes match their pre-edit values.
- The final status check found `project.godot` modified after staging, at **01:29:19 AEDT**, outside RC-001 edits. Its engine-style rewrite changes comments/spacing and removes explicit `window/stretch/aspect`, `textures/default_filters/use_nearest_mipmap_filter`, and `pointing/emulate_mouse_from_touch` entries. Preserve this change unstaged; the tested original configuration remains in the index. The checks and capture above predate this rewrite and do not validate the modified working copy. Review it and rerun affected checks if including it in the eventual checkpoint.
- `git diff --cached --check` returns native Git exit **2** with **28 existing blank-at-EOF warnings only** in the initial project files (the first PowerShell invocation reported process exit 1). These formatting-only warnings are retained to avoid unrelated source cleanup. `git -c core.whitespace=-blank-at-eof diff --cached --check` exits 0; this command-local diagnostic does not change Git configuration or conceal any other whitespace category.
- **Checkpoint pending:** configured email is present, but no Git author name is configured. The owner elected to configure Git after this task; no identity was invented or configuration changed. Intended commit subject: `chore: establish Rune Cast development baseline`. RC-001 remains **partial**, with its task checkbox open until the commit exists and its revision/status are verified.

| Approved file | SHA-256 |
| --- | --- |
| `output/imagegen/approved/home.png` | `5dcac9f327f25de8350c193ad0618530e12c041ec4c42ce97ce703c99ff71fc6` |
| `output/imagegen/approved/combat.png` | `d5fa939150e3953cf1a5e5d3943203d2af4839f191b5ee81533fa8b04d223841` |
| `output/imagegen/approved/map.png` | `58ec4b54b152b383d2b6afd165739d04da8c67108e35f4c5985b23d0f2a9f6e4` |
| `output/imagegen/approved/menu.png` | `d37c1a5ca8c1ccd5ed9066f559ccabc5f599133a2256d5d5b10bfd263c824d6a` |

### Remaining limitations and next tasks

The accepted import still reports `Unable to open Android 'build-tools' directory.` This is an Android export-configuration warning, separate from desktop verification; it did not prevent desktop checks or rendering. Android SDK/JDK/templates, Android packaging, iOS signing/Mac/Xcode work, and physical-device testing were outside RC-001 and remain unverified. No APK, AAB, or IPA was produced.

No gameplay, balance, or artwork changes were needed. The product limitations in the October 7 record still apply. After the owner configures Git identity and the reviewed local checkpoint is created and verified, RC-001 can be completed; **RC-002 and RC-003** are the next dependency-ready tasks.

## October 8, 2026 — RC-001 checkpoint reconciliation during RC-002

The owner confirms RC-001 is complete. Read-only inspection verified starting revision `64930fcb05fb54e1711e084e59214eb33a2d53c0` (`Initial commit`), a clean `master` tracking `origin/master`, 70 committed baseline files, and a resolvable configured Git author identity. The checkpoint includes the workflow, previous verification records, source/data, approved references and both tracked runtime captures. The historical partial record above is preserved; its missing-identity/checkpoint prerequisite has been resolved.

The existing `import.log`, `test.log`, `smoke.log` and `capture.log` were read: import reports the same missing Android build-tools directory; core output reports 23 checks/0 failures; UI output reports 11 checks/0 failures; capture reports `Screenshot saved: OK`. Both tracked captures hash to `17f12203709ab5df2d6dc39900f5464ddac96369b3d328c5d6bd563176f13de2`, matching the original record. The four approved-image hashes also match the table above, and all four references were visually inspected for RC-002.

The committed `project.godot` includes the editor rewrite previously observed after the October 8 checks. Those earlier results do not verify that rewritten configuration. RC-002 neither changes it nor repeats completed baseline work; the next runtime task must run relevant checks against its actual starting configuration. This reconciliation records a restorable checkpoint and owner-confirmed completion, not fresh runtime or device acceptance.

## October 8, 2026 — RC-002 documentation validation

Starting revision: `64930fcb05fb54e1711e084e59214eb33a2d53c0`. Task branch: `codex/rc-002-v1-design-roster`. Checkpoint subject: `docs: define Rune Cast v1 scope and content roster`; its hash is reported in the chat handoff rather than embedded in the commit itself.

| Check actually performed | Result and limit |
| --- | --- |
| Source and reference review | Read required documentation/data, inspected relevant core/UI behavior and all four approved images. Current rules remain distinct from proposed features. |
| Native PowerShell roster-table validation | **52 unique content IDs**; every entry has six populated fields including implementation/rule dependencies and task ownership. Totals: 12 permanent, 1 generated, 5 enemies, 4 boards, 6 relics, 4 events, 6 room types, 6 services, 8 upgrades. |
| Existing ID and upgrade references | All five IDs from `data/runes.json` retain their permanent/generated classification; `training_shadeling` is preserved. All eight upgrade targets refer to permanent definitions. |
| Board witness validation | All four listed paths stay within 4 by 4 bounds, never repeat cells, use orthogonal steps, leave Begin eastward and enter End from north. These are geometric witnesses, not claims of final combat balance or implemented configurable boards. |
| Markdown file and anchor validation | All local links across README and the twelve Markdown files in `docs/` resolve, including the new specification/roster and experiment/economy anchors. |
| Task graph validation | All **60 task IDs** remain unique; referenced tasks exist; dependency ranges expand correctly; depth-first cycle check passes. All 60 dependency cells match the starting plan, so no prerequisite edges changed. |
| Cross-document review | Counts, starter ownership, six open experiments, four-screen states, save/terminal policy, asset owners and external prerequisites agree. The default shop follows Gold-producing fights; 75/90 base Gold makes the scoped individual services reachable. Relic acquisition remains useful before recovery/guardian. Values are proposals for later human tuning. |
| Preservation | Four approved SHA-256 values match the RC-001 table. `git diff --exit-code 64930fc -- data scripts scenes assets project.godot export_presets.cfg output/imagegen docs/gameplay-rules.md tools tests output/qa` passed. Gameplay rules, runtime, data, assets, tooling, tests and existing QA evidence are unchanged. |
| Change review | Only README and task documentation are included; the inventory change corrects Shadeling's role without expanding the manifest. Working and staged whitespace checks pass. Staged names/stat/full diff were reviewed before the authorized local checkpoint. |

No Godot command, gameplay implementation, production asset generation, mobile setup, account configuration, push or PR was performed. RC-002 is a documentation-only task; the earlier runtime evidence and its configuration limitation remain as recorded above. Detailed production specifications/manifest expansion remain RC-010, experiments RC-005/RC-006, and device/human acceptance remain their later tasks.

## October 8, 2026 — RC-003 combat/presentation separation

Starting revision: `b373a8c` (`docs: define Rune Cast v1 scope and content roster`), clean `codex/rc-002-v1-design-roster`. Created `codex/rc-003-combat-presentation` from that revision, preserving RC-002. No applicable `AGENTS.md` was found in the repository or ancestor directories. The branch write needed normal local access because `.git` is read-only in the sandbox. The authorized checkpoint subject is `refactor: separate combat resolution from presentation`; its resulting hash is reported in the chat handoff.

### Fresh baseline before editing

The actual committed `project.godot`, including the editor rewrite discussed in RC-001/RC-002, was verified afresh. The pinned engine was already installed; no engine upgrade/download or mobile prerequisite installation occurred.

| Command / attempt | Exit | Observed result |
| --- | --- | --- |
| `.\tools\godot.ps1 -Action version` | 0 | `4.7.2.stable.official.ed1daf0bf` |
| `.\tools\godot.ps1 -Action import` — sandbox | 0 | `Could not open 'user://' directory` from the object database profiler; not accepted as clean despite exit 0. Existing Android build-tools warning also present. |
| `.\tools\godot.ps1 -Action import` — normal local access | 0 | Import completed without script/user-data errors; only existing Android warning remained. |
| `.\tools\godot.ps1 -Action test` | 0 | **23 checks, 0 failures** |
| `.\tools\godot.ps1 -Action smoke` — normal local access | 0 | **11 UI checks, 0 failures**; sound preference restored |
| `.\tools\godot.ps1 -Action capture` — normal local access | 0 | `Screenshot saved: OK`; inspected before refactoring |

Baseline logs are retained locally as `output/qa/rc-003-before-*.log`, including `rc-003-before-import-sandbox.log`. The sandbox directory error is an environment restriction, not a game regression. The successful import/test/smoke/capture resolves the prior configuration-verification gap for desktop behavior.

### Final verification after implementation

All five required commands were executed separately and their exit codes and output inspected. No runtime source changed after this accepted sequence; subsequent edits record documentation/evidence.

| Command | Exit | Observed result |
| --- | --- | --- |
| `.\tools\godot.ps1 -Action version` | 0 | `4.7.2.stable.official.ed1daf0bf` |
| `.\tools\godot.ps1 -Action import` — normal local access | 0 | Scripts imported successfully, including new `.gd.uid` companions; existing Android warning only |
| `.\tools\godot.ps1 -Action test` | 0 | **75 checks, 0 failures**: original 23 plus 52 event/controller/ownership/RNG checks |
| `.\tools\godot.ps1 -Action smoke` — normal local access | 0 | **32 UI checks, 0 failures**: original 11 plus 21 presentation/view checks; sound preference restored |
| `.\tools\godot.ps1 -Action capture` — normal local access | 0 | `Screenshot saved: OK`; fresh image inspected and compared |

Final logs are retained locally as `output/qa/rc-003-after-*.log` and the standard command logs. The initial expanded test compile attempt exposed a test-only inferred-Variant warning treated as an error; it was stopped, explicitly typed and rerun successfully. Independent read-only review also found selection help hiding inventory errors and cancellation reentering teardown; both were corrected and have focused regression coverage. Final outputs contain no script errors or leaked-object reports.

Additional preservation evidence: a local differential harness loaded `combat.gd` from `b373a8c` beside the refactored model and ran **720 deterministic command steps across seeds 0, 42 and 1234, 0 mismatches**, exit 0. It compared return values, board, hand, piles, history, health, energy, turn/state/log, next UID and RNG state after every step, including resets and invalid commands. An initial relative log-path attempt reported a user-directory error; rerunning with the absolute workspace log path produced clean output. The harness/baseline copy and `rc-003-differential.log` are ignored local evidence, not shipped runtime or a second maintained rules implementation. Four golden draw-order checks from that baseline are integrated into the regular core suite, including Reset continuing the RNG stream.

New checks cover ordered nonlethal/lethal/shielded/defeat/Pass outcomes, actual versus clamped damage, board/hand temporary expiry, cleanup/refresh/draw ordering, Conjure and Focus (including recycling Focus itself), invalid/unaffordable/missing/terminal actions, prior-result stability, consumer mutations and replay. Controlled completion tests cover every gameplay mutation during a pending action, signal reentry, duplicate/stale callbacks, Restart, cancellation, disposal during cancellation, callback owner lifetime and actual scene teardown. UI checks retain editing/navigation/audio behavior and verify local selection help, inventory errors, disabled controls and direct handler guards. Delayed-presentation assertions do not depend on timers or sleeps.

### Visual evidence

Both 450 by 1000 captures are intentionally checkpointed. Rendering used OpenGL 3.3 Compatibility on NVIDIA GeForce RTX 5070 Ti, driver 610.88.

| Capture | Fresh write time, Sydney (AEDT) | UTC | Size |
| --- | --- | --- | --- |
| [Before refactor](../output/qa/rc-003-before.png) | October 8, 2026, **22:20:20** | October 8, 11:20:20 | 72,418 bytes |
| [After refactor](../output/qa/rc-003-after.png) | October 8, 2026, **22:33:14** | October 8, 11:33:14 | 72,418 bytes |

Both SHA-256 hashes are `17f12203709ab5df2d6dc39900f5464ddac96369b3d328c5d6bd563176f13de2`, identical to the refreshed [foundation screen](../output/qa/foundation-screen.png). Fresh capture output and modification times establish that both were newly rendered despite identical bytes. Visual inspection confirmed the title, full enemy/intent/health, player stats, complete 4 by 4 board, wiring/editing controls, three rune cards, status text, Cast/cost and Menu/Map/Guide/Sound remain visible and consistent, with no observed clipping or missing controls at this desktop size.

### Review, scope and limitations

The [architecture contract](combat-presentation.md) documents responsibilities, command/result/event data, detached ownership, exact resolution order, completion/cancellation and RC-017 integration. Source changes are confined to combat outcomes, the controller/adapter boundary, view command routing and focused tests. Scene structure, circuit rules, JSON content, `project.godot`, export presets, audio implementation and approved artwork remain unchanged. README links the contract; the workflow and ignore exceptions preserve both comparison PNGs. Reviewed all **22 staged files**, names/stat/full diffs, generated UIDs and intentional PNG sizes; `git diff --cached --check` passed. All **79 local documentation links** in the edited Markdown files resolve. Preservation diffs against `b373a8c` are empty for scene/configuration/circuit/content/artwork, existing rules/design/roster/decisions and tooling. No unrelated files are staged; final commit/status are reported in the handoff.

The existing import message `Unable to open Android 'build-tools' directory.` is an Android export-configuration warning, separate from desktop success. No SDK/JDK/templates were installed, no mobile package was produced, and no physical-device or production-animation acceptance is claimed. Current UI, Menu and Map remain placeholders; future schemas, experiments, touch changes, production animation and run/save/reward systems remain outside RC-003. No push, remote change, PR or history rewrite occurred.


## October 8, 2026 — RC-004 validated content and configurable setup

RC-004 is complete. The owner explicitly prohibited **all Git operations**, including read-only inspection. None were performed; no revision, branch or checkpoint is asserted for this task. A commit is not an acceptance requirement under that instruction. No applicable `AGENTS.md` was found in the repository or ancestor directories. Required design, workflow, rules, RC-003 handoff and runtime/test files were reviewed before implementation.

### Fresh baseline and environment

The existing pinned `4.7.2.stable.official.ed1daf0bf` installation was used without downloads or upgrades. Before changing behavior, import, core and UI checks ran separately:

| Command / attempt | Exit | Actual result |
| --- | --- | --- |
| `-Action import`, sandbox | 0 | `Could not open 'user://' directory` in the object database profiler; not accepted as clean. Existing Android build-tools warning also present. |
| `-Action import`, normal local access | 0 | Import completed; existing Android build-tools warning only. |
| `-Action test` | 0 | **75 checks, 0 failures**. |
| `-Action smoke`, normal local access | 0 | **32 UI checks, 0 failures**; sound preference restored. |

Baseline logs remain locally as `output/qa/rc-004-before-{import-sandbox,import,test,smoke}.log`. The sandbox directory failure matches the prior environmental limitation and was resolved by normal local access, without changing project behavior.

### Final verification

The required actions were executed separately and their output and exit status inspected. The version/import/test/smoke/default-capture sequence was followed by the documented alternate-scene capture. No runtime edits followed the accepted sequence; later edits record documentation and evidence.

| Command | Exit | Actual result |
| --- | --- | --- |
| `.\tools\godot.ps1 -Action version` | 0 | `4.7.2.stable.official.ed1daf0bf`. |
| `.\tools\godot.ps1 -Action import` | 0 | Clean desktop script import; existing Android build-tools warning only. |
| `.\tools\godot.ps1 -Action test` | 0 | **204 checks, 0 failures**: 75 retained core/controller checks, 90 loader checks, 39 configured-combat checks. |
| `.\tools\godot.ps1 -Action smoke` | 0 | **62 UI checks, 0 failures**: 32 retained checks plus 30 configuration checks. |
| `.\tools\godot.ps1 -Action capture` | 0 | `Screenshot saved: OK`; default screen inspected. |
| `.\tools\godot.ps1 -Action capture -Encounter 'res://data/dev_encounter.json' -CapturePath 'res://output/qa/rc-004-development.png'` | 0 | `Screenshot saved: OK`; actual alternate scene inspected. |
| `.\tools\godot.ps1 -Action capture -Encounter 'res://data/missing.json' -CapturePath 'res://output/qa/rc-004-invalid.png'` | **1, expected** | Missing-file diagnostic, `Screenshot saved: OK`, visibly disabled configuration-error screen. Negative capture completed before final sequence; failure handling was unchanged afterward. |

UI smoke intentionally prints two `Cannot start encounter` diagnostics: the absent fixture file and the targeted `invalid_ui.enemy_id` reference. They are asserted negative-test outcomes, not script failures. Final accepted runs report no script errors or leaked objects. Standard logs and `rc-004-after-{import,test,smoke}.log`, `rc-004-{training,development,invalid}-capture.log` are retained locally, not as shipped artifacts.

Focused development runs exposed incompatible-Variant comparisons while validating deliberately wrong types; validation now checks types before comparisons and includes six extra wrong-type regressions. The first loader-only probe omitted an absolute log path and reported the known `user://logs` environment restriction; subsequent probes used an explicit workspace log and passed cleanly. An earlier integrated run passed 198 checks before those six cases were added; **204** is the final count. Review also corrected the training title and adopted the roster's `board_training` ID before final acceptance.

Coverage includes required/optional fields, root/field types, numeric fractions/strings/booleans/nonfinite values, bounded health/energy/draw/inventory, unique IDs and references, unsupported effects and generated targets, malformed board geometry versus valid incomplete circuits, opening ownership and installed stock. Combat checks cover both configurations, unique UIDs, conservation through edits/undo/turns, generated-card exclusion, configured effect values/targets, fresh seed reproducibility, existing golden training shuffle/reset continuation, selected-setup Restart and detached input/state/snapshots/results. Retained RC-003 checks continue to prove ordered events, duplicate-input guards, cancellation reentry, stale callbacks and teardown. Actual scene tests cover alternate labels, tooltips, help, cast/undo/restart and every direct gameplay callback after invalid startup.

### Visual evidence

All three 450 by 1000 images were visually inspected. Rendering used OpenGL 3.3 Compatibility on NVIDIA GeForce RTX 5070 Ti, driver 610.88. These PNGs have explicit retention exceptions in the capture policy; other local QA output remains ignored.

| Capture | Fresh write time, Sydney (AEDT) | UTC | Bytes |
| --- | --- | --- | --- |
| [Training](../output/qa/rc-004-training.png) | October 8, 23:16:51 | October 8, 12:16:51 | 72,418 |
| [Development fixture](../output/qa/rc-004-development.png) | October 8, 23:17:14 | October 8, 12:17:14 | 71,458 |
| [Invalid configuration](../output/qa/rc-004-invalid.png) | October 8, 23:13:28 | October 8, 12:13:28 | 62,547 |

Training SHA-256 is `17f12203709ab5df2d6dc39900f5464ddac96369b3d328c5d6bd563176f13de2`, identical to RC-003 and the refreshed `foundation-screen.png`. Its title, Shadeling/32 HP/attack 8, player 30/30 and energy 3/3, original board, three cards, stock, Cast and navigation remain visible without clipping. The first cast is still 12 damage for one energy, leaving enemy 20 HP and player 22 HP.

The alternate image visibly shows DEVELOPMENT FIXTURE, CALIBRATION WISP, 45/45 HP and attack 3, player 24/40, energy 4/4, Split 2/2 and Join 0/0, Focus/Shield hand, installed Spark, different path and a two-energy Cast. Labels and all controls fit the preserved layout. Its SHA-256 is `b97e5d49114f5d057db080b527c9883a5fdcf05429a8bc6a23366948165ea4be`. UI tests additionally verify draw-two help, the selected enemy's tooltip and contextual Menu/Map/Guide text.

The invalid capture shows CONTENT ERROR, the missing path/reason and visibly disabled board/edit/Cast controls. No hand or playable fallback is created; UI tests also verify disabled Pass/Restart and safe direct callbacks. Its SHA-256 is `558ca43cb1aef9b172e7572cf513f27de30d9fe27e9367b02e49e57f3faad0b1`.

The four approved-reference hashes still match the RC-001 table. No approved reference or production asset was changed or generated. Existing scene geometry, renderer/project settings and circuit rules remain in place; the gameplay-rules text only clarifies configurable training defaults, leaving future mechanics undecided. Documentation file-link validation checked **142 local links, zero broken targets**. All runtime/test GDScript files have their `.gd.uid` companions.

### Limits and handoff

The existing `Unable to open Android 'build-tools' directory.` warning concerns Android export configuration and is separate from desktop success. No engine upgrade, mobile SDK installation, mobile packaging or physical-device acceptance is claimed. The alternate fixture is deliberately development/test content using the shared placeholder artwork, not balanced production roster expansion. Alternate endpoints, obstacles, ports, mixed effects, relics, statuses, guardian phases, run/save/reward systems and production animation/audio remain outside this task. See [content definitions](content-definitions.md), [combat presentation](combat-presentation.md) and the [RC-004 handoff](project-plan.md). **RC-005** is next ready; **RC-010** remains independently available.

## October 9, 2026 — RC-005 controlled circuit experiments

**RC-005 complete.** This is executable experiment/protocol readiness, not human-playtest acceptance or production-rule selection. The original training encounter and Calibration Wisp remain unchanged. The [experiment matrix and RC-006 handoff](circuit-experiments.md) records exact provisional rules, matched setups, known solutions, controls, metrics, confounds and a blank observation/decision template.

### Baseline and scope

No applicable `AGENTS.md` was found in the repository or ancestor directories. Required design, content, gameplay, workflow (excluding Git work), setup, verification and RC-003/RC-004 handoffs were read. The pinned local Godot installation was used without upgrades or downloads.

The owner's request prohibited all Git operations. One initial `git status --short` was mistakenly included in the first inspection command before the pasted prohibition had been read; this was disclosed immediately. No further Git operations were performed. No branch/revision/checkpoint is asserted or required, and the owner retains Git handling.

Fresh pre-behavior baseline:

| Command / context | Exit | Observed result |
| --- | --- | --- |
| `-Action import`, sandbox | 0 | Existing `Could not open user:// directory` profiler error; not accepted as clean. Android build-tools warning also present. |
| `-Action import`, normal local access | 0 | Desktop import succeeded; Android build-tools warning only. |
| `-Action test` | 0 | **204 checks, 0 failures**. |
| `-Action smoke`, sandbox | 1 | **56 UI checks, 1 failure**, plus null-file script error in the existing user-directory fixture test; sound persistence could not write. |
| `-Action smoke`, normal local access | 0 | **62 UI checks, 0 failures**. First approval-review attempt timed out; the permitted retry succeeded. |

Baseline logs: `output/qa/rc-005-before-{import-sandbox,import,test,smoke-sandbox,smoke}.log`. These failures reproduce the earlier environment restriction; they preceded behavior edits and disappear with normal local user-directory access. They are distinct from runtime regressions.

### Final separate commands

Each action below was run separately; output and exit status were inspected after the final runtime changes:

| Exact command | Exit | Actual result |
| --- | --- | --- |
| `.\tools\godot.ps1 -Action version` | 0 | `4.7.2.stable.official.ed1daf0bf`. |
| `.\tools\godot.ps1 -Action import` | 0 | Script import and new UID companions succeeded; existing Android build-tools warning only. |
| `.\tools\godot.ps1 -Action test` | 0 | **478 checks, 0 failures**: retained204 + experimental core116 + experimental content122 + records/controller36. |
| `.\tools\godot.ps1 -Action smoke` | 0 | **179 UI checks, 0 failures**: retained62 + experiment117. |
| `.\tools\godot.ps1 -Action capture` | 0 | `Screenshot saved: OK`; default capture inspected and copied to `rc-005-training.png`. |

Final logs are `output/qa/rc-005-final-{import,test,smoke}.log` and `rc-005-training-capture.log`. Smoke intentionally prints three asserted startup diagnostics (missing normal fixture, invalid enemy reference, unknown experiment scenario); no script errors or leaked-object reports remain. Intermediate focused validation exposed and fixed a test-only inferred-Variant compile error. An early focused probe with a relative log path had the known user-directory path warning; clean absolute-path reruns passed. Integrated intermediate UI count150 preceded the expanded179-check final suite.

Coverage retains default opening damage/health, configured Wisp behavior, loading diagnostics, ordered events, detached snapshots and all RC-003 input/cancellation protections. New checks cover all19 variant semantics/known openings, the real extra-pair witness, strict options and geometry validation, endpoint/block protection, port rotation/connectivity, consumed/disconnected effects, temporary hand/board cleanup, all expiry replacements, multi-hit totals/order/lethal/zero damage, ownership/UID conservation, same-seed replay and reset/retain transfers, duplicate/incompatible transitions, controlled timing, metrics deduplication/classification, RNG independence, serialization and write failure. UI smoke selects and launches all variants, performs witness edits and casts through actual controls, compares exact-replay snapshots, completes both encounters under both transfer modes, checks stale callbacks across replay, exercises notes/export/write errors and malformed startup.

### Visual evidence

All seven fresh 450×1000 PNGs were inspected. Rendering: OpenGL3.3 Compatibility, NVIDIA GeForce RTX5070Ti, driver610.88. The experiment screen uses a compact enemy summary to keep controls/readouts legible; normal artwork/layout is untouched.

| Capture | Sydney AEDT, October9 | Bytes | What was inspected |
| --- | --- | --- | --- |
| [Normal training](../output/qa/rc-005-training.png) | 00:56:45 | 72,418 | Original complete board, hand, stats, arena, tools and navigation. |
| [Blocked cell and controls](../output/qa/rc-005-blocked.png) | 00:57:02 | 109,823 | Scenario/variant/seed, launch/replay/next/export, explicit blocked6 and valid route. |
| [Alternate endpoints](../output/qa/rc-005-endpoints.png) | 00:57:19 | 115,945 | Begin15/End1, reversed spatial direction, protected endpoint ports and unchanged forecast. |
| [Corner effect](../output/qa/rc-005-ports.png) | 00:57:29 | 107,879 | Spark3 west-to-south ports agree with the actual powered path. |
| [Multi-hit after Cast](../output/qa/rc-005-hits.png) | 00:57:38 | 106,446 | Two visible6-damage hits; enemy24/36, player37/40, turn2. |
| [Retained expiry after Cast](../output/qa/rc-005-expiry.png) | 00:57:48 | 108,796 | Powered3 and disconnected8 become corner wires at the original orientations. |
| [Record inspector](../output/qa/rc-005-record-inspector.png) | 00:58:13 | 137,366 | Scrollable JSON, resolved local path, optional note field and export button. |

Training SHA-256: `17f12203709ab5df2d6dc39900f5464ddac96369b3d328c5d6bd563176f13de2`, identical to RC-003/RC-004. Its fresh timestamp and capture output establish a new render. Experiment capture commands use `-Action capture -Experiment -Scenario <id> -Variant <variant> -Seed 42 -CapturePath res://output/qa/<name>.png`; use `-CaptureStep cast` for hits/expiry and `-CaptureStep inspect` for the inspector. Other captures use the opening state. Captures produce only QA observation files.

### Actual exported records and reproducibility

Inspected JSON files under `output/qa/experiment-records/`:

- `capture-hits-treatment.json`: one accepted Cast, two hits of6, applied damage12, cost3, retaliation3; version `rc005_v1`, seed42, fingerprint `092168db73a29803cadb18666b48ad289e7f95792d39f77ffe1f67b2a40bc4ff`.
- `ui-split_inventory-treatment.json`: three accepted edits (two placements/one rotation), one Cast, damage18/cost4, confirming the extra pair is exercised.
- `ui-encounters-control-complete.json`: four Casts, one rune install, one transition, one rejected duplicate transition, two victories, applied damage48/cost12.
- `ui-encounters-treatment-complete.json`: four Casts, no required edit, one transition, one rejected duplicate transition, two victories, applied damage48/cost12. These scripted counts are **not human behavior findings**.

A separate local audit, `output/qa/rc005_replay_audit.gd`, read these four actual disk exports, rebuilt each validated scenario/variant/seed, checked its configuration fingerprint, replayed command arguments and compared every serialized after-state. **18 command outcomes reproduced, zero mismatches**, exit0; log `output/qa/rc-005-replay-audit.log`. The maintained UI suite also proves exact starting snapshot equality after every variant's Replay button. Preparation timings/notes are not claimed deterministic.

Human records default to `user://experiments/`; the inspector shows the absolute path. Test/capture files are explicitly separated and labelled automated. Ordinary gameplay constructs no recorder. Writes/exports never consume gameplay RNG; failed writes retain gameplay and show a visible error. Replay/Launch preserve an unsaved session rather than discarding its record.

### Limits and handoff

The Android `Unable to open Android build-tools directory` warning remains an export-configuration issue, separate from desktop success. No mobile SDKs were installed, no package was built, and no physical-device acceptance is claimed. No production rules/assets/animations/audio, on-hit/status system, full tower route, shops/rewards/relics or game saves were added. Approved artwork was not modified.

Equal-total multi-hit cannot establish future armor/on-hit balance. Endpoint rotation tests orientation rather than asymmetric board difficulty; the blocked cell initially lies off the path; the corner Spark changes starting cell to hold a valid path constant. The transfer harness supports two identical-geometry encounters only. All these limits are explicit in the protocol. **RC-006 requires actual human playtesting and decisions; RC-010 remains independently available.**

Documentation validation checked **128 local links, zero broken targets** across the updated handoff/reference files. Every runtime/test `.gd` has its generated `.gd.uid` companion. Read-only cross-reviews found no remaining blocking runtime issues; two protocol wording issues (installed Shield count and executable Focus setup) were corrected before handoff.

## October 9, 2026 — RC-006 study preparation and narrow guidance repair

**RC-006 partial.** The [results/session worksheet](rc-006-playtest-results.md) separates evidence sources and tracks the actual session. The [production contract](production-rules-spec.md) is pending, not a selected implementation contract. No rule preference, production choice or testing waiver has been supplied. RC-007 is not ready; RC-010 remains independently available.

No applicable `AGENTS.md` was found in repository/ancestor inspection. The requested design, rules, content, presentation, experiment and handoff documents and recording/launch code were inspected. No Git operations were performed during RC-006.

### Existing evidence and preservation

Both documented/candidate user-record locations initially lacked an experiments directory. A no-gameplay engine probe resolved `user://experiments/` to `C:/Users/nguye/AppData/Roaming/Godot/app_userdata/Rune Cast/experiments/`; see the [path/fingerprint log](../output/qa/rc-006-b1-copy-after-20261009.log). No undisclosed human record was inferred from a directory name.

The [evidence inventory](../output/qa/rc-006-record-inventory.json) parses all 29 pre-existing QA exports: six capture, 22 UI, one recorder fixture. Notes and producing test code establish automated provenance, including the unannotated `ui-session.json` and scripted notes in `record-test.json`. All 29 raw SHA-256 values were unchanged after the repair. `occupied.json` is a test directory, not a participant file. No automated action was counted as a human observation.

### Narrow study repair

`split_inventory/treatment` displayed the exact known solution in participant-facing help before a free attempt. `scripts/core/experiments.gd` now displays neutral stock/cost information instead. Geometry, rules, values, normal gameplay and facilitator/test solution actions are unchanged. The semantics version stays `rc005_v1`; the normalized setup includes help/opening text, so its seed42 configuration fingerprint distinguishes the exposure:

- Previous: `43981ff7148fbb934cb33de07dd23db37dd665f5fdcbd54c92f8256d563b3d5c`.
- Repaired: `639da6f6626f5d7dcc40fd709f8f4cea82c7cb0ca4acab696a1e0758f1842e0d`.

Earlier exports retain their original fingerprint and hint exposure. No located human observation was invalidated. Historical RC-005 semantics and verification entries above remain intact.

| Actual validation | Result / limit |
| --- | --- |
| Pinned engine, headless `--script res://output/qa/rc-006-b1-copy-checks-20261009.gd`, project path `C:/Dev/RuneCast`, unique absolute log path | Exit0; **5 focused checks, 0 failures**. [Log](../output/qa/rc-006-b1-copy-checks-20261009.log). Checks in `tests/experiment_content_tests.gd` cover neutral copy, matched configuration, unchanged options/version, preserved solution and valid 18-damage/cost4 witness. No UI, recorder or participant actions in this check. |
| No-gameplay setup/path probes before/after repair | Both completed; before hash matches the existing automated treatment export and after hash differs only through the intended text changes. Authoritative user path recorded. |
| Raw export integrity | 29 hashes checked, zero changed. No earlier raw records overwritten or relabelled. |
| Markdown local-file/anchor check | See [current audit output](../output/qa/rc-006-document-links.json); zero broken targets at the recorded pass. |

The full Godot suite was not rerun for this copy repair; 478/179 above remain historical RC-005 results. No production rules, new mechanic, mobile acceptance or balance result is claimed.

### Live human-session boundary

Normal `.\tools\godot.ps1 -Action run` launched for practice; restricted user-directory access produced a shader-cache-folder warning. The owner replied “ready” after the four practice steps; completion is participant-reported, not directly observed. The experiment command `.\tools\godot.ps1 -Action run -Experiment -Scenario effects -Variant control -Seed 42` then launched with approved normal user-directory access and no startup error in returned output. Its initial JSON export exists at the resolved human path and contained zero commands, restarts and notes when inspected. That is export readiness, not comparison evidence.

Anonymous session `RC006-S01` is awaiting its first pre-Cast prediction and familiarity/input context. The facilitator has not operated gameplay. Record future actions, assistance and reports in the results worksheet and preserve each completed attempt's export before switching. The owner's participation in this session makes no claim about testers for later milestones.

### October 9 follow-up — initial owner interaction and selected reset direction

The owner reports mouse input and says this is their first game created. Creation experience is not treated as prior playing familiarity. They explicitly selected an endpoints-only board **at the start of every turn, after each Cast or Pass**. This is an owner-directed choice, not a completed persistence/consumption comparison or testing waiver. The [updated specification](production-rules-spec.md) records the selected A/E/F topology consequences; permanent-card destination and the remaining contracts are pending. RC-007 remains not ready.

The active `effects/control` record was read without modification and copied byte-for-byte to the separate [human-study snapshot](../output/playtests/rc-006/RC006-S01/effects-control-1791504179-987301-attempt09-snapshot.json). It contains **9 attempts, 7 accepted edits, 2 rejected placements, 0 Casts, 0 Passes**, and no techniques, damage, outcomes, restarts or embedded notes. Snapshot SHA-256: `de1670a8871ee062ac6ee932b7fbd6a783411787b1511cc2dff3813b93fe062b`. The source was not overwritten or relabelled. The earlier zero-command entry above remains the historical opening inspection.

The [results worksheet](rc-006-playtest-results.md) separates controller-recorded actions from chat preference and interpretation. No direct screen observation, repeated-turn outcome, matched comparison or mobile acceptance is claimed. Existing experimental variants do not implement full-board clearing; manual erase would return cards to hand and cannot validate an automatic discard/draw policy. No runtime/harness code changed during this follow-up, so no additional Godot test run was needed. Local links and original automated-record hashes were checked again; current link results remain in the audit output. No Git operations were performed.

### October 9 follow-up — discard/draw choices and limited next-hand probe

The owner chose **installed permanent cards to discard for later draws**, with the aim of avoiding repeated casts by rebuilding around a changing hand. They explicitly clarified **normal fresh draws, repeats allowed**; no anti-repeat rule is authorized. The specification and linked status documents now record these choices without asking for reconfirmation. This is owner-directed design input, not proof of repeated-turn enjoyment or different hands on every turn.

Before the next launch, the original control record still contained nine attempts and its raw hash matched the preserved human snapshot. The actual command `.\tools\godot.ps1 -Action run -Experiment -Scenario effects -Variant treatment -Seed 42` launched with approved normal user-directory access. Its initial JSON exists at `C:/Users/nguye/AppData/Roaming/Godot/app_userdata/Rune Cast/experiments/effects-treatment-1791505836-787339.json`, version `rc005_v1`, configuration fingerprint `620b7deb4d37b790d538fb23635847bcd6e7029336745d27521ee451c5f79cb3`, with zero commands/restarts/notes at opening inspection.

S01-02 is a **limited one-Cast next-hand probe**, not a completed matched pair or the full-reset rule. The owner was instructed to enter/export their own prediction before Cast, cast once, export and report which new-hand card they would use first when rebuilding. The facilitator performs no gameplay. This fixture retains wires and disconnected Shield, unlike the selected policy; intended usefulness must not be reported as successful construction. Prediction/action/report remain pending at this entry. No runtime code or extra automated gameplay was introduced; documentation/link and prior-record-integrity checks suffice for this follow-up.

## October 9, 2026 — RC-006 full-reset follow-up available

**RC-006 still partial; normal gameplay unchanged.** The owner predicted doubled Spark damage, then reported damage matched, new cards were drawn, but the board should clear. The newer treatment record contains two Casts/four commands; first Cast12/cost3 consumes powered Spark into a straight wire and draws Conjure/Focus/Focus, then Conjure/install Free Spark7/Cast6. Its [unaltered snapshot](../output/playtests/rc-006/RC006-S01/effects-treatment-1791508590-4411584151-attempt04-snapshot.json) has SHA-256 `1e243f2519347a88b57320e9321ab022974ff90f7f5413bd42e8e1768cb47c38`. The owner exceeded the requested single Cast; actual actions and limits are retained. This is feedback on the original treatment, not validation of full-reset play or separate-hit preference.

### Additive experimental implementation

Added only `effects/full_reset`, version `rc006_full_reset_v1`, fingerprint at seed42 `9d979d1f087bced1b8d252ad2b07b78a690345c6d4bf9710e6d06d01680217ab`. The menu now contains nine scenarios/twenty variants; historical RC-005 nine/nineteen remains intact. Existing normalized option dictionaries/setups and their fingerprints remain unchanged relative to the previously verified B1 neutral-copy repair. Normal training has no full-reset option or behavior change.

The new opening contains only Begin0/End14. Accepted Cast/Pass resolves combat, clears all non-endpoint pieces in cell order (permanent→discard, temporary→delete, connectors/special stock→empty), then ordinary hand/Undo cleanup, terminal result or refreshed energy/draw. Disconnected pieces and terminal turns clear; invalid/underfunded Casts do not. No anti-repeat draw logic was added. Loader rejects non-endpoint opening placements and missing/inconsistent metadata. Existing event boundaries are retained, with `board_piece_cleared` for connectors and concise UI cleanup feedback. A facilitator-only construction witness is available without revealing its steps in the player instructions.

Changed code: `scripts/core/{experiments,content_loader,combat}.gd`, experimental UI feedback in `scripts/ui/main.gd`, updated enumeration/witness handling in experiment tests, dedicated `tests/full_reset_tests.gd` and `tests/ui_full_reset_tests.gd`, and their core/UI suite registrations. New `.gd.uid` companions were generated by pinned-engine import. No production switch, route/transfer expansion or other rule selection is implemented.

### Actual validation

| Command / evidence | Result |
| --- | --- |
| Pinned Godot4.7.2, `--headless --script res://output/qa/rc-006-full-reset-checks.gd` with project path and unique absolute log | Final **71 checks, 0 failures**, exit0. [Final core log](../output/qa/rc-006-full-reset-checks-20261009-02.log). Covers Cast/Pass, disconnected/card/temporary conservation, stock, history, rejection, terminal order, recycling, deterministic replay, legacy isolation, malformed new metadata/openings and input immutability. Earlier54-check log preserved before adding17 validation checks. |
| `--headless --script res://output/qa/rc-006-full-reset-ui-checks.gd` | **11 UI checks, 0 failures**, exit0. [UI log](../output/qa/rc-006-full-reset-ui-checks-02.log). Actual scene buttons build/cast, render clearing, save events, exact replay and Menu Pass with disconnected pieces; records use unique `output/qa/rc-006-full-reset-records/` paths, labelled automated. |
| `--headless --script res://output/qa/rc-006-full-reset-regression.gd` | **363 checks, 0 failures**, exit0. [Regression log](../output/qa/rc-006-full-reset-regression-02.log). Existing experiment content/combat, configuration and presentation coverage plus all19 normalized fixture fingerprints. B1 uses its already-repaired fingerprint, not a fabricated match to older hint text. |
| `--headless --editor --import` with unique absolute log | Exit0; new scripts imported and UID files generated. Existing Android build-tools warning only. [Import log](../output/qa/rc-006-full-reset-import.log). |
| `.\tools\godot.ps1 -Action capture -Experiment -Scenario effects -Variant full_reset -Seed 42 -CapturePath res://output/qa/rc-006-full-reset-opening.png` | Exit0, screenshot saved. [450×1000 capture](../output/qa/rc-006-full-reset-opening.png) inspected: only endpoints, curated three-card hand, available Split/Join, disabled Cast, readable controls and explicit testing-only label. New capture record labelled automated; guard confirmed no earlier same-name file would be overwritten. |

The first regression-audit runner stopped on a numeric recorder-fixture `version` compared with a string. That runner-only comparison was fixed with explicit string conversion; the failed log was preserved, then the successful run above completed. It was not a gameplay defect. UI wrapper refactoring was rechecked; no full original record-writing suite was run over earlier QA exports. The original29 raw exports and preserved human snapshots were checked for hash integrity. No Git operations occurred.

### Human follow-up and remaining limits

The verified command `.\tools\godot.ps1 -Action run -Experiment -Scenario effects -Variant full_reset -Seed 42` opened a fresh owner session. The opening export `effects-full_reset-1791509340-605780.json` exists at the resolved user path with the new version/fingerprint and zero commands at initial inspection. It is an opening record, not a human result. The owner was invited to build freely, Cast/Pass and rebuild for two turns, then report whether new hands change their construction. No solution was shown.

The new combined-policy fixture changes starting topology and installed-card allocation, so it is not an isolated matched comparison with old effects control/treatment. Six energy, low repeated enemy damage, fixed endpoints, straight ports, aggregate hits and one pair remain fixture constants, not production approvals. Full-reset human outcomes, remaining rule decisions and complete production contract are pending; RC-007 is not generally ready. RC-010 remains independently available.

## October 9, 2026 — Full-reset human result and moving-endpoint follow-up

### Human evidence preserved

After the requested relaunch, S01-05 `effects/full_reset` recorded **43 accepted commands: 38 edits, three techniques and two Casts**. The owner reported “Yes, clearing is working and new hand also changes.” The [unaltered attempt43 snapshot](../output/playtests/rc-006/RC006-S01/effects-full_reset-1791509912-592636-attempt43-snapshot.json) has SHA-256 `7a6c9257034b342c4c11c955e195d9a67da84914d98da62863342c81062064c5`. Source: `C:/Users/nguye/AppData/Roaming/Godot/app_userdata/Rune Cast/experiments/effects-full_reset-1791509912-592636.json`; version `rc006_full_reset_v1`, seed42, unchanged fingerprint `9d979d1f087bced1b8d252ad2b07b78a690345c6d4bf9710e6d06d01680217ab`.

First Cast12/cost2 uses Spark/Free Spark, clears four cells, takes3 retaliation and draws Focus/Spark/Conjure. The second uses a different longer route with Shield/Spark/Free Spark, deals12/cost3/shield5, blocks3, clears ten cells and draws Conjure/Spark/Conjure after reshuffling. Spark3 is immediately redrawn as allowed. Total recorded cost6 includes Focus1; neither cast uses Split. Both end with only Begin0/End14 and Undo0. No Pass, rejected command, embedded note, restart, terminal outcome or transition occurs. Command snapshots are continuous and totals agree; reasons for specific route choices are not inferred from edit counts.

The owner next said rebuilding was worthwhile because they also wanted Begin/End positions to change each turn, then selected random choice with rotation allowed. H14–H17 in [the results](rc-006-playtest-results.md) distinguish the positive subjective report, recorded fixed-endpoint actions and new design direction. The facilitator stated the interpretation as game-chosen positions/orientations at turn start, always connectable. This does not establish moving-endpoint enjoyment, a matched winner, durable novelty, or mobile usability.

### Separately versioned experimental implementation

Added `effects/moving_endpoints`, version `rc006_moving_endpoints_v1`, seed42 fingerprint `94ea5c516cb6de6f77f55e75c83053e5dfc7849fe1ed2da53d29b90321226512`. Current matrix is nine scenarios/twenty-one variants; all twenty earlier normalized setups retain their fingerprints, including the previously repaired B1 text and the human-played fixed full-reset setup. Normal gameplay rules are unchanged.

The new fixture preserves full-reset stats/cards and initial Begin0/End14, then selects uniformly from eligible entries in an eight-layout catalog where both endpoints change cells. Catalog paths and rotations are pinned in normalized options; each has a simple connection with a straight rune socket, and every layout has eligible successors. This is bounded variety, not arbitrary endpoint generation. Separate endpoint RNG uses `seed XOR 0x52434D45`, without consuming card RNG. Exact replay reseeds both; ordinary Restart restores the initial board and continues both streams.

Old-board/card cleanup happens before relocation; `endpoints_changed` records before/after layout IDs and endpoint cells/rotations before `turn_started` and draws. Terminal turns clear without choosing unused endpoints. Rejected commands, techniques, edits and Undo do not move them. New endpoint cells remain protected, vacated old cells are editable, and cards occupying new destinations are conserved through cleanup. Participant tooltip hides witness paths, while raw inspector/export retains them for audit. Latest feedback says endpoints moved; the Begin symbol follows its actual output direction.

Changed core: `scripts/core/{content_loader,experiments,combat}.gd`; presentation: `scripts/ui/{main,board_cell}.gd`; focused tests: `tests/{moving_endpoint_tests,ui_moving_endpoint_tests}.gd`, plus generic enumeration and core/UI registrations. New script UID companions were generated and verified. No production first-turn policy, catalog approval, terrain exception or other unresolved rule is implied by this fixture.

### Actual validation and launch

| Check / command | Result |
| --- | --- |
| Pinned Godot4.7.2 headless `--script res://output/qa/rc-006-moving-endpoint-checks.gd` | **77 checks, 0 failures**, exit0. [Final core log](../output/qa/rc-006-moving-endpoint-checks-20261009-02.log). All eight layouts have independently constructed rune-capable routes; all56 permitted transitions covered. Mixed Cast/Pass replay, both RNG independence directions, Restart, cleanup/ownership, protection, terminal/rejected/edit/technique/Undo boundaries and malformed metadata covered. Earlier75-check log preserved. |
| `--script res://output/qa/rc-006-moving-endpoint-ui-checks.gd -- --moving-capture=res://output/qa/rc-006-moving-endpoint-turn2-02.png` | **18 UI/capture checks, 0 failures**, exit0. [Final UI log](../output/qa/rc-006-moving-endpoint-ui-02.log). Includes rendered movement, protection, vacated-cell edit, neutral tooltip, inspector export, exact replay and empty-board Menu Pass. Automated records use unique `output/qa/rc-006-moving-endpoint-records/` paths. Earlier headless17-check run also passed. |
| Headless `--script res://output/qa/rc-006-moving-endpoint-regression.gd` | **444 checks, 0 failures**, exit0. [Final regression log](../output/qa/rc-006-moving-endpoint-regression-02.log). Existing experiment/content/configuration/presentation and full-reset71 checks plus all20 prior fixture fingerprints. |
| `--headless --editor --import`, explicit project/log paths | Exit0; scripts imported and new test UIDs generated. [Import log](../output/qa/rc-006-moving-endpoint-import.log). Restricted `user://` profiler-directory warning and existing Android build-tools warning remain environment limitations. |
| Visual inspection of [turn2 capture](../output/qa/rc-006-moving-endpoint-turn2-02.png) | Only Begin1/End7 remain, with changed directions and Begin's downward symbol; three-card hand, disabled Cast, readable controls and relocation feedback. Capture succeeded despite restricted shader-cache-folder warning; no rendering failure observed. Earlier image retained before the directional-symbol correction. |

The command `.\tools\godot.ps1 -Action run -Experiment -Scenario effects -Variant moving_endpoints -Seed 42` opened S01-06 with approved normal user-directory access and no startup error. Initial export `effects-moving_endpoints-1791510778-720169.json` exists in the verified human directory with the new version/fingerprint and zero commands. Opening-only SHA-256 `3ce4c7bd9eef0c38434cdabf3a9a17460031261be6391b8f6832aee9879be9da` is a point-in-time hash, not a final hash of an autosaving session. The owner is invited to build freely for two turns and report direction clarity and useful choices versus awkwardness. No known solution was shown; no moving-endpoint human result is claimed yet.

Original raw records and earlier human snapshots remain separate and unmodified; the current [local-link audit](../output/qa/rc-006-document-links.json) checks the synchronized handoff. No original record-writing suites were rerun over existing exports, and no Git operations occurred. **RC-006 remains partial, RC-007 not generally ready, RC-010 independently available.** Remaining evidence and contracts include B1/B2, C2/C3, D, transfer boundaries and final moving-endpoint production integration.

## October 9, 2026 — Player-controlled endpoint rotation and arbitrary positions

### Correction and preserved human evidence

The owner reported clearing worked, then clarified that Begin/End should rotate like normal pieces and appear anywhere, including next to each other. This corrects the facilitator's earlier interpretation of game-selected, protected rotations. It is an explicit C1 design choice, not approval of the eight-layout restriction or a reported enjoyment/readability result.

The initial S01-06 moving-endpoint file remains zero-command; its [opening snapshot](../output/playtests/rc-006/RC006-S01/effects-moving_endpoints-1791510778-720169-attempt00-snapshot.json) matches the opening hash above. A later active S01-07 file supplies [25 preserved attempts](../output/playtests/rc-006/RC006-S01/effects-moving_endpoints-1791511346-568465250-attempt25-snapshot.json), SHA-256 `d53053bfc710e8356dc31c769b55aeca42ae3e7648060da4b989b6a4fe4ccedb`: eight edits, one Cast6/cost2, eleven rejected endpoint Rotate attempts, and five Passes. Cast clears four cells and moves endpoints0/14→1/7. Five Begin1 and six End7 rotations are rejected. Empty-board Passes advance to turn7, player22HP/enemy30HP; no notes, restart, techniques, terminal outcome or transition. This corroborates the interaction mismatch without inferring frustration or reasons for Pass. Records remain distinct rather than merging the opening-only and played files.

### Corrected opt-in implementation

Added `effects/free_endpoints`, version `rc006_free_endpoints_v1`, seed42 fingerprint `9c83d6c3c90601b6abbfaaf110ae3195c12f705b2eb23a4ba91d68aade6dd005`. All21 earlier fixture fingerprints are preserved; current menu has nine scenarios/twenty-two variants. Normal gameplay rules are unchanged.

Initial placement samples uniformly from all240 ordered distinct-cell pairs. Subsequent surviving Cast/Pass selects among211 pairs moving both endpoints from their own previous cells, including cross-swaps and adjacency. Each starting orientation is sampled independently0–3 and may face off-board. Normal Rotate turns either endpoint90 degrees, updates its ports, and supports existing Undo/history semantics without changing cards/energy/RNG. Endpoint replacement, Erase and Flip remain prohibited. Every positional pair has a rune-bearing connection after suitable rotations/building; no promise that every generated orientation is already connectable. Direct facing neighbors retain the existing valid zero-damage connection, with no added minimum-path/rune requirement.

Initial placement is in the recorded initial state rather than an action event. After a surviving turn, card/board cleanup precedes `endpoints_changed`, then `turn_started` and normal draws. Terminal and rejected actions do not relocate; manual edits cannot consume endpoint RNG. Endpoint/card streams remain separate; Exact replay resets both, Restart continues them and selects a new random opening. Metadata pins `random_any_cells`, player rotation, random initialization, selection algorithm ID,240 initial/211 successor counts. No route catalog or solution is exposed in participant help.

Changed core: `scripts/core/{content_loader,experiments,combat}.gd`; UI: `scripts/ui/main.gd` endpoint selection/tooltip/Guide guidance; dedicated `tests/{free_endpoint_tests,ui_free_endpoint_tests}.gd`, generic enumeration/witness support and core/UI registrations. Clicking an endpoint clears a held placement tool/card and selects it for Rotate. The Guide's old blanket protection sentence now has a new-variant exception; all earlier guide behavior is retained. Facilitator-only solution actions accept a seed and construct a rune-bearing path for the actual random opening. New script UID companions are generated and verified.

### Actual validation

| Command / evidence | Result |
| --- | --- |
| Pinned Godot4.7.2 headless `--script res://output/qa/rc-006-free-endpoint-checks.gd` | **74 checks, 0 failures**, exit0. [Final core log](../output/qa/rc-006-free-endpoint-checks-20261009-03.log). Independently built affordable Spark routes for all240 positional pairs; all211 successor sets/cross-swaps, adjacency/direct zero-damage connection, Rotate/Undo/history limit, protection, cleanup/conservation, terminal/rejected behavior, RNG independence, Restart and exact record replay. |
| `--script res://output/qa/rc-006-free-endpoint-ui-checks.gd -- --free-capture=res://output/qa/rc-006-free-endpoint-adjacent-03.png` | **23 UI/capture checks, 0 failures**, exit0. [Final UI log](../output/qa/rc-006-free-endpoint-ui-capture-03.log). Actual click/Rotate/Undo on both endpoints, held tool/card selection, Guide, Cast, replay, Pass, inspector/export and adjacent seed9. Automated record paths are unique under `output/qa/rc-006-free-endpoint-records/`. |
| Headless `--script res://output/qa/rc-006-free-endpoint-regression.gd` | **536 checks, 0 failures**, exit0. [Regression log](../output/qa/rc-006-free-endpoint-regression-01.log). Existing experiment/configuration/presentation, full-reset71, moving-endpoint77 and all21 earlier fingerprints. |
| Read-only facilitator solution probe, seeds0–63 | Every generated opening solution is accepted, valid and6damage/cost2. [Probe log](../output/qa/rc-006-free-endpoints-core-probe-02.log). No participant record produced. |
| Editor import and generated UID inspection | Exit0; both new test UIDs exist. [Import log](../output/qa/rc-006-free-endpoint-import.log). Restricted user-directory profiler warning and existing Android build-tools warning remain environment limitations. |
| Visual inspection of [final adjacent capture](../output/qa/rc-006-free-endpoint-adjacent-03.png) | Seed9 is correctly shown in input and active label; End1 and Begin5 are neighbors. Begin is selected after normal Rotate, its symbol/port point left, instructions are readable and the board contains only endpoints. Capture succeeded despite restricted shader-cache warning. |

Earlier focused-check logs are preserved: an initial type-annotation parse issue in the new test was corrected; a second test incorrectly compared relocated endpoints with the normal fixed-position evaluator, then was corrected to compare with the existing dynamic-endpoint experiment evaluator. No gameplay defect was indicated by those test-runner issues. UI coverage was expanded after review found the stale Guide sentence. The adjacent UI probe now enters its seed through normal Launch controls, keeping the displayed input and active seed consistent. No full record-writing suites were run over earlier raw evidence.

### Human rotation confirmation and next block

The command `.\tools\godot.ps1 -Action run -Experiment -Scenario effects -Variant free_endpoints -Seed 42` launched S01-08 with approved normal user-folder access and no startup error. Source `effects-free_endpoints-1791512378-674454.json` was initially zero-command, opening hash `3375c4afe5f6553c409c5270f120274b2b9840187a5f36e7d93ab1e3824240bf`. After click/Rotate guidance, the owner replied **“Yes it is working.”** The [seven-command snapshot](../output/playtests/rc-006/RC006-S01/effects-free_endpoints-1791512378-674454-attempt07-snapshot.json), SHA-256 `e8a68cf3d9053683ae3659e6003e5184ae25cdd18b1606e7c5b455dae9a0935e`, contains three accepted Begin6 rotations and four accepted End15 rotations. No Cast, Pass, Undo, other edit, technique, rejection, notes or lifecycle event appears. This confirms manual controls, not completion of the requested build/next turn or adjacency/rebuilding enjoyment.

After preserving that snapshot, `.\tools\godot.ps1 -Action run -Experiment -Scenario split_inventory -Variant treatment -Seed 42` opened S01-09 for B1. Initial source `split_inventory-treatment-1791512571-688570.json` has zero commands and the existing neutral-copy fingerprint `639da6f6626f5d7dcc40fd709f8f4cea82c7cb0ca4acab696a1e0758f1842e0d`. The owner was explicitly told this stock comparison uses a retained sample circuit and does not reverse selected clearing/endpoint rules. They are asked to explore the extra pair freely and state expected damage/cost before Cast; no known solution shown. One-pair control and comparison remain pending.

No Git operations occurred. Raw records, historical reports and snapshots are preserved; automated tests remain distinct from one owner's evidence. RC-006 remains partial and RC-007 is not generally ready; RC-010 is independently available. B1/B2, C2/C3, hit feedback, transfer boundaries and the final combined production contract remain unresolved.

## October 9, 2026 — RC-006 B1 human results and circuit-kit proposal

Preserved the owner's extra-pair screenshot and S01-10 treatment record as unaltered copies. [Treatment attempt12](../output/playtests/rc-006/RC006-S01/split_inventory-treatment-1791512908-337653853-attempt12-snapshot.json), SHA-256 `330fa3ab71e451ba83c6161dd4316dda4dd1436d3005a5648b7315fe0555b820`, has twelve accepted commands: ten edits, one Cast18/cost4 and one Conjure. The two-pair circuit carries three copies of Spark6 to End and resolves one aggregate hit; enemy36→18/player40→37. [Screenshot](../output/playtests/rc-006/RC006-S01/split_inventory-treatment-owner-screenshot-20261009.png), SHA-256 `2007ab454b3e5d58ab57baef718259a951e8b25f470dbee28ef9c81c73983475`, matches the final state and the supplied source image byte for byte. The owner said the extra-pair construction worked as expected. This is a retrospective report without a numeric pre-Cast prediction.

Launched `.\tools\godot.ps1 -Action run -Experiment -Scenario split_inventory -Variant control -Seed 42` with approved normal user-folder access. S01-11 source `split_inventory-control-1791513150-645708.json` initially had zero commands, opening hash `5ece9cf0e1a9f2773f8bd09595e58ae5bda7d2327d9616c841d938a0edf7866d`, fingerprint `361b22fd5bb6424f5af792ec0ed73882d91ccdbb8219da00afd1f345a825b24f`. After the human's free build, [control attempt06](../output/playtests/rc-006/RC006-S01/split_inventory-control-1791513150-645708-attempt06-snapshot.json), SHA-256 `83f6cf191f7ced6cebc620189c73e63445eebfef1169b4e2c3be28b0686eb880`, records five edits and one Cast6/shield10/cost4, blocking incoming3 and keeping player40HP. The owner reported “It work as expected.” Again no numeric pre-Cast prediction was supplied. Both records conserve permanent UIDs0–7 throughout. Initial states differ only in available stock; the resulting offense/defense constructions differ, so damage totals do not isolate stock benefit.

H30 asks for a limited/random supply mechanic instead of selecting one/two pairs. The documented **unselected proposal** uses three equally likely ten-piece kits: Straight/Corner/Split/Join counts6/2/1/1,4/4/1/1,4/2/2/2. A pure JavaScript abstract path enumeration visited all240 ordered distinct endpoint pairs on the4×4 grid and found a simple path for each with at most four interior straight cells, two corner cells and at least one straight socket; no missing pair. Search allowed orthogonal neighbors, no repeated cell, and at most eight path cells. This supports only the basic geometric supply claim with manual endpoint rotation and no obstacles. It is not an engine test, human result, balance finding or proof every rune hand has a useful affordable Cast.

This update changes evidence/documentation only. No gameplay code or Godot test suite rerun; earlier633 checks remain historical verification. The stock proposal is not implemented or selected. B2 and the other unresolved decisions remain open, RC-006 stays partial and RC-007 is not generally ready. Raw-evidence preservation and local-link checks are recorded in the linked audit outputs below. No Git operations occurred.

- [Preservation audit](../output/qa/rc-006-b1-human-preservation.json): all29 original QA records,19 exploration copies,eight frozen human JSON snapshots and one supplied PNG retain their expected hashes; the PNG also matches its original attachment. Zero failures.
- [Local documentation audit](../output/qa/rc-006-document-links.json): README and17 documentation files checked, including local target paths and Markdown anchors; zero broken references.

## October 9, 2026 — RC-006 provisional kit selection

H31 records the owner's acceptance of the three random ten-piece kits: “Okay, let's keep it like that for now.” Updated the evidence register, B1 selection/stock contract and acceptance cases, dated decisions, current-versus-future gameplay notes, project handoff, experiment notes, design, roster and README. The selected prototype counts are Straight/Corner/Split/Join6/2/1/1,4/4/1/1,4/2/2/2. Separate rune ownership, finite stock accounting and no banking remain explicit. Quantities/probabilities are tuning values; no new kit play, B2 cost selection or testing waiver is claimed.

Documentation-only change: no source code, raw records, stable content IDs or budgets changed, and no Godot tests or Git operations were run. The [local-link audit](../output/qa/rc-006-document-links.json) covers current target paths and Markdown anchors. Earlier engine checks and evidence hashes remain historical records. RC-006 stays partial; RC-007 is not generally ready because the other decisions and complete integration are unresolved.

## October 9, 2026 — RC-007 reconciliation and finite-stock groundwork

**Status: partial, pending the consolidated owner rule answer.** No post-H31 evidence closes the remaining decisions; the current request reconfirms first-turn empty setup and equal kit probabilities. Implemented only independent connector definitions, finite inventory/editing, UI labels/Guide and QA preservation. Normal production reset, per-turn kit scheduling, endpoint RNG policy and encounter entry remain unintegrated. This is automated desktop evidence, not a human playtest or a testing waiver.

Before gameplay changes, inventoried 98 existing human/QA evidence and asset files. Two existing test suites had fixed JSON export destinations; changed only their destinations to unique RC-007 QA subdirectories before running the baseline. Automated experiment capture records now also use unique QA paths. Human `user://experiments/` paths are unchanged, and no raw study file was rewritten.

| Separate pinned-engine action | Actual result / evidence |
| --- | --- |
| `tools/godot.ps1 -Action version` | `4.7.2.stable.official.ed1daf0bf`, exit 0; [final version](../output/qa/rc-007/final-version.log). No override or upgrade. |
| Baseline `-Action import` | Exit 0, but sandbox could not access the editor user-data directory. Normal local-access rerun exit 0 without that error; [local import](../output/qa/rc-007/baseline-import-local.log). Android build-tools warning remains. |
| Baseline `-Action test` | **737 checks, 0 failures**, exit 0; [baseline core](../output/qa/rc-007/baseline-test.log). |
| Baseline `-Action smoke` | Sandbox run failed sound-settings persistence and could not create a user-data fixture (241 checks, 1 failure, script diagnostic). Normal local-access rerun: **247 checks, 0 failures**, exit 0; [sandbox result](../output/qa/rc-007/baseline-smoke.log), [local result](../output/qa/rc-007/baseline-smoke-local.log). These precede implementation and are environment failures, not regressions. |
| Baseline `-Action capture -CapturePath res://output/qa/rc-007/baseline-training.png` | Exit 0; [baseline capture log](../output/qa/rc-007/baseline-capture.log). |
| Final `-Action import` | Exit 0 using normal local access; [final import](../output/qa/rc-007/final-import.log). Existing Android warning only. |
| Integrated `-Action test` | **926 checks, 0 failures**, exit 0; [integrated core](../output/qa/rc-007/integrated-test.log). Includes 175 connector-definition/editing checks and 14 assertions over 720 exhaustive geometry cases. |
| Final `-Action smoke` | **289 UI checks, 0 failures**, exit 0 with normal local access; [final smoke](../output/qa/rc-007/final-smoke.log). Includes 42 new finite-stock/Guide checks. Intentional invalid-startup diagnostics remain expected. |
| Final `-Action capture -CapturePath res://output/qa/rc-007/final-training.png` | Exit 0; [final capture log](../output/qa/rc-007/final-capture.log). |
| Rendered finite-stock fixture | **43 UI/capture checks, 0 failures**, exit 0; [runner](../output/qa/rc-007/finite-stock-capture.gd), [log](../output/qa/rc-007/finite-stock-render-final.log). Runs the actual scene, controls, Guide and screenshot save; no participant record. |

The existing core/UI runners already included the RC-006 full-reset, moving-endpoint and free-endpoint suites. They remain registered and unchanged. Their Cast/Pass, cleanup, terminal, endpoint Rotate/Undo, exact replay, Restart, encounter-pair, ownership, input-lock and stale-callback assertions still pass; these are historical fixture checks, not proof of integrated production rules. The new tests cover all three kit definitions, malformed/partial finite configuration, detached inputs/snapshots, injected-stream reproducibility, permitted repeats, all four stock caps, disconnected reservations, same-/cross-type replacement, rune refunds, erase, Rotate/Flip and Undo. Existing 12-damage opening assertions stay valid because normal default migration is explicitly pending.

The independent geometry search command-builds a supplied straight-Spark route for **240 ordered endpoint pairs × 3 kits = 720 cases**. Each kit includes all 48 ordered horizontal/vertical adjacencies; 180 Begin and 180 End cases start outward at a boundary and are repaired by ordinary Rotate. Actual piece ports are checked after Rotate/Flip. Each route is then surrounded by the remaining disconnected kit pieces, exhaustion is rejected for every type, and erasing the extras restores the route. No runtime solver, hidden reroll or extra piece is introduced. This establishes geometric feasibility with a supplied rune, not affordability, useful random hands, balance or human experience.

Visually inspected fresh 450×1000 [baseline training](../output/qa/rc-007/baseline-training.png), [final training](../output/qa/rc-007/final-training.png) and [finite-stock fixture](../output/qa/rc-007/finite-stock.png) images. Training remains pixel-identical: SHA-256 `17f12203709ab5df2d6dc39900f5464ddac96369b3d328c5d6bd563176f13de2`. The finite fixture shows Straight 5/6 after one disconnected placement, Corner 2/2, Split 1/1, Join 1/1, an incomplete-board Cast button, and the unchanged placeholder composition. It is clearly titled `FINITE STOCK QA`; its fixed endpoints/curated hand are test scaffolding, not a final production selection.

[Preservation results](../output/qa/rc-007/preservation-results.json): all **98** previously inventoried evidence/assets retain their SHA-256 hashes; all **22** seed-42 historical experiment configuration fingerprints match [before](../output/qa/rc-007/fixture-fingerprints-before.json) and [after](../output/qa/rc-007/fixture-fingerprints-after.json). The initial standalone fingerprint probe emitted a log-path/user-data diagnostic but successfully wrote its audit; rerunning with an absolute workspace log path completed cleanly. No historical experiment version, definition ID or approved image changed.

The first discovery command included a read-only `git status --short` before the pasted prohibition had been read. This was immediately disclosed; no later Git operations, staging, commit or checkpoint occurred. No mobile SDK installation, packaging, physical-device acceptance, assets, animation/audio, run/reward/save systems or later-task implementation is claimed. Pending owner choices and the exact continuation boundary are in the [RC-007 handoff](project-plan.md).

Documentation QA checked 326 relative file links across 11 updated documentation files, with zero missing targets; [results](../output/qa/rc-007/document-links.json). This check covers file existence, not Markdown anchors.

## October 9, 2026 — RC-007 accepted defaults and completed production integration

**RC-007 complete.** The owner answered “Accept all default.” to the consolidated seven-choice proposal. H32 records this as a design decision, not human-playtest evidence or a testing waiver. The [precise accepted contract](production-rules-spec.md#october-9-2026--accepted-rc-007-implementation-contract) was written before dependent integration. Earlier pending-status entries above are preserved as historical records. The [completed handoff](project-plan.md#october-9-2026--rc-007-production-rules-complete) identifies the delivered files, scope and next tasks.

Normal launch now loads `data/production_encounter.json`: endpoints-only turns, random rotatable endpoints, normal first/later draws, independent random finite kits, Split1/Join0, straight effect ports, no blocked cells, aggregate damage and complete board/hand cleanup. Terminal cleanup generates no unused turn; one configured victory transition conserves permanent UIDs and current/max HP. The original prefilled 12-damage opening is retained explicitly through `-Encounter res://data/encounter.json`. Historical assertions now select that fixture; their expected behavior was not weakened.

Before final integration, a fresh baseline imported successfully and passed **926 core / 289 UI checks**, zero failures: [import](../output/qa/rc-007/implementation/baseline-import.log), [core](../output/qa/rc-007/implementation/baseline-test.log), [UI](../output/qa/rc-007/implementation/baseline-smoke.log). All automated records/captures continue using isolated QA destinations. Inventoried 193 pre-existing evidence/asset files, including the earlier RC-007 preparation evidence, before changing production behavior.

The required launcher actions were run separately with the pinned engine and normal local user-directory access:

| Action | Final actual result |
| --- | --- |
| `.\tools\godot.ps1 -Action version` | `4.7.2.stable.official.ed1daf0bf`, exit 0; [log](../output/qa/rc-007/implementation/final-version.log). |
| `.\tools\godot.ps1 -Action import` | Exit 0; existing Android build-tools warning only; [log](../output/qa/rc-007/implementation/final-import.log). |
| `.\tools\godot.ps1 -Action test` | **1063 checks, 0 failures**, exit 0; [log](../output/qa/rc-007/implementation/final-test.log). |
| `.\tools\godot.ps1 -Action smoke` | **333 UI checks, 0 failures**, exit 0; [final rerun](../output/qa/rc-007/implementation/final-smoke-02.log). Expected invalid-configuration diagnostics remain part of safe-startup tests. |
| `.\tools\godot.ps1 -Action capture -CapturePath res://output/qa/rc-007/implementation/final-production.png` | Exit 0 and screenshot saved; [log](../output/qa/rc-007/implementation/final-capture.log), [image](../output/qa/rc-007/implementation/final-production.png). Explicit fresh destination preserves older captures. |

The [first final smoke run](../output/qa/rc-007/implementation/final-smoke.log) recorded 333 checks with one failure: the new Rotate-direction feedback changed an explicitly historical endpoint fixture's expected guidance. Restricting that wording to production restored historical behavior; the final rerun above passes. Independent review also found that the Cast tooltip still predicted incoming damage on a lethal spell. It now reports zero incoming and has an actual-scene regression assertion. Intermediate logs remain preserved; neither issue is hidden as a pre-existing failure.

Focused production [core verification](../output/qa/rc-007/production-combat-final.log) passes **82 checks**; [content validation](../output/qa/rc-007/implementation/content-tests.log) passes **55 checks**. These counts are included in the full core suite, not additional totals. Coverage includes powered/disconnected permanent/temporary cleanup after Cast and Pass, physical cost/UID deduplication under amplification, zero/requested/applied damage, lethal/shield order, empty pools/immediate repeats, terminal/rejected boundaries, independent RNG sequences, Restart/Exact replay, detached data and guarded compatible encounter transfer.

[Geometry verification](../tests/connector_geometry_tests.gd) now runs the actual production model for **240 ordered endpoint pairs × 3 kits = 720 cases**, with one explicitly supplied straight Spark and naturally selected seeds for each kit. Its 14 aggregate assertions are included in the full suite. Each kit covers all 48 ordered adjacencies and 180 outward-facing starting directions for each endpoint. Ordinary commands build/rotate/flip the route, fill disconnected stock to exhaustion, reject excess placement, erase extras and verify all three RNG states stay unchanged. Core tests separately cover all endpoint rotations and all 48 direct zero-effect adjacency routes. This establishes bounded geometry and accounting, not random-hand usefulness, affordability or kit balance; no runtime reroll, solver or extra piece is added.

The final rendered [actual-scene run](../output/qa/rc-007/production-ui-implementation-04.log) passes **52 checks, 0 failures**, including eight captures. It exercises opening/build/Cast, incomplete-board Pass, changed turns, adjacency, stock exhaustion/Undo, victory/defeat, Restart, Exact replay, configured encounter entry and stale controller callbacks. Visually inspected the [opening](../output/qa/rc-007/implementation-ui-1791517855-6264-1588606/production-opening.png), [Guide](../output/qa/rc-007/implementation-ui-1791517855-6264-1588606/production-guide.png), [built circuit](../output/qa/rc-007/implementation-ui-1791517855-6264-1588606/production-built.png), [next turn](../output/qa/rc-007/implementation-ui-1791517855-6264-1588606/production-turn2.png), [adjacency](../output/qa/rc-007/implementation-ui-1791517855-6264-1588606/production-adjacent.png), [victory](../output/qa/rc-007/implementation-ui-1791517855-6264-1588606/production-victory.png), [defeat](../output/qa/rc-007/implementation-ui-1791517855-6264-1588606/production-defeat.png) and [successor](../output/qa/rc-007/implementation-ui-1791517855-6264-1588606/production-next-encounter.png). Stock/hand/pile labels, selected directions, reset guidance and controls fit the unchanged portrait composition. The successor displays the Wisp with carried 30/30 HP, four energy and two cards. The standalone renderer reports a sandbox shader-cache folder warning, but all rendered checks and saves complete; the separate launcher capture succeeds cleanly.

The [final preservation audit](../output/qa/rc-007/implementation/preservation-results.json) confirms **193 unchanged file hashes and all 22 unchanged historical experiment fingerprints**; [current fingerprints](../output/qa/rc-007/implementation/fixture-fingerprints-current.json) match the preserved before audit. Stable production IDs, original fixture documents, raw human records, historical exports and approved images remain intact. No new participant findings, physical-device acceptance, engine upgrade, SDK installation, packaging, production art/animation/audio or later progression systems are claimed. The Android warning remains separate from desktop success. No Git operations occurred during this integration phase; the initial read-only exception disclosed in the earlier entry remains on record.

Kit quantities/probabilities, arbitrary-position rebuilding quality and starter difficulty remain tuning risks. There are no remaining RC-007 implementation blockers. **RC-008, RC-009, RC-010, RC-024 and RC-033** are next-ready under the updated plan; external platform/device requirements still apply to RC-021/RC-022.

Final [documentation audit](../output/qa/rc-007/implementation/document-links.json) checks 13 updated documents and 432 relative file links, with zero missing targets. This covers file existence, not Markdown anchors.

## October 9, 2026 — RC-008 touch inspection complete

**RC-008 is complete.** The [touch interaction contract](touch-interactions.md) and [handoff](project-plan.md#october-9-2026--rc-008-touch-inspection-complete) describe the delivered behavior. Production/core rules, controller command/event ordering, distributions, ownership and historical experiment semantics remain unchanged. The user-requested no-Git exception and device limitations are recorded below.

### Fresh baseline before editing

Read the requested architecture/rules/content/visual documents, the latest RC-007 handoff, project configuration and launcher, and inspected the approved Combat reference. No applicable `AGENTS.md` was found in the project or its parent locations. Baseline records use a separate `output/qa/rc-008/` directory. Existing fixed-name launcher logs were archived before running commands and restored after verification.

| Baseline action | Actual result |
| --- | --- |
| `-Action import` | Exit 0, but restricted user-data access emitted a `user://` error; existing Android build-tools warning also appeared. [Log](../output/qa/rc-008/baseline-import.log). Final normal-access import below is clean apart from the known Android warning. |
| `-Action test` | **1063 checks / 0 failures**, exit 0. [Log](../output/qa/rc-008/baseline-test.log). |
| `-Action smoke`, restricted | Exit 1, **327 checks / 1 failure** plus a null file-write script error: settings persistence and the temporary invalid-content fixture could not write to `user://`. This incomplete environment-blocked run is preserved in its [log](../output/qa/rc-008/baseline-smoke.log). |
| `-Action smoke`, normal local access | **333 UI checks / 0 failures**, exit 0. Expected invalid-content diagnostics only. [Log](../output/qa/rc-008/baseline-smoke-normal-access.log). This is the valid pre-edit UI baseline. |
| Baseline rendering | [450×1000 normal preview](../output/qa/rc-008/baseline-normal.png) and [360×640 smaller window](../output/qa/rc-008/baseline-small.png), both saved successfully and inspected. |

The baseline showed compact cards with no visible touch inspector and eight small editing controls in one row. Source/input-path inspection confirmed immediate technique activation and no scroll/hold arbitration around card/board Button signals. A real native-window inspection succeeded, but the attempted click returned `SendInput sent 0 of 1 events; GetLastError=87`; the refreshed capture was not reliable for the intended window. Native input attempts stopped. Thus there is no successful manual technique/scroll test to infer from that attempt.

### Final required commands

Each launcher action was executed separately from PowerShell in `C:\Dev\RuneCast`, with actual output and exit status inspected. Normal local user-directory access was used for import/UI/rendering when required; no SDK or engine upgrade was performed.

| Command | Actual final result |
| --- | --- |
| `.\tools\godot.ps1 -Action version` | `4.7.2.stable.official.ed1daf0bf`, exit 0. [Log](../output/qa/rc-008/final-version.log). |
| `.\tools\godot.ps1 -Action import` | Exit 0. Existing `Unable to open Android 'build-tools' directory` warning; no script import error. [Log](../output/qa/rc-008/final-import.log). |
| `.\tools\godot.ps1 -Action test` | **1063 core checks / 0 failures**, exit 0. [Log](../output/qa/rc-008/final-test.log). |
| `.\tools\godot.ps1 -Action smoke` | **503 UI checks / 0 failures**, exit 0. [Final rerun](../output/qa/rc-008/final-smoke-02.log). Deliberately missing/invalid startup diagnostics are expected test coverage. |
| `.\tools\godot.ps1 -Action capture -CapturePath res://output/qa/rc-008/final-production.png` | Exit 0; screenshot saved successfully to a new path. [Log](../output/qa/rc-008/final-capture.log), [normal launch](../output/qa/rc-008/final-production.png). |

The final core count retains all existing checks, including production geometry/accounting and historical rules. The UI count is the existing **333**, plus **67** read-only inspection/availability checks, **30** gesture arbitration checks and **73** actual-scene touch/lifecycle checks. Coverage lives in [inspection_data_tests.gd](../tests/inspection_data_tests.gd), [touch_router_tests.gd](../tests/touch_router_tests.gd) and [ui_touch_tests.gd](../tests/ui_touch_tests.gd), wired into [ui_smoke.gd](../tests/ui_smoke.gd). These include:

- Every hand/installed rune, technique, connector and endpoint description; configured costs/values/ports/stock and profile-specific cleanup; snapshot/RNG/UID/history purity.
- Real `Viewport.push_input` routing for short taps versus holds, exactly-at-threshold motion, scroll cancellation, cancelled release, multiple pointers and emulated touch/mouse suppression. Deterministic timing advances the production hold path; no fragile hold sleeps.
- Modal background blocking, scroll isolation, Close/Escape without click-through, keyboard focus trapping, native Guide scrolling, missing OS release after focus loss and fresh input recovery.
- Legal incomplete placement versus protected/exhausted targets, replacement/refund/Undo labels, endpoint direction and Undo, selection cancellation, technique energy/history boundaries and a validated 14-card hand scrolled to its last item.
- Busy presentation, late callbacks, turn/reset/Exact replay/encounter entry, historical experiment relaunch with synchronous cancellation reentry, scene teardown and safe invalid-content startup.
- Details / Pass consequence confirmation, exactly one accepted Pass, and stale confirmation rejection after Restart.

Intermediate evidence is retained. [Integration run 01](../output/qa/rc-008/integration-smoke-01.log) had nine assertions failing on changed inventory/endpoint feedback wording; restoring compatible wording with clearer reasons fixed them, and [run 02](../output/qa/rc-008/integration-smoke-02.log) passed all then-integrated 421 checks. Subsequent checks caught narrow-screen row overflow; navigation wrapping and responsive board sizing fixed it. A hidden native Guide label still contributed a large minimum height; limiting its visible lines and rendering the body in a scroll container fixed the [reviewed Guide](../output/qa/rc-008/guide-scroll-02.png). Visual review also shortened the narrow Cancel label and moved placement markers beside, rather than over, End's value. The final 503-check rerun and fresh rendered suite include these fixes.

### Rendered interaction evidence

Ran the pinned executable separately with `--path . --script res://tests/ui_touch_capture.gd` and a dedicated RC-008 log path. [Final rendered log](../output/qa/rc-008/touch-render-final-02.log): **82 synthetic touch UI/capture checks / 0 failures**, exit 0. This repeats the **73** scene interaction checks and adds **nine screenshot-save checks**; it is not 82 extra unique tests beyond the UI suite. Earlier restricted rendered runs reported a shader-cache access warning; the final normal-access rendered run does not. The deliberate missing-content diagnostic remains expected.

The following final states were visually inspected. The controlled scene uses a valid deterministic setup with both card types for repeatable inspection; the 14-card hand is an explicitly validated QA fixture, not a changed production opening. Ordinary standalone launch is separately captured above.

| State | Final evidence |
| --- | --- |
| Selected tool, eligible `+` cells and protected `x` endpoints | [720×1600 preview](../output/qa/rc-008/touch-capture-1791519954-3060/selected-tool-preview.png) |
| Selected/rotated Begin, direction feedback and actual editing availability | [Endpoint](../output/qa/rc-008/touch-capture-1791519954-3060/selected-rotated-endpoint.png) |
| Rune cost, ports and ownership/cleanup explanation | [Rune inspector](../output/qa/rc-008/touch-capture-1791519954-3060/inspect-hand-rune.png) |
| Technique effect/payment and explicit inspection safety | [Technique inspector](../output/qa/rc-008/touch-capture-1791519954-3060/inspect-hand-technique.png) |
| Exhausted stock, legal same-kind replacement and rejected new placement | [Unavailable stock](../output/qa/rc-008/touch-capture-1791519954-3060/unavailable-stock.png) |
| Larger hand, visible horizontal scrollbar and selected last card | [14-card hand](../output/qa/rc-008/touch-capture-1791519954-3060/large-hand-scrolled.png) |
| Small viewport with board/edit controls fitting horizontally | [360×640 board](../output/qa/rc-008/touch-capture-1791519954-3060/small-portrait-board.png) |
| Small inspector with independent content scrolling and fixed Close | [360×640 inspector](../output/qa/rc-008/touch-capture-1791519954-3060/small-portrait-inspector.png) |
| Explicit enemy consequence and separate Pass confirmation | [Pass confirmation](../output/qa/rc-008/touch-capture-1791519954-3060/pass-confirmation.png) |

The normal 450×1000 preview preserves the substantial enemy arena and compact name/symbol/value cards. Extra editing rows remain labeled and reachable; the small viewport scrolls vertically, so not every area is visible simultaneously. Inspector content and background scrolling are separated. No permanent forecast strip, production artwork or screen redesign was added.

### Preservation and limits

The [preservation audit](../output/qa/rc-008/preservation-results.json) verifies **506 / 506** pre-existing output/evidence, asset and content file hashes unchanged against the [pre-edit manifest](../output/qa/rc-008/preservation-before.json). This includes the approved reference images, historical captures, experiment definitions and previous raw evidence. Launcher logs at their old fixed filenames were preserved through pre-run copies and restored after verification; all new evidence is separately named. No historical human finding was rewritten or inferred.

The computer-use skill was used to attempt native Windows testing. Input injection failed as recorded above; manual native interaction remains unverified. **All touch acceptance here is synthetic desktop input plus rendered QA. No physical touch device was available**, and no mobile packaging, SDK installation, OS/device minimum, safe-area acceptance or device usability result is claimed. Physical gesture feel, text scaling and platform lifecycle remain RC-021/RC-022 and their later acceptance tasks, including RC-023/RC-044. The existing Android build-tools warning is a platform setup limitation, not a failed desktop gameplay check.

The initial discovery command included one read-only `git status --short` before the pasted no-Git restriction was read. It returned no changes and was disclosed immediately; no subsequent Git operations, commit or checkpoint occurred. The owner retains Git responsibility.

Next-ready: **RC-009**, independently available **RC-010**, **RC-024** and **RC-033**, with platform access still conditional as recorded in the [current plan](project-plan.md).

Documentation QA checked six updated documents and 342 relative file links, with zero missing targets (output/qa/rc-008/document-links.json). This checks file existence, not Markdown anchors.

## October 9, 2026 — RC-009 board identities and construction examples

**RC-009 complete.** The [board catalog](board-catalog.md) distinguishes four stable identities, a sampled runtime layout and an authored example. All four identities use the same accepted random geometry, costs, starter resources and three equally probable finite kits. They do not create different mechanical difficulty. Normal launch remains the existing production encounter. Four clearly labeled development encounters reuse the existing Shadeling/starter catalogs; no final enemies, tower progression, environment art or lighting were added.

### Fresh baseline and environment

Read the applicable project/parent instruction locations (no `AGENTS.md` found), requested design/rules/architecture documents, latest RC-007/RC-008 handoffs, current production data, model/controller/circuit code and existing tests/launcher before implementation. Inspected test/capture output behavior; legacy helper suites use unique paths, while new RC-009 logs, scripts, reports and captures use `output/qa/rc-009/`. Archived fixed-name launcher logs before the baseline and restored them after verification. A pre-edit manifest recorded **897 existing output/evidence, asset and content hashes**.

| Baseline command | Actual result |
| --- | --- |
| `.\tools\godot.ps1 -Action import` | Exit 0; restricted `user://` access error and existing Android build-tools warning. [Baseline import](../output/qa/rc-009/baseline-import.log). |
| `.\tools\godot.ps1 -Action test` | **1063 checks, 0 failures**, exit 0. [Baseline core](../output/qa/rc-009/baseline-test.log). |
| `.\tools\godot.ps1 -Action smoke` with normal local user-directory access | **503 UI checks, 0 failures**, exit 0. Expected missing/invalid-content diagnostics. [Baseline UI](../output/qa/rc-009/baseline-smoke.log). |

A [normal-access import retry](../output/qa/rc-009/import-normal-access.log) exited 0 with only the existing `Unable to open Android 'build-tools' directory` warning. The restricted user-directory message was an environment limitation, not a gameplay regression. No engine upgrade or mobile SDK installation occurred.

### Final required commands

Run separately in PowerShell from `C:\Dev\RuneCast`, with output and exit statuses inspected. `-LogDirectory` is a new optional launcher output path; it prevents replacing the old fixed-name logs. Import/UI/rendering used normal local user-directory access.

| Exact command | Actual final result |
| --- | --- |
| `.\tools\godot.ps1 -Action version -LogDirectory output/qa/rc-009/final-engine` | **4.7.2.stable.official.ed1daf0bf**, exit 0. [Version](../output/qa/rc-009/final-version.log). |
| `.\tools\godot.ps1 -Action import -LogDirectory output/qa/rc-009/final-engine` | Exit 0; existing Android build-tools warning only, no script import error. [Import](../output/qa/rc-009/final-import.log). |
| `.\tools\godot.ps1 -Action test -LogDirectory output/qa/rc-009/final-engine` | **1363 checks, 0 failures**, exit 0. [Core](../output/qa/rc-009/final-test.log). |
| `.\tools\godot.ps1 -Action smoke -LogDirectory output/qa/rc-009/final-engine` | **564 UI checks, 0 failures**, exit 0. [UI](../output/qa/rc-009/final-smoke.log). Deliberately invalid startup diagnostics remain expected coverage. |
| `.\tools\godot.ps1 -Action capture -CapturePath res://output/qa/rc-009/final-production.png -LogDirectory output/qa/rc-009/final-engine` | Screenshot saved, exit 0. [Capture log](../output/qa/rc-009/final-capture.log), [normal production](../output/qa/rc-009/final-production.png). |

The core total retains the original **1063** checks, including all **720 endpoint-pair/kit geometry cases**, and adds **137 catalog checks + 163 example checks**. The UI total retains **503** checks and adds **61 actual-scene board checks**, including reused RC-008 touch controls on the added Belfry identity. These are aggregate assertion counts; the 720 geometry cases and seeded comparisons are not extra checks to add to the reported total.

Catalog coverage verifies all four actual encounter references, the preserved development-only board, malformed/invalid/duplicate/missing definitions, no prefills/obstacles/alternate ports, endpoint-only entries, controller rejections and detached reads. Per identity, **64 seeds** compare first entry, Pass and two continuing-stream Restarts against ordinary production, including altered legal template coordinates and presentation strings, with identical endpoint/card/kit outcomes and all three RNG states. A validated one-HP predecessor isolates successful encounter entry into each identity, preserving current/max HP and each permanent UID; it does not claim ordinary starter victory.

Each example uses a naturally generated starter setup and actual controller commands. Assertions cover every command's acceptance, finite-stock conservation, rotation/Flip, replacement/Undo, physical cost, aggregate damage/shield, ordered cleanup, permanent UID conservation, temporary expiry, exact next-turn resources, and rejected actions preserving state/RNG. Seeds **294 / 39 / 474 / 2149** are recorded authoring choices; there is no runtime search/reroll, extra card/stock, debug state mutation or changed difficulty. The [standalone run](../output/qa/rc-009/authoring/example-tests-01.log) passes **168 checks, 0 failures**, exit 0: the 163 checks above plus four report replays and one report-file check. Its [machine-readable report](../output/qa/rc-009/examples-1791523071-37904-420274/report.json) contains exact commands and outcomes.

### Rendered board and interaction evidence

Executed the pinned engine with `--path . --log-file C:\Dev\RuneCast\output\qa\rc-009\final-board-render-engine.log --script res://tests/ui_board_catalog_capture.gd`. The [rendered run](../output/qa/rc-009/final-board-render.log) passes **80 checks, 0 failures**, exit 0: **61 repeated scene checks plus 19 screenshot saves**, not 80 extra unique cases. All four scenes open their natural endpoints-only setup, execute the authored commands and the actual Cast button, then display cleanup/new turn. Belfry additionally runs synthetic touch inspection, endpoint selection/Rotate/Undo, stock exhaustion/refund and small-screen page/inspector/Guide scrolling.

Representative captures visually inspected:

| State | Evidence |
| --- | --- |
| Normal production remains Training Crypt | [450×1000 normal launch](../output/qa/rc-009/final-production.png) |
| Added identity with natural endpoints-only opening | [Belfry opening](../output/qa/rc-009/board-capture-1791523199-18876/board_belfry-opening.png) |
| Introductory rune route | [First Circuit built](../output/qa/rc-009/board-capture-1791523199-18876/board_training-built.png) |
| Longer route with Spark/Shield | [Long Gallery built](../output/qa/rc-009/board-capture-1791523199-18876/board_gallery-built.png) |
| Turning/reversal route | [Ossuary Turn built](../output/qa/rc-009/board-capture-1791523199-18876/board_ossuary-built.png) |
| Branching with finite Split/Join, 12 damage and Cast2 | [Belfry built](../output/qa/rc-009/board-capture-1791523199-18876/board_belfry-built.png) |
| Complete cleanup, moved endpoints, new hand and full kit | [Belfry turn2](../output/qa/rc-009/board-capture-1791523199-18876/board_belfry-turn2.png), [Gallery turn2](../output/qa/rc-009/board-capture-1791523199-18876/board_gallery-turn2.png) |
| Read-only rune details on an added identity | [Belfry Shield inspector](../output/qa/rc-009/board-capture-1791523199-18876/belfry-touch/inspect-hand-rune.png) |
| Zero stock and unavailable placement feedback | [Belfry exhausted Straight](../output/qa/rc-009/board-capture-1791523199-18876/belfry-touch/unavailable-stock.png) |
| Reachable editing and independent inspector scrolling | [360×640 board](../output/qa/rc-009/board-capture-1791523199-18876/belfry-touch/small-portrait-board.png), [360×640 inspector](../output/qa/rc-009/board-capture-1791523199-18876/belfry-touch/small-portrait-inspector.png) |

Titles, stock labels, hands, Cast and bottom controls fit the 720×1600 scenes. The 360×640 scene scrolls vertically, with reachable controls and a fixed inspector Close. Vertical connections pass behind some rune labels in the existing renderer, but remain readable. All four identities intentionally share the same current crypt/enemy placeholder visuals; no distinct environment treatment is claimed.

The documented wrapper was also exercised directly:

```powershell
.\tools\godot.ps1 -Action capture -BoardExample board_belfry -ExampleStep built -CapturePath res://output/qa/rc-009/launcher-belfry-built.png -LogDirectory output/qa/rc-009/launcher-built-engine
.\tools\godot.ps1 -Action capture -BoardExample board_gallery -ExampleStep cast -CapturePath res://output/qa/rc-009/launcher-gallery-cast.png -LogDirectory output/qa/rc-009/launcher-cast-engine
```

Both saved screenshots and exited 0: [Belfry log](../output/qa/rc-009/launcher-belfry-built.log), [Gallery log](../output/qa/rc-009/launcher-gallery-cast.log). The catalog provides all four ordinary fixture and example-launch commands, plus standalone report/render runners. Normal startup does not load example metadata or auto-build.

### Fixed findings, preservation and limits

Intermediate failures remain visible. The first isolated catalog run had a GDScript inferred-type parse error, corrected before [137 passing checks](../output/qa/rc-009/board-catalog-02.log). The first authoring probe found an incorrectly oriented Ossuary corner; corrected commands produced all four expected results before the witness JSON was finalized. [Scene integration01](../output/qa/rc-009/ui-board-integration-01.log) rejected all four opening facts because JSON parsing represented whole numbers as floats and nested exact comparisons were type-sensitive. The helper now normalizes whole JSON numbers at the validation boundary while retaining full expected-state comparison. [Integration02](../output/qa/rc-009/ui-board-integration-02.log) passes 61 checks/0 failures. Independent review also added type guards for malformed version/setup-kind values. These are fixed development findings, not hidden environment failures or weakened historical assertions.

The [preservation audit](../output/qa/rc-009/preservation-results.json) checks **897 prior files: 896 unchanged hashes, one intended modification (`data/production_boards.json`), zero unexpected changes**. It preserves existing screenshots, raw experiment records, approved images and historical data. Fixed launcher logs were restored. A fresh [fingerprint audit](../output/qa/rc-009/fixture-fingerprint-audit.json) reconstructs all **22 historical fixtures at seed42**, with **22 unchanged fingerprints** against the preserved RC-007 map.

Geometry feasibility with a supplied Spark, affordability with a particular hand, ability to win an encounter and human balance/enjoyment are distinct claims. RC-009 proves the first through the reused geometry suite and the second for its four natural samples. It does not prove universal damaging/affordable hands or ordinary encounter victory. Focus can spend scarce energy, a hand can lack damage, and Pass remains the unchanged fallback. All UI/touch evidence is synthetic desktop input and rendered QA. No new human playtest, physical device, packaging or mobile acceptance is claimed; existing Android configuration and later device work remain outstanding.

The initial discovery command included one read-only `git status --short` before the pasted no-Git prohibition had been read. This was immediately disclosed; it changed no files. No subsequent Git operations, staging, commit or checkpoint occurred. The owner retains Git responsibility.

Next-ready tasks: **RC-010** is the next numbered task; **RC-024** and **RC-033** are also ready under the updated [plan](project-plan.md). Future encounter assignments and presentation remain with their owning tasks.

Documentation QA checked **7 updated documents and 443 relative file links**, with zero missing targets (`output/qa/rc-009/document-links.json`). This checks local file/directory existence, not Markdown anchors. A separate plan audit confirms 60 unique task rows and RC-009 checked complete.

## October 9, 2026 — RC-010 asset manifest and production contracts

**Documentation-only completion.** RC-010 expanded the [manifest](asset-inventory.csv), added [consumer mappings](asset-consumers.csv), [audit/schema guide](asset-manifest-guide.md), [production specification](asset-production-spec.md) and [pilot brief](style-pilot-brief.md), and synchronized art direction, README and plan. No runtime files or final art/audio were changed. Prior RC-009 gameplay results remain historical; this task did not rerun Godot or claim device/import acceptance.

### Actual document and manifest checks

The standard-library Python [validator](../tools/validate_asset_plan.py) was run with the available bundled interpreter after the system `python` alias proved inaccessible:

```powershell
& 'C:\Users\nguye\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' tools/validate_asset_plan.py
```

The [final report](../output/qa/rc-010/validation-report.json) records **PASS**, zero validation errors:

| Check | Actual result |
| --- | --- |
| CSV structure and identity | **92 inventory records / 70 consumer records**, valid quoted CSV, unique IDs and required fields. All **16 original IDs** preserved against [original ID capture](../output/qa/rc-010/original-asset-ids.json). |
| Scope mapping | All **52 primary stable roster IDs** mapped; 12 permanent definitions, 1 generated, 5 actors, 4 boards, 6 relics, 8 upgrades, 4 events, 6 services and 6 room types; one currency. Thirteen screen mappings include Home/Combat/Map/Menu. No extra character/biome/currency/track. |
| Ownership/dependencies | All owners refer to the actual **60 task rows**; production prerequisites/integration order checked against the plan; task graph and asset graph acyclic. No unowned required row or duplicate planned production destination. |
| Readiness/paths | Existing sources/current paths/evidence exist; future paths explicitly planned, source-only or external-delivery. No final asset is claimed source-ready, runtime-ready, integrated or device-verified. Current integrated placeholders remain labeled. No resolved production licence claimed. |
| States and specifications | Automated checks cover four common actor states and seven shared UI states plus linked specifications; manual cross-check covers Home save/recovery/replace, Menu Shop/Quit, Map node entry/inspection, finite stock, RC-008 inspector/Pass, rewards/services/events/results and sound states. |
| Links | Updated documentation file targets and local Markdown anchors resolve; each manifest specification reference resolves. Final count is in the report and includes repeated references. External links are not treated as local-file assertions. |
| Preservation | **974 protected files** match [baseline SHA-256 records](../output/qa/rc-010/preservation-baseline.json): runtime assets/scenes/scripts/data/tests, project/export settings, approved/generation history and prior RC-006–RC-009 QA files captured by the baseline. Zero changed protected files. |
| Reference provenance | Four approved images and ten historical PNG/prompt pairs exist. Every approved image differs from its latest generated-study counterpart; report records both hashes. Exact originating approved-image prompt/model and rights remain unknown. |

Inventory counts are **5 reference, 4 pilot, 3 audit, 5 character, 5 environment (one optional foreground), 2 board, 16 icon, 8 UI, 2 typography, 12 progression, 8 animation/VFX, 16 SFX, 1 music pack (two loops), 1 ambience and 4 release**. These are bounded deliverable records, not a count of all files or claims of production assets already present. Readiness is **80 planned, 1 optional planned, 3 placeholder, 3 integrated placeholder, 5 reference-only**.

Independent review found and corrected pilot path differences, missing stone-bowl/desk motifs, overly broad consumer ownership and a potential future-character scale-preview sequencing ambiguity. The final guide/spec agree on 512-square character exports/foot `(256,448)`, 1440×720 aligned crypt layers, 720×1600 Home, 128-square SVG geometry, button/socket slices and source/runtime separation. Sixteen SFX families contain exactly 21 bounded WAV exports; music remains two loops plus one ambience bed.

The validator initially encountered an empty trailing CSV line; its parser now accepts blank lines as valid CSV whitespace. The [initial report](../output/qa/rc-010/validation-initial.json) then reported only its own report path before that output existed. Once produced, the full check passed; this was an output-bootstrap issue, not missing asset evidence. The final rerun includes the completed handoff/verification documentation.

### Visual inspection and acceptance limits

Visually inspected [Home](../output/imagegen/approved/home.png), [Combat](../output/imagegen/approved/combat.png), [Map](../output/imagegen/approved/map.png) and [Menu](../output/imagegen/approved/menu.png), plus [normal production](../output/qa/rc-009/final-production.png), [Belfry construction](../output/qa/rc-009/board-capture-1791523199-18876/board_belfry-built.png), [unavailable stock](../output/qa/rc-008/touch-capture-1791519954-3060/unavailable-stock.png) and [narrow inspector](../output/qa/rc-008/touch-capture-1791519954-3060/small-portrait-inspector.png). Agent review also inspected selected/rotated endpoint and RC-009 touch captures linked in the pilot brief.

The actual controls preserve live finite counts, precise rotated ports, `+`/`x` placement feedback, compact card faces and independently scrolling inspector text with fixed Close. Their current pixel sizes informed proposed contracts; no reference artwork was cropped or treated as production-ready. Current random-endpoint/finite-kit rules supersede the approved Combat reference's historical fixed arrangement and infinity symbols.

RC-011 still must validate the matching style, proposed dimensions/anchors, type direction, alpha, slices and animation feasibility. RC-012 and later producers must acquire source/rights evidence and test imports. Device minima remain unresolved until RC-021/RC-022; RC-023, RC-044 and RC-047–RC-049 own actual touch/layout/lifecycle/performance acceptance. The **32 MiB active art / 48 MiB retained art**, audio, font, effect and package targets are provisional estimates with explicit decoded-memory calculations, not measured usage.

One forbidden read-only `git status --short` was included in initial discovery before the attached request was read and was disclosed immediately. No subsequent Git operation or checkpoint occurred. Runtime/asset/evidence preservation is established by file hashes, not Git. **Next numbered task: RC-011**, the matching Shadeling/Spark/button style pilot.

## October 11, 2026 — RC-011 r001 source and desktop review

**Corrected review: r001 visual fidelity rejected by the owner; revision required.** The [delivery record](../source-assets/pilot/delivery.md) withdraws the earlier matching-style pass. Existing structural checks below remain valid within their stated scope; they do not establish reference fidelity. RC-011 is open for correction, not waiting for confirmation of a new style. Review candidates do not establish Godot integration or physical-device acceptance.

| Verification | Actual evidence/result |
| --- | --- |
| Required files and editability | [Artifact validation](../output/art/rc-011/pilot-validation.json) passes dimensions/modes/sRGB,7/5/14unique nonempty ORA layers, same-canvas512parts, source foot512,896/export256,448, editable SVG text and linked art. Individual generated brush strokes remain flattened; structural layers are genuine |
| Character and motion | [26Shadeling checks — retired in authorized cleanup](asset-cleanup.md), [native white/black alpha — retired in authorized cleanup](asset-cleanup.md), [gray/navy/turquoise/checker alpha — retired in authorized cleanup](asset-cleanup.md), [scale — retired in authorized cleanup](asset-cleanup.md), [motion keyframes — retired in authorized cleanup](asset-cleanup.md). All nonzero motion pixels stay inside68,84–379,459; allowed32–480. Lantern parent transform corrected. sRGB tagging preserved16decoded source/export pixel hashes |
| Geometry and states | [Glyph checks — retired in authorized cleanup](asset-cleanup.md), [glyph sheet — retired in authorized cleanup](asset-cleanup.md), [states — retired in authorized cleanup](asset-cleanup.md), [grayscale — retired in authorized cleanup](asset-cleanup.md).128viewBox, exact edge ports/four rotations;24/32/48glyphs and137/72cells; shared Spark/FreeSpark with separate TEMP; shape-based power/focus/selection/invalid/unavailable/+/x. Fixed path/text collisions before final render |
| Slices and controls | [Material validation — retired in authorized cleanup](asset-cleanup.md) passes source/export composites and fixed corner comparisons at66×50,58high,64high,wideHome and tile137/72/142×92. Both materials share six responsive state overlays; focus+selected/focus+unavailable shown. Labels/hit bounds stay separate |
| Typography | [Actual Godot fallback specimen — retired in authorized cleanup](asset-cleanup.md), [metrics — retired in authorized cleanup](asset-cleanup.md), [font/source/licence record — retired in authorized cleanup](asset-cleanup.md). Exact required strings/numerals rendered; long labels fit expanded controls and23px inspector scrolls. Noto candidates remain provisional/unacquired; current fallback OpenSansSemiBold is not silently adopted for production |
| Catalog and layout | [Main720 — retired in authorized cleanup](asset-cleanup.md), [actual450reduction — retired in authorized cleanup](asset-cleanup.md), [native360 — retired in authorized cleanup](asset-cleanup.md), [lower controls — retired in authorized cleanup](asset-cleanup.md), [fixedClose inspector — retired in authorized cleanup](asset-cleanup.md), [endpoints-only — retired in authorized cleanup](asset-cleanup.md). Trainingseed294built witness0→1→2,cost2/damage6,stock4/2/2/2,correct live values/hand. Narrow study keeps72px cells/scroll boundaries |
| Manifest and preservation | Existing [asset-plan validator](../tools/validate_asset_plan.py) passes; current [report](../output/art/rc-011/asset-plan-validation.json) retains974protected hashes unchanged. [Wrapper — retired in authorized cleanup](asset-cleanup.md) restores the original RC-010 report bytes. Only fourpilot rows changed; [record](../output/art/rc-011/manifest-update.json). No final assets promoted |
| Memory | [Dimension inventory](../output/art/rc-011/pilot-validation.json): conservative10.875MiB RGBA8/rasterizedSVG candidates; source/review/master/font/engine allocations excluded. This is not compressedPNGbytes or device residency |

All four approved images and required runtime captures were inspected; [context audit — retired in authorized cleanup](asset-cleanup.md) records them. [Reference comparison — retired in authorized cleanup](asset-cleanup.md) uses complete originals only as labelled comparisons. The main composition identifies environment and non-Spark symbols as placeholders.

Motion delivery uses the brief's allowed48PNGframes at8fps/6seconds, with [timing](../output/art/rc-011/pilot-motion-timing.json) and [GIF playback — retired in authorized cleanup](asset-cleanup.md); no available PATH encoder, noMP4claim. Reduced motion is static/opacity with the same labelled sequence. No combat consequences or event integration are implemented.

Commands run: `source-assets/pilot/validate_pilot.py`, the unchanged `tools/validate_asset_plan.py` through `source-assets/pilot/run_asset_plan.py`, local material/Shadeling/glyph validators, and isolated typography rendering. No gameplay suite was run because runtime/gameplay code was unchanged. No owner approval, r001 Noto-package clearance, pilot Godot imports, final pose production, physical touch, safe areas or device-memory/performance result is claimed. RC-011 must correct reference fidelity before dependent production adopts the pilot; later integration/device checks retain their original owners.

### RC-011 r002 corrective review

[Delivery](../source-assets/pilot/revisions/r002/delivery.md) records the owner rejection and actual correction sources. The [r002 artifact report](../output/art/rc-011/r002/revision-validation.json) passes509checks, including sevenactor layers, all six revised UI ORA composites, aligned512parts, anchors, all96paired motion bounds, editable text/linked resources, exact ports and actual raw/font/reference hashes. All nonzero motion alpha stays33,83–418,461 within32–480. Noto Serif 2.015 is actually acquired/rendered with its official OFL retained; the former fallback-only result is not represented as a serif appearance test.

Visually inspected the actual720/450/native360, states/alpha, type and motion exports. Corrected selected-notch/label overlap, native glyph-size captions and ambiguous Begin/End placeholders; moved the blockout annotation clear of health. Character proportions/scale, large amber Spark, stronger bevels, pointed Cast and serif lettering are closer to the reference. **Visual result remains revise for full reference appearance; structural pass is not aesthetic acceptance.** Runtime, approved references and prior raw evidence remain unchanged; no gameplay rerun or Git operations occurred during this correction.

### October 11, 2026 — official final gameplay visual

The owner explicitly selected the supplied complete image as official and expanded the preview scope to include crypt/supporting UI without placeholders. [Final canonical PNG](../output/imagegen/approved/combat-final.png) and [review copy — retired in authorized cleanup](asset-cleanup.md) are byte-identical to the841×1870RGB attachment, SHA-256 `c753021b16fbe7af9fa57cadae5d32525f9283dbc1da0af883b8614965af2da4`. [Image verification](../output/art/rc-011/r003/final-reference-validation.json) also confirms identical decoded pixels to preserved v7Remove and974protected files unchanged. No regeneration, image editing, cropping or resizing was necessary: the attachment already contains all requested visible changes.

Root and independent review verified undirected board/tool connections; only Remove/Rotate editing actions; left Draw/right Discard piles; the damage/shield/cost/incoming bar above Cast; and the full painted crypt, character, supporting UI and navigation without placeholders. The [new contract](gameplay-visual-contract.md) records owner-approved design direction separately from unchanged runtime behavior. BOSS, infinity stock and sample numbers are not silently adopted as mechanics.

[Asset-plan checks](../output/art/rc-011/r003/asset-plan-validation.json) and [delivery/link checks](../output/art/rc-011/r003/delivery-validation.json) pass. The validator now permits additional historical prompt/image pairs beyond the original10 while still protecting original files by exact hashes and requiring a matching PNG for every prompt;12pairs are present. The historical RC-010 report is restored byte-for-byte by the [r003 wrapper — retired in authorized cleanup](asset-cleanup.md). Only reference_combat/reference_history manifest rows changed during final-reference adoption; production assets were not promoted. No gameplay tests or Git operations were run. Final visual-image request complete; editable production layers and undirected runtime implementation remain separate work.

### October 11, 2026 — RC-011 r004 expanded source and visual review

The [r004 delivery](../source-assets/pilot/revisions/r004/delivery.md) completes the expanded asset/preview scope. Four new selected built-in-imagegen paintings supply clean crypt, empty tile, navy panel and Cast; five raw image/prompt pairs are retained including an unused actor alternative. The selected r002 actor, genuine seven-part source, font/OFL and48-frame motion remain unchanged. The crypt has seven semantic layers; tile/buttons separate actual painted face/rim regions; the full SVG keeps text, icons and connections editable. No reference screenshot crop replaces the gameplay screen.

Root and independent reviewers inspected the actual841/720/450main, native360board/controls, button/grayscale/tile states, type and retained motion. They corrected clipped location text, missing infinity/scroll glyphs, TEMP/value and JOIN/path collisions, missing narrow wiring/piles, thin/flat frames, vertically stretched board artwork, hand-frame colours and powered/unpowered shape cues. The final screen follows the complete approved hierarchy with undirected paths, only Remove/Rotate editing, detailed hand, draw/discard piles and forecast above Cast. Remaining differences are reconstruction brushwork, vector pictograms and the evidenced Noto Serif substitute; exact pixel identity and owner acceptance are not inferred.

Commands: `source-assets/pilot/revisions/r004/build_crypt.py`, `record_generation.py`, `build_review.py`, `update_manifest.py`, and `validate_revision.py --asset-plan`. The final [artifact/source report](../output/art/rc-011/r004/revision-validation.json) and [asset-plan report](../output/art/rc-011/r004/asset-plan-validation.json) both pass; their exact check totals are recorded in those reports. Checks cover actual canvas/colour/alpha, distinct ORA layers and exact recomposition, linked/editable SVGs, native geometry/state coverage, actual font coverage/licence hashes, retained generation prompts/hashes, anchors/motion envelope and import exclusions.974original protected files and238prior revision/reference files are unchanged; historical RC-010 report bytes are restored after validation.

Only the four pilot inventory records were reconciled (`source_ready`, `source_only`, `reference_guided`); all other rows remain byte-for-byte unchanged. Selected canonical PNGs total15,465,720RGBA8bytes (14.74926MiB) with neutral plus seven actor parts, or8,125,688bytes (7.74926MiB) for the static subset. Additional variants, SVG/font/state/engine surfaces are excluded; this is not a full game/device measurement. The full seven-layer crypt editing stack alone is about42MiB and is not a runtime loading instruction.

**RC-011 production and assistant review complete.** No gameplay suite was rerun because runtime assets/code/rules/scenes remain untouched. No Git operations occurred in r004. Godot importing/themes, playable undirected evaluation and controls, owner approval of reconstructed art, physical-device readability/input and memory remain separate. RC-012 is the next numbered task using r004 and the unchanged official visual target.

### October 11, 2026 — RC-011 r006 latest approved board changes

The [r006 delivery](../source-assets/pilot/revisions/r006/delivery.md) applies final v2 to actual editable sources and regenerated841/720/450main, native360board/controls and state/type exports. Root and independent visual review verified BEGIN/END-only board text, removal of board names/values/cost badges/TEMP, shared corrected fork/trident silhouettes and preserved external cards/stock/piles/forecast. No placeholder crypt or supporting symbols remain. Main BOSS is retained, matching the supplied pixels; an erroneous current-document sentence claiming its absence was corrected.

Commands: `source-assets/pilot/revisions/r006/build_review.py`, `update_manifest.py` and `validate_revision.py --asset-plan`. The [source audit](../output/art/rc-011/r006/revision-validation.json) inspects actual board XML groups rather than relying only on metadata. It also checks linked resources, actual font coverage, source dimensions/alpha/ICC, distinct ORA layer recomposition, current/retained dependency paths and hashes, motion bounds and import exclusions. [Asset-plan checks](../output/art/rc-011/r006/asset-plan-validation.json) cover the92-record manifest and document links. Final totals and outcomes are in those reports.

Initial source-audit failures concerned report links not yet written; the completed run resolves those links. A retained dependency-path typo was corrected before the final audit. All974original protected files and404prior revision/reference snapshot files remain unchanged, and the historical RC-010 report is restored byte-for-byte. Only four pilot rows were reconciled. No new generation was used; byte-preserved r004 paints and r002 actor/font/motion retain their original provenance.

**RC-011 is complete for pilot production and assistant review with the latest changes.** The supplied reference remains the owner-approved target. Reconstructed paint, repeated frames, vector details and Noto typography are not pixel-identical; no owner acceptance of those assets is inferred. Runtime scripts/scenes/rules, playable undirected evaluation, imports and devices are unchanged and untested by this revision. No gameplay suite or Git operation was run.

## October 11, 2026 — RC-012 core symbols and typography

**Pass for source/export delivery and isolated Godot imports/rendering.** The final [delivery audit](../output/qa/rc-012/validation-report.json) passes 939 checks, covering 278 preserved files, 24 SVG pairs, nine actual sheets, 387 live text measurements and 96 imported rotation cases. The [independent visual review](../output/qa/rc-012/visual-review.json) passes all nine exact PNG hashes. The [usage guide](core-symbols-and-typography.md) links 24 editable vector source/export pairs, one retained Noto Serif 2.015 variable font and three live FontVariation roles. All eight scoped records are runtime-ready. Main gameplay/core/content/theme remain unchanged; these are isolated specimens, not complete-Combat integration or device acceptance.

| Check | Actual evidence/result |
| --- | --- |
| Editable SVG validity and exact geometry | [Symbol source validation](../output/qa/rc-012/symbol_source_validation.json), [alpha bounds](../output/qa/rc-012/symbol_alpha_bounds.json), [rotation geometry](../output/qa/rc-012/symbol_rotation_geometry.json) pass. All 24master/export pairs match; decorative bounds and true cell-edge Straight/Corner are separate. Every quarter-turn is checked. |
| Actual font binary, OFL and coverage | [Font validation](../output/qa/rc-012/font-validation.json) and [Godot font probe](../output/qa/rc-012/font-godot-probe.json) pass: retained Noto Serif 2.015 unchanged, weight 500/600/700 and width 100 verified on actual render RIDs, required glyphs present and labels use tabular digits. Godot keys are `weight`/`width`, not raw SFNT tags. System fallback is off. |
| Actual Godot imports/render | [Import log](../output/qa/rc-012/godot-import.log), [render log](../output/qa/rc-012/godot-render.log), [render results](../output/qa/rc-012/godot-render-results.json): PASS; Godot 4.7.2, GL Compatibility, Windows NVIDIA GeForce RTX 5070 Ti. 24 SVG textures are 256² with no mipmaps. Actual imported edge-alpha checks cover four turns, with no decorative edge contacts. No missing resources, SVG/font/script errors or measured text-fit failures in final output. |
| Actual visual/state sheets | [Symbols](../output/art/rc-012/symbols.png), [states/rotations](../output/art/rc-012/states-and-rotations.png), [72px rotations](../output/art/rc-012/rotations-72.png), [action states](../output/art/rc-012/action-states.png) and [typography](../output/art/rc-012/typography.png) inspected. Colour and grayscale remain distinct on indigo/painted stone/parchment; Sound on/off shape, card-only Free Spark distinction, four turns, clean-board endpoint text and state cues are present. |
| Actual layout sizes | [720×1600](../output/art/rc-012/layout-720x1600.png), [450×1000](../output/art/rc-012/layout-450x1000.png), [native360×640](../output/art/rc-012/layout-360x640.png), [native card companion](../output/art/rc-012/layout-360x640-cards.png) inspected. Detailed card types/effects, values/numerals, forecast, piles, Remove/Rotate and navigation fit; native360 is a separately arranged layout. |
| Manifest, links and task ownership | [Asset-plan report](../output/qa/rc-012/asset-plan-validation.json) checks 92 assets/73 consumers, all 16 original asset IDs, original 60 tasks plus distinct RC-016A, acyclic dependencies and current clean-board/control coverage. [Six focused parser cases](../output/qa/rc-012/task-id-validation.json) pass numeric ranges and suffix separation. Historical RC-010 report is preserved. |
| Preservation and source exclusion | [Delivery validation](../output/qa/rc-012/validation-report.json), [before hashes](../output/qa/rc-012/preservation-before.json) record retained source/reference/runtime preservation. The only export configuration additions are `source-assets/*` exclusion and explicit font OFL/attribution inclusion in both presets. Removing those exact additions reproduces the protected original hash; unrelated changes still fail validation. |

Actual-render review prompted fixes before final captures: Straight/Corner normalized width 8 for 24/32px visibility, independent rotated endpoint ports with upright check/diamond and label clearance, wrapped detailed card text, and two-tone grayscale preserving internal shapes on parchment. Conjure/Draw-pile fine details soften at 24px; use 32/48px when those details matter and retain live labels. 24 SVGs at 256² RGBA8 total 6 MiB decoded; this excludes dynamic font atlases, engine buffers and preview surfaces, and is not a measured device allocation.

The engine logs include host `user://` directory, shader-cache and root-certificate-store warnings; these are recorded environment limitations, not missing asset or script failures. No font substitution, glyph fallback or SVG import errors were observed in final checks.

Commands: `.\tools\preview_core_assets.ps1` for the isolated import/render; `python .\tools\validate_core_assets.py` for [delivery checks](../tools/validate_core_assets.py); `python .\tools\validate_asset_plan.py --report output/qa/rc-012/asset-plan-validation.json` for manifest/link/dependency checks. Focused font, geometry, alpha and rotation checks are linked above. The preview stages exact production copies under excluded `output/qa/rc-012/preview-project`. No global theme or normal launch change is made. No gameplay suite was rerun; the only shared settings edit concerns source exclusions and font licence packaging.

## October 12, 2026 — RC-013 reusable theme and wordmark

**Pass for production and isolated desktop source/import/render/layout verification.** The [UI theme guide](ui-theme.md) records the nine owned manifest packs, seven meaningful multi-layer ORAs,26 texture exports, original editable wordmark, Theme resources and reusable live Control factories. [Source validation](../output/qa/rc-013/source-validation.json) passes 253 checks. [Focused delivery validation](../output/qa/rc-013/validation-report.json) passes 1,795 checks, including547 protected files,83 exact staged-resource identities and793 live-text measurements across34 actual Godot sheets. These are presentation specimens, with no main-game integration or device acceptance.

| Check actually performed | Evidence and result |
| --- | --- |
| Editable source and source/export integrity | [Source report](../output/qa/rc-013/source-validation.json) and [source/export map](../source-assets/ui/source-export-map.json): seven ORAs with distinct semantic layers, named-layer export recomposition, retained layer pixels/hashes, masks, RGBA8/sRGB/alpha dimensions, internal-only vector dependencies and wordmark SVG/ORA correspondence pass. The1024×384 wordmark retains at least32px transparent padding on all sides. No reference screenshot crop or new generated artwork was used. |
| Actual Godot imports/resources/fonts | [Import log](../output/qa/rc-013/godot-import.log), [render log](../output/qa/rc-013/godot-render.log), [render results](../output/qa/rc-013/godot-render-results.json): Godot4.7.2 GL Compatibility on Windows NVIDIA GeForce RTX5070Ti. All26 RC-013 texture exports load at documented sizes, RC-012 resources remain unchanged, actual font RIDs select700/600/500 at width100, resource dependencies resolve and staged bytes match delivered files. |
| Painted construction and required states | [Full state sheet](../output/art/rc-013/states-full.png), [detailed cards](../output/art/rc-013/cards-full.png), [native controls](../output/art/rc-013/components-bottom-360x640.png): sculpted gold/materials, intact primary tips, separate live costs/name/type/effect/value slots, finite stock, empty/populated piles, forecast, valid/invalid/unaffordable Cast, temporary/upgraded card variants, Sound states and combined focus treatments inspected. Source geometry and dynamic text remain separate. |
| Requested output sizes | [720×1600](../output/art/rc-013/components-720x1600.png), [450×1000](../output/art/rc-013/components-450x1000.png), [native360×640](../output/art/rc-013/components-360x640.png), [native hand/detail overflow](../output/art/rc-013/cards-native-bottom.png): no final measured label overflow, absent resource or broken target minimum.720 is a1.6× rendering of the450 logical construction; native360 reflows and scrolls independently. |
| Four screen families and shared dialogs | [Home](../output/art/rc-013/home-save-360x640.png), [no save](../output/art/rc-013/home-empty-450x1000.png), [invalid save](../output/art/rc-013/home-invalid-450x1000.png), [replace confirmation](../output/art/rc-013/replace-360x640.png), [Menu available — retired during cleanup](asset-cleanup.md#october-13-2026--project-wide-follow-up-cleanup), [Menu unavailable — retired during cleanup](asset-cleanup.md#october-13-2026--project-wide-follow-up-cleanup), [Map](../output/art/rc-013/map-360x640.png), [Options](../output/art/rc-013/options-360x640.png), [long detail](../output/art/rc-013/dialog-360x640.png): all requested presentation states exist. Map uses neutral RC-012 samples; no RC-041 map/content library or RC-015 Home painting is implied. |
| Actual control behavior | [Render interaction results](../output/qa/rc-013/godot-render-results.json): transparent pointed-edge click still activates the full rectangular Button once; actual focused keyboard action invokes the callback; unavailable suppresses activation; long modal body scrolls and Close remains visible. Decorative children ignore pointer input. Forced focus/unavailable is visual state coverage, since disabled Buttons are not ordinary tab targets; integration still owns an inspectable unavailable-item flow. |
| Clean board and endpoint identity | [Independent endpoint check](../output/qa/rc-013/endpoint-identity-review.json) confirms native Begin check versus End diamond, distinct SVG/import identities and actual screenshot diamond geometry. Only BEGIN/END text appears on sockets. No retired editing icons, board cost/value/TEMP labels or directional-arrow strokes were added. |
| Packaging and preservation | [Focused delivery audit](../output/qa/rc-013/validation-report.json), [547-file baseline](../output/qa/rc-013/protected-baseline.json) and [asset-plan audit](../output/qa/rc-013/asset-plan-validation.json) pass preservation and source exclusions. Existing export presets already exclude source-assets/output/tools and include RC-012 font licences; they were not changed. Main project/settings/scenes/gameplay/content, approved references, retained pilot originals and prior QA remain preserved. |

The [independent visual review](../output/qa/rc-013/visual-review.json) hashes21 final captures and six retained references, with no remaining blocker for reference-guided isolated presentation. Review corrected early Map caption character-wrapping, missing slider tracks, card content growth, forecast layout, endpoint text clearance, pointed Cast sizing and staged resource mismatches before the recorded final pass. The [native eight-card hand-end capture](../output/art/rc-013/cards-native-hand-end.png) and actual horizontal-scroll check verify access to the last starter-card instance. The [interactive gallery launch](../output/qa/rc-013/interactive-gallery.log) also passes; its scene remains in the isolated project. The [four-screen contact sheet — retired during cleanup](asset-cleanup.md#october-13-2026--project-wide-follow-up-cleanup) is a derived combination of unmodified actual native screenshots, separate from the34 Godot render count. The final logs contain no script/resource/import/layout failure. The host emits `user://`/shader-cache and root-certificate-store diagnostics; the validator records those specific environment messages separately. No SDK installation, engine upgrade, mobile export or gameplay-suite rerun was necessary for the isolated resource/component work.

The26-export dimensional estimate is4.75MiB decoded; the theoretical unique-pixel subtotal is4.25MiB, with explicit shared-resource caveats for identical socket/panel/pile files. RC-012 glyphs, dynamic font atlases and engine/preview buffers are separate. No GPU resident-memory or physical-device measurement is claimed.

Readiness remains accurate: `board_cells`, `ui_frames`, `button_frames`, `rune_frames` and `ui_bars` have existing technically verified runtime exports but retain `source_ready` and inherited unresolved paint rights. Original `ui_state_overlays`, `ui_dialog_scrim`, `ui_theme` and `wordmark` are `runtime_ready`; assembled-theme readiness does not clear its painted dependencies for release. Supplied-reference approval does not approve reconstructed production art. RC-050 owns later distribution-rights reconciliation, RC-016/RC-042 own integration, and RC-016A remains the explicit prerequisite for the undirected evaluator/control migration and unresolved no-cast/inspection decisions.

Commands actually used: `.\tools\preview_ui_theme.ps1`; `python .\tools\build_ui_assets.py --validate --report output/qa/rc-013/source-validation.json`; `python .\tools\validate_ui_theme.py`; `python .\tools\validate_asset_plan.py --report output/qa/rc-013/asset-plan-validation.json`, using the bundled Python executable where required. Historical evidence was preserved in its original locations. One initial read-only Git status call occurred before the pasted restriction was read and was disclosed during the task; no subsequent Git operation or checkpoint was performed.

Process limitation: one read-only `git status --short` command ran during initial discovery before the attachment restriction was read and was disclosed to the user. No subsequent Git operation or checkpoint was performed. This did not modify repository content; preservation is established by hashes.

Current directed mechanics and retired controls remain an implementation baseline. [RC-016A](project-plan.md#rc-016a--undirected-evaluator-and-control-migration-gate) owns undirected evaluation, aggregation/cycles/repeat triggers, no-cast turn ending and revised controls before full RC-016. No integration, physical-device result, exact-reference reconstruction or owner approval of newly prepared components is claimed. **Next numbered task: RC-013**, the reusable UI theme.
