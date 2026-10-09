# Validated content definitions

RC-007 selects the production profile described below: scalar damage/shield runes, draw/conjure techniques, endpoints-only boards, random connector kits and normal draws. RC-004 historical definitions and the narrowly gated RC-005/RC-006 experiments retain their original semantics. The future roster, relics, statuses, combined effects and guardian phases remain unimplemented.

## Files and entry points

| File | JSON root and purpose |
| --- | --- |
| [`data/runes.json`](../data/runes.json) | Array of rune and technique definitions. |
| [`data/boards.json`](../data/boards.json) | Array of starting-board definitions. |
| [`data/enemies.json`](../data/enemies.json) | Array of enemy definitions and scalar attack sequences. |
| [`data/loadouts.json`](../data/loadouts.json) | Array of player stats, permanent ownership, opening policy and inventory. |
| [`data/production_encounter.json`](../data/production_encounter.json) | Default production encounter, preserving `training_shadeling`. |
| [`data/production_boards.json`](../data/production_boards.json) | Four stable production board identities sharing the same random endpoint policy, plus preserved `dev_entry_board`; `board_training` remains normal launch. |
| [`data/board_examples.json`](../data/board_examples.json) | Opt-in RC-009 construction witnesses with exact natural starter seeds, commands and expected observations. Never production prefills. |
| [`data/production_loadouts.json`](../data/production_loadouts.json) | Production normal-draw loadouts; connector stock comes from kit definitions. |
| [`data/production_rules.json`](../data/production_rules.json) | Three versioned, provisional equal-probability ten-piece kits. |
| [`data/production_transition_encounter.json`](../data/production_transition_encounter.json) | Bounded development entry into [`production_next_encounter.json`](../data/production_next_encounter.json); no full progression. |
| [`data/encounter.json`](../data/encounter.json) | Explicit historical prefilled training encounter, also `training_shadeling`; different profile, not a new roster entry. |
| [`data/dev_encounter.json`](../data/dev_encounter.json) | Alternate encounter object, `dev_calibration`; development/test content only. |

[`RuneContentLoader`](../scripts/core/content_loader.gd) separates file access from validation:

```gdscript
const ContentLoader = preload("res://scripts/core/content_loader.gd")
const Combat = preload("res://scripts/core/combat.gd")
var loaded := ContentLoader.load_setup()
if loaded.ok:
    var model := Combat.new(loaded.setup)
else:
    # Show loaded.errors and disable gameplay; do not build a fallback model.
    pass
```

`load_setup(encounter_path = DEFAULT_ENCOUNTER, definition_paths = {})` first reads the encounter. A supported `ruleset: "rc007_production_v1"` selects production board/loadout files and validated kit rules; absence of the marker explicitly selects the historical profile. Unsupported markers fail. Tests/tools can override the `runes`, `boards`, `enemies` and `loadouts` paths; unknown source keys fail. `read_document(path)` returns parsed data or file/JSON diagnostics. `validate_documents(documents, source_names = {}, experiment_context = null, production_context = null)` validates supplied parsed documents without I/O. Production and experiment contexts are mutually exclusive, versioned and strictly validated. Source names are optional diagnostic labels. Setup-producing functions return `{ok, errors, setup}`; any failure returns an empty setup. All definitions are checked, including unused entries.

The returned setup is a deep copy containing `catalog`, flattened `encounter`, sixteen-cell `board`, `owned_cards`, `opening_hand`, `opening_draw` and `inventory`. Production also includes validated `production` options and, when configured, one validated `next_encounter` setup. The combat constructor accepts this normalized setup and performs no file access. Treat it as a trusted internal boundary: callers must validate documents before construction. The constructor makes its own independent restart template and active state copies. `Combat.new(setup, seed_override)` also accepts an optional integer seed override in the same range as the encounter seed; ordinary scene launch uses the encounter seed.

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

Production templates require exactly one Begin and one End at distinct cells with rotations 0–3, and fourteen empty cells. Every distinct pair and outward-facing direction is valid authoring input; playable setup resamples the pair/directions using the selected RNG contract. Prefilled connectors/effects and blocked cells fail. Production effect ports are straight, either omitted or explicitly `port_shape: straight`; corner effects fail. The roster's stable introductory board ID is `board_training`.

