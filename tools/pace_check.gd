extends SceneTree
## 3.7: rounds per fight kind (road day/night, Isle day/night) and monster shield use.
## Run:  godot --headless --path . -s tools/pace_check.gd -- [runs per style]
const Run = preload("res://scripts/core/run.gd")
const World = preload("res://scripts/core/world.gd")
const Combat = preload("res://scripts/core/combat.gd")
const PlayerBot = preload("res://tools/bots/player_bot.gd")
var stats := {}
func _add(key: String, rounds: int, raised: int, absorbed: int, wasted: int, won: bool) -> void:
	if not stats.has(key):
		stats[key] = {"n": 0, "rounds": 0, "raised": 0, "absorbed": 0, "wasted": 0, "long": 0, "wins": 0}
	var s: Dictionary = stats[key]
	s["n"] += 1; s["rounds"] += rounds; s["raised"] += raised; s["absorbed"] += absorbed; s["wasted"] += wasted
	s["long"] += int(rounds >= 7); s["wins"] += int(won)
func _watch(c: Combat) -> Dictionary:
	var w := {"absorbed": 0}
	c.damaged.connect(func(u, amt, blk): if c.monsters.has(u): w["absorbed"] += blk)
	return w
func _shield_sum(c: Combat) -> int:
	var s := 0
	for m in c.monsters:
		if Combat.is_alive(m): s += int(m["shield"])
	return s
func _init():
	var args := OS.get_cmdline_user_args()
	var n := int(args[0]) if args.size() > 0 else 100
	for style in ["newbie", "tactician"]:
		for time in ["day", "night"]:
			for i in n:
				var run := Run.new(300 + i, {"time": time, "chapel": 1, "carver": 1, "smithy": 1})
				var bot := PlayerBot.new(style, 300 + i)
				var steps := 0
				var c: Combat = null
				var w := {}
				var rounds := 0; var raised := 0; var wasted := 0; var last_r := -1; var kind := ""
				while not run.is_over() and steps < 3000:
					steps += 1
					if run.phase == "combat":
						if run.combat != c:
							c = run.combat; w = _watch(c); rounds = 0; raised = 0; wasted = 0; last_r = -1; kind = run.combat_kind
						if c.round_number != last_r:
							last_r = c.round_number; rounds += 1
							raised += _shield_sum(c)
						var before := _shield_sum(c)
						bot.play_run_step(run)
						if c.finished:
							_add("road %s %s %s" % [time, kind, style], rounds, raised, w["absorbed"], 0, c.monsters.all(func(m): return m["hp"] <= 0))
							c = null
					else:
						bot.play_run_step(run)
	# Isle fights (fresh starter party)
	for style in ["newbie", "tactician"]:
		for time in ["day", "night"]:
			var wd = World.new()
			wd.time_of_day = time
			for ci in wd.countries.size():
				var groups: Array = wd.enemies.filter(func(e): return e["country"] == ci)
				for i in 20:
					var e: Dictionary = groups[i % groups.size()]
					wd.setup_party(["varek", "lys", "aldric"], {}, "ash_crow")
					var c: Combat = wd.start_fight(e, i)
					var w := _watch(c)
					var bot := PlayerBot.new(style, i)
					var guard := 0; var raised := 0; var last_r := -1
					while not c.finished and guard < 100:
						if c.round_number != last_r:
							last_r = c.round_number; raised += _shield_sum(c)
						bot.play_turn(c); guard += 1
					var key := "isle %s T%d %s %s" % [time, int(wd.countries[ci]["tier"]), "boss" if e["boss"] else "fight", style]
					_add(key, c.round_number, raised, w["absorbed"], 0, c.monsters.all(func(m): return m["hp"] <= 0))
	var keys := stats.keys(); keys.sort()
	for k in keys:
		var s: Dictionary = stats[k]
		print("%-36s n=%4d rounds %.1f  >=7r %3d%%  win %3d%%  shield up/fight %.1f  absorbed/fight %.1f" % [k, s["n"], float(s["rounds"]) / s["n"], s["long"] * 100 / s["n"], s["wins"] * 100 / s["n"], float(s["raised"]) / s["n"], float(s["absorbed"]) / s["n"]])
	quit()
