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
var day := 0                      # 3.5: days passed (+1 each time the clock goes from Night to Dawn)
var road_bonus_day := -1          # 3.5: the day the "first road-boss kill of the day" bonus was last paid
var star_dust := 0                # upgrade material
var stars := {}                   # "hero:varek" / "pet:ash_crow" / "relic:plague_lance" -> 1..5
var last_bank_quests: Array = []  # quests completed by the last bank() (not saved)
var npc_done := {}                # villager id -> ids of the requests already finished (order-independent)
var npc_active := {}              # villager id -> { "base": int, "run_best": int } for the accepted request
var villagers: Array
var materials := {}               # banked materials from the open world
var world_state := {}             # saved open-world session (see world.gd to_dict)
var gear: Array = []              # crafted items: { "uid": int, "recipe": id }
var equipped := {}                # hero id -> { "weapon": uid, "armor": uid }
var next_uid := 1
var bestiary_claimed := {}        # monster id -> how many Bestiary milestones are claimed (v3.1)
var bestiary: Dictionary          # data/bestiary.json
var star_rules: Dictionary
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
	villagers = GameData.load_json("res://data/villagers.json")
	star_rules = GameData.load_json("res://data/stars.json")
	bestiary = GameData.load_json("res://data/bestiary.json")
	for h in GameData.load_heroes():
		if h.get("starter", false):
			owned_heroes.append(h["id"])
	party = owned_heroes.slice(0, 3)
	for p in GameData.load_pets():
		if p.get("starter", false):
			owned_pets.append(p["id"])


# ---------------------------------------------------------------- save / load

## Bump when the save layout changes, and add a step to migrate().
const SAVE_VERSION := 5

## Villager request order before 3.3 (saves stored a position in this list; 3.3 stores request ids instead).
const _OLD_REQUEST_ORDER := {
	"tobin": ["tobin_rats", "tobin_fields", "tobin_harvest", "tobin_iron"],
	"marla": ["marla_camps", "marla_twist", "marla_bishop", "marla_hides"],
	"pip": ["pip_events", "pip_carve", "pip_night", "pip_shard"],
	"hesk": ["hesk_ghouls", "hesk_knight", "hesk_curse", "hesk_copper"],
}


## Upgrades an older save, one version at a time, so old players never lose progress.
static func migrate(d: Dictionary) -> Dictionary:
	var v := int(d.get("version", 1))
	if v < 2:
		# v1 (before the Isle): no materials, gear or stars yet; the loader's defaults cover them.
		v = 2
	if v < 3:
		# v3 (3.1): isle_trips joined stats for staged unlocks. Players who already banked items have been to the Isle.
		var st: Dictionary = d.get("stats", {})
		if not st.has("isle_trips") and (not d.get("materials", {}).is_empty() or not d.get("gear", []).is_empty()):
			st["isle_trips"] = 1
		d["stats"] = st
		v = 3
	if v < 4:
		# v4 (3.3): requests are tracked by id, so their order in villagers.json can change freely.
		var done := {}
		var active: Dictionary = d.get("npc_active", {})
		var steps: Dictionary = d.get("npc_step", {})
		for vid in steps:
			var order: Array = _OLD_REQUEST_ORDER.get(vid, [])
			var n: int = min(int(steps[vid]), order.size())
			done[vid] = order.slice(0, n)
			if active.has(vid) and n < order.size():
				active[vid]["req"] = order[n]
		d["npc_done"] = done
		d["npc_active"] = active
		d.erase("npc_step")
		v = 4
	if v < 5:
		# v5 (3.4): the road has two bosses, so Marla's "Rest for the Dead" counts Bishop kills, not road wins.
		# Keep her progress exactly: move the request's starting point from the wins counter to the Bishop counter.
		var active5: Dictionary = d.get("npc_active", {})
		var st5: Dictionary = d.get("stats", {})
		if active5.has("marla") and active5["marla"].get("req", "") == "marla_bishop":
			var done_so_far := int(st5.get("wins", 0)) - int(active5["marla"].get("base", 0))
			active5["marla"]["base"] = int(st5.get("kills_rotting_bishop", 0)) - done_so_far
		v = 5
	d["version"] = v
	return d


