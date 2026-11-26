extends RefCounted
## Loads game content (heroes, monsters, encounters) from the JSON files in res://data/.
## Designers edit the JSON; code never hard-codes content.

const HEROES_PATH := "res://data/heroes.json"
const MONSTERS_PATH := "res://data/monsters.json"
const REGION_PATH := "res://data/region1.json"
const EVENTS_PATH := "res://data/events.json"

## Every face type the combat code knows how to resolve.
const FACE_TYPES := ["attack", "fire", "blood", "cleave", "shield", "guard", "heal", "sweep", "blank"]


## Content files are parsed once and kept in memory (cheap phones stuttered when the town re-read them on every click).
## Callers get a deep copy, so changing the result never changes the cache.
static var _json_cache := {}

static func load_json(path: String) -> Variant:
	if not _json_cache.has(path):
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			push_error("Cannot open %s" % path)
			return null
		var data: Variant = JSON.parse_string(file.get_as_text())
		if data == null:
			push_error("Invalid JSON in %s" % path)
			return null
		_json_cache[path] = data
	var cached: Variant = _json_cache[path]
	return cached.duplicate(true) if cached is Dictionary or cached is Array else cached


# ---------------------------------------------------------------- safe saving
# A phone can kill the app in the middle of a save. So: write a temporary file, keep the previous
# save as ".bak", then swap the new file in. Reading falls back to ".bak" if the main file is broken.

static func safe_store(path: String, data: Dictionary) -> bool:
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_error("Cannot write %s" % tmp)
		return false
	f.store_var(data)
	f.close()
	var dir := DirAccess.open(path.get_base_dir())
	if dir == null:
		return false
	if FileAccess.file_exists(path):
		dir.copy(path, path + ".bak")
	return dir.rename(tmp, path) == OK


static func safe_load(path: String) -> Dictionary:
	for p in [path, path + ".bak"]:
		if not FileAccess.file_exists(p):
			continue
		var f := FileAccess.open(p, FileAccess.READ)
		if f == null:
			continue
		var d: Variant = f.get_var()
		if typeof(d) == TYPE_DICTIONARY and not d.is_empty():
			return d
	return {}


static func safe_delete(path: String) -> void:
	for p in [path, path + ".bak", path + ".tmp"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))


static func load_heroes() -> Array:
	return load_json(HEROES_PATH)


## Returns monsters keyed by id, e.g. { "ghoul": {...} }.
static func load_monsters() -> Dictionary:
	var by_id := {}
	for def in load_json(MONSTERS_PATH):
		by_id[def["id"]] = def
	return by_id


static func load_weapons() -> Array:
	return load_json("res://data/weapons.json")


static func load_pets() -> Array:
	return load_json("res://data/pets.json")


static func load_region() -> Dictionary:
	return load_json(REGION_PATH)


static func load_events() -> Array:
	return load_json(EVENTS_PATH)
