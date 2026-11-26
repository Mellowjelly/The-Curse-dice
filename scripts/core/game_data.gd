extends RefCounted
## Loads game content (heroes, monsters, encounters) from the JSON files in res://data/.
## Designers edit the JSON; code never hard-codes content.

const HEROES_PATH := "res://data/heroes.json"
const MONSTERS_PATH := "res://data/monsters.json"
const REGION_PATH := "res://data/region1.json"
const EVENTS_PATH := "res://data/events.json"

## Every face type the combat code knows how to resolve.
const FACE_TYPES := ["attack", "fire", "blood", "cleave", "shield", "guard", "heal", "sweep", "blank"]


static func load_json(path: String) -> Variant:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Cannot open %s" % path)
		return null
	var data: Variant = JSON.parse_string(file.get_as_text())
	if data == null:
		push_error("Invalid JSON in %s" % path)
	return data


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
