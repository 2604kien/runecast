# Asset cleanup — retained current set

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
