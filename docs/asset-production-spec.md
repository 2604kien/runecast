# Asset production specification

RC-010 planning contract, October 9, 2026. The [asset manifest](asset-inventory.csv) identifies the bounded deliverables, consumers, ownership and readiness; the [RC-011 pilot brief](style-pilot-brief.md) is the first production handoff. This document chooses practical **proposed** dimensions, anchors, formats and budgets. They are not delivered assets, approved technical settings, runtime integration or physical-device acceptance.

The [four approved images](visual-reference.md) establish visual direction only. Keep strong dark outlines, angular silhouettes, matte painted shading, indigo/blue stone, warm candlelight, restrained gold and turquoise primary actions. Keep the centered full-body enemy without a visible player, compact rune choices, parchment Map without a legend strip, turquoise Resume and navy secondary Menu buttons. Never extract the flattened screen into a runtime background or bake live paths, health, energy, values, stock, costs or button labels into illustration.

The [accepted production rules](production-rules-spec.md#october-9-2026--accepted-rc-007-implementation-contract), [current gameplay](gameplay-rules.md), [board catalog](board-catalog.md), [touch contract](touch-interactions.md) and [presentation boundary](combat-presentation.md) take precedence over historical fixed-board mockups. All four board IDs share one socket/geometry system and one crypt; there are no four painted board sets. A production turn starts with two randomly positioned/rotated endpoints and fourteen empty cells. Straight/Corner/Split/Join supply is finite, all installed pieces clear after accepted Cast/Pass, and Free Spark expires without leaving a replacement wire.

<a id="general"></a>
## General

### Evidence and coordinate basis

Reviewed sources include `project.godot`, `export_presets.cfg`, `scenes/main.tscn`, `scripts/ui/main.gd`, `arena.gd`, `board_cell.gd`, `scripts/core/circuit.gd`, the content/rules documents above, the [roster](content-roster.md) and actual [task descriptions](project-plan.md). All four approved images were visually inspected. Actual placeholder captures inspected include [RC-009 production](../output/qa/rc-009/final-production.png), [selection/placement](../output/qa/rc-008/touch-capture-1791519954-3060/selected-tool-preview.png), [exhausted stock](../output/qa/rc-008/touch-capture-1791519954-3060/unavailable-stock.png) and [small inspector](../output/qa/rc-008/touch-capture-1791519954-3060/small-portrait-inspector.png). These establish current layout and states, not production-art readiness.

| Observed current implementation | Consequence for production |
| --- | --- |
| Godot project declares 4.7 / GL Compatibility, logical design viewport 720 × 1600, `canvas_items` stretch, portrait orientation; desktop override 450 × 1000 | Dimensions below are logical design pixels unless explicitly called texture pixels. A 137-pixel cell appears about 86 physical screenshot pixels wide at the desktop override. Do not equate either with mobile density-independent units. |
| Main content margin 18; arena minimum height 310; arena drawing coordinates 680 × 300 | Supply a reusable overscanned arena asset and map its crop to the arena, preserving aspect. The source is not a full Combat screen. |
| Board side = `min(137, floor((viewport_width - 70) / 4))`, gaps 6 | Preview cells at 137 design pixels and at 72 pixels in the 360-wide synthetic viewport. These are checks, not a new minimum-device decision. |
| Hand cards minimum 142 × 92; ordinary buttons minimum 66 × 50; editing row height 58; Cast height 64 | Compact labels, symbols and scalable frames must fit the existing controls. Padding must not force clipped values or shrink active target areas. |
| Inspector width 4–96% and height 12–88% of viewport, content margins 18, persistent Close/Pass controls height 64 | Frame must support independently scrolling live text and stationary actions; it must not turn the inspector into a baked image. |
| Theme, board and actor are code-drawn; symbols are text; only `assets/ui/app_icon.svg` is a current image asset | Approved references do not imply supplied production layers/fonts/sprites. Retain the prototype until its replacing integration task. |

Coordinates have origin at top left, +X right and +Y down. Raster source coordinates are texture pixels. For art exported at 2×, divide export pixels by two for nominal design pixels; explicitly record exceptions such as the character sprite scale. Source-master resolution is an editing choice, not the runtime Control size. Supply anchor metadata even when a file is transparent.

### Directories, filenames and revisions

Use lowercase `snake_case` filenames and preserve stable asset/content IDs. Revisions change the delivery record, not the ID. A display-name change must not rename `shadeling`, `training_shadeling`, `board_training`, `board_gallery`, `board_ossuary` or `board_belfry`.

| Purpose | Planned convention |
| --- | --- |
| Painted character master | `source-assets/characters/<actor_id>/<actor_id>.ora`; retain generator originals and original editing-app file beside the open layered interchange file |
| Painted environment/Home master | `source-assets/environments/<asset_id>/<asset_id>.ora` |
| UI, icon, font and audio sources | `source-assets/ui/`, `source-assets/icons/`, `source-assets/fonts/`, `source-assets/audio/`; each deliverable keeps its own subfolder and notes |
| Motion and release sources | `source-assets/animation/`, `source-assets/release/`; technical source copies do not substitute for editable Godot resources |
| Pilot only | `source-assets/pilot/`; runtime-format candidates stay here until the final production owner adopts them; previews in `output/art/rc-011/` |
| Runtime imports | `assets/enemies/<actor_id>/`, `assets/environments/`, `assets/ui/`, `assets/icons/`, `assets/fonts/`, `assets/audio/` |
| Runtime scenes/resources | Character scene inside `assets/enemies/<actor_id>/`; VFX scenes in `scenes/vfx/`, shared animation/particle textures and resources in `assets/animation/`; theme resources in `assets/ui/` |
| Review evidence | `output/art/rc-NNN/<asset_id>/` and `output/audio/rc-NNN/<asset_id>/`; integration captures remain under a dated/task-specific `output/qa/` folder |

The manifest's more specific path wins over a family example here. A planned destination is not an existing-file assertion. Put `delivery.md` beside each source master, with asset ID, task, revision `r001`, date, creator, exact source filenames, dimensions, anchor/crop/slice metadata, export settings, import instructions, provenance/licence status, known limits and evidence paths. Preserve previous raw generations, prompts and accepted revision previews under revision subfolders; avoid `final_final` filenames. Runtime exports keep stable names (`neutral.png`, `attack.png`, `hit.png`, for example); promote a reviewed revision deliberately and update its manifest evidence.

### Format, colour and import defaults

Painted master: layered OpenRaster `.ora`, plus the original editable application file when OpenRaster cannot retain a feature; keep a flattened reference export for visual comparison. Vectors: plain editable SVG without embedded raster screenshots, external references or live fonts; outlines for glyph art only. Runtime: 8-bit-per-channel sRGB PNG, RGBA for cutouts and RGB where wholly opaque; SVG for small geometry/symbols; TTF/OTF fonts; Godot `.tscn`/`.tres` resources; audio as specified below. Do not use JPEG for outlined transparent sprites or UI. Font text stays runtime text.

PNG uses straight/unassociated alpha. Remove colour fringes from the generating background, paint valid edge colours under partially transparent pixels, and inspect on black, white, turquoise and in-game indigo. A transparent pixel must not contain an obvious white/black matte that appears under filtering. Keep ground shadows and glow on separate nodes/layers; an intentional translucent glow is not dirty alpha. Export to sRGB with a consistent profile; reject accidental CMYK, HDR/tone-map changes or inconsistent gamma between layers. Do not premultiply the file then let the renderer multiply it again.

Proposed initial Godot import policy: lossless texture import, linear filtering for painted art, repeat disabled, no mipmaps for fixed-scale UI/icons and character/arena sprites at this first scale range, no automatic upscale. Import SVG at the documented scale so its rasterized size is known; SVG is not free of decoded texture cost. Preserve useful PNG edge fixing and confirm its actual effect during RC-016. Do not silently change compression/colour flags to solve visual defects. If later profiling enables mipmaps or platform compression, record the import revision, new memory and device/readability evidence. These are recommendations for production tasks, not changes to current project settings.

`export_presets.cfg` currently uses `all_resources` and excludes `docs/*`, `output/*`, `tools/*`, `tests/*`, `.tools/*` and `.local/*`; it does **not** exclude planned `source-assets/`. The first production/integration owner must establish source-folder import exclusion (for example `.gdignore`) and explicit export exclusions before adding masters to the project. RC-016/RC-042 check their delivered assets, RC-021/RC-022 establish platform export behavior, RC-048 profiles package contents, and RC-050/RC-053/RC-054 audit the shipped result. This documentation task does not edit export configuration. Do not package prompts, references, master files, contact sheets, unused revisions or audio masters.

### Provisional gates

RC-011 validates character density/scale, outline weights, font direction, alpha, Spark at small sizes, frame slices and the lean animation approach. RC-012/RC-013 establish real imports and fonts; RC-014/RC-015 establish final production art. RC-016 proves integration. RC-021/RC-022 establish device/toolchain baselines; RC-023 checks the first polished encounter; RC-044, RC-047–RC-049 verify accessibility, lifecycle and performance on supported devices. A pilot may revise a proposed technical value within the approved composition, updating the spec, brief and manifest together before dependent production begins. No human approval, rights clearance or device result is inferred from this planning document.

<a id="characters"></a>
## Characters

Five packs only: `shadeling` (RC-014), `wickling` (RC-037), `stone_sentinel` (RC-038), `chain_warden` (RC-039), `bell_keeper` (RC-040). RC-016 integrates Shadeling illustration, RC-017 adds its/common motion, RC-042 integrates the remaining packs. Their production owners own their isolated assets/previews; they do not concurrently edit the shared main scene/presenter/theme.

### Canvas, anchor and scale

Every full pose uses a **1024 × 1024 master → 512 × 512 runtime PNG**. Common foot anchor is runtime **(256, 448)**, master **(512, 896)**; ground line is runtime Y448. Never trim each pose independently. The complete animation envelope, including lantern, chain, flame, cloak and motion overshoot, stays within runtime **X32–480, Y32–480**. At least 32 pixels of transparent outside padding remains. Neutral Shadeling body plus lantern fits **X80–432, Y88–448**; keep feet and lantern visible. Widening a character is preferable to scaling its head out of the intent-safe area.

Place the foot anchor at arena drawing coordinate **(340, 233)** in the current 680 × 300 reference arena, then use the arena's layout transform. Proposed Shadeling scale is **0.46 design pixels per runtime texture pixel**, with pilot comparisons at 0.42 and 0.48. Its 360-pixel opaque height therefore displays at approximately 166 design pixels at 0.46; the full transparent canvas displays at 236 pixels. This is intentionally an explicit texture-to-design scale, not a 2× UI convention. Keep the actor inside the clear region described below; do not squeeze the whole sprite nonuniformly when the screen aspect changes.

| Actor | Neutral visible-height target in the 680 × 300 arena | Distinctive requirement |
| --- | --- | --- |
| Shadeling | 160–173 design px | Lantern, ragged angular cloak, visible full body; normal introductory role, no baked BOSS label |
| Wickling | 135–155 | Smaller candle/flame silhouette; virtual foot anchor remains the same even when it floats 8–16 pixels above ground |
| Stone Sentinel | 165–178 | Broad broken stone; readable windup/swing without inventing armour mechanics |
| Chain Warden | 170–180 | Tall masked chain silhouette; chain excursion remains inside envelope; no cell-lock/status illustration |
| Bell Keeper | 173–181 | Large bell-headed mass achieved mostly through width; one phase-change pose/overlay on the same actor |

The 181-pixel height ceiling keeps the head below the stage's intent region when grounded at Y233. These are proposed relative-scale targets; a larger accepted arena may use uniformly larger art later, but RC-011/RC-016 must first prove it preserves the approved full-body composition and control space. Scene metadata records per-actor scale, opaque bounds, foot anchor and attachment points, rather than shifting the common ground line to disguise a mismatch.

### Provisional motion method and minimum pack

Choose a lean Godot pose/transform method for the first pass: neutral, attack and hit full-canvas transparent poses, with idle bob/lantern movement and defeat collapse/fade driven by editable animation. No full frame-by-frame sheet, skeleton toolchain or 3D rig is required. Layered master must retain body, arm/held item and cloak/flame elements where useful; optional exported parts share the full canvas or include exact offsets/pivots. Supply attachment metadata `foot`, `body_center`, `head`, `attack_origin` and held-item pivot. Do not hide missing limbs behind a baked ground shadow.

State names are **`idle`, `attack`, `hit`, `defeat`**; Bell Keeper additionally has the **`phase_intensified`** overlay/pose variant, reached through a one-shot **`phase_change`** clip. Idle loops; attack and hit are one-shot clips returning to idle only when their controlling presentation allows; defeat ends in a stable hidden/fallen pose and never loops back. Attack includes a clear anticipation and contact pose. A normal hit and zero applied damage must be distinguishable without fabricating HP loss. Guardian phase treatment is a single pose/overlay/accent, not a new character or second music track; its timing is driven by RC-033/RC-034 events, not inferred by art from an HP bar. Lethal outcomes skip retaliation and phase transition.

Deliver `neutral.png`, `attack.png`, `hit.png`, an isolated editable `character.tscn` and state/anchor notes. Bell Keeper adds `phase_intensified.png` or an explicitly documented editable overlay. RC-014 may supply the poses/parts before RC-017 finalizes animation; it must document the intended four-state use. RC-037–RC-040 reuse RC-017's accepted presentation contract and include motion previews. For RC-011 only, one polished neutral illustration with separable layers and a short four-state technical motion study is sufficient; pose feasibility sketches are acceptable. RC-014 owns the refined final pose pack.

Acceptance preview: every actor on the **same ground line and same 680 × 300 arena crop**, neutral silhouette, black/white/indigo alpha backgrounds. RC-017 uses Shadeling plus explicitly labelled proxy envelopes for future actors; it does not wait for RC-037–RC-040. Each later pack updates the scale sheet, and RC-042 supplies the completed five-actor scale contact sheet. Show target sizes, not five independently resized thumbnails. Show the complete attack/defeat envelope, intent, live name and health overlays. A placeholder may stand in for a not-yet-produced actor only when labelled clearly.

<a id="environment-home"></a>
## Environment and Home

### One crypt with shared layers

Crypt source canvas is **2880 × 1440**, exported as aligned **1440 × 720** layers: `background.png`, `floor.png`, and optional `foreground.png`. Their origin is (0,0); they must remain full-canvas with no automatic crop. At a nominal 0.5 export-to-design scale, the complete art spans 720 × 360 design pixels. The canonical **680 × 300 arena** is the centered design crop **Rect(20,30,680,300)**, export crop **Rect(40,60,1360,600)**. This provides 20 design pixels each side and 30 top/bottom of overscan. Ground at stage Y233 equals export Y526, with stage center/foot (340,233) equal to export (720,526).

| Stage region in the 680 × 300 crop | Contract |
| --- | --- |
| Intent: X200–480, Y10–52 | Low-detail, dark/cool backing; no bright candles, chains or trim crossing icon/value |
| Actor: X170–510, Y52–245 | Clear centered full-body silhouette; keep brightest environmental light outside head/body silhouette |
| Name and health: X170–510, Y247–297 | Dark/quiet floor/background under live label/bar; no painted names, values or gold line mistaken for health |
| Floor overlap: Y200–250 | Background extends behind floor through at least 24 design pixels (48 export pixels) of overlap; no transparent seam during scaling |
| Foreground | Restrict opaque foreground largely to outer 60 design pixels and bottom 20; must not cover the actor's feet, lantern, name/health or any UI |

Keep the background painted behind the floor, and paint hidden overlap rather than abutting edges. Optional foreground must earn its memory/readability cost; omission is acceptable and must be recorded. Use one quiet base with **three parameter presets only**: base cool (training/gallery), warm candle (ossuary/recovery), dark (belfry/guardian). Shared art plus tint/light intensity/one reusable glow provides variation; do not export four complete environments or four board paintings. Preserve health/intent/port contrast after each preset. Any guardian accent belongs to its single actor/VFX treatment, not another biome.

RC-015 supplies layers, masks only where necessary, crop/overlap metadata and contact sheets at 680 × 300 plus the actual 684 × 310 integration slot. RC-016 decides the precise aspect-preserving fit/crop within the available overscan; no anisotropic character stretch. All layers use the same transform. A crop beyond the declared overscan requires a reviewed revision; it cannot silently cut feet or reveal empty corners. Do not add parallax unless the static scene is already accepted and the movement fits the overscan/performance budget.

### Separate Home illustration and wordmark

Home master **1440 × 3200**, runtime **720 × 1600** opaque PNG. Preserve the approved moonlit tower composition; tower is separate from logo and buttons. Treat **X36–684** as the horizontal focal safe region. Proposed content reservations in the 720 × 1600 design canvas: separate logo area **X36–684, Y70–400**; primary tower read **X110–610, Y340–1020**; quiet live-control backing **X100–620, Y1010–1450**. These describe production clearance under the approved hierarchy, not fixed Control coordinates or a redesigned Home.

The outer 36 pixels per side and top/bottom 80 pixels must tolerate cropping without losing a critical silhouette. Preview center-cropped cover at 9:16, 9:20 and 9:21.5 ratios. A short display may show less decorative sky/floor; controls/layout must remain usable through responsive placement/safe areas, not stretching the painting. RC-044 determines supported layouts. Painted moon, tower and candlelight are fine; no logo, Continue/New Run/Options text, save-state indicator or invisible fake touch control may be baked into the background.

The separate in-game wordmark (RC-013) uses editable vector lettering or a **1536 × 768 layered master → 768 × 384 transparent PNG**, centered art with 32 export-pixel outer padding. It must work in the large Home logo zone and a simplified header treatment; a tiny header can remain live text when the full ornament is illegible. The logo does not force one raster to serve every resolution. Distribution refinements belong to RC-051 and must not delay RC-042 Home acceptance.

### Map and small progression decoration

RC-041 supplies a reusable parchment surface **1440 × 2880 master → 720 × 1440 PNG** with 36-pixel export edge/corner safe area, quiet central field and optional separate edge ornaments. If implemented as a nine-slice frame, slices are 36 export pixels on all sides and the center texture must stretch acceptably; no noisy repeated seams. Route connections, room symbols, title, current location text, checks, locks and gold/turquoise highlights are live overlays. Use six room types only; a reward/chest symbol is not an extra treasure-room type. No encounter legend strip.

Shop/recovery/event decoration is fulfilled by the scoped **128 × 128 editable SVG symbols** on shared panels, with no mandatory additional painted vignette. The `event_symbols` pack supplies only `stone_bowl.svg` and `etched_desk.svg`; Lost Satchel reuses the room-shop bag and Sealed Reliquary reuses the reward chest. `progression_symbols` supplies six motifs: reward chest, remove card, heal, victory wreath, defeat broken seal and abandon exit. Existing rune/relic/health/currency/upgrade symbols cover the other choices. Results reuse theme frames, the relevant outcome emblem and shared result VFX. No bespoke illustration per text choice or full-screen event painting.

<a id="circuit-icons"></a>
## Circuit icons

### Shared exact geometry

SVG symbol canvas is **`viewBox="0 0 128 128"`**, default export/import 128 × 128 texture pixels. Decorative glyph safe bounds are **X16–112, Y16–112**. Glyph center is (64,64); an optical baseline at Y104 may guide standalone icon alignment. Runtime label baselines belong to text layout, not SVG. Export compound appearance without external fonts, linked files, filters that change geometry bounds or hidden bitmap screenshots. Keep named editable layers `outline`, `fill`, `detail`; include a simple one-colour version/preview.

Ports use **N(64,0), E(128,64), S(64,128), W(0,64)**, with center (64,64). Coordinate scale is cell side/128. Port channels stay open through the tile's decorative border within 10 normalized units either side of each port. The renderer connects to the true cell edge/gap; the frame never moves a port inward to accommodate gold trim. Current placeholder lines stop 3–4 design pixels short of the edges; a future precise renderer may bridge the 6-pixel grid gap with its own shared overlay. RC-012/RC-016 must visually validate matching adjacent edges without altering the model's ports.

| Piece at rotation 0 | Input | Output | Edit behavior |
| --- | --- | --- | --- |
| Begin | None | E | Rotate 0–3; no Flip/Erase/replacement |
| End | N | None | Rotate 0–3; no Flip/Erase/replacement |
| Straight | W | E | Rotate; Flip swaps input/output |
| Corner | W | S | Rotate; Flip swaps input/output, not a mirror of the art |
| Split | W | E and S | Rotate; no Flip; show live physical-piece energy cost |
| Join | N and E | S | Rotate; no Flip; do not draw a three-way output |
| Installed effect rune, including Free Spark | W | E | Rotate; no Flip; same straight ports for every scoped effect |
| Technique | None | None | Hand action; never imply it can be placed on the board |

Directions use the existing model order N0/E1/S2/W3. Rotate is a clockwise quarter-turn about (64,64). Flip reverses Straight/Corner input/output on their existing geometry; it does not move the connected edges. Rotate only geometry/directional decoration: names, costs, values and temporary/upgrade badges remain upright. Begin and End must read as distinct source/sink silhouettes even when both point in the same on-screen direction. A one-colour arrow shows output; arrowheads cannot be replaced by colour alone.

Proposed normalized weights: dark silhouette outline **8 units**, coloured symbol main strokes **6 units**, detail no thinner than **3 units**. Wire stroke **5 design pixels at a 137-pixel cell**, scaling down only to **3 pixels** at the 72-pixel inspection test; arrowhead length 12 and half-width 6 design pixels at 137, reduced proportionally subject to legibility. Use crisp joins and restrained glows; RC-011/RC-012 may simplify internal details at 24/32-pixel icon display sizes. No art revision may change a port graph.

Use code/vector geometry for wires, arrows and live traversal. Painted tile material is a separate underlying layer. Never raster-paint a predetermined circuit into the socket or environment. The sixteen sockets are one reusable asset, with overlays for empty, selected, focused, eligible `+`, unavailable `x`, powered/unpowered, incomplete/invalid, temporary and upgraded states. Do not produce art for blocked production cells; blocked historical fixtures keep their existing development representation.

### Symbol scope and sharing

RC-012 produces Begin/End, four connector tools, starter Spark/Shield/Focus/Conjure, shared temporary marker, health/energy, initial attack intent, editing/inspection/cancel/Pass controls and Menu/Map/Guide/Sound on/off. RC-041 extends the same library for the remaining roster runes, six relics, six room types, currency, service/event/result needs and any implemented final intent distinction. The manifest/mapping table enumerates the individual scoped consumers.

Free Spark reuses the Spark glyph plus shared temporary badge; a cheap/free value is live text, not another painted Spark. The eight upgrades reuse base rune icons plus a shared upgrade marker. Damage-only intents reuse the attack symbol plus live amount; new poses or alternating attack strength do not require a unique icon per turn. Reserve multiple-value space for mixed effects such as Cinder Guard; no glyph may obscure either value. Stock uses all four available/total counters, exhausted `0 / total` and an inspectable unavailable state; no infinity symbol in production.

Deliver SVG masters/runtime imports plus a labelled contact sheet at **128, 48, 32 and 24 pixels**, a monochrome sheet, and board composites at **137 and 72 design-pixel cells**. Verify all rotations and legal Flip states against the table. Keep labels, cost bubbles, values and badges on independent live layers, with at least 4 design pixels between them and the nearest glyph stroke where layout allows. Any small-size conflict is resolved in the pilot/theme layout, not by hiding the number.

<a id="ui-typography"></a>
## UI and typography

### Reusable frames and margins

RC-013 owns one reusable theme, not a separate illustration for every button/screen. Use editable SVG/painted masters, PNG/SVG export and Godot Theme/StyleBox resources. Stateful tint/overlays are preferred to seven copies of identical decoration where they preserve the intended appearance.

| Family | Proposed runtime texture and source | Slices and live content safe area |
| --- | --- | --- |
| Primary turquoise / secondary navy button | Runtime **512 × 128**, layered master **1024 × 256** | Nine-slice left/right **24**, top/bottom **20 runtime texture px**; nominal 2× use. Content padding **16 horizontal / 10 vertical design px**; minimum control 66 × 50, with longer labels expanding/using the existing row layout |
| Board socket / rune card frame | Runtime **256 × 256**, master **512 × 512** | Nine-slice **16 texture px** on each side; at nominal128 design square borders occupy8. Leave four port channels clear. Stretch center with independently placed glyph/text; support 137/72 square cells and 142 × 92 hand cards without stretched symbols |
| Panel / dialog / inspection frame | Runtime **256 × 256**, master **512 × 512** | Nine-slice **24 texture px** each side; content padding at least18 design px, matching inspector. Ornaments outside slices must not intrude into scrollbars/Close controls |
| Health/energy/progress track | Runtime **256 × 64**, master **512 × 128** | Left/right caps16, top/bottom8 texture px; separate fill/track; fill changes by live value, not exported percentages; labels sit independently above/inside only where readable |
| Small badge | Editable SVG128², import64² | Shape safe8–56 in64 export; separate live count/rank text. TEMP shape and upgrade chevron/star must differ in silhouette |
| Fullscreen dim layer / focus / selection / placement feedback | Godot colour/style/vector resource | No full-screen raster. Focus ring and selection stroke stay outside live content; clipping/overlap reviewed at smallest controls |

Slice margins are texture-pixel measurements, not an instruction to add that many logical pixels to every control. Theme resource records the texture-to-design scale and content margins explicitly. For the smallest 66 × 50 controls, supply a **compact inset** using the same frame with **8 horizontal / 6 vertical design-pixel content padding** and simplified inner decoration; retain the target bounds and live text. Standard16/10 padding remains the default elsewhere. Test66 × 50,142 × 92, wide64-high Cast, narrow inspector and large Home/Menu actions. A frame that needs a taller control than the existing contract must be reviewed as a layout change during RC-016/RC-044, not silently imposed by the export. Parchment uses the distinct **720 × 1440 /36-pixel slice** contract under [Environment and Home](#environment-home), not this generic256-square panel.

### State contract

| State | Required appearance and use |
| --- | --- |
| Normal | Calm matte fill, restrained gold edge, readable live label |
| Pressed | Small inset/darker center plus changed edge highlight; no movement of the actual hitbox |
| Focused | Additional high-contrast outline visible on both turquoise and navy; remains distinct from selection |
| Selected | Persistent outline/check/notch, used for tools/cards/navigation and Inspect ON; colour is supplemental |
| Disabled | Muted fill/label while preserving legibility; unavailable reason supplied by the live UI where relevant |
| Invalid | Error cross/broken path cue plus warm outline and explanatory live text; never only red; distinct from an unfinished but legal edit |
| Unavailable/inspectable | Muted fill with stock/lock/unaffordable marker; still readable/inspectable where the interaction contract requires; do not use disabled input semantics merely to draw exhausted stock |

Other overlays compose with these: eligible `+`, protected/unavailable `x`, temporary badge, upgrade badge, current/available/completed/locked node state, sold/used service state and Sound on/off. Focus may coexist with selected/unavailable. Pressed is transient; it must not erase the selected marker. Disabled primary and disabled secondary remain recognizable as the same component. Opacity cannot be the only distinction on the dimmed Menu.

Home uses Continue/New Run/Options with no-save (Continue unavailable), valid save, invalid/incompatible-save explanation and replace-run confirmation. Menu uses turquoise Resume, navy Options/Shop/Quit, room-gated disabled Shop explanation and safe Quit/abandon confirmation flows. Shared Options uses volume sliders/toggles, mute and reduced-motion states; Home and Menu reuse the same surface. Bottom navigation shares four controls, selected-page focus and Sound on/off. Map nodes use turquoise current plus a locator shape, gold available plus an outer ring, completed check, and locked/inaccessible treatment plus explanatory inspection. All route connections remain live.

Rewards/collection/shop/recovery/events/results reuse panels, compact cards, shared selection frames, confirmation dialog, affordability/owned/sold/used/eligible markers and live text. Use one shared empty/unavailable message surface. Upgrades/removal show the actual selected permanent instance and live before/after values. Result victory/defeat/abandon variants do not add new environment paintings. Details/Pass and RC-008 inspection preserve a scrolling body and fixed buttons; do not insert an activation button for techniques inside the inspector.

### Font direction and text

Proposed families for RC-011 comparison: **Noto Serif SemiBold** for display headings and large action labels; **Noto Sans Regular / SemiBold** for body text, compact labels and numerals. These are **unacquired candidates**, not current bundled or licensed project assets. RC-012 must obtain exact font files from an authoritative source, record version/hash, actual licence file and attribution requirements, and verify embedding/redistribution before marking them usable. If the pilot cannot acquire them, its annotated direction comparison may use Godot's existing default font; that does not clear a future font licence. A local/default fallback does not silently become a shipped production family.

| Role | Proposed design-pixel size/weight | Acceptance concern |
| --- | --- | --- |
| Display title | 28–36, serif semibold | Rune Cast wordmark is a separate custom graphic; headings remain text |
| Primary/large action | 24–28, serif semibold or sans semibold if clearer | Continue/Resume/Cast consistent; label/cost remain live |
| General UI/body | 20, sans regular/semibold | Current default is20; preserve contrast and avoid condensed long labels |
| Inspector text | 22–24, sans regular; title28–32 | Small viewport body scrolls; no shrinking to fit whole explanation |
| Compact board/tool labels | 14–18, sans semibold | Current board labels14/tool labels15 are evidence, not a proven mobile minimum; test at137/72 cells and enlarge/shorten if required |
| Values / stock | 18–22, sans semibold, tabular figures if available | Clearly distinguish0/O,1/I,5/S; all four available/total counters and cost/value positions |

Ship only necessary regular/bold/semibold weights after actual review; do not carry a full font family by default. Fallback must cover English letters, digits, punctuation, arrows used by text, multiplication/dash/apostrophe and required accessibility labels; game pictograms should use the SVG library rather than rely on uncertain Unicode glyphs. Inspect Godot font-import settings and missing-glyph warnings. Translation production is outside scope; the typography layout must still tolerate existing long English labels and accessibility text scaling without baking text into art. RC-044 and device tasks settle actual minimum readable sizes/contrast; pilot screenshots alone cannot prove finger comfort or safe-area compliance.

<a id="animation-vfx"></a>
## Animation and VFX

RC-017 owns the shared editable Godot presentation adapter and effects; RC-037–RC-040 deliver actor-specific motion/accent pieces, RC-042 attaches final roster/progression presentation. Use `.tscn` scenes and `.tres` animation/particle/material resources, retaining editable curves. Shared textures use at most **256 × 256 RGBA** per particle/glow motif unless a documented preview proves a larger one is necessary; vector/gradient drawing is acceptable. No baked full-screen video.

Attach each effect to a named target: board cell center/port coordinates, actor `foot`/`body_center`/`attack_origin`, player-stat control, card UID view, or result panel center. Scene-local origin must match that anchor and be documented. Draw background/floor first, then separate ground shadow, actor, actor/world accents, live UI, cell traversal overlay, and modal/inspection surfaces last. Effects cannot intercept input or cover critical ports/numbers with opaque particles. Screen-wide flashes are unnecessary; use local rings/glows and a reduced-motion alternative.

| Shared effect | Event/trigger and treatment | Timing proposal / completion |
| --- | --- | --- |
| Idle | Active actor's `idle` scene animation | 1.6–2.4s loop, subtle≤3 design-pixel bob; nonblocking; stop on teardown |
| Spell traversal | Accepted `cast`, using detached before-board/forecast active path | 0.25–0.45s total traversal, not an independent spell per branch; batch waits |
| Damage / enemy hit | `damage` requested/applied values; hit on actual affected actor | 0.12–0.22s; show actual HP lost, distinguish zero; no extra damage event |
| Shield | `shield` and `retaliation.blocked` | 0.15–0.25s local shield pulse on player-stat area; do not draw a player character |
| Enemy action | `retaliation` | 0.25–0.40s attack anticipation/contact/recover; absent after lethal Cast |
| Expiry / clearing | `effect_consumed`, `temporary_expired`, `board_piece_cleared`, `turn_cleanup` | Group cells into one≤0.20s visual sweep while retaining event order; no replacement-wire animation |
| Draw / create / energy / technique | `technique`, actual `card_drawn`/`card_created`, `turn_started` | 0.10–0.20s grouped fan/pulse; never animate cards not actually supplied |
| Victory / defeat | `battle_ended` outcome | 0.4–0.7s result/actor treatment with stable final state; future run-result flows reuse it |
| Guardian phase | Future RC-033 event after surviving retaliation/next-turn boundary | One≤0.4s accent/pose on same actor; no HP polling and no lethal phase transition |
| Progression gain / reward / upgrade / heal | Future accepted transaction/result notification from owning run system | Shared0.15–0.35s icon/panel pulse; UI-only and one per committed transaction |

These are provisional pacing targets, not measured performance or a hard requirement to wait through a long chain. Typical Cast presentation should finish within **1.2s**, including grouped cleanup/draw; RC-017 may shorten/combine cosmetic tails without changing event order. Decorative idle, focus pulses and ambient flame are nonblocking. Cast/Pass/technique presenters complete exactly once after their relevant visual steps; reduced motion still completes. Menu/help/sound remain usable under the existing controller contract. Never implement completion by invoking a gameplay command.

Consume the detached event batch from `present(result, completed)`; the model has already paid, damaged, cleaned up and drawn. Animation never applies consequences, selects random content, mutates stock or infers an extra hit from branches/particles. Use `action_id`/`sequence`/`encounter_id` to avoid duplicate playback. On cancellation/restart/teardown, stop owned tweens/timers/audio, clear obsolete node references and prevent late writes. The controller's token guard is defense, not permission to leave effects running. A future-only event mapping stays marked proposed until its owning system supplies a real event.

Reduced motion: static selected/focus/port cues, instant or≤0.1s opacity/colour transitions, no shakes, no travel trails or bobbing, and still-visible outcome/expiry feedback. Effects that merely decorate need not delay action completion. Preserve sound settings independently; reduced motion must not silently mute feedback.

<a id="audio"></a>
## Audio

RC-018 produces the bounded shared SFX library. RC-019 produces exactly two music loops (Home/exploration, combat) and one crypt ambience bed. RC-020 owns audio buses, playback/settings, event binding and replacement of the current cast tone; RC-042 binds future roster/room cues after their systems exist. Current placeholder is code-generated mono **8-bit 22050Hz**, 2205 samples (0.1s), 440Hz decaying sine in `main.gd`; it is not a delivered SFX master or production recording.

### File and level contract

| Delivery | Format and proposed limits |
| --- | --- |
| Editable source | Original DAW/project/session or generator output/settings where available, plus consolidated **48kHz 24-bit PCM WAV** master; preserve sufficient source head/tail for revision |
| Short runtime SFX | **48kHz 16-bit PCM WAV mono** by default; stereo only for an intentional spatial texture. Most0.05–1s, maximum2s without a documented reason |
| Runtime music | **48kHz stereo Ogg Vorbis**, initial target160–192kb/s, **60–120s per loop**; retain uncompressed48kHz24-bit WAV master and exact loop sample points |
| Runtime crypt ambience | **48kHz stereo Ogg Vorbis**, target96–128kb/s, **30–60s loop**; one bed reused across crypt rooms |
| Cue metadata | Stable cue/manifest ID, variant list, sample count, channel count, true-peak/loudness measurements, loop start/end in samples, intended bus/gain, event mapping, creator/source and rights |

Trim accidental silence; permit only intentional attack/decay. Short fade-in/out (typically2–10ms) prevents clicks without blunting a purposeful transient. Normalize by listening in context, not identical waveform peak alone. **Provisional SFX target: true peak≤−3dBTP**, consistent perceived level across comparable cues; very short sounds should be matched by peak/listening rather than a misleading integrated LUFS number. **Music target−18LUFS integrated ±2, true peak≤−2dBTP; ambience−26LUFS integrated ±3, true peak≤−3dBTP**. These are mix starting points, not platform mandates. RC-020 verifies headroom when effects/music/ambience overlap and adjusts bus gains; do not brickwall every cue to a target.

Record measurements and tool/settings in delivery notes; do not claim a meter result from file format alone. Export no clipped sample, DC offset, unintended reverb cutoff or audible loop seam. Review loop boundary at least five repeats on headphones and ordinary speakers, including after runtime codec import. Crossfade composition/ambience tails only where needed and document the chosen loop points; a crossfade must not duplicate a percussion beat.

### Shared event-to-cue mapping

The manifest IDs remain authoritative; semantic cue names below describe routing and can be the stable basename. There is one sound per meaningful action, not one per frame/particle, branch or duplicated signal subscription.

The initial library is bounded to **16 manifest families /21 runtime WAV files**. Source notes may retain rejected takes, but only the named reviewed take ships. Duration is the complete trimmed file including decay. Basenames below live inside each manifest row's runtime directory; every master has the same basename with the24-bit source format. These counts deliberately share the action base across five actor accents and reuse cues across services; a later proposed variant needs a manifest/budget revision, not an implied unlimited pack.

| Manifest ID | Runtime basename(s), count | Duration per file | Exact binding / alias status |
| --- | --- | --- | --- |
| `sfx_ui_confirm` | `ui_confirm.wav`,1 | 0.05–0.20s | Proposed UI alias `ui_confirm`: successful selection/open/confirm, not a core event |
| `sfx_ui_back` | `ui_back.wav`,1 | 0.05–0.20s | Proposed UI alias `ui_back`: successful close/cancel/navigation back |
| `sfx_place` | `edit_place.wav`,1 | 0.05–0.25s | Proposed UI alias `edit_place`: accepted `place_wire`/`place_rune` result; edits emit no core events |
| `sfx_rotate` | `edit_orient.wav`,1 | 0.05–0.20s | Proposed UI alias `edit_orient`: accepted `rotate`/`flip` result |
| `sfx_undo` | `edit_restore.wav`,1 | 0.05–0.25s | Proposed UI alias `edit_restore`: accepted `undo` or `place_wire` with `kind=erase` |
| `sfx_invalid` | `action_rejected.wav`,1 | 0.08–0.25s | Proposed feedback alias `action_rejected`; rejected commands have no accepted model event |
| `sfx_technique` | `technique_draw.wav`, `technique_conjure.wav`,2 | 0.15–0.50s | Existing `technique` event plus actual `card_drawn`/`card_created`; these two cue aliases are not event enums; group actual additions once per batch |
| `sfx_cast` | `cast.wav`,1 | 0.25–0.60s | Existing `cast` event, once per accepted action |
| `sfx_impact` | `damage.wav`,1 | 0.10–0.40s | Existing `damage` or `retaliation` with positive actual HP loss; zero uses no impact |
| `sfx_shield` | `shield.wav`,1 | 0.15–0.45s | Existing `shield` / `retaliation` blocked amount; `retaliation_block` is a cue alias, reuse same file and avoid duplicate pulse |
| `sfx_enemy_attack` | `spectral.wav`, `flame.wav`, `stone.wav`, `chain.wav`, `bell.wav`,5 | 0.20–0.60s | Existing `retaliation`; one variant per actor in roster order Shadeling/Wickling/Stone Sentinel/Chain Warden/Bell Keeper; derive from one shared base master with short material accent; choose one file, not five simultaneous layers |
| `sfx_expiry` | `temporary_expired.wav`,1 | 0.10–0.35s | Existing `temporary_expired`; also reuse once for grouped `effect_consumed`/`board_piece_cleared` cleanup if useful |
| `sfx_reward` | `reward.wav`,1 | 0.20–0.65s | Future aliases `reward_committed`, `purchase_committed`, `upgrade_committed`, `heal_committed`; reuse one file with documented gains, not four new core enums |
| `sfx_victory` | `victory.wav`,1 | 0.60–1.80s | Existing `battle_ended` where `state=victory`; future run victory reuses it without double playback |
| `sfx_defeat` | `defeat.wav`,1 | 0.60–1.80s | Existing `battle_ended` where `state=defeat`; abandonment uses subdued UI back, not fabricated combat defeat |
| `sfx_phase` | `guardian_phase_changed.wav`,1 | 0.30–0.80s | Future alias `guardian_phase_changed`, to be reconciled with RC-033/RC-034's committed event; bell-like single transition accent |

Music runtime basenames are `home_exploration.ogg` and `combat.ogg` in the `music` row's directory; ambience is the manifest's `assets/audio/ambience/crypt.ogg`. No extra battle-result music stems are required. The family summary below explains contextual use without adding files beyond this table.

| Cue family | Current/future attachment | Sharing/deduplication |
| --- | --- | --- |
| UI confirm/open/close/select | Successful UI navigation/selection/confirmation | One quiet family; opening inspection is not a technique sound; no repeated hover chatter |
| Place/edit/undo/remove | Accepted `place_wire`, `place_rune`, `rotate`, `flip`, `undo`, `erase` UI result | Edits currently return no presentation events; RC-020 binds accepted command feedback, never attempted-input alone |
| Invalid/unavailable | Rejected action or explicit unavailability feedback | Throttle rapid repeats; no cast/placement cue and no model event fabricated |
| Technique/draw/create | Accepted `technique`, actual `card_drawn` / `card_created` | Generic technique start plus small grouped draw/create accent; Focus and Conjure share components; absent cards make no sound |
| Cast/traversal | Accepted `cast` | One cast cue per action; traversal can share a short texture, never create multi-hit semantics |
| Impact/shield/player hurt | `damage.applied`, `shield`, `retaliation` | Quiet zero-outcome treatment if useful; no impact implying HP loss when applied0; shield reflects actual blocked amount |
| Enemy action | `retaliation` actor presentation | Five bounded spectral/flame/stone/chain/bell variations of one shared action base, one per actor; the separate guardian phase cue is one transition accent, not a new track |
| Cleanup/expiry | `temporary_expired`, `effect_consumed`, `board_piece_cleared`, `turn_cleanup` | One grouped cleanup accent; no16-cell burst of identical sounds |
| Battle victory/defeat | `battle_ended` | One outcome cue; future guardian/run results reuse or layer this cue without double triggering |
| Reward/acquire/purchase | Future accepted reward/shop/relic transaction | One gain cue shared; do not play on inspection/offer display or rejected purchase |
| Heal/upgrade/remove | Future accepted recovery/service/event transaction | Reuse matching UI/reward accent; no sound for cancelled picker |
| Guardian phase | Future committed phase change from RC-033/RC-034 | Bell accent on the single transition; must not trigger from predicted/lethal threshold crossing |

Concrete event payloads presently exist only where named in [combat presentation](combat-presentation.md); progression/phase notifications are future contracts. RC-020/RC-042 reconcile exact event names and update the mapping when those systems arrive, without asking audio production to invent gameplay events.

### Music, ambience and interruption

Home, Map, shop/recovery/event/reward/collection navigation reuse the **Home/exploration** loop; combat, elite and guardian reuse the **combat** loop. Crypt ambience is shared at low level where appropriate. A Menu overlay does not restart/stack the current music. Proposed transition is0.4–0.8s crossfade between at most two music players; ambience fades independently. Never keep a hidden old scene's loop alive. Save/load and back navigation must not create additional players; suspense/defeat can fade or duck existing tracks rather than add a third track.

Music and SFX have independent volume/mute persistence; ambience routes with music unless RC-020 documents a separate user-facing need. Sound on/off navigation reflects actual settings. Backgrounding, focus/audio interruption and resume are verified by RC-047; do not assert mobile playback policy from the Windows tone. Source notes must trace every sample/library/generation source, exact prompt/model if available, transformations and actual licence/attribution. Unknown or restricted sources remain unapproved and cannot be shipped merely because they play.

<a id="release-assets"></a>
## Release assets

`app_icon` retains its existing identity and current prototype path until RC-051 deliberately replaces it. Proposed art master: editable vector plus **2048 × 2048 layered/raster master**, with a **1024 × 1024 clean square export** for derivation and silhouette tests at64/48/32 pixels. Keep important symbol mass in the central70% and preview candidate masks; this is a working art-safe area, **not** an assertion of an Android/iOS store requirement. RC-051 must check then-current platform requirements and produce required icon layers/sizes/opacity/masks/launch-title variants. Do not reuse the in-game logo unreadably as a tiny launcher icon.

RC-051 owns distribution identity refinements and corresponding runtime updates; RC-052 owns final identifiers/publisher/signing decisions; RC-053/RC-054 own release exports and actual package checks. Current `com.example.runecast`, empty iOS team ID and development presets are not release readiness. Keep platform-specific dimension/format compliance with those later tasks, not an invented permanent checklist here.

RC-056 owns honest release-build screenshots, platform promotional graphics, listings and support/privacy/credits links, using then-current official requirements and owner business details. Working masters may be layered at capture/native aspect plus text-safe overlays, but screenshots must show actual shipped gameplay. Do not present approved flattened concepts or RC-011 composites as release screenshots. Trailer, extra characters/biomes and a third track remain outside scope. RC-050 audits final distribution assets, fonts/audio and any other shipped dependency for provenance/credits after RC-051; this audit is not a prerequisite for producing the pilot.

<a id="performance-budgets"></a>
## Performance budgets

All budgets below are **provisional planning limits**, not measured memory, engine guarantees or established minimum-device support. RC-011/RC-016 check usefulness; RC-021/RC-022 select practical device baselines; RC-023 observes the first encounter; **RC-048 measures and adjusts** actual texture/audio memory, frame pacing/load/startup/effect cost/package contents on selected devices; RC-049 records acceptance. Record deviations and evidence instead of silently lowering art quality.

Decoded RGBA8 estimate is **width × height × 4 bytes / 1,048,576 = MiB**. Transparent pixels cost as much as opaque ones in this conservative estimate. A complete mip chain adds approximately **one third** (multiply by4/3); use actual imported format/allocation during profiling. PNG compression/disk bytes do not predict texture memory. Engine staging copies, mip alignment, render targets, font glyph atlases and driver overhead are additional.

| Asset/allocation | No-mipmap RGBA8 estimate | With full mip chain | Provisional resident policy |
| --- | --- | --- | --- |
| Character512² pose | 1MiB | 1.33MiB | Three pose exports ≈3MiB/actor; allow≤4MiB for active actor including small pieces; guardian≤5MiB with phase overlay; only one combat actor loaded |
| All five three-pose packs plus one phase overlay | 16MiB | 21.33MiB | Disk/import planning total, **not** required simultaneous residency; parts replace/reuse budget rather than unbounded duplication |
| Crypt1440 × 720 layer | 3.96MiB | 5.27MiB | Two required layers≈7.91MiB; optional third raises to11.87MiB; lighting presets add negligible texture storage unless documented mask needed |
| Home720 × 1600 | 4.39MiB | 5.86MiB | Load for Home; release/invalidate after leaving when lifecycle permits |
| Parchment720 × 1440 | 3.96MiB | 5.27MiB | Load for Map; menu dimming is a colour layer, not another screenshot texture |
| Wordmark768 × 384 | 1.13MiB | 1.50MiB | One shared import; header simplification need not retain a second large raster |
| Glyph128² | 0.0625MiB | 0.0833MiB | 64 such rasterized SVGs≈4MiB; inventory larger than64 requires recalculation, not arbitrary trimming |
| Button512 × 128 or socket256² | 0.25MiB each | 0.33MiB | Derive states through resources/tints/overlays; do not multiply all seven states blindly |
| One1024² atlas if later justified | 4MiB | 5.33MiB | Optional UI/icon family only; independent imports first |
| One full720 × 1600 RGBA render target | 4.39MiB | N/A | Budget separately if a future blur/capture effect introduces one; do not confuse it with the texture subtotal |

Initial **active Combat art texture target≤32MiB** (actor≤4–5, crypt≤11.9, UI/glyph/theme≤10, VFX≤2, headroom for small extras); **all concurrently retained imported art≤48MiB** during transitions including Home/Map/wordmark. These exclude engine/render buffers and font atlas memory; reserve **up to8MiB provisional font glyph-atlas allowance** and report actual allocation. Full application resident memory working ceiling **256MiB** is a profiling starting point only, including audio, game/engine and GPU-associated costs where measurable; it is not a promised Android/iOS minimum. Report CPU/GPU/dedicated/shared categories clearly rather than adding incompatible tool counters.

Maximum routine runtime raster dimension is **2048 per axis**; the proposed delivered runtime textures fit below it. Do not split a 720 × 1600 painting into tiles simply to impose powers of two. Separate source masters may exceed2048. Start with individual assets; atlas only a measured group that shares material/filter/lifetime after RC-048 demonstrates value. If an atlas is adopted, use≤1024² initially,2–4px extruded gutters, stable region metadata and no mixing world layers with UI. Atlas generation must remain reproducible without requiring a heavyweight asset-management application.

PCM decoded size is **sample_rate × channels × bytes_per_sample × seconds**. A48kHz16-bit mono SFX uses96,000B/s≈0.0916MiB/s; **40 one-second mono cues≈3.66MiB**. A48kHz stereo float playback representation uses≈0.366MiB/s, so decoder/mixer storage can exceed the original16-bit files. Start with **resident short-SFX allowance≤8MiB**, keep total short-cue duration roughly≤60 mono-equivalent seconds, and profile actual imports. Shared variants count toward that allowance.

A120s48kHz16-bit stereo music WAV would decode to≈21.97MiB;24-bit master≈32.96MiB. A192kb/s encoded120s loop is≈2.75MiB on disk before overhead, while decoded audio remains much larger. Keep music/ambience compressed and use a bounded playback path; **do not predecode all loops into full PCM buffers**. RC-020/RC-048 must verify the chosen Godot Ogg playback/import behavior and actual compressed residency/decoder buffers. Proposed long-audio compressed total≤8MiB (two≤120s music loops plus≤60s ambience), combined audio residency target≤16MiB including SFX and playback buffers; two music streams maximum during crossfade plus one ambience stream.

Effect limits: one ordered combat action presentation, one actor, at most **two simultaneous transient VFX emitters**, **32 particles/emitter**, and **64 active particles total**; traversal uses one shared overlay visiting cells, not16 independent persistent emitters. At most **eight SFX voices** concurrently, with gain/priority limiting; replacing/dropping decorative duplicate cues cannot suppress the one important action/outcome cue. Result/phase/cleanup tails must respect the same budget. These are default implementation caps for RC-017/RC-020 to validate, not an instruction to introduce particles everywhere.

Runtime content/package working target: **≤64MiB compressed art/audio/fonts payload**, **≤100MiB installed exported game payload excluding platform-dependent engine/signing overhead**. RC-048 records actual imported/package sizes and revises against devices; RC-053/RC-054 report actual distributed and installed totals. Source masters/raw revisions are outside builds: suggested **≤2GiB working delivery footprint** for this bounded art/audio set, with large DAW/generation originals archived separately and still traceable. Storage estimates are planning allowances, not evidence of current files or licences.

<a id="delivery-acceptance"></a>
## Delivery and acceptance

### Ownership and promotion

| Owner | Concrete boundary |
| --- | --- |
| RC-011 | Isolated matching style pilot; validates this document's provisional values and records chosen direction; no final integration |
| RC-012 | Font/core SVG library and actual import/rights records |
| RC-013 | Shared theme, frames/state resources and in-game logo; does not author live screen behavior |
| RC-014 / RC-015 | Shadeling production pack / aligned crypt and separate Home illustration |
| RC-016 | First encounter imagery/theme integration, live values and correct source/build exclusions |
| RC-017 | Shared presentation adapter/animation/VFX; no gameplay consequences |
| RC-018 / RC-019 | SFX / two music loops and ambience with sources/rights/loop/level evidence |
| RC-020 | Audio playback, settings, event mapping, cancellation/lifecycle and removal of temporary tone |
| RC-037–RC-040 | Wickling, Stone Sentinel, Chain Warden, Bell Keeper packs in order; same anchor/motion contract |
| RC-041 | Remaining rune/relic/intent/progression art and parchment Map, reusing theme |
| RC-042 | Full roster/Home/Map/Menu/options/result art/audio integration and manifest reconciliation |
| RC-050 / RC-051 / RC-056 | Shipped provenance/credits audit / final distribution identity / release store materials |

Implementation of Home/save/navigation/Map/services remains with RC-025/RC-028/RC-029/RC-030/RC-031/RC-032 as specified in the project plan. Production acceptance does not claim those behaviors exist. Art production supplies reusable states and review assets; integration owner modifies shared code/resources and captures the working result. Independent producers may edit their isolated asset directory and delivery note; the integrator reconciles a proposed manifest change when several deliveries arrive at once. No task should acquire a circular dependency on a later integration/audit task merely to produce a source file.

### Required delivery package

Every later production task supplies:

1. Source master and runtime-format exports, stable manifest ID(s), exact filenames/revision and manifest update. Clearly mark candidates vs accepted/delivered files and optional omissions.
2. Creator/source provenance, source URLs or original generation file links, exact prompt/model/version when recorded, raw references, refinement steps and actual licence/attribution evidence. Say `unknown` when unknown; do not invent a model or rights from a filename. Approved source direction is not a redistribution licence.
3. Geometry metadata: canvas/export size, colour/alpha/import settings, anchors, crop origins/overlap, part pivots, ports, frame slices and content padding as applicable. Audio adds sample/channel/loop/level data and event/bus mapping.
4. Isolated preview/contact sheet or listening sample; alpha/monochrome/state sheet where relevant. Include an actual gameplay-scale composition in720 × 1600 and450 × 1000 and a360 × 640 small portrait check; assets must not merely look good as enlarged thumbnails.
5. Known limits, unfinished states, integration instructions, task-specific acceptance evidence and unresolved device questions. Name which assets are reused and why no duplicate production file is needed.

An editable standalone preview is permitted; label it as an art review composition. It is not an integrated runtime capture. New files become runtime-ready only after real import/format/geometry/state checks; integrated only after actual scene binding/capture; device-verified only with named hardware/OS/build and observed result. Use the manifest's status vocabulary without collapsing these stages. Licence status is independent of visual readiness: a technically usable asset with unresolved rights cannot be marked shipping-ready.

### Acceptance checks by family

| Family | Required evidence before production acceptance |
| --- | --- |
| All art | Matches approved direction; original/reference untouched; filenames/manifest/source paths correct; no baked live labels/values; no unplanned character/biome/room family |
| Character | Full body and extremities visible; clean alpha on four backgrounds; same anchor across all states; grounded scale sheet; no pose jitter/cropping; separate shadow; state coverage and envelope preview |
| Environment/Home | Aligned origins/layer seams; overlap hidden at all accepted crops; actor/intent/name/health remain readable; Home logo/controls separate; no screenshot crop masquerading as a new layer |
| Geometry/icons | Correct exact ports under four rotations and legal flips; Begin/End distinguishable; output arrows clear;24/32px/monochrome and137/72px-cell checks; badges/counts do not hide ports or values |
| Theme/text | Seven shared states plus required overlays; scalable borders unbroken at minimum/wide sizes; live text/fallbacks intact; disabled vs inspectable distinction; inspector body scroll and fixed actions preserved |
| Navigation/progression | Home no/valid/invalid save and replace; Menu turquoise Resume/navy Options/Shop/Quit and disabled Shop; Sound on/off; four node states; sold/unaffordable/used/empty/upgrade/confirmation/result variants through shared components |
| Animation/VFX | Editable resources; event order/deduplication; no gameplay writes; no post-cancel visuals; one completion; zero/lethal/Pass/expiry cases; reduced motion; caps and observed timing recorded |
| Audio | Source/rights file; no clipping/clicks/trim errors; loop points and five-repeat seam audition; actual codec/runtime listening; consistent relative mix; no stacking/duplicate action cue; mute/interruption handled by integration |
| Release | Current platform requirements verified by later owner; real release-build captures; distribution identity and credits reconciled; source-only files excluded |

### Validation and acceptance levels

Planning validation checks CSV parse/unique IDs, preservation of existing IDs, complete roster/screen/state mapping, owners against actual task descriptions, acyclic asset dependencies, shared reuse, consistent contract links/dimensions, and existence of paths claimed as delivered evidence. Planned paths are checked for clear planned status, not required to exist prematurely. Readiness/provenance/licence claims must each have their own evidence. The [verification record](verification.md) records the actual RC-010 checks; this spec does not claim to have run a gameplay suite.

Desktop acceptance records the preview/capture dimensions, source or build revision, states exercised and reviewer findings. It can prove clean exports, import rendering, composition and synthetic state handling. **Physical-device acceptance is separate:** record real Android/iOS model, OS/build, safe areas, density/readability, actual touch, frame/memory measurements and audio/lifecycle observations under RC-021/RC-022/RC-023 and RC-044/RC-047–RC-049. Missing device access remains unverified; a desktop screenshot or approved concept cannot satisfy it.
