# RC-014 — Shadeling production character pack

**October 16, RC-017 integration:** the playable Combat actor retains the approved-atlas neutral and the existing full-texture attack/hit paintings. [Production actor/attachment contract](../../../docs/actor-animation-contract.md) adds editable normalized motion, lifecycle restoration and stable terminal state. Hidden scenery uses a broad feathered clean center instead of the neutral-shaped hole. All source paintings/exports remain unchanged; historical isolated-study details below remain provenance, while production integration and timing statements are superseded by that contract.

October 12, 2026 · asset ID `shadeling` · revision `r001`.

**October 13 cleanup:** [framing-360](../../../output/art/rc-014/framing-360/) is the retained current preview set. Earlier duplicate/superseded images, generated staging projects and the write-only normalized underlap intermediate are retired in the [exact cleanup ledger](../../../docs/asset-cleanup.md#october-13-2026--project-wide-follow-up-cleanup). Editable masters, canonical layers, runtime exports, raw generations/provenance and historical QA records remain. Historical preservation statements below describe their original audit dates, before this authorized cleanup.

**RC-014 is complete for production and isolated desktop verification.** The pack supplies three distinct painted poses, genuine editable pixel-layer masters, nine aligned neutral parts and an isolated Godot character scene. Shadeling is the boss for one designated map encounter (October 12 owner direction). The supplied Combat reference is approved; these reconstructed/refined poses have assistant review, not inferred owner approval. Manifest readiness is **source_ready**, visual direction **reference_guided**, licence **unresolved**. Technical import/render verification is separate from release rights.

**Follow-up direction, October 12:** the owner observes that the hit study reads as dodging and explicitly chooses to keep the pose. Retain revision `r001` artwork and the existing `hit` interface; dodging is a possible RC-034 boss mechanic, with no new state or behavior implemented here. This supersedes earlier recoil-readability claims and historical introductory-normal/no-BOSS context in the original evidence. It does not imply broader artwork approval. See the [decision](../../../docs/decisions.md#october-12-2026--preserve-shadeling-pose-and-consider-dodging) and the follow-up audit below.

## Delivery and editing map

| Purpose | Source | Runtime or evidence |
| --- | --- | --- |
| Neutral / idle | [shadeling.ora](shadeling.ora), [nine editable layers](layers/), [reference composite](neutral-reference.png) | [neutral.png](../../../assets/enemies/shadeling/neutral.png) |
| Raised-lantern attack / windup | [attack.ora](poses/attack.ora), [seven paint regions](poses/attack/), [reference](attack-reference.png) | [attack.png](../../../assets/enemies/shadeling/attack.png) |
| Retained hit / dodge-like side lean | [hit.ora](poses/hit.ora), [eight paint regions](poses/hit/), [reference](hit-reference.png) | [hit.png](../../../assets/enemies/shadeling/hit.png) |
| Neutral part alternatives | [source layers](layers/) | [nine aligned parts](../../../assets/enemies/shadeling/parts/) |
| Four-state illustration scene | [scene](../../../assets/enemies/shadeling/character.tscn), [editable GDScript study](../../../assets/enemies/shadeling/character.gd) | [usage / RC-017 guide](../../../assets/enemies/shadeling/README.md), [exportable attachment resource](../../../assets/enemies/shadeling/attachments.tres) |
| Technical assembly | [build_pack.py](build_pack.py), [neutral masks](neutral-masks.svg), [attack masks](attack-masks.svg), [hit masks](hit-masks.svg) | [metadata](metadata.json), [generation record](raw/generation-record.json) |

Every ORA layer is a full 1024×1024 RGBA surface with meaningful, distinct visible content. Parts are extracted semantic paint regions or real painted underlaps, not repeated flattened sprites renamed as layers. Fully transparent RGB is cleared. ORA preserves editable pixels, layer order, visibility and alpha; original brush strokes and a generator's native painting history were never exposed. The explicit masks and assembly recipe remain editable alongside the ORAs.

Full runtime poses and neutral parts are 512×512. Every pose retains the same canvas and origin, with foot **(512,896)** in source and **(256,448)** in runtime. Nothing is independently tight-cropped. OpenRaster remains the main editing interchange; no proprietary source file is claimed.

## Retained baseline, new painting and refinements

The [r006 delivery](../../pilot/revisions/r006/delivery.md) establishes composition, using the retained [r002 ORA](../../pilot/revisions/r002/shadeling.ora), [neutral](../../pilot/revisions/r002/neutral-reference.png), [seven layers](../../pilot/revisions/r002/layers/), [metadata](../../pilot/revisions/r002/metadata.json), [original raw generation](../../pilot/revisions/r002/raw/shadeling.png) and [original prompt](../../pilot/revisions/r002/raw/shadeling.prompt.txt). Exact retained input SHA-256 values are in `metadata.json.reuse`; the [baseline audit](../../../output/qa/rc-014/retained-baseline-audit.json) records measured layer integrity and bounds. Pilot originals are preserved.

The previous 48-frame, 8fps [feasibility sequence](../../../output/art/rc-011/r002/pilot-motion-frames/) used modest arm/lantern/body transforms, a flat indigo shoulder polygon and collapse/fade. It did not supply separately painted attack/hit poses or robust hidden anatomy. The mask also stranded a small gold chain fragment on the body layer and joined the hood to the body.

This revision:

- Keeps the retained neutral identity, broad cloak, crooked hood, skeletal mask, clasp, wrapped boots and right-hand lantern (viewer left). Its visible outer bounds remain the same.
- Uses new built-in imagegen paintings for a raised-lantern attack and rightward recoil. Both preserve costume, handedness, warm lantern and matte contours.
- Uses a third generated **arm-removed cloak repair plate** for painted shoulder and neck underlaps. The shoulder patch replaces the old flat fill. A mapped robe-paint patch fills the hidden neck/collar boundary. Only those local patches enter the neutral, rather than replacing it with the whole repair image.
- Separates the neutral hood/head, reassigns the stray chain fragment to the lantern and expands hidden overlap after actual Godot stress frames exposed seams. Fully transparent pixels are cleared; genuine partially transparent edge colour is preserved.
- Uniformly normalizes the new raw paintings into the common source canvas. Attack mapping: scale `720/929`, translation `(64−55s,896−1118s)`. Hit: scale `720/887`, translation `(512−671s,896−1095s)`. Actual raw images are1254²; no requested1024 dimensions are misreported as returned dimensions. Normalization keeps about720 source pixels of visible height, matching neutral, rather than reducing actor scale to hide clipping.

The raw [attack prompt](raw/attack.prompt.txt), [hit prompt](raw/hit.prompt.txt), [underlap prompt](raw/underlap.prompt.txt), all three raw PNGs and returned output paths/hashes are retained. The prompts request transparent cutouts, fixed costume/handedness, common ground, broad matte shapes and no UI/background/shadow. Calls used **built-in `image_gen.imagegen` edit mode**, each referencing the r002 neutral. Model version and seed were not exposed and remain `null`; no guessed version is recorded. The approved final-v2 and r006 were visually inspected as current direction, but are not falsely described as the historical r002 generator input. R002's actual input was the earlier `combat.png`.

Creator/source: inherited built-in generated painting plus new built-in generated poses/repair plate; Codex-authored separation, normalization, Godot code and verification. Inherited generated-art and reference rights are **unresolved**. No evidence in this task clears those rights or confers a third-party licence. Font/UI/crypt previews reuse their retained source/licence records. RC-050 retains shipping provenance/rights review.

## Parts, pivots, attachments and ordering

Neutral bottom-to-top order is `shoulder_underlap`, `neck_underlap`, `body_cloak`, `head_hood`, `lantern_arm`, `lantern_glass_backing`, `lantern_shell`, `lantern_glass_light`, `flame`. Attack/hit ORAs use complementary body, hood, lantern arm, lantern shell, glass light and flame paint regions; hit also separates the crossed free arm. Their exact order/masks are in `metadata.json.poses`. Attack/hit layers support editing; their delivered motion uses complete poses, so no unseen anatomy is exposed between those extracted regions.

Neutral part-study pivots in runtime pixels: hood **(237,208)**, arm **(183.2095,176.9296)**, lantern handle **(114.3715,177.5883)**, flame **(106.1372,260.2598)**. Lantern/glass/flame inherit the arm transform, then swing about the handle. The verified editable-part stress is arm±4°, relative lantern±3°, hood±2°; it is a bounded feasibility envelope, not authorization for arbitrary puppet deformation. Larger motion needs further hidden painting or another pose.

| Pose | Head | Body centre | Attack origin | Lantern pivot |
| --- | --- | --- | --- | --- |
| Neutral |224.051,156.509|238.543,278.375|108.443,176.930|114.371,177.588|
| Attack |246.682,154.265|267.996,299.582|97.877,119.001|104.853,134.889|
| Hit |302.674,146.038|277.511,278.755|138.706,238.169|144.794,249.533|

These are texture coordinates. Subtract(256,448) for scene-local coordinates. `PoseRoot` owns the sprite and four markers, so attachments follow the selected pose and study transform. The foot is the stable root origin. Scene draw order is optional contact shadow at−20, full pose at0, invisible markers at10. The optional shadow is a separate editable vector polygon, disabled by default; it is never baked into the PNG. Flame/glass light remain separate source/export parts; no external glow conceals alpha defects.

## Measured scale and alpha

The r006 values384² at(254,92) are **full841×1870 composition coordinates**, not coordinates in the old680×300 arena. Runtime texture scale is384/512=**0.75**; foot is(446,428). The isolated arena previews use the retained crypt crop **Rect(0,60,841,450)**, giving local foot(446,368). For a uniformly scaled crop, `display = (composition − (0,60)) × width/841`.

| Presentation | Texture scale | Foot in preview |
| --- | --- | --- |
| Reference841-wide crop |0.75|(446,368)|
| Design720-wide crop |0.64209275|(381.831,315.054)|
| Desktop450-wide crop |0.40130797|(238.644,196.908)|
| Proportional360 arena crop, 360×193 viewport |0.32104637|(190.9156,157.5268)|

**October 12 framing correction:** the current360 arena preview uses the same crop and proportional scale as720/450: texture scale `0.75*360/841`, foot `(446,368)*360/841` and a164.3757² sprite canvas in a360×193 viewport. Rounding the viewport height leaves the uniform art transform unchanged. The earlier r006180² canvas at(90,60), scale0.3515625 and foot(180,217.5), shown in the original360×280 isolated specimen, is preserved historical evidence and superseded for this three-size comparison. The proportional360 preview does not establish a full native-phone layout or device acceptance. The old0.46 scale and160–173px height/181px ceiling are superseded in the [production specification](../../../docs/asset-production-spec.md#characters). RC-015/RC-016 must reconcile their final environment/integration arena to this mapping, rather than applying384px or254/92 to an unrelated rectangle.

Bounds are half-open runtime pixel rectangles:

| Pose | Alpha>16 | Any nonzero alpha | Fully opaque pixels |
| --- | --- | --- | --- |
| Neutral |[62,88,404,449)|[60,86,406,451)|[63,89,402,447)|
| Attack |[32,88,474,448)|[29,86,476,450)|[33,89,472,447)|
| Hit |[87,88,421,448)|[85,86,423,450)|[89,90,418,447)|

Neutral visible height361px becomes270.75px in the reference and231.80px in the720-wide crop. Foot support differs naturally across the stances while their canvas origin/ground are fixed. Fine filtered edge coverage can extend one to three pixels around the physical contact line; no canvas border clips art.

This pack explicitly adopts an all-alpha safety envelope **X24–488, Y32–480**. The broad new attack has significant alpha insideX32–474 but valid filtered tail atX29; erasing its edge or shrinking the character would be inappropriate. Source/export dimensions and anchor stay unchanged. The final actual Godot union is **[29,84,476,456)** across136 normal/reduced state samples; the17 source-part stress samples occupy **[53,86,406,451)**. Both pass this declared envelope.

## Motion and scene interface

Instantiate `character.tscn` under a presentation `Node2D`, position that root at the foot, and apply a uniform presentation scale. The default is static neutral; local study playback is opt-in. `show_pose()`, `sample_state()`, `play_state()`, `stop_preview()` and attachment/cache helpers are documented in the [runtime README](../../../assets/enemies/shadeling/README.md).

Idle is a restrained0.4% vertical breathing cycle around the fixed foot. Attack is a one-shot neutral anticipation, raised-lantern pose with at most1.2% foot-rooted vertical squash, then neutral. The wide attack does not rotate or slide. Hit selects the retained side lean with a small angular/opacity cue, settling to neutral; the owner notes that it reads as dodging. Defeat selects the same hit pose, collapses vertically to65% with a small lean and fades to a stable transparent endpoint; it never returns to idle. The local finished signal is only a preview facility. RC-034 may consider this pose for a future dodge mechanic; RC-017 must keep resolved damage, dodge and zero-damage feedback distinct if that mechanic is adopted.

Reduced motion preserves pose changes and restrained opacity cues, removes geometric motion and uses a fade for defeat. It has the same persistent defeat endpoint. No new damage, hit/phase rules, intent selection, turn cleanup, model writes or controller completion/cancellation are implemented. RC-017 owns event timing, generation/action identity guards, completion/cancellation, lethal ordering and settings binding. Its presenter must consume already-resolved detached events, not infer damage or intent from this sprite.

## Imports, texture residency and reproduction

Exports are RGBA8 sRGB PNG with embedded standard sRGB ICC, straight alpha and consistent colour assignment. Godot recipes use lossless import, alpha-border fixing, no premultiplication, no mipmaps and no size limit. Scene filtering is linear and repeat disabled. Settings were tested in a separate pinned Godot4.7.2 Compatibility project; the normal game's scene/theme/data remain unchanged.

Decoded RGBA8 estimates: **1MiB** for one512² pose; **3MiB** when all three poses are explicitly warmed; **9MiB** for nine neutral part textures; **12MiB** if all poses and all parts are deliberately retained together. Default scene loads one full pose and no parts. A switch may temporarily overlap old/new textures (~2MiB). Engine resource-cache lifetime can differ from node references. These are dimension estimates, not measured GPU/device memory; font atlases, retained crypt/UI, framebuffer/engine buffers and allocator overhead are excluded. Source1024² layers are excluded from imports and release packaging.

```powershell
# Use the bundled Python executable if python is unavailable on PATH.
python .\source-assets\characters\shadeling\build_pack.py
.\tools\preview_shadeling.ps1
python .\tools\validate_shadeling.py
python .\tools\validate_asset_plan.py --report output/qa/rc-014/asset-plan-validation.json
```

The [preview wrapper](../../../tools/preview_shadeling.ps1) now stages exact copies into `output/qa/rc-014/framing-360/preview-project`; [preview sources](../../../tools/rc014_preview/) render actual Godot viewports. Run the wrapper before the validator when generated staging has been cleaned. No main-game import/run or full gameplay suite is required by this isolated pack. [Focused source/asset validator](../../../tools/validate_shadeling.py) checks ORA content/recomposition, canvases/profiles, source→export correspondence, alpha, anchors, source reuse, staging identity, import recipes and state/render reports. The [state test](../../../tools/test_shadeling.gd) checks actual scene behavior. [Protected snapshot](../../../output/qa/rc-014/protected-snapshot.json) records217 existing gameplay/pilot/reference files for preservation checks.

## Review evidence and handoff

The following original production counts remain historical evidence. Their no-BOSS/normal-enemy framing is superseded by the follow-up boss review. Original reports/provenance remain; image links resolve to byte-identical retained copies or explicit cleanup-retirement notes.

| Actual Godot output | Review purpose |
| --- | --- |
| [Pose sheet](../../../output/art/rc-014/framing-360/pose-sheet.png) | Three poses at common scale and ground |
| [Alpha backgrounds](../../../output/art/rc-014/framing-360/alpha-backgrounds.png) | Every pose and neutral part on indigo, white/light gray, black, checker and retained crypt |
| [Anchor/envelope](../../../output/art/rc-014/framing-360/anchor-envelope.png) | Pose-specific head/body/attack/lantern markers and shared foot |
| [Part underlap stress](../../../output/art/rc-014/framing-360/part-underlap-stress.png) | Opposite arm/lantern/head extremes on white and crypt |
| [Design720 — retired during cleanup](../../../docs/asset-cleanup.md#october-13-2026--project-wide-follow-up-cleanup), [desktop450 — retired during cleanup](../../../docs/asset-cleanup.md#october-13-2026--project-wide-follow-up-cleanup), [native360 — retired during cleanup](../../../docs/asset-cleanup.md#october-13-2026--project-wide-follow-up-cleanup) | Historical arena-only crops with live intent, name and health overlays; pre-correction BOSS-label omission superseded below |
| [Motion comparison](../../../output/art/rc-014/framing-360/motion-comparison.png) | Normal versus reduced-motion key moments |
| [Normal sequence](../../../output/art/rc-014/framing-360/motion-frames), [reduced sequence](../../../output/art/rc-014/framing-360/reduced-motion-frames) | Actual Godot frames through idle→attack→hit→defeat |

The delivered motion format is **46 PNG frames per normal/reduced sequence, with [motion GIF](../../../output/art/rc-014/framing-360/motion.gif) and [reduced-motion GIF](../../../output/art/rc-014/framing-360/reduced-motion.gif) convenience previews**, not an MP4 claim. GIF replay restarts the review sequence; the scene's defeat endpoint stays hidden until an explicit new request. Exact per-frame timing is in [Godot results](../../../output/qa/rc-014/godot-render-results.json).

Final checks pass **359 focused source/texture/import/evidence checks** and **194 Godot scene behavior checks**, plus136 full-pose and17 part-stress envelope samples. Eight Godot PNG sheets and92 motion frames were rendered. [Focused results](../../../output/qa/rc-014/validation-report.json), [asset-plan audit](../../../output/qa/rc-014/asset-plan-validation.json), [visual review](../../../output/qa/rc-014/visual-review.json) and the [verification entry](../../../docs/verification.md#october-12-2026--rc-014-shadeling-character-pack) retain actual evidence. The host logged shader-cache/user-directory and root-certificate-store diagnostics, but no missing textures or script/import failures. These environment diagnostics are retained honestly rather than labelled a clean engine log.

These are deliberately arena-only character previews. They reuse the retained painted crypt and RC-012/RC-013 resources without claiming a complete integrated Combat screen. They introduce no obsolete controls or substitute scenery. The full-screen visual/interaction contract continues to govern RC-016.

RC-016 imports/binds the illustration into the real arena, keeps boss name/intent/health/damage/BOSS labels live and validates its final crop/scale. RC-016A's evaluator/control migration remains separate and gates full Combat acceptance. RC-017 integrates event-driven animation, lifecycle and reduced-motion preferences; the local studies are a reviewable starting point, not that integration. RC-025/RC-034 own the designated encounter/node, board and boss behavior; RC-036 owns route/economy/reward reconciliation; RC-024A determines permanent-reward eligibility. Bell Keeper remains the proposed final guardian. Physical-device readability, texture pressure, performance and touch/safe-area behavior remain unverified. Distribution rights remain unresolved despite technical tests. The owner's pose-retention choice does not imply broader artwork approval.

## Follow-up audit — boss role and retained hit pose

This review and its linked results are retained evidence. The later360 framing correction below supersedes its separately framed native360 comparison; previous image/report files remain unchanged.

October 12, 2026: inspected the approved Combat final-v2 image, retained r006 composition, production contract, editable sources/provenance, delivered scene/API and original/fresh previews. **No artwork refinement was necessary.** All three masters, source layers, transparent exports, anchors, measured scale and four-state motion remain unchanged. The owner retains the dodge-like hit pose; this is a possible future mechanic, not an implemented dodge or a requirement for another animation state.

Corrected stale roster counts and role wording, scene role metadata, handoffs and Shadeling manifest/consumer notes. The source metadata and assembly recipe now preserve the role and owner feedback. Historical evidence remains in place with explicit supersession notes. The only visible preview change is a separate live **BOSS** label; fixture intent `8` and health `32/32` remain unchanged. Preview tools accept separate evidence destinations so this review preserves the original reports and renders.

Fresh checks passed **359 source/texture/import/evidence checks**, **194 Godot behavior checks**, **136 full-pose samples** and **17 part-stress samples**, with unchanged bounds. All eight new sheets were visually inspected. Of **102 PNG/GIF outputs**, 99 match the originals byte-for-byte; only the three arena images changed for live BOSS UI. A pre-edit SHA-256 snapshot confirms **462 protected files unchanged**, including the art, gameplay/fixtures, references, retained pilot and original RC-014 evidence. Python assembly syntax and role/feedback metadata consistency passed without executing the source builder. No raster generation, gameplay tests, new gameplay behavior or Git operations were performed.

- Fresh evidence: [audit and visual record](../../../output/qa/rc-014/followup-boss-dodge/audit.json), [focused validator](../../../output/qa/rc-014/followup-boss-dodge/validation-report.json), [Godot checks](../../../output/qa/rc-014/followup-boss-dodge/godot-render-results.json), [preservation](../../../output/qa/rc-014/followup-boss-dodge/preservation-validation.json), [document/manifest validation](../../../output/qa/rc-014/followup-boss-dodge/asset-plan-validation.json).
- Fresh boss-context previews: [720 design](../../../output/art/rc-014/framing-360/arena-design-720.png), [450 desktop](../../../output/art/rc-014/framing-360/arena-desktop-450.png), [360 native — retired during cleanup](../../../docs/asset-cleanup.md#october-13-2026--project-wide-follow-up-cleanup); [motion comparison](../../../output/art/rc-014/framing-360/motion-comparison.png), [normal GIF](../../../output/art/rc-014/framing-360/motion.gif), [reduced GIF](../../../output/art/rc-014/framing-360/reduced-motion.gif).
- Reproduction: `tools/preview_shadeling.ps1 -QaDirectory output/qa/rc-014/followup-boss-dodge -ArtDirectory output/art/rc-014/followup-boss-dodge`, then bundled Python `tools/validate_shadeling.py --qa-dir output/qa/rc-014/followup-boss-dodge --art-dir output/art/rc-014/followup-boss-dodge --report output/qa/rc-014/followup-boss-dodge/validation-report.json --package-gifs` and `tools/validate_asset_plan.py --report output/qa/rc-014/followup-boss-dodge/asset-plan-validation.json`.

The fresh engine logs retain host shader-cache/user-directory and root-certificate-store diagnostics, with no script/import/resource failure. These remain isolated desktop specimens, not final Combat integration or physical-device acceptance. Rights remain unresolved; broad owner approval is not inferred from the explicit pose-retention choice. Downstream ownership is unchanged as listed above. **RC-014 remains complete**, with no unmet acceptance requirement identified in this follow-up.

## 360-wide framing correction

October 12, 2026: the owner requests that the360 preview match the720/450 framing and scale. The current preview therefore uses the same `Rect(0,60,841,450)` arena crop, uniform `W/841` transform and foot mapping at every width. The360 viewport is now360×193, with texture scale0.3210463734 and foot(190.9156,157.5268). This corrects the comparison framing without changing any character paint, source/runtime image, anchor, animation state, fixture value or gameplay behavior. The old180² independent character placement remains documented historical r006 evidence.

Current outputs: [720 design](../../../output/art/rc-014/framing-360/arena-design-720.png), [450 desktop](../../../output/art/rc-014/framing-360/arena-desktop-450.png), [360 proportional arena](../../../output/art/rc-014/framing-360/arena-native-360.png), and [Godot render report](../../../output/qa/rc-014/framing-360/godot-render-results.json). The legacy `arena-native-360.png` filename is retained for compatibility; this image is an arena-only proportional specimen, not a full native-phone layout, touch/readability test or physical-device acceptance.

Fresh validation passes [359 focused source/import checks](../../../output/qa/rc-014/framing-360/validation-report.json), [194 Godot behavior checks](../../../output/qa/rc-014/framing-360/godot-render-results.json) and [16 framing checks](../../../output/qa/rc-014/framing-360/framing-validation.json). Independent visual review of all three arena sizes passes. The [preservation report](../../../output/qa/rc-014/framing-360/preservation-validation.json) records574 protected files unchanged;101 of102 PNG/GIF outputs match the prior boss-role follow-up byte-for-byte, with only the360 arena image changed. [Metadata/document validation](../../../output/qa/rc-014/framing-360/metadata-document-validation.json) confirms that the corrected presentation values match the unexecuted assembly recipe and retain the historical native mapping and common source/export anchors.

The earlier commands above record their respective deliveries. For current reruns, use `tools/preview_shadeling.ps1 -QaDirectory output/qa/rc-014/framing-360 -ArtDirectory output/art/rc-014/framing-360` and pass the same directories plus an explicit report under `output/qa/rc-014/framing-360` to the focused validator. This keeps original and boss-role follow-up evidence intact. The assembly recipe and source metadata record the corrected preview mapping; the artwork builder was not executed. RC-016 retains full responsive-screen integration ownership and RC-014 remains complete.

Next numbered task: **RC-015 — the layered crypt and separate Home tower illustration**. No Git checkpoint is required or performed.
