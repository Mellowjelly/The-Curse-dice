extends RefCounted
## Dice combat rules. NO UI code in this file.
## The UI calls the public functions and listens to the signals.
## Keeping rules separate from the screen lets us add co-op multiplayer later.
##
## Round flow:
##   1. _start_round(): heroes roll their dice, monsters roll and show intents.
##   2. Player locks dice / rerolls / picks a target.
##   3. end_turn(): hero faces resolve, then monsters act, then a new round starts.

signal log_added(text: String)
signal state_changed
signal battle_ended(victory: bool)
signal damaged(unit: Dictionary, amount: int, blocked: int)  # for floating numbers in the UI
signal phase_changed(unit: Dictionary, text: String)          # boss second phase

const REROLLS_PER_TURN := 2
const MAX_FATE := 5
const FATE_REROLL_COST := 2
const FATE_TWIST_COST := 4      # set one die to any of its faces
const FATE_PER_PAIR := 1        # combos feed Fate (v0.3 critique: Fate was starved)
const FATE_PER_VICTORY := 1
const BURN_PER_FIRE := 2
const MAX_BURN := 4  # burn cannot stack forever (v0.3 critique)
const BLOOD_SELF_DAMAGE := 2

# Skills: heroes charge every round (+1 more if their die is part of a combo).
const START_CHARGE := 0
const CHARGE_PER_ROUND := 1
const CHARGE_PER_COMBO := 1
# Skill numbers (tunable by the designer).
const OATH_SHIELD := 5
const OATH_HP_COST := 2
const HOLLOW_FLAME_DAMAGE := 4
const HOLLOW_FLAME_BURN := 1
const HOLLOW_FLAME_HP_COST := 3
const LAST_RITE_HEAL := 3
const LAST_RITE_REVIVE_HP := 4
const LAST_RITE_HP_COST := 3

var rng := RandomNumberGenerator.new()
var heroes: Array = []    # Array[Dictionary] (units)
var monsters: Array = []  # Array[Dictionary] (units)
var fate := 0
var rerolls_left := 0
var target_index := 0
var round_number := 0
var finished := false
var pet: Dictionary = {}  # optional companion: { id, name, faces (d4), face, passive }
var bonus_fate_start := 0  # from the town's Fortune Teller
var twists := 0            # Fate Twists used (for quests)

# Pet passive numbers.
const PET_FIRST_STRIKE := 3
const PET_MEND := 1  # Candle Moth: heal all heroes after a won fight (applied by run.gd)


func _init(seed_value: int = -1) -> void:
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()


## Turns a JSON definition into a live unit with current HP, shield, etc.
static func make_unit(def: Dictionary) -> Dictionary:
	return {
		"id": def["id"],
		"name": def["name"],
		"max_hp": int(def["hp"]),
		"hp": int(def["hp"]),
		"shield": 0,
		"burn": 0,
		"faces": def["faces"].duplicate(true),
		"face": 0,        # index of the face currently showing
		"locked": false,
		"target": -1,     # monsters only: which hero they intend to hit
		"boss": def.get("boss", false),
		"skill": def.get("skill", {}),  # heroes only, see data/heroes.json
		"phase2": def.get("phase2", {}),  # monsters only: { "at": 0.5, "faces": [...], "text": "..." }
		"phased": false,
		"death_line": def.get("death_line", ""),
		"charge": 0,
	}


static func is_alive(unit: Dictionary) -> bool:
	return unit["hp"] > 0


## Short display name, e.g. "Aldric" for "Brother Aldric".
static func short_name(unit: Dictionary) -> String:
	return String(unit["id"]).capitalize()


static func current_face(unit: Dictionary) -> Dictionary:
	if unit.has("held_face"):
		return unit["held_face"]  # boss mid phase-change: keep the announced intent
	return unit["faces"][unit["face"]]


# ---------------------------------------------------------------- public API

## Starts a fight. Hero units are passed in (not copied) so HP carries over between fights.
func start_battle(hero_units: Array, monster_defs: Array) -> void:
	heroes = hero_units
	monsters = []
	for def in monster_defs:
		monsters.append(make_unit(def))
	for h in heroes:
		h["shield"] = 0
		h["burn"] = 0
		h["locked"] = false
		h["charge"] = START_CHARGE
	finished = false
	round_number = 0
	target_index = 0
	if bonus_fate_start > 0:
		fate = min(MAX_FATE, fate + bonus_fate_start)
	_apply_pet_battle_start()
	_start_round()


