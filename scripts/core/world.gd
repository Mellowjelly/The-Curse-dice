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
var nodes: Array = []              # { id, kind: "ore"|"tree", cell: Vector2i, country, depleted_until }
var enemies: Array = []            # { id, cell: Vector2i, country, group: Array, defeated_until, boss: bool }
var party: Array = []              # hero units (HP carries between fights)
var pet: Dictionary = {}
var bag := {}                      # material id -> amount (lost if you fall in a dangerous country)
var player_cell := Vector2i(22, 48)
var clock := 0.0                   # seconds of world time (for respawns)
var monster_defs: Dictionary
var time_of_day := ""             # set from the town when you set out
var trip_carvings := 0            # Isle wins sharpen the party's dice until they go home
const MAX_TRIP_CARVINGS := 3
const SHARPEN_OFFERS := 3         # 3.4: after an Isle win the player picks 1 of 3 sharpenings
var sharpen_offers: Array = []    # [{ "hero": int, "face": int, "new": Dictionary, "text": String }]
var dungeons: Array = []          # 3.5: { "id", "name", "cell": Vector2i, "country": int } Isle dungeon entrances
var on_trip := false              # 3.5: true from setting out until the party is home (a closed app resumes the trip)


func _init(world_seed: int = -1) -> void:
	data = GameData.load_json("res://data/world.json")
	size = int(data["size"])
	countries = data["countries"]
	monster_defs = GameData.load_monsters()
	_generate(int(data["seed"]) if world_seed < 0 else world_seed)
	player_cell = Vector2i(int(countries[0]["center"][0]), int(countries[0]["center"][1]))
	_place_dungeons()


## 3.5: a country with "dungeon" in world.json has an entrance near its centre (data/dungeon_<id>.json).
func _place_dungeons() -> void:
	dungeons = []
	for ci in countries.size():
		var id := String(countries[ci].get("dungeon", ""))
		if id == "":
			continue
		var d: Dictionary = GameData.load_json("res://data/dungeon_%s.json" % id)
		var centre := Vector2i(int(countries[ci]["center"][0]), int(countries[ci]["center"][1]))
		var off: Array = d.get("entrance", [0, 0])
		var want := centre + Vector2i(int(off[0]), int(off[1]))
		var cell := centre
		var best := INF
		for dy in range(-4, 5):  # the nearest free cell in the country: no vein, tree or monster on it
			for dx in range(-4, 5):
				var c := want + Vector2i(dx, dy)
				var dist := Vector2(c).distance_to(Vector2(want))
				if dist < best and country_index_at(c) == ci and not nodes.any(func(n): return n["cell"] == c) \
						and not enemies.any(func(e): return Vector2(e["cell"]).distance_to(Vector2(c)) < 2.0):
					best = dist
					cell = c
		dungeons.append({"id": id, "name": d["name"], "cell": cell, "country": ci})