Explicit historical loading retains Begin0/End14 with rotation0. Alternate geometry/ports remain gated by their historical experiment contexts below.

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
| `draw_per_turn` | Required integer 0–20; production uses this count for every playable entry, including the first. |
| `owned_cards` | Required ordered array of 0–100 known permanent card IDs; repeated IDs are owned copies. Temporary cards are forbidden. |
| `opening_policy` | Production requires `draw`; historical profiles also permit `curated`. |
| `opening_hand` | Required for `curated`: ordered permanent IDs, maximum 100. Omit for `draw`. |
| `opening_draw` | Required for `draw`: integer 0–20. Production requires equality with `draw_per_turn`; draws stop when the permanent pool is empty. Omit for historical `curated`. |
| `inventory` | Omit in production: every playable entry selects its complete kit. Historical profiles require integer `split`/`join` totals 0–14 and optionally `straight`/`corner` together, also 0–14. Omitting both basic types preserves historical unlimited wires. |

Historical curated hand copies and permanent installed runes must fit ownership together, and historical draw openings cannot exceed remaining ownership. Production permits a smaller or empty pool and draws only available cards. Finite totals include disconnected installations; overinstalled authored stock fails. Production's normalized `inventory` receives a detached first-kit placeholder, replaced by the model's actual one-time kit selection before its initial snapshot. Raw authored stock is forbidden so it cannot override or bypass the selected kits. These caps bound setup data, not balance recommendations.

### RC-007 selected production profile — October 9, 2026

[`RuneProductionRules`](../scripts/core/production_rules.gd) validates the selected kit definitions and complete production options. `load_rules(path)` and `validate_rules(document, source)` return detached `{ok, errors, rules}` values; failure returns no partial rules. Version `rc007_connector_kits_v1` requires `extra_straights` 6/2/1/1, `extra_corners` 4/4/1/1 and `extra_branches` 4/2/2/2, weight 1 each and `balance: provisional`. Unsupported fields, partial kits and changed counts/probabilities fail this version. Later tuning explicitly revises the versioned definition and validation together.

`production_options(validated_kit_rules)` supplies the `rc007_production_v1` options; `validate_production(context)` rejects missing, unsupported or unselected options. These select full reset/discard, empty temporary expiry, Split1/Join0, aggregate damage, random distinct endpoints and player Rotate. `select_kit(validated_rules, dedicated_rng)` makes one uniform selection and returns a detached kit; repeats are allowed. Combat owns the stream and calls this helper exactly once at playable entry, replacing stock. Exact seed/selection/order policies are in the [production specification](production-rules-spec.md).

Finite inventory uses the existing authoritative combat model. Placement reserves stock by board occupancy; erase/replacement returns the displaced type; rune installation returns its displaced connector; removing a rune creates no connector. Rotation/Flip preserve quantities and Undo restores board, hand and derived stock together. Production snapshots expose all four stock types plus detached `production` and `kit` metadata. Historical fixtures retain their exact snapshot/configuration shapes and fingerprints.

Production encounter files may specify `next_encounter: "res://...json"`. File loading resolves and validates that successor before constructing a model; missing/incompatible successors, cycles or a second successor fail. Pure document validation rejects unresolved path fields; callers composing normalized setups use `validate_transition(current_setup, next_setup)` and attach its detached result as `setup.next_encounter`. Both profiles must be production, catalog definitions and permanent ownership multisets must match, and the successor ID must differ. This is a trusted normalized-setup boundary, not an unvalidated command payload.

`next_encounter` takes no command arguments and is accepted once after eligible victory. Runtime reconciliation also verifies the initial permanent UID ledger against every live instance before mutating or consuming RNG. Current/max HP carry without healing, overriding the next loadout's authored health. The next enemy starts at its maximum; energy/draw use its configuration. Old zones, temporaries and Undo clear; UID-sorted permanents are shuffled using continuing card RNG, then drawn normally. Endpoints sample the initial 240-pair domain with continuing endpoint RNG; the kit uses continuing kit RNG. No nested run/map/reward/save system is provided.

### Encounters

Required fields are `id`, `enemy_id`, `board_id`, `loadout_id`, `title` and `help_text`. References must resolve in their corresponding definition arrays. Optional `opening_log` defaults to `help_text`; optional integer `seed` defaults to 42 and must be 0–2,147,483,647. The title, help text and opening log are presentation strings, not executable instructions.

To add a supported encounter, add/reuse a validated enemy, board and loadout, then create an encounter object referencing their IDs. Keep development fixtures clearly named and described. Validate the selected combination before exposing it in a scene. To use entirely separate definition files from a test/tool, supply the `definition_paths` override dictionary to the loader.

## Ownership, identity and reproducibility