func toggle_lock(hero_index: int) -> void:
	if finished or hero_index < 0 or hero_index >= heroes.size():
		return
	var h: Dictionary = heroes[hero_index]
	if not is_alive(h):
		return
	h["locked"] = not h["locked"]
	state_changed.emit()


func reroll() -> bool:
	if finished or rerolls_left <= 0:
		return false
	for h in heroes:
		if is_alive(h) and not h["locked"]:
			h["face"] = rng.randi_range(0, h["faces"].size() - 1)
	rerolls_left -= 1
	state_changed.emit()
	return true


## Spend Fate Points to buy one extra reroll this turn.
func fate_reroll() -> bool:
	if finished or fate < FATE_REROLL_COST:
		return false
	fate -= FATE_REROLL_COST
	rerolls_left += 1
	_log("Fate bends: +1 reroll (-%d Fate)" % FATE_REROLL_COST)
	state_changed.emit()
	return true


## Fate Twist: spend Fate to turn a hero's die to the face of your choice.
func fate_twist(hero_index: int, face_index: int) -> bool:
	if finished or fate < FATE_TWIST_COST or hero_index < 0 or hero_index >= heroes.size():
		return false
	var h: Dictionary = heroes[hero_index]
	if not is_alive(h) or face_index < 0 or face_index >= h["faces"].size():
		return false
	fate -= FATE_TWIST_COST
	twists += 1
	h["face"] = face_index
	h["locked"] = true
	_log("* Fate twists %s's die to %s %d (-%d Fate)" % [short_name(h), String(h["faces"][face_index]["type"]).to_upper(),
		int(h["faces"][face_index]["value"]), FATE_TWIST_COST])
	state_changed.emit()
	return true


func set_target(monster_index: int) -> void:
	if monster_index >= 0 and monster_index < monsters.size() and is_alive(monsters[monster_index]):
		target_index = monster_index
		state_changed.emit()


## Counts showing faces by type (blanks ignored), e.g. { "attack": 2, "heal": 1 }.
func compute_combos() -> Dictionary:
	var counts := {}
	for h in heroes:
		if not is_alive(h):
			continue
		var t: String = current_face(h)["type"]
		if t == "blank":
			continue
		counts[t] = counts.get(t, 0) + 1
	return counts


## Combo rule: 2 of the same type = +1 each, 3 of the same type = double.
static func effective_value(face: Dictionary, combos: Dictionary) -> int:
	var v := int(face["value"])
	var c: int = combos.get(face["type"], 0)
	if c >= 3:
		return v * 2
	if c >= 2:
		return v + 1
	return v


static func skill_cost(h: Dictionary) -> int:
	return int(h["skill"].get("cost", 0))


func can_use_skill(hero_index: int) -> bool:
	if finished or hero_index < 0 or hero_index >= heroes.size():
		return false
	var h: Dictionary = heroes[hero_index]
	return is_alive(h) and not h["skill"].is_empty() and h["charge"] >= skill_cost(h)


