# Shadeling pilot delivery — r001

`pilot_shadeling`, RC-011. Created October 10 and technically reviewed October 11, 2026. **Owner rejected r001 visual fidelity. Revise against the approved reference; source readiness is a file-existence claim only.** Technical alpha/layer/anchor findings remain valid; the earlier direction pass is withdrawn.

## Sources and exports

| Purpose | Exact repository-relative path |
| --- | --- |
| Layered exchange master | `source-assets/pilot/shadeling/shadeling.ora` |
| Native editable assembly | `source-assets/pilot/shadeling/assemble_shadeling.py` |
| Editable separation boundaries | `source-assets/pilot/shadeling/separation-masks.svg` |
| Source layers | `source-assets/pilot/shadeling/layers/` |
| Source flattened comparison | `source-assets/pilot/shadeling/neutral-reference.png` |
| Raw immutable generation | `source-assets/pilot/shadeling/raw/neutral-generation.png` |
| Actual generation prompt | `source-assets/pilot/shadeling/raw/neutral.prompt.txt` |
| Metadata and validation | `source-assets/pilot/shadeling/metadata.json`; `source-assets/pilot/shadeling/validation.json`; `source-assets/pilot/shadeling/validate_shadeling.py` |
| Neutral review export | `source-assets/pilot/exports/shadeling.png` |
| Same-canvas parts | `source-assets/pilot/exports/shadeling_parts/body_cloak.png`; `shoulder_underlap.png`; `lantern_arm.png`; `lantern_glass_backing.png`; `lantern_shell.png`; `lantern_glass_light.png`; `flame.png` |

The seven part leaf filenames above are all under `source-assets/pilot/exports/shadeling_parts/`. Every source layer is1024×1024; every exported part and the neutral is512×512 RGBA8 PNG with an embedded standard sRGB ICC profile and straight alpha. Every PNG member of the ORA also carries the sRGB profile. Transparent canvases retain origin(0,0). Exports are source-only review resources excluded by `source-assets/.gdignore`; no runtime import settings or export preset was changed.

## Provenance and refinement

The painting was generated with the built-in `image_gen.imagegen` tool from the actual [prompt](raw/neutral.prompt.txt), with the approved Combat image used for visual direction. The tool did not expose a model/version identifier; none is invented. The generated output actually measures **1254×1254**, despite the requested1024 canvas. Its SHA-256 is `b66d8f6bbba3b846950bd8b7940c40c85558efc635054ef2230c10a1684a0fba`. Raw pixels remain unchanged. No external CLI/API generation or reference-image crop was used in this assembly.

The editable source uses polygon masks in raw coordinates to partition actual painted pixels into body/cloak, lantern arm/sleeve, lantern shell, glass light and bright flame. Separate vector patches supply a small shoulder underlap and dark glass backing. These are seven different, nonempty layers; there is no full flattened image duplicated into named layers. The raw reference is retained separately, not disguised as a layered source. The ORA can be edited in an OpenRaster application; the SVG shows mask boundaries and the native Python script records the complete deterministic assembly.

Refinement removed only sparse raw alpha values1–3 (17,759 pixels) before resampling; the original alpha remains in the raw file. Visible edge alpha is preserved. The source was uniformly normalized by scale0.6338028169 and translation(58.19718310,143.04225352), mapping raw foot datum(716,1188) to source(512,896). No environment, contact shadow or external glow was introduced. Final file inspection caught missing explicit colour profiles on the initial Shadeling PNGs; the assembly now assigns standard sRGB consistently without converting any pixels. [Decoded-pixel baseline](profile-pixel-baseline.json) and validation confirm identical pixels in all16 source/export PNGs before and after assignment. The raw generation is unchanged.

The arm and lantern initially moved independently in the feasibility preview. Actual frame inspection showed the handle detaching during the action. The final hierarchy makes the lantern shell/backing/light/flame inherit the arm transform, with a small additional swing at the held-item pivot. The corrected action frame was visually inspected.

Rights status remains **unresolved**. The actual prompt, generator identity and output hash document provenance; they do not constitute a third-party licence record or final RC-050 rights clearance.

## Anchors, scale and memory

Foot datum: source(512,896), export(256,448). Source and part origins remain identical. [Metadata](metadata.json) records the export-space body center, head, attack origin, shoulder pivot and held-item pivot, as well as draw order.

Visible neutral bounds at alpha>16 are `[93,88,370,449)` export pixels; all nonzero alpha including filtering is `[91,86,372,451)`. These lie inside the proposed approximate neutral area; the final visible ground pixel is y448. The complete motion union at alpha>16 is `[69,86,377,457)`; **all nonzero alpha** is `[68,84,379,459)`, inside the agreed x32–480/y32–480 envelope. Bounds use exclusive right/bottom coordinates.