Stable definition IDs include `spark`, `shield`, `focus`, `conjure`, `free_spark`, `shadeling`, `board_training` and `training_shadeling`. The scene exposes the selected stable encounter ID as `snapshot.encounter_content_id`. RC-003's numeric `snapshot.encounter_id` remains a reset/presentation generation counter, not a content ID. Card UIDs identify live instances and carry unchanged through the configured encounter transition, even though that advances the generation. Fresh construction and Restart allocate new instances; UIDs are not persistent save identifiers. Events retain their existing action/generation/sequence identities.

Production construction allocates the complete permanent collection in ownership-array order (starter UIDs 0–7), shuffles it with descending Fisher–Yates, then draws from the end of the pile. Historical construction allocates temporary starting board runes first, then curated hand cards, then permanent board runes, then all remaining owned cards in ownership-array order. Each permanent allocation removes one owned copy from the remainder; none are duplicated. The remaining historical draw pile uses the same shuffle and end-of-pile draws. Setup dealing emits no action/presentation batch.

Both training profiles own exactly two each of Spark, Shield, Focus and Conjure Spark. Production draws its first hand normally and has no tutorial installation. The explicit historical profile preserves the original curated hand `spark`, `shield`, `conjure` and residual sequence `spark`, `shield`, `focus`, `focus`, `conjure` before shuffling. Its installed Free Spark is a tutorial setup item outside the eight permanent cards, retaining UID 0 followed by permanent UIDs 1–8. Generated cards receive fresh UIDs and never enter permanent ownership or discard/draw piles. Every live hand, board and pile instance has a unique UID.

Fresh models with the same normalized setup/seed reproduce the same state. Exact replay reconstructs that initial state. Restart restores the original selected cached encounter, definitions, opening policy and health without reloading files. Production selects fresh endpoints and a kit while **continuing all three RNG streams**; historical profiles restore their configured board and totals while continuing their applicable streams. Thus Restart need not reproduce the opening. Card UIDs restart while presentation generation increases, and action identity remains monotonic. Edits and Undo compute available inventory from current totals minus board usage.

## Development scene and diagnostics

RC-009 adds four small encounter files under [`data/development/`](../data/development/), reusing the existing Shadeling, starter loadout and production catalogs. They display **DEV / First Circuit**, **DEV / Long Gallery**, **DEV / Ossuary Turn**, or **DEV / Belfry Circuit**. Board display names, teaching roles and future presentation assignments are documented in the [board catalog](board-catalog.md); the board JSON schema is unchanged. Identity has no effect on endpoint positions, rotations, cards, kits, costs or enemy difficulty.

`-Encounter res://data/development/rc009_gallery_encounter.json` opens its ordinary endpoints-only sample. The separate `-BoardExample board_gallery -ExampleStep opening|built|cast` launch reads the corresponding witness, validates its natural opening, then optionally sends its exact construction commands and one Cast through the existing controller. `built` is the default. No cards, stock or geometry are injected. `data/board_examples.json` uses version `rc009_board_examples_v1`; each of the four entries contains `board_id`, `purpose`, `setup_kind: natural_starter_draw`, `encounter_path`, `seed`, exact `commands` and `expected.initial/built/after_cast` facts. The development helper validates IDs, paths, seed, command forms and phase observations; reproduction mismatch disables startup instead of falling back. Only this explicit development mode reads the witness data.

`-BoardExample` is exclusive with `-Encounter` and `-Experiment`, and applies only to `run`/`capture`. `-ExampleStep` requires it. Menu Exact replay restores the selected fixture's endpoints-only opening; it does not auto-build again. Menu Restart continues the ordinary random streams. `-LogDirectory output/qa/rc-009/<fresh-name>` optionally isolates engine logs for any launcher action; `-CapturePath` still selects the PNG destination. Exact commands for all four identities and examples are in the catalog.

Normal launch selects the production Training Crypt. Historical and bounded transition fixtures require explicit selection:

```powershell
.\tools\godot.ps1 -Action run
.\tools\godot.ps1 -Action run -Encounter res://data/encounter.json
.\tools\godot.ps1 -Action run -Encounter res://data/dev_encounter.json
.\tools\godot.ps1 -Action run -Encounter res://data/production_transition_encounter.json
.\tools\godot.ps1 -Action capture -Encounter res://data/dev_encounter.json -CapturePath res://output/qa/rc-007/implementation/review-development.png
```

The equivalent Godot user arguments are `-- --encounter=res://data/dev_encounter.json` and, for a capture, `--capture --capture-path=res://output/qa/rc-007/implementation/review-development.png`. Use a fresh capture destination to preserve earlier evidence. The actual main scene also accepts an injected encounter path before `_ready()` for tests. Use the documented launcher rather than editing the default JSON to select the fixture.