## Uses a hero's special skill right away (during the planning phase).
func use_skill(hero_index: int) -> bool:
	if not can_use_skill(hero_index):
		return false
	var h: Dictionary = heroes[hero_index]
	var who := short_name(h)
	h["charge"] = 0
	_log("* %s uses %s!" % [who, h["skill"]["name"]])
	match h["skill"]["id"]:
		"broken_oath":
			# Taunt: every monster that plans a single-target attack now targets this hero.
			h["shield"] += OATH_SHIELD
			for m in monsters:
				if is_alive(m) and current_face(m)["type"] == "attack":
					m["target"] = hero_index
			_log("%s gains %d shield and draws every single-target attack to himself" % [who, OATH_SHIELD])
			var oath_cost: int = min(OATH_HP_COST, h["hp"] - 1)
			if oath_cost > 0:
				h["hp"] -= oath_cost
				_log("The broken oath bleeds %s (-%d HP)" % [who, oath_cost])
		"hollow_flame":
			for m in monsters:
				if is_alive(m):
					_damage(m, HOLLOW_FLAME_DAMAGE, who, true)
					if is_alive(m):
						m["burn"] = min(MAX_BURN, m["burn"] + HOLLOW_FLAME_BURN)
			var cost: int = min(HOLLOW_FLAME_HP_COST, h["hp"] - 1)
			if cost > 0:
				h["hp"] -= cost
				_log("The flame feeds on %s (-%d HP)" % [who, cost])
		"last_rite":
			var revived := false
			for ally in heroes:
				if is_alive(ally):
					ally["hp"] = min(ally["max_hp"], ally["hp"] + LAST_RITE_HEAL)
				elif not revived:
					# Bring back one fallen ally and give them a fresh roll.
					revived = true
					ally["hp"] = LAST_RITE_REVIVE_HP
					ally["face"] = rng.randi_range(0, ally["faces"].size() - 1)
					ally["locked"] = false
					_log("%s rises from death!" % ally["name"])
			_log("All allies heal %d" % LAST_RITE_HEAL)
			# Dark price: the faithless priest pays with his own life force.
			var rite_cost: int = min(LAST_RITE_HP_COST, h["hp"] - 1)
			if rite_cost > 0:
				h["hp"] -= rite_cost
				_log("%s's faith is paid in blood (-%d HP)" % [who, rite_cost])
		_:
			push_error("Unknown skill id: %s" % h["skill"]["id"])
	if _all_dead(monsters):
		_finish(true)
	else:
		state_changed.emit()
	return true


func end_turn() -> void:
	if finished:
		return
	var combos := compute_combos()
	_gain_charge(combos)
	var fate_gain := 0
	for t in combos:
		if combos[t] >= 3:
			_log("COMBO! Triple %s - values doubled" % t.to_upper())
			fate_gain += FATE_PER_PAIR
		elif combos[t] >= 2:
			_log("Combo: pair of %s - +1 each" % t.to_upper())
			fate_gain += FATE_PER_PAIR
	if fate_gain > 0:
		gain_fate(fate_gain, "The combo feeds your Fate")

	for h in heroes:
		if not is_alive(h):
			continue
		var face := current_face(h)
		_apply_hero_face(h, face, effective_value(face, combos))
		if _all_dead(monsters):
			_finish(true)
			return

	if not pet.is_empty():
		_apply_pet_face()
		if _all_dead(monsters):
			_finish(true)
			return

	_monster_phase()
	if not finished:
		_start_round()


## Short text describing what a monster plans to do, for the UI.
func intent_text(monster: Dictionary) -> String:
	var face := current_face(monster)
	var v := int(face["value"])
	match face["type"]:
		"attack":
			var t: int = monster["target"]
			var who: String = short_name(heroes[t]) if t >= 0 else "?"
			return "Attack %d -> %s" % [v, who]
		"sweep":
			return "Sweep %d -> ALL" % v
		"shield":
			return "Shield %d" % v
		"heal":
			return "Heal %d" % v
		_:
			return "Hesitates"


# ---------------------------------------------------------------- internals

func _start_round() -> void:
	round_number += 1
	rerolls_left = REROLLS_PER_TURN + _overflow_rerolls
	_overflow_rerolls = 0
	if not pet.is_empty():
		pet["face"] = rng.randi_range(0, pet["faces"].size() - 1)
		if pet["passive"] == "lucky":
			rerolls_left += 1
	for h in heroes:
		h["shield"] = 0
		h["locked"] = false
		if is_alive(h):
			h["face"] = rng.randi_range(0, h["faces"].size() - 1)
	for m in monsters:
		m.erase("held_face")
		if is_alive(m):
			m["face"] = rng.randi_range(0, m["faces"].size() - 1)
			m["target"] = _random_alive_index(heroes)
	if not is_alive(monsters[target_index]):
		target_index = _first_alive_index(monsters)
	_log("--- Round %d ---" % round_number)
	state_changed.emit()


