# RC-015 shared crypt environment

October 13, 2026 · r001. This is shared environment art for the existing four board identities and applicable room specimens. It is not a Shadeling-exclusive room. Shadeling is used only as the delivered encounter-boss scale specimen, retaining its artwork and hit-named pose.

## Delivered files

- [crypt.ora](crypt.ora): two meaningful, overlapping, full-canvas editable paint layers; [external layers](layers/) and [merged master](merged.png).
- Runtime [background.png](../../../assets/environments/crypt/background.png) and [floor.png](../../../assets/environments/crypt/floor.png).
- [lighting.json](lighting.json), reusable [lighting.tres](../../../assets/environments/crypt/lighting.tres), and [environment.tscn](../../../assets/environments/crypt/environment.tscn). Exactly three parameter presets share the two textures: base cool, warm candle and dark.
- [metadata.json](metadata.json) supplies coordinates, provenance and bounds. [Assembly recipe](../../../tools/build_crypt_environment.py) reproduces the initial delivery.

The optional foreground is deliberately omitted: the existing side stones, statues and candles frame the arena without covering the actor or adding another full texture. The manifest retains its optional row with this explicit waiver.

## Canvas and integration contract

Master **1682×1140**; aligned exports **841×570**, origin **(0,0)**. The 2× editing canvas is resampled from the retained native 841-wide painting; it does not claim new fine detail. Runtime coordinates match the top 570 rows of r006's 841×1870 composition. Source coordinates are twice runtime coordinates. The old 2880×1440/1440×720 and 680×300 proposals are superseded.

Use **Rect(0,60,841,450)** for the isolated comparisons. With width `W`, `k=W/841`, map `preview=(runtime-(0,60))*k`. Apply that same positive uniform transform to both environment layers and the character stage. The Shadeling scene root goes at `(446,368)*k`, with its unchanged texture scale `0.75*k` and texture foot `(256,448)`. It is not stretched or independently reframed.

| Width × rounded height | Character texture scale | Foot |
| --- | --- | --- |
| 720×385 | 0.6420927467 | (381.8312,315.0535) |
| 450×241 | 0.4013079667 | (238.6445,196.9084) |
| 360×193 | 0.3210463734 | (190.9156,157.5268) |

The fractional image height is preserved by the transform; viewport rounding never changes the scale. This is arena-only comparison evidence, not a responsive phone layout. RC-016 owns the final Combat layout.

The canvas supplies **0 horizontal / 60 top / 60 bottom pixels of overscan** around the default crop. Art-only 450-high crops can start at Y0 through Y120 and remain fully painted. Only the default Y60 crop is accepted for the present actor/overlay arrangement. Those other crops prove coverage, not alternative gameplay layouts. Do not add horizontal translation, layer motion, rotation or parallax. Any broader crop or changed actor/UI layout needs RC-016 review.

The unchanged declared character envelope maps to composition `[272,116,620,452)`; RC-014's measured full-motion union maps to `[275.75,155,611,434)`. Feet contact the floor at `(446,428)`. Intent uses composition X390–500/Y76–144; live BOSS/name/health are separately placed below the actor. The isolated Godot specimen records its exact live UI bounds. No labels, health bars, characters, board content or controls are painted into either environment texture.

## Layer construction and hidden paint

The [retained r004 master](../../pilot/revisions/r004/crypt/crypt.ora) and [r006 clean plate](../../pilot/revisions/r006/exports/crypt-background.png) were inspected alongside the approved Combat final-v2 and current RC-014 comparison. The pilot's seven regions were disjoint and explicitly lacked hidden paint. They were unsuitable as independently composited production background/floor layers without repair.

The visible rear architecture and cobblestone platform reuse that **clean generated environment**, not pixels from the approved flattened gameplay screenshot. The floor has a 24-runtime-pixel alpha transition above its irregular rear horizon (Y340–381). Background is opaque across the entire canvas, including every floor pixel. Retained matching paint covers the transition and continues below it. Newly generated recessed chamber/floor underpainting blends into the hidden background at Y396–432 and extends through Y570. Turning off the floor exposes a painted chamber, not a transparent hole or another copy of the raised foreground platform. There is more than 48 pixels of opaque hidden coverage below every horizon point.

