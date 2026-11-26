extends SceneTree
## Fair pet comparison: the same seeds, each pet forced in turn (newbie + tactician bots).
const Run = preload("res://scripts/core/run.gd")
const PlayerBot = preload("res://tools/bots/player_bot.gd")
func _init():
	for style in ["newbie", "tactician"]:
		var line: String = style + ": "
		for pet_id in ["ash_crow", "grave_pup", "candle_moth", "black_cat"]:
			var wins := 0
			for s in 150:
				var run := Run.new(7000 + s)
				run.pet_offers = run.pets_db.filter(func(p): return p["id"] == pet_id)
				run.choose_pet(0)
				var bot = PlayerBot.new(style, s)
				var steps := 0
				while not run.is_over() and steps < 3000:
					bot.play_run_step(run)
					steps += 1
				wins += int(run.phase == "victory")
			line += "%s %d%%  " % [pet_id, int(100.0 * wins / 150)]
		print(line)
	quit()
