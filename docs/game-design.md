# Rune Cast game description

Rune Cast is a portrait, turn-based spell-building roguelike for Android and iOS. A travelling spellcaster descends into a cursed tower, constructing attacks and protection from individual runes instead of choosing complete spells.

The central challenge is spatial: build a valid circuit between randomly placed Begin and End sockets, rotate their ports, then use the space, finite connector supply, rune cards and energy budget to improve what the spell produces.

## Player experience

Enemies announce their next action. During preparation, the player draws a small hand, uses techniques, installs effect runes, and edits the circuit. Once every powered branch reaches End and the circuit is affordable, Cast releases the spell. A surviving enemy performs its announced action.

A Split copies the spell prepared upstream. Its branches occupy separate board cells. A Join combines their effects before End. For example, a 6 damage Spark followed by a Split and Join produces 12 total damage. The same structure can amplify protection.

Every playable turn starts with only Begin and End. After Cast or Pass, permanent runes enter discard, temporary runes disappear and all connectors clear. The next turn supplies a normal hand and one random ten-piece kit, with no banking or guarantee of different cards. Endpoint positions change each turn and the player can Rotate them. The owner accepted the complete [production contract](production-rules-spec.md#october-9-2026--accepted-rc-007-implementation-contract) on October 9; RC-007 now implements it in normal gameplay, with final core/UI/rendered verification recorded.

## Run structure

The intended run lasts 15–25 minutes. Victories lead to rune choices, upgrades, or relics. A branching route includes normal encounters, dangerous encounters, shops, recovery, and events. Defeat the final guardian before losing all health. Save between encounters.

These progression systems are planned. The current implementation contains one repeatable training encounter.

The October 8 RC-002 [first-release specification](v1-design-spec.md) and [content roster](content-roster.md) make this direction concrete. Their new quantities and functional policies are **proposed working defaults**, not owner-approved requirements: one spellcaster/loadout and crypt theme; nine visited rooms within an 8–10 room budget; five enemies (three normal, one elite, one guardian); four boards; twelve permanent rune/technique definitions plus generated Free Spark; six relics, four events and eight single-rank upgrades. Shadeling is recommended as the introductory normal enemy, preserving the training fixture and reference silhouette.

Proposed flow: Home → New Run/Continue → route → room → rewards → guardian victory or defeat → results/Home. Start with eight cards (two each Spark, Shield, Focus and Conjure Spark), 30 health, three energy/draw, no relics and zero run-only Gold. There is no permanent power progression or second currency. Collection ownership survives encounter transfer; installed, hand, draw and discard are mutually exclusive battle locations of normal instances. Generated runes never become permanent collection cards.

The proposed offline English release saves room transactions and battle-entry checkpoints. An interrupted battle replays its committed entry state and seed; Menu Quit returns Home while preserving the active run. Menu Shop opens only the current unresolved shop room, and Home New Run confirms replacement of active progress. The specification defines invalid-save recovery, shared Options and the remaining screen states. None of this navigation is implemented by RC-002.

## Design principles

- Completing a circuit should feel understandable and satisfying.
- Branches must occupy real space; multiplication should compete with other useful effects.
- The player sees enemy intent before committing.
- Editing should encourage experimentation with free changes and undo.
- Card and technique combinations should support the circuit puzzle.
- Portrait touch controls should communicate through clear shapes, values, and feedback.

## Presentation

Original hand-painted cartoon fantasy art, with bold outlines, angular silhouettes, and restrained painted shading. The enemy stands in the center of a side-view arena without a visible player character. Below it sit player status, the board, wiring tools, compact rune choices, Cast, and bottom navigation.

Slay the Spire is a gameplay and presentation influence. Rune Cast uses its own name, characters, artwork, icons, and interface assets.

## Foundation scope

The foundation validates construction, casting, energy, enemy response, simple hand management, and navigation. It uses a placeholder enemy and environment. The approved visual reference establishes the production target rather than claiming that the prototype already has finished art.

Ordinary effect persistence, additional Split allowances/costs, alternate ports/board constraints, hit semantics, temporary expiry geometry and between-encounter circuit retention remain experiments for RC-005/RC-006. The earlier statement that the circuit remains between turns describes the current prototype only. RC-002 does not settle these rules or change [implemented gameplay rules](gameplay-rules.md). See the specification for acceptance gates, deferred features and external device/account/playtest prerequisites.