The [scale comparison](../../../output/art/rc-011/pilot-shadeling-scale.png) uses0.42/0.46/0.48 design pixels per export pixel on one ground line. The proposed0.46 gives approximately166 design pixels of visible height. Place the foot at(340,233) in the current680×300 arena, then apply the arena layout transform. The actor must not stretch independently by axis. At0.46 the hood, pale mask, separated lantern and both feet remain readable. Fine painted cloth texture merges at this scale, so RC-014 should keep major shadow shapes and avoid adding more detail.

Decoded RGBA8 neutral cost is **1,048,576 bytes (1MiB)**. Seven512² parts cost **7,340,032 bytes (7MiB)** if simultaneously retained. Keeping both neutral and all parts would cost8MiB, so production should select its active representation deliberately. ORA/raw sources and contact sheets are excluded from runtime memory estimates. These are dimension-based calculations, not PNG compressed-file sizes or measured GPU allocations.

## Motion study

- [48-frame PNG sequence](../../../output/art/rc-011/pilot-motion-frames/frame_000.png), `frame_000.png` through `frame_047.png`, all1280×720;8fps,125ms each, total6s.
- [Timing and per-frame envelope record](../../../output/art/rc-011/pilot-motion-timing.json).
- [Animated GIF convenience preview](../../../output/art/rc-011/pilot-motion.gif), six seconds, alternating120/130ms frame delays to preserve the six-second total under GIF timing quantization.
- [Key-frame contact sheet](../../../output/art/rc-011/pilot-motion-sheet.png).

The available environment had no `ffmpeg` executable in PATH. The brief permits the delivered PNG-sequence substitute; no MP4 is falsely claimed. PNG timing is authoritative. The GIF is only a convenient playback copy.

The sequence shows idle0–1.5s, attack anticipation1.5–2s, attack action2–2.5s, one hit recoil2.5–3.5s, and defeat settle/fade3.5–6s. Labels/timecodes, common foot anchor and envelope are visible. The reduced-motion panel has a static neutral pose, brief action/hit opacity cues and a brief defeat fade; no bob, travel or shake. No combat VFX or gameplay action is applied.

**Method finding: sufficient for pilot feasibility.** Small body/arm/lantern transforms and a settled fade communicate the four states at this scale. They do not replace final attack/hit silhouettes. RC-014 must paint/refine hidden anatomy and final attack/hit poses; the simple shoulder underlap only supports the modest tested rotations. RC-017 owns actual timing, cancellation, event order, completion callbacks, zero-damage feedback and runtime reduced-motion behavior. No animation resources are integrated.

## Actual review

| Criterion | Result and evidence |
| --- | --- |
| Crooked hood, ragged indigo/purple cloak, pale skeletal mask, warm lantern, full body | **Pass for pilot.** [Neutral export](../exports/shadeling.png) was visually inspected; both feet, hood tip and lantern remain visible. All four approved references were inspected in the [context audit](../context-audit.md). |
| Broad matte shading and dark outlines at actual scale | **Revise for reference fidelity.** [Scale sheet](../../../output/art/rc-011/pilot-shadeling-scale.png) uses a tall thin detailed character at undersized0.46scale. Approved Combat requires the compact broad cartoon silhouette, short crooked hood, simple cloak planes, gold clasp and squat lantern. Feature presence alone does not establish identity matching. |
| Clean alpha | **Pass.** Actual export inspected on [native512 white/black](../../../output/art/rc-011/pilot-shadeling-alpha-native.png), [gray/navy/turquoise/checkerboard](../../../output/art/rc-011/pilot-shadeling-alpha.png). No visible matte rectangle, bright fringe, clipped extremity or baked shadow was seen. |
| Meaningful source separation | **Pass.** [Layer sheet](../../../output/art/rc-011/pilot-shadeling-layers.png) visibly shows different parts; [validation](validation.json) checks seven unique nonempty layers,1024² canvases, exact ORA merge and exact512-part recomposition. |
| Anchors and envelope | **Pass.** [Metadata](metadata.json) and [per-frame bounds](../../../output/art/rc-011/pilot-motion-timing.json) show all nonzero alpha inside the agreed envelope; guides remain fixed in every frame. |
| Four states and reduced motion | **Pass for unintegrated feasibility.** [Motion study](../../../output/art/rc-011/pilot-motion.gif) and [key sheet](../../../output/art/rc-011/pilot-motion-sheet.png) inspected at idle, anticipation, action, hit and defeat; corrected lantern attachment verified. |
| Final attack/hit production and hidden anatomy | **Revise in RC-014.** Neutral-source transforms and small vector underlap are pilot scope only. |
| Godot import and filtering | **Not tested.** No runtime resources or settings changed. |
| Physical-device readability/performance/accessibility | **Not tested.** Desktop exported evidence only. |
| Owner aesthetic approval / final rights clearance | **Visual fidelity rejected; revision required.** Rights clearance remains unresolved. |

`validate_shadeling.py` passes **26 actual-file checks**, recorded in [validation.json](validation.json). No gameplay suite was rerun. No Git operations were performed.
