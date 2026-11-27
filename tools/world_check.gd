extends SceneTree
## Win rate of single world fights (fresh starter party, tactician bot) per country: normal groups and the boss.
const World = preload("res://scripts/core/world.gd")
const PlayerBot = preload("res://tools/bots/player_bot.gd")
func _fight(w, e, seed_value: int) -> bool:
	w.setup_party(["varek", "lys", "aldric"], {}, "ash_crow")
	var c = w.start_fight(e, seed_value)
	var bot = PlayerBot.new("tactician", seed_value)
	var guard := 0
	while not c.finished and guard < 100:
		bot.play_turn(c)
		guard += 1
	return c.monsters.all(func(m): return m["hp"] <= 0)
func _init():
	var w = World.new()
	for ci in w.countries.size():
		var normal: Array = w.enemies.filter(func(e): return e["country"] == ci and not e["boss"])
		var boss: Dictionary = w.enemies.filter(func(e): return e["country"] == ci and e["boss"])[0]
		var nw := 0
		for i in 80:
			nw += int(_fight(w, normal[i % normal.size()], i))
		var bw := 0
		for i in 80:
			bw += int(_fight(w, boss, 500 + i))
		print("%-18s tier %d   normal fights %3d%%   boss %-20s %3d%%" % [w.countries[ci]["name"], w.countries[ci]["tier"], nw * 100 / 80, w.monster_defs[boss["group"][0]]["name"], bw * 100 / 80])
	for ci in [0, 2]:
		for style in ["newbie", "tactician"]:
			print(_trip_economy(ci, style))
	for id in ["sunken_abbey", "slag_cathedral", "marrow_vault"]:
		for style in ["newbie", "tactician"]:
			print(_dungeon_check(id, style))
	quit()


## 3.5: win rate of an Isle dungeon run (starter party, no town upgrades; and with a mid-game town).
func _dungeon_check(id: String, style: String) -> String:
	const Run = preload("res://scripts/core/run.gd")
	var out: Array[String] = []
	for town in [{}, {"chapel": 2, "smithy": 1, "carver": 2, "fortune": 1, "kennel": 1},
			{"chapel": 3, "smithy": 2, "carver": 2, "fortune": 1, "kennel": 1, "market": 2}]:
		var wins := 0
		var boss := 0
		var n := 120
		for i in n:
			var o: Dictionary = town.duplicate()
			o["region"] = "res://data/dungeon_%s.json" % id
			o["time"] = "day"
			var run := Run.new(5000 + i, o)
			var bot = PlayerBot.new(style, 5000 + i)
			var steps := 0
			while not run.is_over() and steps < 2000:
				bot.play_run_step(run)
				steps += 1
			wins += int(run.phase == "victory")
			boss += int(run.pos == run.board.size() - 1)
		out.append("%s %d%% (reached the boss %d%%)" % [["starter town", "mid town", "full town"][0 if town.is_empty() else (1 if town.size() == 5 else 2)], wins * 100 / n, boss * 100 / n])
	return "Dungeon %-13s %-9s: %s" % [id, style, ", ".join(out)]


## 3.5: what one Isle trip pays (to compare with a road run): a fresh starter party walks into a country,
## gathers 4 veins, fights 3 roaming groups and then the boss (HP carries over, a little regen between fights),
## and goes home when the boss falls or the party does. Materials are counted at their selling price in embers.
func _trip_economy(ci: int, style: String) -> String:
	const TRIPS := 60
	var embers := 0.0
	var dust := 0.0
	var mats := 0.0
	var boss_wins := 0
	for t in TRIPS:
		var w = World.new()
		w.begin_trip(["varek", "lys", "aldric"], {}, "ash_crow")
		var rng := RandomNumberGenerator.new()
		rng.seed = 7000 + t
		var nodes: Array = w.nodes.filter(func(n): return n["country"] == ci and n["kind"] == "ore")
		for k in 4:
			w.gather(nodes[k]["id"], rng)
		var normal: Array = w.enemies.filter(func(e): return e["country"] == ci and not e["boss"])
		var plan: Array = [normal[t % normal.size()], normal[(t + 3) % normal.size()], normal[(t + 7) % normal.size()]]
		plan.append(w.enemies.filter(func(e): return e["country"] == ci and e["boss"])[0])
		for e in plan:
			var c = w.start_fight(e, 9000 + t * 10 + plan.find(e))
			var bot = PlayerBot.new(style, 9000 + t)
			var guard := 0
			while not c.finished and guard < 100:
				bot.play_turn(c)
				guard += 1
			var won: bool = c.monsters.all(func(m): return m["hp"] <= 0)
			var r: Dictionary = w.finish_fight(e, won, rng)
			embers += r["embers"]
			dust += r["dust"]
			w.skip_sharpening()
			if not won:
				break
			if e["boss"]:
				boss_wins += 1
			w.regenerate(4)
		for id in w.bag:
			mats += w.bag[id] * w.material_value(id)
	return "Isle trip %-14s %-9s: %.0f embers + %.0f in materials (sell value) + %.1f dust per trip; boss beaten in %d%% of trips" % [
		w_name(ci), style, embers / TRIPS, mats / TRIPS, dust / TRIPS, boss_wins * 100 / TRIPS]


func w_name(ci: int) -> String:
	return World.new().countries[ci]["name"]
