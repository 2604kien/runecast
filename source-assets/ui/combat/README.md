# Combat artwork sources

The current implementation uses the [approved reference artwork](reference/README.md) for visible scenery, the separately masked neutral character and separable decoration. Three unchanged built-in image-generation outputs supply hidden arena fill, the icon sheet and the painted status frame. The superseded generated neutral was removed by the [October 16 unused-resource cleanup](../../../output/qa/resource-cleanup-2026-10-16/deletion-manifest.json); its prompt and hash remain historical provenance. See [current provenance](reference/provenance.json), [sampling regions](reference/regions.json), [integration](../../../docs/rc-016-integration.md) and [verification](../../../docs/verification.md).

## Historical October14 generated-surface revision

The owner previously requested GPT Image replacement surfaces after rejecting procedural painting. Eighteen original tool-output PNGs were integrated at that stage, with their exact prompts in [generated/prompts.json](generated/prompts.json). Layout-only passes initially preserved those images. The subsequent owner request to correct the remaining artwork replaced all eighteen surface roles with clean original-reference sampling.

The eighteen unused PNGs, import recipes and exact generated cache files were removed on October15 under the [path/hash manifest](../../../output/qa/rc-016/reference-art/deletion-manifest.json). [Historical provenance](provenance.json) preserves their hashes, dimensions, import limits and explicitly retired paths; those paths are not active runtime dependencies. No duplicate obsolete PNG source copies are retained.

The original [image-rework evidence](../../../output/qa/rc-016/image-rework/) remains historical. The shared [preview script](preview.gd) now exercises the current CombatSurface renderer, so rerunning it does not recreate the retired artwork. Canonical pilot/RC-012–015 sources, original approved references and their licences/provenance remain intact.
