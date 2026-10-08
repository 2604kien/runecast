# Validated content definitions

RC-004 adds a small loader for the current combat rules. Normal definitions describe existing scalar damage/shield runes, draw/conjure techniques, fixed-geometry boards, attack sequences and player setups. RC-005 adds narrowly gated experimental geometry described below. The future roster, relics, statuses, combined effects and guardian phases remain unimplemented.

## Files and entry points

| File | JSON root and purpose |
| --- | --- |
| [`data/runes.json`](../data/runes.json) | Array of rune and technique definitions. |
| [`data/boards.json`](../data/boards.json) | Array of starting-board definitions. |
| [`data/enemies.json`](../data/enemies.json) | Array of enemy definitions and scalar attack sequences. |
| [`data/loadouts.json`](../data/loadouts.json) | Array of player stats, permanent ownership, opening policy and inventory. |
| [`data/encounter.json`](../data/encounter.json) | Default encounter object, `training_shadeling`. |
| [`data/dev_encounter.json`](../data/dev_encounter.json) | Alternate encounter object, `dev_calibration`; development/test content only. |

[`RuneContentLoader`](../scripts/core/content_loader.gd) separates file access from validation:

```gdscript
const ContentLoader = preload("res://scripts/core/content_loader.gd")
const Combat = preload("res://scripts/core/combat.gd")
var loaded := ContentLoader.load_setup("res://data/encounter.json")
if loaded.ok:
    var model := Combat.new(loaded.setup)
else:
    # Show loaded.errors and disable gameplay; do not build a fallback model.
    pass
```

`load_setup(encounter_path, definition_paths = {})` reads the selected encounter plus the four definition files. Tests or tools can override the `runes`, `boards`, `enemies` and `loadouts` file paths. Unknown source keys fail. `read_document(path)` returns parsed data or file/JSON diagnostics. `validate_documents({runes, boards, enemies, loadouts, encounter}, source_names = {})` validates supplied parsed documents without I/O. Source names are optional diagnostic labels. Both setup-producing functions return `{ok, errors, setup}`; any failure returns an empty setup. All definitions are checked, including unused entries; ownership and installed-inventory accounting apply to the selected encounter's board/loadout combination.

The returned setup is a deep copy containing `catalog`, flattened `encounter`, sixteen-cell `board`, `owned_cards`, `opening_hand`, `opening_draw` and `inventory`. The combat constructor accepts this normalized setup and performs no file access. Treat it as a trusted internal boundary: callers must validate documents before construction. The constructor makes its own independent restart template and active state copies. `Combat.new(setup, seed_override)` also accepts an optional integer seed override in the same range as the encounter seed; ordinary scene launch uses the encounter seed.

## Common schema rules

Every array entry is an object with a required nonempty `id`. IDs contain lowercase letters, digits and underscores and are unique within their definition category. Display names can change without changing IDs. Arrays, rather than object keys, make duplicate definition IDs detectable. Unknown fields are rejected at every definition, placement, inventory and encounter level.

Required strings must be nonempty after trimming. Numeric fields must be finite mathematical integers within the stated limits; JSON numbers such as `3.0` are accepted and normalized to integer `3`, while `3.5`, `"3"`, booleans and null are rejected. Values are never silently truncated or coerced from strings. Optional defaults apply only when the field is omitted, never when a supplied value is invalid.

### Runes and techniques

Required fields are `id`, `name`, `symbol`, `type`, `effect`, `value`, `cost` and `color`. `color` is a valid Godot HTML hex color, such as `#efb553`. Optional `board_label` defaults to `name`; `free_spark` explicitly uses `Spark` to preserve its compact board label. Optional `temporary` is boolean and defaults to `false`.

| Type/effect | Meaning of `value` | Other rules |
| --- | --- | --- |
| `rune` / `damage` | Added scalar damage, 0–10,000. | Straight effect ports under current circuit rules. |
| `rune` / `shield` | Added scalar shield, 0–10,000. | Straight effect ports under current circuit rules. |
| `technique` / `draw` | Number of attempted card draws, 0–20. | Draws actual available cards, reshuffling discard as needed. |
| `technique` / `conjure` | Number of generated cards, 0–20. | Required `generated_rune_id` must resolve to a temporary effect rune with zero cost. |

`cost` is 0–20. Temporary definitions must be effect runes with cost zero; temporary techniques are unsupported. Only a conjure technique may provide `generated_rune_id`. The target can use either supported rune effect; dispatch honors both its target and count. Zero-count techniques still pay their cost, discard the technique and commit preparation, but draw/create nothing. Unknown types/effects and mismatched combinations fail validation; there is no implicit Conjure fallback.

