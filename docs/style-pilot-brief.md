# RC-011 matching style pilot

Prepared by RC-010 on October 9, 2026. **This is a production brief; none of its planned deliverables has been produced, approved or integrated by RC-010.** RC-011 produces one matching set: Shadeling, a Spark tile treatment and a reusable button. Its review chooses the practical font direction and animation approach before mass production. It does not reopen the four approved screen compositions or complete RC-012–RC-020.

Use the authoritative [asset manifest](asset-inventory.csv) and [production specification](asset-production-spec.md). The [character contract](asset-production-spec.md#characters), [circuit and icon contract](asset-production-spec.md#circuit-icons), [UI and typography contract](asset-production-spec.md#ui-typography), [animation contract](asset-production-spec.md#animation-vfx) and [delivery checklist](asset-production-spec.md#delivery-acceptance) govern the deliverables below. Dimensions are concrete **proposed production defaults**, to be checked by this pilot; they are not claims about delivered assets or device acceptance.

## Inputs and authority

Inspect all four exact approved references, including at phone scale. They are flattened visual targets, never source layers to crop into the game.

| Approved input | Use in this pilot |
| --- | --- |
| [Combat](../output/imagegen/approved/combat.png) | Primary matching reference: centered full-body lantern-bearing Shadeling, substantial arena, strong dark outlines, angular silhouettes, matte painted shading, amber Spark, compact rune choices and turquoise Cast. |
| [Home](../output/imagegen/approved/home.png) | Moonlit indigo/blue stone, warm candlelight, restrained gold and turquoise primary actions. The tower, logo and buttons remain separate future assets. |
| [Map](../output/imagegen/approved/map.png) | Check that navy/cream/gold symbols remain readable on parchment, with turquoise current and gold available states. Preserve the absence of an encounter legend strip. This pilot does not produce Map art. |
| [Menu](../output/imagegen/approved/menu.png) | Match turquoise Resume and the same navy treatment for Options, Shop and Quit; centered overlay over dimmed gameplay. |

The [visual-reference history](visual-reference.md#history) and original `output/imagegen/*.prompt.txt` preserve earlier generation intent. Older fixed circuits, infinity stock and the reference's BOSS label are historical artwork details, not current production rules. Do not edit those images or prompts.

Also inspect these actual desktop captures and their source controls before making the pilot:

| Runtime evidence inspected for RC-010 | What it establishes |
| --- | --- |
| [RC-009 normal production](../output/qa/rc-009/final-production.png) | The current 450×1000 desktop preview, compact hand, finite stock, editing/inspection rows, Cast and navigation. It uses placeholders. |
| [RC-009 exhausted stock](../output/qa/rc-009/board-capture-1791523199-18876/belfry-touch/unavailable-stock.png) | 720×1600 scene with `0 / 6` stock, inspectable unavailable tool, eligible `+` and protected/unavailable `x` borders, live explanations and disabled Cast. |
| [RC-008 selected rotated endpoint](../output/qa/rc-008/touch-capture-1791519954-3060/selected-rotated-endpoint.png) | A player-rotated Begin, selected-cell outline, enabled Rotate and unavailable Flip, and a finite Join count. |
| [RC-009 small inspector](../output/qa/rc-009/board-capture-1791523199-18876/belfry-touch/small-portrait-inspector.png) | 360×640 viewport with readable scrolling details and a separate Close control. It is desktop evidence, not a physical phone. |

Read [touch interactions](touch-interactions.md), [board catalog](board-catalog.md), [gameplay rules](gameplay-rules.md), [content definitions](content-definitions.md) and [combat presentation](combat-presentation.md). The current UI is in [`main.gd`](../scripts/ui/main.gd), [`arena.gd`](../scripts/ui/arena.gd) and [`board_cell.gd`](../scripts/ui/board_cell.gd). These determine current scale and behavior; the accepted references determine visual direction.

## Scope and files

The manifest IDs below identify the pilot; final assets keep their separate stable IDs. All paths in this section are **planned destinations**. Keep raw generated outputs, prompts and refinement history in each pilot source folder. A layered `.ora` is the exchange master; retain any application-native original as well. Raster exports are straight-alpha, sRGB PNGs, following the [general contract](asset-production-spec.md#general).

| Pilot ID | Required source | Runtime-format exports for review only | Later adoption |
| --- | --- | --- | --- |
| `pilot_shadeling` | `source-assets/pilot/shadeling/shadeling.ora`, 1024×1024, with separate body/cloak, lantern arm, lantern and flame layers | `source-assets/pilot/exports/shadeling.png`, 512×512 transparent neutral pose; same-canvas transparent part exports under `source-assets/pilot/exports/shadeling_parts/` for the feasibility preview | RC-014 refines the production `shadeling` pack in `assets/enemies/shadeling/`; RC-016 integrates its neutral presentation; RC-017 adds event-driven motion. |
| `pilot_spark_tile` | `source-assets/pilot/spark_tile/spark_tile.ora`, 512×512 layered frame/material; `source-assets/pilot/spark_tile/spark.svg`, editable 128×128 viewBox | `source-assets/pilot/exports/spark_tile.png`, 256×256; `source-assets/pilot/exports/spark.svg`; temporary-marker candidate separate from glyph/frame | RC-012 adopts the precise glyph/marker; RC-013 adopts the shared frame. RC-016 integrates. `spark` and `free_spark` remain separate content IDs using shared art. |
| `pilot_button` | `source-assets/pilot/button/button.ora`, 1024×256; separate material, trim and state layers | `source-assets/pilot/exports/button_primary_<state>.png` and `button_secondary_<state>.png`, 512×128; state names below | RC-013 produces the shared theme; RC-016 integrates Combat controls, RC-042 completes all screen consumers. |
| `pilot_review` | `source-assets/pilot/pilot_review.svg`, editable comparison/composition with linked art and separate text/geometry; accompanying delivery notes | PNG previews under `output/art/rc-011/`, plus a short motion study and state/alpha sheets | RC-011 records review outcome and handoff. These previews never become runtime background textures. |

These are runtime-**format** candidates, not runtime-ready, shipped or integrated assets. Keep them under `source-assets/pilot/exports/` until the owning production task accepts/refines them and records the actual final runtime path. RC-011 may build a small standalone preview scene if useful, but must not change the main scene, rules, content data, export presets or current runtime assets. Use the [source exclusion contract](asset-production-spec.md#general) for any preview project; later integration tasks own build exclusions and imports.

RC-011 owns only its pilot sources/previews/delivery notes and the coordinated manifest/review update. It does not author five character packs, a crypt, a new screen, a logo, a full font library, final animations or audio. Keep the existing `shadeling`, `spark`, `free_spark`, `training_shadeling` and all four board IDs intact.

## Shadeling illustration and motion feasibility

Produce one polished neutral full-body Shadeling. Preserve the reference's crooked hood, ragged angular cloak, skeletal/masked face, lantern and warm flame against muted indigo/purple forms. The eyes and lantern can be bright; avoid glossy rendering, dense tiny texture and bloom that dissolves the outline. Shadeling remains the introductory normal enemy, with no baked BOSS label, intent, health, name, stage or visible player.

- Source canvas: **1024×1024**. Review export: **512×512**. Foot anchor: **(512,896)** source, **(256,448)** export. Do not tight-crop exports or change origin between parts/poses.
- Neutral opaque bounds: approximately **x80–432, y88–448** in the 512 canvas. All preview motion stays within **x32–480, y32–480**; the lantern, cloak tips and feet stay fully visible. The ground contact is y448. A floating pose still uses that common ground datum.
- Preview at **0.46 runtime pixels per export pixel**, comparing **0.42–0.48**, with the foot placed at **(340,233)** in the current arena's **680×300 reference coordinates**. The neutral art is about **166 logical pixels tall** at 0.46 before the arena's own layout transform. State the applied transforms in the delivery note rather than judging scale from source canvas size.
- Keep contact shadow, lantern light and any glow on separate layers. No opaque or semiopaque background rectangle, baked environment or inseparable ground shadow. Check alpha on light gray, dark navy and checkerboard.
- Separate body/cloak, arm, lantern and flame sufficiently for a small transform study. Supply metadata for their shared origin, pivots, draw order and anchor. Rough alternate attack/hit sketches are permitted only if the neutral parts cannot demonstrate the intended movement; three polished pilot poses are not required.
- Show a short **idle → attack → hit → defeat** feasibility sequence. Idle can use restrained cloak/lantern movement; attack uses a clear anticipation/action; hit gives one readable recoil; defeat settles or fades without clipping. Show a reduced-motion counterpart using static poses/brief opacity changes. This is an unintegrated visual study, not gameplay logic or RC-017 completion.

The pilot must record whether the proposed lean pose-plus-transform approach is sufficient. RC-014 later supplies final neutral/attack/hit poses and the parts needed for the production four-state pack. RC-017 owns timing, cancellation, reduced-motion behavior and action-completion callbacks. No animation applies damage, spends energy, rerolls endpoints or performs cleanup.

## Spark tile and exact circuit boundary

Use the approved amber sun/spark motif with strong simple rays, dark outline and a bright center. Separate three things: painted socket/frame material, editable symbol geometry and live labels/values/ports. The tile must share the button's material and Shadeling's outline/shading language without making the circuit less exact.

- Glyph: editable SVG `viewBox="0 0 128 128"`, centered at **(64,64)**, essential art within **16–112**, provisional dark outline **8 units** and internal stroke **6 units**. Show it at **24, 32 and 48 logical pixels**, in color and monochrome. Avoid externally linked images, fonts, filters or text inside the glyph SVG.
- Tile frame: **512×512 source → 256×256 PNG**. Use **16 export-pixel nine-slice margins on every side**, equivalent to **8 logical pixels at nominal 128 size**. Keep decoration away from ports, cost/value zones and placement feedback. The glyph remains a separate overlay.
- Use cell-edge ports **N(64,0), E(128,64), S(64,128), W(0,64)**. Spark is **W input → E output** at rotation0. Preview all four clockwise quarter-turns. Rotate the geometry; keep name/value/cost text upright. Live paths continue to the edge-port centers, with no painted fake branch or socket that implies a second connection.
- Preview the same glyph/frame as permanent `spark` and generated `free_spark`, using a separate temporary shape/marker and live temporary wording. The generated rune is not a second painted glyph or a new permanent card. Current sample values are **Spark 6 damage / cost2** and **Free Spark 6 damage / cost0**; retain them as editable preview text only.
- Include unpowered, powered, selected, focused, invalid and unavailable examples, plus eligible `+` and protected/unavailable `x` overlays. Keep those overlays reusable and independent of the base tile. TEMP, cost and value must not disappear under a selection border.

The [circuit contract](asset-production-spec.md#circuit-icons) owns all Straight/Corner/Split/Join connections and reversal. Pilot context can use existing code/vector geometry; RC-011 does not redraw that geometry as painterly linework. Cell samples must be legible at the current **137×137** logical size and at **72×72** in a native 360-wide viewport. Keep hand choices compact at the current **142×92 minimum**, showing name, glyph and value; longer explanation stays in the inspector.

## Shared button and typography study

Produce **one reusable button construction** with turquoise primary and navy secondary material variants. Gold is a border/accent, not a bright fill over the entire UI. Resume/Continue/Cast use the primary direction; Menu Options/Shop/Quit share the same navy direction, including Quit.

Source size is **1024×256**; export each state at **512×128**. Nine-slice borders are **24 export pixels left/right and 20 top/bottom**. Keep live content padding at least **16 logical pixels horizontally and 10 vertically** wherever the control size permits; use a compact inset variant per the UI contract for the smallest current controls. Corners must not stretch, and border tips must not intrude into labels or adjacent targets.

| State token | Required visual distinction |
| --- | --- |
| `normal` | Stable readable fill, trim and live label. |
| `pressed` | Inset/darker material and a small internal shift; control bounds do not move. |
| `focused` | A clear additional outline/shape cue that can coexist with another state. |
| `selected` | Persistent inset/highlight or marker, visibly different from a momentary press. |
| `disabled` | Muted fill/trim and readable label; no implied available action. |
| `invalid` | Warning outline/shape treatment plus live explanation; do not rely on red alone. |
| `unavailable` | Distinct inspectable condition such as exhausted stock; retain name/count and an explanation affordance. It must not look like a permanently dead control. |

State exports may share the same base texture plus separate overlay assets; record reuse instead of duplicating visually identical files. Demonstrate focused+selected and focused+unavailable combinations. Hover may reuse focus/normal on desktop; a hover-only cue cannot be essential on touch.

Test the scalable frame at the current **66×50 minimum button**, **58-high editing control**, **64-high Cast/inspector action**, and wider Home/Menu proportions. Never reduce hit areas to the ornament silhouette. Inspect, Cancel selection/Cancel and Details / Pass remain visible live controls. A stock button with `0 / 6` remains inspectable while placement is unavailable.

Use the proposed font direction and candidates in the [UI/typography contract](asset-production-spec.md#ui-typography). Compare title/large action lettering with body/numeral text and record one chosen family/weight per role, source, licence evidence and fallback behavior. If a candidate has not been obtained/licence-checked, label its specimen provisional and use the current engine fallback for scale comparisons. RC-012 owns production font files and licensing records. Include `Spark`, `Free Spark`, `Conjure Spark`, `Cancel selection`, `Details / Pass`, `Confirm Pass / enemy acts`, `0 / 6`, `32 / 32` and `6`/`0`/`8`/`1` in the typography sheet. Do not turn labels into permanent graphics; the in-game logo remains RC-013.

## Required previews and review record

Supply a **single matching composition** placing all three candidates together in the current Combat hierarchy. Reconstruct the control layout using separate art, vector geometry and text layers; an unmodified runtime capture may sit beside it as evidence. A reference screenshot may be a clearly labeled comparison underlay, but must never be exported as a game background or treated as integrated art.

| Planned preview | Required content |
| --- | --- |
| `output/art/rc-011/pilot-720x1600.png` | Main composition at design scale. Centered full-body Shadeling, live-style intent/name/health, a 4×4 board with exact ports, finite stock, required editing/inspection controls, compact hand, Cast and navigation. |
| `output/art/rc-011/pilot-450x1000.png` | The same design-scale composition reduced to the current desktop window scale; no zoomed readability claim. |
| `output/art/rc-011/pilot-360x640.png` | A native narrow/short viewport layout study using 72-pixel cells and scrolling/cropping boundaries; show essential controls and an inspector view as companion panels, rather than shrinking a whole tall screen to fit. |
| `output/art/rc-011/pilot-states.png` | Tile/button variants, all required states and combinations, four Spark port rotations, finite-stock unavailable example, alpha and grayscale/monochrome samples. |
| `output/art/rc-011/pilot-type.png` | Actual-size text roles, values and longest labels with font source/licence status. |
| `output/art/rc-011/pilot-motion.mp4` | Short four-state Shadeling feasibility preview and reduced-motion comparison; state labels/timecodes plus anchor/envelope overlay. An image sequence is acceptable if the available tools cannot export video; record that substitution. |
| `source-assets/pilot/delivery.md` | Source/export mapping, creator/provenance, prompt/model records where available, refinement notes, dimensions, alpha/import assumptions, scale/pivots/slices, tested preview sizes, known limits and review outcome. |

Use **`board_training`, seed294, built witness** from the [board catalog](board-catalog.md#first-circuit--introductory-rune) for the main composition if a concrete circuit is needed. It has Begin0 rotation0 → Spark1 rotation0 → End2 rotation3, cost2 and damage6, with remaining kit4/2/2/2. It is a reproducible built example, never a production prefill. Supply a separate endpoints-only/rotated-endpoint view and an unavailable-stock inset; do not imply every random hand has that Spark or route. The generated Free Spark variant can be shown isolated or via the documented Belfry witness, not silently substituted into Training.

Keep underlying mechanics unchanged: unrestricted distinct random endpoints including adjacency, player Rotate/Undo, straight effect ports, all four finite counts, no banking, one aggregate hit, permanent discard and complete temporary/connector cleanup after Cast/Pass. No decorative asset may imply fixed endpoint cells, permanent routes, unlimited connectors, a temporary replacement wire or guaranteed first-hand cards.

## Review criteria and handoff

Record **pass / revise / not tested** with a linked artifact for each criterion; a filename alone is not acceptance evidence.

1. **Matching visual language:** all three assets share outline strength, broad matte shadows and restrained detail. Combat, Home, Map and Menu remain visually compatible; no player, new character, biome, currency, legend strip or screen redesign is introduced.
2. **Actual-scale readability:** the enemy silhouette/lantern/feet remain clear, the Spark glyph is recognizable at 24/32/48 pixels, 137/72-pixel board cells preserve exact ports and feedback, compact hand values remain distinct, and narrow inspector/button text fits or scrolls as designed.
3. **Technical integrity:** clean alpha on multiple backdrops, consistent foot/pivots and complete animation envelope, correct nine-slice corners, aligned layers/ports at all rotations, no label/value baked into artwork, and no unintended glowing fringe/black matte.
4. **State coverage:** normal/pressed/focused/selected/disabled/invalid/unavailable samples and temporary/powered/placement overlays are distinguishable without color alone. Focus can coexist with selection; unavailable stock remains visibly inspectable. Home no-save/invalid-save Continue and Menu room-gated Shop can reuse these same components later.
5. **Production feasibility:** record chosen font direction and animation method, refinement steps needed for clean source masters, decoded texture estimates against the [provisional budgets](asset-production-spec.md#performance-budgets), and any dimension/anchor changes required before RC-012–RC-015. Do not claim a source PNG's compressed byte count is decoded memory.
6. **Truthful acceptance:** source and licence fields contain evidence or explicit unresolved status; no model version is guessed. Desktop visual review is separate from Godot import acceptance, gameplay integration and physical-device acceptance.

RC-011 finishes when one coherent style set has a recorded review result, usable editable sources, review exports and a clear handoff. Any accepted dimension/anchor/font/method adjustment must be reconciled once into the production specification and manifest before mass production; preserve superseded previews and notes. The chosen set is not blanket approval of future assets. Unresolved style defects keep RC-011 open; unresolved device measurements belong to RC-021/RC-022, RC-023 and RC-044/RC-048/RC-049 and stay explicitly unverified.

Next owners: **RC-012** font/core-symbol production; **RC-013** shared UI/logo production; **RC-014** Shadeling pack; **RC-015** crypt and separate Home art; **RC-016** first-encounter integration; **RC-017** event-driven animation. RC-018/RC-019 may use the selected mood for sound/music under their own contracts. RC-010 itself generates none of these assets.
