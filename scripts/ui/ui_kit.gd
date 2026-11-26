extends RefCounted
## Shared palette and widget helpers so every screen looks like one game.

const BG := Color("#0e0b12")
const PANEL := Color("#1c1622")
const PANEL_DARK := Color("#15101a")
const BORDER := Color("#3a2f45")
const TEXT := Color("#d8cfc4")
const DIM := Color("#7a6f80")
const BLOOD := Color("#b3261e")
const HP := Color("#8e1c1c")
const GOLD := Color("#c9a227")
const GREEN := Color("#5f9e58")

const FACE_COLORS := {
	"attack": Color("#9b2c2c"), "fire": Color("#c2571a"), "blood": Color("#5e0b1a"),
	"shield": Color("#3b5876"), "guard": Color("#2f6b6b"), "heal": Color("#3f6e3a"),
	"sweep": Color("#6b2d6b"), "blank": Color("#2a2530"),
}
const FACE_NAMES := {
	"attack": "ATK", "fire": "FIRE", "blood": "BLOOD", "shield": "SHIELD",
	"guard": "GUARD", "heal": "HEAL", "sweep": "SWEEP", "blank": "-",
}
const TILE_COLORS := {
	"start": Color("#2a2530"), "fight": Color("#6e2424"), "elite": Color("#8a1f4a"),
	"boss": Color("#b3261e"), "event": Color("#4b3a6b"), "chest": Color("#7a5a14"),
	"shop": Color("#2f5d5d"), "rest": Color("#a3541c"),
}
const TILE_LABELS := {
	"start": "Start", "fight": "Fight", "elite": "Elite", "boss": "BOSS", "event": "?",
	"chest": "Chest", "shop": "Shop", "rest": "Camp",
}


static func label(text: String, size: int = 16, color: Color = TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func wrap_label(text: String, size: int = 16, color: Color = TEXT, min_width: float = 200) -> Label:
	var l := label(text, size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(min_width, 0)
	return l


static func button(text: String, on_press: Callable, size: int = 16) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size)
	b.pressed.connect(on_press)
	return b


static func box(color: Color, border: Color = BORDER, border_width: int = 1, radius: int = 6, margin: int = 10) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.border_color = border
	s.set_border_width_all(border_width)
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(margin)
	return s


static func panel(border: Color = BORDER, border_width: int = 1, color: Color = PANEL) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", box(color, border, border_width, 6, 12))
	return p


## A button styled as a big choice card (used for carvings, events, shop).
static func choice_button(text: String, on_press: Callable, accent: Color = BORDER, enabled: bool = true) -> Button:
	var b := button(text, on_press, 17)
	b.custom_minimum_size = Vector2(0, 54)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.disabled = not enabled
	var normal := box(PANEL_DARK, accent, 2, 6, 12)
	var hover := box(Color("#2a1a22"), GOLD, 2, 6, 12)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_stylebox_override("focus", normal)
	b.add_theme_stylebox_override("disabled", box(PANEL_DARK, BORDER, 1, 6, 12))
	b.add_theme_color_override("font_color", TEXT)
	b.add_theme_color_override("font_hover_color", GOLD)
	b.add_theme_color_override("font_disabled_color", DIM)
	return b


static func hp_bar(hp: int, max_hp: int, height: float = 20) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.max_value = max_hp
	bar.value = max(hp, 0)
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, height)
	var fill := StyleBoxFlat.new()
	fill.bg_color = HP
	var back := StyleBoxFlat.new()
	back.bg_color = Color("#2a1418")
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", back)
	var text := label("%d / %d" % [max(hp, 0), max_hp], 13)
	text.set_anchors_preset(Control.PRESET_FULL_RECT)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bar.add_child(text)
	return bar


static func face_short(f: Dictionary) -> String:
	return FACE_NAMES[f["type"]] + ("" if f["type"] == "blank" else str(int(f["value"])))


static func full_rect(c: Control) -> Control:
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	return c
