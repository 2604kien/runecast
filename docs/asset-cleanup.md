# Asset cleanup — retained current set

## October 13, 2026 — Project-wide follow-up cleanup

The owner explicitly requested deletion of unnecessary assets across the **whole RuneCast project**, with no Git operations. This later authorization supersedes preserve-every-preview requirements only for the exact files in the [project-wide deletion manifest](../output/qa/asset-cleanup-2026-10-13/deletion-manifest.json). The October 11 cleanup below remains a separate historical record.

**Completed: 2,685 files removed, freeing150,959,491 bytes (143.97 MiB).** [Post-cleanup validation](../output/qa/asset-cleanup-2026-10-13/validation.json) and [manifest/reference validation](../output/qa/asset-cleanup-2026-10-13/asset-plan-validation.json) record actual results. All403 guarded current runtime/gameplay/reference/preview files remain byte-identical. The retained UI evidence audit passed1,813 checks and the Shadeling source/evidence audit passed359 before disposable staging was removed; their prior engine measurements were not rerun or relabelled as new.

The audit identified 227 superseded/duplicate preview images and GIFs, 20 regenerable source PNG intermediates, nine generated preview-project trees, disposable child caches/staged character copies and one Python bytecode cache. The manifest records each path, byte size, SHA-256, reason and replacement where one exists. No rejected-art backup is retained. Old compact QA reports and preservation snapshots keep their original dates and bytes; a listed retirement explains why their historical paths are no longer present. Byte-identical previews link to the retained copy; differing retired previews link to this record rather than being presented as current evidence.

Retained current entry points:

