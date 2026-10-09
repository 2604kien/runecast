extends RefCounted

# RC-007 preserves these historical assertions using the explicit legacy fixture.
# Production defaults are covered separately by production_*_tests.gd.

const Combat = preload("res://scripts/core/combat.gd")
const Controller = preload("res://scripts/ui/combat_controller.gd")
const Immediate = preload("res://scripts/ui/combat_presentation.gd")
const Delayed = preload("res://tests/delayed_presentation.gd")
const ContentLoader = preload("res://scripts/core/content_loader.gd")

func training_combat() -> Combat:
	return Combat.new(ContentLoader.load_setup(ContentLoader.LEGACY_ENCOUNTER).setup)

func types(result: Dictionary) -> Array:
	return result.events.map(func(event): return event.type)

func gameplay(game: Combat) -> Dictionary:
	var value := game.snapshot()
	value.erase("log_text") # Rejections retain the existing feedback behavior.
	value.rng_state = game.rng.state
	value.next_uid = game.next_uid
	value.history = game.history.duplicate(true)
	return value

func run(check: Callable) -> void:
	var game := training_combat()
	# Golden draw order from b373a8c under the pinned engine (including reset RNG continuation).
	check.call(game.draw_pile.map(func(card): return card.uid) == [7, 5, 8, 4, 6], "The seeded opening shuffle is unchanged from the RC-002 baseline.")
	game.cast()
	check.call(game.hand.map(func(card): return card.uid) == [6, 4, 8], "Opening cast preserves the baseline draw order.")
	game.pass_turn()
	check.call(game.hand.map(func(card): return card.uid) == [5, 7, 4], "Cross-pile draws and reshuffling preserve baseline RNG consumption.")
	game.reset()
	check.call(game.draw_pile.map(func(card): return card.uid) == [6, 8, 4, 7, 5], "Restart continues the RNG stream instead of reseeding it.")
	game = training_combat()
	var before := game.snapshot()
	var result := game.execute("cast")
	check.call(types(result) == ["cast", "damage", "shield", "retaliation", "temporary_expired", "turn_cleanup", "turn_started", "card_drawn", "card_drawn", "card_drawn"], "Opening cast exposes resolution, cleanup, refresh and draws in order.")
	check.call(result.accepted and result.before == before and result.after == game.snapshot(), "Action snapshots agree with authoritative before and final state.")
	var ordered := true
	for index in range(result.events.size()):
		var event: Dictionary = result.events[index]
		ordered = ordered and event.sequence == index and event.action_id == result.action_id and event.encounter_id == result.encounter_id
	check.call(ordered, "Each event has stable action/encounter identity and contiguous sequence.")
	check.call(result.events[0].spell.damage == 12 and result.events[0].spell.cost == 1 and result.events[0].energy_before == 3 and result.events[0].energy_after == 2, "Cast retains the resolved circuit and actual energy payment.")
	check.call(result.events[1].health_before == 32 and result.events[1].health_after == 20 and result.events[1].applied == 12 and result.events[3].health_after == 22, "Damage and retaliation amounts reconcile with health.")
	check.call(result.events[4].cell == 1 and result.events[4].before.uid == 0 and result.events[4].after == {"kind": "straight", "rotation": 0}, "Expiry identifies the old rune and exact replacement socket.")
	check.call(result.events[5].discarded == before.hand and result.events[6].turn_after == 2 and result.events[6].energy_before == 2 and result.events[6].energy_after == 3, "Cleanup preserves hand order and refresh follows it.")
	check.call(result.events.slice(7).map(func(event): return event.card) == game.hand, "Draw events identify the final hand in actual draw order.")
	var retained := result.duplicate(true)
	game.pass_turn()
	game.reset()
	check.call(result == retained, "Issued outcomes survive later actions and Reset unchanged.")
	var next := game.execute("cast")
	check.call(next.encounter_id > result.encounter_id and next.action_id > result.action_id, "Reset never reuses action identity despite restarting card UIDs.")
	var authoritative := gameplay(game)
	next.after.board[1].kind = "corrupted"
	next.before.hand[0].id = "corrupted"
	next.events[0].spell.active.clear()
	var exposed := game.snapshot()
	exposed.board.clear()
	exposed.hand.clear()
	exposed.catalog.spark.cost = 100
	exposed.encounter.intents.clear()
	var last := game.last_result()
	last.events.clear()
	check.call(gameplay(game) == authoritative and not game.last_result().events.is_empty(), "Nested snapshots, catalog, encounter and outcome copies cannot mutate model or retained results.")
	var replayed := [0]
	var immediate := Immediate.new()
	for count in range(2):
		immediate.present(result.duplicate(true), func(): replayed[0] += 1)
	check.call(replayed[0] == 2 and gameplay(game) == authoritative, "Consuming/replaying presentation cannot reapply model consequences.")

	game.reset()
	game.enemy_hp = 7
	result = game.execute("cast")
	check.call(types(result) == ["cast", "damage", "temporary_expired", "turn_cleanup", "battle_ended"], "Lethal cast cleans up before victory without shielding, retaliation or another turn.")
	check.call(result.events[1].amount == 12 and result.events[1].applied == 7 and game.player_hp == 30 and game.energy == 2 and game.turn == 1 and game.hand.is_empty(), "Overkill is clamped once and terminal turns retain spent energy/turn.")
	game.reset()
	game.place_rune(1, game.hand[1].uid)
	result = game.execute("cast")
	check.call(result.events[2].type == "shield" and result.events[2].amount == 10 and result.events[3].blocked == 8 and result.events[3].applied == 0 and game.player_hp == 30, "Shield resolves before fully blocked retaliation.")
	check.call(game.board[1].rune_id == "shield" and not types(result).has("temporary_expired"), "Ordinary installed runes persist after shielded casts.")
	game.reset()
	game.player_hp = 4
	result = game.execute("cast")
	check.call(types(result).back() == "battle_ended" and result.events.back().state == "defeat" and result.events[3].amount == 8 and result.events[3].applied == 4 and game.turn == 1, "Defeat clamps retaliation and stops before turn refresh.")
	game.reset()
	game.play_technique(game.hand[2].uid)
	var temporary: Dictionary = game.hand.back().duplicate(true)
	game.place_rune(12, temporary.uid)
	result = game.execute("pass")
	check.call(types(result).slice(0, 4) == ["passed", "retaliation", "temporary_expired", "temporary_expired"] and not types(result).has("cast") and not types(result).has("shield"), "Pass has no spell/shield and expires connected and disconnected temporary runes in socket order.")
	check.call(result.events[3].cell == 12 and game.enemy_hp == 32 and game.player_hp == 22 and game.energy == 3 and game.turn == 2, "Pass preserves enemy health and performs ordinary turn advancement.")
	game.reset()
	game.play_technique(game.hand[2].uid)
	temporary = game.hand.back().duplicate(true)
	result = game.execute("pass")
	check.call(result.events[3].type == "turn_cleanup" and result.events[3].expired == [temporary] and not (game.hand + game.discard_pile + game.draw_pile).any(func(card): return card.id == "free_spark"), "Unused hand temporaries are recorded as expired and never enter piles.")

	game.reset()
	game.place_wire(12, "straight")
	var conjure: Dictionary = game.hand[2].duplicate(true)
	result = game.execute("technique", {"uid": conjure.uid})
	check.call(types(result) == ["technique", "card_created"] and result.events[0].card == conjure and result.events[0].cost == 0 and result.events[0].undo_cleared == 1 and result.events[1].card == game.hand.back(), "Conjure uses the same outcome boundary with payment, committed edits and stable generated-card identity.")
	check.call(game.energy == 3 and game.history.is_empty() and game.discard_pile == [conjure], "Technique costs/discard/history commit occur exactly once.")
	game.reset()
	game.hand = [game._card("focus")]
	game.draw_pile.clear()
	game.discard_pile.clear()
	var focus: Dictionary = game.hand[0].duplicate(true)
	result = game.execute("technique", {"uid": focus.uid})
	check.call(types(result) == ["technique", "reshuffled", "card_drawn"] and game.hand == [focus] and game.energy == 2, "Focus discards before drawing and can recycle itself when the draw pile is empty.")
	check.call(result.events[1].cards == [focus] and result.events[2].card == focus and result.events[2].draw_remaining == 0, "Reshuffle and short draws report actual cards without extra RNG/draws.")

	game.reset()
	game.cast()
	game.energy = 0
	assert_rejected(check, game, "cast", {}, "Unaffordable cast")
	game.energy = 3
	game.place_wire(3, "erase")
	assert_rejected(check, game, "cast", {}, "Invalid circuit")
	assert_rejected(check, game, "technique", {"uid": -99}, "Missing technique")
	assert_rejected(check, game, "place_rune", {"index": 0, "uid": game.hand[0].uid}, "Fixed endpoint edit")
	assert_rejected(check, game, "unknown", {}, "Unknown command")
	game.reset()
	game.hand = [game._card("focus")]
	game.energy = 0
	assert_rejected(check, game, "technique", {"uid": game.hand[0].uid}, "Unaffordable technique")
	game.player_hp = 1
	game.pass_turn()
	assert_rejected(check, game, "pass", {}, "Terminal pass")
	assert_rejected(check, game, "cast", {}, "Terminal cast")
	_controller_checks(check)

