extends RefCounted
## Player settings (language, music and sound volume), stored in user://settings.cfg.
## Applied once at start-up by AppEvents and again whenever the Settings panel changes something.
##
## Translation: data/lang_<code>.json maps the English text to the translated text.
## Godot translates any Label/Button whose text matches a key; code uses tr() for formatted text.

const PATH := "user://settings.cfg"
const LANGUAGES := {"en": "English", "th": "ภาษาไทย"}
const THAI_FONT := "res://assets/fonts/NotoSansThai-Regular.woff2"

static var language := "en"
static var music := 0.8      # 0..1
static var sound := 0.8      # 0..1
static var tutorial_step := 0  # first-fight tutorial progress (TUTORIAL_DONE = finished or skipped)
const TUTORIAL_DONE := 99
static var _ready := false


static func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		language = str(cfg.get_value("game", "language", "en"))
		music = float(cfg.get_value("audio", "music", 0.8))
		sound = float(cfg.get_value("audio", "sound", 0.8))
		tutorial_step = int(cfg.get_value("game", "tutorial_step", 0))
	if not LANGUAGES.has(language):
		language = "en"


static func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("game", "language", language)
	cfg.set_value("audio", "music", music)
	cfg.set_value("audio", "sound", sound)
	cfg.set_value("game", "tutorial_step", tutorial_step)
	cfg.save(PATH)


## First call installs the Thai font and the translations; every call applies volume and language.
static func apply() -> void:
	if not _ready:
		_ready = true
		_install_font()
		_load_translations()
		_ensure_bus("Music")
		_ensure_bus("SFX")
	_set_bus_volume("Music", music)
	_set_bus_volume("SFX", sound)
	TranslationServer.set_locale(language)


static func set_language(code: String) -> void:
	language = code if LANGUAGES.has(code) else "en"
	save_settings()
	apply()


static func set_volume(kind: String, value: float) -> void:
	if kind == "music":
		music = clamp(value, 0.0, 1.0)
	else:
		sound = clamp(value, 0.0, 1.0)
	save_settings()
	apply()


static func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) == -1:
		AudioServer.add_bus()
		var i := AudioServer.bus_count - 1
		AudioServer.set_bus_name(i, bus_name)
		AudioServer.set_bus_send(i, "Master")


static func _set_bus_volume(bus_name: String, value: float) -> void:
	var i := AudioServer.get_bus_index(bus_name)
	if i == -1:
		return
	AudioServer.set_bus_mute(i, value <= 0.01)
	AudioServer.set_bus_volume_db(i, linear_to_db(max(value, 0.01)))


## The default font has no Thai letters, so Noto Sans Thai is added as its fallback:
## English keeps its look and Thai text is drawn with Noto.
static func _install_font() -> void:
	if not ResourceLoader.exists(THAI_FONT):
		return
	var thai: Font = load(THAI_FONT)
	var theme := ThemeDB.get_default_theme()
	var base: Font = theme.default_font if theme.default_font != null else ThemeDB.fallback_font
	var fv := FontVariation.new()
	fv.base_font = base
	fv.fallbacks = [thai]
	theme.default_font = fv
	ThemeDB.fallback_font = fv


static func _load_translations() -> void:
	for code in LANGUAGES:
		if code == "en":
			continue
		var path := "res://data/lang_%s.json" % code
		if not FileAccess.file_exists(path):
			continue
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if typeof(data) != TYPE_DICTIONARY:
			push_error("Invalid translation file %s" % path)
			continue
		var t := Translation.new()
		t.locale = code
		for key in data:
			if key.begins_with("_"):
				continue  # "_comment" and similar notes for translators
			t.add_message(key, str(data[key]))
		TranslationServer.add_translation(t)


static func set_tutorial_step(step: int) -> void:
	tutorial_step = step
	save_settings()