- [Corrected Shadeling pack and 360 framing](../source-assets/characters/shadeling/delivery.md#360-wide-framing-correction), with its complete102-image/frame/GIF set under [framing-360](../output/art/rc-014/framing-360/).
- [Current Store menu](../output/art/rc-013/menu-button-revert/), plus the30 other RC-013 screen/component captures and current RC-012 symbol/type previews. Current Menu evidence replaces the superseded Shop/padding/shared-frame review copies.
- All runtime assets, editable ORA/SVG masters, canonical layers/masks, selected generation images/prompts/records, fonts/licences and all six approved references. Retained r002/r004/r006 inputs and r002 motion frames remain real production/validation dependencies.
- Gameplay scripts/scenes/data/tests, project/export settings, root `.godot`, pinned tools/SDKs and the unique font-probe sources. Only isolated generated QA staging and caches are removed.

Seven small r006 renderer intermediates remain because both current RC-012/RC-013 preservation validators require their exact bytes. Their external SVG references resolve against the r006 root, as specified by the retained render helper, not against the intermediate `ui/render` directory. They are documented dependencies rather than orphan artwork.

### Recreate isolated validation stages

Staged projects are generated working copies, not source masters. Recreate them before running focused validators or opening a staged gallery:

```powershell
.\tools\preview_core_assets.ps1
.\tools\preview_ui_theme.ps1 -EvidenceName menu-button-revert -MenuOnly
.\tools\preview_shadeling.ps1
```

The Shadeling wrapper and validator now default to `output/{qa,art}/rc-014/framing-360`, so reruns use the corrected canonical preview set. The UI validator uses retained non-menu results and current menu-button-revert results, with strict staged identity checks; it does not claim that old layout measurements were newly executed. Pass a separate `--report` path when recording a later audit. Source builders may recreate their raster intermediates when explicitly run.

October 11, 2026. The owner authorized removal of unused and unapproved artwork/files while keeping the corrected current pilot, approved reference images and runtime dependencies. This instruction supersedes earlier preserve-all-history instructions **for the files enumerated by this cleanup**. It does not authorize deleting runtime work or unrelated project evidence. No Git operations are part of this cleanup.

## Current assets retained

| Retained group | Purpose and current entry point |
| --- | --- |
| Corrected r006 pilot | [Current delivery](../source-assets/pilot/revisions/r006/delivery.md), [editable composition](../source-assets/pilot/revisions/r006/pilot_review.svg), [current preview](../output/art/rc-011/r006/pilot-720x1600.png), source/build recipes, reusable materials, states/type/narrow previews and current validation records. Begin uses one check; End uses the diamond. |
| Selected r002 actor and font | [Shadeling master](../source-assets/pilot/revisions/r002/shadeling.ora), aligned parts, selected generation and provenance, [font provenance](../source-assets/pilot/revisions/r002/type-geometry/font-provenance.json), actual Noto Serif font and its licence. |
| Selected r002 motion/alpha evidence | [Motion GIF](../output/art/rc-011/r002/pilot-motion.gif), frame sequence, timing/reduced-motion record, keyframe sheet, actor alpha/layer/scale sheets and relevant source validation. These support the actor reused by r006. |
| Selected r004 crypt and painted inputs | [Crypt master](../source-assets/pilot/revisions/r004/crypt/crypt.ora), semantic layers and metadata, selected raw crypt/tile/button paintings and prompts, [generation record](../source-assets/pilot/revisions/r004/raw/generation-record.json), and required material/crypt build recipes. |
| Runtime and project evidence | Runtime assets, scenes, scripts, tests, dependency helpers and `output/qa/` are retained. Small historical audit and approval JSON files remain project evidence; they are not alternative artwork. |

The retained dependency set includes shared helpers such as [the material builder](../source-assets/pilot/button/build_materials.py). Folder age alone is not a deletion criterion: r002/r004 inputs still support the current pilot.

## Approved reference images retained

All six canonical approved images remain in [the approved reference directory](../output/imagegen/approved/):

| Image | Retained role |
| --- | --- |
| [Home](../output/imagegen/approved/home.png) | Approved Home reference. |
| [Map](../output/imagegen/approved/map.png) | Approved Map reference. |
| [Menu](../output/imagegen/approved/menu.png) | Approved Menu reference. |
| [Combat](../output/imagegen/approved/combat.png) | Earlier approved Combat reference and provenance for selected artwork. |
| [Complete Combat](../output/imagegen/approved/combat-final.png) | Earlier complete approved target and original reference for selected painted assets. |
| [Clean-board Combat v2](../output/imagegen/approved/combat-final-v2-clean-board.png) | Current approved final gameplay target. |

Retaining earlier approved references preserves the actual input history of selected artwork. The latest target is not substituted retroactively into older generation records.

## Removal record and metadata

**Completed: 603 obsolete files removed, totaling 114,739,357 bytes (109.42 MiB).** [The deletion manifest](../output/art/rc-011/cleanup/deletion-manifest.json) records every removed path, pre-deletion hash, reason and byte size, plus six retained source/document updates. No rejected-art backup was kept.

[Final cleanup validation](../output/art/rc-011/cleanup/validation.json) passes. The current pilot rebuild succeeds; all 24 guarded artwork/reference files remain byte-identical, no deleted paths reappear, and 33 retained Markdown documents have no broken local links. The source audit passes 1,170 checks and the asset-plan audit passes 2,799 checks. Of the 974 original baseline files, 954 remain unchanged and 20 historical study/prompt files were explicitly retired. The 404-file prior-art snapshot partitions into 130 unchanged, 268 removed and 6 documented source/document updates, with no unexpected changes. Original baseline bytes and raw runtime QA remain unchanged.

The removal scope covers enumerated rejected/superseded preview artwork, unused alternatives, duplicate review copies, obsolete composition caches and the pre-correction Begin-overlap archive. Current indexes, source mappings and generation metadata are reconciled with the retained files. Historical records may still describe an earlier audit state; the cleanup ledger explains intentional removals instead of treating those old preservation snapshots as current requirements.

The [concise pilot index](../source-assets/pilot/delivery.md) replaces the former r001 history index. The retained r006 pilot remains `reference_guided`; approval of a supplied reference does not implicitly approve reconstructed assets or establish Godot/device readiness.
