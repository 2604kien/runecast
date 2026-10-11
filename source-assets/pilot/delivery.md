# RC-011 — current pilot assets

October 11, 2026. The corrected **r006 clean-board pilot** is the current editable review set. It uses a single check for Begin and a diamond for End, only BEGIN/END text inside the board, the approved fork/trident silhouettes and full supporting UI. The supplied final reference is owner-approved; the reconstructed pilot remains `reference_guided`, with source and visual review distinct from owner approval or runtime/device acceptance.

## Current review and editable sources

| Asset | Current files |
| --- | --- |
| Pilot delivery | [r006 delivery and methods](revisions/r006/delivery.md), [independent visual review](revisions/r006/cross-screen-review.md) |
| Main composition | [720×1600 preview](../../output/art/rc-011/r006/pilot-720x1600.png), [full 841×1870](../../output/art/rc-011/r006/pilot-841x1870.png), [editable SVG](revisions/r006/pilot_review.svg), [builder](revisions/r006/build_review.py) |
| Layout and states | [Native board](../../output/art/rc-011/r006/pilot-360x640.png), [controls companion](../../output/art/rc-011/r006/pilot-360x640-controls.png), [state sheet](../../output/art/rc-011/r006/pilot-states.png), [tile states](../../output/art/rc-011/r006/pilot-tile-states.png), [type specimen](../../output/art/rc-011/r006/pilot-type.png) |
| Shadeling | [Selected r002 master](revisions/r002/shadeling.ora), [neutral export](revisions/r002/exports/shadeling.png), [aligned parts](revisions/r002/exports/shadeling_parts/), [metadata](revisions/r002/metadata.json) |
| Crypt | [Selected r004 master](revisions/r004/crypt/crypt.ora), [semantic layers](revisions/r004/crypt/layers/), [metadata](revisions/r004/crypt/metadata.json), [current merged plate](revisions/r006/exports/crypt-background.png) |
| Reusable UI | [Tile master](revisions/r006/ui/painted_tile.ora), [primary button](revisions/r006/ui/cast-button.ora), [secondary panel](revisions/r006/ui/navy-panel.ora), [Spark](revisions/r006/ui/spark.svg), [Split](revisions/r006/ui/split.svg), [Join](revisions/r006/ui/join.svg), [reuse dependencies](revisions/r006/ui/reuse-dependencies.json) |
| Selected font | [Noto Serif binary](revisions/r002/type-geometry/fonts/NotoSerif-Variable.ttf), [OFL licence](revisions/r002/type-geometry/fonts/OFL.NotoSerif.txt), [provenance](revisions/r002/type-geometry/font-provenance.json) |
| Motion evidence | [Selected r002 GIF](../../output/art/rc-011/r002/pilot-motion.gif), [keyframes](../../output/art/rc-011/r002/pilot-motion-sheet.png), [frame sequence](../../output/art/rc-011/r002/pilot-motion-frames/), [timing/reduced-motion record](../../output/art/rc-011/r002/pilot-motion-timing.json) |
| Current checks | [Artifact/source validation](../../output/art/rc-011/r006/revision-validation.json), [asset-plan validation](../../output/art/rc-011/r006/asset-plan-validation.json) |

## References and cleanup

The [current clean-board target](../../output/imagegen/approved/combat-final-v2-clean-board.png) remains alongside approved [Home](../../output/imagegen/approved/home.png), [Map](../../output/imagegen/approved/map.png), [Menu](../../output/imagegen/approved/menu.png), [Combat](../../output/imagegen/approved/combat.png) and [complete Combat](../../output/imagegen/approved/combat-final.png). Earlier approved Combat images retain the original reference provenance of selected artwork; the latest target is not retroactively claimed as an old generation input. Selected r002 character/font/motion sources and r004 crypt/raw-paint recipes remain dependencies of r006.

The owner authorized removal of unused and unapproved artwork/files. That request supersedes earlier preserve-all-history instructions for the enumerated cleanup. This current index replaces the obsolete r001 history index; its links to removed artwork are intentionally retired. [Cleanup scope and retention](../../docs/asset-cleanup.md) explains the retained set, and [the deletion ledger](../../output/art/rc-011/cleanup/deletion-manifest.json) records removed paths, hashes, reasons, sizes and metadata updates when the cleanup run writes it.

Runtime assets, scenes, scripts, tests, required helpers, output QA and small historical audit/approval JSON records are retained as project dependencies or evidence. No Git operations are part of the cleanup. Keeping current pilot sources does not make them production-integrated or implicitly owner-approved.
