# Board catalog

RC-009, October 9, 2026. The four stable identities below use the same accepted [production rules](production-rules-spec.md#october-9-2026--accepted-rc-007-implementation-contract). A **board identity** is a content/encounter reference. A **runtime layout** is the sampled endpoints and the player's current construction. An **authored example** is a reproducible witness for one sampled setup. These definitions do not create mechanically different difficulty.

| Identity / display name | Teaching/content role | Future assignment and presentation |
| --- | --- | --- |
| `board_training` / First Circuit | Introductory rune-bearing route; endpoint Rotate, replacement and Undo. | First Shadeling/onboarding, RC-043; shared crypt and circuit feedback, RC-012/RC-016. |
| `board_gallery` / Long Gallery | Longer routing and placement of damage/shield runes within stock. | Early/middle normal encounters, RC-034/RC-036; proposed cool crypt lighting, RC-010/RC-015/RC-042. |
| `board_ossuary` / Ossuary Turn | Turns, directional reversal and Undo. | Middle/late normals and elite, RC-034/RC-036; proposed warm candle treatment, RC-010/RC-015/RC-042. |
| `board_belfry` / Belfry Circuit | Split/Join amplification versus physical-piece cost. | Guardian assignment, RC-034/RC-036; proposed darker crypt/guardian accent, RC-010/RC-015/RC-042. |

The current four development scenes all use the same placeholder crypt and existing Shadeling. Final enemies, progression, environment art and lighting are future work. `dev_entry_board` remains a separate preserved development fixture, outside the four production identities.

## Shared generation policy

[`production_boards.json`](../data/production_boards.json) uses the unchanged board schema: 4×4, exactly one Begin and End and fourteen empty cells. Its canonical endpoint coordinates are loader/reset placeholders, replaced before the first playable snapshot. They do not constrain runtime geometry. Every playable entry, including encounter entry, starts endpoints-only. The first pair is uniform among all 240 ordered distinct-cell pairs; subsequent turns select among 211 pairs moving both endpoints from their own previous cell, allowing cross-swaps and adjacency. Each endpoint independently starts at rotation 0–3 and supports player Rotate/Undo.

There are no obstacles, alternate effect ports, prefills, board-specific weighting, route-length requirements or mandatory runes. All identities use the same independent card/endpoint/kit streams and one uniformly selected ten-piece kit per playable turn. Kit totals in Straight/Corner/Split/Join order are **6/2/1/1**, **4/4/1/1**, or **4/2/2/2**. Editing and presentation do not consume randomness. Kits replace old stock without banking. Ordinary Restart continues streams; Exact replay restores the selected seed's opening.

The original four fixed-coordinate proposals are retained in the [roster's historical subsection](content-roster.md#historical-rc-002-fixed-coordinate-references). They predate the accepted unrestricted random endpoints and are reference constructions only. The old prefilled training encounter remains explicit historical content at `res://data/encounter.json`.

## Reproduction and resources

All four witnesses are **natural starter draws at deliberately selected, recorded seeds**. Seed selection happened during authoring; neither launch nor gameplay searches/rerolls a seed or inserts resources. These particular hands are not guaranteed random openings. Each fixture reuses `starter` and `shadeling` through the production loader: player **30/30 HP**, **3 energy**, three normal opening draws, eight permanent instances (two each of Spark, Shield, Focus and Conjure Spark), enemy **32 HP**, intents **8 → 12 → 6**, first intent **8**.

[`board_examples.json`](../data/board_examples.json) is the executable source of truth: exact commands and complete expected initial/built/after-Cast boards, hand/piles, UIDs, endpoint rotations, stock, forecast, energy and health. [`board_examples.gd`](../scripts/dev/board_examples.gd) validates the witness then sends every action through the real controller. It never assigns model geometry, cards, stock, HP or energy. All commands must be accepted and observations must match. A mismatch produces a startup error.

Cell indices below are zero-based, row-major:

```text
 0  1  2  3
 4  5  6  7
 8  9 10 11
12 13 14 15
```

Rotations are clockwise quarter turns. Begin's rotation0 output is east; End's rotation0 input is north. `R(c)` means `rotate {index:c}`; `F(c)` means `flip {index:c}`; `U` means `undo {}`; `W(c,kind)` means `place_wire {index:c,kind:kind}`; `P(c,uid)` means `place_rune {index:c,uid:uid}`; `T(uid)` means `technique {uid:uid}`. Repeated `R` commands are individually executed. New wires start at rotation0 and unreversed; a rune on an empty cell starts at rotation0, while a rune replacing a piece inherits its rotation. Append the normal `cast {}` command to any completed sequence below.

| Identity | Seed | Sampled opening Begin / End (`cell:rotation`) | Actual opening hand, in order | Kit (S/C/Split/Join) |
| --- | --- | --- | --- | --- |
| First Circuit | 294 | `0:2 / 2:3` | Spark UID0, Spark UID3, Focus UID5 | `extra_branches` 4/2/2/2 |
| Long Gallery | 39 | `0:2 / 13:0` | Spark UID0, Spark UID3, Shield UID1 | `extra_corners` 4/4/1/1 |
| Ossuary Turn | 474 | `12:0 / 15:3` | Conjure UID2, Focus UID5, Spark UID3 | `extra_corners` 4/4/1/1 |
| Belfry Circuit | 2149 | `0:2 / 14:3` | Focus UID6, Shield UID1, Conjure UID7 | `extra_straights` 6/2/1/1 |

### First Circuit — introductory rune

Purpose: rotate Begin, install one paid Spark and inspect replacement/refund/Undo. Final route **0 → 1 → 2**; Begin0 rotation0, End2 rotation3. The temporary Straight reservation is refunded when Spark replaces it; Undo restores the wire and returns the same Spark to hand, then the last command installs it again.

```text
R(0), U, R(0), R(0), W(1,straight), P(1,0), U, P(1,0)
```

### Long Gallery — longer routing

Purpose: build around the right/bottom edges and combine damage/shield without exceeding three energy. Final route **0 → 1 → 2 → 3 → 7 → 11 → 15 → 14 → 13**; Begin0 rotation0, End13 rotation1. Spark occupies1; Shield occupies7 with rotation1.

```text
R(0), R(0), R(13), P(1,0), W(2,straight), W(3,corner),
P(7,1), R(7), W(11,straight), R(11), W(15,corner), R(15),
W(14,straight), R(14), R(14)
```

### Ossuary Turn — turns and reversal

Purpose: orient a northbound Spark, undo a trial Flip and retain a required final corner reversal. Final route **12 → 8 → 4 → 5 → 6 → 10 → 14 → 15**; Begin12 rotation3, End15 rotation3. Spark occupies8 at rotation3. Corner4 ends at rotation3/unreversed; Corner14 at rotation2/reversed.

```text
R(12), R(12), R(12), P(8,3), R(8), R(8), R(8),
W(4,corner), R(4), R(4), R(4), F(4), U,
W(5,straight), W(6,corner), W(10,straight), R(10),
W(14,corner), R(14), R(14), F(14)
```

### Belfry Circuit — legal Split/Join

Purpose: Conjure one Free Spark, amplify its contribution and add Shield on one branch. Conjure UID7 costs zero and creates temporary **Free Spark UID8** through the normal technique. It is not supplied by the fixture. Begin0 rotation0 → Free Spark1 → Split2. The branches **2 → 6 → 10** and **2 → 3 → 7 → 11 → 10** meet at Join10 → End14 rotation0. Shield UID1 occupies6 at rotation1. The single physical Free Spark contributes twice; Shield contributes once.

```text
T(7), R(0), R(0), R(14), P(1,8), W(2,split), W(3,corner),
P(6,1), R(6), W(7,straight), R(7), W(10,join), W(11,corner), R(11)
```

### Expected Cast and cleanup

All four completed circuits are valid and affordable. Construction edits cost no energy. Belfry's Conjure costs zero; no other technique is used.

| Identity | Physical connectors used S/C/Split/Join | Physical runes | Cast cost | Damage / shield | Player / enemy HP after Cast |
| --- | --- | --- | --- | --- | --- |
| First Circuit | 0/0/0/0 | 1 Spark | 2 | 6 / 0 | 22 / 26 |
| Long Gallery | 3/2/0/0 | 1 Spark, 1 Shield | 3 | 6 / 5 | 27 / 26 |
| Ossuary Turn | 2/3/0/0 | 1 Spark | 2 | 6 / 0 | 22 / 26 |
| Belfry Circuit | 1/2/1/1 | 1 Free Spark, 1 Shield | 2 (Split1 + Shield1) | 12 / 5 | 27 / 20 |

Each enemy survives. One aggregate damage event resolves, followed by shield/retaliation. All connectors clear; installed permanents discard exactly once, installed Free Spark disappears, remaining permanent hand cards discard, and Undo clears. Every permanent UID0–7 remains exactly once across ownership zones; amplification creates no card copies. A new kit and endpoints are sampled and turn2 begins with **3 energy**, three normal draws, zero installed runes/connectors, full new stock, and next enemy intent **12**. Unspent old energy/stock does not bank. The exact next samples are:

| Identity | Next Begin / End (`cell:rotation`) | New kit | Turn2 hand, in order |
| --- | --- | --- | --- |
| First Circuit | `1:2 / 11:2` | extra_branches | Shield1, Shield4, Conjure7 |
| Long Gallery | `3:1 / 5:1` | extra_straights | Focus6, Focus5, Conjure2 |
| Ossuary Turn | `6:2 / 12:1` | extra_branches | Focus6, Conjure7, Shield1 |
| Belfry Circuit | `13:1 / 12:2` | extra_straights | Shield4, Spark3, Spark0 |

The suffixes in the last table are UIDs. Complete draw/discard order and built rotations are retained in the machine-readable witness. Pass remains available through **Details / Pass** even when construction is incomplete; it attacks without shield, clears the board/hand and starts the next turn if the player survives.

## Exact launch commands

Run from `C:\Dev\RuneCast` in PowerShell. Normal launch remains `.\tools\godot.ps1 -Action run`. Open each development identity at its natural endpoints-only opening:

```powershell
.\tools\godot.ps1 -Action run -Encounter res://data/development/rc009_training_encounter.json
.\tools\godot.ps1 -Action run -Encounter res://data/development/rc009_gallery_encounter.json
.\tools\godot.ps1 -Action run -Encounter res://data/development/rc009_ossuary_encounter.json
.\tools\godot.ps1 -Action run -Encounter res://data/development/rc009_belfry_encounter.json
```

Reproduce the exact command sequences and leave the constructed circuit ready to inspect/Cast:

```powershell
.\tools\godot.ps1 -Action run -BoardExample board_training
.\tools\godot.ps1 -Action run -BoardExample board_gallery
.\tools\godot.ps1 -Action run -BoardExample board_ossuary
.\tools\godot.ps1 -Action run -BoardExample board_belfry
```

Add `-ExampleStep opening` for validated starting resources or `-ExampleStep cast` for the resulting turn2. `built` is the default stage. These modes are exclusive with `-Experiment`/`-Encounter`; no production board-selection screen is added. Exact replay restores the selected seed's opening, without replaying construction; ordinary Restart continues randomness.

Capture an example using a fresh destination:

```powershell
.\tools\godot.ps1 -Action capture -BoardExample board_belfry -ExampleStep built -CapturePath res://output/qa/rc-009/review-belfry.png -LogDirectory output/qa/rc-009/review
```

Run the standalone machine witness or scene/capture verification with the pinned engine (use `--headless` on the scene runner to omit screenshots):

```powershell
& .\.tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --path . --headless --log-file C:\Dev\RuneCast\output\qa\rc-009\review-examples.log --script res://tests/board_example_runner.gd
& .\.tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --path . --log-file C:\Dev\RuneCast\output\qa\rc-009\review-scenes.log --script res://tests/ui_board_catalog_capture.gd
```

The ordinary `-Action test` and `-Action smoke` include RC-009 checks. Rendered captures use a new timestamp/process directory per run. `-LogDirectory` isolates launcher logs; existing screenshot paths are not implicitly protected, so select a new path when retaining evidence.

## Validation and limits

The existing [geometry suite](../tests/connector_geometry_tests.gd) runs **240 ordered endpoint pairs × 3 kits = 720 cases**, supplying one straight Spark explicitly. RC-009 reuses this solver and verifies that all four identities select the same tested profile. The [catalog checks](../tests/board_catalog_tests.gd) cover actual encounter references, invalid/missing/duplicate IDs and malformed geometry; 64 seeded comparisons per identity over opening, Pass and continuing-stream Restarts verify unchanged endpoint/rotation/kit/card samples and RNG states, including changed presentation strings and legal template coordinates. They also verify all four encounter-entry targets using a clearly controlled, validated **one-HP predecessor**. That isolates transfer and does not demonstrate winning the ordinary Shadeling encounter.

The [example checks](../tests/board_example_tests.gd) execute exact controller commands and validate stock, costs/effects, rotations, Flip, replacement/Undo, temporary cleanup, permanent conservation and rejection purity. [Scene checks](../tests/ui_board_catalog_tests.gd) execute the witnesses, actual Cast controls and reused RC-008 synthetic touch inspection, endpoint editing, stock feedback and small-screen scrolling on Belfry. Dated counts, command exit statuses, captures, initial failures/fixes and preservation audits are in [verification](verification.md).

Keep these claims separate:

- **Geometry:** the supplied-Spark solver establishes a route within each finite kit after legal orientation changes.
- **Specific hand/energy:** the four natural samples above can construct and afford their documented spells. Some ordinary hands lack Spark/Conjure, Shield cannot damage, Focus spends energy to reveal cards, and expensive combinations can exceed the turn budget. No useful-hand rerolls, free cards or extra stock are added; Pass remains the fallback.
- **Encounter victory:** these nonlethal one-turn witnesses do not prove that every seeded encounter can be won. The transfer test's one-HP predecessor is explicitly controlled.
- **Balance/enjoyment:** no human playtest or physical-device acceptance was performed. Equal kit probability does not imply equal usefulness. Rebuilding quality, starter difficulty, gesture feel and final encounter balance remain later testing work.