func load_profile() -> void:
	var raw := GameData.safe_load(path)
	if raw.is_empty():
		return
	var d := migrate(raw)
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
	day = int(d.get("day", 0))
	road_bonus_day = int(d.get("road_bonus_day", -1))
	star_dust = d.get("star_dust", 0)
	stars = d.get("stars", {})
	npc_done = d.get("npc_done", {})
	npc_active = d.get("npc_active", {})
	materials = d.get("materials", {})
	world_state = d.get("world_state", {})
	gear = d.get("gear", [])
	equipped = d.get("equipped", {})
	next_uid = d.get("next_uid", 1)
	bestiary_claimed = d.get("bestiary_claimed", {})


func save() -> void:
	GameData.safe_store(path, {"version": SAVE_VERSION, "embers": embers, "levels": levels, "stats": stats, "quests_done": quests_done,
		"grave_dice": grave_dice, "owned_heroes": owned_heroes, "unlocked_weapons": unlocked_weapons,
		"party": party, "summons_since_hero": summons_since_hero, "curse": curse,
		"summon_pity": summon_pity, "owned_pets": owned_pets, "time_of_day": time_of_day,
		"star_dust": star_dust, "stars": stars, "npc_done": npc_done, "npc_active": npc_active,
		"materials": materials, "world_state": world_state, "gear": gear, "equipped": equipped, "next_uid": next_uid,
		"bestiary_claimed": bestiary_claimed, "day": day, "road_bonus_day": road_bonus_day})


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
	_add("camps", int(s["tiles"].get("rest", 0)))
	_add("events", int(s["events"]))
	if won and int(run.upgrades.get("curse", 0)) >= 1:
		_add("cursed_level_wins", 1)
	# Single-journey goals for villagers' requests.
	var per_run := {"run_elites": s["elites"], "run_carves": s["carves"], "run_tile": run.pos,
		"night_tile": run.pos if run.upgrades.get("time", "") == "night" else 0}
	for npc_id in npc_active:
		var req := npc_request(npc_id)
		if not req.is_empty() and req["goal"]["scope"] == "run":
			var a: Dictionary = npc_active[npc_id]
			a["run_best"] = max(int(a.get("run_best", 0)), int(per_run.get(req["goal"]["stat"], 0)))
	star_dust += int(star_rules["dust_per_run"]) + (int(star_rules["dust_per_victory"]) if won else 0)
	# Per-run quest stats are checked against this run only.
	var run_stats := {"run_elites": s["elites"], "run_carves": s["carves"]}
	var completed := _complete_quests(run_stats)
	for q in completed:
		earned += int(q["reward"])
	var dice: int = int(summon["dice_per_run"]) + s["elites"] * int(summon["dice_per_elite"])
	dice += (int(summon["dice_per_victory"]) if won else 0) + completed.size() * int(summon["dice_per_quest"])
	dice += 1 if night else 0
	# 3.5: the road remembers the first boss you put down each day (a day = Dawn to Night).
	var bonus := {}
	if won and road_bonus_ready():
		var b: Dictionary = town.get("road_boss_daily", {})
		bonus = {"embers": int(b.get("embers", 0)), "dice": int(b.get("dice", 0))}
		earned += bonus["embers"]
		dice += bonus["dice"]
		road_bonus_day = day
	embers += earned
	grave_dice += dice
	_pass_time()  # you return to town a little later
	save()
	return {"embers": earned, "quests": completed, "dice": dice, "boss_bonus": bonus}


## 3.5: true while today's first road-boss kill has not been paid yet.
func road_bonus_ready() -> bool:
	return road_bonus_day != day and not town.get("road_boss_daily", {}).is_empty()


