extends RefCounted
## Audio observations must preserve the production presentation's authority,
## ordering, pacing and cancellation. These fixtures use real resolved actions.
const Combat = preload("res://scripts/core/combat.gd")
const Loader = preload("res://scripts/core/content_loader.gd")
const Controller = preload("res://scripts/ui/combat_controller.gd")
const Animated = preload("res://scripts/ui/animated_combat_presentation.gd")
const Style = preload("res://scenes/vfx/combat_feedback_style.tres")
const Motion = preload("res://assets/enemies/shadeling/motion.tres")

class InstantPresentation extends Animated:
	func _event_seconds(_event: Dictionary) -> float:
		return 0.0

func run(check: Callable) -> void:
	for reduced in [false, true]:
		_milestones(check, reduced)
	_zero_duration(check)
	_metadata(check)
	_reentrant_cancellation(check)
	_command_observations(check)
	_controller_lifecycle(check)

func _game() -> Combat:
	var setup: Dictionary = Loader.load_setup().setup.duplicate(true)
	setup.erase("next_encounter")
	setup.encounter.player_health = 1000
	setup.encounter.player_max_health = 1000
	setup.encounter.max_health = 1000
	return Combat.new(setup)

func _trace(presenter: Animated, trace: Array) -> void:
	var owner: WeakRef = weakref(presenter)
	presenter.phase_started.connect(func(notice): trace.append({"kind": "start", "notice": notice.duplicate(true)}))
	presenter.contact_reached.connect(func(notice): trace.append({"kind": "contact", "notice": notice.duplicate(true)}))
	presenter.event_presented.connect(func(event):
		var current = owner.get_ref()
		trace.append({"kind": "commit", "event": event.duplicate(true), "elapsed": current.elapsed, "snapshot": current.visual_snapshot()})
	)

func _milestones(check: Callable, reduced: bool) -> void:
	var game := _game()
	var result := game.execute("pass")
	var authoritative := game.snapshot()
	var rng_state := [game.rng.state, game.endpoint_rng.state, game.kit_rng.state]
	var presenter := Animated.new()
	presenter.reduced_motion = reduced
	var trace: Array = []
	_trace(presenter, trace)
	presenter.phase_started.connect(func(notice): notice.event.clear())
	presenter.contact_reached.connect(func(notice): notice.event.clear())
	var completions := [0]
	presenter.present(result, func(): completions[0] += 1)
	check.call(trace.size() == 1 and trace[0].kind == "start" and trace[0].notice.event.type == "passed"
		and trace[0].notice.phase_progress == 0.0, "RC-020 announces the initial zero-duration phase exactly when it enters.")
	presenter.advance(0.0)
	var attack_seconds: float = Style.reduced_seconds if reduced else Style.attack_seconds
	var contact_seconds := attack_seconds * float(Motion.attack_contact)
	presenter.advance(contact_seconds - 0.00001)
	check.call(trace.filter(func(item): return item.kind == "contact").is_empty(),
		"RC-020 never announces actor contact before the metadata fraction (reduced=%s)." % reduced)
	presenter.advance(0.00002)
	var contacts := trace.filter(func(item): return item.kind == "contact")
	check.call(contacts.size() == 1 and is_equal_approx(contacts[0].notice.elapsed, contact_seconds)
		and is_equal_approx(contacts[0].notice.phase_progress, Motion.attack_contact)
		and contacts[0].notice.sequence == 1 and contacts[0].notice.action_id == result.action_id
		and contacts[0].notice.encounter_id == result.encounter_id and contacts[0].notice.reduced_motion == reduced,
		"RC-020 contact reports detached action/encounter/event identity and exact presentation time (reduced=%s)." % reduced)
	check.call(presenter.visual_snapshot().player_hp == result.before.player_hp,
		"RC-020 contact occurs before the staged retaliation consequence commits.")
	presenter.advance(1000.0)
	var settled_count := trace.size()
	presenter.advance(1000.0)
	presenter.finish()
	var starts := trace.filter(func(item): return item.kind == "start")
	var commits := trace.filter(func(item): return item.kind == "commit")
	check.call(starts.map(func(item): return item.notice.event) == result.events
		and commits.map(func(item): return item.event) == result.events
		and trace.filter(func(item): return item.kind == "contact").size() == 1
		and trace.size() == settled_count and completions[0] == 1,
		"RC-020 a large advance emits each start, contact and committed event once in order (reduced=%s)." % reduced)
	var ordered := true
	for index in range(result.events.size()):
		var start_index := trace.find(starts[index])
		var commit_index := trace.find(commits[index])
		ordered = ordered and start_index < commit_index
		if index > 0: ordered = ordered and trace.find(commits[index - 1]) < start_index
		if result.events[index].type == "retaliation":
			ordered = ordered and start_index < trace.find(contacts[0]) and trace.find(contacts[0]) < commit_index
			ordered = ordered and commits[index].snapshot.player_hp == result.events[index].health_after
	check.call(ordered, "RC-020 phase/contact/commit observations preserve the ordered visual consequence boundary.")
	check.call(game.snapshot() == authoritative and [game.rng.state, game.endpoint_rng.state, game.kit_rng.state] == rng_state
		and presenter.visual_snapshot() == result.after and is_equal_approx(presenter.elapsed, presenter.duration),
		"RC-020 notifications neither alter outcomes/RNG nor add presentation time.")

