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
	quit()
