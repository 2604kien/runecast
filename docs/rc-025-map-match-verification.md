# RC-025 — Map reference correction

October 21, 2026 (Australia/Sydney). The live Map now follows the approved screen's composition: stone surroundings, framed health/Gold/depth, a dominant torn parchment with side architecture, its title and subtitle inside the paper, an icon-based route, a separate encounter hint, and the framed Menu/Map/Guide/Sound bar. The earlier [RC-025 delivery and evidence](rc-025-verification.md) remain retained. No Git commands or native platform setup/builds were performed during this correction.

**Later October 21 navigation follow-up:** Combat and Map now share the same 82-pixel bar and identical button/icon/caption geometry. [Shared-navigation verification](rc-025-shared-navigation-verification.md) contains the current focused comparisons and resource audit; the captures below retain this earlier Map-composition correction.

## Reference and actual result

The comparison images are rendered by Godot from two separate textures: the untouched approved image on the left and the actual live viewport on the right. Each side uses the approved image's native 841×1870 dimensions. The reference is read only by the excluded capture test; it is not a runtime background.

- [Approved versus active third room](../output/qa/rc-025-map-match/screenshots/approved-vs-live-current-depth3.png)
- [Approved versus three completed rooms and available successors](../output/qa/rc-025-map-match/screenshots/approved-vs-live-frontier-depth3.png)
- Fresh production route: [841×1870](../output/qa/rc-025-map-match/screenshots/fresh-route-841x1870.png), [720×1600](../output/qa/rc-025-map-match/screenshots/fresh-route-720x1600.png), [450×1000](../output/qa/rc-025-map-match/screenshots/fresh-route-450x1000.png), [360×640](../output/qa/rc-025-map-match/screenshots/fresh-route-360x640.png)

Visual review checked the final comparisons, full portrait composition, narrow scrolling, inspection, confirmation, Menu, Options and current guardian. The title and subtitle are separated, ordinary node labels no longer crowd the route, the current node has a turquoise star/ring/ribbon, completed nodes have checks, and available nodes and connections use gold. Unchosen branches are subdued. The footer frame now fills its container, including after responsive layout; this has a capture assertion. At 360×640, the route scrolls while the title, live stats, Close and navigation remain reachable.

The result deliberately shows real model values and topology. Fresh health is 30/30 and Gold is zero; the comparison fixture grants no damage, healing or rewards. Thirteen nodes still form the accepted nine-visit route with a designated Shadeling boss and separate guardian. An active room keeps successors locked, so current and next-choice screenshots are separate. No route-model or content rules changed in this pass. The new artwork and procedural symbols follow the approved direction without claiming to be pixel-identical or final room-art acceptance.

## Assets and navigation

`assets/ui/map/parchment.png` is a newly generated, blank reusable paper surface with quiet crypt architecture at its sides. It was copied directly from the generated original without pixel edits. Text, values, paths, symbols, node states and controls remain live Godot elements. The complete prompt, source location and treatment are recorded in [parchment provenance](../source-assets/ui/map/parchment-provenance.md).

`route_map_node.gd` draws the rings, checkmarks and current-location marker; `route_map_symbol.gd` supplies distinct room symbols; `route_map_canvas.gd` draws connections. `route_map_chrome.gd` supplies small live ornaments and reuses unmarked stone and lower candles from the existing Combat backdrop. Existing wordmark, fonts, frame and navigation assets remain in use. Neither approved Map pixels nor its baked controls are used by runtime code.

Menu opens over the same Map and scroll position. Resume returns to it; Options uses the shared settings screen and Back dismisses one layer at a time. Quit to Home preserves the session. Store is explicitly unavailable. Guide opens the scrolling route explanation. Sound updates the existing owner's setting without replacing the Map, run, Combat coordinator or player. Combat-origin Menu returns to the existing Combat menu. The current node's inspection provides Resume room.

Modal input guards and generation checks cover Close, entry, Menu and Sound callbacks. No new audio coordinator or music track was added. The retained standalone encounter still resumes the exact scene/model and prepared controls; its [prepared](../output/qa/rc-025-map-match/screenshots/battle-prepared-360x640.png) and [resumed](../output/qa/rc-025-map-match/screenshots/battle-resumed-360x640.png) viewport PNGs have identical SHA-256 hashes.

## Final validation

Pinned Godot **4.7.2.stable.official.ed1daf0bf**, Windows Compatibility renderer. Settings/cache locations are isolated under this task's evidence directory. Rendered captures use `--audio-driver Dummy` with Sound visibly enabled, avoiding audible playback while representing the normal control state.

| Coverage | Final result |
| --- | --- |
| Core | **2,223 checks, 0 failures** — [log](../output/qa/rc-025-map-match/core.log) |
| Existing UI | **1,171 checks, 0 failures** — [log](../output/qa/rc-025-map-match/ui.log); deliberate malformed/missing fixtures retain their expected diagnostics |
| Application shell | **97 checks, 0 failures** — [log](../output/qa/rc-025-map-match/shell-tests.log), [assertions](../output/qa/rc-025-map-match/shell-tests.json) |
| Audio | **428 checks, 0 failures** — [log](../output/qa/rc-025-map-match/audio.log) |
| Presentation | **31 checks, 0 failures** — [log](../output/qa/rc-025-map-match/presentation.log) |
| Actual rendered Map/Combat | **664 checks, 0 failures**, **86 PNGs** across 841×1870, 720×1600, 450×1000 and 360×640 — [log](../output/qa/rc-025-map-match/map-capture.log), [assertions](../output/qa/rc-025-map-match/screenshots/results.json) |
| Resource-only PCK | **370 policy/integrity checks and 73 exact-payload desktop decode checks, 0 failures** — [audit](../output/qa/rc-025-map-match/resources/resource-audit.json), [decode log](../output/qa/rc-025-map-match/resources/ios-resource-probe.log) |
| Python resource/workflow/transfer regressions | **32 tests passed** — [log](../output/qa/rc-025-map-match/resources/tool-tests.txt) |