func _zero_duration(check: Callable) -> void:
	var result := _game().execute("pass")
	var presenter := InstantPresentation.new()
	var trace: Array = []
	_trace(presenter, trace)
	var completions := [0]
	presenter.present(result, func(): completions[0] += 1)
	presenter.advance(0.0)
	presenter.advance(0.0)
	var starts := trace.filter(func(item): return item.kind == "start")
	var contacts := trace.filter(func(item): return item.kind == "contact")
	var commits := trace.filter(func(item): return item.kind == "commit")
	check.call(starts.size() == result.events.size() and commits.size() == result.events.size() and contacts.size() == 1
		and completions[0] == 1 and presenter.elapsed == 0.0 and presenter.duration == 0.0,
		"RC-020 zero-duration events drain at advance(0), including exactly one instantaneous contact.")
	check.call(trace.find(starts[1]) < trace.find(contacts[0]) and trace.find(contacts[0]) < trace.find(commits[1])
		and contacts[0].notice.elapsed == 0.0 and presenter.visual_snapshot() == result.after,
		"RC-020 zero-duration contact remains between phase start and staged commit without extra pacing.")

func _metadata(check: Callable) -> void:
	var result := _game().execute("pass")
	var presenter := Animated.new()
	var contacts: Array = []
	presenter.contact_reached.connect(func(notice): contacts.append(notice.duplicate(true)))
	var original: float = Motion.attack_contact
	Motion.set("attack_contact", 0.63)
	presenter.present(result, Callable())
	presenter.advance(0.0)
	Motion.set("attack_contact", original)
	presenter.finish()
	check.call(contacts.size() == 1 and is_equal_approx(contacts[0].phase_progress, 0.63)
		and is_equal_approx(contacts[0].elapsed, 0.63 * Style.attack_seconds),
		"RC-020 contact comes from editable actor metadata captured on phase entry, not a hard-coded delay/fraction.")
	presenter = Animated.new()
	contacts.clear()
	result.before.encounter.enemy_id = "unknown_test_actor"
	presenter.contact_reached.connect(func(notice): contacts.append(notice))
	presenter.present(result, Callable())
	presenter.finish()
	check.call(contacts.is_empty(), "RC-020 an unknown actor receives no invented contact metadata.")

func _reentrant_cancellation(check: Callable) -> void:
	for boundary in ["phase_started", "contact_reached", "event_presented"]:
		var game := _game()
		var result := game.execute("pass")
		var authoritative := game.snapshot()
		var presenter := Animated.new()
		var trace: Array = []
		_trace(presenter, trace)
		var owner: WeakRef = weakref(presenter)
		var cancellations: Array = []
		var completions := [0]
		presenter.presentation_cancelled.connect(func(notice): cancellations.append(notice.duplicate(true)))
		presenter.connect(boundary, func(_notice): owner.get_ref().cancel())
		presenter.present(result, func(): completions[0] += 1)
		presenter.advance(1000.0)
		var count := trace.size()
		presenter.advance(1000.0)
		presenter.cancel()
		check.call(not presenter.is_active() and trace.size() == count and cancellations.size() == 1 and completions[0] == 0
			and cancellations[0].action_id == result.action_id and game.snapshot() == authoritative,
			"RC-020 reentrant cancellation at %s invalidates old milestones/completion exactly once." % boundary)
	var game := _game()
	var first := game.execute("pass")
	var second := game.execute("pass")
	var third := game.execute("pass")
	var presenter := Animated.new()
	var owner: WeakRef = weakref(presenter)
	var finished := [0]
	presenter.present(first, Callable())
	presenter.presentation_cancelled.connect(func(_notice): owner.get_ref().present(third, func(): finished[0] += 1), CONNECT_ONE_SHOT)
	presenter.present(second, Callable())
	presenter.finish()
	check.call(finished[0] == 1 and presenter.visual_snapshot() == third.after,
		"RC-020 a reentrant replacement from cancellation cannot be overwritten by the abandoned outer present call.")

