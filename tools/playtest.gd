extends SceneTree
const GameData = preload("res://scripts/core/game_data.gd")
## Automated playtest: every bot style plays many full runs of the region,
## then we write a report (numbers + one full annotated transcript per style)
## for the playtester panel (.claude/agents/playtester.md) to critique.
##
## Run:  godot --headless --path . -s tools/playtest.gd -- v0.3
## Output: docs/playtests/<version>/report.md and transcript_<style>.txt

const Combat = preload("res://scripts/core/combat.gd")
const Run = preload("res://scripts/core/run.gd")
const PlayerBot = preload("res://tools/bots/player_bot.gd")
const Profile = preload("res://scripts/core/profile.gd")

const CAMPAIGNS := 20
const CAMPAIGN_RUNS := 20
# The order each bot style buys town upgrades in.
const BUY_ORDER := {
	"newbie": ["chapel", "chapel", "chapel", "market", "fortune", "kennel", "smithy", "carver", "fortune", "market", "smithy", "carver"],
	"tactician": ["carver", "fortune", "smithy", "chapel", "kennel", "carver", "fortune", "chapel", "smithy", "market", "chapel", "market"],
	"berserker": ["smithy", "smithy", "fortune", "carver", "fortune", "chapel", "kennel", "carver", "chapel", "market", "chapel", "market"],
}

const STYLES := ["newbie", "tactician", "berserker"]
const RUNS := 300
const MAX_STEPS := 3000
# Rough human timing used to estimate session length.
const SECONDS_PER_COMBAT_ROUND := 15.0
const SECONDS_PER_DECISION := 6.0


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var version: String = args[0] if args.size() > 0 else "dev"
	var runs: int = int(args[1]) if args.size() > 1 else RUNS
	# 3.7: optional 3rd argument: another region (e.g. ash_desert). It opens after a road win,
	# so its bots start from a small town (MID_TOWN) and the campaign section is skipped.
	if args.size() > 2:
		region_path = "res://data/region2.json" if args[2] == "ash_desert" else args[2]
	var out_dir := "res://docs/playtests/%s" % version
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))

	var report: Array[String] = ["# Playtest report %s" % version, "",
		"%d full runs per bot style (start of the road -> boss)." % runs, ""]
	if region_path != "":
		report[2] = "%d full runs per bot style on %s, town %s." % [runs, region_path, str(MID_TOWN)]
	for style in STYLES:
		report.append_array(_measure(style, runs))
		if region_path == "":
			report.append_array(_campaign(style))
		_write(out_dir + "/transcript_%s.txt" % style, "\n".join(_transcript(style, 7)))
	_write(out_dir + "/report.md", "\n".join(report))
	print("\n".join(report))
	quit()


func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text + "\n")


## Plays one full run. If `log` is given, everything is recorded there.
var region_path := ""
const MID_TOWN := {"chapel": 1, "carver": 1, "smithy": 1, "fortune": 1}


func play_run(style: String, seed_value: int, log: Array[String] = [], levels: Dictionary = {}) -> Dictionary:
	if region_path != "":
		levels = MID_TOWN.duplicate() if levels.is_empty() else levels.duplicate()
		levels["region"] = region_path
	var run := Run.new(seed_value, levels)
	var bot := PlayerBot.new(style, seed_value)
	bot.notes = log
	run.log_added.connect(func(t): log.append(t))
	var r := {"rounds": 0, "decisions": 0, "blank": 0, "rolls": 0, "boss_hp_start": -1.0,
		"died_at": "", "died_tile": -1, "fate_spent": 0}
	var steps := 0
	var last_round := -1
	while not run.is_over() and steps < MAX_STEPS:
		steps += 1
		if run.phase == "combat":
			var c := run.combat
			if c.round_number != last_round:
				last_round = c.round_number
				r["rounds"] += 1
				log.append(_snapshot(run))
				if run.combat_kind == "boss" and r["boss_hp_start"] < 0:
					r["boss_hp_start"] = bot._party_hp_ratio(run)
				for h in c.heroes:
					if Combat.is_alive(h):
						r["rolls"] += 1
						if Combat.current_face(h)["type"] == "blank":
							r["blank"] += 1
		else:
			r["decisions"] += 1
			last_round = -1
		bot.play_run_step(run)
	if run.phase == "defeat":
		r["died_at"] = run.combat_kind
		r["died_tile"] = run.pos
	r["run"] = run
	r["bot"] = bot
	r["won"] = run.phase == "victory"
	r["minutes"] = (r["rounds"] * SECONDS_PER_COMBAT_ROUND + r["decisions"] * SECONDS_PER_DECISION) / 60.0
	return r


