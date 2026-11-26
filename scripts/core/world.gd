extends RefCounted
## The open world: 7 countries on a square grid of cells (drawn isometric by the UI),
## mineral nodes to gather, roaming enemies, the party's bag. NO UI code here.
##
## Cells belong to the nearest country centre (with some noise, so borders look natural).
## Danger rises with each country's tier. Above `safe_tier`, falling in battle loses the bag.

const Combat = preload("res://scripts/core/combat.gd")
const GameData = preload("res://scripts/core/game_data.gd")
const Run = preload("res://scripts/core/run.gd")

var data: Dictionary
var size := 96
var countries: Array = []
var grid := PackedByteArray()      # country index per cell (y * size + x); 255 = water
var nodes: Array = []              # { id, cell: Vector2i, country, depleted_until }
var enemies: Array = []            # { id, cell: Vector2i, country, group: Array, defeated_until }
var party: Array = []              # hero units (HP carries between fights)
var pet: Dictionary = {}
var bag := {}                      # material id -> amount (lost if you fall in a dangerous country)
var player_cell := Vector2i(22, 48)
var clock := 0.0                   # seconds of world time (for respawns)
var monster_defs: Dictionary


func _init(world_seed: int = -1) -> void:
	data = GameData.load_json("res://data/world.json")
	size = int(data["size"])
	countries = data["countries"]
	monster_defs = GameData.load_monsters()
	_generate(int(data["seed"]) if world_seed < 0 else world_seed)
	player_cell = Vector2i(int(countries[0]["center"][0]), int(countries[0]["center"][1]))


# ---------------------------------------------------------------- generation

