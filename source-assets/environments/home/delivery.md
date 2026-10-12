# RC-015 Home tower illustration

October 13, 2026 · revision r001. The [editable Home master](home_tower.ora) delivers the separate moonlit tower and the [opaque runtime illustration](../../../assets/environments/home/home_tower.png) contains no logo, controls, labels, rune emblems or characters. The approved [Home reference](../../../output/imagegen/approved/home.png) was inspected along with the latest Combat reference, current RC-012/RC-013 deliveries, retained pilot and cleanup ledger. There is no retained clean Home painting to promote; the crypt/UI pilot does not supply this separate illustration.

The new image preserves indigo night clouds, a pale blue moon, the narrow gothic tower, warm windows, the spiral approach, deep mountainous gorge, arched bridges and edge braziers. The lower stone backing is subdued by its own adjustable grading layer. The existing RC-013 wordmark and live Godot controls remain separate preview resources.

| Deliverable | Contract |
| --- | --- |
| [home_tower.ora](home_tower.ora) | 1440×3200, eight named aligned RGBA paint layers, origin(0,0), visible stack in mergedimage.png |
| [Runtime PNG](../../../assets/environments/home/home_tower.png) | 720×1600 opaque RGB, embedded sRGB ICC, exact0.5 source scale, LANCZOS export |
| [Metadata](metadata.json) | Source/export mapping, layer files/hashes, semantic bounds, crop/focal reservations and memory estimates |
| [Source layer sheet](source-layer-sheet.png) | Actual independent layers on gray; no duplicated composite presented as a layer |
| [Semantic region geometry](separation-regions.svg), [masks](masks/) | Editable region boundaries and exact per-layer alpha masks |
| [Generation record](raw/generation-record.json), [initial prompt](raw/home-clean.prompt.txt), [framing edit prompt](raw/home-reframe.prompt.txt) | Both raw generations and their actual inputs, observed dimensions, hashes and tool output paths |

The master separates sky/clouds, distant mountains/bridges/mist, tower/rocky approach, foreground paving, left and right edge braziers, moon/halo and control-backing grade. Seven complementary semantic paint regions exactly recompose the selected generated painting before grading. These are real distinct regions of newly generated scenery, not cropped UI/reference screenshot pixels. The region masks support repaint, recolour and replacement. Generated brushwork is flattened inside each region; hidden geometry and original brush strokes are unavailable. This static illustration does not promise movable cutout objects or parallax. Moving a region requires painting the exposed area.

The raw selected painting is 841×1870. Source preparation uses uniform center cover at 1440/841, cropping the equivalent of 0.555556 raw pixels at both top and bottom. The editing master is upsampled from this retained generation; native 1440×3200 generated detail is not claimed. It does not stretch the tower. The full source stack is reduced to 720×1600 with LANCZOS then converted to RGB. All eight layers share the same canvas and transform; only the final opaque composite is imported by Home.

## Cover crops and live layout

At viewport(W,H), use `k=max(W/720,H/1600)`, center the uniformly scaled texture, and crop excess. The following rectangles are in720×1600 runtime coordinates; multiply by2 for source coordinates.

| Aspect | Runtime source rectangle x,y,width,height | Critical content |
| --- | --- | --- |
| 9:16 | (0,160,720,1280) | Complete moon and tower; only decorative upper sky and bottom paving removed |
| 9:20 | (0,0,720,1600) | Full export |
| 9:21.5 | (25.116279,0,669.767442,1600) | 25.116279px cropped from each side; tower/moon remain inside horizontal focal safe area |

The prior proposed80px top/bottom allowance cannot mathematically cover9:16 from720×1600. This delivery explicitly revises that allowance to160px per end and keeps36px per side. The first generation placed the moon too high; the retained targeted edit corrects its framing before export. The safe intersection isX36–684,Y160–1440. Approximate visible moon bounds are(485,214,146,150); main tower bounds are(285,394,278,459). The original proposed tower reservationX110–610,Y340–1020 and control backingX100–620,Y1010–1450 remain appropriate. Metadata distinguishes the approach path from the primary tower silhouette.

The separate logo reservation isX36–684,Y70–400 in the full design canvas. Position the logo and live buttons responsively in viewport space, with safe-area handling; do not crop a flattened Home composition or stretch the wordmark. A short cover crop therefore needs a separately positioned wordmark/control stack. RC-032 owns functional Home flows, RC-042 owns full presentation integration, and RC-044 decides supported device layouts. The isolated comparisons do not establish those final flows or physical-device acceptance.

## Editing, imports and validation

Open the ORA in an OpenRaster-capable paint application. Edit the named regions or grade opacity, keep the common canvas/origin, then update the external layer/mask files and regenerate the export. [The deterministic builder](../../../tools/build_home_environment.py) reproduces the recorded revision from the selected raw painting and explicit masks. Running it restores this revision, so save later artist edits before rebuilding. No generation call occurs during the build.

```powershell
& 'C:\Users\nguye\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' tools/build_home_environment.py
```

Use lossless Godot import, linear filtering, repeat disabled, no mipmaps and no size limit. Source masks, ORA and raw generations are editing evidence and excluded from runtime packaging. The opaque export needs3,456,000 bytes asRGB or a conservative4,608,000 bytes/**4.39453125MiB** asRGBA8. One source layer is17.578125MiB decodedRGBA8; eight layers total140.625MiB in an editor, outside runtime. These dimension estimates exclude engine/framebuffer/cache/font allocations and are not measured GPU/device memory.

Build checks passed: expected raw/source/export dimensions, all eight nonempty distinct regions, seven-region exact reconstruction, opaque final coverage and deterministic export. The actual runtime export and source layer sheet were visually inspected: no baked UI, readable tower/moon hierarchy, no visible assembly seams or unpainted corners. The parent RC-015 verification records cover actual Godot imports, isolated Home previews with the existing wordmark/theme, all three crops and independent source/export validation.

The final [Godot report](../../../output/qa/rc-015/godot-render-results.json) passes780 checks across40 crypt/Home renders, including six clean/composed Home images. [9:16](../../../output/art/rc-015/home-1280-composed.png), [9:20](../../../output/art/rc-015/home-1600-composed.png) and [9:21.5](../../../output/art/rc-015/home-1720-composed.png) reuse actual RC-013 wordmark/buttons and live labels. The short-view wordmark was moved/resized to clear the tower apex; partial overlap with the moon follows the approved hierarchy, while each clean crop retains the full moon. [Focused validation](../../../output/qa/rc-015/validation-report.json) passes1,094 checks across both packs, including exact source/export correspondence. [Visual review](../../../output/qa/rc-015/visual-review.json) and the [derived overview](../../../output/art/rc-015/overview.png) record the final reviewed appearance.

The tool was built-in `image_gen.imagegen`; model/version and seed were not exposed and remain null. Both prompts and raw outputs are retained. New art is `reference_guided`; owner approval applies only to the supplied reference. Rights clearance remains unresolved, and no physical-device result or main-game integration is claimed.