func _snapshot(run: Run) -> String:
	var c := run.combat
	var hs: Array[String] = []
	for h in c.heroes:
		if Combat.is_alive(h):
			var f := Combat.current_face(h)
			hs.append("%s %d/%dhp [%s %d] chg %d/%d" % [Combat.short_name(h), h["hp"], h["max_hp"],
				f["type"], int(f["value"]), h["charge"], Combat.skill_cost(h)])
		else:
			hs.append("%s DEAD" % Combat.short_name(h))
	var ms: Array[String] = []
	for m in c.monsters:
		if Combat.is_alive(m):
			ms.append("%s %d/%dhp%s (%s)" % [m["name"], m["hp"], m["max_hp"],
				(" shield %d" % m["shield"]) if m["shield"] > 0 else "", c.intent_text(m)])
	return ">> STATE R%d  heroes: %s | enemies: %s | fate %d" % [c.round_number, ", ".join(hs), ", ".join(ms), c.fate]


func _avg(total: float, n: int) -> float:
	return total / max(n, 1)


func _measure(style: String, runs: int) -> Array[String]:
	var wins := 0
	var died := {}
	var died_third := [0, 0, 0]
	var totals := {"rounds": 0.0, "decisions": 0.0, "minutes": 0.0, "fights": 0.0, "elites": 0.0,
		"events": 0.0, "carves": 0.0, "gold": 0.0, "blank": 0.0, "rolls": 0.0, "fate_rerolls": 0.0,
		"rerolls": 0.0}
	var boss_hp := 0.0
	var boss_n := 0
	var skills := {}
	var tiles := {}
	var boss_rounds := 0.0
	var by_pet := {}     # pet -> [wins, runs]
	var by_weapon := {}  # weapon -> [wins, runs]
	var by_boss := {}    # road boss -> [boss fights won, boss fights reached]
	for s in runs:
		var r := play_run(style, 5000 + s)
		var run: Run = r["run"]
		if r["won"]:
			wins += 1
		else:
			died[r["died_at"]] = died.get(r["died_at"], 0) + 1
			died_third[min(2, int(3.0 * r["died_tile"] / run.board.size()))] += 1
		for k in ["rounds", "decisions", "minutes", "blank", "rolls"]:
			totals[k] += r[k]
		totals["fights"] += run.stats["fights"]
		totals["elites"] += run.stats["elites"]
		totals["events"] += run.stats["events"]
		totals["carves"] += run.stats["carves"]
		totals["gold"] += run.stats["gold_earned"]
		totals["fate_rerolls"] += r["bot"].stats["fate_rerolls"]
		totals["rerolls"] += r["bot"].stats["rerolls"]
		for t in run.stats["tiles"]:
			tiles[t] = tiles.get(t, 0) + run.stats["tiles"][t]
		if r["boss_hp_start"] >= 0:
			boss_hp += r["boss_hp_start"]
			boss_n += 1
			if r["won"]:
				boss_rounds += run.combat.round_number
			by_boss[run.boss_id] = [by_boss.get(run.boss_id, [0, 0])[0] + int(r["won"]), by_boss.get(run.boss_id, [0, 0])[1] + 1]
		var pet_name: String = run.combat.pet.get("name", "none")
		by_pet[pet_name] = [by_pet.get(pet_name, [0, 0])[0] + int(r["won"]), by_pet.get(pet_name, [0, 0])[1] + 1]
		for h in run.heroes:
			var wn: String = h["weapon"].get("name", "")
			if wn != "":
				by_weapon[wn] = [by_weapon.get(wn, [0, 0])[0] + int(r["won"]), by_weapon.get(wn, [0, 0])[1] + 1]
		for k in r["bot"].stats["skills"]:
			skills[k] = skills.get(k, 0) + r["bot"].stats["skills"][k]
	var lines: Array[String] = ["## Bot: %s" % style, ""]
	lines.append("- **Win rate: %.0f%%**" % (100.0 * wins / runs))
	lines.append("- Deaths by fight type: %s; by board third (early/mid/late): %s" % [str(died), str(died_third)])
	lines.append("- Reached the boss: %.0f%% of runs, party HP when the boss starts: %.0f%%, boss fight length when won: %.1f rounds" % [
		100.0 * boss_n / runs, 100.0 * _avg(boss_hp, boss_n), _avg(boss_rounds, max(wins, 1))])
	lines.append("- Per run (avg): %.1f fights + %.1f elites won, %.1f events, %.1f carvings, %.0f gold earned" % [
		_avg(totals["fights"], runs), _avg(totals["elites"], runs), _avg(totals["events"], runs),
		_avg(totals["carves"], runs), _avg(totals["gold"], runs)])
	lines.append("- Session length estimate: %.0f min (%.0f combat rounds, %.0f map decisions)" % [
		_avg(totals["minutes"], runs), _avg(totals["rounds"], runs), _avg(totals["decisions"], runs)])
	lines.append("- Blank faces: %.0f%% of rolls; per run %.1f rerolls, %.2f Fate rerolls" % [
		100.0 * totals["blank"] / max(totals["rolls"], 1), _avg(totals["rerolls"], runs), _avg(totals["fate_rerolls"], runs)])
	var bb: Array[String] = []
	for k in by_boss:
		bb.append("%s %.0f%% of %d boss fights" % [k, 100.0 * by_boss[k][0] / by_boss[k][1], by_boss[k][1]])
	lines.append("- Boss fights won, by road boss: " + ", ".join(bb))
	var sk: Array[String] = []
	for k in skills:
		sk.append("%s %.1f" % [k, float(skills[k]) / runs])
	lines.append("- Skills per run: " + ", ".join(sk))
	var tl: Array[String] = []
	for k in tiles:
		tl.append("%s %.1f" % [k, float(tiles[k]) / runs])
	lines.append("- Tiles landed on per run: " + ", ".join(tl))
	var pets: Array[String] = []
	for k in by_pet:
		pets.append("%s %.0f%% (%d runs)" % [k, 100.0 * by_pet[k][0] / by_pet[k][1], by_pet[k][1]])
	lines.append("- Win rate by pet: " + ", ".join(pets))
	var ws: Array[String] = []
	for k in by_weapon:
		ws.append("%s %.0f%% (%d)" % [k, 100.0 * by_weapon[k][0] / by_weapon[k][1], by_weapon[k][1]])
	lines.append("- Win rate by weapon held at the end: " + ", ".join(ws))
	lines.append("")
	return lines


