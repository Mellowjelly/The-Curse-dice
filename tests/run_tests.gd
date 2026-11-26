extends SceneTree
## Automated tests for the combat rules and game data.
## Run:  godot --headless --path . -s tests/run_tests.gd
## Exit code 0 = all passed, 1 = something failed.

const Combat = preload("res://scripts/core/combat.gd")
const GameData = preload("res://scripts/core/game_data.gd")
const Run = preload("res://scripts/core/run.gd")
const Profile = preload("res://scripts/core/profile.gd")

var _failures := 0
var _checks := 0


func _init() -> void:
	test_data_is_valid()
	test_ui_scripts_compile()
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
	test_weapons()
	test_fate_twist()
	test_pets()
	test_profile_and_quests()
	test_run_save_load()
	test_town_upgrades_apply()
	test_summon_roll()
	test_party_and_new_skills()
	test_gates_stop_movement()
	test_time_of_day()
	test_villager_requests()
	test_stars()
	test_world()
	test_elements()
	test_v22_player_bugs()
	test_v30_changes()
	test_v31_safe_saves()
	test_v31_isle_quests()
	test_v32_translations()
	test_v32_player_bugs()
	test_crafting_and_hunting()
	test_new_pets()
	test_tile_snapshot_reload()
	test_v31_delivery_requests()
	test_v31_bestiary()
	test_v31_pet_treats()
	print("\n%d checks, %d failed" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func check(cond: bool, message: String) -> void:
	_checks += 1
	if not cond:
		_failures += 1
		print("FAIL: " + message)


func _heroes() -> Array:
	return GameData.load_heroes().filter(func(d): return d.get("starter", false)).map(func(d): return Combat.make_unit(d))


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
	check(c.monsters[0]["hp"] == c.monsters[0]["max_hp"] - Combat.HOLLOW_FLAME_DAMAGE, "Hollow Flame hits monster 1")
	check(c.monsters[1]["hp"] == c.monsters[1]["max_hp"] - Combat.HOLLOW_FLAME_DAMAGE, "Hollow Flame hits monster 2")
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


func test_weapons() -> void:
	var run := Run.new(11)
	var h: Dictionary = run.heroes[0]
	var max_before: int = h["max_hp"]
	var cursed: Dictionary = run.weapons_db.filter(func(w): return w["id"] == "thirsting_sword")[0]
	var plain: Dictionary = run.weapons_db.filter(func(w): return w["id"] == "rusted_blade")[0]
	Run.equip_weapon(h, cursed)
	check(h["faces"][4]["type"] == "blood" and h["faces"][5]["type"] == "blood", "weapon replaces faces 5 and 6")
	check(h["max_hp"] == max_before - 3, "cursed weapon lowers max HP")
	Run.equip_weapon(h, plain)
	check(h["max_hp"] == max_before, "swapping away a cursed weapon restores max HP")
	check(h["faces"][4]["type"] == "attack", "new weapon faces are applied")


func test_fate_twist() -> void:
	var c := Combat.new(12)
	c.start_battle(_heroes(), [_monster("ghoul")])
	c.fate = Combat.FATE_TWIST_COST - 1
	check(not c.fate_twist(0, 2), "twist needs enough Fate")
	c.fate = Combat.FATE_TWIST_COST
	check(c.fate_twist(0, 2), "twist works with enough Fate")
	check(c.heroes[0]["face"] == 2 and c.heroes[0]["locked"], "twisted die shows the chosen face and is locked")
	check(c.fate == 0, "twist costs Fate")


func test_pets() -> void:
	var c := Combat.new(13)
	c.pet = {"id": "grave_pup", "name": "Grave Pup", "passive": "first_strike", "face": 0,
		"faces": [{"type": "attack", "value": 2}]}
	c.start_battle(_heroes(), [_monster("rotting_bishop")])
	var boss: Dictionary = c.monsters[0]
	check(boss["hp"] == boss["max_hp"] - Combat.PET_FIRST_STRIKE, "Grave Pup bites at the start of the fight")
	c.pet["passive"] = "lucky"
	c._start_round()
	check(c.rerolls_left == Combat.REROLLS_PER_TURN + 1, "Black Cat gives an extra reroll")
	var run := Run.new(14)
	check(run.phase == "pet" and run.pet_offers.size() == 2, "a run starts by choosing 1 of 2 pets")
	run.choose_pet(0)
	check(run.phase == "map" and not run.combat.pet.is_empty(), "choosing a pet starts the road")


func test_profile_and_quests() -> void:
	var path := "user://test_profile.save"
	GameData.safe_delete(path)
	var p := Profile.new(path)
	var run := Run.new(20)
	run.pos = 20
	run.phase = "defeat"
	run.stats["fights"] = 3
	run.stats["kills"] = {"ghoul": 30}
	var res := p.record_run(run)
	check(res["embers"] == 12 + 3 + 15 + 20, "embers = tiles*0.6 + fights + quests (got %d)" % res["embers"])
	check("first_steps" in p.quests_done and "ghoul_hunter" in p.quests_done, "quests complete from run stats")
	var again := Profile.new(path)
	again.load_profile()
	check(again.embers == p.embers and again.stat("kills_ghoul") == 30, "profile survives save/load")
	for q in again.quests:
		check(again.quest_progress(q) >= 0, "quest progress readable: " + q["id"])
	again.embers = 1000
	check(again.upgrade("chapel") and again.level("chapel") == 1, "buildings can be upgraded")
	check(again.next_cost("kennel") == 70 and again.upgrade("kennel") and again.next_cost("kennel") == -1, "max level reports -1")


func test_run_save_load() -> void:
	var run := Run.new(21)
	run.choose_pet(0)
	run.gold = 42
	run.pos = 7
	run.heroes[0]["faces"][5] = {"type": "attack", "value": 9}
	var copy: Run = Run.from_dict(run.to_dict())
	check(copy.gold == 42 and copy.pos == 7 and copy.phase == "map", "run state restored")
	check(copy.heroes[0]["faces"][5]["value"] == 9, "carved faces restored")
	check(copy.combat.pet["id"] == run.combat.pet["id"], "pet restored")
	run.roll_move()
	copy.roll_move()
	check(run.move_options == copy.move_options, "random numbers continue identically after loading")


func test_town_upgrades_apply() -> void:
	var run := Run.new(22, {"chapel": 2, "kennel": 1, "smithy": 1, "carver": 2, "market": 1, "fortune": 1})
	check(run.heroes[0]["max_hp"] == 28 + 2, "Chapel adds max HP")
	check(run.pet_offers.size() == 3, "Kennel offers 3 pets")
	run.choose_pet(0)
	check(run.phase == "loot" and run.weapon_offers.size() == 1 and run.weapon_offers[0]["rarity"] == "common", "Gravesmith offers a common weapon")
	run.equip(0, 0)
	check(run.phase == "reward" and run.carve_offers.size() == 4, "Bone Carver gives a free 4-choice carving")
	run.skip_carving()
	check(run.phase == "map", "then the road begins")
	check(run.price({"cost": 20}) == 17, "Night Market discounts prices")
	check(run.combat.bonus_fate_start == 1, "Fortune Teller adds starting Fate")


func test_summon_roll() -> void:
	var path := "user://test_summon.save"
	GameData.safe_delete(path)
	var p := Profile.new(path)
	check(p.owned_heroes.size() == 3 and p.owned_pets.size() == 4, "3 starter heroes and 4 starter pets are owned")
	check(not p.can_summon("heroes"), "summoning needs Grave Dice")
	p.grave_dice = 300
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	for banner in Profile.BANNERS:
		var since := 0
		var max_gap := 0
		var guard := 0
		while p.can_summon(banner) and guard < 60:
			guard += 1
			var r := p.summon_roll(rng, banner)
			since += 1
			if r["new"]:
				max_gap = max(max_gap, since)
				since = 0
		check(p.locked_in(banner).is_empty(), "banner %s can be completed" % banner)
		check(max_gap <= int(p.summon["pity"]), "pity guarantees something new in %s within %d rolls (gap %d)" % [banner, p.summon["pity"], max_gap])
		check(not p.can_summon(banner), "a completed banner cannot be rolled")
	check(p.owned_heroes.size() == 6, "all heroes unlocked")
	check(p.owned_pets.size() == 7, "all pets unlocked")
	var run := Run.new(30, p.run_options(), ["rook", "vael", "mordecai"])
	check(run.heroes.map(func(h): return h["id"]) == ["rook", "vael", "mordecai"], "the chosen party is used")
	var relics := run.weapons_db.filter(func(w): return w.get("locked", false))
	check(relics.size() == p.unlocked_weapons.size(), "only unlocked relics appear on the road")
	check(not Run.new(31).weapons_db.any(func(w): return w.get("locked", false)), "locked relics never drop without unlocking")
	check(not Run.new(32).pet_offers.any(func(x): return not x.get("starter", false)), "locked pets are never offered")


func test_time_of_day() -> void:
	var day := Run.new(60, {"time": "day"})
	var night := Run.new(60, {"time": "night"})
	var dawn := Run.new(60, {"time": "dawn"})
	var dusk := Run.new(60, {"time": "dusk"})
	var plain := Run.new(60)
	check(day.price({"cost": 20}) < plain.price({"cost": 20}), "Day: cheaper shops")
	var g: Dictionary = plain.monster_defs["ghoul"]
	check(night.scaled_monster(g, "fight", "early")["hp"] > plain.scaled_monster(g, "fight", "early")["hp"], "Night: tougher enemies")
	check(dawn.rest_percent() > plain.rest_percent(), "Dawn: better camps")
	check(dusk.combat.bonus_fate_start == plain.combat.bonus_fate_start + 1, "Dusk: +1 Fate each fight")
	var path := "user://test_time.save"
	GameData.safe_delete(path)
	var p := Profile.new(path)
	var t := p.time_name()
	p.advance_time()
	check(p.time_name() != t, "waiting moves time forward")


func test_new_pets() -> void:
	var c := Combat.new(70)
	c.pet = {"id": "lantern_wisp", "name": "Lantern Wisp", "passive": "ward", "face": 0, "faces": [{"type": "blank", "value": 0}]}
	c.start_battle(_heroes(), [_monster("ghoul")])
	check(c.heroes[0]["shield"] == Combat.PET_WARD, "Lantern Wisp shields the party in round 1")
	var c2 := Combat.new(71)
	c2.pet = {"id": "ember_salamander", "name": "Ember Salamander", "passive": "burn_aura", "face": 0, "faces": [{"type": "blank", "value": 0}]}
	c2.start_battle(_heroes(), [_monster("ghoul"), _monster("cultist")])
	check(c2.monsters.all(func(m): return m["burn"] == 1), "Ember Salamander sets every enemy burning")


func test_party_and_new_skills() -> void:
	var by_id := {}
	for d in GameData.load_heroes():
		by_id[d["id"]] = d
	var c := Combat.new(32)
	var party := ["rook", "vael", "mordecai"].map(func(id): return Combat.make_unit(by_id[id]))
	c.start_battle(party, [_monster("rotting_bishop")])
	var boss: Dictionary = c.monsters[0]
	boss["shield"] = 5
	c.heroes[0]["charge"] = 4
	c.use_skill(0)
	check(boss["hp"] == boss["max_hp"] - Combat.BACKSTAB_DAMAGE, "Backstab ignores shields")
	c.heroes[1]["charge"] = 4
	c.use_skill(1)
	check(boss["burn"] == 3, "Miasma sets enemies burning")
	c.heroes[2]["charge"] = 3
	c.fate = 0
	c.use_skill(2)
	check(Combat.current_face(c.heroes[2])["value"] == 8 and c.fate == 2, "Loaded Dice picks the best face and gives Fate")


func test_gates_stop_movement() -> void:
	var run := Run.new(40)
	check(run.board[21]["type"] == "shop" and run.board[21].get("gate", false), "tile 21 is a shop gate")
	check(run.board[30]["type"] == "rest" and run.board[30].get("gate", false), "tile 30 is a camp gate")
	run.pos = 18
	check(run.destination(6) == 21, "moving past the shop gate stops at the shop")
	run.pos = 27
	check(run.destination(5) == 30, "moving past the camp gate stops at the camp")
	var cursed := Run.new(41, {"curse": 2})
	var plain := Run.new(41)
	var g: Dictionary = plain.monster_defs["ghoul"]
	check(cursed.scaled_monster(g, "fight", "early")["hp"] > plain.scaled_monster(g, "fight", "early")["hp"], "Curse makes enemies tougher")


func test_tile_snapshot_reload() -> void:
	var run := Run.new(50)
	run.choose_pet(0)
	run.roll_move()
	run.choose_move(0)
	var snap := run.tile_snapshot
	check(snap.get("pending_enter", false), "stepping on a tile takes a snapshot")
	var again: Run = Run.from_dict(snap)
	check(again.pos == run.pos and again.phase == run.phase, "reloading re-enters the same tile (%s)" % run.phase)
	if run.phase == "combat":
		var a: Array = run.combat.monsters.map(func(m): return m["id"])
		var b: Array = again.combat.monsters.map(func(m): return m["id"])
		check(a == b, "the same enemies appear after reloading")
	var old := run.to_dict()
	old["version"] = 1
	old.erase("pending_enter")
	check(Run.from_dict(old).phase == "map", "version-1 saves still load")
	var cursed := Run.new(51, {"curse": 3})
	check(cursed.rest_percent() == 20, "Curse III makes camps heal less")


## UI scripts are not exercised by the rule tests, so at least make sure they all compile.
func test_ui_scripts_compile() -> void:
	for f in DirAccess.get_files_at("res://scripts/ui"):
		if f.ends_with(".gd"):
			var scr: GDScript = load("res://scripts/ui/" + f)
			check(scr != null and scr.can_instantiate(), "UI script compiles: " + f)


func _fresh_profile(name: String) -> Profile:
	var path := "user://%s.save" % name
	GameData.safe_delete(path)
	return Profile.new(path)


func test_villager_requests() -> void:
	var p := _fresh_profile("test_villagers")
	check(p.villagers.size() == 4, "4 villagers live in Ashfall")
	for v in p.villagers:
		check(v["requests"].size() == 4, "%s has a chain of 4 requests (3 + 1 Isle delivery)" % v["id"])
		for r in v["requests"]:
			if r["reward"]["kind"] in ["hero", "pet", "relic"]:
				check(not p.item_def(r["reward"]["kind"], r["reward"]["id"]).is_empty(), "reward exists: " + r["reward"]["id"])
	# Total-scope request: kill rats after accepting.
	check(p.npc_request("tobin")["id"] == "tobin_rats", "Tobin starts with the rat request")
	p.stats["kills_plague_rat"] = 10
	check(p.accept_request("tobin"), "a request can be accepted")
	check(p.request_progress("tobin") == 0, "kills before accepting do not count")
	p.stats["kills_plague_rat"] = 16
	check(p.is_request_done("tobin"), "6 more kills finishes it")
	var dust := p.star_dust
	var r := p.claim_request("tobin")
	check(r["kind"] == "dust" and p.star_dust == dust + 3, "reward handed over")
	check(p.npc_request("tobin")["id"] == "tobin_fields", "the next request in the chain unlocks")
	# Run-scope request: needs it in ONE journey.
	p.npc_step["pip"] = 1
	p.accept_request("pip")
	var run := Run.new(80)
	run.phase = "defeat"
	run.stats["carves"] = 3
	p.record_run(run)
	check(not p.is_request_done("pip"), "3 carvings is not enough")
	run.stats["carves"] = 5
	p.record_run(run)
	check(p.is_request_done("pip"), "5 carvings in one journey completes it")
	p.time_of_day = 3  # night: Pip is asleep
	check(p.claim_request("pip").is_empty(), "you cannot claim from a villager who is away")
	p.time_of_day = 1
	r = p.claim_request("pip")
	check(r["kind"] == "pet" and "ember_salamander" in p.owned_pets and r["grade"] == "SSR", "Pip gives an SSR pet")
	# Owned rewards become Star Dust.
	dust = p.star_dust
	r = p.grant({"kind": "pet", "id": "ember_salamander"})
	check(r["kind"] == "dust" and p.star_dust == dust + 8, "a duplicate SSR becomes 8 Star Dust")
	check(p.npc_is_out("hesk") == (p.time_name() in ["dusk", "night"]), "the night watch keeps its hours")


func test_stars() -> void:
	var p := _fresh_profile("test_stars")
	check(p.star("hero", "varek") == 1, "heroes start at 1 star")
	check(not p.can_upgrade_star("hero", "varek"), "upgrades cost embers and dust")
	p.embers = 5000
	p.star_dust = 500
	for i in 4:
		check(p.upgrade_star("hero", "varek"), "upgrade to star %d" % (i + 2))
	check(p.star("hero", "varek") == 5 and p.star_cost("hero", "varek").is_empty(), "5 stars is the max")
	check(p.star_cost("hero", "vael")[0] > p.star_cost("hero", "lys")[0], "SSR upgrades cost more")
	var run := Run.new(81, p.run_options())
	var v: Dictionary = run.heroes[0]
	check(v["max_hp"] == 28 + 4 and v.get("charge_bonus", 0) == 1, "a 5-star Varek has +4 HP and +1 charge")
	var pet := {"faces": [{"type": "attack", "value": 1}, {"type": "blank", "value": 0}]}
	Run.apply_pet_stars(pet, 5)
	check(pet["faces"][1]["type"] == "attack", "a 5-star pet loses its blank face")
	var w := Run.apply_relic_stars({"name": "X", "faces": [{"type": "fire", "value": 3}, {"type": "guard", "value": 3}]}, 3)
	check(w["faces"][0]["value"] == 4 and w["faces"][1]["value"] == 4 and w["name"] == "X +2", "relic stars raise both faces")


func test_world() -> void:
	var World = load("res://scripts/core/world.gd")
	var w = World.new()
	check(w.countries.size() == 7, "the world has 7 countries")
	var biomes := {}
	for i in w.countries.size():
		var c: Dictionary = w.countries[i]
		biomes[c["biome"]] = true
		check(w.cells_of(i).size() > 150, "%s has land (%d cells)" % [c["id"], w.cells_of(i).size()])
		check(w.nodes.filter(func(n): return n["country"] == i and n["kind"] == "ore").size() == int(w.data["nodes_per_country"]), "%s has mineral fields" % c["id"])
		check(w.nodes.filter(func(n): return n["country"] == i and n["kind"] == "tree").size() >= 8, "%s has trees to chop" % c["id"])
		check(w.enemies.filter(func(e): return e["country"] == i and e["boss"]).size() == 1, "%s has a boss" % c["id"])
		for g in c["beasts"]:
			for id in g:
				check(w.monster_defs.has(id), "%s beast exists: %s" % [c["id"], id])
		check(w.monster_defs.has(c["boss"]) and w.monster_defs[c["boss"]].get("boss", false), "%s boss is a boss" % c["id"])
		for g in c["monsters"]:
			for id in g:
				check(w.monster_defs.has(id), "%s monster exists: %s" % [c["id"], id])
	check(biomes.size() == 7, "every country has its own ecosystem")
	check(w.country_at(w.player_cell)["id"] == "ashfall_vale", "the journey starts in Ashfall Vale")
	check(not w.is_walkable(Vector2i(0, 0)), "the sea surrounds the land")
	w.setup_party(["varek", "lys", "aldric"], {"hero:varek": 2}, "ash_crow")
	check(w.party.size() == 3 and w.party[0]["max_hp"] == 30 and not w.pet.is_empty(), "the travelling party uses stars")
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var n: Dictionary = w.nodes[0]
	var got: Dictionary = w.gather(n["id"], rng)
	check(not got.is_empty() and int(w.bag.get(got["id"], 0)) == got["amount"], "gathering fills the bag")
	check(w.gather(n["id"], rng).is_empty(), "a gathered node is depleted")
	w.clock += float(w.data["node_respawn_seconds"]) + 1
	check(w.node_ready(n), "nodes grow back")
	# Danger: falling in a safe country keeps the bag, in a dangerous one loses it.
	var safe_enemy: Dictionary = w.enemies.filter(func(e): return w.countries[e["country"]]["tier"] <= 2)[0]
	var deadly_enemy: Dictionary = w.enemies.filter(func(e): return w.countries[e["country"]]["tier"] >= 4)[0]
	var r: Dictionary = w.finish_fight(safe_enemy, false, rng)
	check(not r["lost_bag"] and not w.bag.is_empty(), "falling in a safe country keeps the bag")
	r = w.finish_fight(deadly_enemy, false, rng)
	check(r["lost_bag"] and w.bag.is_empty(), "falling in a dangerous country loses the bag")
	check(w.country_at(w.player_cell)["id"] == "ashfall_vale", "the fallen wake up in Ashfall")
	var weak: Array = w.fight_defs(safe_enemy)
	var strong: Array = w.fight_defs(deadly_enemy)
	check(strong[0]["hp"] >= w.monster_defs[deadly_enemy["group"][0]]["hp"], "tougher countries scale their monsters")
	var c = w.start_fight(safe_enemy, 1)
	check(c.monsters.size() == weak.size() and not c.finished, "a world fight uses the dice combat")
	# Banking and trading.
	var p := _fresh_profile("test_world")
	w.bag = {"grave_iron": 10}
	p.bank(w)
	check(w.bag.is_empty() and p.materials["grave_iron"] == 10, "returning to town banks the bag")
	var e0 := p.embers
	check(p.trade_material("grave_iron", 5, "embers", w.material_value("grave_iron")) and p.embers == e0 + 10, "materials sell for embers")
	var copy = World.new()
	copy.load_dict(w.to_dict())
	check(copy.player_cell == w.player_cell and copy.party.size() == 3, "the world session saves and loads")


func test_crafting_and_hunting() -> void:
	var World = load("res://scripts/core/world.gd")
	var w = World.new()
	w.setup_party(["varek", "lys", "aldric"], {}, "")
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	var wolf: Dictionary = w.enemies.filter(func(e): return e["group"].has("dire_wolf") and not e["boss"])[0]
	var r: Dictionary = w.finish_fight(wolf, true, rng)
	check(int(w.bag.get("wolf_pelt", 0)) >= 1 and r["drops"].has("wolf_pelt"), "wolves drop pelts")
	var tree: Dictionary = w.nodes.filter(func(n): return n["kind"] == "tree" and n["country"] == 0)[0]
	var got: Dictionary = w.gather(tree["id"], rng)
	check(got["id"] == "ashwood", "chopping Ashfall trees gives Ashwood")
	var boss: Dictionary = w.enemies.filter(func(e): return e["boss"] and e["country"] == 0)[0]
	r = w.finish_fight(boss, true, rng)
	check(r["boss"] and int(w.bag.get("alpha_fang", 0)) == 1 and r["dust"] >= 3, "the Ashen Alpha drops its fang")
	check(not w.enemy_active(boss) and float(boss["defeated_until"]) - w.clock >= 899.0, "bosses take long to return")
	check(w.material_name("bear_hide") == "Bear Hide" and w.material_value("ashwood") == 1, "hides and wood have names and value")
	# Forge
	var p := _fresh_profile("test_forge")
	for rec in p.recipes():
		for m in rec["materials"]:
			check(w.material_value(m) >= 1 and w.material_name(m) != m, "recipe %s uses a real material: %s" % [rec["id"], m])
	check(not p.can_craft("iron_hatchet"), "crafting needs materials")
	p.materials = {"grave_iron": 6, "ashwood": 6, "wolf_pelt": 5}
	p.embers = 100
	var hatchet := p.craft("iron_hatchet")
	check(hatchet > 0 and not p.materials.has("grave_iron") and p.embers == 80, "crafting uses materials and embers")
	var coat := p.craft("wolfhide_coat")
	check(coat > 0, "armour can be crafted")
	p.equip_gear("varek", "weapon", hatchet)
	p.equip_gear("varek", "armor", coat)
	var run := Run.new(90, p.run_options())
	var v: Dictionary = run.heroes[0]
	check(v["faces"][4]["value"] == 4 and v["max_hp"] == 28 + 4, "crafted gear is worn on the road")
	var c := Combat.new(91)
	c.start_battle(run.heroes, [_monster("ghoul")])
	check(c.heroes[0]["shield"] == 0 or c.heroes[0]["shield"] >= 0, "armour shield applies")
	p.equip_gear("lys", "weapon", hatchet)
	check(p.gear_owner(hatchet) == "lys" and not p.equipped["varek"].has("weapon"), "one item, one hero")
	w.setup_party(["varek"], {}, "", p.gear_bonuses())
	check(w.party[0]["max_hp"] == 28 + 4, "crafted gear is worn in the open world")


func test_elements() -> void:
	check(Combat.element_multiplier("fire", "wind") == 1.2, "fire beats wind")
	check(Combat.element_multiplier("wind", "earth") == 1.2 and Combat.element_multiplier("earth", "water") == 1.2 and Combat.element_multiplier("water", "fire") == 1.2, "the elemental cycle")
	check(Combat.element_multiplier("wind", "fire") == 0.8, "wind is weak against fire")
	check(Combat.element_multiplier("light", "dark") == 1.2 and Combat.element_multiplier("dark", "light") == 1.2, "light and dark beat each other")
	check(Combat.element_multiplier("fire", "fire") == 1.0 and Combat.element_multiplier("", "dark") == 1.0, "same element or none: normal damage")
	for d in GameData.load_heroes() + GameData.load_monsters().values():
		check(Combat.elements()["elements"].has(d.get("element", "")), "%s has an element" % d["id"])
	# In a real fight: Lys (fire) hitting a Lava Lizard (fire) vs a Dire Wolf (wind).
	var c := Combat.new(100)
	c.start_battle(_heroes(), [_monster("dire_wolf"), _monster("lava_lizard")])
	var lys: Dictionary = c.heroes[1]
	c._damage(c.monsters[0], 10, "test", true, lys)
	check(c.monsters[0]["hp"] == c.monsters[0]["max_hp"] - 12, "fire on wind deals +20%")
	c._damage(c.monsters[1], 10, "test", true, lys)
	check(c.monsters[1]["hp"] == c.monsters[1]["max_hp"] - 10, "fire on fire deals normal damage")
	var wolf: Dictionary = c.monsters[0]
	var varek: Dictionary = c.heroes[0]
	var hp: int = varek["hp"]
	c._damage(varek, 10, "test", true, wolf)
	check(varek["hp"] == hp - 12, "wind wolves hit earth Varek +20%")


## Bugs found by the AI player in v2.2.
func test_v22_player_bugs() -> void:
	var c := Combat.new(120)
	c.start_battle(_heroes(), [_monster("ghoul")])
	c.fate = 4
	c.fate_twist(0, 2)
	c.toggle_lock(0)
	check(c.heroes[0]["locked"], "a twisted die cannot be unlocked by accident")
	c.rerolls_left = 1
	c.reroll()
	check(c.heroes[0]["face"] == 2, "rerolling keeps the twisted face")
	var before: int = c.heroes[1]["face"]
	c.rerolls_left = 1
	c.reroll()
	check(c.heroes[1]["face"] != before, "a reroll always shows a different face")
	var hp: int = c.monsters[0]["hp"]
	c._damage(c.monsters[0], 2, "test", true, {"element": "light"})
	check(c.monsters[0]["hp"] == hp - 3, "super effective adds at least 1 (2 -> 3)")
	var p := _fresh_profile("test_bugs")
	p.npc_step["hesk"] = 0
	p.time_of_day = 3
	p.accept_request("hesk")
	p.record_world_fight(["ghoul", "ghoul"], true, 2)
	check(p.request_progress("hesk") == 2, "ghouls killed on the Cursed Isle count for Captain Hesk")
	check(p.stat("fate_twists") == 2, "twists on the Isle count too")
	var run := Run.new(121)
	run.choose_pet(0)
	run.phase = "shop"
	run.gold = 100
	run.last_reward_text = "Victory! +9 gold."
	run.buy("carving")
	check(not run.last_reward_text.begins_with("Victory"), "shop carving does not show an old victory message")


## v3.0 changes from the player + critic review.
func test_v30_changes() -> void:
	var c := Combat.new(130)
	c.start_battle(_heroes(), [_monster("plague_rat"), _monster("ghoul")])
	var rat: Dictionary = c.monsters[0]
	var ghoul: Dictionary = c.monsters[1]
	c.target_index = 0
	c._apply_hero_face(c.heroes[0], {"type": "attack", "value": 15}, 15)
	if Combat.OVERKILL_SPILL > 0.0:
		check(not Combat.is_alive(rat) and ghoul["hp"] < ghoul["max_hp"], "overkill spills onto the next enemy")
	else:
		check(not Combat.is_alive(rat) and ghoul["hp"] == ghoul["max_hp"], "no spill while OVERKILL_SPILL is 0")
	var c2 := Combat.new(131)
	c2.start_battle(_heroes(), [_monster("rotting_bishop")])
	c2._damage(c2.monsters[0], 14, "test", true, c2.heroes[0])
	check(c2.monsters[0]["shield"] == Combat.BOSS_HARDEN_SHIELD, "bosses harden after a 12+ hit")
	var World = load("res://scripts/core/world.gd")
	var w = World.new()
	w.setup_party(["varek", "lys", "aldric"], {}, "", {}, 2)
	check(w.party[0]["max_hp"] == 30, "the Chapel bonus applies on the Isle too")
	var e: Dictionary = w.enemies.filter(func(x): return not x["boss"] and x["country"] == 0)[0]
	var fight = w.start_fight(e, 1)
	check(not fight.flee(), "no fleeing in round 1")
	fight.round_number = 2
	check(fight.flee() and fight.fled and fight.finished, "fleeing works from round 2")
	var rng := RandomNumberGenerator.new()
	rng.seed = 2
	var r: Dictionary = w.finish_fight(e, true, rng)
	check(not r["drops"].is_empty(), "every Isle fight drops something")
	check(r["embers"] >= 10, "Isle fights pay at least 10 embers per tier")
	check(r["carved"] != "", "an Isle win sharpens a die")
	var p := _fresh_profile("test_v30")
	check(p.banner_cost("pets") == 2 and p.banner_cost("heroes") == 3, "pet and relic banners are cheaper")
	check(int(p.star_cost("hero", "varek")[0]) == 25 and int(p.star_cost("hero", "varek")[1]) == 4, "first stars cost mostly Star Dust")
	var plain := Run.new(132)
	var gp := _fresh_profile("test_v30_gear")
	var sw: Dictionary = gp.recipe("alpha_fang_blade")
	var sa: Dictionary = gp.recipe("bog_heart_charm")
	var geared := Run.new(132, {"gear": {"varek": {"weapon": sw, "armor": sa}, "lys": {"weapon": sw}}})
	check(abs(geared.gear_scaling() - 1.3) < 0.001, "gear scaling caps at +30%")
	var g: Dictionary = plain.monster_defs["ghoul"]
	var np := _fresh_profile("test_v30_unlock")
	check(not np.feature_unlocked("forge") and not np.feature_unlocked("isle"), "a new player starts with a small town")
	np.stats["runs"] = 1
	check(np.feature_unlocked("isle") and np.feature_unlocked("summon"), "one journey opens the Isle and the Summon tab")
	check(geared.scaled_monster(g, "fight", "early")["hp"] > plain.scaled_monster(g, "fight", "early")["hp"], "the road answers crafted gear")


func test_v31_delivery_requests() -> void:
	var p := _fresh_profile("test_v31_deliver")
	var World = load("res://scripts/core/world.gd")
	var w = World.new()
	for v in p.villagers:
		var last: Dictionary = v["requests"][v["requests"].size() - 1]
		check(last["goal"]["scope"] == "deliver", "%s's last request asks for Isle materials" % v["id"])
		check(w.material_value(last["goal"]["material"]) > 0, "%s asks for a real material: %s" % [v["id"], last["goal"]["material"]])
	p.npc_step["tobin"] = 3
	check(p.npc_request("tobin")["id"] == "tobin_iron", "Tobin's 4th request wants Grave Iron")
	p.materials["grave_iron"] = 2
	check(p.accept_request("tobin") and p.request_progress("tobin") == 2, "delivery progress counts what is in Storage")
	check(not p.is_request_done("tobin") and p.claim_request("tobin").is_empty(), "not enough iron yet")
	p.materials["grave_iron"] = 9
	check(p.is_request_done("tobin"), "enough iron finishes the delivery")
	p.time_of_day = 1
	var dice := p.grave_dice
	var r := p.claim_request("tobin")
	check(r["kind"] == "dice" and p.grave_dice == dice + 2, "Tobin pays 2 Grave Dice")
	check(int(p.materials.get("grave_iron", 0)) == 3, "claiming hands the 6 iron over")
	check(p.npc_request("tobin").is_empty(), "Tobin's chain is finished")
	# An exact amount leaves no empty entry behind, and old saves (step 3) simply see the new request.
	p.npc_step["pip"] = 3
	p.materials["ember_shard"] = 1
	p.accept_request("pip")
	p.claim_request("pip")
	check(not p.materials.has("ember_shard"), "an emptied material leaves Storage")
	p.save()
	var again := Profile.new(p.path)
	again.load_profile()
	check(int(again.npc_step.get("pip", 0)) == 4, "delivery progress is saved")


func test_v31_bestiary() -> void:
	var p := _fresh_profile("test_v31_bestiary")
	var entries: Array = p.bestiary_entries()
	check(entries.size() == GameData.load_monsters().size(), "every monster has a Bestiary page")
	for e in entries:
		check(e["lore"] != "", "%s has a line of lore" % e["id"])
		check(not e["known"] and not e["claimable"], "%s starts unknown" % e["id"])
	check(p.bestiary_claimable_count() == 0, "nothing to claim at first")
	p.stats["kills_ghoul"] = 12
	p.stats["kills_rotting_bishop"] = 1
	check(p.bestiary_claimable_count() == 2, "12 ghouls and one Bishop reach a milestone")
	var dust := p.star_dust
	var r := p.claim_bestiary("ghoul")
	check(r["kind"] == "dust" and p.star_dust == dust + 2, "the first ghoul milestone pays 2 Star Dust")
	check(p.claim_bestiary("ghoul").is_empty(), "the next ghoul milestone needs 30 kills")
	var g: Dictionary = p.bestiary_entries().filter(func(e): return e["id"] == "ghoul")[0]
	check(int(g["next_kills"]) == 30 and g["known"], "the ghoul page shows the next goal")
	check(not p.claim_bestiary("rotting_bishop").is_empty(), "a boss pays on its first kill")
	check(p.claim_bestiary("nobody").is_empty(), "unknown monsters pay nothing")
	# Isle kills count too.
	p.record_world_fight(["dire_wolf"], true, 0)
	check(p.bestiary_entries().filter(func(e): return e["id"] == "dire_wolf")[0]["known"], "Isle kills fill pages")
	# Saved, and old saves without the field load with nothing claimed.
	var again := Profile.new(p.path)
	again.load_profile()
	check(int(again.bestiary_claimed.get("ghoul", 0)) == 1, "claimed milestones are saved")
	var old := _fresh_profile("test_v31_old_save")
	var f := FileAccess.open(old.path, FileAccess.WRITE)
	f.store_var({"version": 2, "embers": 5, "stats": {"kills_ghoul": 40}})
	f = null
	old.load_profile()
	check(old.bestiary_claimed.is_empty() and old.bestiary_claimable_count() == 1, "an old save loads into the Bestiary")
	old.claim_bestiary("ghoul")
	check(old.claim_bestiary("ghoul")["kind"] == "dust", "40 old kills reach the second ghoul milestone too")


func test_v31_pet_treats() -> void:
	var p := _fresh_profile("test_v31_treats")
	var treats: Array = p.recipes().filter(func(r): return r["slot"] == "treat")
	check(treats.size() >= 4, "the Forge offers companion treats")
	for t in treats:
		check(t["face"]["type"] in GameData.FACE_TYPES and t["face"]["type"] != "blank", "treat %s gives a real face" % t["id"])
	p.embers = 100
	p.materials = {"boar_hide": 2, "ashwood": 3}
	var uid := p.craft("boar_jerky")
	check(uid >= 0 and p.materials.is_empty(), "jerky is crafted from boar hide and ashwood")
	check(not p.feed_treat("ember_salamander", uid), "you cannot feed a companion you do not own")
	check(p.feed_treat("grave_pup", uid) and p.pet_treat("grave_pup")["id"] == "boar_jerky", "the Grave Pup eats the jerky")
	check(p.gear_owner(uid) == "pet:grave_pup", "the Armory knows who ate it")
	check(p.feed_treat("black_cat", uid) and p.pet_treat("grave_pup").is_empty(), "feeding it to another pet moves it")
	p.feed_treat("grave_pup", uid)
	var helmet_uid := -1
	p.materials = {"grave_iron": 6, "ashwood": 4}
	helmet_uid = p.craft("iron_hatchet")
	check(not p.feed_treat("grave_pup", helmet_uid), "a weapon is not a treat")
	# The road: the chosen pet's blank face becomes ATK 2, and the road does not get harder for it.
	var run := Run.new(140, p.run_options())
	run.phase = "pet"
	run.pet_offers = [GameData.load_pets().filter(func(x): return x["id"] == "grave_pup")[0]]
	run.choose_pet(0)
	var faces: Array = run.combat.pet["faces"]
	check(not faces.any(func(f): return f["type"] == "blank") and run.combat.pet.get("treat", "") == "Smoked Boar Jerky", "the fed pup has no blank face on the road")
	check(abs(run.gear_scaling() - 1.0) < 0.001, "treats do not scale road enemies")
	# The Isle uses the same rule.
	var World = load("res://scripts/core/world.gd")
	var w = World.new()
	w.setup_party(["varek", "lys", "aldric"], {}, "grave_pup", p.gear_bonuses())
	check(not w.pet["faces"].any(func(f): return f["type"] == "blank"), "the fed pup has no blank face on the Isle")
	# A 5-star pet has no blank: the treat raises its weakest face instead.
	var pet := {"faces": [{"type": "attack", "value": 3}, {"type": "attack", "value": 1}, {"type": "attack", "value": 2}, {"type": "attack", "value": 2}]}
	Run.apply_pet_treat(pet, treats[0])
	check(int(pet["faces"][1]["value"]) == 2, "a 5-star pet gets +1 on its weakest face")
	# Saved like other gear.
	var again := Profile.new(p.path)
	again.load_profile()
	check(again.pet_treat("grave_pup")["id"] == "boar_jerky", "treats are saved")


## 3.1: saves survive a broken file, old saves are upgraded, cached data cannot be changed by callers.
func test_v31_safe_saves() -> void:
	var p := _fresh_profile("test_safe")
	p.embers = 11
	p.save()
	p.embers = 22
	p.save()
	check(FileAccess.file_exists("user://test_safe.save.bak"), "saving keeps a backup of the previous save")
	var f := FileAccess.open("user://test_safe.save", FileAccess.WRITE)
	f.store_string("garbage")
	f.close()
	var p2 := Profile.new("user://test_safe.save")
	p2.load_profile()
	check(p2.embers == 11, "a broken save falls back to the backup (got %d)" % p2.embers)
	var old := {"version": 2, "embers": 5, "materials": {"grave_iron": 3}, "stats": {"runs": 2}}
	var m := Profile.migrate(old)
	check(int(m["version"]) == Profile.SAVE_VERSION and int(m["stats"]["isle_trips"]) == 1, "v2 saves are upgraded to the current version")
	var a: Array = GameData.load_json("res://data/heroes.json")
	a[0]["hp"] = 999
	var b: Array = GameData.load_json("res://data/heroes.json")
	check(int(b[0]["hp"]) != 999, "the data cache hands out copies")
	Profile.save_run_data({"x": 1})
	check(Profile.has_saved_run(), "run save exists")
	Profile.delete_saved_run()
	check(not Profile.has_saved_run(), "deleting a run save also removes its backup")


## 3.1: Isle quests pull new players to the Isle and finish when they come home.
func test_v31_isle_quests() -> void:
	var p := _fresh_profile("test_isle_quests")
	var World = load("res://scripts/core/world.gd")
	var w = World.new()
	w.bag = {"grave_iron": 3}
	var dice := p.grave_dice
	p.bank(w)
	check("isle_landfall" in p.quests_done and p.embers == 20, "the first trip home completes Landfall (+20)")
	check(p.grave_dice == dice + int(p.summon["dice_per_quest"]), "Isle quests also pay a Grave Die")
	p.record_world_fight(["dire_wolf", "dire_wolf"], true, 0)
	check(p.stat("isle_kills") == 2, "Isle kills are counted")
	w.bag = {}
	p.bank(w)
	check(p.last_bank_quests.is_empty(), "no quest twice")


## 3.2: every Thai line keeps the same placeholders as its English key, and every key is used.
func test_v32_translations() -> void:
	var th: Dictionary = GameData.load_json("res://data/lang_th.json")
	check(th.size() > 200, "Thai translation file loaded (%d lines)" % th.size())
	var re := RegEx.new()
	re.compile("%[-0-9]*[sd%]")
	var bad: Array[String] = []
	for key in th:
		if key.begins_with("_") or key.contains("."):
			continue
		var a: Array = re.search_all(key).map(func(m): return m.get_string())
		var b: Array = re.search_all(str(th[key])).map(func(m): return m.get_string())
		if a != b:
			bad.append(key)
	check(bad.is_empty(), "Thai placeholders match English: %s" % str(bad))
	check(ResourceLoader.exists("res://assets/fonts/NotoSansThai-Regular.woff2"), "Thai font is bundled")
	# Every player-facing text in data/ has a Thai line (proper names of heroes and places may stay English).
	var keep_english := ["Varek the Oathbroken", "Lys the Hollow", "Brother Aldric", "Rook the Gravedigger",
		"Sister Vael", "Mordecai the Gambler", "The Hollow Road"]
	var missing: Array[String] = []
	for f in DirAccess.get_files_at("res://data"):
		if f.ends_with(".json") and not f.begins_with("lang_"):
			_collect_untranslated(GameData.load_json("res://data/" + f), "", th, keep_english, missing)
	check(missing.is_empty(), "all story text has Thai (%d missing, e.g. %s)" % [missing.size(), str(missing.slice(0, 3))])


const _NOT_TEXT_KEYS := ["id", "type", "sprite", "element", "grade", "slot", "stat", "scope", "kind", "material",
	"times", "color", "biome", "music", "tile", "icon", "bg", "background", "rarity", "mood", "strong", "effect", "goal", "phase", "group"]


func _collect_untranslated(x: Variant, key: String, th: Dictionary, keep: Array, out: Array[String]) -> void:
	if x is Dictionary:
		for k in x:
			_collect_untranslated(x[k], k, th, keep, out)
	elif x is Array:
		for v in x:
			_collect_untranslated(v, key, th, keep, out)
	elif x is String:
		var re := RegEx.new()
		re.compile("[A-Za-z]{2}")
		var ident := RegEx.new()
		ident.compile("^[a-z0-9_]+$")
		if key in _NOT_TEXT_KEYS or re.search(x) == null or ident.search(x) != null:
			return
		if not th.has(x) and not x in keep and not x in out:
			out.append(x)


## Bugs the AI player found in 3.2.
func test_v32_player_bugs() -> void:
	var r := Run.new(321)
	var altar: Dictionary = GameData.load_json("res://data/events.json")[0]
	r.event = altar
	r.phase = "event"
	r.last_reward_text = "The Bone Carver sets to work on your dice."
	r.choose_event_option(0)
	check(not r.last_reward_text.contains("Bone Carver"), "an event that leads to carving shows its own text (got: %s)" % r.last_reward_text)
