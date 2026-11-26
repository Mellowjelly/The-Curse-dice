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
var summons_since_hero := 0      # (old single-banner pity, kept for old saves)
var summon_pity := {}             # banner -> rolls since its last new item
var owned_pets: Array = []        # pet ids; starter pets are always owned
var time_of_day := 1              # index into TIMES (starts at Day)
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
	for p in GameData.load_pets():
		if p.get("starter", false):
			owned_pets.append(p["id"])


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
	summon_pity = d.get("summon_pity", {})
	for id in d.get("owned_pets", []):
		if not id in owned_pets:
			owned_pets.append(id)
	time_of_day = d.get("time_of_day", 1)


func save() -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_var({"version": 2, "embers": embers, "levels": levels, "stats": stats, "quests_done": quests_done,
		"grave_dice": grave_dice, "owned_heroes": owned_heroes, "unlocked_weapons": unlocked_weapons,
		"party": party, "summons_since_hero": summons_since_hero, "curse": curse,
		"summon_pity": summon_pity, "owned_pets": owned_pets, "time_of_day": time_of_day})


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
	var night: bool = run.upgrades.get("time", "") == "night"
	earned = int(earned * (1.0 + CURSE_EMBER_BONUS * run_curse + (0.4 if night else 0.0)))
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
	dice += 1 if night else 0
	grave_dice += dice
	time_of_day = (time_of_day + 1) % TIMES.size()  # you return to town a little later
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
	o["owned_pets"] = owned_pets.duplicate()
	o["time"] = time_name()
	o["unlocked_weapons"] = unlocked_weapons.duplicate()
	return o


# ---------------------------------------------------------------- summon roll (fair gacha, 3 banners)
# Paid only with Grave Dice earned by playing. Each banner shows its odds and its own pity counter:
# a roll gives something NEW from that banner with new_chance %, and is guaranteed every `pity` rolls.
# Otherwise (or when a banner is complete) the roll gives Soul Embers. Nothing is ever a duplicate stat boost.

const BANNERS := ["heroes", "relics", "pets"]


func can_summon(banner: String = "heroes") -> bool:
	return grave_dice >= int(summon["cost"]) and not locked_in(banner).is_empty()


func locked_heroes() -> Array:
	return GameData.load_heroes().filter(func(h): return not h["id"] in owned_heroes)


func locked_relics() -> Array:
	return GameData.load_weapons().filter(func(w): return w.get("locked", false) and not w["id"] in unlocked_weapons)


func locked_pets() -> Array:
	return GameData.load_pets().filter(func(p): return not p["id"] in owned_pets)


func locked_in(banner: String) -> Array:
	match banner:
		"heroes": return locked_heroes()
		"relics": return locked_relics()
		"pets": return locked_pets()
	return []


func pity_count(banner: String) -> int:
	return int(summon_pity.get(banner, 0))


## Returns { "kind": "hero"|"relic"|"pet"|"embers", "id": String, "name": String, "text": String, "new": bool }.
func summon_roll(rng: RandomNumberGenerator, banner: String = "heroes") -> Dictionary:
	if not can_summon(banner):
		return {}
	grave_dice -= int(summon["cost"])
	summon_pity[banner] = pity_count(banner) + 1
	var pool := locked_in(banner)
	var hit: bool = pity_count(banner) >= int(summon["pity"]) or rng.randi_range(1, 100) <= int(summon["new_chance"])
	var result := {}
	if hit and not pool.is_empty():
		summon_pity[banner] = 0
		var item: Dictionary = pool[rng.randi_range(0, pool.size() - 1)]
		match banner:
			"heroes":
				owned_heroes.append(item["id"])
				result = {"kind": "hero", "id": item["id"], "name": item["name"], "new": true,
					"text": "A new hero joins you: %s! %s" % [item["name"], item.get("lore", "")]}
			"relics":
				unlocked_weapons.append(item["id"])
				result = {"kind": "relic", "id": item["id"], "name": item["name"], "new": true,
					"text": "Relic unlocked: %s. It can now appear on the road." % item["name"]}
			"pets":
				owned_pets.append(item["id"])
				result = {"kind": "pet", "id": item["id"], "name": item["name"], "new": true,
					"text": "A new companion follows you: %s. %s" % [item["name"], item.get("desc", "")]}
	else:
		var amount := int(summon["embers_amount"])
		embers += amount
		result = {"kind": "embers", "id": "", "name": "Soul Embers", "new": false,
			"text": "Embers swirl from the dice: +%d Soul Embers. (%d/%d toward a guaranteed find)" % [amount, pity_count(banner), int(summon["pity"])]}
	save()
	return result


# ---------------------------------------------------------------- time of day
# Each journey back to town moves time forward; the player may also wait in town.

const TIMES := ["dawn", "day", "dusk", "night"]
const TIME_NAMES := {"dawn": "Dawn", "day": "Day", "dusk": "Dusk", "night": "Night"}
const TIME_EFFECTS := {
	"dawn": "First light: camps heal +10% more.",
	"day": "Open roads: shop prices -15%.",
	"dusk": "Long shadows: +1 Fate at the start of every fight.",
	"night": "The dead walk: enemies +20% HP, but +40% Soul Embers and +1 Grave Die.",
}


func time_name() -> String:
	return TIMES[time_of_day % TIMES.size()]


func advance_time() -> void:
	time_of_day = (time_of_day + 1) % TIMES.size()
	save()


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
