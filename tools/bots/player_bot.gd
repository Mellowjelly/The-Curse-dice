extends RefCounted
## A simulated player. Plays combat through the same public API the UI uses,
## so bots test exactly what a human can do.
##
## Styles:
##   "newbie"    - casual first-timer: rerolls blanks only, fires skills ASAP, ignores Fate & targeting.
##   "tactician" - careful planner: reads intents, keeps defense when danger is high, focuses fire,
##                 saves skills for the right moment, spends Fate on blanks.
##   "berserker" - aggressive gambler: chases damage and combos, ignores defense, burns Fate freely.

const Combat = preload("res://scripts/core/combat.gd")

var style: String
var notes: Array[String] = []   # human-readable reasoning, written into transcripts
var stats := {
	"rerolls": 0, "fate_rerolls": 0, "skills": {}, "locks": 0, "turns": 0,
}


func _init(play_style: String, seed_value: int = 0) -> void:
	style = play_style
	_rng.seed = seed_value


func note(text: String) -> void:
	notes.append("[%s] %s" % [style.to_upper(), text])


## Plays one full player turn: skills, target, locks/rerolls, then end turn.
func play_turn(c: Combat) -> void:
	stats["turns"] += 1
	_use_skills(c)
	if c.finished:
		return
	_pick_target(c)
	_handle_dice(c)
	if c.finished:
		return
	var final: Array[String] = []
	for h in c.heroes:
		if Combat.is_alive(h):
			var f := Combat.current_face(h)
			final.append("%s %s %d" % [Combat.short_name(h), f["type"], int(f["value"])])
	note("ends turn with: " + ", ".join(final))
	c.end_turn()


# ---------------------------------------------------------------- threat reading

## Damage each hero will take this round if nothing changes: { hero_index: damage }.
func incoming(c: Combat) -> Dictionary:
	var dmg := {}
	for i in c.heroes.size():
		dmg[i] = 0
	for m in c.monsters:
		if not Combat.is_alive(m):
			continue
		var f := Combat.current_face(m)
		var v := int(f["value"])
		match f["type"]:
			"attack":
				if m["target"] >= 0:
					dmg[m["target"]] += v
			"sweep":
				for i in c.heroes.size():
					if Combat.is_alive(c.heroes[i]):
						dmg[i] += v
	return dmg


func total_incoming(c: Combat) -> int:
	var t := 0
	for v in incoming(c).values():
		t += v
	return t


func _party_missing_hp(c: Combat) -> int:
	var m := 0
	for h in c.heroes:
		if Combat.is_alive(h):
			m += h["max_hp"] - h["hp"]
	return m


func _alive_count(units: Array) -> int:
	return units.filter(func(u): return Combat.is_alive(u)).size()


# ---------------------------------------------------------------- skills

func _use_skills(c: Combat) -> void:
	for i in c.heroes.size():
		if not c.can_use_skill(i):
			continue
		var h: Dictionary = c.heroes[i]
		var id: String = h["skill"]["id"]
		var use := false
		match style:
			"newbie", "berserker":
				use = true
			"tactician":
				use = _tactician_wants_skill(c, i, id)
		if use:
			stats["skills"][id] = stats["skills"].get(id, 0) + 1
			note("uses %s (incoming %d, party missing %d HP)" % [id, total_incoming(c), _party_missing_hp(c)])
			c.use_skill(i)
			if c.finished:
				return


func _tactician_wants_skill(c: Combat, i: int, id: String) -> bool:
	var h: Dictionary = c.heroes[i]
	match id:
		"broken_oath":
			# Worth it when attacks are aimed at someone fragile.
			var inc := incoming(c)
			for j in inc:
				if j != i and inc[j] >= 6 and c.heroes[j]["hp"] <= inc[j] + 4:
					return true
			return total_incoming(c) >= 12
		"hollow_flame":
			if h["hp"] <= 5:
				return false
			var alive := _alive_count(c.monsters)
			var killable := c.monsters.filter(func(m): return Combat.is_alive(m) and m["hp"] + m["shield"] <= 4).size()
			return alive >= 2 or killable >= 1 or c.monsters.any(func(m): return m["boss"] and Combat.is_alive(m))
		"last_rite":
			var dead := c.heroes.any(func(x): return not Combat.is_alive(x))
			return dead or _party_missing_hp(c) >= 12
		_:
			return true


