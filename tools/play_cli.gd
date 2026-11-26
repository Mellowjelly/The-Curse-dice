extends SceneTree
const GameData = preload("res://scripts/core/game_data.gd")
## Text interface to play the whole game (for AI playtesters and quick checks).
##
## The game is deterministic, so a session is just a list of commands that is REPLAYED from the start
## every time. Write commands into a text file (one per line) and run:
##     godot --headless --path . -s tools/play_cli.gd -- session.txt [lines_of_output]
## Add more lines to the file and run again to continue. Type "help" for all commands.

const Profile = preload("res://scripts/core/profile.gd")
const Run = preload("res://scripts/core/run.gd")
const Combat = preload("res://scripts/core/combat.gd")
const World = preload("res://scripts/core/world.gd")

var profile: Profile
var run: Run
var world: World
var wcombat: Combat
var wenemy: Dictionary = {}
var mode := "town"           # town | road | world
var runs_started := 0
var fights_started := 0
var rng_summon := RandomNumberGenerator.new()
var rng_world := RandomNumberGenerator.new()
var out: Array[String] = []

const HELP := """COMMANDS
 anywhere: help | status
 TOWN: party <hero> <hero> <hero> | wait | build <building> | summon heroes|relics|pets
       talk <villager> | accept <villager> | claim <villager> | upgrade hero|pet|relic <id>
       bestiary | trophy <monster> (claim a Bestiary kill milestone)
       recipes | craft <recipe> | equip <hero> <weapon|armor> <uid> | feed <pet> <treat uid> | sell <material> <n> | grind <material> <n>
       road (start a Hollow Road journey) | explore (go out to the Cursed Isle)
 ROAD (map): roll | move 0|1 | reroll_move | pick <n> (pet/carving/event option/close event) | skip
       equip_loot <weapon#> <hero#> | buy <item> | leave | rest heal|carve
 WORLD: look | goto <x> <y> | gather | fight | home | sharpen <n>|skip (after a win: pick 1 of 3 sharpenings)
 COMBAT (road or world): lock <hero#> | reroll | fate_reroll | twist <hero#> <face#> | skill <hero#>
       target <enemy#> | end | flee (Isle only, from round 2)"""


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		print("usage: -- session.txt [tail_lines] [th]")
		quit()
		return
	var tail := int(args[1]) if args.size() > 1 else 60
	if "th" in args:  # optional 3rd argument: show the game's own text (combat log, intents, story) in Thai
		var Settings = load("res://scripts/ui/settings.gd")
		Settings.language = "th"
		Settings.apply()
	var path := "user://cli_profile.save"
	GameData.safe_delete(path)
	profile = Profile.new(path)
	rng_summon.seed = 7
	rng_world.seed = 11
	var f := FileAccess.open(args[0], FileAccess.READ)
	if f == null:
		print("cannot open ", args[0])
		quit()
		return
	var lines := f.get_as_text().split("\n")
	for raw in lines:
		var cmd := raw.strip_edges()
		if cmd == "" or cmd.begins_with("#"):
			continue
		out.append("> " + cmd)
		_exec(cmd)
	var start: int = max(0, out.size() - tail)
	print("\n".join(out.slice(start)))
	print("\n========== NOW ==========")
	print(_status())
	quit()


func say(text: String) -> void:
	out.append(text)


# ---------------------------------------------------------------- dispatch

func _exec(cmd: String) -> void:
	var p := cmd.split(" ", false)
	var c := p[0].to_lower()
	if c == "help":
		say(HELP)
		return
	if c == "status":
		say(_status())
		return
	var combat := _combat()
	if combat != null and not combat.finished:
		_combat_cmd(combat, c, p)
		return
	match mode:
		"town":
			_town_cmd(c, p)
		"road":
			_road_cmd(c, p)
		"world":
			_world_cmd(c, p)


func _combat() -> Combat:
	if mode == "road" and run != null and run.phase == "combat":
		return run.combat
	if mode == "world" and wcombat != null and not wcombat.finished:
		return wcombat
	return null


