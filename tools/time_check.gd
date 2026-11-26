extends SceneTree
## Win rate for each time of day (same seeds). Run: godot --headless --path . -s tools/time_check.gd
const Run = preload("res://scripts/core/run.gd")
const PlayerBot = preload("res://tools/bots/player_bot.gd")
func _init():
	for style in ["newbie", "tactician"]:
		var line: String = style + ": "
		for t in ["", "dawn", "day", "dusk", "night"]:
			var wins := 0
			for s in 150:
				var run := Run.new(9100 + s, {"time": t})
				var bot = PlayerBot.new(style, s)
				var steps := 0
				while not run.is_over() and steps < 3000:
					bot.play_run_step(run)
					steps += 1
				wins += int(run.phase == "victory")
			line += "%s %d%%  " % [t if t != "" else "none", int(100.0 * wins / 150)]
		print(line)
	quit()
