# RC-032 excluded development tower

This fixture preserves the nine-visit route and its branch links: three normal
rooms, one event, the normal/elite alternative, the designated depth-six
Shadeling boss, one shop, one recovery and a distinct depth-nine guardian.
The normal path chooses Lost Satchel; the elite path chooses Sealed Reliquary.
Both paths can be selected manually in the same authored graph.

All encounters enter through the ordinary route and Combat owners. The three
explicit calibration definitions in this directory are development content,
not delivered Wickling, Stone Sentinel, Chain Warden or Bell Keeper content.
Shadeling uses its unchanged production encounter and stats. The ordinary
eight-card starter, 30/30 HP and zero initial Gold are unchanged. Each calibration
normal/elite victory offers a skippable rune and **250 fixture Gold**; these are
explicit deterministic fixture rules, not production economy. Gold is claimed
through real reward transactions. Nothing injects resources after launch.

The `--variant=normal` and `--variant=elite` manual commands select separate
save/settings slots and tell the player which depth-five branch to choose;
they do not choose rooms automatically. Their isolated profile starts with
Spark and Shield unlocked, leaving legitimate Focus/Conjure definition awards
at Shadeling and the guardian. The owned eight-card starter remains unchanged.
`--exhausted` starts with all four definitions unlocked, so both milestones
record exhausted pools with zero award and zero compensation. Subsequent
New Runs retain whichever unlocks were actually committed in that slot.

Launch the pinned engine from the workspace with isolated APPDATA/LOCALAPPDATA:

```powershell
& '.tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe' --path C:\Dev\RuneCast --script res://tests/rc032_manual.gd -- --variant=normal
```

Add `--save-root=C:/Dev/RuneCast/output/qa/rc-032/request-review/manual`
after `--` to keep a fresh walkthrough separate from older manual slots. The
variant and award-pool name remain subdirectories of that root. Without the
option, the established `output/qa/rc-032/manual` slots are preserved.

Choose Home → New Run; inspect and explicitly enter each room, play the
battles, resolve the event, buy a rune/relic and upgrade a physical UID in the
shop, then recover before the guardian. Every room completion and final award
uses the existing APIs. Guardian result acknowledgement and reward resolution
are separate; final victory waits for all required choices. Home, Continue,
Quit, abandonment, Options and New Run use the application's actual screens.

For the exact seed-42 verified paths, normal starts at the right-hand opening
node (`d1b`, leading to Satchel), then chooses the left-hand depth-four and
normal depth-five nodes. Elite starts at the left-hand opening (`d1a`, leading
to Reliquary), chooses the left-hand depth-four node, then the elite at depth
five. Both converge on Shadeling → shop → recovery → calibration guardian.

The accepted separate Store is available through **Map → Menu → Store** between
fully settled rooms. Initial zero-Gold browsing is allowed. Active rooms,
interrupted entry, pending results/rewards and terminal runs block Store access.
Win and fully settle a calibration battle to fund a purchase through real reward
transactions: runes cost **45 run Gold** and relics **90 run Gold**, with one rune
and one relic purchase independently allowed per run. The fixed catalogue uses
permanently unlocked supported rune definitions and the six supported relics.
Rune copies get fresh rank-zero UIDs; relics stay unique across all sources.
Purchases and allowances persist through Home/Continue/restart and reset on New
Run, while permanent unlocks and settings remain. Purchase cancellation changes
nothing; an injected save failure retains the identical candidate for Retry.
The actual depth-seven route shop has separate allowances and supports the
later upgrade/removal services. Its purchases do not consume Store allowances.
The ordinary shell provides Store access; no test-specific switch is used.

`tests/rc032_store_shell_runner.gd` verifies normal and elite nine-visit routes
with Store transactions at 450×1000 and 360×640. Use
`-- --output-root=res://output/qa/rc-032-store-accepted/ui` for fresh evidence;
add `--capture-rc032-store` after `--` for actual renderer screenshots. The
accepted contract preserves run v6 and the `rc032_store_v1` receipt policy.

`tests/rc032_route_runner.gd` runs both branch alternatives with both genuine
and exhausted permanent award pools, using legal actions selected by the
existing `encounter_player.gd`. `tests/helpers/rc032_route_fixture.gd` exposes
`play_to_guardian_pending(subject, branch)` for independent lifecycle/process
tests. It performs every preceding visit and battle; it does not teleport,
auto-win, fabricate visits or edit resources.

All files under `tests/` and QA artifacts remain excluded from release packs.
The fixture does not establish production tower completion or final balance.
