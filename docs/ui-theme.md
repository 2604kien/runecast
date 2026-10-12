# Reusable UI theme and wordmark — RC-013

**October 13 cleanup:** current Menu images are retained in [menu-button-revert](../output/art/rc-013/menu-button-revert/). Superseded review images, the outdated combined contact sheet, generated staging projects and raster intermediates were retired in the [project-wide cleanup](asset-cleanup.md#october-13-2026--project-wide-follow-up-cleanup). Historical counts/reports below retain their original dates; unchanged captures remain available. Recreate staging before executing the focused validator.

October 12, 2026; production began October 11. This delivery adopts the retained r006/r004 painted gold bevels, indigo recesses and stone/navy surfaces into a separate reusable Godot library. The [clean-board Combat contract](gameplay-visual-contract.md) is the current authority; Home, Map and Menu retain their [approved references](visual-reference.md). RC-012 supplies the [existing symbols and serif roles](core-symbols-and-typography.md). Reconstructed production assets are `reference_guided`; approval of the supplied references does not approve this reconstruction or identify its typeface.

**RC-013 is complete for production and isolated desktop verification.** [Focused delivery checks](../output/qa/rc-013/validation-report.json) pass 1,795 checks and [source integrity](../output/qa/rc-013/source-validation.json) passes 253. All26 texture exports and the shared font roles imported successfully;34 actual Godot sheets cover the required component/screen states. The five inherited painted packs remain `source_ready` because their recorded distribution rights are unresolved; independently authored overlays, wordmark, scrim and Theme are `runtime_ready`. All runtime paths exist and technical import verification is recorded separately from rights. The normal game remains on its earlier theme and controls. RC-016 and RC-042 own integration; [RC-016A](project-plan.md#rc-016a--undirected-evaluator-and-control-migration-gate) must settle and implement undirected evaluation and control migration before full gameplay acceptance.

## Ownership and component boundaries

| Manifest ID | Editable source contract | Runtime destination |
| --- | --- | --- |
| `board_cells` | `source-assets/ui/board_cells.ora` | `assets/ui/board/` |
| `ui_frames` | `source-assets/ui/ui_frames.ora` | `assets/ui/frames/` |
| `button_frames` | `source-assets/ui/button_frames.ora` | `assets/ui/buttons/` |
| `rune_frames` | `source-assets/ui/rune_frames.ora` | `assets/ui/runes/` |
| `ui_bars` | `source-assets/ui/ui_bars.ora` | `assets/ui/bars/` |
| `ui_state_overlays` | `source-assets/ui/ui_state_overlays.ora` and editable vector overlays | `assets/ui/states/` |
| `ui_dialog_scrim` | `source-assets/ui/ui_dialog_scrim.json` | `assets/ui/scrim.tres` |
| `ui_theme` | `source-assets/ui/theme-notes.json` | `assets/ui/rune_cast_theme.tres` |
| `wordmark` | `source-assets/ui/wordmark.ora` and editable lettering source | `assets/ui/wordmark.png` |

These are shared materials and controls. They do not supply a new content icon library, final Home/crypt paintings, a production map, saving, shops, a game evaluator, or distribution identity. Later rune/relic/room and parchment production remains RC-041; the launcher/store identity remains RC-051. Draw/Discard, top Pause, Remove/Rotate, navigation, Sound on/off and temporary markers reuse RC-012 imports.

The [source delivery](../source-assets/ui/delivery.md) links every editable master, semantic layer and mask. [source-export-map.json](../source-assets/ui/source-export-map.json) records the26 exact runtime members and retained inputs; [Theme notes](../source-assets/ui/theme-notes.json) and [scrim source](../source-assets/ui/ui_dialog_scrim.json) cover the resource/code mappings.

## Separate wordmark

The [transparent runtime wordmark](../assets/ui/wordmark.png) is1024×384, from a1280×480 [editable SVG](../source-assets/ui/wordmark.svg) and [six-layer ORA](../source-assets/ui/wordmark.ora). Its independent stone backing, trim/crest, letter extrusion, custom serif lettering, facets and three diamonds are also supplied as [editable vector layers](../source-assets/ui/wordmark-layers/). Exported transparent padding is at least32px on every side. Preserve its aspect ratio; do not nine-slice or stretch lettering.

The lettering consists of original custom serif paths, with no font outlines, font dependency, sampled reference pixels or new generation. It follows the approved gold-serif/indigo-crest direction without identifying the reference's unknown typeface. The [size preview](../source-assets/ui/wordmark-preview.png) shows Home and compact-header treatments. At very small widths, use live `RCTitle` text instead of forcing the ornamental logo to function as a tiny label. The wordmark remains separate from Home tower art and buttons; distribution icon/store variants stay RC-051.

## Resources and consumer API

The [Theme](../assets/ui/rune_cast_theme.tres) can be assigned to a screen's root Control. The [component factory](../scenes/ui/theme/components.gd) constructs reusable live Godot controls, using the [painted skin renderer](../scenes/ui/theme/painted_skin.gd) and [state overlay](../scenes/ui/theme/state_layer.gd). Standalone style resources live under [styles](../assets/ui/styles/); the separate [scrim](../assets/ui/scrim.tres) supplies modal dimming. Do not assign this Theme to the main project globally as part of consuming the preview.

| Theme variation group | Named variations |
| --- | --- |
| Buttons and live painted factories | `RCPrimary`, `RCSecondary`, `RCPointed`, `RCSecondaryLive`, `RCTool`, `RCNav`, `RCSetting`, `RCSocket`, `RCCardLive` |
| Panels, detailed-card skins and dialogs | `RCPanel`, `RCDialog`, `RCMenu`, `RCForecast`, `RCCardDamage`, `RCCardShield`, `RCCardTechnique`, `RCCardMixed` |
| Labels | `RCTitle`, `RCBody`, `RCMuted`, `RCLocation`, `RCValue` |
| Value-driven bars | `RCHealth`, `RCEnergy`, `RCShield` |

Native Button/CheckButton/CheckBox/OptionButton, Label/RichTextLabel, LineEdit/TextEdit, PopupMenu/TabContainer, HSlider and scrollbars also inherit the shared appearance. Prefer the component factories for the pointed primary, clean sockets and live cards: those add independent slice scaling, safe live content and composable state layers that a single native StyleBox does not supply.

| Constructor or method | Data and returned control |
| --- | --- |
| `label(text, role, font_size)` | Live wrapping Label; roles `title`, `body`, `muted`, `location`, `value`; size0 uses the role default |
| `icon(name, extent)` | RC-012 imported SVG in a pointer-transparent TextureRect; known names route to their existing pack |
| `action(text, primary, minimum, states)` | Full rectangular Button; pointed turquoise when `primary` is true, painted navy otherwise; connect `pressed` |
| `apply_states(control, states)` | Replace composable visual state flags and refresh the overlay; selection/focus are independent |
| `socket(icon_name, states, endpoint, extent, quarter_turn)` | Clean board Button; `endpoint` accepts only BEGIN/END; glyph rotation preserves its center |
| `card(data, states, width)` | Detailed Button with cost/name/symbol/type/value and scrolling description; `kind` chooses damage/shield/technique/mixed material |
| `stock_tool(icon_name, title, remaining, total, states)` | Finite stock Button with separate live title, icon, remaining/owned slots and exhaustion treatment |
| `pile(kind, count, minimum)` | Draw/Discard Button with live count and explicit empty treatment |
| `forecast(values, columns)` | Grid of live damage/shield/cost/incoming cells; caller supplies values and responsive column count |
| `cast_button(data, minimum)` | VBox with pointed action, live energy/cost and reason/caption; action Button is metadata `rc_action` |
| `navigation(icon_name, title, states)` | RC-012 icon plus live label; also reusable for top Pause and Remove/Rotate |
| `status_bar(title, value, maximum, kind)` | Live label and value-driven ProgressBar; kinds health/energy/shield |
| `settings_toggle(title, enabled)` | Toggle Button; native `toggled(bool)` reports changed value |
| `settings_slider(title, value)` | Live percent label and HSlider; slider is metadata `rc_slider`, native `value_changed(float)` signal |
| `modal(title, body, width, height, confirm_text)` | Panel with independent body scroll and fixed footer; metadata `rc_close`, optional `rc_confirm`, `rc_body_scroll` |
| `map_node(state, icon_name, extent)` | Neutral sample icon plus current/available/completed/locked state; map ownership and navigation remain with consumer |

Card dictionaries support `name`, `cost`, `icon`, `kind`, `type`, `description`, optional `value`, `temporary` and `upgraded`. Cast dictionaries support `valid`, `affordable`, `cost`, optional `reason` and `states`. Constructors display copied input values; they are not subscriptions to a mutable combat dictionary. Refresh the corresponding control from a new detached snapshot, update the owning native Control property, or rebuild the relevant display when data changes. Keep callbacks on the owning screen/controller.

```gdscript
const Ui = preload("res://scenes/ui/theme/components.gd")

func build_presentation(container: Control) -> void:
    container.theme = preload("res://assets/ui/rune_cast_theme.tres")
    var remove := Ui.navigation("remove", "Remove")
    container.add_child(remove)
    remove.pressed.connect(on_remove_requested)

    var card := Ui.card({
        "name": "Shield", "cost": 1, "icon": "shield", "kind": "shield",
        "type": "Rune", "value": "5 shield", "description": "Add 5 shield."
    }, {"selected": true}, 202)
    container.add_child(card)
    card.pressed.connect(on_card_requested)

    var cast := Ui.cast_button({"valid": true, "affordable": true, "cost": 3})
    container.add_child(cast)
    var cast_action: Button = cast.get_meta("rc_action")
    cast_action.pressed.connect(on_cast_requested)
```

`on_remove_requested`, `on_card_requested` and `on_cast_requested` are the consumer's existing command callbacks; this library supplies no alternative command model. For Options, connect `settings_toggle(...).toggled` and the `rc_slider` HSlider's `value_changed` to the owning settings service. For modal completion, connect `rc_confirm` and `rc_close`; the generic component does not save, replace or abandon a run itself.

## Typography and live content

All ordinary labels, values, costs, names and descriptions are live Godot text. The decorative wordmark is the one explicit identity exception. Use Noto Serif 2.015 through the unchanged RC-012 resources: `assets/fonts/display/title.tres` at weight700/width100 for title and large actions, `assets/fonts/ui/labels.tres` at600/100 for labels/values, and `assets/fonts/ui/location.tres` at500/100. Godot variation dictionaries use `weight` and `width`; the raw SFNT tags `wght`/`wdth` are not the resource keys. System fallback remains disabled and the bundled OFL/attribution remain in the export presets.

Cream type has a dark outline; secondary copy uses a warm muted role without sacrificing available/unavailable explanations. Costs and stock remain separate slots, not part of frame artwork. Long names wrap, descriptions scroll, and hands can scroll horizontally. Keep the card type and effect text visible at a useful size; do not hide effect text behind an ellipsis or shrink a complete720-wide screen to claim native360 readability.

Default local font sizes are title28, body/location16, muted14 and value18, with2px dark outlines. Large factory actions use18, Cast26, detailed-card name/value16, description14, type13 and marker12. These are local layout pixels before a specimen's scale transform, not device-independent mobile measurements. Tiny board endpoints use11 at72px cells and17 above80px. Live content may override sizes after actual layout review; preserve the selected700/600/500 role weight.

## Slicing, padding and minimums

The exact dimensions, layer provenance and per-file slices are in [source-export-map.json](../source-assets/ui/source-export-map.json). Primary/secondary exports are512×128; square socket/panel/card exports256×256; bars256×64. Keep the painted surface and rim separate in their editable masters. No card text, cost, stock, circuit path or live bar percentage is baked in.

| Construction | Source slice caps and live layout |
| --- | --- |
| Pointed primary |56px left/right,18px top/bottom in the512×128 image. The custom renderer multiplies caps by live height/128, preserving tip/bevel proportions while the center stretches across width. Use `action(..., true)` or `cast_button`; never scale the whole bitmap nonuniformly. |
| Navy secondary |38px left/right,20px top/bottom source caps; factory destinations19/10px. |
| Square socket/card skin |24px source caps; factory destinations12px. Card content inset16px; pile inset12px; tool/navigation inset10px. |
| Native panel/dialog StyleBox |24px texture caps,20px content margins. Forecast uses its own compact safe margins. |
| Menu panel | `RCMenu` uses [menu.tres](../assets/ui/styles/menu.tres):24px texture caps and36px content margins on all sides, leaving12px beyond the painted bezel. Center the title; keep all actions inside this inset. |
| Bars |16px horizontal/8px vertical source caps, separate track and fill. The native ProgressBar owns the changing value. |
| Actions |Factory default180×56; caller may request larger sizes. The factory floor is44×44, while the actual delivered examples use larger controls. Cast default280×72 plus caption. |
| Stock/navigation/piles |Stock tools80×100; navigation68×80; piles at least90×144 before container expansion. Count/label and icon occupy separate live rows. |
| Cards |Default width202, minimum190. Height is at least312 and follows the actual wrapped content minimum plus32px margins; description owns a76px minimum scroll area. The hand needs enough height for its resulting minimum and a horizontal scrollbar. |
| Forecast/settings |Forecast cells142×64, arranged by the caller's column count. Sliders retain44px hit height with a12px visible track and existing26px RC-012 energy crystal as the live-value knob. |
| Dialog |Default312×430; title and fixed footer remain outside the independent body scroll. Footer actions are at least52px high; long body never pushes Close below the panel. |

At narrow widths, stack forecast cells and toolbar groups, scroll detailed hands horizontally, and scroll the page vertically. The visible pointed silhouette never replaces the full rectangular action target. Square board channels stay at N/E/S/W centers independently of decorative cap size.

## States and input

Normal and pressed treatments preserve the same painted construction. Selection has a persistent shape cue; focus has its own high-contrast outline and remains visible with selection or unavailability. Invalid uses a cross/broken-path cue plus live explanation. Unavailable combines muted material with a shape marker and reason; it is not a colour-only state. Stock counters show `remaining / owned`, including exhausted zero. In this delivery, `unavailable` and `disabled` both disable the native Button and suppress its ordinary pressed callback; put the reason in visible sibling text. Disabled Buttons are not ordinary tab targets. The combined focused/unavailable gallery state deliberately forces the visual focus overlay; it does not establish a keyboard or touch inspection flow. RC-016A/RC-042 must choose and test the separate inspectable affordance during integration.

Decorative textures, text, symbols and state layers must ignore pointer input. The underlying rectangular Control owns its full touch region, including transparent pointed tips. Visual alpha must not define or reduce its hit area. Consumer callbacks must be connected to the owning control; state renderers do not apply gameplay commands, consume stock, validate a circuit, save a run or navigate a shop.

The board remains a separate clean surface: only live **BEGIN** and **END** text, with no other names, values, cost, TEMP or upgrade badge. Frames leave the four exact RC-012 edge channels unobstructed. Draw connection strokes on their own live geometry layer with blunt ends and no directional arrows; use shape collars for powered state. Do not infer Split/Join logical ports from their fork/trident decorative endpoints. Temporary and upgrade marks belong in card/detail contexts only.

## Responsive composition and dialogs

The720×1600 and450×1000 specimens test the shared design construction at two desktop scales. Native360×640 specimens reflow into a scrollable page with a separate scrolling hand. These are presentation samples, not a fixed replacement for the game's layout. Maintain at least the documented component minimums when choosing container widths, and put overflow in the relevant scroll area instead of scaling fonts to unreadability.

Dialogs separate a scrolling body from a fixed footer so Close and confirmation remain reachable. The dimming surface is a resource, not a full-screen raster. Modal owners must establish focus, prevent activation of the covered screen, and restore focus when closing during integration. A generic detail/modal does not decide the new gameplay inspection gesture or no-cast turn-ending route; those remain RC-016A decisions.

Home specimens cover no save, available save, invalid-save feedback and replacement confirmation. Following the owner's October 12 clarification, Menu uses turquoise Resume with navy Options, **Store** and Quit. Store is a separate destination for buying in-game items such as runes, perks and relics; it is not gated on being in a shop room. Entering a shop room opens that room as the main screen. The generic unavailable Store specimen demonstrates a visual state only, with no decided eligibility, connectivity or payment rule. Shared Options uses the same controls for volumes, mute/Sound states and reduced motion. Map specimens use neutral existing symbols on a parchment-compatible surface with current/available/completed/locked cues; this does not deliver RC-041's full map library or route behavior.

## Sample data and integration handoff

The presentation gallery uses finite values from the current content files. The starter loadout owns eight cards and begins with three drawn, HP30/30 and energy3; an untouched opening can therefore show Draw5 and Discard0. Shadeling has32 HP and the first intent is8. Spark adds6 damage at cost2, Shield adds5 shield at cost1, Focus draws2 at cost1, and Conjure Spark creates one Free Spark at cost0. Free Spark shares Spark's board symbol, adds6 damage at cost0 and has temporary lifetime text only in cards/details. A preview of an upgraded marker does not introduce new gameplay upgrade values.

The actual finite kits in `data/production_rules.json` are Straight/Corner/Split/Join totals6/2/1/1,4/4/1/1, or4/2/2/2. Example availability can be lower as pieces are installed; it cannot exceed owned stock. The approved reference's infinity, BOSS label, fixed board and example totals do not change this model. Display specimens can supply independent valid/invalid/unaffordable presentations without computing a competing forecast.

RC-016 should bind detached combat snapshots to cell geometry, live card/pile/stock values, health/energy, action log and permanent damage/shield/cost/incoming summary. Connect Remove and Rotate to the migrated controller only after RC-016A; retain navigation and separate top Pause. Bind the large pointed Cast to the accepted command/affordance without deriving validity from its appearance. RC-042 should reuse this Theme and modal/card/button components across Home, Map, Menu, Options and later progression screens, supplying its own data and callbacks.

## Packaging, provenance and limits

Editable masters stay under `source-assets/.gdignore`; both export presets already exclude `source-assets/*`, `output/*` and `tools/*`. No source master, review sheet, isolated preview project or approved reference should be packaged. The source-delivery record distinguishes retained generated brushwork from new deterministic vector/code work and preserves the original generation reference and unknown model/seed fields. The Noto direction is not claimed identical to the unknown reference font.

Inherited painted-art rights were unresolved in the retained pilot. Technical import success does not resolve those rights. Under the manifest's stricter vocabulary, affected painted packs remain `source_ready` with existing, technically verified exports until RC-050 resolves distribution provenance. Independently authored code/vector resources can be `runtime_ready` after their own checks; assembled-theme availability does not clear its dependent painted textures for release.

Desktop imports and rendered specimens establish technical/layout evidence only. They do not establish physical-device touch sizing, safe areas, low-resolution display readability, mobile GPU memory, owner approval or main-game integration. RC-021/RC-022, RC-044 and the later device/performance tasks retain those checks. Memory figures must count each shared texture once and exclude dynamic font atlases/engine buffers explicitly.

## Reproduce and review

Run the isolated [preview wrapper](../tools/preview_ui_theme.ps1); it stages exact runtime/font/icon/component copies into the excluded `output/qa/rc-013/preview-project` and renders through the pinned Godot4.7.2 Compatibility renderer. The [preview project source](../tools/rc013_preview/project.godot) remains separate from the main game. The source builder is documented in [source delivery](../source-assets/ui/delivery.md).

For the current Menu audit, run `.\tools\preview_ui_theme.ps1 -EvidenceName menu-button-revert -MenuOnly` first. Then open the generated `output/qa/rc-013/menu-button-revert/preview-project/project.godot` in the pinned editor and run its default [interactive gallery scene](../tools/rc013_preview/gallery.tscn). Its canonical [project source](../tools/rc013_preview/project.godot) and gallery remain retained; generated copies can be cleaned and recreated. The gallery lets reviewers exercise controls/scrolling without replacing the main game's launch scene. The [smoke log](../output/qa/rc-013/interactive-gallery.log) remains the original historical launch evidence.

```powershell
.\tools\preview_ui_theme.ps1
python .\tools\validate_ui_theme.py
python .\tools\validate_asset_plan.py --report output/qa/rc-013/asset-plan-validation.json
```

Use the configured bundled Python executable if `python` is not on PATH. The focused validator checks source/export records, actual imported texture dimensions, font-role RIDs, exact staged-resource identity, local resource dependencies, live text/layout results, pointer/focus/disabled callbacks, scrolling Close access, package exclusions and547 protected baseline hashes. It does not run or replace the gameplay evaluator suite. [Import log](../output/qa/rc-013/godot-import.log), [render log](../output/qa/rc-013/godot-render.log), [render results](../output/qa/rc-013/godot-render-results.json) and [asset-plan validation](../output/qa/rc-013/asset-plan-validation.json) retain the actual evidence.

| Actual Godot evidence | Coverage |
| --- | --- |
| [State gallery](../output/art/rc-013/states-full.png) | Normal/pressed/focused/selected/disabled/invalid/unavailable, combinations, Sound states, valid/invalid/unaffordable Cast and clean board treatments |
| [Detailed cards](../output/art/rc-013/cards-full.png), [native cards](../output/art/rc-013/cards-native-bottom.png), [eight-card hand end](../output/art/rc-013/cards-native-hand-end.png) | Live costs/names/type/effects/value, long copy, temporary/upgraded variants, empty/populated piles and horizontal/description scrolling; the hand stress specimen uses the eight actual starter card instances |
| [720×1600](../output/art/rc-013/components-720x1600.png), [450×1000](../output/art/rc-013/components-450x1000.png), [native360×640](../output/art/rc-013/components-360x640.png), [native scrolled controls](../output/art/rc-013/components-bottom-360x640.png) | Actual imported material/port/text layout at the requested output sizes; the720 specimen scales the450-layout construction by1.6, while360 reflows natively |
| [Home no save](../output/art/rc-013/home-empty-450x1000.png), [save available](../output/art/rc-013/home-save-360x640.png), [invalid save](../output/art/rc-013/home-invalid-450x1000.png), [replacement confirmation](../output/art/rc-013/replace-360x640.png) | Separate wordmark, turquoise Continue, navy secondary controls and live feedback/confirmation |
| [Corrected Store menu](../output/art/rc-013/menu-button-revert/menu-open-360x640.png), [generic unavailable Store](../output/art/rc-013/menu-button-revert/menu-locked-360x640.png), [Options](../output/art/rc-013/options-360x640.png) | Dimmed Menu with pointed turquoise Resume and navy secondary actions, Store independent of shop rooms and content clear of the painted border; generic availability style, shared settings/toggles/volume tracks and state cues |
| [Map states](../output/art/rc-013/map-360x640.png), [scrollable detail](../output/art/rc-013/dialog-360x640.png), [wordmark sizes](../output/art/rc-013/wordmark-450x1000.png) | Parchment-compatible current/available/completed/locked rings, fixed Close and independent card detail scroll, Home/header identity legibility |

The [independent visual review](../output/qa/rc-013/visual-review.json) compares final captures against the approved screen references and retained r006 construction; it records hashes, resolved defects and remaining integration/device limitations. A [screen-state contact sheet — retired during cleanup](asset-cleanup.md#october-13-2026--project-wide-follow-up-cleanup) combines four unmodified native renders for convenient review; it is derived evidence, not an additional Godot render or runtime asset.

The actual Windows GPU was NVIDIA GeForce RTX5070Ti. Logs report host `user://`/shader-cache and root-certificate-store diagnostics; source/import/script/layout checks have no failures. These diagnostics are recorded, not hidden or presented as a gameplay regression. The specimens use neutral component backgrounds; none claims a rebuilt complete Combat screen with an unfinished environment. The next numbered task is **RC-014**, the production Shadeling character pack.

## October 12 correction — Store and shop-room separation

The original 34 renders and their reports remain historical evidence of the RC-013 delivery. Their Shop label and shop-room-only explanation are superseded by the owner's clarification above. Six [corrected Menu renders — retired during cleanup](asset-cleanup.md#october-13-2026--project-wide-follow-up-cleanup) cover normal Store and generic unavailable-state styling at720×1600,450×1000 and native360×640. The [new Godot report](../output/qa/rc-013/store-clarification/godot-render-results.json) records zero layout/input errors. The generic unavailable example does not establish a purchase or eligibility rule; the technical mode name `menu-locked` is retained for preview compatibility only.

Reproduce this narrow revision without overwriting prior evidence:

```powershell
.\tools\preview_ui_theme.ps1 -EvidenceName store-clarification -MenuOnly
```

Store catalog/transactions and permanent rune acquisition require their own design and implementation tasks. No purchase, reward, shop-room navigation, saving or gameplay logic was added by this presentation correction.

## October 12 correction — Menu border clearance

The owner identified that MENU and Quit overlapped the painted frame. The inherited20px content inset was smaller than the24px bevel. The reusable `RCMenu` variation now applies36px padding on every edge, and the live MENU title is centered. The menu retains Resume, Options, Store and Quit.

Six [replacement previews](../output/art/rc-013/menu-button-revert) cover both Store states at720×1600,450×1000 and native360×640. The [Godot report](../output/qa/rc-013/menu-padding/godot-render-results.json) includes33 content-bound checks requiring at least8px clearance beyond the24px bezel; every measured minimum is12px. Whole-panel viewport bounds, existing text/input checks and visual review of all six images pass. Earlier evidence remains historical: its outer-rectangle containment check did not detect this painted-border overlap.

Reproduce in a separate evidence destination with `.\tools\preview_ui_theme.ps1 -EvidenceName menu-padding -MenuOnly`. RC-042 should use `RCMenu` for the integrated menu. This correction remains isolated theme work, with no main-screen integration or physical-device verification.

## October 12 revision — Shared menu button frame (superseded)

This superseded revision made all four Menu actions share the secondary button frame and used a shader for Resume's turquoise face. The owner subsequently requested reverting that button change. The helper and shader are no longer part of the current library; no bitmap was changed.

The [six historical Godot render records](../output/qa/rc-013/menu-shared-frame/godot-render-results.json) retain that revision's text, input and33 border-clearance checks. Its [shared-frame preview images were retired during cleanup](asset-cleanup.md#october-13-2026--project-wide-follow-up-cleanup); they do not describe the current menu appearance.

## October 12 correction — Restore the previous menu buttons

At the owner's request, Menu again uses `action()` with pointed turquoise Resume and navy Options, Store and Quit, matching the [menu-padding previews](../output/art/rc-013/menu-button-revert). The corrected `RCMenu`36px padding and centered title remain in place. RC-042 should use the existing primary/secondary action factory inside `RCMenu` when integrating this menu.

All six fresh renders pass in the [revert Godot report](../output/qa/rc-013/menu-button-revert/godot-render-results.json) and are SHA-256-identical to the corresponding menu-padding baselines. [Revert validation](../output/qa/rc-013/menu-button-revert/validation.json) records33 content-bound checks with a minimum12px clearance beyond the painted border. Reproduce without overwriting earlier evidence using `.\tools\preview_ui_theme.ps1 -EvidenceName menu-button-revert -MenuOnly`.