func _command_observations(check: Callable) -> void:
	var game := Combat.new(Loader.load_setup(Loader.LEGACY_ENCOUNTER).setup)
	var controller := Controller.new(game)
	var outcomes: Array = []
	var order: Array = []
	controller.command_resolved.connect(func(outcome):
		outcomes.append(outcome.duplicate(true))
		order.append("outcome")
		outcome.arguments.clear()
		if outcome.result.has("after"): outcome.result.after.board.clear()
	)
	controller.changed.connect(func(): order.append("changed"))
	var arguments := {"index": 3, "kind": "erase", "detail": {"target": 3}}
	check.call(controller.command("place_wire", arguments), "RC-020 accepted Remove retains the existing successful command result.")
	check.call(outcomes.size() == 1 and outcomes[0].arguments == arguments and outcomes[0].accepted
		and outcomes[0].result.events.is_empty() and order == ["outcome", "changed"]
		and game.snapshot().board.size() == 16 and arguments.detail.target == 3,
		"RC-020 accepted edits publish detached actual arguments/target before refresh, without inventing presentation events.")
	for iteration in 10:
		controller.can_edit()
		controller.snapshot()
		controller.display_snapshot()
	check.call(outcomes.size() == 1, "RC-020 passive snapshots and availability checks emit no command feedback.")
	check.call(not controller.command("unknown", {"index": 7}) and outcomes.size() == 2
		and not outcomes[1].accepted and outcomes[1].arguments.index == 7,
		"RC-020 an explicit rejected attempt publishes its actual command target once.")
	controller = Controller.new(_game(), Animated.new())
	outcomes.clear()
	controller.command_resolved.connect(func(outcome): outcomes.append(outcome.duplicate(true)))
	controller.command("pass")
	controller.command("rotate", {"index": 7})
	check.call(outcomes.size() == 2 and outcomes[0].accepted and not outcomes[1].accepted
		and outcomes[1].reason == "busy" and outcomes[1].arguments.index == 7 and outcomes[1].result.is_empty(),
		"RC-020 a guarded explicit attempt reports its rejection without a fabricated model outcome.")
	controller.dispose()
	game = _game()
	controller = Controller.new(game, Animated.new())
	var owner: WeakRef = weakref(controller)
	var batches: Array = []
	controller.presentation_started.connect(func(result): batches.append(result))
	controller.command_resolved.connect(func(_outcome): owner.get_ref().dispose())
	check.call(controller.command("pass") and batches.is_empty() and not controller.is_busy() and game.turn == 2,
		"RC-020 disposal from a confirmed command callback preserves resolution and prevents obsolete presentation dispatch.")

func _controller_lifecycle(check: Callable) -> void:
	var presenter := Animated.new()
	var controller := Controller.new(_game(), presenter)
	var order: Array = []
	controller.presentation_invalidated.connect(func(notice): order.append(notice.reason))
	presenter.presentation_cancelled.connect(func(_notice): order.append("presenter_cancelled"))
	controller.command("pass")
	controller.restart()
	check.call(order == ["restart", "presenter_cancelled"] and not presenter.is_active(),
		"RC-020 Restart invalidates the owner before cancelling the old active presentation.")
	order.clear()
	var replacement := Animated.new()
	controller.presenter_changed.connect(func(current): order.append("new_presenter" if current == replacement else "wrong_presenter"))
	check.call(controller.set_presenter(replacement) and order == ["presenter_replaced", "new_presenter"]
		and controller.get_presenter() == replacement,
		"RC-020 accepted presenter replacement invalidates old subscriptions before exposing its new presenter.")
	order.clear()
	controller.dispose()
	check.call(order == ["dispose"], "RC-020 idle disposal still invalidates audio tails and future subscription work.")