# ---------------------------------------------------------------- targeting

func _pick_target(c: Combat) -> void:
	if style == "newbie":
		return  # never touches targeting
	var best := -1
	var best_score := -INF
	for i in c.monsters.size():
		var m: Dictionary = c.monsters[i]
		if not Combat.is_alive(m):
			continue
		var f := Combat.current_face(m)
		var threat := int(f["value"]) if f["type"] in ["attack", "sweep"] else 0
		if f["type"] == "sweep":
			threat *= 3
		if f["type"] == "heal":
			threat += 3  # healers drag fights out
		var ehp: int = m["hp"] + m["shield"]
		# Prefer enemies we can finish, then dangerous ones.
		var score := threat * 2.0 - ehp * 0.5 + (15.0 if ehp <= 6 else 0.0)
		if style == "berserker":
			score = -ehp  # just hit the weakest
		if score > best_score:
			best_score = score
			best = i
	if best >= 0 and best != c.target_index:
		c.set_target(best)


# ---------------------------------------------------------------- dice

## How much this bot wants a given face right now.
func face_score(c: Combat, hero_index: int, face: Dictionary) -> float:
	var h: Dictionary = c.heroes[hero_index]
	var v := float(face["value"])
	var danger := float(total_incoming(c))
	var my_incoming := float(incoming(c)[hero_index])
	var missing := float(_party_missing_hp(c))
	match style:
		"berserker":
			match face["type"]:
				"attack", "fire": return v * 1.5
				"blood": return v * 1.6
				"blank": return 0.0
				_: return v * 0.4
		_:
			match face["type"]:
				"attack": return v
				"fire": return v + 1.5
				"blood": return v - (3.0 if h["hp"] <= 6 else 1.0)
				"shield": return min(v, my_incoming) * 1.1
				"guard": return min(v * _alive_count(c.heroes), danger) * 0.9
				"heal": return min(v, missing) * (1.3 if missing >= 8 else 0.8)
				"blank": return 0.0
	return 0.0


func _handle_dice(c: Combat) -> void:
	match style:
		"newbie":
			# Rerolls once if anyone shows a blank, otherwise doesn't bother.
			if c.heroes.any(func(h): return Combat.is_alive(h) and Combat.current_face(h)["type"] == "blank"):
				for i in c.heroes.size():
					var h: Dictionary = c.heroes[i]
					if Combat.is_alive(h) and Combat.current_face(h)["type"] != "blank" and not h["locked"]:
						c.toggle_lock(i)
				if c.reroll():
					stats["rerolls"] += 1
		_:
			_smart_reroll_loop(c)


func _smart_reroll_loop(c: Combat) -> void:
	var guard := 0
	while guard < 6:
		guard += 1
		var to_reroll: Array[int] = []
		for i in c.heroes.size():
			var h: Dictionary = c.heroes[i]
			if not Combat.is_alive(h):
				continue
			var faces: Array = h["faces"]
			var avg := 0.0
			for f in faces:
				avg += face_score(c, i, f)
			avg /= faces.size()
			var cur := face_score(c, i, Combat.current_face(h))
			var keep := cur >= avg
			if keep != h["locked"]:
				c.toggle_lock(i)
				if keep:
					stats["locks"] += 1
			if not keep:
				to_reroll.append(i)
		if to_reroll.is_empty():
			return
		if c.rerolls_left <= 0:
			var wants_fate := style == "berserker" or c.heroes.any(
				func(h): return Combat.is_alive(h) and Combat.current_face(h)["type"] == "blank")
			if wants_fate and c.fate_reroll():
				stats["fate_rerolls"] += 1
				note("spends Fate for an extra reroll")
			else:
				return
		c.reroll()
		stats["rerolls"] += 1


# ================================================================ map / run decisions

const Run = preload("res://scripts/core/run.gd")


func _party_hp_ratio(run: Run) -> float:
	var hp := 0
	var mx := 0
	for h in run.heroes:
		hp += max(h["hp"], 0)
		mx += h["max_hp"]
	return float(hp) / float(mx)


