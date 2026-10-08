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

These defaults allow playtesting. They are not claims that balance or the full game's rules are final.

## RC-002 proposed release defaults — October 8, 2026

The owner confirmed RC-001 complete; its checkpoint is `64930fc` (`Initial commit`). RC-002 defines a release proposal in [v1-design-spec.md](v1-design-spec.md) and [content-roster.md](content-roster.md). It does not implement gameplay or confer owner approval on new functional decisions.

| Proposal | Reason and owning task |
| --- | --- |
| Retain the original content budget; default nine rooms inside 8–10 | One loadout/theme, five enemies, four boards, twelve permanent definitions plus Free Spark, six relics/four events/eight single-rank upgrades keeps production bounded. RC-009/RC-034–RC-036 author it; RC-045 measures the 15–25 minute target. |
| Shadeling is an introductory normal enemy | Reuses the training encounter and first style pilot; simple telegraphed attacks teach circuits. The reference's BOSS label is illustrative. A separate guardian supplies the climax. Preserve `training_shadeling` and existing `shadeling` asset ID. RC-014/RC-034. |
| One local active run; offline English; no persistent power progression | Start each run with the existing eight-card loadout, 30 health, three energy/draw, zero relics/Gold. Gold is run-only. No extra currency/account system. RC-024/RC-036. |
| Interrupted combat replays the committed battle entry | Avoid partial-turn serialization while preserving completed-room progress and seeded offers. Save terminal outcomes and room transactions exactly once. RC-028/RC-047. |
| Menu Quit returns Home and keeps progress | Confirm loss of current battle preparation/replay when relevant. Separate confirmed Abandon action belongs in Map run details. RC-032. |
| Menu Shop is available only in the current unresolved shop room | Preserves route/economy choices and the four approved menu buttons. Elsewhere disabled with explanation; no global or real-money store. RC-029/RC-032. |
| Shared Options and explicit Home save states | Same audio/reduced-motion preferences from Home/Menu; no-save, valid-save and invalid-save states; confirm New Run replacing progress. RC-020/RC-028/RC-032/RC-044. |
| Separate Home tower illustration and in-game logo | RC-015 produces Home art alongside crypt layers, RC-013 produces logo/theme, RC-041 parchment/map art; RC-032/RC-042 integrate. RC-051 handles final distribution identity. Detailed manifest remains RC-010. |

The [external prerequisite register](v1-design-spec.md#external-prerequisites-and-owner-inputs) records unknown Android devices, Mac/Xcode/iOS devices, distribution/signing access, production identity/IDs and human participants with task owners. Unknown access does not block RC-002. Exact OS/device support is selected during RC-021/RC-022, not inferred from the desktop preview. Trailer, translation, extra music/biomes/characters and other expansion features are deferred as specified.

## Questions reserved for RC-005/RC-006

| Decision | Current prototype / outstanding choice |
| --- | --- |
| Persistent versus consumed effect runes | Ordinary effects currently persist; compare cast consumption and its destination without deleting run ownership. |
| Additional Split limits and costs | One Split/Join, Split costs 1 per cast today; extra inventory and costs are undecided. |
| Alternate effect ports and board constraints | Fixed endpoints and straight effect ports, no obstacles today; compare variants and known valid solutions. |
| Single-hit versus multi-hit | One aggregate hit today; no hit-count/targeting/status system is authorized by the roster. |
| Temporary-rune expiry geometry | Installed temporaries become straight wire with current rotation today; alternate-port cleanup needs evidence. |
| Reset versus retain circuit between encounters | No progression today. Reset board/retain collection is an earlier **planned default**, still undecided; compare paired encounters before implementation. |

The [experiment matrix](v1-design-spec.md#experiments-deliberately-left-open) records affected content, evidence and ownership for all six. RC-005 builds controlled scenarios, RC-006 records human evidence and decides, RC-007 implements. Stable roster IDs describe useful roles under either outcome; new effect types and relic hooks require explicit implementation, not JSON alone. Inspection and safe areas are assigned to RC-008/RC-044 and device tasks.

## Changes that need playtesting

The biggest remaining design risk is a standard layout that puts every effect before Split. A split limit controls scaling but does not solve layout repetition. Test varying board obstacles, endpoints, effect ports, and enemy demands before adding more currencies or arbitrary restrictions.


## RC-005 candidates available — October 9, 2026

The [controlled experiment harness](circuit-experiments.md) implements provisional alternatives for all six reserved questions: effect lifetime, extra Split allowance/cost, alternate endpoints/blocked cells/effect ports, damage-hit representation, temporary expiry geometry, and reset/retain transfer. It provides matched seeds, known solutions, local records and a human protocol. These are executable candidates, not owner-approved production rules. All six decisions remain **pending RC-006 human evidence**; automated checks establish behavior and reproducibility only. RC-007 implements subsequent selected rules. Existing normal gameplay defaults remain unchanged.
