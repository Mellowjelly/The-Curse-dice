extends ColorRect
## Settings overlay: language, music volume, sound volume. Open with show(); everything saves at once.

const UI = preload("res://scripts/ui/ui_kit.gd")
const Settings = preload("res://scripts/ui/settings.gd")

signal closed

var _language_at_open := ""


func _ready() -> void:
	color = Color(0, 0, 0, 0.85)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := UI.panel(UI.GOLD, 2)
	panel.custom_minimum_size = Vector2(520, 0)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)
	box.add_child(UI.label("Settings", 30, UI.GOLD))

	box.add_child(UI.label("Language", 18, UI.TEXT))
	var langs := HBoxContainer.new()
	langs.add_theme_constant_override("separation", 10)
	for code in Settings.LANGUAGES:
		var b := UI.choice_button(Settings.LANGUAGES[code], func(): Settings.set_language(code); _rebuild(), UI.GOLD if Settings.language == code else UI.BORDER)
		b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED  # language names stay in their own language
		b.custom_minimum_size = Vector2(200, 48)
		langs.add_child(b)
	box.add_child(langs)

	box.add_child(_slider_row("Music", Settings.music, func(v): Settings.set_volume("music", v)))
	box.add_child(_slider_row("Sound effects", Settings.sound, func(v): Settings.set_volume("sound", v)))

	if _language_at_open == "":
		_language_at_open = Settings.language
	var close := UI.button("Close", _close, 18)
	close.custom_minimum_size = Vector2(0, 48)
	box.add_child(close)


func _rebuild() -> void:
	for c in get_children():
		c.queue_free()
	_ready.call_deferred()


func _slider_row(title: String, value: float, on_change: Callable) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var l := UI.label(title, 18, UI.TEXT)
	l.custom_minimum_size = Vector2(170, 0)
	row.add_child(l)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = value
	s.custom_minimum_size = Vector2(280, 44)
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.value_changed.connect(on_change)
	row.add_child(s)
	return row


func _close() -> void:
	hide()
	closed.emit()
	if Settings.language != _language_at_open:
		# Most screens build their text once, so rebuild the screen in the new language.
		get_tree().reload_current_scene()
