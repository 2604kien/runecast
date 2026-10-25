# RC-033 excluded enemy phase framework

This is a framework fixture, not delivered Bell Keeper content or production balance. It is registered only by `tests/helpers/rc033_fixture.gd`, through the ordinary validated content loader and Combat/controller/view. Production encounter registration and all RC-032 fixtures remain unchanged. All files under `tests` and this launch helper remain excluded from resource packages.

Enemy: **80 HP; 8 / 12 / 16 repeating; at 40 HP or less, next surviving turn begins 12 / 16 / 20 repeating**. Player: **400 HP, 20 energy each turn, eight opening/turn draws, six Spark and two Shield**, normal random endpoints and connector kits. These resources are explicit fixture configuration, never injected during play.

From `C:\Dev\RuneCast`:

```powershell
.\tools\rc033_fixture.ps1
.\tools\rc033_fixture.ps1 -AtThreshold -Narrow
```

The launcher uses pinned Godot 4.7.2 and isolated APPDATA/LOCALAPPDATA/settings. `-AtThreshold` performs two ordinary Passes and six legal single-Spark Casts, then prepares the seventh circuit. At turn 9 the enemy has 44 HP, the player has 308 HP and 16 is announced. Tap the attack to inspect, close, then Cast: enemy reaches 38, original 16 retaliates, and phase two starts at 12. Pass three times to see 16, 20, 12. Seven more one-Spark Casts finish with six requested damage/two actual HP loss and no final retaliation. `-ReducedMotion` uses the existing reduced animation policy. Menu Exact replay reconstructs the entry; Resume retains preparation.

For the full manual route from entry, Pass twice and build seven single-Spark circuits (6 damage each, no Shield) before the phase-two steps above. Rotations, current hand and kits use normal controls. [Recorded legal paths/commands](../../../output/qa/rc-033/ui/legal-walkthrough.json) use zero-based row-major cells. No automatic player is attached during normal play.

The separate `rc033_lifecycle_fixture.gd` uses a validated **74 HP threshold** with the ordinary 30 HP/eight-card run starter solely to test phase persistence and fresh-process replay early in a legal battle. It does not replace the required 40 HP playable fixture or register any production enemy. [Full verification and RC-034 interface](../../../docs/rc-033-verification.md).