Both source layers have full dimensions and zero offsets. Their visible stack recomposes the stored merged master exactly. Export each layer separately at 50% with Lanczos; background becomes RGB, floor stays straight-alpha RGBA, both with embedded sRGB. Runtime recomposition preserves the pilot appearance with only filtering differences from the documented upsample/downsample. Rebuild restores initial pixels, so save subsequent artist edits before running the builder.

## Lighting and imports

The resource and editable JSON keep exactly `base_cool`, `warm_candle`, and `dark`. The shared environment shader changes environment colour only; the actor, live intent, role/name/health and UI remain outside that modulation. No duplicated full backgrounds or new biome/room assets are introduced. Preset values and runtime usage are recorded in [lighting.json](lighting.json) and the [runtime guide](../../../assets/environments/crypt/README.md).

The GDScript, shader, Resource and JSON are original RC-015 code/settings authored by Codex for Rune Cast, with no external code or painted pixels embedded. Their independently recorded readiness does not resolve the dependent artwork's inherited rights.

PNG imports use lossless storage, alpha-border fixing, no premultiplication, no mipmaps and no size limit. Display uses linear filtering and disabled repeat. Two 841×570 textures cost **3,834,960 bytes / 3.6573 MiB** under the conservative RGBA8 estimate, versus the provisional 11.9 MiB crypt cap. Presets add no texture. This excludes font atlases, actor/UI, engine/render buffers, allocation overhead and device measurements.

## Provenance and evidence

[Raw underpaint](raw/underpaint.png), [exact edit prompt](raw/underpaint.prompt.txt), [retained edit input](raw/retained-arena.png) and metadata preserve the built-in `image_gen.imagegen` edit record. Model version and seed were not exposed. The prior crypt input/provenance remains unchanged in r004/r006. Source brush history is unavailable; ORA supplies editable pixel layers with real overlap. Inherited reference/generated-art rights remain unresolved, so the painted pack stays `source_ready` even after technical import verification. Reference approval does not approve this reconstructed pack.

Reproduce isolated imports/renders with `tools/preview_environments.ps1`, then run `tools/validate_environments.py` and `tools/validate_asset_plan.py --report output/qa/rc-015/asset-plan-validation.json` using the bundled Python. New evidence is kept under [RC-015 QA](../../../output/qa/rc-015/) and [RC-015 art](../../../output/art/rc-015/). The focused [validation report](../../../output/qa/rc-015/validation-report.json), [Godot report](../../../output/qa/rc-015/godot-render-results.json) and [visual review](../../../output/qa/rc-015/visual-review.json) record actual results and limits.

Actual verification passes **1,094 focused checks**, **780 Godot checks** and **136 full-motion samples**, retaining the measured texture-space union `[29,84,476,456)`. Forty Godot PNGs plus three derived contact sheets cover every layer, recomposition, overlap/overscan, three presets at three widths, idle/attack/retained hit/defeat including transparent endpoint, and all Home crops. [Lighting/scale sheet](../../../output/art/rc-015/lighting-and-scale.png), [motion sheet](../../../output/art/rc-015/crypt-motion-contact.png) and [overview](../../../output/art/rc-015/overview.png) are convenient derived views; individual PNGs remain authoritative. The source/import check verifies671 protected files unchanged. Visual review corrected compact name/health spacing and a Home logo/tower-tip overlap before the final render. The host logged a shader-cache-directory diagnostic; no script/import/resource failure occurred. No unrelated gameplay suite was run.

RC-016A remains the independent evaluator/control migration gate; RC-016 integrates Combat art, RC-017 binds event-driven character motion, and RC-032/RC-042 own functional Home/full presentation. No main-game scene, encounter stats, controls, maps, saves, Store, progression or rewards are changed. No physical-device, rights-clearance or owner-acceptance result is claimed.
