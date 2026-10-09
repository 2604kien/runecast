extends SceneTree

# RC-007 preserves these historical assertions using the explicit legacy fixture.
# Production defaults are covered separately by production_*_tests.gd.
const Circuit = preload("res://scripts/core/circuit.gd")
const Combat = preload("res://scripts/core/combat.gd")
const ContentLoader = preload("res://scripts/core/content_loader.gd")
var failures := 0
var checks := 0

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)

func _initialize() -> void:
	var game := Combat.new(ContentLoader.load_setup(ContentLoader.LEGACY_ENCOUNTER).setup)
	var result := game.forecast()
	check(result.valid and result.damage == 12 and result.cost == 1, "Reference circuit doubles the temporary Spark for one energy.")
	var board := game.board.duplicate(true)
	board[7] = {}
	check(not Circuit.evaluate(board, game.catalog).valid, "A dangling split branch prevents casting.")
	board = game.board.duplicate(true)
	board[10].rotation = 1
	check(not Circuit.evaluate(board, game.catalog).valid, "A misoriented join prevents casting.")
	board = game.board.duplicate(true)
	board[12] = {"kind": "rune", "rotation": 0, "rune_id": "spark", "uid": 999}
	result = Circuit.evaluate(board, game.catalog)
	check(result.valid and result.damage == 12 and result.cost == 1, "Disconnected runes do not contribute or cost energy.")
	board = game.board.duplicate(true)
	board[1].rune_id = "shield"
	result = Circuit.evaluate(board, game.catalog)
	check(result.valid and result.damage == 0 and result.shield == 10 and result.cost == 2, "Split copies shielding as well as damage.")
	var cycle_board := Circuit.empty_board()
	cycle_board[5] = {"kind": "corner", "rotation": 3}
	cycle_board[6] = {"kind": "corner", "rotation": 0}
	cycle_board[10] = {"kind": "corner", "rotation": 1}
	cycle_board[9] = {"kind": "corner", "rotation": 2}
	var context := {"visiting": {}, "visited": {}, "order": [], "parents": {}, "error": ""}
	Circuit._visit(5, cycle_board, context)
	check(context.error != "", "Directed loops are detected without infinite traversal.")
	check(game.cast(), "A valid affordable spell casts.")
	check(game.enemy_hp == 20 and game.player_hp == 22 and game.turn == 2, "Damage, enemy attack, and turn advance resolve in order.")
	check(game.board[1].kind == "straight", "A temporary rune expires into a wire.")
	check(game.hand.size() == 3 and game.energy == 3, "The next turn refreshes energy and draws three.")
	game.reset()
	game.enemy_hp = 12
	game.cast()
	check(game.state == "victory" and game.player_hp == 30, "Lethal spell damage prevents the enemy attack.")
	game.reset()
	game.energy = 0
	check(not game.cast() and game.enemy_hp == 32 and game.player_hp == 30, "An unaffordable cast changes no combat state.")
	game.reset()
	check(not game.place_wire(0, "corner") and not game.rotate(14), "Fixed endpoints cannot be edited.")
	check(not game.place_wire(4, "split"), "Owned piece supply limits placement.")
	var original := game.board.duplicate(true)
	game.place_wire(3, "straight")
	game.undo()
	check(game.board == original, "Undo restores the previous circuit.")
	game.reset()
	var spark_uid: int = game.hand[0].uid
	game.place_rune(1, spark_uid)
	check(game.forecast().cost == 3 and game.forecast().damage == 12, "Physical rune mana is counted once, despite its copied output.")
	game.cast()
	check(game.board[1].kind == "rune" and game.board[1].rune_id == "spark", "Ordinary runes remain installed after a cast.")
	game.reset()
	var conjure_uid: int = game.hand[2].uid
	check(game.play_technique(conjure_uid), "Conjure is playable from hand.")
	check(game.energy == 3 and game.discard_pile.size() == 1 and game.hand.back().id == "free_spark", "Conjure creates a temporary free rune and goes to discard.")
	game.pass_turn()
	var has_temporary := false
	for card in game.discard_pile + game.draw_pile + game.hand:
		has_temporary = has_temporary or card.id == "free_spark"
	check(not has_temporary, "Unused temporary runes never enter the deck.")
	game.reset()
	game.hand = [game._card("focus")]
	check(game.play_technique(game.hand[0].uid) and game.energy == 2 and game.hand.size() == 2, "Focus pays immediately and draws two.")
	game.reset()
	game.player_hp = 1
	game.pass_turn()
	check(game.state == "defeat" and not game.cast(), "Defeat prevents further casts.")
	var corner := {"kind": "corner", "rotation": 0, "reversed": true}
	check(Circuit.ports(corner).input == [2] and Circuit.ports(corner).output == [3], "Wire reversal permits both elbow directions.")
	preload("res://tests/combat_presentation_tests.gd").new().run(check)
	preload("res://tests/content_loading_tests.gd").new().run(check)
	preload("res://tests/combat_configuration_tests.gd").new().run(check)
	preload("res://tests/experiment_combat_tests.gd").new().run(check)
	preload("res://tests/experiment_content_tests.gd").new().run(check)
	preload("res://tests/full_reset_tests.gd").new().run(check)
	preload("res://tests/moving_endpoint_tests.gd").new().run(check)
	preload("res://tests/free_endpoint_tests.gd").new().run(check)
	preload("res://tests/experiment_record_tests.gd").new().run(check)
	preload("res://tests/production_rules_tests.gd").new().run(check)
	preload("res://tests/connector_geometry_tests.gd").new().run(check)
	preload("res://tests/production_content_tests.gd").new().run(check)
	preload("res://tests/production_combat_tests.gd").new().run(check)
	print("%d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

