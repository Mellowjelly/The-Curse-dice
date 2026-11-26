extends RefCounted
## Persistent progress between runs: Soul Embers, town building levels, quests, lifetime stats.
## Saved with FileAccess.store_var (keeps int/float types exactly). NO UI code here.

const GameData = preload("res://scripts/core/game_data.gd")

const DEFAULT_PATH := "user://profile.save"
const RUN_SAVE_PATH := "user://run.save"

var path := DEFAULT_PATH
var embers := 0
var levels := {}          # building id -> level
var stats := {}           # lifetime counters, e.g. "runs", "wins", "best_tile", "kills_ghoul"
var quests_done: Array = []
var town: Dictionary
var quests: Array


func _init(save_path: String = DEFAULT_PATH) -> void:
	path = save_path
	town = GameData.load_json("res://data/town.json")
	quests = GameData.load_json("res://data/quests.json")


# ---------------------------------------------------------------- save / load

func load_profile() -> void:
	if not FileAccess.file_exists(path):
		return
	var f := FileAccess.open(path, FileAccess.READ)
	var d: Variant = f.get_var()
	if typeof(d) != TYPE_DICTIONARY:
		return
	embers = d.get("embers", 0)
	levels = d.get("levels", {})
	stats = d.get("stats", {})
	quests_done = d.get("quests_done", [])


func save() -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_var({"version": 1, "embers": embers, "levels": levels, "stats": stats, "quests_done": quests_done})


# ---------------------------------------------------------------- town

func level(building_id: String) -> int:
	return int(levels.get(building_id, 0))


func building(building_id: String) -> Dictionary:
	for b in town["buildings"]:
		if b["id"] == building_id:
			return b
	return {}


## Cost of the next level, or -1 if maxed.
func next_cost(building_id: String) -> int:
	var costs: Array = building(building_id).get("costs", [])
	var lv := level(building_id)
	return int(costs[lv]) if lv < costs.size() else -1


func can_upgrade(building_id: String) -> bool:
	var c := next_cost(building_id)
	return c >= 0 and embers >= c


func upgrade(building_id: String) -> bool:
	if not can_upgrade(building_id):
		return false
	embers -= next_cost(building_id)
	levels[building_id] = level(building_id) + 1
	save()
	return true


# ---------------------------------------------------------------- after a run

func stat(key: String) -> int:
	return int(stats.get(key, 0))


func _add(key: String, amount: int) -> void:
	stats[key] = stat(key) + amount


## Records a finished run: updates stats, awards Embers, completes quests.
## Returns { "embers": int, "quests": [quest dicts completed now] }.
func record_run(run) -> Dictionary:
	var won: bool = run.phase == "victory"
	var s: Dictionary = run.stats
	var e: Dictionary = town["embers"]
	var earned: int = int(run.pos * float(e["per_tile"])) + s["fights"] * int(e["per_fight"]) + s["elites"] * int(e["per_elite"])
	if won:
		earned += int(e["victory"])
	_add("runs", 1)
	_add("wins", 1 if won else 0)
	stats["best_tile"] = max(stat("best_tile"), run.pos)
	_add("fate_twists", run.combat.twists)
	for id in s.get("kills", {}):
		_add("kills_" + id, s["kills"][id])
	if won and run.heroes.any(func(h): return h.get("weapon", {}).get("rarity", "") == "cursed"):
		_add("cursed_wins", 1)
	# Per-run quest stats are checked against this run only.
	var run_stats := {"run_elites": s["elites"], "run_carves": s["carves"]}
	var completed: Array = []
	for q in quests:
		if q["id"] in quests_done:
			continue
		var value: int = run_stats[q["stat"]] if run_stats.has(q["stat"]) else stat(q["stat"])
		if value >= int(q["goal"]):
			quests_done.append(q["id"])
			earned += int(q["reward"])
			completed.append(q)
	embers += earned
	save()
	return {"embers": earned, "quests": completed}


func quest_progress(q: Dictionary) -> int:
	if q["id"] in quests_done:
		return int(q["goal"])
	if q["stat"] in ["run_elites", "run_carves"]:
		return 0  # single-run goals show 0 until done
	return min(stat(q["stat"]), int(q["goal"]))


# ---------------------------------------------------------------- run save

static func has_saved_run() -> bool:
	return FileAccess.file_exists(RUN_SAVE_PATH)


static func save_run_data(data: Dictionary) -> void:
	var f := FileAccess.open(RUN_SAVE_PATH, FileAccess.WRITE)
	f.store_var(data)


static func load_run_data() -> Dictionary:
	if not has_saved_run():
		return {}
	var f := FileAccess.open(RUN_SAVE_PATH, FileAccess.READ)
	var d: Variant = f.get_var()
	return d if typeof(d) == TYPE_DICTIONARY else {}


static func delete_saved_run() -> void:
	if has_saved_run():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(RUN_SAVE_PATH))