## Moves the clock one step; Night -> Dawn starts a new day.
func _pass_time() -> void:
	time_of_day = (time_of_day + 1) % TIMES.size()
	if time_of_day == 0:
		day += 1


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
	o["road_wins"] = stat("wins")  # 3.4: the second road boss appears only after the first win
	o["stars"] = stars.duplicate()
	o["gear"] = gear_bonuses()
	o["unlocked_weapons"] = unlocked_weapons.duplicate()
	return o


# ---------------------------------------------------------------- summon roll (fair gacha, 3 banners)
# Paid only with Grave Dice earned by playing. Each banner shows its odds and its own pity counter:
# a roll gives something NEW from that banner with new_chance %, and is guaranteed every `pity` rolls.
# Otherwise (or when a banner is complete) the roll gives Soul Embers. Nothing is ever a duplicate stat boost.

const BANNERS := ["heroes", "relics", "pets"]


func can_summon(banner: String = "heroes") -> bool:
	return grave_dice >= banner_cost(banner) and not locked_in(banner).is_empty()


func banner_cost(banner: String) -> int:
	return int(summon.get("banner_costs", {}).get(banner, summon["cost"]))


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
	grave_dice -= banner_cost(banner)
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
					"text": tr("A new hero joins you: %s! %s") % [tr(item["name"]), tr(item.get("lore", ""))]}
			"relics":
				unlocked_weapons.append(item["id"])
				result = {"kind": "relic", "id": item["id"], "name": item["name"], "new": true,
					"text": tr("Relic unlocked: %s. It can now appear on the road.") % tr(item["name"])}
			"pets":
				owned_pets.append(item["id"])
				result = {"kind": "pet", "id": item["id"], "name": item["name"], "new": true,
					"text": tr("A new companion follows you: %s. %s") % [tr(item["name"]), tr(item.get("desc", ""))]}
	else:
		var amount := int(summon["embers_amount"])
		embers += amount
		result = {"kind": "embers", "id": "", "name": "Soul Embers", "new": false,
			"text": tr("Embers swirl from the dice: +%d Soul Embers. (%d/%d toward a guaranteed find)") % [amount, pity_count(banner), int(summon["pity"])]}
	save()
	return result


## Marks every quest whose goal is met as done and returns them (rewards are paid by the caller).
func _complete_quests(run_stats: Dictionary = {}) -> Array:
	var completed: Array = []
	for q in quests:
		if q["id"] in quests_done:
			continue
		var value: int = run_stats[q["stat"]] if run_stats.has(q["stat"]) else stat(q["stat"])
		if value >= int(q["goal"]):
			quests_done.append(q["id"])
			completed.append(q)
	return completed


## Open-world fights count for lifetime stats and villagers' requests too.
func record_world_fight(group: Array, victory: bool, twists: int, boss: bool = false) -> void:
	if victory:
		for id in group:
			_add("kills_" + id, 1)
		_add("isle_kills", group.size())
		if boss:
			# Isle bosses pay Grave Dice: 3 the first time each one falls, then 1.
			var first := stat("isle_boss_" + str(group[0])) == 0
			_add("isle_boss_" + str(group[0]), 1)
			grave_dice += 3 if first else 1
	_add("fate_twists", twists)
	save()


# ---------------------------------------------------------------- villagers and their requests

func npc(id: String) -> Dictionary:
	for v in villagers:
		if v["id"] == id:
			return v
	return {}


## The villager's current request, or {} when they have nothing more to ask.
func npc_request(id: String) -> Dictionary:
	var v := npc(id)
	if v.is_empty():
		return {}
	var active_id: String = npc_active.get(id, {}).get("req", "")
	var done: Array = npc_done.get(id, [])
	for r in v["requests"]:
		if (active_id != "" and r["id"] == active_id) or (active_id == "" and not r["id"] in done):
			return r
	return {}