## The dungeon entrance within `reach` cells of `cell`, or {}.
func dungeon_near(cell: Vector2i, reach: float = 1.5) -> Dictionary:
	for d in dungeons:
		if Vector2(d["cell"]).distance_to(Vector2(cell)) <= reach:
			return d
	return {}


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
		var c: Dictionary = countries[ci]
		var used := {}
		# Ore fields: veins cluster around a few spots.
		var fields: Array = []
		for k in int(data.get("ore_fields", 2)):
			fields.append(cells[rng.randi_range(0, cells.size() - 1)])
		var guard := 0
		var placed := 0
		while placed < int(data["nodes_per_country"]) and guard < 500:
			guard += 1
			var f: Vector2i = fields[placed % fields.size()]
			var cell := f + Vector2i(rng.randi_range(-3, 3), rng.randi_range(-3, 3))
			if country_index_at(cell) != ci or used.has(cell):
				continue
			used[cell] = true
			nodes.append({"id": "n%d" % nid, "kind": "ore", "cell": cell, "country": ci, "depleted_until": 0.0})
			nid += 1
			placed += 1
		# Trees to chop, scattered.
		for k in int(data.get("trees_per_country", 0)):
			var cell: Vector2i = cells[rng.randi_range(0, cells.size() - 1)]
			if used.has(cell):
				continue
			used[cell] = true
			nodes.append({"id": "n%d" % nid, "kind": "tree", "cell": cell, "country": ci, "depleted_until": 0.0})
			nid += 1
		# Roaming monsters and beasts.
		for k in int(data["enemies_per_country"]):
			var groups: Array = c["beasts"] if rng.randf() < 0.6 and c.has("beasts") else c["monsters"]
			var cell: Vector2i = cells[rng.randi_range(0, cells.size() - 1)]
			# Keep the start of Ashfall Vale quiet.
			if ci == 0 and Vector2(cell).distance_to(Vector2(player_cell)) < 6:
				continue
			enemies.append({"id": "e%d" % eid, "cell": cell, "country": ci,
				"group": groups[rng.randi_range(0, groups.size() - 1)], "defeated_until": 0.0, "boss": false})
			eid += 1
		# The country's boss waits in its lair near the centre.
		if c.has("boss"):
			var centre := Vector2i(int(c["center"][0]), int(c["center"][1]))
			var lair := centre + Vector2i(4, -3) if ci == 0 else centre
			if country_index_at(lair) != ci:
				lair = centre
			enemies.append({"id": "boss_%s" % c["id"], "cell": lair, "country": ci, "group": [c["boss"]],
				"defeated_until": 0.0, "boss": true})


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
func setup_party(hero_ids: Array, stars: Dictionary, pet_id: String, gear: Dictionary = {}, bonus_hp: int = 0) -> void:
	party = []
	trip_carvings = 0
	sharpen_offers = []
	var by_id := {}
	for d in GameData.load_heroes():
		by_id[d["id"]] = d
	for id in hero_ids:
		var u := Combat.make_unit(by_id[id])
		Run.apply_hero_stars(u, int(stars.get("hero:" + id, 1)))
		u["weapon"] = {}
		Run.apply_gear(u, gear.get(id, {}))
		u["max_hp"] += bonus_hp  # the town Chapel, same as on the road
		u["hp"] += bonus_hp
		party.append(u)
	pet = {}
	for p in GameData.load_pets():
		if p["id"] == pet_id:
			pet = p.duplicate(true)
			Run.apply_pet_stars(pet, int(stars.get("pet:" + pet_id, 1)))
			Run.apply_pet_treat(pet, gear.get("pet:" + pet_id, {}).get("treat", {}))
			pet["face"] = 0


## 3.5: sets out from town. If the last trip never reached home (the app was closed on the Isle) and the
## same heroes and pet are chosen, the trip resumes: HP, sharpened faces and pending sharpen offers are kept.
## Otherwise a fresh party is built. Returns true when an old trip was resumed.
func begin_trip(hero_ids: Array, stars: Dictionary, pet_id: String, gear: Dictionary = {}, bonus_hp: int = 0) -> bool:
	var same := on_trip and party.size() == hero_ids.size() and String(pet.get("id", "")) == pet_id
	if same:
		for i in hero_ids.size():
			if String(party[i].get("id", "")) != String(hero_ids[i]):
				same = false
	if not same:
		setup_party(hero_ids, stars, pet_id, gear, bonus_hp)
	on_trip = true
	return same


## 3.5: the party is home: heal, clear the trip's sharpening and stand at the gate.
func end_trip() -> void:
	rest_in_town()
	on_trip = false
	sharpen_offers = []
	trip_carvings = 0
	player_cell = Vector2i(int(countries[0]["center"][0]), int(countries[0]["center"][1]))


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
		if n.get("kind", "ore") == "tree":
			res = {"id": c["wood"]["id"], "name": c["wood"]["name"], "amount": rng.randi_range(int(r[0]), int(r[1]) + 1), "rare": false}
		elif rng.randf() < float(data["rare_chance"]):
			res = {"id": c["rare"]["id"], "name": c["rare"]["name"], "amount": 1, "rare": true}
		else:
			res = {"id": c["mineral"]["id"], "name": c["mineral"]["name"], "amount": rng.randi_range(int(r[0]), int(r[1])), "rare": false}
		bag[res["id"]] = int(bag.get(res["id"], 0)) + res["amount"]
		n["depleted_until"] = clock + float(data["node_respawn_seconds"])
		return res
	return {}


## Value of one unit of a material (for trading in town).
func material_value(id: String) -> int:
	if data.get("hides", {}).has(id):
		return int(data["hides"][id][1])
	for c in countries:
		if c.get("wood", {}).get("id", "") == id:
			return int(c["wood"]["value"])
		if c["mineral"]["id"] == id:
			return int(c["mineral"]["value"])
		if c["rare"]["id"] == id:
			return int(c["rare"]["value"])
	return 1


