extends Node
## App-wide phone behaviour (autoload "AppEvents"):
## - Android Back: a screen may handle it first (on_back() returns true, e.g. closing a dialog).
##   Otherwise press Back twice to leave to the title screen, or to quit from the title screen.
## - When the app is paused, hidden or closed, the current screen saves (save_state()).

const UI = preload("res://scripts/ui/ui_kit.gd")
const TITLE_SCENE := "res://scenes/title.tscn"
const CONFIRM_TIME := 2.0

var _armed_until := 0.0
var _layer: CanvasLayer
var _toast: Label


func _ready() -> void:
	get_tree().quit_on_go_back = false
	get_tree().auto_accept_quit = false
	_layer = CanvasLayer.new()
	_layer.layer = 100
	add_child(_layer)
	_toast = UI.label("", 18, UI.GOLD)
	_toast.add_theme_color_override("font_shadow_color", Color.BLACK)
	_toast.add_theme_constant_override("shadow_offset_x", 2)
	_toast.add_theme_constant_override("shadow_offset_y", 2)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.position = Vector2(0, 660)
	_toast.size = Vector2(1280, 30)
	_toast.hide()
	_layer.add_child(_toast)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_GO_BACK_REQUEST:
			_on_back()
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT:
			_save_scene()
		NOTIFICATION_WM_CLOSE_REQUEST:
			_save_scene()
			get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	# Escape on desktop behaves like the phone's Back button.
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_on_back()
		get_viewport().set_input_as_handled()


func _save_scene() -> void:
	var scene := get_tree().current_scene
	if scene != null and scene.has_method("save_state"):
		scene.save_state()


func _on_back() -> void:
	var scene := get_tree().current_scene
	if scene != null and scene.has_method("on_back") and scene.on_back():
		return
	var at_title := scene != null and scene.scene_file_path == TITLE_SCENE
	var now := Time.get_ticks_msec() / 1000.0
	if now > _armed_until:
		_armed_until = now + CONFIRM_TIME
		_show("Press Back again to quit" if at_title else "Press Back again to return to the title (progress is saved)")
		return
	_armed_until = 0.0
	_toast.hide()
	_save_scene()
	if at_title:
		get_tree().quit()
	else:
		get_tree().change_scene_to_file(TITLE_SCENE)


func _show(text: String) -> void:
	_toast.text = text
	_toast.modulate.a = 1.0
	_toast.show()
	var tw := create_tween()
	tw.tween_interval(CONFIRM_TIME - 0.4)
	tw.tween_property(_toast, "modulate:a", 0.0, 0.4)
	tw.tween_callback(_toast.hide)