func _generate(world_seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = world_seed
	grid.resize(size * size)
	var noise := FastNoiseLite.new()
	noise.seed = world_seed
	noise.frequency = 0.08
	for y in size:
		for x in size:
			# Water around the map's edge (the world is an island).
			var edge: float = min(min(x, y), min(size - 1 - x, size - 1 - y))
			if edge + noise.get_noise_2d(x * 2.0, y * 2.0) * 3.0 < 2.5:
				grid[y * size + x] = 255
				continue
			var best := 0
			var best_d := INF
			for i in countries.size():
				var c: Array = countries[i]["center"]
				var d := Vector2(x, y).distance_to(Vector2(c[0], c[1])) + noise.get_noise_2d(x, y) * 9.0
				if d < best_d:
					best_d = d
					best = i
			grid[y * size + x] = best
	var nid := 0
	var eid := 0
	for ci in countries.size():
		var cells := cells_of(ci)
		for k in int(data["nodes_per_country"]):
			nodes.append({"id": "n%d" % nid, "cell": cells[rng.randi_range(0, cells.size() - 1)], "country": ci, "depleted_until": 0.0})
			nid += 1
		for k in int(data["enemies_per_country"]):
			var groups: Array = countries[ci]["monsters"]
			var cell: Vector2i = cells[rng.randi_range(0, cells.size() - 1)]
			# Keep the start of Ashfall Vale quiet.
			if ci == 0 and Vector2(cell).distance_to(Vector2(player_cell)) < 6:
				continue
			enemies.append({"id": "e%d" % eid, "cell": cell, "country": ci,
				"group": groups[rng.randi_range(0, groups.size() - 1)], "defeated_until": 0.0})
			eid += 1


func cells_of(country_index: int) -> Array:
	var out: Array = []
	for y in size:
		for x in size:
			if grid[y * size + x] == country_index:
				out.append(Vector2i(x, y))
	return out


func country_index_at(cell: Vector2i) -> int:
	if cell.x < 0 or cell.y < 0 or cell.x >= size or cell.y >= size:
		return 255
	return grid[cell.y * size + cell.x]


func country_at(cell: Vector2i) -> Dictionary:
	var i := country_index_at(cell)
	return countries[i] if i != 255 else {}


func is_walkable(cell: Vector2i) -> bool:
	return country_index_at(cell) != 255


func is_dangerous(country: Dictionary) -> bool:
	return not country.is_empty() and int(country["tier"]) > int(data["safe_tier"])


# ---------------------------------------------------------------- party

## Builds the travelling party from the profile (stars applied). Call when leaving town.
func setup_party(hero_ids: Array, stars: Dictionary, pet_id: String) -> void:
	party = []
	var by_id := {}
	for d in GameData.load_heroes():
		by_id[d["id"]] = d
	for id in hero_ids:
		var u := Combat.make_unit(by_id[id])
		Run.apply_hero_stars(u, int(stars.get("hero:" + id, 1)))
		party.append(u)
	pet = {}
	for p in GameData.load_pets():
		if p["id"] == pet_id:
			pet = p.duplicate(true)
			Run.apply_pet_stars(pet, int(stars.get("pet:" + pet_id, 1)))
			pet["face"] = 0


func party_alive() -> bool:
	return party.any(func(h): return Combat.is_alive(h))


## Slow healing while travelling (called by the UI every few seconds).
func regenerate(amount: int = 1) -> void:
	for h in party:
		if Combat.is_alive(h):
			h["hp"] = min(h["max_hp"], h["hp"] + amount)


func rest_in_town() -> void:
	for h in party:
		h["hp"] = h["max_hp"]


# ---------------------------------------------------------------- gathering

func node_ready(n: Dictionary) -> bool:
	return clock >= float(n["depleted_until"])


## Gathers a node. Returns { "id", "name", "amount", "rare": bool } or {} if depleted.
func gather(node_id: String, rng: RandomNumberGenerator) -> Dictionary:
	for n in nodes:
		if n["id"] != node_id or not node_ready(n):
			continue
		var c: Dictionary = countries[n["country"]]
		var r: Array = data["gather_amount"]
		var res: Dictionary
		if rng.randf() < float(data["rare_chance"]):
			res = {"id": c["rare"]["id"], "name": c["rare"]["name"], "amount": 1, "rare": true}
		else:
			res = {"id": c["mineral"]["id"], "name": c["mineral"]["name"], "amount": rng.randi_range(int(r[0]), int(r[1])), "rare": false}
		bag[res["id"]] = int(bag.get(res["id"], 0)) + res["amount"]
		n["depleted_until"] = clock + float(data["node_respawn_seconds"])
		return res
	return {}


## Value of one unit of a material (for trading in town).
func material_value(id: String) -> int:
	for c in countries:
		if c["mineral"]["id"] == id:
			return int(c["mineral"]["value"])
		if c["rare"]["id"] == id:
			return int(c["rare"]["value"])
	return 1


func material_name(id: String) -> String:
	for c in countries:
		if c["mineral"]["id"] == id:
			return c["mineral"]["name"]
		if c["rare"]["id"] == id:
			return c["rare"]["name"]
	return id


# ---------------------------------------------------------------- enemies and combat

func enemy_active(e: Dictionary) -> bool:
	return clock >= float(e["defeated_until"])


## Monster definitions for a fight with this enemy group, scaled by the country's tier.
func fight_defs(e: Dictionary) -> Array:
	var tier := int(countries[e["country"]]["tier"])
	var out: Array = []
	for id in e["group"]:
		var d: Dictionary = monster_defs[id].duplicate(true)
		d["hp"] = int(round(float(d["hp"]) * (1.0 + 0.22 * (tier - 1))))
		var bonus := (tier - 1) / 2
		for faces in [d["faces"], d.get("phase2", {}).get("faces", [])]:
			for f in faces:
				if f["type"] in ["attack", "sweep"]:
					f["value"] = int(f["value"]) + bonus
		out.append(d)
	return out


func start_fight(e: Dictionary, seed_value: int) -> Combat:
	var c := Combat.new(seed_value)
	c.pet = pet.duplicate(true) if not pet.is_empty() else {}
	c.start_battle(party, fight_defs(e))
	return c


## After a fight. Returns a summary { "victory", "embers", "dust", "lost_bag" }.
func finish_fight(e: Dictionary, victory: bool, rng: RandomNumberGenerator) -> Dictionary:
	var tier := int(countries[e["country"]]["tier"])
	if victory:
		e["defeated_until"] = clock + float(data["enemy_respawn_seconds"])
		for h in party:
			if not Combat.is_alive(h):
				h["hp"] = max(1, h["max_hp"] / 4)
		var dust := 1 if rng.randf() < 0.25 * tier else 0
		return {"victory": true, "embers": 4 * tier + rng.randi_range(0, 3 * tier), "dust": dust, "lost_bag": false}
	var lost := is_dangerous(countries[e["country"]]) and not bag.is_empty()
	if lost:
		bag.clear()
	# Carried back to Ashfall, battered but alive.
	player_cell = Vector2i(int(countries[0]["center"][0]), int(countries[0]["center"][1]))
	for h in party:
		h["hp"] = max(1, h["max_hp"] / 2)
	return {"victory": false, "embers": 0, "dust": 0, "lost_bag": lost}


# ---------------------------------------------------------------- save

func to_dict() -> Dictionary:
	return {"party": party, "pet": pet, "bag": bag, "player_cell": [player_cell.x, player_cell.y], "clock": clock,
		"nodes": nodes.map(func(n): return n["depleted_until"]),
		"enemies": enemies.map(func(e): return e["defeated_until"])}


func load_dict(d: Dictionary) -> void:
	party = d.get("party", party)
	pet = d.get("pet", pet)
	bag = d.get("bag", {})
	var pc: Array = d.get("player_cell", [player_cell.x, player_cell.y])
	player_cell = Vector2i(int(pc[0]), int(pc[1]))
	clock = float(d.get("clock", 0.0))
	var nd: Array = d.get("nodes", [])
	for i in min(nd.size(), nodes.size()):
		nodes[i]["depleted_until"] = float(nd[i])
	var ed: Array = d.get("enemies", [])
	for i in min(ed.size(), enemies.size()):
		enemies[i]["defeated_until"] = float(ed[i])
