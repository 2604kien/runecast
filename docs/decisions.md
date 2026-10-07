# Rune Cast decisions

## Explicit direction

- Name: Rune Cast.
- Engine: Godot.
- Platforms: Android and iOS, confirmed October 7, 2026.
- Portrait presentation and a 4 by 4 board.
- Connected Begin and End sockets are required to cast.
- Splitting and rejoining can amplify an attack.
- Strong deckbuilding influence, including generated free runes and hand techniques.
- Hand-painted cartoon art with a Slay the Spire-like encounter presentation.
- Center the full-body enemy and omit the player character.
- Give the encounter substantial vertical room.
- Compact rune choices show name, symbol, and value.
- Remove the separate forecast bar above Cast.
- Bottom navigation: Menu, Map, Guide, Sound.
- Final visual references for Home, Combat, Map, and Menu approved October 8, 2026; see [visual-reference.md](visual-reference.md). These supersede earlier visual drafts.
- Menu overlay: Resume, Options, Shop, Quit; Quit matches the navy Options and Shop buttons.
- Map uses a branching parchment route without the encounter legend strip.
- Home composition: moonlit tower with Continue, New Run, Options.

## Working defaults used in the foundation

- Godot 4.7.2 Standard, GDScript, Compatibility renderer.
- Three energy per turn and three cards drawn per turn.
- One Split and one Join initially; basic wires unlimited.
- Split costs one energy each cast.
- Editing is free and ordinary installed runes persist.
- Techniques resolve immediately from the hand.
- Temporary runes expire into their straight connector.
- The tutorial starts with a complete circuit and a curated first hand.
- Both branches must complete, joins require both inputs, and loops are invalid.
- A single combined damage total is released at End.
- Replacing an installed rune returns it to hand during preparation.
- A directional wire can be flipped as well as rotated.
- Reset the board between future encounters while retaining the player's collection; this is a planned rule, not implemented progression.

These defaults allow playtesting. They are not claims that balance or the full game's rules are final.

## Questions for later milestones

| Decision | Why it matters |
| --- | --- |
| Permanent effects versus effects consumed after each cast | Determines the importance of new hands and how often circuits change |
| Additional Split pieces and their limits | Determines whether repeated multiplication dominates builds |
| Different port shapes on effect runes | May create more meaningful spatial choices |
| Damage as one hit versus several copies | Affects armour, on-hit effects, and targeting |
| Production application identifiers and studio name | Needed before distributable mobile builds |
| iOS signing team and access to a Mac | Needed for device builds and distribution |
| Mobile long-press inspection and safe areas | Needed before touch-device acceptance |
| Reset versus retain a core circuit between encounters | Affects run pacing and ownership |

## Changes that need playtesting

The biggest remaining design risk is a standard layout that puts every effect before Split. A split limit controls scaling but does not solve layout repetition. Test varying board obstacles, endpoints, effect ports, and enemy demands before adding more currencies or arbitrary restrictions.