## The request this villager most recently finished, or {} (for their thank-you line).
func last_done_request(id: String) -> Dictionary:
	var done: Array = npc_done.get(id, [])
	if done.is_empty():
		return {}
	for r in npc(id).get("requests", []):
		if r["id"] == done[done.size() - 1]:
			return r
	return {}


## Marks requests as finished without rewards (tests and tools).
func mark_requests_done(id: String, request_ids: Array) -> void:
	npc_done[id] = request_ids.duplicate()


func npc_is_out(id: String) -> bool:
	return time_name() in npc(id).get("times", [])


func is_request_active(id: String) -> bool:
	return npc_active.has(id)


func request_progress(id: String) -> int:
	var req := npc_request(id)
	if req.is_empty() or not npc_active.has(id):
		return 0
	var g: Dictionary = req["goal"]
	var value: int
	if g["scope"] == "deliver":
		value = int(materials.get(g["material"], 0))  # what is in storage right now
	elif g["scope"] == "run":
		value = int(npc_active[id].get("run_best", 0))
	elif g["stat"] == "best_tile":
		value = stat("best_tile")
	else:
		value = stat(g["stat"]) - int(npc_active[id].get("base", 0))
	return min(value, int(g["amount"]))


func is_request_done(id: String) -> bool:
	var req := npc_request(id)
	return not req.is_empty() and npc_active.has(id) and request_progress(id) >= int(req["goal"]["amount"])


func accept_request(id: String) -> bool:
	var req := npc_request(id)
	if req.is_empty() or npc_active.has(id):
		return false
	var goal_stat: String = req["goal"].get("stat", "")
	npc_active[id] = {"base": stat(goal_stat), "run_best": 0, "req": req["id"], "reward": resolve_reward(req["reward"])}
	save()
	return true


## 3.5: what this villager's current request will really give (shown before you accept).
## The reward chosen when you accepted stays, unless you have since got that item another way.
func request_reward(id: String) -> Dictionary:
	var req := npc_request(id)
	if req.is_empty():
		return {}
	var kept: Dictionary = npc_active.get(id, {}).get("reward", {})
	if not kept.is_empty() and not (String(kept["kind"]) in ["hero", "pet", "relic"] and owns(kept["kind"], kept["id"])):
		return kept
	return resolve_reward(req["reward"])


## 3.5: an item reward you already own becomes another item of the same kind you do not own yet
## (same grade first, then data order: always the same choice). Only if you own them all is it Star Dust (see grant).
func resolve_reward(r: Dictionary) -> Dictionary:
	var kind := String(r["kind"])
	if not kind in ["hero", "pet", "relic"] or not owns(kind, r["id"]):
		return r
	var pool: Array
	match kind:
		"hero": pool = GameData.load_heroes()
		"pet": pool = GameData.load_pets()
		_: pool = GameData.load_weapons().filter(func(w): return w.get("locked", false))
	var grade: String = item_def(kind, r["id"]).get("grade", "SR")
	var free: Array = pool.filter(func(x): return not owns(kind, x["id"]))
	if free.is_empty():
		return r
	var same: Array = free.filter(func(x): return x.get("grade", "SR") == grade)
	var pick: Dictionary = same[0] if not same.is_empty() else free[0]
	return {"kind": kind, "id": pick["id"], "instead_of": r["id"]}


## Hands over the reward. Returns a result like summon_roll's, or {} if not finished.
func claim_request(id: String) -> Dictionary:
	if not is_request_done(id) or not npc_is_out(id):
		return {}
	var req := npc_request(id)
	var reward := request_reward(id)
	var g: Dictionary = req["goal"]
	if g["scope"] == "deliver":  # hand the materials over
		var mat: String = g["material"]
		materials[mat] = int(materials.get(mat, 0)) - int(g["amount"])
		if materials[mat] <= 0:
			materials.erase(mat)
	npc_active.erase(id)
	if not npc_done.has(id):
		npc_done[id] = []
	npc_done[id].append(req["id"])
	var result := grant(reward)
	save()
	return result


