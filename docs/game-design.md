# Rune Cast game description

Rune Cast is a portrait, turn-based spell-building roguelike for Android and iOS. A travelling spellcaster descends into a cursed tower, constructing attacks and protection from individual runes instead of choosing complete spells.

The central challenge is spatial: build a valid circuit between fixed Begin and End sockets, then use the space, connections, owned pieces, and energy budget to improve what the spell produces.

## Player experience

Enemies announce their next action. During preparation, the player draws a small hand, uses techniques, installs effect runes, and edits the circuit. Once every powered branch reaches End and the circuit is affordable, Cast releases the spell. A surviving enemy performs its announced action.

A Split copies the spell prepared upstream. Its branches occupy separate board cells. A Join combines their effects before End. For example, a 6 damage Spark followed by a Split and Join produces 12 total damage. The same structure can amplify protection.

The circuit remains between turns. The player can exploit a good arrangement and selectively rebuild it when the enemy's intent or available runes changes.

## Run structure

The intended run lasts 15–25 minutes. Victories lead to rune choices, upgrades, or relics. A branching route includes normal encounters, dangerous encounters, shops, recovery, and events. Defeat the final guardian before losing all health. Save between encounters.

These progression systems are planned. The current implementation contains one repeatable training encounter.

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