func material_name(id: String) -> String:
	if data.get("hides", {}).has(id):
		return data["hides"][id][0]
	for c in countries:
		if c.get("wood", {}).get("id", "") == id:
			return c["wood"]["name"]
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
	var is_boss: bool = e.get("boss", false)
	var out: Array = []
	for id in e["group"]:
		var d: Dictionary = monster_defs[id].duplicate(true)
		# Early bosses get a big boost; late bosses are already huge and are meant for crafted gear.
		var boss_hp := (1.35 if tier <= 2 else 1.0) if is_boss else 1.0
		var night := 1.2 if time_of_day == "night" else 1.0
		d["hp"] = int(round(float(d["hp"]) * (1.0 + 0.22 * (tier - 1)) * boss_hp * night))
		var bonus := tier / 2 + (1 if is_boss and tier <= 2 else 0) - (1 if is_boss and tier >= 3 else 0)
		for faces in [d["faces"], d.get("phase2", {}).get("faces", [])]:
			for f in faces:
				if f["type"] in ["attack", "sweep"]:
					f["value"] = int(f["value"]) + bonus
		out.append(d)
	return out


func start_fight(e: Dictionary, seed_value: int) -> Combat:
	var c := Combat.new(seed_value)
	c.can_flee = true
	c.pet = pet.duplicate(true) if not pet.is_empty() else {}
	c.start_battle(party, fight_defs(e))
	return c


## After a fight. Returns a summary { "victory", "embers", "dust", "lost_bag" }.
## The party ran: no loss, but the enemy stays and the party steps back.
func flee_fight(e: Dictionary) -> Dictionary:
	var back := player_cell + Vector2i(sign(player_cell.x - e["cell"].x), sign(player_cell.y - e["cell"].y)) * 2
	if is_walkable(back):
		player_cell = back
	return {"victory": false, "fled": true, "embers": 0, "dust": 0, "lost_bag": false, "drops": {}, "boss": e.get("boss", false)}


func finish_fight(e: Dictionary, victory: bool, rng: RandomNumberGenerator) -> Dictionary:
	var tier := int(countries[e["country"]]["tier"])
	if victory:
		var is_boss: bool = e.get("boss", false)
		e["defeated_until"] = clock + float(data["boss_respawn_seconds" if is_boss else "enemy_respawn_seconds"])
		for h in party:
			if not Combat.is_alive(h):
				h["hp"] = max(1, h["max_hp"] / 4)
		# Beasts leave hides; bosses leave a trophy.
		var drops := {}
		for id in e["group"]:
			var hide: String = monster_defs[id].get("hide", "")
			if hide != "":
				drops[hide] = int(drops.get(hide, 0)) + (1 if is_boss else rng.randi_range(2, 3))  # 3.3: 2-3 hides, less grind
		var c: Dictionary = countries[e["country"]]
		if is_boss:
			drops[c["mineral"]["id"]] = int(drops.get(c["mineral"]["id"], 0)) + 6
			drops[c["rare"]["id"]] = int(drops.get(c["rare"]["id"], 0)) + 1
		elif drops.is_empty():
			drops[c["mineral"]["id"]] = rng.randi_range(1, 2)  # every fight leaves something behind
		for id in drops:
			bag[id] = int(bag.get(id, 0)) + drops[id]
		var dust := (3 + tier) if is_boss else (1 if rng.randf() < 0.25 * tier else 0)
		var embers := (30 * tier) if is_boss else 10 * tier + rng.randi_range(0, 5 * tier)
		if time_of_day == "night":
			embers = int(embers * 1.4)
		# Battle-hardened: the party's dice sharpen a little (until they go home). 3.4: the player picks 1 of 3.
		sharpen_offers = _make_sharpen_offers(rng) if trip_carvings < MAX_TRIP_CARVINGS else []
		return {"victory": true, "embers": embers, "dust": dust, "lost_bag": false, "drops": drops, "boss": is_boss, "carved": "",
			"sharpen": not sharpen_offers.is_empty()}
	sharpen_offers = []
	var lost := is_dangerous(countries[e["country"]]) and not bag.is_empty()
	if lost:
		bag.clear()
	# Carried back to Ashfall, battered but alive.
	player_cell = Vector2i(int(countries[0]["center"][0]), int(countries[0]["center"][1]))
	for h in party:
		h["hp"] = max(1, h["max_hp"] / 2)
	return {"victory": false, "embers": 0, "dust": 0, "lost_bag": lost, "drops": {}, "boss": e.get("boss", false)}