## Gives a reward. Items you already own turn into Star Dust instead.
func grant(r: Dictionary) -> Dictionary:
	var kind: String = r["kind"]
	match kind:
		"dust":
			star_dust += int(r["amount"])
			return {"kind": "dust", "id": "", "name": tr("Star Dust x%d") % int(r["amount"]), "new": false, "text": tr("+%d Star Dust") % int(r["amount"])}
		"dice":
			grave_dice += int(r["amount"])
			return {"kind": "dice", "id": "", "name": tr("Grave Dice x%d") % int(r["amount"]), "new": false, "text": tr("+%d Grave Dice") % int(r["amount"])}
		"embers":
			embers += int(r["amount"])
			return {"kind": "embers", "id": "", "name": tr("Soul Embers x%d") % int(r["amount"]), "new": false, "text": tr("+%d Soul Embers") % int(r["amount"])}
	var id: String = r["id"]
	var def := item_def(kind, id)
	var owned_list: Array = {"hero": owned_heroes, "pet": owned_pets, "relic": unlocked_weapons}[kind]
	if id in owned_list:
		var dust := duplicate_dust(kind, id)
		star_dust += dust
		return {"kind": "dust", "id": id, "name": def.get("name", id), "new": false, "grade": def.get("grade", "SR"),
			"text": tr("%s is already with you, so it turns into %d Star Dust.") % [tr(def.get("name", id)), dust]}
	owned_list.append(id)
	return {"kind": kind, "id": id, "name": def.get("name", id), "new": true, "grade": def.get("grade", "SR"),
		"text": tr("%s joins you!") % tr(def.get("name", id))}


func owns(kind: String, id: String) -> bool:
	return id in {"hero": owned_heroes, "pet": owned_pets, "relic": unlocked_weapons}.get(kind, [])


## Star Dust given instead of an item you already have (3.3: raised so a repeat reward still feels like a reward).
func duplicate_dust(kind: String, id: String) -> int:
	return 20 if item_def(kind, id).get("grade", "SR") == "SSR" else 12


func item_def(kind: String, id: String) -> Dictionary:
	var list: Array = {"hero": GameData.load_heroes(), "pet": GameData.load_pets(), "relic": GameData.load_weapons()}[kind]
	for x in list:
		if x["id"] == id:
			return x
	return {}


# ---------------------------------------------------------------- the Bestiary (v3.1)
# Every monster you have killed (road or Isle) gets a page with a line of lore and its kill count.
# Kill milestones pay small rewards (Star Dust, then a Grave Die), so hunting on the Isle has a goal.

## "boss", "elite" or "common": which milestone ladder a monster uses.
static func bestiary_rank(def: Dictionary) -> String:
	if def.get("boss", false):
		return "boss"
	return "elite" if def.get("elite", false) else "common"


## One page per monster, in monsters.json order:
## { id, name, element, rank, kills, known, lore, next_kills (-1 = all claimed), next_reward, claimable }
func bestiary_entries() -> Array:
	var out: Array = []
	var monsters := GameData.load_monsters()
	for id in monsters:
		var def: Dictionary = monsters[id]
		var rank := bestiary_rank(def)
		var ladder: Array = bestiary["milestones"][rank]
		var claimed := int(bestiary_claimed.get(id, 0))
		var kills := stat("kills_" + id)
		var e := {"id": id, "name": def["name"], "element": def.get("element", ""), "rank": rank, "kills": kills,
			"known": kills > 0, "lore": bestiary["lore"].get(id, ""), "next_kills": -1, "next_reward": {}, "claimable": false}
		if claimed < ladder.size():
			e["next_kills"] = int(ladder[claimed]["kills"])
			e["next_reward"] = ladder[claimed]["reward"]
			e["claimable"] = kills >= e["next_kills"]
		out.append(e)
	return out


func bestiary_claimable_count() -> int:
	return bestiary_entries().filter(func(e): return e["claimable"]).size()