func _gain_charge(combos: Dictionary) -> void:
	for h in heroes:
		if not is_alive(h) or h["skill"].is_empty():
			continue
		var gain := CHARGE_PER_ROUND
		if combos.get(current_face(h)["type"], 0) >= 2:
			gain += CHARGE_PER_COMBO
		h["charge"] = min(skill_cost(h), h["charge"] + gain)


func _apply_hero_face(h: Dictionary, face: Dictionary, value: int) -> void:
	var who := short_name(h)
	match face["type"]:
		"attack":
			var t := _get_target()
			_damage(t, value, who)
		"fire":
			var t := _get_target()
			_damage(t, value, who)
			if is_alive(t):
				t["burn"] = min(MAX_BURN, t["burn"] + BURN_PER_FIRE)
				_log("%s is burning (%d)" % [t["name"], t["burn"]])
		"blood":
			var t := _get_target()
			_damage(t, value, who + " (blood magic)")
			# Dark price: blood magic hurts the caster, but never kills them.
			var cost: int = min(BLOOD_SELF_DAMAGE, h["hp"] - 1)
			if cost > 0:
				h["hp"] -= cost
				_log("%s pays %d HP in blood" % [who, cost])
		"cleave":
			for m in monsters:
				if is_alive(m):
					_damage(m, value, who)
		"shield":
			h["shield"] += value
			_log("%s raises a shield (%d)" % [who, value])
		"guard":
			for ally in heroes:
				if is_alive(ally):
					ally["shield"] += value
			_log("%s guards the party (+%d shield all)" % [who, value])
		"heal":
			var ally := _lowest_hp_ratio(heroes)
			var healed: int = min(value, ally["max_hp"] - ally["hp"])
			ally["hp"] += healed
			var extra := value - healed
			if healed > 0:
				_log("%s heals %s for %d" % [who, short_name(ally), healed])
			if extra > 0:
				# Healing nobody needs is not wasted: it becomes a ward.
				ally["shield"] += extra
				_log("%s's prayer wards %s (+%d shield)" % [who, short_name(ally), extra])
		"blank":
			gain_fate(1, "%s rolls nothing..." % who)


func _apply_pet_battle_start() -> void:
	if pet.is_empty():
		return
	match pet["passive"]:
		"fate_start":
			fate = min(MAX_FATE, fate + 2)
			_log("%s caws: +2 Fate" % pet["name"])
		"first_strike":
			var i := _random_alive_index(monsters)
			if i >= 0:
				_damage(monsters[i], PET_FIRST_STRIKE, pet["name"])


func _apply_pet_face() -> void:
	var face: Dictionary = pet["faces"][pet["face"]]
	var v := int(face["value"])
	match face["type"]:
		"attack":
			_damage(_get_target(), v, pet["name"])
		"fire":
			var t := _get_target()
			_damage(t, v, pet["name"])
			if is_alive(t):
				t["burn"] = min(MAX_BURN, t["burn"] + 1)
		"heal":
			var ally := _lowest_hp_ratio(heroes)
			if not ally.is_empty():
				ally["hp"] = min(ally["max_hp"], ally["hp"] + v)
				_log("%s heals %s for %d" % [pet["name"], short_name(ally), v])
		"shield":
			var ally := _lowest_hp_ratio(heroes)
			if not ally.is_empty():
				ally["shield"] += v
				_log("%s shields %s (%d)" % [pet["name"], short_name(ally), v])


## Adds Fate. Fate beyond the cap is not wasted: it becomes a free reroll next round.
var _overflow_rerolls := 0

func gain_fate(amount: int, reason: String) -> void:
	var room := MAX_FATE - fate
	var added: int = min(amount, room)
	fate += added
	var over := amount - added
	if added > 0:
		_log("%s +%d Fate" % [reason, added])
	if over > 0:
		_overflow_rerolls += over
		_log("%s Fate overflows: +%d free reroll next round" % [reason, over])