# ---------------------------------------------------------------- town

func _town_cmd(c: String, p: PackedStringArray) -> void:
	var gate := {"summon": "summon", "recipes": "forge", "craft": "forge", "equip": "forge", "feed": "forge", "sell": "storage", "grind": "storage", "explore": "isle"}
	if gate.has(c) and not profile.feature_unlocked(gate[c]):
		say("Locked. " + profile.unlock_hint(gate[c]))
		return
	match c:
		"party":
			var ids := Array(p.slice(1))
			if ids.size() != 3 or not ids.all(func(x): return x in profile.owned_heroes):
				say("Need 3 heroes you own: " + ", ".join(profile.owned_heroes))
				return
			profile.party = ids
			profile.save()
			say("Party: " + ", ".join(ids))
		"wait":
			profile.advance_time()
			say("Time passes. It is now " + profile.time_name() + ". " + Profile.TIME_EFFECTS[profile.time_name()])
		"build":
			say("Built %s." % p[1] if p.size() > 1 and profile.upgrade(p[1]) else "Cannot build that (cost or max level).")
		"summon":
			var banner := p[1] if p.size() > 1 else "heroes"
			var r := profile.summon_roll(rng_summon, banner)
			say(r["text"] if not r.is_empty() else "Cannot summon (need %d Grave Dice, or the banner is complete)." % profile.banner_cost(banner))
		"talk":
			_talk(p[1] if p.size() > 1 else "")
		"accept":
			var vid := p[1] if p.size() > 1 else ""
			if not profile.npc_is_out(vid):
				say("%s is not out at this time of day." % vid)
			else:
				say("Request accepted: " + profile.npc_request(vid).get("title", "") if profile.accept_request(vid) else "Nothing to accept.")
		"claim":
			var vid := p[1] if p.size() > 1 else ""
			var r := profile.claim_request(vid)
			if not r.is_empty():
				say("Reward: " + r["text"])
			elif profile.is_request_done(vid) and not profile.npc_is_out(vid):
				say("%s is not in town right now (out at: %s). Wait until then to claim." % [vid, ", ".join(profile.npc(vid).get("times", []))])
			else:
				say("Not finished yet.")
		"bestiary":
			var unknown := 0
			for e in profile.bestiary_entries():
				if not e["known"]:
					unknown += 1
					continue
				var nxt: String = "all milestones claimed" if int(e["next_kills"]) < 0 else "next %d kills -> %s%s" % [int(e["next_kills"]), str(e["next_reward"]), "  (CLAIM: trophy %s)" % e["id"] if e["claimable"] else ""]
				say("  %s [%s] x%d - %s  | %s" % [e["name"], e["rank"], int(e["kills"]), nxt, e["lore"]])
			say("  ...and %d pages not yet met." % unknown)
		"trophy":
			var tr := profile.claim_bestiary(p[1] if p.size() > 1 else "")
			say(("Bestiary milestone: " + tr["text"]) if not tr.is_empty() else "No milestone ready for that monster.")
		"upgrade":
			if p.size() > 2 and profile.upgrade_star(p[1], p[2]):
				say("%s %s is now %d stars." % [p[1], p[2], profile.star(p[1], p[2])])
			else:
				say("Cannot upgrade (cost: %s)." % str(profile.star_cost(p[1], p[2]) if p.size() > 2 else []))
		"recipes":
			for r in profile.recipes():
				say("  %s [%s %s] mats %s + %d embers %s" % [r["id"], r["grade"], r["slot"], str(r["materials"]), int(r["embers"]), "(CAN CRAFT)" if profile.can_craft(r["id"]) else ""])
		"craft":
			var uid := profile.craft(p[1] if p.size() > 1 else "")
			if uid >= 0:
				var r := profile.recipe(p[1])
				var eff: String
				if r["slot"] == "weapon":
					eff = "faces " + str(r["faces"].map(func(f): return "%s%d" % [f["type"], f["value"]])) + " (replaces die faces 5-6)"
				elif r["slot"] == "treat":
					eff = "companion's blank face becomes %s%d" % [r["face"]["type"], int(r["face"]["value"])]
				else:
					eff = "+%d max HP, +%d shield each fight" % [int(r["hp"]), int(r["shield"])]
				var how: String = ("feed <pet> %d" % uid) if r["slot"] == "treat" else ("equip <hero> %s %d" % [r["slot"], uid])
				say("Crafted item #%d: [%s] %s - %s. Use with: %s" % [uid, r["grade"], r["name"], eff, how])
			else:
				say("Missing materials or embers.")
		"feed":
			say("Fed." if p.size() > 2 and profile.feed_treat(p[1], int(p[2])) else "Cannot feed that (need an owned pet and a crafted treat uid).")
		"equip":
			if p.size() > 3:
				profile.equip_gear(p[1], p[2], int(p[3]))
				say("Equipped.")
		"sell", "grind":
			if p.size() > 2:
				var w := World.new()
				var ok := profile.trade_material(p[1], int(p[2]), "embers" if c == "sell" else "dust", w.material_value(p[1]))
				if ok:
					say("Done. Embers %d, Star Dust %d." % [profile.embers, profile.star_dust])
				elif int(profile.materials.get(p[1], 0)) < int(p[2]):
					say("You only have %d %s." % [int(profile.materials.get(p[1], 0)), p[1]])
				else:
					say("Too little to grind: %d x value %d gives less than 1 Star Dust (needs total value 10)." % [int(p[2]), w.material_value(p[1])])
		"road":
			runs_started += 1
			run = Run.new(1000 + runs_started, profile.run_options(), profile.party)
			mode = "road"
			say("You set out on the Hollow Road (%s)." % profile.time_name())
			say(_road_state())
		"explore":
			world = World.new()
			if not profile.world_state.is_empty():
				world.load_dict(profile.world_state)
			world.setup_party(profile.party, profile.stars, profile.owned_pets[0] if not profile.owned_pets.is_empty() else "", profile.gear_bonuses(), profile.level("chapel"))
			world.time_of_day = profile.time_name()
			mode = "world"
			say("You walk out of the gate onto the Cursed Isle.")
			say(_world_look())
		_:
			say("Unknown town command. Type help.")


