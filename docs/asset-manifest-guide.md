# Asset manifest, reuse and evidence

RC-010, October 9, 2026. [asset-inventory.csv](asset-inventory.csv) is the authoritative inventory; [asset-consumers.csv](asset-consumers.csv) maps reusable assets to screens and stable content IDs. Read both with the [production contracts](asset-production-spec.md), [pilot brief](style-pilot-brief.md) and [bounded roster](content-roster.md). This delivery plans assets; it supplies no final artwork, audio, licensed font acquisition or runtime integration.

## Reading and maintaining the CSV

UTF-8, comma-separated, one header, quoted fields, with semicolons separating finite lists inside fields. Asset IDs use stable lowercase snake_case. All 16 original IDs remain. An inventory row is either one asset or a **bounded delivery pack**, never a copy per consumer. Counts of records therefore differ from counts of files, glyphs or music tracks. For example, `music` delivers exactly two tracks, `room_symbols` delivers six glyphs, and `navigation_icons` delivers five glyphs.

| Field | Contract |
| --- | --- |
| `id`, `row_kind`, `category` | Unique stable identity; `deliverable`, `reference` or `audit`; category is for reporting, not readiness. |
| `description`, `consumer_ids`, `runtime_use` | Purpose and direct consumers. The companion mapping expands reuse and interaction states. `all_screens` means all thirteen `screen_*` mappings. Screen/mapping IDs are documentation identifiers, not claims that those scenes exist. |
| `source_master_path`, `source_path_state` | Editable source location, with `existing` or `planned`. A trailing slash is a bounded pack directory using the file rules below. `none` is reserved for no applicable destination. |
| `runtime_destination`, `runtime_path_state` | Intended export/resource destination. `planned` means it need not exist; `existing` points at current delivered evidence; `source_only` is a review artifact never shipped; `external_delivery` is a store/listing package; `not_applicable` applies to references. A planned final app-icon path happens to contain a prototype; that does not make the final asset delivered. |
| `format`, `spec_ref`, `required_states_variants` | File formats, exact local contract/anchor, and bounded variants. Shared overlays can implement several states without duplicate images. The contract and consumer table jointly specify screen conditions. |
| `production_owner`, `integration_owner` | RC task responsible for making the asset versus connecting it to the live product. Multiple integration owners denote initial/later stages. `none` is allowed only on nonruntime references. |
| `task_dependencies`, `asset_dependencies` | Semicolon lists of required RC tasks and upstream asset IDs. Task prerequisites apply transitively from the plan; an asset edge is production input, not a claim that integration is complete. Never make RC-042 wait for the later RC-051/RC-050 release audit. |
| `readiness_status`, `visual_direction_status` | Separate delivery maturity from reference approval. See below. |
| `provenance`, `generation_reference`, `licence_status` | Known creator/source, actual prompt/model or explicit unknown, and rights evidence status. Planned material is not licensed merely because it is on this list. |
| `evidence_paths`, `current_paths`, `notes` | Existing evidence and implementation locations must exist. Planned exports belong only in planned path fields or explicitly labeled prose. Evidence of a placeholder is not acceptance of its planned replacement. |

`spec_ref` and all path fields are repository-root-relative; Markdown links in documents remain relative to their own document. Do not silently rename an ID when its display name, revision, source application or destination changes. Update the row and delivery notes, preserve the old source, and reconcile consumers.

### Readiness and approval vocabulary

| Status | Meaning and evidence required |
| --- | --- |
| `reference_only` | Existing visual direction/history; never a production export. Approval lives in `visual_direction_status`, not in licensing or integration. |
| `integrated_placeholder` | Existing code/prototype used by the runtime. It is not final production readiness. |
| `placeholder` | The required production asset has only a current code/text stand-in; planned source/runtime paths are not delivered. |
| `planned` | Required bounded delivery has not been produced. |
| `optional_planned` | Only the crypt edge foreground is optional; omission is recorded, not a missing required asset. |
| `source_ready` | Later task has supplied editable source, traceable provenance and preview evidence; import/integration may still be outstanding. |
| `runtime_ready` | Later task has exported and tested imports against dimensions/alpha/state contracts, with linked evidence and resolved usage rights. |
| `integrated` | The asset is bound to actual state/events and appears in actual-scene captures or listening evidence. This does not establish physical-device acceptance. |
| `device_verified` | Identified build/device/OS observations cover the asset's relevant states and import/render/audio behavior. Preserve the separate desktop result. |

Current visual-direction values are `approved_reference`, `historical_reference`, `reference_guided`, `placeholder`, and `not_applicable`. `reference_guided` **does not mean the new asset is approved**. Record future asset-review outcomes in delivery notes before changing its approval description. Current licence fields are only `unresolved` or `unverified_reference_only`; there is no rights-cleared production delivery in this audit. Later `resolved` requires a linked licence/permission/creator declaration and attribution terms, reviewed at RC-050.

## Existing asset audit