### Boards

Required fields are `id`, `width`, `height` and `placements`. Width and height must both equal 4. Placements are a sparse array of objects, each with a unique integer `cell` in 0–15 and required `kind`: `begin`, `end`, `straight`, `corner`, `split`, `join` or `rune`. Unlisted cells are empty.

`rotation` is an optional integer 0–3, default 0, representing clockwise quarter turns. `reversed` is optional boolean, default false, and may be explicitly supplied only for straight/corner wires. A `rune` placement requires a known `rune_id` whose definition type is `rune`; other pieces cannot carry this field. Board data never provides card UIDs.

In normal loading, Begin must be explicitly installed at cell 0, End at cell 14, both rotation 0. Explicit custom ports, endpoint geometry, blocked cells and obstacle kinds fail validation outside the opt-in experimental contexts below. The roster's stable introductory board ID is `board_training`.

A structurally valid board does **not** need to be currently castable. Open connections, disconnected pieces and incomplete paths remain editable starting positions; `RuneCircuit.evaluate` supplies the ordinary circuit forecast and cast rejection. Schema errors concern malformed/unsupported data, not whether the current circuit can cast.

### Enemies

Required fields are `id`, `name`, `max_health` and `intents`. Maximum health is 1–100,000. `intents` contains 1–100 integer scalar attack amounts, each 0–100,000. Combat cycles through the sequence once per turn. Object intents, phases, statuses and other future enemy behaviors are unsupported. Enemies start at maximum health.

### Loadouts/player setup

| Field | Requirement/default |
| --- | --- |
| `id` | Required stable ID. |
| `max_health` | Required integer 1–100,000. |
| `current_health` | Optional; defaults to maximum. Must be 1–`max_health`, because a battle setup starts with a living player. |
| `energy_per_turn` | Required integer 0–20; also the initial energy. |
| `draw_per_turn` | Required integer 0–20 for each subsequent turn. |
| `owned_cards` | Required ordered array of 0–100 known permanent card IDs; repeated IDs are owned copies. Temporary cards are forbidden. |
| `opening_policy` | Required `curated` or `draw`. |
| `opening_hand` | Required for `curated`: ordered permanent IDs, maximum 100. Omit for `draw`. |
| `opening_draw` | Required for `draw`: integer 0–20. Omit for `curated`. |
| `inventory` | Required object containing integer `split` and `join` totals, each 0–14. Basic wires remain unlimited. |

Curated hand copies and permanent installed runes must fit ownership together. A draw opening cannot request more cards than ownership remaining after permanent board allocation. Inventory totals include pieces already on the board; a setup installing more Splits or Joins than owned fails. These caps bound supported setup data, not balance recommendations.

### Encounters

Required fields are `id`, `enemy_id`, `board_id`, `loadout_id`, `title` and `help_text`. References must resolve in their corresponding definition arrays. Optional `opening_log` defaults to `help_text`; optional integer `seed` defaults to 42 and must be 0–2,147,483,647. The title, help text and opening log are presentation strings, not executable instructions.

To add a supported encounter, add/reuse a validated enemy, board and loadout, then create an encounter object referencing their IDs. Keep development fixtures clearly named and described. Validate the selected combination before exposing it in a scene. To use entirely separate definition files from a test/tool, supply the `definition_paths` override dictionary to the loader.

## Ownership, identity and reproducibility

Stable definition IDs include `spark`, `shield`, `focus`, `conjure`, `free_spark`, `shadeling`, `board_training` and `training_shadeling`. The scene exposes the selected stable encounter ID as `snapshot.encounter_content_id`. RC-003's numeric `snapshot.encounter_id` remains a reset/presentation generation counter, not a content ID. Card UIDs identify instances within one generation and are not persistent ownership IDs. Events retain their existing action/generation/sequence identities.

Construction allocates temporary starting board runes first, then curated hand cards, then permanent board runes, then all remaining owned cards in ownership-array order. Each permanent allocation removes one owned copy from the remainder; none are duplicated. The remaining draw pile uses the existing descending Fisher–Yates shuffle and end-of-pile draws. Draw policy deals from that shuffled remainder. Setup dealing emits no action/presentation batch.