func _talk(vid: String) -> void:
	var v := profile.npc(vid)
	if v.is_empty():
		say("Villagers: " + ", ".join(profile.villagers.map(func(x): return x["id"])))
		return
	if not profile.npc_is_out(vid):
		say("%s is not out now (out at: %s)." % [v["name"], ", ".join(v["times"])])
		return
	var req := profile.npc_request(vid)
	say("%s, %s: \"%s\"" % [v["name"], v["title"], v["greeting"][0]])
	if req.is_empty():
		say("  (no more requests)")
	elif profile.is_request_done(vid):
		say("  Request '%s' is DONE - claim it." % req["title"])
	elif profile.is_request_active(vid):
		say("  Working on '%s': %d/%d%s" % [req["title"], profile.request_progress(vid), int(req["goal"]["amount"]),
			" (counts %s in Storage, handed over on claim)" % req["goal"]["material"] if req["goal"]["scope"] == "deliver" else ""])
	else:
		say("  Asks: %s  -> reward %s" % [req["ask"], _reward_text(req["reward"])])


# ---------------------------------------------------------------- the Hollow Road

func _road_cmd(c: String, p: PackedStringArray) -> void:
	var n := int(p[1]) if p.size() > 1 else 0
	match c:
		"roll":
			run.roll_move()
		"move":
			run.choose_move(n)
		"reroll_move":
			run.reroll_move()
		"pick":
			match run.phase:
				"pet": run.choose_pet(n)
				"reward": run.choose_carving(n)
				"event":
					if run.event_result != "":
						run.close_event()
					else:
						run.choose_event_option(n)
		"skip":
			if run.phase == "reward":
				run.skip_carving()
			elif run.phase == "loot":
				run.skip_loot()
		"equip_loot":
			var hi := int(p[2]) if p.size() > 2 else 0
			if n >= 0 and n < run.weapon_offers.size() and hi >= 0 and hi < run.heroes.size():
				var w: Dictionary = run.weapon_offers[n]
				var hf: Array = run.heroes[hi]["faces"]
				say("%s takes %s: faces 5-6 %s %s -> %s" % [Combat.short_name(run.heroes[hi]), w["name"], _face(hf[4]), _face(hf[5]),
					" ".join(w["faces"].map(_face))])
			run.equip(n, hi)
		"buy":
			var item := p[1] if p.size() > 1 else ""
			if not run.can_buy(item):
				say("Cannot buy %s: %s" % [item, "already bought here" if item in run.shop_bought else "not enough gold or not useful now"])
			else:
				run.buy(item)
		"leave":
			run.leave_shop()
		"rest":
			if p.size() > 1 and p[1] == "carve":
				run.rest_carve()
			else:
				run.rest_heal()
		_:
			say("Unknown road command (phase %s). Type help." % run.phase)
	_after_road()