Shell checks cover Menu/Options/Back ordering, unchanged Map identity/scroll and run state, Sound ownership, blocked underlying actions, stale callbacks, and Combat Menu/Sound round trips. Capture checks cover touch target size and nonoverlap, viewport bounds, frame geometry, entry/guardian scrolling, boss/help inspection scroll reset, reachable confirmation actions and preserved Combat preparation.

Current, visited and guardian screenshots use explicitly isolated accepting adapters under `tests/`. They invoke real model entry/completion interfaces but do not demonstrate playable production room content. Normal New Run still reports unavailable entry without mutating the route. No physical-device, full-run, final listening or final art acceptance is claimed.

| Reviewed interaction/state | Actual viewport |
| --- | --- |
| Narrow inspection / confirmation / pending room | [inspection](../output/qa/rc-025-map-match/screenshots/node-inspection-360x640.png), [confirmation](../output/qa/rc-025-map-match/screenshots/entry-confirmation-360x640.png), [pending](../output/qa/rc-025-map-match/screenshots/room-pending-360x640.png) |
| Menu / shared Options | [Menu](../output/qa/rc-025-map-match/screenshots/map-menu-360x640.png), [Options](../output/qa/rc-025-map-match/screenshots/map-options-360x640.png) |
| Test-only boss / visited / locked | [boss](../output/qa/rc-025-map-match/screenshots/fixture-boss-inspection-360x640.png), [visited](../output/qa/rc-025-map-match/screenshots/fixture-visited-inspection-360x640.png), [locked](../output/qa/rc-025-map-match/screenshots/fixture-locked-inspection-360x640.png) |
| Test-only active guardian | [841×1870](../output/qa/rc-025-map-match/screenshots/fixture-current-guardian-841x1870.png), [360×640](../output/qa/rc-025-map-match/screenshots/fixture-current-guardian-360x640.png) |
| Narrow route at both ends | [entries](../output/qa/rc-025-map-match/screenshots/route-entry-end-360x640.png), [guardian](../output/qa/rc-025-map-match/screenshots/route-guardian-end-360x640.png) |
| Actual Combat Map / Resume inspection | [Map](../output/qa/rc-025-map-match/screenshots/battle-map-360x640.png), [Resume inspection](../output/qa/rc-025-map-match/screenshots/battle-resume-inspection-360x640.png) |

Earlier diagnostics remain available: [first render bounds failures](../output/qa/rc-025-map-match/map-capture-first.log), [old scroll assumption](../output/qa/rc-025-map-match/shell-tests-old-scroll-assumption.log), and [capture before footer frame correction](../output/qa/rc-025-map-match/map-capture-footer-before.log). The drag check now uses the genuinely scrolling 360×640 layout; 450×1000 fits the graph and no longer needs a drag. Final logs contain no unexpected engine errors.

## Packaged resources

The explicit runtime inventory and packed decode probe include `route_map_node.gd`, `route_map_chrome.gd` and `assets/ui/map/parchment.png`, alongside the original route scripts. A regression rejects a missing parchment resource. The existing export policy excludes reference images, tests, capture code, tools, source provenance and output evidence. The actual PCK was decoded from an empty project with no workspace fallback.

Resource-only pack: `builds/rc-025-map-match-resources/RuneCast.pck`, **12,240,000 bytes**, **357 entries**, SHA-256 **`872f88f45a46a4657e5454dcb1f8f9fc535755a49a113700b144d591f8cb7d3d`**. The [export log](../output/qa/rc-025-map-match/resources/export-engine.log) retains the existing SDK-version fallback informational message. Exporting resources through the existing iOS preset is not a native Android/iOS build or device validation.

## Reproduce

From `C:\Dev\RuneCast`:

```powershell
$engine = 'C:\Dev\RuneCast\.tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe'
$py = 'C:\Users\nguye\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
$env:APPDATA = 'C:\Dev\RuneCast\output\qa\rc-025-map-match\recheck-appdata'
$env:LOCALAPPDATA = 'C:\Dev\RuneCast\output\qa\rc-025-map-match\recheck-localappdata'
& $engine --headless --path . --log-file C:/Dev/RuneCast/output/qa/rc-025-map-match/shell-tests.log --script res://tests/application_shell_tests.gd -- --qa-output=res://output/qa/rc-025-map-match
Start-Process -FilePath $engine -ArgumentList @('--path','C:/Dev/RuneCast','--audio-driver','Dummy','--log-file','C:/Dev/RuneCast/output/qa/rc-025-map-match/map-capture.log','--script','res://tests/route_map_capture.gd') -WindowStyle Hidden -Wait
& $engine --headless --path . --export-pack iOS builds/rc-025-map-match-resources/RuneCast.pck --log-file C:/Dev/RuneCast/output/qa/rc-025-map-match/resources/export-engine.log
& $py tools/verify_ios_resources.py --pack builds/rc-025-map-match-resources/RuneCast.pck --engine $engine --report output/qa/rc-025-map-match/resources/resource-audit.json
$env:RUNECAST_RESOURCE_TEST_PACK = 'C:\Dev\RuneCast\builds\rc-025-map-match-resources\RuneCast.pck'
& $py -m unittest discover -s tests -p 'test_ios_*.py' -v
```

RC-026 remains the next route-to-real-encounter integration. Production room handlers, rewards, saving, permanent progression, final content art/integration and device acceptance retain their existing owners.