func _transcript(style: String, seed_value: int) -> Array[String]:
	var log: Array[String] = ["TRANSCRIPT - bot style: %s, seed %d" % [style, seed_value],
		"Lines starting with [%s] are the player's own reasoning; '>> STATE' is what the screen shows at the start of a combat round." % style.to_upper()]
	var r := play_run(style, seed_value, log)
	log.append("")
	log.append("RESULT: %s at tile %d/%d" % ["VICTORY" if r["won"] else "DEFEAT", r["run"].pos, r["run"].board.size() - 1])
	return log


## Meta-progression: the bot plays CAMPAIGN_RUNS runs in a row from a fresh profile,
## buying town upgrades between runs. Shows how fast the town makes the game easier.
func _campaign(style: String) -> Array[String]:
	var wins_at := []
	wins_at.resize(CAMPAIGN_RUNS)
	wins_at.fill(0)
	var first_win_total := 0.0
	var first_win_n := 0
	var embers_total := 0.0
	var levels_total := 0.0
	var curse_total := 0.0
	var road_only := 0.0      # embers from the road itself (no first-time quest rewards), runs 6-20
	var road_only_n := 0
	var dice_total := 0.0
	var bonus_n := 0
	for cmp in CAMPAIGNS:
		var path := "user://bot_campaign.save"
		GameData.safe_delete(path)
		var prof := Profile.new(path)
		var first := -1
		for i in CAMPAIGN_RUNS:
			var r := play_run(style, 90000 + cmp * 100 + i, [], prof.run_options())
			var res := prof.record_run(r["run"])
			embers_total += res["embers"]
			dice_total += res["dice"]
			if not res.get("boss_bonus", {}).is_empty():
				bonus_n += 1
			if i >= 5:
				var q_embers := 0
				for q in res["quests"]:
					q_embers += int(q["reward"])
				road_only += res["embers"] - q_embers
				road_only_n += 1
			if r["won"]:
				wins_at[i] += 1
				if first < 0:
					first = i + 1
			if r["won"] and prof.curse < prof.max_curse() and style != "newbie":
				prof.set_curse(prof.curse + 1)  # experienced bots climb the Curse ladder
			# Spend embers in this style's order.
			for id in BUY_ORDER[style]:
				if prof.can_upgrade(id):
					prof.upgrade(id)
				elif prof.next_cost(id) >= 0:
					break  # saving up for this one
		if first > 0:
			first_win_total += first
			first_win_n += 1
		for k in prof.levels:
			levels_total += prof.levels[k]
		curse_total += prof.curse
	var curve: Array[String] = []
	for i in CAMPAIGN_RUNS:
		curve.append("%d%%" % int(100.0 * wins_at[i] / CAMPAIGNS))
	return ["- **Campaign (%d profiles x %d runs, buying town upgrades):** win rate by run #: %s" % [CAMPAIGNS, CAMPAIGN_RUNS, " ".join(curve)],
		"- Campaign: first win on run #%.1f on average (%d/%d profiles ever won); %.0f embers per run; %.1f building levels and Curse %.1f after %d runs" % [
			_avg(first_win_total, first_win_n), first_win_n, CAMPAIGNS, embers_total / (CAMPAIGNS * CAMPAIGN_RUNS), levels_total / CAMPAIGNS, curse_total / CAMPAIGNS, CAMPAIGN_RUNS],
		"- Campaign economy: %.0f embers per road run from run 6 on (without first-time quest rewards); %.1f Grave Dice per run; first-boss-kill-of-the-day bonus paid on %.0f%% of runs" % [
			_avg(road_only, road_only_n), dice_total / (CAMPAIGNS * CAMPAIGN_RUNS), 100.0 * bonus_n / (CAMPAIGNS * CAMPAIGN_RUNS)],
		""]
