# Reusable UI theme and wordmark — RC-013

## October 25, 2026 — Focused enemy intent details

Keep the existing attack icon and value geometry. A compact outlined tap/hold target with a small **i** opens the shared navy/gold inspector; the body scrolls and Close stays fixed. Sequence values use ordinary slash separators supported by the shipped body font. Phase changes use the existing transient text overlay, without new artwork, poses or sound. No Incoming row, BOSS caption, Pause control, forecast action or board-slot inspection returns. The accepted compact Store and surrounding Combat layout remain intact. [RC-033 captures and verification](rc-033-verification.md).

## October 25, 2026 — Accepted Store restored to normal navigation

The owner accepted the concrete Store defaults and authorized re-enablement, superseding the temporary global-unavailable state. Keep the Menu label **Store** stable: enable it at a settled Map boundary and otherwise use disabled styling with its actual state-dependent reason. Reuse the compact catalogue below, detailed purchase confirmation and fixed Back. Preserve shared Menu/Options sizing, literal **Resume Combat**, caller-specific shop/service information and approved Home/Map/Combat composition. [Accepted contract](decisions.md#october-25-2026--store-defaults-accepted-and-production-enablement-authorized), [current handoff](rc-032-store-verification.md).

## October 25, 2026 — Compact Store catalogue correction

The owner found the Store's rune imagery oversized and its copy excessive. Store now uses simple navy list rows with 32px existing glyphs, an item name and short effect summary. Prices and purchase availability are grouped at the category heading instead of repeated purchase buttons and error paragraphs. Full descriptions and exact costs remain in the confirmation; rune energy cost is shown there after removing the large catalogue card. The shared gold outer frame and fixed Back action remain. Rows keep 68px minimum targets and expand when text wraps; unavailable states stay visible with one contextual reason per category. This supersedes the full-card catalogue layout in the initial Store delivery below.

## October 25, 2026 — Functional separate Store

The [accepted Store contract](decisions.md#october-25-2026--separate-store-contract-accepted) supersedes the generic unavailable-only destination. The existing shared Menu opens Store between fully settled rooms and states why it is unavailable otherwise. Store uses the same navy/gold popup components, typography, 68px actions, scrolling body and fixed **Back to Menu** action. Rune cards reuse current definition presentation; relic names/descriptions reuse the supported six definitions. Purchase confirmation shows exact cost, remaining Gold, benefit and the once-per-category run limit. Store returns to the same Menu/Map without consuming a visit. Home artwork/actions, literal **Resume Combat**, route-shop main screens and Combat composition remain unchanged.

## October 23, 2026 — Fit popup content up to the Menu height

Popups grow only as needed to display their complete text, with the shared Menu's **660 px height** as the maximum before narrow-window fitting. Correct wrap-width measurement and body allocation remove unnecessary scrollbars from short confirmations, including New Run replacement at every tested size. Long guides and lists scroll only within the cap, with fixed bottom actions and a reserved scrollbar lane. Collection/reward panels omit duplicate cost/effect copy already visible on their cards. The approved Menu, shared text/control sizes and padding remain unchanged. [Verification and captures](popup-sizing-verification.md#october-23-follow-up--fit-complete-text-within-the-menu-height) record **889 rendered checks**, **1,175 UI checks** and the final resource-only audit.

## October 23, 2026 — Keep Home focused on artwork and actions

The owner removed the run-status summary above Continue and the checkpoint, battle-replay and music-availability notes below Options. Home presents its tower artwork, logo and Continue, New Run and Options actions, without routine status, tutorial or development notes in those regions.

Favor discovery through play over unnecessary explanatory UI copy. Keep essential action labels and actionable confirmations or errors concise. This correction targets the two marked Home text blocks; the shared Menu and popup sizing/style decisions below remain in force.

## October 23, 2026 — All popups share Menu text and control sizing

The owner extended the restored gameplay Menu sizing to every popup: **22 px headings, 16 px body text, 18 px action labels and 68 px minimum action rows**, with the same sharp serif fonts and 36/40 px panel padding. Options, Collection, Rewards, Map inspection/Guide, confirmations/results/save recovery and Combat native/inspection dialogs share one display-size policy. Long content scrolls above fixed actions; narrow windows use Menu's existing uniform fit. Native dialogs retain borderless frames and their original input callbacks. The approved Menu interior remains pixel-identical. [Implementation, captures and validation](popup-sizing-verification.md) record **438 rendered checks**, **1,175 UI checks**, clean lifecycle/persistence regressions and a fresh resource audit.

## October 23, 2026 — Gameplay screenshot is the shared Menu reference

The owner selected the **large gameplay Menu screenshot** as the canonical appearance for both Map and Combat, explicitly rejecting the smaller Map reference used in the October 22 follow-up below. Both screens still open the same `route_menu` instance. They use the gameplay body copy, “Resume keeps this battle unchanged. Quit to Home discards battle progress; Continue replays its entry.”, and the exact **Resume Combat** label in both contexts. Resume still returns to the caller.

At the actual **450×1000** game window, the panel is **402×660 physical pixels at (24, 170)**. It retains **68 px** action minima, **14 px** action gaps, **22/16/18 px** heading/body/action fonts and **36/40 px** horizontal/vertical padding. A local inverse canvas transform restores this Menu size without changing project stretch, gameplay art, Combat layout or the shared 82 px navigation. At **360×640**, the existing letterboxed content is **288×640**; the fitted panel is **249.6×528** physical pixels with **54.4 px** action minima.

Menu-local copies of the existing fonts render at the intended display size without changing shared font imports. Final configured-root checks pass **143/0**, with **1,174/0 UI** and **118/0 shell** regressions. The fresh resource-only package passes **386 integrity, 106 payload-decode and 32 Python checks**. [Current verification](rc-027-verification.md#gameplay-screenshot-restored-as-the-shared-menu-reference), [measurements](../output/qa/gameplay-menu/results.json), [Map Menu](../output/qa/gameplay-menu/map-menu-450x1000.png) and [Combat Menu](../output/qa/gameplay-menu/combat-menu-450x1000.png).

## October 22, 2026 — One shared Map and Combat Menu

**Historical sizing decision:** the smaller Map Menu selection in this section is superseded by the October 23 gameplay-screenshot contract above. The single-instance implementation remains in force.

The owner clarified that both screens must use the exact same Menu. Normal run-managed Combat now requests the application's existing Map Menu instance instead of showing its separate native dialog. Both entry points use identical heading, body copy, Resume label, buttons, sizing, canvas and artwork. Resume returns to the caller; Options and Collection return to the retained Menu. Combat Quit keeps its checkpoint warning in the confirmation. Explicit standalone development encounters retain their separate development actions.

The earlier comparison mixed an unscaled 450×1000 test viewport with a normal 720×1600 game canvas displayed at 450×1000. The previous audited runtime's two menus actually scale alike under the same configured window, but their copy and separate implementations differed. Verification included the real root-window stretch configuration, exact text and instance identity, plus matching panel pixels at the same physical size. This revision used the normal Map Menu as its sizing reference; the owner subsequently replaced that selection on October 23. No global stretch, Combat or navigation geometry changed. [Historical verification](rc-027-verification.md#one-shared-menu-and-configured-window-scaling).

## October 22, 2026 — Matching menus and borderless popups

The latest owner correction makes Combat's Menu match Map's Menu: the same 560×660 preferred panel, internal Menu heading, dimmed background, 18 px action labels, 68 px minimum button height, padding and footer positions. Both show Resume first in turquoise, then Options, Collection, unavailable Store and Quit to Home; Resume names its current screen. Combat copy retains the battle-entry replay warning. Standalone development actions retain their existing callbacks.

All three native popup constructors (Menu, Guide/error/result text and experiment observations) are borderless. Titles appear inside the content panel, and visible dismiss actions retain their existing signals and Back handling. Production Menu/Guide no longer reserve native footer spacing or title-bar geometry, so their full panels keep the same 24 px outer gutter as Map. This supersedes the earlier embedded-chrome exception below. [Verification](rc-027-verification.md#matching-menus-and-borderless-popups), [Combat Menu](../output/qa/menu-match/combat-menu-450x1000.png) and [narrow Guide](../output/qa/menu-match/combat-guide-360x640.png).

## October 22, 2026 — Taller Menu and shared panel spacing

The owner's spacing correction gives Map and Combat Menus a preferred height of 660 px, with 68 px action buttons and 14 px gaps. Short portrait screens reduce the scrolling copy area so the actions remain reachable. Shared modal bodies now use 36 px horizontal and 40 px vertical padding, with 20 px between title, body and footer. Panels fit within a 24 px outer gutter; embedded native window decoration extends beyond its client area.

Options, Guide, room inspection, confirmations, collection, rewards and Combat inspection use the same padded gold-frame/navy-body treatment. Current cards, board and the shared 82 px navigation retain their geometry. [Verification](rc-027-verification.md#menu-and-panel-spacing-follow-up), [Map Menu](../output/qa/menu-spacing/map-menu-450x1000.png) and [narrow Combat Menu](../output/qa/menu-spacing/combat-menu-360x640.png) supersede the earlier Menu/panel spacing captures.

## October 21, 2026 — Disabled and unavailable symbols removed

The owner's correction applies to every screen and shared UI component, including Home, menus, Combat and previews. Disabled or unavailable controls use muted appearance, their existing live reason or status, and the appropriate input guard. Never add a barred-circle badge or any other disabled/unavailable symbol. Focus and selection remain independent states. Earlier specimens and dated records showing availability symbols are historical and do not authorize their return.

## October 18, 2026 — Reused Options in playable Combat

RC-020 adds Menu access to [reusable Audio Options](../scripts/ui/audio_options.gd), built with the existing `Ui.modal`, `settings_slider` and `settings_toggle`. Music/SFX levels and independent mutes, compatible Sound master and reduced motion bind to the shared ConfigFile service; rebuilding controls is silent. Options sits in the existing Menu body, preserving Restart/Exact replay/Resume and bounded narrow-layout text scrolling. No Home/run navigation is added. Nine actual-scene captures at 720×1600, 450×1000 and 360×640 pass 42 bounds/scroll/fixed-Close checks. [Verification](rc-020-verification.md), [360 Options](../output/qa/rc-020/options/options-top-360x640.png), [360 Menu](../output/qa/rc-020/options/menu-360x640.png).

## October 16, 2026 — Unused runtime exports retired

The shared UI pack now exports 17 used resources. Removed the duplicate pile.png (piles already load panel.png) and eight unused non-node state SVGs (StateLayer already draws those cues). Four dynamically loaded Map-node SVGs and all editable source layers remain. The builder and source/import validators enforce the reduced export set. [Source map](../source-assets/ui/source-export-map.json) and [cleanup record](asset-cleanup.md#october-16-2026--unused-resource-cleanup).

## October 16, 2026 — Generated painted status frame

Stats uses the complete image-generated [painted frame](../assets/ui/combat/reference/status-frame.png). The generated slate, gold rails, closed ends and dividers render together; local border polygons and divider lines are removed. Original source columns `[20, 683.5, 1302.5, 1968]` map to the three equal live cells, while rows `[270, 314, 458, 502]` map to `[0, 8, height-8, height]`. This preserves the existing 54px frame, 36px content lane and 24/9/24/9 default margins. The 1987×791 source is unchanged; its lossless, nonmipmapped import is limited to 768px. [Prompt and provenance](../source-assets/ui/combat/reference/status-frame/provenance.json), [comparison](../output/qa/rc-016/stats-generated-frame/before-after.png), [verification](verification.md#october-16-2026--generated-painted-status-frame).

## October 16, 2026 — Drawn status border

Stats uses a directly drawn closed chamfered bezel. Its dark outer contour is inset1px, the continuous3px gold band spans insets2–5px, and the slate face clips at6px. Straight1.5px gold dividers with3px dark underlines meet the inner frame. The 54px row and 24/9/24/9 content margins are unchanged. This supersedes all earlier stats rim/endcap sampling; other surfaces retain their art. [Comparison (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup) and [geometry](../source-assets/ui/combat/reference/regions.json).

## October 16, 2026 — Status-bar end borders

Stats retains its original upper/lower rails and 24/9/24/9 content margins, with mirrored gold bridges closing the previously open side flares. `CombatSurface._draw_stats_endcaps` samples the original divider at uniform height scale; it adds no bitmap and draws above the clipped face. [Geometry/provenance](../source-assets/ui/combat/reference/regions.json), [before/after (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup), and [verification](verification.md#october-16-2026--status-bar-end-borders).

## October 15, 2026 — Full-screen reference polish

Production Combat now uses the original player-status rails and flared separators with a clipped clean face and separate rim. Its 54 px row has default 24/9/24/9 content margins, yielding a contained 36 px well. Seven original empty-socket material variants preserve the cell footprint while varying slate cracks; the ribbon keeps its full shaped ends. These replace the substitute stats frame and repeated socket surface described in earlier dated entries.

Shared Combat font resources use width100: display weight700, label/body/value weight600. Compact cards keep their 149×146 footprint and 25×29 cost glyph, with 18 px names (smaller for long names), 16 px effect copy, explicit outline room and the existing scroll lane. No card-category line is restored. Draw/Discard caption fitting keeps their original pile art and count geometry. [Card/pile render (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup) and [fit measurements](../output/qa/rc-016/full-screen-polish/typography-fit.json) record the result.

Cast uses a local weight850 variation and 4 px outline, retaining its 43 px normal font size. Tool counts use -4/-4 line spacing. Footer icons occupy y13–49 and captions y52–70 with -5/-5 line spacing; the font stays19 px normally,17 px below400, with only Sound reduced to16 px at that narrow width. These explicit lanes pass the existing painted-frame containment checks.

Begin's painted circle uses the original atlas through a masked child TextureRect inside the unchanged endpoint glyph bounds. Its label stays live and only its connection rotates. End retains its SVG because wire/text overlap the original painted ring.

`ReferenceIcons` supplies original atlas textures and contour masks for Menu, Map, Guide, Sound, Health, Energy, Shield and Focus. `Ui.apply_combat_icon(TextureRect, name)` is the binding contract: update both texture and material together; the Sound-off SVG requires a null mask. [Navigation (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup) and [resource (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup) proofs show transparent outer gaps. Remove/Rotate art is 36×36 at y10 within its padded lane; navigation uses separate icon and caption lanes clear of its frame.

The approved actor remains separate from the restored scenery through their shared silhouette mask. [Source recombination](../output/qa/rc-016/whole-screen-art/actor-arena-pixel-proof.json) records zero RGB error over 360,002 visible source pixels, excluding live-label holes. That scoped proof does not identify the source typeface or establish whole-screen identity: generated Attack/Spark and board glyphs remain among the fallbacks, and hidden paint uses clean patches.

The owner's later removals and mobile behavior remain: no Pause/BOSS/card categories/Incoming/Cast caption/hover popups, no floating unavailable badges, small card gems, padded controls, display-only forecast and confirmed Pass. [Current screen (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup), [integration](rc-016-integration.md#october-15-2026--full-screen-reference-polish) and [verification](verification.md#october-15-2026--full-screen-reference-polish) are the current contract; older entries below are historical where they differ.

## October 15, 2026 — Cast face continuity

`CombatSurface` now draws Cast's clean turquoise face with one shared mapping across the complete pointed inner contour, then draws the approved gold/cyan rim separately. Replacing only the old nine-slice center left a darker right-cap face and a visible seam at source x649. The center portions of the middle and lower rim use a clean strip at matching source heights so the original cost crystal and shadow do not reappear.

The outer silhouette, caps, dimensions, live cost, input and state feedback are unchanged. This is a sampling correction using the existing atlas; no bitmap was generated or edited. [Current screen (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup), [integration](rc-016-integration.md#october-15-2026--cast-face-continuity) and [verification](verification.md#october-15-2026--cast-face-continuity) describe the current implementation.

## October 15, 2026 — Stats inner frame correction

The earlier stats center rectangle overwrote diagonal gold pixels despite passing outer-bound and child-padding checks. Those checks did not cover the painted inner bevel, so the previous containment claim was incomplete.

The live stats row also uses z30 to sit above the arena environment/actor/status layers at z20/21/22 and below the inspector at z100. This prevents arena bleed from overpainting its top rim without changing arena allocation or cropping.

Only the stats renderer now uses an explicit inner contour and border ring. Its 40/19/40/19 source caps scale to the current row height using height/79. The clean face is drawn inside the inner polygon first; the original rim is drawn above it, with clean recess samples excluding old reference content. The 54 px row, 24/11/24/13 margins and divider span y11–41 remain. [Corrected actual bar (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup), [current screen (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup) and [verification](verification.md#october-15-2026--stats-inner-frame-correction) document the correction; other controls and source artwork are unchanged.

## October 15, 2026 — Display-only forecast and frame cleanup

Production Combat's Damage/Shield/Cost strip is a display-only `Control`. It and its contents ignore pointer input, do not receive focus and have no tap or hold callback. Live controller values still refresh the three centered totals. Card Info, other inspection targets and Pass confirmation retain their existing interactions.

Stats now combines the approved closed gold frame Rect(40,1581,762,79) with the clean stats face. Dividers sample only the upright Rect(281,531,10,29) and stay inside the frame, clear of both rails. This replaces the open rails and mismatched end caps while keeping the 54 px strip and 30 px well.

The board crop stops at source y1255 before the neighboring toolbar corner. `ReferenceBackdrop` also excludes the old board corner by sampling its right strip from x824 with width 17, painting that strip at 24k+1 logical pixels to cover the fractional underpaint seam. Correcting the board alone did not remove the separately scaled gold sliver. Source PNGs remain unchanged.

[Current screen (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup), [integration](rc-016-integration.md#october-15-2026--display-only-forecast-and-frame-cleanup) and [verification](verification.md#october-15-2026--display-only-forecast-and-frame-cleanup) supersede earlier forecast-details guidance. Shared preview factories and dated delivery evidence remain separate from this production binding.

## October 15, 2026 — Header order and connector rotation

The full-width 52 px Combat header keeps its painted background and lower rule, with the approved wordmark on the left and the live floor label on the right. Production board rendering keeps Split and Join's central emblems in their approved orientation while applying the selected rotation to their logical ports and connection strokes.

The card top-left gap came from using an unflipped lower-left corner and below-frame background rows. `CombatSurface` now samples the clean upper-right corner with a horizontal UV mirror, retaining the 11 px upper rim. The change repairs the painted join without altering card size, cost size or padding.

Original pile bodies and emblems, live counts, and compact-card cost symbols at 25×29 with 20 px numbers remain. Source artwork is retained. [Current screen (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup), [integration](rc-016-integration.md#october-15-2026--header-order-and-connector-rotation) and [verification](verification.md#october-15-2026--header-order-and-connector-rotation) supersede the previous header order below.

## October 15, 2026 — Header and reference pile correction

Combat's 52 px header now fills the full portrait viewport. `CombatSurface` first paints a clean header patch across its full bounds and then its gold lower rule. The floor label remains live at the left; the right-aligned wordmark samples Rect(56,1,245,46) at uniform scale. Pause remains absent.

Stats now clips source exterior stones to its own silhouette, preserving the 54 px frame and 30 px padded content well. The toolbar's left-middle sample uses Rect(21,1260,20,107): the former 25 px cap included the original WIRING parchment edge at x42 and produced the stray gold line beside Pass. This is a sampling correction, not extra button padding.

[`reference_pile.gd`](../scenes/ui/theme/reference_pile.gd) owns the distinct Draw and Discard body regions, original emblems and plaques. Each body uses one uniform scale inside the art lane; only its original numeral is cleared before the live count is drawn, and the last 20 px remain the live caption lane. The obsolete `CombatSurface` deck/deck-count/mirroring branches are removed. Compact-card cost glyphs are 25×29 with 20 px live numbers. No source PNG changed. [Current screen (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup), [integration](rc-016-integration.md#october-15-2026--header-and-reference-pile-correction) and [verification](verification.md#october-15-2026--header-and-reference-pile-correction) supersede the earlier pile/header implementations below.

## October 15, 2026 — Mobile presentation corrections

Normal Combat uses a live left-aligned floor heading without the product wordmark or Pause control, and omits the BOSS caption. The shared wordmark, Pause and state resources remain available to other consumers. Production controls suppress hover tooltips and decorative invalid/unavailable x/circle badges; availability guards, focus and selection remain active. Detailed information is available through tap/hold, Info, the forecast and confirmed Pass.

`CombatSurface` now maps Cast and parchment silhouette masks through the same nine-slice transform as their paint, excluding pixels from outside those shapes. Stats source caps are 33/12/35/12; destination caps remain 24/7/24/9. Its 24/11/24/13 content margins leave a 30 px high well inside the 54 px frame; live value fonts are 26 px and Turn is 21 px. Navigation separates the glyph lane at y13–43 from the caption lane at y45–69, inside the 82 px frame. Its end segments use 26 px outer and 8 px inner padding; captions use 18 px type, or 17 px below 400 px native width.

The Combat pile uses `flip_h` on its artwork surface for Discard. `get_front_face_rect()` maps the actual front card through slicing and mirroring so upright symbols and counts center on that card. Deferred layout callbacks validate their controls before use. These changes do not modify source PNGs or the shared preview defaults. [Current screen (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup), [integration](rc-016-integration.md#october-15-2026--mobile-presentation-corrections) and [verification](verification.md#october-15-2026--mobile-presentation-corrections) supersede the earlier dated Combat layout notes below.

## October 15, 2026 — Approved reference artwork adoption

CombatSurface now samples original empty sockets, isolated decorative rims and clean material patches from the approved atlas. It retains its existing surface/state API and is input-transparent; live content and hit targets remain in controls. [Sampling regions](../source-assets/ui/combat/reference/regions.json) document which pixels can appear, including exclusions around card cost badges and printed reference content. The static Combat wordmark uses its original reference region. Combat resource/card/navigation glyphs use a generated transparent symbol atlas through [reference_icons.gd](../scenes/ui/theme/reference_icons.gd); canonical RC-012 SVGs and font files remain unchanged for shared consumers.

The [current integration](rc-016-integration.md#october-15-2026--approved-reference-artwork-adoption) preserves the card-category, Incoming and Cast-caption removals and circuit-button padding. Original RC-013 source packs remain available. Eighteen obsolete generated Combat surface PNGs were retired under the [cleanup ledger](asset-cleanup.md#october-15-2026--approved-reference-surface-cleanup). Sampled original decoration does not establish identical hidden textures, generated glyphs or live-font rasterization. [Current verification](verification.md#october-15-2026--approved-reference-artwork-adoption).

## October 15, 2026 — Full-screen type and spacing

Production compact cards omit category labels and use one divider; effect text fits at 16–18 px in a 58 px lane. The forecast shows three centered totals with no Incoming row. Stats use 32 px values, a 42×38 health-icon lane and 30×38 energy lane at design width, within a 40 px interior. Circuit controls use 76 px height, 16/18 px title/count text and 28 px icon lanes; the toolbar uses 30/15/30/21 px margins, with 26 px bottom margin in the two-row fallback. Feedback uses one consistent 23 px lane. Navigation labels use 20 px, and Cast lettering uses gold with a dark outline. Endpoint captions use a local small-cap font variation and measured visible-ring bounds. [Current implementation and exceptions](rc-016-integration.md#october-15-2026--full-screen-reference-alignment) supersede earlier dimensions below.

## October 15, 2026 — Circuit button gutter

Toolbar content margins are now 30/16/30/20 px, with 24 px bottom inset for the two-row fallback. Vertical destination caps use 12 reference units rather than 20 so the painted rim leaves a visible slate gutter around the unchanged 64 px controls. Desktop control separation is 8 px; the narrow grid retains 6 px. [Current details](rc-016-integration.md#october-15-2026--circuit-button-padding).

## October 15, 2026 — Painted-well padding

`CombatSurface.CONTENT_MARGINS` describes measured clear content space separately from decorative slice caps, and `get_content_rect()` exposes that space. Production stats reserve 22/10/22/12 px (left/top/right/bottom); the toolbar reserves 22/16/22/20 px. `_combat_panel` consumes these margins. Stats use three padded cells with separately centered icons and a Turn parchment containing its own label. Stock controls use 64 px input heights, 14 px titles, 22 px glyph lanes and 16 px counts. Editing controls have centered 60×42 plates, 26 px glyphs and 14 px captions. [Containment details](rc-016-integration.md#october-15-2026--painted-frame-containment).

## October 15, 2026 — Highlighted content lanes

`Ui.cast_button` accepts `show_caption=false`; normal Combat uses it to omit the label and strip while preview callers retain the default caption. `CombatSurface` supports `deck_count`, an unsliced crop of the existing deck plaque rather than a new texture. Counts use local font spacing to fit their 38×27 plaque; captions have separate bounds. `StateLayer` accepts optional `rc_state_rect` metadata for invalid/unavailable badges inside a painted button body; focus and selection still cover the full input target. [Current correction](rc-016-integration.md#october-15-2026--annotated-area-correction-and-caption-removal).

## October 15, 2026 — Combat scale and typography

The [measured layout correction](rc-016-integration.md#october-15-2026--reference-geometry-and-typography-correction) adds four `assets/fonts/combat/` variations and `Ui.combat_label`, `Ui.style_combat_label`, `Ui.combat_icon` and `Ui.combat_icon_texture`. Cropped AtlasTexture symbols preserve the original SVGs while giving callers an extent based on visible ink. Audits unwrap the atlas and count its complete backing texture once. The existing theme and noncompact factories are unchanged.

Compact Combat cards now use a 149×146 footprint, a 34×38 cost crystal, 44px visible rune glyph, fitted 19–16px title, 13px type and 14–16px body copy. The title lane is y=58–81, dividers y=83/100 and description viewport y=102 through height−4. All three opening names/descriptions fit without scrolling. The 44×44 Info target and longer-description scrolling remain available. The four generated card color roles and other painted PNGs are retained unchanged. The older dimensions below describe previous corrections.

## October 14, 2026 — RC-016 image-generated painted UI rework (historical)

**Current technical status: 18 generated painted surfaces are integrated; import, gameplay, rendering and layout regressions pass. Exact reference identity and owner visual acceptance remain unverified.**

The built-in GPT Image tool created the painted 2D surfaces. All 18 selected PNGs remain byte-identical to their tool outputs at `assets/ui/combat/generated/`; Godot samples normalized painted regions and applies import size limits. No local script repainted or regenerated those pixels. Godot still handles live text, icons, circuit connections, values, input and responsive layout. The tool does not expose its model/version, so a specific GPT Image release is not asserted. The Combat consumer continues to use the shared theme, fonts, icons and component API. The 18 generated raster roles replace procedural borders, material faces, ribbons, parchment and deck stacks. The standalone [surface sheet (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup) uses the same renderer as the game. [Prompts](../source-assets/ui/combat/generated/prompts.json), [per-file provenance and hashes](../source-assets/ui/combat/provenance.json), [source notes](../source-assets/ui/combat/README.md) and the [normal 450×1000 desktop capture (retired)](asset-cleanup.md#october-16-2026--unused-resource-cleanup) record the implemented approach.

Fresh checks pass **1,453 core, 594 UI, 737 art integration, 157 focused geometry/content and 119 touch/branch checks**, all with zero failures. See [verification](verification.md#october-14-2026--rc-016-image-generated-painted-ui-rework) for exact evidence. Normal layout dimensions, controller ownership and independent input/inspection regions remain unchanged. Native narrow views use an 82-pixel forecast with a separate 32-pixel Incoming lane and 28-pixel icons to prevent overlap; normal 720-wide views retain 62 pixels. Original RC-013 noncompact components and source masters remain dependencies of the separate gallery and shared-screen library. The [cleanup ledger](asset-cleanup.md#october-14-2026--image-generated-combat-rework-cleanup) records retired copies/previews. The October 13 geometry implementation below is historical.

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

Card dictionaries support `name`, `cost`, `icon`, `kind`, `type`, `description`, optional `value`, `temporary`, `upgraded`, `compact` and `compact_height`. RC-016's optional `compact=true` uses height ≥168px and width ≥150px; actual Combat requests 164×168. At that width the existing transparent-padded symbol occupies a 72px extent, with a 48px cost badge/24px text, outlined title fitted from 21px down to 16px in y=54–85, 13px type in y=87–105, dividers at y=86/106 and a 52px description viewport with 14px text. Standard Conjure Spark uses a 20px title; the other opening names use 21px. The description retains scrolling with a hidden scrollbar, avoiding the conditional scrollbar's extra wrapping. [Actual Godot measurements](../output/qa/rc-016/reference-match/card-size-probe.log) show complete standard descriptions, including Conjure Spark's two lines, within the viewport. Actual Combat overlays a quiet `i` inside its unchanged 44×44px Info target in the upper corner. Compact cards use `CombatSurface` with `card_damage`, `card_shield`, `card_technique` or `card_mixed`, retaining the hidden original `rc_skin` metadata for existing callers. The default noncompact factory remains width ≥190, 52px symbol, 16px inset, 76px description and content-derived height ≥312px. Existing default preview consumers are unchanged. Cast dictionaries support `valid`, `affordable`, `cost`, optional `reason` and `states`. Constructors display copied input values; they are not subscriptions to a mutable combat dictionary. Refresh the corresponding control from a new detached snapshot, update the owning native Control property, or rebuild the relevant display when data changes. Keep callbacks on the owning screen/controller.

Actual Combat uses `stock_tool()`'s separate title/icon/count layout; main stores the count Label as `stock_label` metadata and refreshes its available/owned text from each snapshot. Pass, Straight, Corner, Split, Join, Remove and Rotate share an inset toolbar. Combat piles use `ReferencePile` to preserve each approved body and emblem at uniform scale, with separate upright live counts and captions. The consumer centers Damage/Shield/Cost in three columns within a 54 px forecast strip (64 px in the narrow fallback), with no Incoming row or hover tooltip. The forecast is display-only, with no input, focus or details action; Pass opens its consequence confirmation. These caller bindings do not change the shared preview defaults. Decorative Controls ignore input; actionable controls supply their own hit regions. Production uses static lit faces and rounded circuit glow while retaining selection and keyboard-focus cues.

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

Cream type has a dark outline; secondary copy uses a warm muted role without sacrificing available/unavailable explanations. Costs and stock remain separate slots, not part of frame artwork. Long names wrap, descriptions scroll, and hands can scroll horizontally. Keep effect text visible at a useful size; normal Combat omits the category line, while the shared noncompact preview may retain it. Do not hide effect text behind an ellipsis or shrink a complete720-wide screen to claim native360 readability.

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

Normal and pressed treatments preserve the same painted construction. Selection has a persistent shape cue; focus has its own high-contrast outline and remains visible with selection or unavailability. Invalid uses a cross/broken-path cue plus live explanation. Unavailable combines muted material with the existing live reason or status; disabled/unavailable symbols, including barred-circle badges, are prohibited on every screen and shared UI component. Stock counters show `remaining / owned`, including exhausted zero. In the isolated RC-013 delivery, `unavailable` and `disabled` both disable the native Button and suppress its ordinary pressed callback; put the reason in visible sibling text. Disabled Buttons are not ordinary tab targets. The combined focused/unavailable gallery state deliberately forces the visual focus overlay; it does not establish a keyboard or touch inspection flow. Production RC-016A keeps exhausted connector tools inspectable, adds a separate focusable Info button to each hand card, and uses hold/I/right-click inspection. RC-042 must apply the appropriate inspectable affordances when integrating other screens.

Decorative textures, text, symbols and state layers must ignore pointer input. For an action, its underlying rectangular Control owns the full touch region, including transparent pointed tips. Visual alpha must not define or reduce that action's hit area. Display-only controls such as the forecast have no input target or activation callback. Consumer callbacks must be connected to the owning actionable control; state renderers do not apply gameplay commands, consume stock, validate a circuit, save a run or navigate a shop.

The board remains a separate clean surface: only live **BEGIN** and **END** text, with no other names, values, cost, TEMP or upgrade badge. Frames leave the four exact RC-012 edge channels unobstructed. Draw connection strokes on their own live geometry layer with blunt ends and no directional arrows; use shape collars for powered state. Do not infer Split/Join logical ports from their fork/trident decorative endpoints. Temporary and upgrade marks belong in card/detail contexts only.

## Responsive composition and dialogs

The720×1600 and450×1000 specimens test the shared design construction at two desktop scales. Native360×640 specimens reflow into a scrollable page with a separate scrolling hand. These are presentation samples, not a fixed replacement for the game's layout. Maintain at least the documented component minimums when choosing container widths, and put overflow in the relevant scroll area instead of scaling fonts to unreadability.

Dialogs separate a scrolling body from a fixed footer so Close and confirmation remain reachable. The dimming surface is a resource, not a full-screen raster. Modal owners must establish focus, prevent activation of the covered screen, and restore focus when closing during integration. Production uses Info/hold/I/right-click inspection on cards, pieces and tools; the forecast is display-only. The visible Pass turn control occupies the WIRING-label position beside the four connector tools and opens a confirmation of the live unshielded attack and cleanup. It remains available with an incomplete circuit or empty hand; Escape or Cancel dismisses the confirmation.

Home specimens cover no save, available save, invalid-save feedback and replacement confirmation. Following the owner's October 12 clarification, Menu uses turquoise Resume with navy Options, **Store** and Quit. Store is a separate destination for buying in-game items such as runes, perks and relics; it is not gated on being in a shop room. Entering a shop room opens that room as the main screen. The generic unavailable Store specimen demonstrates a visual state only, with no decided eligibility, connectivity or payment rule. Shared Options uses the same controls for volumes, mute/Sound states and reduced motion. Map specimens use neutral existing symbols on a parchment-compatible surface with current/available/completed/locked cues; this does not deliver RC-041's full map library or route behavior.

## Sample data and integration handoff

The presentation gallery uses finite values from the current content files. The starter loadout owns eight cards and begins with three drawn, HP30/30 and energy3; an untouched opening can therefore show Draw5 and Discard0. Shadeling has32 HP and the first intent is8. Spark adds6 damage at cost2, Shield adds5 shield at cost1, Focus draws2 at cost1, and Conjure Spark creates one Free Spark at cost0. Free Spark shares Spark's board symbol, adds6 damage at cost0 and has temporary lifetime text only in cards/details. A preview of an upgraded marker does not introduce new gameplay upgrade values.

The actual finite kits in `data/production_rules.json` are Straight/Corner/Split/Join totals6/2/1/1,4/4/1/1, or4/2/2/2. Example availability can be lower as pieces are installed; it cannot exceed owned stock. The approved reference's infinity, BOSS label, fixed board and example totals do not change this model. Display specimens can supply independent valid/invalid/unaffordable presentations without computing a competing forecast.

RC-016A binds detached production snapshots to undirected cell geometry, live detailed cards, pile/stock counts, health/energy, action log and forecast values. RC-016 adds the production root Theme, painted arena/board/panels/piles/buttons and responsive composition around those accepted bindings. The display-only Damage/Shield/Cost strip scrolls with the page above Cast; it is not fixed to the viewport and opens no details window. Remove and Rotate remain the only editing actions, with Pass turn beside the wiring tools and the bottom navigation retained. The top Pause control is removed. Cast validity and affordability come from the controller forecast. The [RC-016 guide](rc-016-integration.md) separates this actual-game integration from source rights and physical-device acceptance. RC-042 should reuse the Theme and modal/card/button components across Home, Map, Menu, Options and later progression screens, supplying their own data and callbacks.

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

The RC-013 verification used the Windows NVIDIA GeForce RTX5070Ti GPU. Its logs report host `user://`/shader-cache and root-certificate-store diagnostics; source/import/script/layout checks have no failures. These diagnostics are recorded, not hidden or presented as a gameplay regression. The specimens use neutral component backgrounds; none claims a rebuilt complete Combat screen. RC-014 was the next numbered production task at that handoff; current task status is maintained in the [project plan](project-plan.md).

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