The training loadout owns exactly two each of Spark, Shield, Focus and Conjure Spark. Its ownership order preserves the original curated hand `spark`, `shield`, `conjure` and residual sequence `spark`, `shield`, `focus`, `focus`, `conjure` before shuffling. The installed Free Spark is a tutorial setup item outside the eight permanent cards. It retains UID 0, followed by permanent UIDs 1–8. Generated cards receive fresh UIDs and never enter permanent ownership or discard/draw piles. Every live hand, board and pile instance has a unique UID.

Fresh models with the same normalized setup/seed reproduce the same state. Restart restores the selected cached setup, including its definitions, opening policy, board, health and totals; it does not reload files or switch to training. Restart **continues** the RNG stream, preserving RC-003 behavior, so it need not reproduce a fresh battle's shuffle. Card UIDs restart while presentation generation increases, and action identity remains monotonic. Edits and undo compute available inventory from configured totals minus current board usage.

## Development scene and diagnostics

Normal launch stays on training:

```powershell
.\tools\godot.ps1 -Action run
.\tools\godot.ps1 -Action run -Encounter res://data/dev_encounter.json
.\tools\godot.ps1 -Action capture -Encounter res://data/dev_encounter.json -CapturePath res://output/qa/rc-004-development.png
```

The equivalent Godot user arguments are `-- --encounter=res://data/dev_encounter.json` and, for a capture, `--capture --capture-path=res://output/qa/rc-004-development.png`. The actual main scene also accepts an injected encounter path before `_ready()` for tests. Use the documented launcher rather than editing the default JSON to select the fixture.

The alternate **Calibration Wisp** is explicitly a development fixture, not balanced production content: enemy 45 HP with attacks 3→7→5; player 24/40 HP, four energy and two cards per turn; two Splits and zero Joins. It owns six permanent cards, opens with Focus/Shield and an owned Spark installed on a different complete path. Its opening forecast is six damage for two energy. The shared placeholder art is retained.

Missing/unreadable files, malformed JSON and schema failures return diagnostics such as `res://data/runes.json [spark].cost: expected an integer in [0, 20]`. JSON syntax errors include a parser line. The screen shows startup errors and disables gameplay with no silently playable training fallback. Tests inject malformed/invalid fixtures under `tests/fixtures/` and mutate detached source documents; production data is not corrupted.

The existing `-Action test` includes loader and configured-combat tests; `-Action smoke` exercises alternate bindings and safe invalid startup alongside RC-003 interaction/cancellation coverage. See [combat presentation](combat-presentation.md) for snapshot construction and [verification](verification.md) for dated actual counts, captures and environment limits.

## RC-005 opt-in extensions

Normal `load_setup` has no experimental flag: JSON cannot enable candidate rules by adding an encounter field. `RuneExperiments.load_setup(scenario_id, variant_id, seed=42)` builds bounded fixture documents and calls `validate_documents(documents, source_names={}, experiment_context=null)` with an explicit context. `experiment_options` creates the exact `rc005_v1` mapping, and `validate_experiment` rejects unknown/missing keys, incorrect types, unknown IDs, mismatched seed/version or rules inconsistent with that scenario/variant. There is no general scripting or arbitrary option cross-product.

Normalized experimental setup gains a detached `experiment` dictionary: `scenario_id`, `variant_id`, `version`, `seed`, `effects`, `split_cost`, `damage_mode`, `expiry`, `transfer`. See the [matrix and exact semantics](circuit-experiments.md). The same core model implements these strategies; normal snapshots and events retain their existing shape.

Geometry capabilities are limited to their comparison context:

- `endpoints/treatment`: exactly one Begin and End at unique cells, rotations 0–3, each endpoint port facing an in-bounds neighbor. Both are protected in model editing. Other scenarios retain the normal endpoint rules.
- `blocked/treatment`: `kind: blocked`, rotation0, no rune ID or explicit reversal. It has zero ports, cannot be edited, and blocks traversal as well as rendering a marked cell.
- `ports` and `expiry`: effect definitions may specify `port_shape: straight|corner`; techniques may not. Placement metadata is derived from the catalog, never independently supplied. `RuneCircuit.ports`, evaluation, installed-card placement, rotation and rendering share this geometry. No arbitrary port arrays or new effect families are accepted.

Experiment fixtures use existing scalar rune definitions without modifying normal content files. Unknown document fields, second-board/transfer overrides and unsupported combinations are rejected. The two-encounter harness repeats identical geometry; it never silently relocates pieces. It conserves existing permanent UIDs across its one transition and excludes temporary ownership. A fresh exact replay reconstructs the cached normalized setup/seed; normal Restart still continues RNG. The setup fingerprint and full setup are recorded locally for reproduction.
