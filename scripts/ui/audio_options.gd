extends Control
## Reusable Options surface. The screen owner supplies values and persistence;
## rebinding values never emits a setting change or previews an audio cue.
const Ui = preload("res://scenes/ui/theme/components.gd")
signal setting_changed(key: String, value: Variant)
signal close_requested

var panel: PanelContainer
var body_scroll: ScrollContainer
var close_button: Button
var toggles: Dictionary = {}
var sliders: Dictionary = {}
var _slider_rows: Dictionary = {}
var _values: Dictionary = {}
const TOGGLE_LABELS := {"enabled": "Sound", "music_muted": "Music muted", "sfx_muted": "SFX muted", "reduced_motion": "Reduced motion"}
const SLIDER_LABELS := {"music_volume": "Music volume", "sfx_volume": "SFX volume"}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 110
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.025, 0.045, 0.9)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	panel = Ui.modal("Options", "", 312, 430)
	add_child(panel)
	body_scroll = panel.get_meta("rc_body_scroll")
	var placeholder := body_scroll.get_child(0)
	body_scroll.remove_child(placeholder)
	placeholder.queue_free()
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	body_scroll.add_child(body)
	for key in ["enabled", "music_volume", "music_muted", "sfx_volume", "sfx_muted", "reduced_motion"]:
		if SLIDER_LABELS.has(key):
			var row := Ui.settings_slider(SLIDER_LABELS[key], 100)
			body.add_child(row)
			var slider: HSlider = row.get_meta("rc_slider")
			sliders[key] = slider
			_slider_rows[key] = row
			slider.value_changed.connect(func(value: float): setting_changed.emit(key, value / 100.0))
		else:
			var toggle := Ui.settings_toggle(TOGGLE_LABELS[key], false)
			body.add_child(toggle)
			toggles[key] = toggle
			toggle.toggled.connect(func(value: bool): setting_changed.emit(key, value))
	var note := Ui.label("Music also controls crypt ambience. Sound keeps both levels when switched off.", "muted", 14)
	body.add_child(note)
	close_button = panel.get_meta("rc_close")
	close_button.pressed.connect(func(): close_requested.emit())
	resized.connect(_fit)
	set_values(_values)
	_fit()
	hide()

func set_values(values: Dictionary) -> void:
	_values = values.duplicate(true)
	for key in toggles:
		var enabled := bool(values.get(key, false))
		var button: Button = toggles[key]
		button.set_pressed_no_signal(enabled)
		button.text = TOGGLE_LABELS[key] + ": " + ("On" if enabled else "Off")
		Ui.apply_states(button, {"selected": enabled})
	for key in sliders:
		var value := float(values.get(key, 1.0)) * 100.0
		sliders[key].set_value_no_signal(value)
		_slider_rows[key].get_child(0).text = SLIDER_LABELS[key] + "  " + str(int(value)) + "%"

func register_gestures(router: Node) -> void:
	router.register_scroll(body_scroll)
	router.register_target(close_button, func(): close_requested.emit())
	for button in toggles.values():
		router.register_target(button, func(): button.button_pressed = not button.button_pressed)

func _fit() -> void:
	if panel == null: return
	panel.size = Vector2(minf(560.0, size.x - 32.0), minf(690.0, size.y - 32.0))
	panel.position = (size - panel.size) / 2.0