## Claims the next kill milestone of a monster. Returns a grant() result, or {} if not reached.
func claim_bestiary(id: String) -> Dictionary:
	for e in bestiary_entries():
		if e["id"] == id and e["claimable"]:
			bestiary_claimed[id] = int(bestiary_claimed.get(id, 0)) + 1
			var result := grant(e["next_reward"])
			save()
			return result
	return {}


# ---------------------------------------------------------------- stars (upgrades)

func star(kind: String, id: String) -> int:
	return int(stars.get("%s:%s" % [kind, id], 1))


## [embers, dust] for the next star, or [] when maxed.
func star_cost(kind: String, id: String) -> Array:
	var s := star(kind, id)
	if s >= int(star_rules["star_max"]):
		return []
	var grade: String = item_def(kind, id).get("grade", "SR")
	return star_rules["costs"][grade][s - 1]


func can_upgrade_star(kind: String, id: String) -> bool:
	var c := star_cost(kind, id)
	return not c.is_empty() and embers >= int(c[0]) and star_dust >= int(c[1])


func upgrade_star(kind: String, id: String) -> bool:
	if not can_upgrade_star(kind, id):
		return false
	var c := star_cost(kind, id)
	embers -= int(c[0])
	star_dust -= int(c[1])
	stars["%s:%s" % [kind, id]] = star(kind, id) + 1
	save()
	return true


# ---------------------------------------------------------------- materials (open world)

## Moves everything in the world bag into the town's storage.
func bank(world) -> Dictionary:
	var moved: Dictionary = world.bag.duplicate()
	for id in moved:
		materials[id] = int(materials.get(id, 0)) + int(moved[id])
	world.bag.clear()
	_add("isle_trips", 1)
	var total := 0
	for id in moved:
		total += int(moved[id])
	_add("isle_banked", total)
	# Isle quests finish on the way home; they pay Embers and Grave Dice like road quests.
	last_bank_quests = _complete_quests()
	for q in last_bank_quests:
		embers += int(q["reward"])
		grave_dice += int(summon["dice_per_quest"])
	save()
	return moved


# ---------------------------------------------------------------- staged unlocks (v3.0)
# A new player sees only the Hollow Road, the party and the buildings. The rest opens as they play,
# so the town is not a wall of tabs on the first visit. Old saves already meet every condition.

func feature_unlocked(feature: String) -> bool:
	var runs := int(stats.get("runs", 0))
	match feature:
		"summon", "collection", "isle":
			return runs >= 1 or grave_dice > 0 or star_dust > 0
		"forge", "storage":
			return int(stats.get("isle_trips", 0)) >= 1 or not materials.is_empty() or not gear.is_empty()
	return true


func unlock_hint(feature: String) -> String:
	match feature:
		"summon", "collection", "isle":
			return "Finish one journey on the Hollow Road to unlock."
		"forge", "storage":
			return "Return from the Cursed Isle once to unlock."
	return ""


## Sells `amount` of a banked material for Soul Embers ("embers") or Star Dust ("dust").
func trade_material(id: String, amount: int, into: String, value: int) -> bool:
	if int(materials.get(id, 0)) < amount or amount <= 0:
		return false
	var trade: Dictionary = GameData.load_json("res://data/world.json")["trade"]
	var total := value * amount
	if into == "dust":
		var dust := int(floor(total * float(trade["dust_per_value"])))
		if dust <= 0:
			return false
		star_dust += dust
	else:
		embers += int(total * float(trade["embers_per_value"]))
	materials[id] = int(materials[id]) - amount
	if materials[id] <= 0:
		materials.erase(id)
	save()
	return true


# ---------------------------------------------------------------- crafting (the Forge)

func recipes() -> Array:
	return GameData.load_json("res://data/recipes.json")


func recipe(id: String) -> Dictionary:
	for r in recipes():
		if r["id"] == id:
			return r
	return {}