func _monster_phase() -> void:
	# Upkeep: monster shields expire, burn ticks (burn ignores shields).
	for m in monsters:
		if not is_alive(m):
			continue
		m["shield"] = 0
		if m["burn"] > 0:
			m["hp"] = max(0, m["hp"] - m["burn"])
			_log("%s burns for %d" % [m["name"], m["burn"]])
			_check_phase(m)
			m["burn"] -= 1
			if not is_alive(m):
				m["burn"] = 0
				_log("%s is reduced to ash!" % m["name"])
	if _all_dead(monsters):
		_finish(true)
		return

	for m in monsters:
		if not is_alive(m):
			continue
		var face := current_face(m)
		var v := int(face["value"])
		match face["type"]:
			"attack":
				var t: int = m["target"]
				if t < 0 or not is_alive(heroes[t]):
					t = _random_alive_index(heroes)
				_damage(heroes[t], v, m["name"])
			"sweep":
				_log("%s sweeps the whole party!" % m["name"])
				for h in heroes:
					if is_alive(h):
						_damage(h, v, m["name"])
			"shield":
				m["shield"] += v
				_log("%s shields itself (%d)" % [m["name"], v])
			"heal":
				var ally := _lowest_hp_ratio(monsters)
				var healed: int = min(v, ally["max_hp"] - ally["hp"])
				ally["hp"] += healed
				if healed > 0:
					_log("%s heals %s for %d" % [m["name"], ally["name"], healed])
				if v - healed > 0:
					ally["shield"] += v - healed
					_log("%s wards %s (+%d shield)" % [m["name"], ally["name"], v - healed])
			_:
				_log("%s hesitates" % m["name"])
		if _all_dead(heroes):
			_finish(false)
			return


func _damage(unit: Dictionary, amount: int, source: String, pierce := false) -> void:
	if unit.is_empty() or not is_alive(unit):
		return
	var absorbed: int = 0 if pierce else min(unit["shield"], amount)
	unit["shield"] -= absorbed
	var dealt := amount - absorbed
	unit["hp"] = max(0, unit["hp"] - dealt)
	var text := "%s hits %s for %d" % [source, unit["name"], dealt]
	if absorbed > 0:
		text += " (%d blocked)" % absorbed
	_log(text)
	damaged.emit(unit, dealt, absorbed)
	_check_phase(unit)
	if not is_alive(unit):
		unit["burn"] = 0
		unit["shield"] = 0
		_log("%s falls!" % unit["name"])


## Marks a boss for its second phase when its HP drops low enough.
## The new faces take over at the start of the next round, so this round's intent stays honest.
func _check_phase(unit: Dictionary) -> void:
	var p2: Dictionary = unit.get("phase2", {})
	if p2.is_empty() or unit["phased"] or not is_alive(unit):
		return
	if unit["hp"] <= int(unit["max_hp"] * float(p2["at"])):
		unit["held_face"] = current_face(unit)
		unit["phased"] = true
		unit["faces"] = p2["faces"].duplicate(true)
		_log("!! " + p2["text"])
		phase_changed.emit(unit, p2["text"])


func _get_target() -> Dictionary:
	if target_index >= 0 and target_index < monsters.size() and is_alive(monsters[target_index]):
		return monsters[target_index]
	target_index = _first_alive_index(monsters)
	return monsters[target_index] if target_index >= 0 else {}


func _lowest_hp_ratio(units: Array) -> Dictionary:
	var best: Dictionary = {}
	var best_ratio := 2.0
	for u in units:
		if not is_alive(u):
			continue
		var r := float(u["hp"]) / float(u["max_hp"])
		if r < best_ratio:
			best_ratio = r
			best = u
	return best


func _random_alive_index(units: Array) -> int:
	var alive: Array[int] = []
	for i in units.size():
		if is_alive(units[i]):
			alive.append(i)
	if alive.is_empty():
		return -1
	return alive[rng.randi_range(0, alive.size() - 1)]


static func _first_alive_index(units: Array) -> int:
	for i in units.size():
		if is_alive(units[i]):
			return i
	return -1


static func _all_dead(units: Array) -> bool:
	return _first_alive_index(units) == -1


func _finish(victory: bool) -> void:
	finished = true
	if victory:
		fate = min(MAX_FATE, fate + FATE_PER_VICTORY)
		for m in monsters:
			if m.get("death_line", "") != "":
				_log("!! " + m["death_line"])
	_log("VICTORY!" if victory else "Your party has fallen...")
	state_changed.emit()
	battle_ended.emit(victory)


func _log(text: String) -> void:
	log_added.emit(text)