func _after_road() -> void:
	if run.is_over():
		var res := profile.record_run(run)
		say("JOURNEY OVER: %s at tile %d. +%d Soul Embers, +%d Grave Dice%s" % [run.phase.to_upper(), run.pos, int(res["embers"]), int(res.get("dice", 0)),
			("; quests: " + ", ".join(res["quests"].map(func(q): return q["name"]))) if not res["quests"].is_empty() else ""])
		mode = "town"
		run = null
		return
	say(_road_state())


func _road_state() -> String:
	var s: Array[String] = []
	s.append("[ROAD tile %d/%d, gold %d, fate %d, phase %s]" % [run.pos, run.board.size() - 1, run.gold, run.combat.fate, run.phase])
	s.append("  party: " + "; ".join(run.heroes.map(func(h): return "%s %d/%d" % [Combat.short_name(h), h["hp"], h["max_hp"]])))
	match run.phase:
		"map":
			var ahead: Array[String] = []
			for i in range(run.pos + 1, min(run.pos + 9, run.board.size())):
				ahead.append("%d:%s" % [i, run.board[i]["type"]])
			s.append("  ahead: " + " ".join(ahead))
			if run.move_options.is_empty():
				s.append("  -> roll")
			else:
				for i in run.move_options.size():
					var dest := run.destination(run.move_options[i])
					s.append("  move %d = die %d -> %d steps -> %s%s" % [i, run.move_options[i], dest - run.pos, run.board[dest]["type"],
						" (the party must stop here)" if dest - run.pos < run.move_options[i] else ""])
		"pet":
			for i in run.pet_offers.size():
				s.append("  pick %d: %s - %s" % [i, run.pet_offers[i]["name"], run.pet_offers[i]["desc"]])
		"reward":
			s.append("  " + run.last_reward_text)
			for i in run.carve_offers.size():
				s.append("  pick %d: %s" % [i, run.carve_offers[i]["text"]])
		"loot":
			for i in run.weapon_offers.size():
				var w: Dictionary = run.weapon_offers[i]
				s.append("  weapon %d: %s (%s) faces %s" % [i, w["name"], w["rarity"], str(w["faces"].map(func(f): return "%s%d" % [f["type"], f["value"]]))])
			s.append("  -> equip_loot <weapon#> <hero#> or skip")
		"event":
			s.append("  EVENT %s: %s" % [run.event["title"], run.event["text"]])
			if run.event_result != "":
				s.append("  RESULT: %s  -> pick 0 to continue" % run.event_result)
			else:
				for i in run.event["options"].size():
					s.append("  pick %d: %s%s" % [i, run.event["options"][i]["label"], "" if run.can_choose_event_option(i) else " (cannot afford)"])
		"shop":
			for it in run.shop_items():
				s.append("  buy %s: %s (%d gold) %s" % [it["id"], it["name"], run.price(it), it["desc"]])
			s.append("  -> leave")
		"rest":
			s.append("  rest heal (%d%%) | rest carve" % run.rest_percent())
		"combat":
			s.append(_combat_state(run.combat))
	return "\n".join(s)


