extends SceneTree
## Hero balance: every party of 3 out of all heroes plays the same seeds.
## Prints win rate per hero (average over parties that include them) and the best/worst parties.
## Run: godot --headless --path . -s tools/hero_check.gd -- [runs_per_party]
const Run = preload("res://scripts/core/run.gd")
const PlayerBot = preload("res://tools/bots/player_bot.gd")
const GameData = preload("res://scripts/core/game_data.gd")

func _init():
	var args := OS.get_cmdline_user_args()
	var runs: int = int(args[0]) if args.size() > 0 else 60
	var ids: Array = GameData.load_heroes().map(func(h): return h["id"])
	var parties: Array = []
	for a in ids.size():
		for b in range(a + 1, ids.size()):
			for c in range(b + 1, ids.size()):
				parties.append([ids[a], ids[b], ids[c]])
	for style in ["newbie", "tactician"]:
		var hero_w := {}
		var hero_n := {}
		var results: Array = []
		for party in parties:
			var wins := 0
			for s in runs:
				var run := Run.new(8000 + s, {}, party)
				var bot = PlayerBot.new(style, s)
				var steps := 0
				while not run.is_over() and steps < 3000:
					bot.play_run_step(run)
					steps += 1
				wins += int(run.phase == "victory")
			var rate := 100.0 * wins / runs
			results.append([rate, party])
			for id in party:
				hero_w[id] = hero_w.get(id, 0.0) + rate
				hero_n[id] = hero_n.get(id, 0) + 1
		results.sort_custom(func(x, y): return x[0] > y[0])
		var line: String = "%s heroes: " % style
		for id in ids:
			line += "%s %.0f%%  " % [id, hero_w[id] / hero_n[id]]
		print(line)
		print("%s best: %s %.0f%% | worst: %s %.0f%%" % [style, str(results[0][1]), results[0][0], str(results[-1][1]), results[-1][0]])
	quit()
