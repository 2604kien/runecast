# Approved reference artwork adoption — RC-016

## October 16, 2026 — Unused neutral resource retirement

The superseded generated neutral has been retired under the owner's unused-resource cleanup. It was no longer loaded by runtime code or used as a build or generation input. Its historical prompt, dimensions and original hash remain in [provenance.json](provenance.json) and [prompts.json](prompts.json); the [deletion manifest](../../../../output/qa/resource-cleanup-2026-10-16/deletion-manifest.json) records the exact removed source. The approved atlas, current generated assets, canonical actor masters and retained poses are unchanged.

## October 16, 2026 — Generated painted status frame

The Health/Energy/Turn frame now uses [status-frame.png](../../../../assets/ui/combat/reference/status-frame.png), generated with the built-in image tool from the approved screen and original status closeup. Its painted gold rails, closed ends, dividers and slate face replace the rejected local outline. The [exact prompt](status-frame/prompt.txt) and [provenance](status-frame/provenance.json) record the raw output, SHA-256, reference inputs, alpha and runtime sampling; the model version was not exposed.

The selected PNG is copied byte-for-byte without local painting or re-encoding. Runtime sampling fits its three compartments to the existing live cells and 54px frame; the 768px import stays within the texture budget. [Integrated screen](../../../../output/qa/rc-016/stats-generated-frame/normal-desktop.png), [comparison](../../../../output/qa/rc-016/stats-generated-frame/before-after.png), and [verification](../../../../docs/verification.md#october-16-2026--generated-painted-status-frame). The old code border/divider helpers are removed; no unused bitmap variant was added.

## October 15, 2026 — Original neutral actor and tighter scenery masks

Combat now renders the approved actor's original pixels from atlas Rect(285,145,295,290), through a [shared silhouette mask](../../../../assets/enemies/shadeling/reference/approved_actor_mask.gdshaderinc). The actor remains a separate foot-local sprite; the existing 512 logical canvas, canonical poses and character API remain available. Switching to attack/hit restores ordinary full-texture rendering. The scenery excludes the same silhouette and four small live intent/name/health regions, retaining the original architecture and floor everywhere else. The generated empty arena supplies only hidden fill.

The [focused rendered checks](../../../../output/qa/rc-016/whole-screen-art/arena-focused/results.json) pass eight checks, including exact source RGB across more than 350,000 recombined visible pixels, face/lantern/hand/boot coverage, absence of baked status content, and neutral/attack restoration. The shared mask quantizes source coordinates to 1/64 pixel to prevent differing sprite transforms from opening one-pixel seams. See the [recombined arena (retired)](../../../../docs/asset-cleanup.md#october-16-2026--unused-resource-cleanup) and [isolated actor (retired)](../../../../docs/asset-cleanup.md#october-16-2026--unused-resource-cleanup).

At this revision, the superseded generated neutral was archived byte-identically. Its runtime placement, import recipe and exact cache pair were retired after a zero-consumer check; the [path/hash manifest](../../../../output/qa/rc-016/whole-screen-art/actor-cleanup-manifest.json) records that earlier move and retirement. The unused archive was subsequently removed by the [October 16 cleanup](../../../../output/qa/resource-cleanup-2026-10-16/deletion-manifest.json). The current actor shares the already-loaded atlas, eliminating the separate 512² neutral texture allocation. No retained source PNG was rewritten.

## October 15, 2026 — Cast face continuity

The original center-only replacement met the darker Cast right-cap face at source x649. Cast now uses one clean material Rect(191,1678,103,59) across the full destination width, vertically between the existing caps, clipped to the inner points (165,1707), (190,1679), (653,1679), (675,1707), (651,1735), (190,1735). The original gold/cyan rim remains a separate ring above it. Middle and bottom center-ring samples use x191 with width103 at their original source heights to exclude the baked cost crystal and shadow.

[regions.json](regions.json) records the contours and mapping. Existing dimensions, caps, live values, interactions and source PNGs remain unchanged. [Current screen (retired)](../../../../docs/asset-cleanup.md#october-16-2026--unused-resource-cleanup), [built desktop (retired)](../../../../docs/asset-cleanup.md#october-16-2026--unused-resource-cleanup) and [verification](../../../../docs/verification.md#october-15-2026--cast-face-continuity) record the scoped correction.

## October 15, 2026 — Stats inner frame correction

The previous 27/11 stats caps cut across the diagonal inner bevel, allowing the rectangular replacement background to overwrite gold pixels. Outer-bound and child-padding checks did not cover that boundary; the earlier containment claim was incomplete. The stats source caps are now 40/19/40/19, with destination caps scaled by row height/79. The clean fill is clipped to the eight-point inner polygon, then the original rim ring is drawn above it.

The stats row renders at z30, above the arena environment/actor/status layers at z20/21/22 and below the inspector at z100. Live-row pixel checks found that arena bleed had covered its top three pixels at 720 px while stats used z0; only the stats draw order changes, preserving arena allocation, crop and geometry.

The top middle retains the original 11 source pixels of gold rail, followed by clean recess Rect(280,1592,60,8); the bottom middle uses Rect(90,1641,200,19) to exclude the old Incoming caption. [regions.json](regions.json) records both contours and the current sampling. The 54 px row, content margins and other UI are unchanged; no source PNG changed. [Before (retired)](../../../../docs/asset-cleanup.md#october-16-2026--unused-resource-cleanup), [corrected actual bar (retired)](../../../../docs/asset-cleanup.md#october-16-2026--unused-resource-cleanup), [current screen (retired)](../../../../docs/asset-cleanup.md#october-16-2026--unused-resource-cleanup) and [verification](../../../../docs/verification.md#october-15-2026--stats-inner-frame-correction) record the rendered result.

## October 15, 2026 — Display-only forecast and frame cleanup

The production forecast frame now contains only live Damage, Shield and Cost displays. Its `Control` is input-transparent and nonfocusable, with no tap/hold callback or details window. Card Info, other inspection controls and confirmed Pass remain separate interactions.

The player stats frame now uses the approved closed gold border Rect(40,1581,762,79) around its clean stats material, replacing open rails with mismatched ends. Its divider sample is only the upright Rect(281,531,10,29), rendered inside the frame clear of both rails; the 54 px frame and 30 px content well are unchanged.

The board crop ends at source y1255 before the next toolbar corner. The independently scaled right backdrop strip previously sampled x818 and included old board-corner gold around y1244–1252. [`reference_backdrop.gd`](../../../../scenes/ui/theme/reference_backdrop.gd) now samples x824 with width 17 and paints a width of 24k+1 to close the fractional seam over the candle underpaint. [regions.json](regions.json) records the sampling changes. No source PNG is modified.

[Current screen (retired)](../../../../docs/asset-cleanup.md#october-16-2026--unused-resource-cleanup), [integration](../../../../docs/rc-016-integration.md#october-15-2026--display-only-forecast-and-frame-cleanup) and [verification](../../../../docs/verification.md#october-15-2026--display-only-forecast-and-frame-cleanup) describe the current revision. Earlier dated notes about activating the forecast retain only historical meaning.

## October 15, 2026 — Header order and connector rotation

The original Rune Cast wordmark now sits on the left, with the live floor name on the right of the full-width 52 px header. Its source region, uniform scaling and painted header background are retained. Board Split and Join keep their approved central icon orientation while their live ports and connection strokes rotate.

The previous upper-left card sample reused the lower-left corner without changing its orientation and included background below the frame. It now uses the clean upper-right corner with a horizontal UV mirror, preserving the existing 11 px upper rim and excluding the original cost badge. Card dimensions, cost-symbol size and padding are unchanged; [regions.json](regions.json) records the corrected sampling.

The original reference pile bodies and emblems remain unchanged, with live counts and captions. Compact card cost symbols remain 25×29 with 20 px live numbers. Original source artwork is retained. [Current screen (retired)](../../../../docs/asset-cleanup.md#october-16-2026--unused-resource-cleanup), [integration](../../../../docs/rc-016-integration.md#october-15-2026--header-order-and-connector-rotation) and [verification](../../../../docs/verification.md#october-15-2026--header-order-and-connector-rotation) supersede the earlier header arrangement below.

## October 15, 2026 — Header and reference pile correction

The full-viewport header is 52 px high, with the live floor name on the left and the original wordmark region Rect(56,1,245,46) on the right at uniform scale. A clean Rect(310,2,132,36) patch fills the complete background before the gold lower rule. Pause remains removed. Stats excludes exterior stone pixels with a mapped silhouette; its 54 px frame and 30 px content well remain unchanged. The toolbar's left-middle cap now samples Rect(21,1260,20,107), excluding the original WIRING parchment edge around x42 that caused the line beside Pass.

[`reference_pile.gd`](../../../../scenes/ui/theme/reference_pile.gd) renders the separate approved Draw Rect(25,1418,95,136) and Discard Rect(725,1423,91,132) bodies at one uniform scale. Original compass/skull, stack edges and plaque rims remain source pixels; only their numerals are cleared for live counts. Captions remain live. [regions.json](regions.json) records each body, front face, emblem, plaque, numeral patch and silhouette. Obsolete generic deck/mirroring support is removed from `CombatSurface`. Compact-card costs use a 25×29 glyph and 20 px numeral.

No source PNG was added, modified or deleted. [Current screen (retired)](../../../../docs/asset-cleanup.md#october-16-2026--unused-resource-cleanup), [integration](../../../../docs/rc-016-integration.md#october-15-2026--header-and-reference-pile-correction) and [verification](../../../../docs/verification.md#october-15-2026--header-and-reference-pile-correction) supersede the earlier header/pile methods below.

## October 15, 2026 — Mobile presentation corrections

The source PNGs are unchanged. Runtime Cast and Pass parchment sampling now clips to the painted silhouettes recorded in [regions.json](regions.json), preventing neighboring background and caption pixels from appearing at their edges. Stats includes the complete bottom rim and uses 24/11/24/13 content margins, leaving a 30 px well in its 54 px frame. The live values use 26 px type and Turn uses 21 px. Navigation keeps its glyph and caption lanes at y13–43 and y45–69 inside an 82 px frame.

Discard applies `flip_h` to stack artwork only; `get_front_face_rect()` centers upright symbols and counts on the front card. The Combat header uses the live floor name at the left, with no wordmark or Pause, and the BOSS caption is removed. Production suppresses hover tooltips and invalid/unavailable x/circle badges while preserving availability guards, focus cues and tap/hold/Info/forecast/Pass details. Deferred layout callbacks ignore freed controls. [Current screen (retired)](../../../../docs/asset-cleanup.md#october-16-2026--unused-resource-cleanup), [integration](../../../../docs/rc-016-integration.md#october-15-2026--mobile-presentation-corrections) and [verification](../../../../docs/verification.md#october-15-2026--mobile-presentation-corrections) describe this revision. The original adoption record below is historical where superseded.

October 15, 2026. The owner requested correction of the remaining artwork across the whole screen. This permits sampling clean, separable decoration from the approved image, superseding the earlier reconstruction-only workflow. It does not permit replacing live controls with a flattened screenshot. [Current integration](../../../../docs/rc-016-integration.md#october-15-2026--approved-reference-artwork-adoption) and [verification](../../../../docs/verification.md#october-15-2026--approved-reference-artwork-adoption) describe the actual runtime.

## Exact sources and generation records

| Input | Retained original | Runtime import cap |
| --- | --- | --- |
| Approved decoration atlas | [approved-atlas.png](../../../../assets/ui/combat/reference/approved-atlas.png), byte-identical to the [approved reference](../../../../output/imagegen/approved/combat-final-v2-clean-board.png), 841×1870 | Original resolution |
| Original approved neutral | Atlas Rect(285,145,295,290), shared silhouette shader | Shares approved atlas |
| Generated empty arena | [arena.png](../../../../assets/environments/crypt/reference/arena.png), 1715×917 RGB | 960 px |
| Generated twelve-symbol sheet | [icons.png](../../../../assets/ui/combat/reference/icons.png), 1448×1086 RGBA | 768 px |
| Generated status frame | [status-frame.png](../../../../assets/ui/combat/reference/status-frame.png), 1987×791 RGBA | 768 px |

[provenance.json](provenance.json) records current original byte hashes, exact dimensions, imports, consumers and limitations, plus the explicitly retired neutral's historical record. The approved atlas SHA-256 is `ad5e7429a79c53d65c6ef00e5094b83b58738b10715a2478c64230bdbc6688ac`. The existing full-page crypt underpaint remains unchanged with a 1024 px import cap. The three active generated PNGs are the original built-in `image_gen.imagegen` outputs; no local raster repainting, extraction script or resized duplicate replaces them. Model/version and seed were not exposed by the tool. [Neutral/arena prompts](prompts.json), [icon prompt](icons-prompt.txt) and [status prompt](status-frame/prompt.txt) retain the exact requests. A request for extraction does not make the generated result pixel-identical.

## Sampling and live-content boundary

[regions.json](regions.json) identifies original empty sockets, separate border strips, clean material patches, silhouette masks and distinct pile regions. [CombatSurface](../../../../scenes/ui/theme/combat_surface.gd) assembles framed controls and excludes original text, cost badges and other live reference content. The static approved Rune Cast wordmark appears at the left of the live floor heading. [ReferencePile](../../../../scenes/ui/theme/reference_pile.gd) preserves the original pile emblems and bodies while replacing their numerals with live counts. Other labels and all game values remain live. Hidden face pixels are reconstructed from clean patches, so their arrangement is not identical to the obscured reference texture.

[ReferenceIcons](../../../../scenes/ui/theme/reference_icons.gd) samples measured visible bounds from the transparent generated sheet and normalizes coordinates after import downsampling. Canonical RC-012 SVGs remain unchanged for shared consumers. Circuit ports, connections, endpoint orientation and live selection/feedback remain functional rendering, not a painted circuit screenshot.

The [environment scene](../../../../assets/environments/crypt/environment.gd) places the empty generated arena at source Rect(0,60,841,450). Its [mask shader](../../../../assets/environments/crypt/reference/visible_edges.gdshader) preserves original visible scenery outside the shared actor silhouette and four small live-label holes. The original actor is drawn separately over its corresponding hole. Base-cool lighting is identity. [ReferenceBackdrop](../../../../scenes/ui/theme/reference_backdrop.gd) supplies the supporting page surround separately.

## Character and API limits

Normal Combat opts into the original approved neutral; isolated pack consumers retain the original default. [character.gd](../../../../assets/enemies/shadeling/character.gd) maps the masked approved atlas region into the existing 512×512 logical canvas and foot (256,448). Source-coordinate attachments, region bounds and shared mask are recorded in provenance. The superseded generated neutral is retired, with its prompt and hash preserved in the historical record. Existing attack/hit PNGs, attachment resource, canonical source masters and idle/attack/hit/defeat API are unchanged.

The current neutral uses original approved pixels. Generated symbols still differ, and hidden fill remains reconstructed. Retained live fonts do not establish the unidentified raster font's exact identity. RC-017 must reconcile visual continuity between this neutral and retained attack/hit artwork before accepting event-driven motion. No complete pixel-identical screen, device acceptance, new owner aesthetic approval or release-rights clearance is claimed.

Pass turn, circuit-button padding, removed card-category row, removed Incoming row and removed Cast-ends-turn caption remain the owner's explicit later exceptions. State-dependent values and board arrangements remain game data. The [cleanup ledger](../../../../docs/asset-cleanup.md#october-15-2026--approved-reference-surface-cleanup) and [deletion manifest](../../../../output/qa/rc-016/reference-art/deletion-manifest.json) retire the eighteen unused earlier surfaces while preserving prompts and historical provenance.