# ---------------------------------------------------------------- combat

func _combat_cmd(cb: Combat, c: String, p: PackedStringArray) -> void:
	var n := int(p[1]) if p.size() > 1 else 0
	var log: Array[String] = []
	var collect := func(t): log.append("    " + t)
	cb.log_added.connect(collect)
	match c:
		"lock": cb.toggle_lock(n)
		"reroll": cb.reroll()
		"fate_reroll": cb.fate_reroll()
		"twist": cb.fate_twist(n, int(p[2]) if p.size() > 2 else 0)
		"skill": cb.use_skill(n)
		"flee":
			if not cb.flee():
				say("You can only flee from Isle fights, from round 2.")
		"target": cb.set_target(n)
		"end": cb.end_turn()
		_: say("Unknown combat command. Type help.")
	cb.log_added.disconnect(collect)
	out.append_array(log)
	if cb.finished:
		if mode == "road":
			_after_road()
		else:
			var won: bool = cb.monsters.all(func(m): return not Combat.is_alive(m))
			var r := world.flee_fight(wenemy) if cb.fled else world.finish_fight(wenemy, won, rng_world)
			profile.record_world_fight(wenemy["group"], won, cb.twists, wenemy.get("boss", false))
			profile.embers += int(r["embers"])
			profile.star_dust += int(r["dust"])
			say("FIGHT OVER: %s. +%d embers, +%d dust, drops %s%s%s" % ["FLED" if cb.fled else ("VICTORY" if r["victory"] else "DEFEAT"), r["embers"], r["dust"], str(r.get("drops", {})),
				" - YOUR BAG WAS LOST" if r["lost_bag"] else "", ("  | " + r["carved"]) if r.get("carved", "") != "" else ""])
			if r.get("sharpen", false):
				say(_sharpen_text())
			profile.world_state = world.to_dict()
			profile.save()
			wcombat = null
	else:
		say(_combat_state(cb))


func _combat_state(cb: Combat) -> String:
	var s: Array[String] = []
	s.append("  [COMBAT round %d] fate %d, rerolls %d" % [cb.round_number, cb.fate, cb.rerolls_left])
	for i in cb.monsters.size():
		var m: Dictionary = cb.monsters[i]
		if Combat.is_alive(m):
			s.append("   enemy %d%s: %s %d/%d hp%s [%s] intent: %s" % [i, " (TARGET)" if i == cb.target_index else "", m["name"], m["hp"], m["max_hp"],
				(" shield %d" % m["shield"]) if m["shield"] > 0 else "", m.get("element", ""), cb.intent_text(m)])
	for i in cb.heroes.size():
		var h: Dictionary = cb.heroes[i]
		if not Combat.is_alive(h):
			s.append("   hero %d: %s FALLEN" % [i, Combat.short_name(h)])
			continue
		var f := Combat.current_face(h)
		s.append("   hero %d: %s %d/%d hp%s [%s] die: %s %d%s | skill %s %d/%d | faces %s" % [i, Combat.short_name(h), h["hp"], h["max_hp"],
			(" shield %d" % h["shield"]) if h["shield"] > 0 else "", h.get("element", ""), f["type"], int(f["value"]), " LOCKED" if h["locked"] else "",
			h["skill"].get("name", "-"), h["charge"], Combat.skill_cost(h), str(h["faces"].map(func(x): return "%s%d" % [x["type"], x["value"]]))])
	return "\n".join(s)


# ---------------------------------------------------------------- the Cursed Isle

func _sharpen_text() -> String:
	var s: Array[String] = ["BATTLE-HARDENED: pick 1 sharpening (+1 until you go home) with `sharpen <n>`, or `sharpen skip`:"]
	for i in world.sharpen_offers.size():
		s.append("   %d: %s" % [i, world.sharpen_offers[i]["text"]])
	return "\n".join(s)