func _tile_score(run: Run, tile_type: String) -> float:
	var hp := _party_hp_ratio(run)
	var dead := run.heroes.any(func(h): return not Combat.is_alive(h))
	match style:
		"berserker":
			return {"elite": 10, "fight": 8, "event": 6, "chest": 5, "boss": 9}.get(tile_type, 1)
		"tactician":
			if hp < 0.45 or dead:
				return {"rest": 10, "shop": 8 if run.gold >= 20 else 1, "chest": 6, "event": 4,
					"fight": 2, "elite": -5, "boss": 0}.get(tile_type, 1)
			return {"elite": 7 if hp > 0.75 else 3, "fight": 6, "chest": 5, "event": 5,
				"shop": 4 if run.gold >= 35 else 1, "rest": 2, "boss": 5}.get(tile_type, 1)
	return 0.0


## Plays one non-combat decision. Returns false if nothing could be done.
func play_run_step(run: Run) -> void:
	match run.phase:
		"combat":
			play_turn(run.combat)
		"map":
			if run.move_options.is_empty():
				run.roll_move()
			var scores := []
			for i in run.move_options.size():
				var t: String = run.board[run.destination(run.move_options[i])]["type"]
				scores.append(_tile_score(run, t))
			if style == "tactician" and scores.max() < 3 and run.combat.fate >= 2 and run.reroll_move():
				note("rerolls movement with Fate (options were bad)")
				return
			var pick := 0
			if style != "newbie":
				pick = scores.find(scores.max())
			var dest: int = run.destination(run.move_options[pick])
			note("moves %d -> tile %d (%s). Options: %s" % [run.move_options[pick], dest,
				run.board[dest]["type"], str(run.move_options.map(func(m): return run.board[run.destination(m)]["type"]))])
			run.choose_move(pick)
		"reward":
			var best := 0
			if style != "newbie":
				var best_score := -INF
				for i in run.carve_offers.size():
					var o: Dictionary = run.carve_offers[i]
					var old: Dictionary = run.heroes[o["hero"]]["faces"][o["face"]]
					var sc := float(o["new"]["value"]) - float(old["value"]) + (3.0 if old["type"] == "blank" else 0.0)
					if style == "berserker" and o["new"]["type"] in ["attack", "fire", "blood"]:
						sc += 2.0
					if sc > best_score:
						best_score = sc
						best = i
			note("carves: " + run.carve_offers[best]["text"])
			run.choose_carving(best)
		"event":
			if run.event_result != "":
				run.close_event()
				return
			var opts: Array = run.event["options"]
			var pick := 0
			match style:
				"newbie":
					pick = rng_pick(opts.size())
				"tactician":
					# Take the powerful option unless it costs HP we can't afford.
					var risky := str(opts[0]["effects"]).contains("\"hp\"") or str(opts[0]["effects"]).contains("max_hp") or str(opts[0]["effects"]).contains("fight")
					pick = 1 if (risky and _party_hp_ratio(run) < 0.5) else 0
			if not run.can_choose_event_option(pick):
				pick = 1 - pick
			note("event '%s': picks \"%s\"" % [run.event["title"], opts[pick]["label"]])
			run.choose_event_option(pick)
		"shop":
			var wants: Array = []
			match style:
				"newbie":
					wants = ["tonic"]
				"berserker":
					wants = ["carving", "fate_shard"]
				"tactician":
					wants = ["resurrect"]
					if _party_hp_ratio(run) < 0.6:
						wants.append("tonic")
					wants.append_array(["carving", "fate_shard"])
			for id in wants:
				if run.can_buy(id):
					note("buys %s (gold %d)" % [id, run.gold])
					run.buy(id)
					return
			run.leave_shop()
		"rest":
			var heal := true
			match style:
				"tactician":
					heal = _party_hp_ratio(run) < 0.6 or run.heroes.any(func(h): return not Combat.is_alive(h))
				"berserker":
					heal = _party_hp_ratio(run) < 0.35
			note("rests: %s (party HP %.0f%%)" % ["heal" if heal else "carve", 100 * _party_hp_ratio(run)])
			if heal:
				run.rest_heal()
			else:
				run.rest_carve()


var _rng := RandomNumberGenerator.new()

func rng_pick(n: int) -> int:
	return _rng.randi_range(0, n - 1)
