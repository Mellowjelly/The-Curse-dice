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
var grave_dice := 0
var owned_heroes: Array = []      # hero ids; starters are always owned
var unlocked_weapons: Array = []  # relic weapon ids unlocked by summoning
var party: Array = []             # last chosen party (3 hero ids)
var summons_since_hero := 0
var curse := 0                    # chosen Curse level (opt-in difficulty, unlocked by wins)
const MAX_CURSE := 4
const CURSE_EMBER_BONUS := 0.25
var summon: Dictionary
var town: Dictionary
var quests: Array


func _init(save_path: String = DEFAULT_PATH) -> void:
	path = save_path
	town = GameData.load_json("res://data/town.json")
	quests = GameData.load_json("res://data/quests.json")
	summon = GameData.load_json("res://data/summon.json")
	for h in GameData.load_heroes():
		if h.get("starter", false):
			owned_heroes.append(h["id"])
	party = owned_heroes.slice(0, 3)


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
	grave_dice = d.get("grave_dice", 0)
	for id in d.get("owned_heroes", []):
		if not id in owned_heroes:
			owned_heroes.append(id)
	unlocked_weapons = d.get("unlocked_weapons", [])
	party = d.get("party", party)
	summons_since_hero = d.get("summons_since_hero", 0)
	curse = d.get("curse", 0)


func save() -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_var({"version": 2, "embers": embers, "levels": levels, "stats": stats, "quests_done": quests_done,
		"grave_dice": grave_dice, "owned_heroes": owned_heroes, "unlocked_weapons": unlocked_weapons,
		"party": party, "summons_since_hero": summons_since_hero, "curse": curse})


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
	var run_curse := int(run.upgrades.get("curse", 0))
	earned = int(earned * (1.0 + CURSE_EMBER_BONUS * run_curse))
	if won:
		stats["best_curse_won"] = max(stat("best_curse_won"), run_curse + 1) if stats.has("best_curse_won") else run_curse + 1
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
	var dice: int = int(summon["dice_per_run"]) + s["elites"] * int(summon["dice_per_elite"])
	dice += (int(summon["dice_per_victory"]) if won else 0) + completed.size() * int(summon["dice_per_quest"])
	grave_dice += dice
	save()
	return {"embers": earned, "quests": completed, "dice": dice}


## What a run should be started with: town levels plus unlocked relic weapons.
## Highest Curse level the player may choose: one above the highest level they have beaten.
func max_curse() -> int:
	return min(MAX_CURSE, stat("best_curse_won"))


func set_curse(level: int) -> void:
	curse = clamp(level, 0, max_curse())
	save()


func run_options() -> Dictionary:
	var o := levels.duplicate()
	o["curse"] = curse
	o["unlocked_weapons"] = unlocked_weapons.duplicate()
	return o


# ---------------------------------------------------------------- summon roll (fair gacha)
# Paid only with Grave Dice earned by playing. Rates are shown in the town.
# Pity: a new hero is guaranteed on the `pity`-th summon without one.

func can_summon() -> bool:
	return grave_dice >= int(summon["cost"])


func locked_heroes() -> Array:
	return GameData.load_heroes().filter(func(h): return not h["id"] in owned_heroes)


func locked_relics() -> Array:
	return GameData.load_weapons().filter(func(w): return w.get("locked", false) and not w["id"] in unlocked_weapons)


## Returns { "kind": "hero"|"relic"|"embers", "name": String, "text": String, "new": bool }.
func summon_roll(rng: RandomNumberGenerator) -> Dictionary:
	if not can_summon():
		return {}
	grave_dice -= int(summon["cost"])
	summons_since_hero += 1
	var kind := ""
	if summons_since_hero >= int(summon["pity"]) and not locked_heroes().is_empty():
		kind = "hero"
	else:
		var total := 0
		for r in summon["rates"]:
			total += int(r["weight"])
		var roll := rng.randi_range(1, total)
		for r in summon["rates"]:
			roll -= int(r["weight"])
			if roll <= 0:
				kind = r["kind"]
				break
	var result := {}
	match kind:
		"hero":
			summons_since_hero = 0
			var pool := locked_heroes()
			if pool.is_empty():
				embers += int(summon["duplicate_embers"]["hero"])
				result = {"kind": "embers", "name": "Echo of a hero", "text": "A familiar soul answers. +%d Soul Embers." % int(summon["duplicate_embers"]["hero"]), "new": false}
			else:
				var h: Dictionary = pool[rng.randi_range(0, pool.size() - 1)]
				owned_heroes.append(h["id"])
				result = {"kind": "hero", "name": h["name"], "text": "A new hero joins you: %s! %s" % [h["name"], h.get("lore", "")], "new": true}
		"relic":
			var pool := locked_relics()
			if pool.is_empty():
				embers += int(summon["duplicate_embers"]["relic"])
				result = {"kind": "embers", "name": "Dust of relics", "text": "Only dust. +%d Soul Embers." % int(summon["duplicate_embers"]["relic"]), "new": false}
			else:
				var w: Dictionary = pool[rng.randi_range(0, pool.size() - 1)]
				unlocked_weapons.append(w["id"])
				result = {"kind": "relic", "name": w["name"], "text": "Relic unlocked: %s. It can now appear on the road." % w["name"], "new": true}
		_:
			var amount := 0
			for r in summon["rates"]:
				if r["kind"] == "embers":
					amount = int(r["amount"])
			embers += amount
			result = {"kind": "embers", "name": "Soul Embers", "text": "Embers swirl from the dice: +%d Soul Embers." % amount, "new": false}
	save()
	return result


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