func can_craft(id: String) -> bool:
	var r := recipe(id)
	if r.is_empty() or embers < int(r["embers"]):
		return false
	for m in r["materials"]:
		if int(materials.get(m, 0)) < int(r["materials"][m]):
			return false
	return true


## Crafts one item from banked materials. Returns its uid, or -1.
func craft(id: String) -> int:
	if not can_craft(id):
		return -1
	var r := recipe(id)
	embers -= int(r["embers"])
	for m in r["materials"]:
		materials[m] = int(materials[m]) - int(r["materials"][m])
		if materials[m] <= 0:
			materials.erase(m)
	var uid := next_uid
	next_uid += 1
	gear.append({"uid": uid, "recipe": id})
	save()
	return uid


func gear_item(uid: int) -> Dictionary:
	for g in gear:
		if int(g["uid"]) == uid:
			return g
	return {}


## Who wears this item ("" if nobody).
func gear_owner(uid: int) -> String:
	for hero in equipped:
		for slot in equipped[hero]:
			if int(equipped[hero][slot]) == uid:
				return hero
	return ""


## Puts an item on a hero (taking it off anyone else). uid -1 empties the slot.
func equip_gear(hero_id: String, slot: String, uid: int) -> void:
	if uid >= 0:
		var prev := gear_owner(uid)
		if prev != "":
			equipped[prev].erase(slot)
	if not equipped.has(hero_id):
		equipped[hero_id] = {}
	if uid < 0:
		equipped[hero_id].erase(slot)
	else:
		equipped[hero_id][slot] = uid
	save()


## Feeds a crafted treat to a companion (v3.1). Stored like gear under the key "pet:<id>", slot "treat".
func feed_treat(pet_id: String, uid: int) -> bool:
	var g := gear_item(uid)
	if g.is_empty() or recipe(g["recipe"]).get("slot", "") != "treat" or not pet_id in owned_pets:
		return false
	equip_gear("pet:" + pet_id, "treat", uid)
	return true


## The treat a companion has been given, or {}.
func pet_treat(pet_id: String) -> Dictionary:
	var uid := int(equipped.get("pet:" + pet_id, {}).get("treat", -1))
	var g := gear_item(uid)
	return {} if g.is_empty() else recipe(g["recipe"])


## What each hero's gear does, for runs and the open world:
## { hero_id: { "weapon": {name, faces}, "armor": {name, hp, shield} } }
func gear_bonuses() -> Dictionary:
	var out := {}
	for hero in equipped:
		for slot in equipped[hero]:
			var g := gear_item(int(equipped[hero][slot]))
			if g.is_empty():
				continue
			var r := recipe(g["recipe"])
			if not out.has(hero):
				out[hero] = {}
			out[hero][slot] = r
	return out


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


## The boss that would guard the Hollow Road if the player set out now (3.4: shown in town).
func road_boss() -> Dictionary:
	var Run = load("res://scripts/core/run.gd")
	return Run.pick_road_boss(GameData.load_json("res://data/region1.json"), time_name(), stat("wins"))


func advance_time() -> void:
	_pass_time()
	save()


func quest_progress(q: Dictionary) -> int:
	if q["id"] in quests_done:
		return int(q["goal"])
	if q["stat"] in ["run_elites", "run_carves"]:
		return 0  # single-run goals show 0 until done
	return min(stat(q["stat"]), int(q["goal"]))


# ---------------------------------------------------------------- run save

static func has_saved_run() -> bool:
	return FileAccess.file_exists(RUN_SAVE_PATH) or FileAccess.file_exists(RUN_SAVE_PATH + ".bak")


static func save_run_data(data: Dictionary) -> void:
	GameData.safe_store(RUN_SAVE_PATH, data)


static func load_run_data() -> Dictionary:
	return GameData.safe_load(RUN_SAVE_PATH)


static func delete_saved_run() -> void:
	GameData.safe_delete(RUN_SAVE_PATH)