func _world_cmd(c: String, p: PackedStringArray) -> void:
	match c:
		"look":
			say(_world_look())
		"goto":
			if p.size() < 3:
				say("goto <x> <y>")
				return
			_walk_to(Vector2i(int(p[1]), int(p[2])))
		"gather":
			var best := {}
			for nd in world.nodes:
				if world.node_ready(nd) and Vector2(nd["cell"]).distance_to(Vector2(world.player_cell)) <= 1.5:
					best = nd
					break
			if best.is_empty():
				say("Nothing to gather within 1 cell. Use look and goto.")
				return
			world.clock += 1.2
			var got := world.gather(best["id"], rng_world)
			say("Gathered %d %s%s." % [got["amount"], got["name"], " (RARE)" if got["rare"] else ""])
		"fight":
			for e in world.enemies:
				if world.enemy_active(e) and Vector2(e["cell"]).distance_to(Vector2(world.player_cell)) <= 1.5:
					_start_world_fight(e)
					return
			say("No monster within 1 cell.")
		"sharpen":
			if world.sharpen_offers.is_empty():
				say("Nothing to sharpen. Win an Isle fight first (max %d per trip)." % world.MAX_TRIP_CARVINGS)
				return
			if p.size() > 1 and p[1] == "skip":
				world.skip_sharpening()
				say("You leave your dice as they are.")
				return
			var msg := world.choose_sharpening(int(p[1]) if p.size() > 1 else -1)
			say(msg if msg != "" else "sharpen <0-%d> or sharpen skip" % (world.sharpen_offers.size() - 1))
		"home":
			var moved := profile.bank(world)
			profile.advance_time()
			world.rest_in_town()
			world.player_cell = Vector2i(int(world.countries[0]["center"][0]), int(world.countries[0]["center"][1]))
			profile.world_state = world.to_dict()
			profile.save()
			mode = "town"
			say("Back in Ashfall. Stored: %s" % str(moved))
			for q in profile.last_bank_quests:
				say("Quest complete: %s (+%d embers)" % [q["name"], int(q["reward"])])
		_:
			say("Unknown world command. Type help.")


func _walk_to(target: Vector2i) -> void:
	var steps := 0
	while world.player_cell != target and steps < 200:
		var d := target - world.player_cell
		var next := world.player_cell + Vector2i(sign(d.x), sign(d.y))
		if not world.is_walkable(next):
			say("The way is blocked by water at %s." % str(next))
			break
		world.player_cell = next
		steps += 1
		world.clock += 0.6
		if steps % 7 == 0:
			world.regenerate(1)
		for e in world.enemies:
			if world.enemy_active(e) and Vector2(e["cell"]).distance_to(Vector2(world.player_cell)) <= 1.0:
				if e.get("boss", false):
					say("Walked %d steps. BOSS %s guards its lair here (tier %d) - use 'fight' to challenge it, or walk away." % [
						steps, world.monster_defs[e["group"][0]]["name"], int(world.countries[e["country"]]["tier"])])
					return
				say("Walked %d steps. A monster blocks the way!" % steps)
				_start_world_fight(e)
				return
	var c := world.country_at(world.player_cell)
	say("Walked %d steps. You are at %s in %s." % [steps, str(world.player_cell), c.get("name", "?")])


func _start_world_fight(e: Dictionary) -> void:
	fights_started += 1
	wenemy = e
	wcombat = world.start_fight(e, 5000 + fights_started)
	var c: Dictionary = world.countries[e["country"]]
	say("FIGHT in %s (tier %d)%s!" % [c["name"], int(c["tier"]), " - BOSS" if e.get("boss", false) else ""])
	say(_combat_state(wcombat))