- **Actual standalone runtime art:** [app_icon.svg](../assets/ui/app_icon.svg), its [import settings](../assets/ui/app_icon.svg.import) and the binding in [project.godot](../project.godot). It is a prototype, not a released icon. No authored character/environment/font/audio files were found under `assets/`.
- **Code and text stand-ins:** [arena.gd](../scripts/ui/arena.gd) combines pillars, candles, floor, shadow, polygon Shadeling, name/intent and health drawing. [board_cell.gd](../scripts/ui/board_cell.gd) draws sockets/paths/arrows/labels/values and selection/placement feedback. [main.gd](../scripts/ui/main.gd) creates flat styles, live buttons, hand cards, dialogs and the inspector; [runes.json](../data/runes.json) contains text symbols. Font rendering currently uses the engine default; no separately acquired font has a project licence record.
- **Placeholder audio:** `main.gd` synthesizes a 2,205-sample, 22,050 Hz, 8-bit mono, 440 Hz decaying tone (0.1 s), with player gain -12 dB. There is no audio master, music or ambience file. This code is evidence of a placeholder, not of normalized or licensed final audio.
- **Reusable foundations to retain:** exact port computation in [circuit.gd](../scripts/core/circuit.gd), state/control bindings, the RC-008 gesture/inspection model, dynamic labels/counts, detached presentation events and validated content IDs. Production skins these foundations; it does not replace them with a flattened screenshot.
- **Missing production:** all five final character packs, layered crypt/Home, authored UI/fonts/symbols/map/progression art, event-driven animation/VFX, sound library/two loops/ambience and release identities. Existing development fixtures and historical blocked/corner-effect experiments do not add release assets.

### References and generation history

The four exact approved files are [Home](../output/imagegen/approved/home.png), [Combat](../output/imagegen/approved/combat.png), [Map](../output/imagegen/approved/map.png) and [Menu](../output/imagegen/approved/menu.png). The recorded approval on October 8 covers visual direction only. Each differs by SHA-256 from its latest historical generated study; do not infer its exact originating prompt/model or claim that it is a layered master. The [validation report](../output/qa/rc-010/validation-report.json) records that comparison.

Ten historical pairs remain in `output/imagegen/`, each with the identical stem plus `.png` and `.prompt.txt`:

| Family | Exact stems |
| --- | --- |
| Combat studies | `rune-cast-gameplay-reference-v1`; `rune-cast-gameplay-reference-v2-cartoon`; `rune-cast-gameplay-reference-v3-arena`; `rune-cast-gameplay-reference-v4-centered`; `rune-cast-gameplay-reference-v5-navigation` |
| Home | `rune-cast-home-reference-v1` |
| Map | `rune-cast-map-reference-v1`; `rune-cast-map-reference-v2-no-legend` |
| Menu | `rune-cast-menu-reference-v1`; `rune-cast-menu-reference-v2-blue-quit` |

Prompt text is available for those studies; model/version metadata and production-use rights are not established. Some prompts describe external staging/structure references. Retain that provenance context and review it at RC-050; never transfer an assumed licence from a reference to new art. Preserve all approved files and historical pairs unmodified.

### Visual inspection evidence

RC-010 visually inspected all four approved PNGs and existing [450×1000 normal production](../output/qa/rc-009/final-production.png), [720×1600 Belfry construction](../output/qa/rc-009/board-capture-1791523199-18876/board_belfry-built.png), [unavailable stock](../output/qa/rc-008/touch-capture-1791519954-3060/unavailable-stock.png), and [360×640 inspector](../output/qa/rc-008/touch-capture-1791519954-3060/small-portrait-inspector.png). The pilot brief records additional inspected captures. The current screen needs more live editing/inspection controls than the old flattened Combat drawing. Finite counts, `+`/`x` feedback, independently scrolling details, fixed Close, upright text and exact ports must survive decoration. These are observations of existing desktop captures, not newly executed gameplay or device tests.

## Pack boundaries and reuse

Directory destinations denote these bounded files, not open-ended art requests. Runtime leaf filenames use the lower-case state/variant names from the manifest; delivery notes list the exact files adopted. Each family uses the dimensions and imports in the production specification.