The historical **Calibration Wisp** (`dev_encounter.json`) is explicitly a development fixture, not balanced production content: enemy 45 HP with attacks 3→7→5; player 24/40 HP, four energy and two cards per turn; two Splits and zero Joins. It owns six permanent cards, opens with Focus/Shield and an owned Spark installed on a different complete path. Its opening forecast is six damage for two energy. The separate production successor reuses this enemy with endpoints-only geometry, normal draws and the same eight-card collection as production training; entry carries the previous player's current/max HP. The shared placeholder art is retained.

Missing/unreadable files, malformed JSON and schema failures return diagnostics such as `res://data/runes.json [spark].cost: expected an integer in [0, 20]`. JSON syntax errors include a parser line. The screen shows startup errors and disables gameplay with no silently playable training fallback. Tests inject malformed/invalid fixtures under `tests/fixtures/` and mutate detached source documents; production data is not corrupted.

The existing `-Action test` includes loader and configured-combat tests; `-Action smoke` exercises alternate bindings and safe invalid startup alongside RC-003 interaction/cancellation coverage. See [combat presentation](combat-presentation.md) for snapshot construction and [verification](verification.md) for dated actual counts, captures and environment limits.

## RC-005 opt-in extensions

The following study sections preserve historical fixture semantics and the decisions available when each was added. References to unchanged normal gameplay or unresolved production choices describe that historical stage; the accepted RC-007 profile above is current. None of these old fixtures is rewritten to use production rules.

Normal `load_setup` has no experimental flag: JSON cannot enable candidate rules by adding an encounter field. `RuneExperiments.load_setup(scenario_id, variant_id, seed=42)` builds bounded fixture documents and calls `validate_documents(documents, source_names={}, experiment_context=null)` with an explicit context. `experiment_options` creates the exact `rc005_v1` mapping, and `validate_experiment` rejects unknown/missing keys, incorrect types, unknown IDs, mismatched seed/version or rules inconsistent with that scenario/variant. There is no general scripting or arbitrary option cross-product.

Normalized experimental setup gains a detached `experiment` dictionary: `scenario_id`, `variant_id`, `version`, `seed`, `effects`, `split_cost`, `damage_mode`, `expiry`, `transfer`. See the [matrix and exact semantics](circuit-experiments.md). The same core model implements these strategies; historical baseline snapshots and events retain their existing shape.

Geometry capabilities are limited to their comparison context:

- `endpoints/treatment`: exactly one Begin and End at unique cells, rotations 0–3, each endpoint port facing an in-bounds neighbor. Both are protected in model editing. Other scenarios retain the normal endpoint rules.
- `blocked/treatment`: `kind: blocked`, rotation0, no rune ID or explicit reversal. It has zero ports, cannot be edited, and blocks traversal as well as rendering a marked cell.
- `ports` and `expiry`: effect definitions may specify `port_shape: straight|corner`; techniques may not. Placement metadata is derived from the catalog, never independently supplied. `RuneCircuit.ports`, evaluation, installed-card placement, rotation and rendering share this geometry. No arbitrary port arrays or new effect families are accepted.

Experiment fixtures use existing scalar rune definitions without modifying normal content files. Unknown document fields, second-board/transfer overrides and unsupported combinations are rejected. The two-encounter harness repeats identical geometry; it never silently relocates pieces. It conserves existing permanent UIDs across its one transition and excludes temporary ownership. A fresh exact replay reconstructs the cached normalized setup/seed; normal Restart still continues RNG. The setup fingerprint and full setup are recorded locally for reproduction.

## RC-006 opt-in full-reset extension

The additive `effects/full_reset` fixture uses version `rc006_full_reset_v1`; the original 19 variants retain their `rc005_v1` mappings. Its normalized `experiment` dictionary adds **`board_reset: "each_turn"`** and selects **`effects: "discard_all"`**, **`expiry: "empty"`**, `split_cost: 1`, `damage_mode: "aggregate"` and `transfer: "none"`. The scenario/variant/version/seed and every required key/value are checked by `validate_experiment`; the reset field is not a normal-content flag or an arbitrary option that other variants can enable.

The fixture encounter ID is `rc006_effects_full_reset` and board ID is `rc006_effects_full_reset_board`. Initial placements contain only Begin at cell0 and End at cell14, both rotation0; full-reset setup validation rejects any other starting piece. The existing eight-card collection allocates the curated Spark/Shield/Conjure hand and remaining draw pile with no installed permanent-card allocation. This differs from the original effects fixtures and is not a matched starting state. No production content ID or family budget changes.