# ---------------------------------------------------------------- sharpening after an Isle win

## Up to 3 offers of "+1 on one face (1-4)", each on a different hero when possible, never the same face twice.
func _make_sharpen_offers(rng: RandomNumberGenerator) -> Array:
	var alive: Array = []
	for i in party.size():
		if Combat.is_alive(party[i]):
			alive.append(i)
	var candidates: Array = []  # [[hero index, face index], ...] ordered so different heroes come first
	for pass_n in 4:
		for hi in alive:
			var faces: Array = []
			for fi in 4:
				if party[hi]["faces"][fi]["type"] != "blank" and not candidates.any(func(c): return c[0] == hi and c[1] == fi):
					faces.append(fi)
			if not faces.is_empty():
				candidates.append([hi, faces[rng.randi_range(0, faces.size() - 1)]])
	# Shuffle the heroes' first offers, so the first offer is not always the party leader.
	var first: Array = candidates.slice(0, min(alive.size(), candidates.size()))
	for k in range(first.size() - 1, 0, -1):
		var j := rng.randi_range(0, k)
		var t = first[k]
		first[k] = first[j]
		first[j] = t
	candidates = first + candidates.slice(first.size())
	var offers: Array = []
	for c in candidates.slice(0, SHARPEN_OFFERS):
		var h: Dictionary = party[c[0]]
		var f: Dictionary = h["faces"][c[1]]
		var nf: Dictionary = f.duplicate()
		nf["value"] = int(f["value"]) + 1
		var o := {"hero": c[0], "face": c[1], "new": nf}
		o["text"] = sharpen_text(o)
		offers.append(o)
	return offers


## "Varek: ATTACK 3 -> 4" for one offer (rebuilt after loading, so the language is current).
func sharpen_text(o: Dictionary) -> String:
	var h: Dictionary = party[int(o["hero"])]
	var nf: Dictionary = o["new"]
	return "%s: %s %d -> %d" % [Combat.short_name(h), tr(String(nf["type"]).to_upper()), int(nf["value"]) - 1, int(nf["value"])]


## Applies the chosen sharpening. Returns the message to show ("" if the choice is not valid).
func choose_sharpening(index: int) -> String:
	if index < 0 or index >= sharpen_offers.size():
		return ""
	var o: Dictionary = sharpen_offers[index]
	sharpen_offers = []
	var h: Dictionary = party[int(o["hero"])]
	h["faces"][int(o["face"])] = o["new"]
	trip_carvings += 1
	return tr("%s's %s face sharpens to %d (until you go home)") % [Combat.short_name(h), tr(String(o["new"]["type"]).to_upper()), int(o["new"]["value"])]


func skip_sharpening() -> void:
	sharpen_offers = []


# ---------------------------------------------------------------- save

func to_dict() -> Dictionary:
	return {"party": party, "pet": pet, "bag": bag, "player_cell": [player_cell.x, player_cell.y], "clock": clock,
		"nodes": nodes.map(func(n): return n["depleted_until"]),
		"enemies": enemies.map(func(e): return e["defeated_until"]),
		"trip_carvings": trip_carvings, "on_trip": on_trip,
		"sharpen_offers": sharpen_offers.map(func(o): return {"hero": o["hero"], "face": o["face"], "new": o["new"]})}


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
	# 3.5: the trip state (old saves have none: no trip in progress).
	trip_carvings = int(d.get("trip_carvings", 0))
	on_trip = bool(d.get("on_trip", false))
	sharpen_offers = []
	for o in d.get("sharpen_offers", []):
		var hi := int(o.get("hero", -1))
		var fi := int(o.get("face", -1))
		if hi < 0 or hi >= party.size() or fi < 0 or fi >= party[hi]["faces"].size():
			continue
		var off := {"hero": hi, "face": fi, "new": Dictionary(o["new"]).duplicate()}
		off["text"] = sharpen_text(off)
		sharpen_offers.append(off)
