# Asset cleanup — retained current set

## October 16, 2026 — Unused resource cleanup

**Completed: 2,221 files removed, freeing 1,370,344,711 bytes (1.28 GiB).** The owner requested: “Please remove all unused resources.” The [exact deletion manifest](../output/qa/resource-cleanup-2026-10-16/deletion-manifest.json) records every path, size, hash and reason. Runtime, source and output dependency audits are saved beside it.

Removed nine unused runtime exports (the duplicate pile frame and eight unused state SVGs), their 27 import/cache files, 12 orphan import-cache files, the superseded generated neutral character, and 2,172 obsolete QA files (2,141 screenshots, 30 one-off helpers and one comparison page). StateLayer already draws the non-node cues, and piles already use panel.png. Updated the generator and export map to prevent the unused exports returning. The approved atlas supplies the current neutral character.

Current artwork, all six approved references, editable masters, selected generation inputs, licences, gameplay resources, dynamic preview consumers and required regression images remain. Historical JSON/log evidence is retained; 156 links to retired images now lead to this record. This cleanup supersedes earlier instructions to preserve the unused generated neutral as an archive.

Every target was resolved inside the workspace, checked for reparse points, and matched against its recorded size/hash before native PowerShell removed the individually named file. No recursive deletion or Git operation was used. [Verification](verification.md#october-16-2026--unused-resource-cleanup) records the post-cleanup checks.

## October 16, 2026 — Generated status frame replacement

One selected image-generated PNG, `assets/ui/combat/reference/status-frame.png`, is now consumed by the production stats surface. The rejected border existed only as local drawing code; its bezel and divider helpers have been removed. No unused generated bitmap variant was added, and no existing asset became unreferenced by this change. Historical screenshots and source provenance remain evidence. [Generation record](../source-assets/ui/combat/reference/status-frame/provenance.json) and [resource audit](../output/qa/rc-016/stats-generated-frame/resource-audit.json).

## October 15, 2026 — Approved reference surface cleanup

**Completed: 72 files removed, freeing 24,856,901 bytes (23.71 MiB).** The owner had explicitly requested unused-asset removal after rework. All eighteen old generated surface roles now use the approved-reference atlas; a content search across runtime scripts, scenes, resources, shaders and data found no consumer of `assets/ui/combat/generated/` before retirement. The [deletion manifest](../output/qa/rc-016/reference-art/deletion-manifest.json) records each exact path, byte size, SHA-256 and replacement.

Removed only the eighteen obsolete PNGs, their eighteen `.import` recipes and the thirty-six matching regenerable `.godot/imported` texture/hash files. Every original PNG hash matched historical provenance, resolved targets remained inside the workspace and intended directories, and each hash was checked again immediately before native PowerShell `Remove-Item -LiteralPath`. No recursive or cross-shell deletion was used; post-deletion checks confirmed all enumerated paths absent. Root `.godot` remains, apart from these exact obsolete cache entries.

The [historical provenance](../source-assets/ui/combat/provenance.json) explicitly marks every old runtime/source path retired; [old prompts](../source-assets/ui/combat/generated/prompts.json) and earlier QA evidence remain. Original canonical RC-012–015 packs, editable ORA/SVG masters, shared fonts, approved references, retained actor poses and their source/provenance records were not deleted. The [new source record](../source-assets/ui/combat/reference/README.md) lists the four active image inputs. No Git operations were used. Current runtime checks belong to [the verification entry](verification.md#october-15-2026--approved-reference-artwork-adoption), not the historical counts below.

## October 14, 2026 — Image-generated Combat rework cleanup

**Completed: 1,264 files removed, freeing 565,617,093 bytes (539.41 MiB).** The owner explicitly requested unused-asset deletion after the generated-art rework. The [deletion manifest](../output/qa/rc-016/image-rework/deletion-manifest.json) records every exact path, pre-deletion hash, size, reason and replacement. No Git operation was used.

The cleanup retires superseded RC-016 screenshots, the six unused procedural material copies and their import recipes, and the disposable RC-015 preview stage. All selected generated PNGs remain intact; they serve as their own original source files. The original r002/r004/r006 masters, source inputs/build recipes, shared RC-013 resources, approved references, raw playtest evidence and compact historical reports remain dependencies and are retained.

Old image links now point here. Their historical JSON/log counts and hashes remain unchanged and do not describe current artwork. Replacement evidence is in [image-rework](../output/qa/rc-016/image-rework/). The post-cleanup [resource audit](../output/qa/rc-016/image-rework/resource-audit.json) passes **1,343 checks**, with all **532 protected hashes** unchanged. Its conservative decoded full-pack estimate including the future 2 MiB VFX allowance is **31.83918 MiB** against the provisional 32 MiB subtotal.

The cleanup script verified project containment, no reparse-point traversal, exact file sizes/hashes and absent live consumers before removing explicitly enumerated files with PowerShell. Root `.godot`, `.tools`, engine/SDK files and Git data were excluded. Recreate the removed isolated environment preview stage with `.\tools\preview_environments.ps1` before a full environment validator run; `--source-only` intentionally excludes its Godot evidence checks.

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


## October 17, 2026 — RC-018 source and preview retention

RC-018 adds 21 indexed runtime WAVs under `assets/audio/sfx/` and matching 24-bit masters plus editable recipes/provenance under `source-assets/audio/sfx/`. The shared enemy float stem is a source dependency, not a 22nd runtime cue. Listening reels, comparisons, real-event sequences and internal Godot mixer capture remain under `output/audio/rc-018/`; focused reports are under `output/qa/rc-018/`. Existing export exclusions keep sources, tools, docs and previews outside shipped assets. All 164 protected existing production files remain unchanged; no earlier audio existed to retire. [Delivery and evidence](rc-018-verification.md).

The owner subsequently rejected r001's sound direction as too snare-like. Retain it for comparison and historical technical evidence while five r002 Runway candidates are auditioned. Original MP3s and generation/provenance records are under `source-assets/audio/sfx/revisions/r002-runway-audition/`; the comparison player is under `output/audio/rc-018/r002/`. These are source-only candidates, not extra runtime cues or accepted replacements. No r001 source, runtime or QA evidence was deleted.

The owner approved the r002 direction and requested a full Runway rebuild. The r003 revision replaces the same 21 runtime destinations and matching working masters; all 21 original MP3s, generation records and decoded/editable processing inputs are retained under `source-assets/audio/sfx/revisions/r003-runway-library/`. The 21 rejected r001 runtimes and 21 masters plus metadata are archived under `revisions/r001-procedural/`, and prior QA is under `output/qa/rc-018/r001/`. The r002 comparison now points to frozen r001 WAVs, preserving its meaning. Current previews and verification are refreshed for r003; no historical numerical baseline was rewritten to force a pass. Existing export exclusions keep all source, history and audition files outside shipped assets.

## October 17, 2026 — RC-019 ambience retention and deferred music

Retain the single crypt runtime under `assets/audio/ambience/`, its original Runway MP3, generation/provenance records, 24-bit working master and editable processing under `source-assets/audio/`, and the [audition page](../output/audio/rc-019/index.html). The six-cycle decoded-runtime WAV contains five internal joins for listening; it is a source-only review export, not another runtime bed. The shorter boundary excerpt, focused reports, Godot internal capture and independent reproduction under `output/qa/rc-019/` document this delivery. Existing export exclusions keep those source, review and QA files outside the shipped game.

The owner left both music tracks pending after Runway required a paid plan. Retain the prepared requests and [deferral record](../source-assets/audio/music/delivery.md); no missing music path should be treated as a deliverable or an orphan to remove. RC-019 remains incomplete, and production integration belongs to RC-020. No SFX, previous preview or production file was retired by this task. [Current evidence](rc-019-verification.md).


## October 18, 2026 — RC-020 Cast placeholder retired

Removed the code-generated 8-bit 440 Hz Cast tone, its dedicated production player and the old Cast playback call. Current accepted Cast uses the single coordinator and existing r003 `sfx_cast` WAV once. No authored audio file was deleted or replaced. All 21 delivered SFX and the crypt Ogg keep their existing paths; future-only SFX stay unbound, and deferred music paths remain unavailable.

The shipped GDScript catalogue is metadata owned by runtime code; sources/docs/tests/review captures remain excluded from exports. Retain the compact initial headroom-failure report and final measured playback evidence under `output/qa/rc-020/`, plus the WAV, timed-frame review and optional AVI. A transient 8 ms release envelope is computed from an active cue in memory and is not a new asset. [Current verification](rc-020-verification.md).