func _world_look() -> String:
	var s: Array[String] = []
	var c := world.country_at(world.player_cell)
	s.append("[WORLD at %s] %s (tier %d, %s) - %s" % [str(world.player_cell), c.get("name", "?"), int(c.get("tier", 0)),
		"DANGER: bag lost if you fall" if world.is_dangerous(c) else "safe", c.get("desc", "")])
	s.append("  party: " + "; ".join(world.party.map(func(h): return "%s %d/%d" % [Combat.short_name(h), h["hp"], h["max_hp"]])))
	s.append("  bag: " + str(world.bag))
	var near: Array = []
	for nd in world.nodes:
		var dist := Vector2(nd["cell"]).distance_to(Vector2(world.player_cell))
		if dist <= 10 and world.node_ready(nd):
			near.append([dist, "  %s at %s (%s)" % [nd["kind"], str(nd["cell"]), world.countries[nd["country"]]["wood" if nd["kind"] == "tree" else "mineral"]["name"]]])
	for e in world.enemies:
		var dist := Vector2(e["cell"]).distance_to(Vector2(world.player_cell))
		if dist <= 10 and world.enemy_active(e):
			near.append([dist, "  %s%s at %s" % ["BOSS " if e["boss"] else "", "+".join(e["group"]), str(e["cell"])]])
	near.sort_custom(func(a, b): return a[0] < b[0])
	for n in near.slice(0, 14):
		s.append(n[1])
	s.append("  countries: " + "; ".join(world.countries.map(func(x): return "%s T%d centre %s" % [x["name"], int(x["tier"]), str(x["center"])])))
	return "\n".join(s)


# ---------------------------------------------------------------- status

func _status() -> String:
	if mode == "road" and run != null:
		return _road_state()
	if mode == "world":
		if wcombat != null and not wcombat.finished:
			return _combat_state(wcombat)
		return _world_look()
	var s: Array[String] = []
	s.append("[TOWN of Ashfall] time %s (%s)" % [profile.time_name(), Profile.TIME_EFFECTS[profile.time_name()]])
	s.append("  embers %d, grave dice %d, star dust %d" % [profile.embers, profile.grave_dice, profile.star_dust])
	s.append("  party %s | owned heroes %s | pets %s" % [str(profile.party), str(profile.owned_heroes), str(profile.owned_pets)])
	s.append("  stars %s | gear %s | equipped %s" % [str(profile.stars), str(profile.gear), str(profile.equipped)])
	s.append("  materials %s" % str(profile.materials))
	var b: Array[String] = []
	for bd in profile.town["buildings"]:
		var nc := profile.next_cost(bd["id"])
		b.append("%s lv%d (%s)" % [bd["id"], profile.level(bd["id"]), ("next %d" % nc) if nc >= 0 else "max"])
	s.append("  buildings: " + ", ".join(b))
	var v: Array[String] = []
	for vd in profile.villagers:
		var mark := "-"
		if not profile.npc_request(vd["id"]).is_empty():
			mark = "DONE" if profile.is_request_done(vd["id"]) else ("active" if profile.is_request_active(vd["id"]) else "has request")
		v.append("%s(%s, %s)" % [vd["id"], "out" if profile.npc_is_out(vd["id"]) else "away", mark])
	s.append("  villagers: " + ", ".join(v))
	s.append("  -> road | explore | talk <villager> | summon <banner> | recipes | help")
	return "\n".join(s)


func _face(f: Dictionary) -> String:
	return "%s%d" % [String(f["type"]).to_upper(), int(f["value"])] if f["type"] != "blank" else "BLANK"


func _reward_text(r: Dictionary) -> String:
	match String(r["kind"]):
		"dust":
			return "%d Star Dust" % int(r["amount"])
		"dice":
			return "%d Grave Dice" % int(r["amount"])
		"embers":
			return "%d Soul Embers" % int(r["amount"])
	var id: String = r.get("id", "")
	if profile.owns(r["kind"], id):
		return "%d Star Dust (you already have %s)" % [profile.duplicate_dust(r["kind"], id), id]
	return "%s %s" % [r["kind"], id]
