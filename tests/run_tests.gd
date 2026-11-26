extends SceneTree
## Automated tests for the combat rules and game data.
## Run:  godot --headless --path . -s tests/run_tests.gd
## Exit code 0 = all passed, 1 = something failed.

const Combat = preload("res://scripts/core/combat.gd")
const GameData = preload("res://scripts/core/game_data.gd")
const Run = preload("res://scripts/core/run.gd")

var _failures := 0
var _checks := 0


func _init() -> void:
	test_data_is_valid()
	test_shield_absorbs_damage()
	test_combo_values()
	test_blank_gives_fate_capped()
	test_fate_reroll()
	test_locked_die_does_not_change()
	test_blood_never_kills_caster()
	test_skill_charging()
	test_broken_oath_taunts()
	test_hollow_flame_hits_all_and_costs_hp()
	test_last_rite_revives_one()
	test_skill_finishing_blow_wins()
	test_full_runs_finish()
	test_board_rules()
	test_carving_changes_die()
	test_shop_and_rest()
	test_event_gold_requirement()
	print("\n%d checks, %d failed" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func check(cond: bool, message: String) -> void:
	_checks += 1
	if not cond:
		_failures += 1
		print("FAIL: " + message)


func _heroes() -> Array:
	return GameData.load_heroes().map(func(d): return Combat.make_unit(d))


func _monster(id: String) -> Dictionary:
	return GameData.load_monsters()[id]


# ---------------------------------------------------------------- tests

func test_data_is_valid() -> void:
	var monsters := GameData.load_monsters()
	var all_defs: Array = GameData.load_heroes() + monsters.values()
	for def in all_defs:
		check(def["faces"].size() == 6, "%s must have 6 faces" % def["id"])
		check(int(def["hp"]) > 0, "%s must have hp > 0" % def["id"])
		for f in def["faces"] + def.get("carve_pool", []) + def.get("phase2", {}).get("faces", []):
			check(f["type"] in GameData.FACE_TYPES, "%s has unknown face type %s" % [def["id"], f["type"]])
	var region := GameData.load_region()
	for pool in region["encounters"]:
		for enc in region["encounters"][pool]:
			for id in enc:
				check(monsters.has(id), "region pool %s uses unknown monster %s" % [pool, id])
	var ops := ["hp", "max_hp", "gold", "fate", "revive", "carve", "fight", "chance"]
	for ev in GameData.load_events():
		check(ev["options"].size() >= 2, "event %s needs at least 2 options" % ev["id"])
		for opt in ev["options"]:
			for e in opt["effects"]:
				check(e["op"] in ops, "event %s uses unknown op %s" % [ev["id"], e["op"]])


func test_shield_absorbs_damage() -> void:
	var c := Combat.new(1)
	var h := Combat.make_unit(GameData.load_heroes()[0])
	h["shield"] = 3
	c._damage(h, 5, "test")
	check(h["shield"] == 0, "shield should be used up")
	check(h["hp"] == h["max_hp"] - 2, "only 2 damage should get through a 3 shield")


func test_combo_values() -> void:
	var face := {"type": "attack", "value": 3}
	check(Combat.effective_value(face, {"attack": 1}) == 3, "single attack = base value")
	check(Combat.effective_value(face, {"attack": 2}) == 4, "pair = +1")
	check(Combat.effective_value(face, {"attack": 3}) == 6, "triple = x2")


func test_blank_gives_fate_capped() -> void:
	var c := Combat.new(2)
	c.start_battle(_heroes(), [_monster("rotting_bishop")])
	c.fate = Combat.MAX_FATE - 1
	for h in c.heroes:
		h["faces"] = [{"type": "blank", "value": 0}]
		h["face"] = 0
	c.end_turn()
	check(c.fate == Combat.MAX_FATE, "fate should cap at MAX_FATE, got %d" % c.fate)


func test_fate_reroll() -> void:
	var c := Combat.new(3)
	c.start_battle(_heroes(), [_monster("ghoul")])
	c.fate = Combat.FATE_REROLL_COST - 1
	check(not c.fate_reroll(), "fate reroll must fail without enough fate")
	c.fate = Combat.FATE_REROLL_COST
	var before := c.rerolls_left
	check(c.fate_reroll(), "fate reroll should succeed")
	check(c.rerolls_left == before + 1 and c.fate == 0, "fate reroll gives +1 reroll and costs fate")


func test_locked_die_does_not_change() -> void:
	var c := Combat.new(4)
	c.start_battle(_heroes(), [_monster("ghoul")])
	c.toggle_lock(0)
	var face_before: int = c.heroes[0]["face"]
	for i in 20:
		c.rerolls_left = 1
		c.reroll()
		check(c.heroes[0]["face"] == face_before, "locked die must not change on reroll")


func test_blood_never_kills_caster() -> void:
	var c := Combat.new(5)
	c.start_battle(_heroes(), [_monster("rotting_bishop")])
	var lys: Dictionary = c.heroes[1]
	lys["hp"] = 1
	c._apply_hero_face(lys, {"type": "blood", "value": 6}, 6)
	check(lys["hp"] == 1, "blood magic must not kill the caster")


func test_skill_charging() -> void:
	var c := Combat.new(6)
	c.start_battle(_heroes(), [_monster("rotting_bishop")])
	check(c.heroes[0]["charge"] == Combat.START_CHARGE, "heroes start a fight with START_CHARGE")
	check(not c.can_use_skill(0), "skill must not be usable before it is charged")
	check(not c.use_skill(0), "use_skill must fail when not charged")
	# Force a pair combo for heroes 0 and 1; hero 2 has no combo.
	c.heroes[0]["faces"] = [{"type": "shield", "value": 1}]
	c.heroes[1]["faces"] = [{"type": "shield", "value": 1}]
	c.heroes[2]["faces"] = [{"type": "heal", "value": 1}]
	for h in c.heroes:
		h["face"] = 0
		h["hp"] = 999  # make sure nobody dies in this test
		h["max_hp"] = 999
	var start := Combat.START_CHARGE
	c.end_turn()
	var combo_gain := Combat.CHARGE_PER_ROUND + Combat.CHARGE_PER_COMBO
	check(c.heroes[0]["charge"] == start + combo_gain, "combo should give extra charge (got %d)" % c.heroes[0]["charge"])
	check(c.heroes[2]["charge"] == start + Combat.CHARGE_PER_ROUND, "no combo = normal charge (got %d)" % c.heroes[2]["charge"])
	for i in 10:
		c.end_turn()
	for i in 3:
		var cost := Combat.skill_cost(c.heroes[i])
		check(c.heroes[i]["charge"] == cost, "charge must stop at skill cost")
		check(c.can_use_skill(i), "hero %d should be ready after many rounds" % i)


func test_broken_oath_taunts() -> void:
	var c := Combat.new(7)
	c.start_battle(_heroes(), [_monster("ghoul"), _monster("ghoul")])
	for m in c.monsters:
		m["face"] = 0  # attack 2
		m["target"] = 2
	c.heroes[0]["charge"] = Combat.skill_cost(c.heroes[0])
	check(c.use_skill(0), "Broken Oath should be usable at full charge")
	check(c.heroes[0]["charge"] == 0, "using a skill empties the charge")
	check(c.heroes[0]["shield"] == Combat.OATH_SHIELD, "Broken Oath gives shield")
	for m in c.monsters:
		check(m["target"] == 0, "all attacks should now target Varek")


func test_hollow_flame_hits_all_and_costs_hp() -> void:
	var c := Combat.new(8)
	c.start_battle(_heroes(), [_monster("ghoul"), _monster("cultist")])
	var lys: Dictionary = c.heroes[1]
	lys["charge"] = Combat.skill_cost(lys)
	var lys_hp: int = lys["hp"]
	c.use_skill(1)
	check(c.monsters[0]["hp"] == 12 - Combat.HOLLOW_FLAME_DAMAGE, "Hollow Flame hits monster 1")
	check(c.monsters[1]["hp"] == 10 - Combat.HOLLOW_FLAME_DAMAGE, "Hollow Flame hits monster 2")
	check(c.monsters[1]["burn"] == Combat.HOLLOW_FLAME_BURN, "Hollow Flame adds burn")
	check(lys["hp"] == lys_hp - Combat.HOLLOW_FLAME_HP_COST, "Hollow Flame costs Lys HP")
	lys["hp"] = 1
	lys["charge"] = Combat.skill_cost(lys)
	c.use_skill(1)
	check(lys["hp"] == 1, "Hollow Flame must not kill Lys")


func test_last_rite_revives_one() -> void:
	var c := Combat.new(9)
	c.start_battle(_heroes(), [_monster("ghoul")])
	c.heroes[0]["hp"] = 0
	c.heroes[1]["hp"] = 0
	c.heroes[2]["hp"] = 10
	c.heroes[2]["charge"] = Combat.skill_cost(c.heroes[2])
	c.use_skill(2)
	check(c.heroes[0]["hp"] == Combat.LAST_RITE_REVIVE_HP, "first fallen ally is revived")
	check(c.heroes[1]["hp"] == 0, "only ONE ally is revived")
	check(c.heroes[2]["hp"] == 10 + Combat.LAST_RITE_HEAL - Combat.LAST_RITE_HP_COST,
		"Aldric heals himself, then pays the HP cost")


func test_skill_finishing_blow_wins() -> void:
	var c := Combat.new(10)
	var won := [false]
	c.battle_ended.connect(func(v): won[0] = v)
	c.start_battle(_heroes(), [_monster("ghoul")])
	c.monsters[0]["hp"] = 3
	c.heroes[1]["charge"] = Combat.skill_cost(c.heroes[1])
	c.use_skill(1)
	check(c.finished and won[0], "killing the last enemy with a skill wins the battle")


## Plays full runs with the tactician bot to catch crashes, soft-locks and endless loops.
func test_full_runs_finish() -> void:
	var PlayerBot = load("res://tools/bots/player_bot.gd")
	var wins := 0
	var runs := 40
	for seed_value in runs:
		var run := Run.new(seed_value)
		var bot = PlayerBot.new("tactician", seed_value)
		var steps := 0
		while not run.is_over() and steps < 3000:
			bot.play_run_step(run)
			steps += 1
		check(run.is_over(), "run %d should end (stuck in phase %s at tile %d)" % [seed_value, run.phase, run.pos])
		if run.phase == "victory":
			wins += 1
	print("Tactician bot: %d/%d full runs won (use tools/playtest.gd for the full report)" % [wins, runs])


func test_board_rules() -> void:
	var run := Run.new(3)
	var last := run.board.size() - 1
	check(run.board[last]["type"] == "boss", "the last tile is the boss")
	check(run.board[last - 1]["type"] == "rest" and run.board[last - 1].get("gate", false), "a gate campfire sits before the boss")
	run.pos = last - 3
	check(run.destination(6) == last - 1, "movement stops at the gate campfire")
	run.pos = last - 1
	check(run.destination(6) == last, "movement from the campfire reaches the boss")


func test_carving_changes_die() -> void:
	var run := Run.new(4)
	run._offer_carving("map")
	check(run.phase == "reward" and run.carve_offers.size() == Run.CARVE_OFFERS, "carving offers 3 choices")
	var o: Dictionary = run.carve_offers[0]
	run.choose_carving(0)
	check(run.heroes[o["hero"]]["faces"][o["face"]] == o["new"], "the chosen carving changes the hero's die")
	check(run.phase == "map", "after carving we return to the map")


func test_shop_and_rest() -> void:
	var run := Run.new(5)
	run.phase = "shop"
	run.gold = 10
	check(not run.can_buy("tonic"), "cannot buy without enough gold")
	run.gold = 100
	run.heroes[0]["hp"] = 5
	run.buy("tonic")
	check(run.gold == 80 and run.heroes[0]["hp"] == 13, "tonic costs 20 and heals 8")
	check(not run.can_buy("tonic"), "each item once per visit")
	check(not run.can_buy("resurrect"), "cannot buy a revive when nobody is dead")
	run.leave_shop()
	run.phase = "rest"
	run.heroes[1]["hp"] = 0
	run.rest_heal()
	check(Combat.is_alive(run.heroes[1]), "resting revives the fallen")


func test_event_gold_requirement() -> void:
	var run := Run.new(6)
	for ev in run.events:
		if ev["id"] == "confessor":
			run.event = ev
	run.phase = "event"
	run.event_result = ""
	run.gold = 5
	check(not run.can_choose_event_option(0), "option needing 20 gold is locked with 5 gold")
	check(run.can_choose_event_option(1), "free option is always available")