Accepted Cast/Pass clears every nonendpoint piece after combat resolution: installed permanents, including disconnected ones, go to discard with the same UIDs; temporaries disappear without entering ownership/piles. Hand/history cleanup follows, then terminal resolution or normal refresh/draw with repeats allowed. Rejected commands do not reset. See [follow-up invariants, fingerprint and validation](circuit-experiments.md#rc-006-full-reset-follow-up) and [presentation events](combat-presentation.md#rc-006-full-reset-events). Normal definitions/gameplay remain unchanged; this study fixture does not settle production timing, board-feature compatibility or encounter-transfer policy.

## RC-006 opt-in moving-endpoint extension

`effects/moving_endpoints` uses version `rc006_moving_endpoints_v1`, encounter ID `rc006_effects_moving_endpoints` and board ID `rc006_effects_moving_endpoints_board`. It inherits the full-reset rule values while adding `endpoint_policy: "random_each_turn"` and a pinned eight-entry `endpoint_layouts` catalog. Every entry has `id`, `path`, `begin: {cell, rotation}` and `end: {cell, rotation}`. Required keys, exact versioned values and the entire catalog are validated; normal JSON and other variants cannot enable this policy. Existing 20 variant mappings/fingerprints remain unchanged.

Each witness path is simple, in bounds and orthogonally connected, with at least one interior straight rune socket. The loader verifies unique layout IDs and an eligible successor from the fixed opening and every layout. Eligibility requires both endpoints to change their respective positions. Endpoint orientations follow the witness geometry; successive orientations may repeat. The complete catalog is fingerprinted and retained in raw exports, but omitted from the participant's rules tooltip to avoid exposing solutions.

Initial placement remains Begin0/End14 at rotation0 as a study control. Nonterminal accepted Cast/Pass clears the board and hand, then selects a new endpoint layout using its separate RNG before normal drawing. Exact replay reproduces both card and endpoint sequences; Restart continues them. Terminal/rejected actions, edits, techniques and Undo do not select a layout. See [follow-up controls and limits](circuit-experiments.md#rc-006-moving-endpoint-follow-up) and [presentation payload/order](combat-presentation.md#rc-006-moving-endpoint-events). This preserves the historical bounded experimental catalog. H19 supersedes it as the selected direction by allowing any distinct endpoint positions, including adjacency, with normal player rotation; first-turn generation and encounter integration remain incomplete.


## RC-006 opt-in free-endpoint extension

The separate `effects/free_endpoints` fixture uses version `rc006_free_endpoints_v1`, encounter ID `rc006_effects_free_endpoints` and board ID `rc006_effects_free_endpoints_board`. It implements H19's corrected player-rotation/unrestricted-position direction without changing the prior moving fixture. The full-reset cleanup rule values remain, with exact versioned metadata `endpoint_policy: "random_any_cells"`, `endpoint_rotation: "player"`, `endpoint_initial: "random"`, `endpoint_selection: "uniform_ordered_pairs_v1"`, `endpoint_position_pairs: 240` and `endpoint_successor_pairs: 211`. There is no `endpoint_layouts` catalog in this variant. Validation requires the exact keys, types and values; normal content cannot enable these features by adding JSON fields.

The normalized source board retains canonical Begin0/End14 at rotation0 as a reset template, with no other installed pieces. The model samples the actual opening from all 240 distinct ordered cell pairs. Each later nonterminal turn samples uniformly from the 211 pairs in which neither endpoint retains its own previous cell. Adjacent cells and cross-swaps are eligible. Each endpoint gets an independent rotation0–3; the player can use ordinary Rotate and Undo to change its direction. Initial directions may face the edge or be unconnected, so the player may need to rotate before constructing a valid circuit. Erase, replacement and Flip remain prohibited on endpoints.

The separate endpoint RNG uses the existing `seed XOR 0x52434D45` seed derivation and does not alter the card draw RNG. Fresh launch/Exact replay reproduces the random opening and later sequence. Menu Restart generates another opening while continuing both streams. The actual sampled opening is preserved in the record's `initial_state`; `starting_setup` and its fingerprint describe the normalized source configuration. See [follow-up behavior and validation](circuit-experiments.md#rc-006-free-endpoint-follow-up) and [event semantics](combat-presentation.md#rc-006-free-endpoint-events). Random initial generation and independent initial orientations are experimental choices, not additional owner approval of the production first-turn policy.