func assert_rejected(check: Callable, game: Combat, command: String, arguments: Dictionary, label: String) -> void:
	var before := gameplay(game)
	var result := game.execute(command, arguments)
	check.call(not result.accepted and result.action_id == 0 and result.events.is_empty() and game.last_result().events.is_empty() and gameplay(game) == before, label + " preserves all gameplay/RNG/history and exposes no stale events.")

func _controller_checks(check: Callable) -> void:
	var game := training_combat()
	var presenter := Delayed.new()
	var controller := Controller.new(game, presenter)
	var weak_controller: WeakRef = weakref(controller)
	var changes := [0]
	controller.changed.connect(func(): changes[0] += 1)
	var reentrant := [true]
	controller.presentation_started.connect(func(batch):
		reentrant[0] = weak_controller.get_ref().command("pass")
		batch.after.board.clear()
	)
	check.call(controller.command("cast") and controller.is_busy() and not reentrant[0] and presenter.batches.size() == 1, "Presentation locks before signals and rejects reentrant resolution.")
	check.call(presenter.batches[0].after.board.size() == 16, "Each presentation consumer receives an independent batch.")
	var after := gameplay(game)
	var commands := [
		["cast", {}], ["pass", {}], ["technique", {"uid": game.hand[0].uid}],
		["place_wire", {"index": 3, "kind": "erase"}], ["place_rune", {"index": 1, "uid": game.hand[0].uid}],
		["rotate", {"index": 3}], ["flip", {"index": 3}], ["undo", {}]
	]
	var rejected := true
	for entry in commands:
		rejected = not controller.command(entry[0], entry[1]) and rejected
	check.call(rejected and gameplay(game) == after and presenter.batches.size() == 1, "Delayed presentation guards repeated Cast/Pass, techniques and every board mutation.")
	presenter.batches[0].events.clear()
	check.call(gameplay(game) == after and not game.last_result().events.is_empty(), "A delayed consumer cannot mutate model or recorded output.")
	presenter.complete(0)
	var change_count: int = changes[0]
	presenter.complete(0)
	check.call(not controller.is_busy() and controller.can_edit() and changes[0] == change_count, "Completion unlocks and notifies exactly once.")
	controller.command("pass")
	presenter.complete(0)
	check.call(controller.is_busy() and game.turn == 3, "A prior action's completion cannot unlock a newer action.")
	var cancel_reentry := [true]
	presenter.on_cancel = func(): cancel_reentry[0] = weak_controller.get_ref().command("cast")
	controller.restart()
	presenter.complete(1)
	check.call(not cancel_reentry[0] and not controller.is_busy() and game.turn == 1 and game.enemy_hp == 32 and presenter.cancellations == 1, "Restart invalidates callbacks before synchronous cancel and resets safely.")
	controller.command("technique", {"uid": game.hand[2].uid})
	check.call(controller.is_busy() and presenter.batches.back().command == "technique" and not controller.command("cast"), "Successful techniques wait for the same presentation completion.")
	presenter.complete(1)
	check.call(controller.is_busy(), "Pre-Restart completion cannot unlock a new encounter's technique.")
	after = gameplay(game)
	controller.cancel_presentation()
	presenter.complete(2)
	check.call(not controller.is_busy() and gameplay(game) == after and controller.can_edit(), "Cancellation unlocks without undoing or reapplying resolved gameplay.")
	controller.command("cast")
	after = gameplay(game)
	controller.dispose()
	change_count = changes[0]
	presenter.complete()
	check.call(not controller.is_busy() and not controller.can_edit() and not controller.restart() and not controller.command("pass") and changes[0] == change_count and gameplay(game) == after, "Disposal cancels pending work; late callbacks and commands cannot update a closed encounter.")
	# Release deliberately retained test closures before dropping the controller.
	presenter.on_cancel = Callable()
	controller = null
	check.call(weak_controller.get_ref() == null, "Retained presentation completions do not keep their controller alive.")
	presenter.complete()
	controller = Controller.new(training_combat())
	controller.command("place_wire", {"index": 3, "kind": "erase"})
	check.call(not controller.command("cast") and not controller.is_busy() and controller.can_edit(), "Rejected actions never strand input.")
	controller.restart()
	check.call(controller.command("cast") and not controller.is_busy() and controller.snapshot().player_hp == 22, "Immediate presenter completes synchronously with preserved opening gameplay.")
	for operation in ["restart", "cancel_presentation"]:
		game = training_combat()
		presenter = Delayed.new()
		controller = Controller.new(game, presenter)
		var disposal_target: WeakRef = weakref(controller)
		var disposal_changes := [0]
		controller.changed.connect(func(): disposal_changes[0] += 1)
		presenter.on_cancel = func(): disposal_target.get_ref().dispose()
		controller.command("cast")
		after = gameplay(game)
		change_count = disposal_changes[0]
		controller.call(operation)
		presenter.complete()
		check.call(presenter.cancellations == 1 and gameplay(game) == after and disposal_changes[0] == change_count and not controller.can_edit(), "Teardown during " + operation + " cancels once and cannot reset or emit after disposal.")