| Pack | Bounded members and sharing |
| --- | --- |
| `circuit_geometry` | `begin.svg`, `end.svg`, `straight.svg`, `corner.svg`, `split.svg`, `join.svg`; exact live paths/arrows use the current geometry contract. No per-rotation images. |
| `rune_symbols` | `spark.svg`, `shield.svg`, `focus.svg`, `conjure.svg`; `free_spark` reuses Spark plus `temporary_marker.svg`. Eight remaining permanent definitions have their own manifest glyph rows. |
| `navigation_icons` | `menu.svg`, `map.svg`, `guide.svg`, `sound_on.svg`, `sound_off.svg`; share live label/state treatment. |
| `editing_icons`, `resource_icons` | Eight named editing glyphs and three resource glyphs listed in their rows. The default attack glyph serves every scalar attack; the guardian gets one phase accent. |
| `room_symbols` | Six files named `room_normal.svg`, `room_elite.svg`, `room_guardian.svg`, `room_shop.svg`, `room_recovery.svg`, `room_event.svg`; rings/checks come from `ui_state_overlays`. |
| `progression_symbols` | `reward_chest.svg`, `remove_card.svg`, `heal.svg`, `victory_wreath.svg`, `defeat_seal.svg`, `abandon_exit.svg`. Event choices reuse these and existing room/resource/card/relic symbols. No seventh room type. |
| `ui_frames` | Panel, dialog, inspector and navigation-bar constructions; share corners/materials and state layers. `button_frames` has primary/secondary constructions, `rune_frames` has damage/shield/technique/mixed material variants, and `ui_bars` has health/energy/slider track and fill. `ui_state_overlays` shares focus/selection/invalid/unavailable/placement/node rings and badges. Exact file reuse is recorded by RC-013 rather than exporting every state combination as a duplicate image. |
| Characters | Five actors only. Each pack supplies same-canvas `neutral.png`, `attack.png`, `hit.png`, necessary separate parts and editable `character.tscn`. Idle/defeat use the shared lean animation method. Bell Keeper alone adds the scoped intensified-phase pose/overlay. |
| Environments | `crypt` is the background member of the original crypt requirement, with floor and optional foreground rows; one shared layered master. Three modulation presets cover base cool, warm candle/recovery and dark guardian. Home is a separate illustration. No environment per board/event/room. |
| Progression | Six relic glyphs; eight upgrades reuse base glyph plus one marker. `event_symbols` adds only `stone_bowl.svg` for Blood Tithe and `etched_desk.svg` for Etched Desk; Lost Satchel reuses the shop bag, Sealed Reliquary reuses the reward chest. Four events and six services use live choices and shared symbols. `progression_previews` demonstrates states rather than adding new runtime paintings. |
| Audio | Sixteen cue families, exactly two music loops and one ambience bed. Bounded cue variants/durations and event mappings are in the audio contract. Character accents are variants of `sfx_enemy_attack`, never another music track. |

Four board identities map to the same board/socket/geometry/environment assets. Proposed Gallery cool, Ossuary warm and Belfry dark treatments are shared modulation presets, not mechanical differences or separately painted boards. `dev_entry_board` and Calibration Wisp are preserved development fixtures, not additions to the five-actor release roster.

## Ownership and work handoff

RC-011 owns the matching pilot and review. RC-012 makes fonts/core glyphs; RC-013 makes theme/wordmark; RC-014 makes Shadeling; RC-015 makes crypt/Home. RC-016 performs first-encounter binding. RC-017 produces and connects initial motion; RC-018 makes SFX and RC-019 makes music/ambience; RC-020 implements their playback/settings. RC-037–RC-040 each own one remaining actor pack. RC-041 produces progression art; RC-042 performs complete screen/content integration. Behavior owners in the consumer table are not substitute art-production owners.

RC-051 produces/replaces distribution identity after RC-042; RC-050 then audits provenance and supplies credits, and RC-053/RC-054 verify release packaging. RC-056 uses actual release builds for store materials. Platform-specific size/export requirements remain assigned there. RC-021/RC-022 establish device minimums and first device observations; RC-023 accepts the polished encounter, RC-044 responsive/accessibility behavior, RC-047 lifecycle, RC-048 measured budgets, and RC-049 the supported-device matrix.

Parallel production chats edit their own asset directories and delivery note first. Supply a proposed manifest-row update in that note; the coordinating task applies updates serially to this CSV and shared theme/atlas/resources. RC-017 owns the shared animation library; later actor tasks reference it and edit their own packs. RC-013 owns shared theme files; RC-041 adds content assets without rewriting them concurrently. An RC task producing preview scenes is not authorized to silently bind all later screens.

Follow the [delivery checklist](asset-production-spec.md#delivery-acceptance) for editable masters, runtime exports, IDs, metadata, import settings, provenance/rights, prompts/refinements, isolated/contact/audio previews, actual-scale composition and known limitations. No reference crop, health/energy/card values/counts/button labels or circuit paths may be baked into background art.

## Validation and limits

Run the lightweight Python 3 [validator](../tools/validate_asset_plan.py) from the project root (use the bundled Python executable if `python` is unavailable):

```powershell
python .\tools\validate_asset_plan.py
```

It checks CSV shape/unique IDs, original-ID preservation, ownership and task/asset dependency cycles, scoped consumer coverage, referenced assets, concrete spec anchors, required screen/character state coverage, existing evidence/current/source paths, planned destination labeling, local documentation links and protected-file hashes. It records counts and approved/history hashes in `output/qa/rc-010/validation-report.json`. The roster and task plan supply coverage/ownership evidence; the validator is not a new asset-management system and does not judge artistic quality or clear rights.

RC-010 does not rerun Godot gameplay tests because runtime files are unchanged. Prior desktop evidence stays historical. Pilot validation, actual imports, licensing resolution, live integration, physical devices and measured performance remain with their owning tasks.
