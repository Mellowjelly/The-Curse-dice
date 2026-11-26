# Cursed Dice v3.2: Critique of a Real Player's Session

**Critic:** game-critic (mobile roguelites, dice/deck builders, open-world gathering games)
**Primary evidence:** `player_diary.md` and `session.txt` (497 lines). I replayed the whole session with `tools/play_cli.gd` (English and `th`). "Replay l.N" refers to line N of the full English replay (`... session.txt 100000`). It matches the diary line for line.
**Also read:** `v2.2/critique.md`, `GDD.md`, `data/*.json`, `scripts/core/*.gd` and `scripts/ui/*.gd`. I read the UI scripts to sort each complaint into one of two tags:

- **[GAME]**: the problem is in the real game.
- **[CLI]**: the problem exists only in the text test interface. The graphical UI already handles it.

---

## 1. Verdict

**Score: 7.5 / 10** (v2.2: 6.5). The player gave 7/10. I mark it up half a point because about half of the diary's lowlights are CLI artefacts. The real UI already has the missing information (see §3).

1. The team acted on the v2.2 critique almost item by item. The Isle pays, both modes share one rule set, bosses need consent and you can flee, twists are pinned, the Forge previews faces, and unlocks are staged. The game is now **one joined loop**.
2. The combat core is still excellent, and the tuning works: both Bishop wins ended with heroes on 1–2 HP. Two boss fights with a phase line, two last-HP wins and a twist-into-triple moment is a very good session.
3. The new weak spots are **the second road** (the same boss, and now it pays less than the Isle), **villager chains** that never reach their Isle requests and offer rewards you already own, **Thai text hard-coded in core scripts**, and a few trust bugs.

---

## 2. What improved, what did not, what regressed (vs v2.2)

### v2.2 Top 10: status in v3.2

| v2.2 # | Change | Status | Evidence (v3.2) |
|---|---|---|---|
| 1 | Isle payout + Whetstones | **Done** | T1 fights paid +13 / +12 embers, T2 fights +29 / +20, Thornback +60 and 5 dust (replay l.1431, 3077, 3356, 3427). Every fight dropped something. "after each Isle win one face 'sharpens until you go home'" |
| 2 | Ember rebalance | **Mostly done** | `town.json`: victory 40, elite 10, tile 0.6. Stars now cost 25 embers + 4 dust (64→14 embers after two upgrades). Pet and relic banners cost 2 dice. The session ended with **138 embers / 19 dust** (v2.2: 33 / 19). *Not done:* an Isle boss gives no Grave Die |
| 3 | Information layer | **Done in the UI** | Forge: "Replaces faces 5-6. Now: …" (`town_screen.gd:923`). Loot modal "(replaces …)". The diary now learns the elements: "I learned the elements from the log. Good." "Super effective" is at least 1 damage (`combat.gd:637`) |
| 4 | One rule set | **Done** | Chapel max HP is the same on the road and the Isle (Varek 29/29 on the Isle after the chapel). Hesk's ghouls count on the Isle (1/8 after one Isle ghoul). Fate overflow works on the Isle ("ชะตาล้น: ทอยใหม่ฟรี +1") |
| 5 | Combat input safety | **Done** (spill turned off on purpose) | Twisted dice stay put (`combat.gd:135`), and a reroll never lands on the same face. Overkill spill was added, then set to 0 in 3.1 based on bot data. Reasonable, and the diary has no overkill complaint |
| 6 | Road scales with gear | **Done** | Bishop 72 HP → 76 HP with one SR hatchet. Both Bishop fights went 6+ rounds and ended on 1–2 HP: "Very satisfying" |
| 7 | Boss consent + flee | **Done** | "guards its lair here … use 'fight' to challenge it". "`flee` worked … Good safety valve." |
| 8 | Staged unlocks + Isle villager requests | **Half done** | Unlocks: "Each lock says exactly what opens it." Isle deliveries exist, but **every one is step 4 of its villager chain**, so "I never saw a villager material request" |
| 9 | Skill / hero pass | **Done** | Last Rite heals 4, revives at 6, costs 2. Vael was reskinned ("scalding water cures everything") |
| 10 | Bug sweep | **Mostly done** | The shop and rest texts are fixed. Tobin's "far fields" now starts at 0/20 (it completed retroactively in v2.2). *Still broken:* the event carving reuses the shop line (see P5) |

### What did not improve
- **The second road is still worse than the first.** v2.2 paid 187 then 58; v3.2 paid 224 then 71. The first-time quest bonus still carries run 1. Run 2 has the same boss and the same 14-event pool: "The second road felt like a repeat."
- **Crafting grind.** v2.2: the Alpha blade "at 59/60". v3.2: "6 bear hides … too many for one trip". Grind still converts poorly: 4 Amberheart → 1 dust (replay l.3487).

### What regressed or is new
- **The road now pays less than the Isle.** Isle trip 2 gave 109 embers from 3 fights plus a 30-ember quest plus materials. Road 2 gave 71 embers from a full 42-tile journey. The v2.2 QA target was "within ±20%". It overshot.
- **Villager rewards can duplicate what you own.** The longer villager chains are new. Marla offers Vael after Vael was summoned, and Pip offers Ember Salamander after the banner gave it (replay l.2939, l.1619). The game converts the duplicate to dust, but only says so *on claim*.
- **The Thai combat log is mixed.** These lines are core strings that never go through `tr()`: "The combo feeds your Fate +1 ชะตา", "(blood magic)", "rolls nothing...". They show in Thai mode in the real game (§7).

---

## 3. What works (protect this)

| Strength | Evidence | Why it matters |
|---|---|---|
| **Twist into a triple** | "used Fate 4 to Twist Lys to ATTACK 4 for a triple-attack combo … one-shot it. Best moment of the run, I felt smart." | The signature move now always pays off, because twists are pinned |
| **Boss tuning and writing** | Bishop phase 2: "Something underneath was never human." Thornback: "Flowers grow where it fell." "I won both on the last HP." | Gear scaling kept the boss tense. Don't nerf it |
| **Skills with a price** | "Broken Oath … plus Last Rite saved me … each has a price, which fits the tone." | The tone pillar works as a mechanic too |
| **Unlock pacing** | "I knew right away that the road comes first." | Fixed the v2.2 "10 new verbs at once" |
| **The town clock** | "Captain Hesk is 'away' and comes out only at dusk and night … the town feels like it has a clock." | Cheap world-building. Keep it |
| **Isle safety valves** | Flee, lair consent, no HP regen between fights: "good tension, it pushes you to go home" | Push-your-luck trips without hidden punishment |
| **Requests that teach mechanics** | "Pip's carve x5 and Marla's twist x4 … nudge you to try mechanics" | Onboarding by request is the right pattern |
| **Bestiary and villager text** | "Hounds of the old kennels, rebuilt by someone who never saw a dog." | Excellent flavour per word |

---

## 4. Problems ranked by impact

Format: **problem → evidence → fix → effort** (S ≈ 1 day, M ≈ 2–5 days, L > 1 week).

### First: complaints that are CLI-only (not game problems)
The real UI already covers these. They still matter, because they skew every future AI playtest (see Top 10 #10).

| Diary complaint | Real game |
|---|---|
| "`equip_loot` never says which faces it replaces" | The loot modal shows "Give to X (replaces …)" (`game_screen.gd:411`) |
| "Buildings have no description" / "Kennel `next -1`" | The town shows `b["desc"]`, "Build (N Embers)" and "MAX" (`town_screen.gd:480–482`) |
| "Upgrade cost never shown" | "Upgrade N Embers + N Dust" and "Next star: …" (`:766, :773`) |
| "Could not see rates or what is in each banner" | The summon panel shows the new-item chance, the ember fallback and pity (`:507`) |
| "No quest list" | A Quests tab with progress and rewards (`:575`) |
| Raw JSON rewards and drops | Only CLI `str()` |
| `goto` keeps stopping at the Ashen Alpha's lair | The UI shows one toast and doesn't block movement (`world_screen.gd:464`) |
| "Pip shows DONE but can't be claimed" | Core requires the villager to be out. Only the CLI message "Not finished yet." is wrong |
| Wrong-phase `roll` gives no error | CLI only |
| Events, villagers and summons in English with `th` | The strings exist in `lang_th.json`. The CLI just doesn't call `tr()` on them |
| "Always Aldric" sharpening | The CLI uses a fixed seed (`rng_world.seed = 11`), while `world_screen.gd` uses an unseeded RNG. Probably seed luck, but see P7 |

### P1. The second road is a repeat, and it pays less than the Isle [GAME]
- **Player:** "The second road felt like a repeat: same boss, same events pool." "Reward was only +71 embers."
- **Analysis:**
  - Road 1 paid **224 embers** (with five first-time quests). Road 2 paid **71** (replay l.2917). Isle trip 2 paid **139 embers** (29 + 60 + 20 + quest 30) for 3 fights, plus 18 Amberheart and a boss hide.
  - The road is the slower and riskier mode, yet it is now the worse ember source.
  - The road has one boss (the Bishop) and 14 events.
  - The Curse ladder exists in the real UI (+25% embers per level, `profile.gd:39`), but nothing *pushes* the player to it after the first win.
- **Fix:**
  - After the first Bishop kill, a villager line plus a town banner: "The road remembers you. Curse I unlocked: +25% embers, new rule."
  - Road `per_fight` 1 → **5**. A first-Bishop-kill-of-the-day bonus of **+40 embers**.
  - At Curse II+, one of two **alternate road bosses**, chosen by the time of day.
  - **+6 events**, including 2 that trade Isle materials.
- **Effect:** road 2 is worth about 120–140 embers (±20% of an Isle trip), and each run has a visible "next rung".
- **Effort:** M

### P2. Villager chains never reach the Isle requests, and they offer duplicates [GAME]
- **Evidence:**
  - "I never saw a villager material request." In `villagers.json`, **all four** `deliver` requests are step 4 of 4. After two roads the player was on step 2–3.
  - Duplicate offers: Marla rewards hero `vael` (already summoned), Pip rewards `ember_salamander` (already owned) and `mordecai` (summoned right after accepting). The conversion only shows on claim: "Ember Salamander is already with you, so it turns into 8 Star Dust."
  - Hesk's first request, 8 ghouls, sat at 2/8 after a full session, and it gates his whole chain. Ghouls are rare on the Isle, and Hesk is only out at dusk and night.
- **Fix:**
  - Move each `deliver` request to **step 2**, available from the first Isle unlock. Tobin's "6 Grave Iron" is the natural Isle tutorial.
  - Resolve item rewards **when the request is offered**: if the item is owned, offer an unowned one from the same pool, or print "(you have it: becomes 8 Star Dust)" in the ask.
  - Hesk: 8 → **5 ghouls**, plus a night-only ghoul pack in Ashfall Vale.
- **Effect:** the Isle has a purpose from minute 1 (the v2.2 plan, finally delivered), and rewards stop feeling like a cheat.
- **Effort:** S

### P3. Core strings bypass translation, so the Thai combat log is half English [GAME]
- **Evidence (th replay):**
  - "The combo feeds your Fate +1 ชะตา" (in almost every fight)
  - "Lys (blood magic) ตี …"
  - "Varek rolls nothing... +1 ชะตา"
  - "Luck is never free for Mordecai (-3 HP)"
  - "ชนะ! +27 ทอง The party catches its breath (+35% HP). The elite drops its arms."
- **Cause:**
  - `combat.gd:293, 317, 464, 494` and `gain_fate(2, "Loaded Dice:")` pass raw English into `tr("%s +%d Fate")`.
  - `run.gd:208, 211, 427, 432` append untranslated suffixes with `+=`.
  - The translation test only scans `data/*.json`, so these lines slip through.
- **Fix:**
  - Wrap each of these strings in `tr()`, and use `tr(skill["name"])` for the skill name.
  - Add a test that greps `scripts/core/*.gd` for `_log(`, `gain_fate(`, `_pay_hp(` and `last_reward_text +=` with a bare `"..."` literal.
- **Effect:** a fully Thai combat log, and the problem can't come back.
- **Effort:** S

### P4. Crafting grind and a bad grind ratio [GAME]
- **Evidence:** "Cave Bear dropped only 1 bear_hide. The armor needs 6." "4 Amberheart ground into just +1 star dust." `thornback_carapace` needs the boss hide **plus 6 bear hides**.
- **Analysis:** beasts drop 1–2 hides (`world.gd:292`). At a 6-hide cost, one SR armour takes about 4 beast fights. That is fine for a goal, but nothing tells the player how far away it is. Grind is 4:1, while selling the same 4 Amberheart gives +12 embers (replay l.3489).
- **Fix:**
  - Beast hides **2–3** per win.
  - SR armour hides 6 → **4**.
  - Grind **2 common → 1 dust** (rare 1 → 3).
  - The Forge shows "need 5 more Bear Hide · Cave Bears in Elderglade".
- **Effect:** an armour piece per 2-trip goal instead of 4. Grind becomes a real choice.
- **Effort:** S

### P5. Trust bugs: wasted Fate, stale text, silent chest [GAME]
- **Fate Shard caps:**
  - Evidence: `buy fate_shard` at Fate 3 → Fate 5. "1 point lost, no warning."
  - Cause: `run.gd:668` uses `min(MAX_FATE, fate + 3)`, while the game's own rule (GDD and `gain_fate`) is "overflow becomes a free reroll".
  - Fix: route it through `combat.gain_fate(3, …)`, and show "(2 overflow → free reroll)" on the shop card.
- **Bleeding Altar text:**
  - Evidence: `pick 0` → "The Bone Carver sets to work on your dice." (replay l.251).
  - Cause: event carvings don't set `last_reward_text`, so the shop line stays. This is v2.2 bug B1 surviving in the event path.
  - Fix: event effects that carve set "The altar drinks. Your dice change shape."
- **Chest gold:**
  - Evidence: a gold-only chest goes straight back to the map, gold 42 → 62, with no message. `game_screen` doesn't listen to `run.log_added`, so this is likely silent in the UI too.
  - Fix: a 1.5 s toast or floating "+20 gold" on the map.
- **Effort:** S

### P6. The elite that never attacks [GAME]
- **Evidence:** "Elite Grave Knight mostly 'Hesitates' and went down in 3 rounds. The elite felt weaker than some normal fights." Replay: intents in rounds 1–3 were *Hesitates, Shield 5, Hesitates*, so it never attacked.
- **Analysis:** an elite fight pays the most (+27 gold, 35% heal, a 2-weapon choice), so its threat must be reliable. One blank face out of six is fine on fodder and bad on the one enemy you route toward.
- **Fix:** add an elite trait "Relentless": a blank roll becomes the elite's best attack face. Alternatively, swap the Grave Knight's blank for `attack 4`.
- **Effect:** elites read as elites. The routing choice ("3 elites in a row … I routed around them") becomes a real risk/reward choice.
- **Effort:** S

### P7. Isle sharpening has no choice [GAME, the bias is likely CLI]
- **Evidence:** all 5 sharpenings went to Aldric (HEAL, GUARD, HEAL, GUARD, HEAL). The code picks a random living hero and only faces 1–4 (`world.gd:310–316`).
- **Analysis:** even without the seed bias, a random +1 on a random face is invisible power. The road's "pick 1 of 3 carvings" is the beloved version ("Carving feels great").
- **Fix:** after an Isle win, offer **1 of 3** sharpenings (different heroes), using the same modal as road carvings.
- **Effect:** one more small decision per Isle fight, and it is consistent with the road.
- **Effort:** S

### P8. Pet passives are unclear [GAME, mostly UI wording]
- **Evidence:** "Black Cat ('+1 reroll every round') … *shielded* allies and *hit* enemies … my rerolls stayed at 3. I could not tell whether the '+1 reroll' ever happened."
- **Analysis:** the passive works (`REROLLS_PER_TURN` is 2, the player had 3). The pet also rolls its own d4, and the description mentions only the passive. Nothing ties the 3rd reroll to the cat.
- **Fix:**
  - Show two lines on the pet card: "Passive: +1 reroll each round" and "Die: ATK2 / SHD2 / ATK1 / –".
  - The combat button reads "REROLL (3 left · +1 Black Cat)".
  - Ash Crow logs "Ash Crow: +2 Fate" at the start of a fight.
- **Effect:** the player understands the pet choice, the first decision of every run.
- **Effort:** S

### P9. The Isle lacks long-term hooks into the gacha [GAME]
- **Evidence:** Isle quests "just pop ('Landfall', 'A Full Cart'). Rewards are small (+20/+30 embers)." Thornback paid 60 embers, 5 dust, **0 Grave Dice**. Dice still come only from the road: "Never had 3 Grave Dice spare" (v2.2), and 2 dice at the end of v3.2.
- **Fix:**
  - A first kill of each Isle boss gives **+2 Grave Dice**, and repeats give +1 per day.
  - Isle quests pay dust or dice rather than embers, since embers are no longer scarce.
  - Isle quests are announced on departure: "Isle task: bring home 20 materials".
- **Effect:** both modes feed the summon banners, and an Isle trip has a stated goal.
- **Effort:** S

### P10. The CLI under-reports the game, and future playtests inherit the noise [CLI / tooling]
- **Evidence:** 6 of the 13 "Confusions and bugs" and 4 of the 6 lowlights are CLI-only (table above).
- **Fix:** see Top 10 #10.
- **Effort:** S

**Minor:**
- An Ash Cultist shows "Heal 3" while at full HP. It heals an ally (correct), but the intent has no target. Show "Heal 3 → lowest ally".
- The GDD header says 3.0, but the build is 3.2.

---

## 5. Onboarding and the first 10 minutes

| Minute | What happened | Grade |
|---|---|---|
| 0–2 | Town, 4 villagers, 3 requests that fit one road. The locks explain what opens them | **A** |
| 2–4 | Pet pick: Black Cat's passive vs its die is unclear (P8) | **B−** |
| 4–10 | Carving, lock/reroll, then the first twist into a triple. Pinned twists make it pay off | **A** (v2.2: D) |
| End of road 1 | +224 embers, 9 dice, 5 quests, then Summon, Build and the Isle unlock in one stop | **B**: much better than v2.2. Building descriptions exist in the UI |
| First Isle trip | Gather, two fights, a boss warning, flee, home | **A−** |

**Recommendation:** make the step-2 villager request the Isle tutorial (P2). That is the one onboarding piece still missing.

---

## 6. Economy and progression

### Currencies (as measured in this session)

| Currency | Earned | Spent | End | Verdict |
|---|---|---|---|---|
| Soul Embers | about 620: road 224 + 71, Isle 45 + 139, summon fallbacks 70, sales 14, quests | buildings 290, crafts 35, stars 100 | **138** | **Healthy** (v2.2: starved at 33). Every return bought something |
| Star Dust | about 35 | stars 16 | **19** | Slightly loose but useful. Duplicate rewards add +8 lumps |
| Grave Dice | 12 (road 9 + 3) | 3 + 2 + 2 + 3 | **2** | **The tightest currency now.** Only the road gives dice (P9) |
| Materials | 18 Amberheart, 10 Grave Iron, 1 bear hide | 2 crafts | surplus commons, starved hides | Surplus commons need a better sink (grind 2:1, P4) |

### Pacing
- **Ember income per unit of play:** Isle T2 is about 25–30 per fight plus a quest. The road is about 70 per journey after run 1. Isle trips are **faster and richer**. Fix the road side (P1), not the Isle.
- **Stars:** 25 embers + 4 dust per step works. The player upgraded 4 things in one session without starving other sinks. Keep it.
- **Buildings:** chapel, market and smithy (220 embers) after road 1 is a good first purchase.

**Targets for QA (3.3):**
- Road journey 2+ ember income is within ±20% of an Isle T2 trip.
- One Grave Die source per mode.
- Every craftable SR is reachable in at most 2 Isle trips.

---

## 7. Thai translation findings

**Good (protect):**
- Most of the combat log reads naturally: "Varek ตี หนูโรคระบาด 3 ดาเมจ", "บิชอปเน่า กวาดทั้งทีม!".
- Intents are short ("โจมตี 5", "ลังเล", "โล่ 3").
- The boss lines keep their mood: "สิ่งที่อยู่ข้างใต้ไม่เคยเป็นมนุษย์", "ดอกไม้ผลิบานตรงที่มันล้ม".
- No broken placeholders or garbled characters.

**Real-game gaps (P3):**
- `combat.gd` passes English reason strings: "The combo feeds your Fate", "(blood magic)", "%s rolls nothing...", "Luck is never free for %s", "Loaded Dice:". The last one appears as "เต๋าถ่วง" elsewhere.
- `run.gd` appends English suffixes: "A weapon lies among the bones.", "Inside, a bone chisel.", "The Candle Moth mends your wounds", "The party catches its breath … The elite drops its arms."
- Add the grep test from P3 so the CI catches the next one.

**Wording:**
- "พวกเดียวกันทุกคนฮีล %d" (Last Rite) reads like "the same gang". Use **"ทุกคนในทีมฟื้น %d HP"**.
- Face names stay English in combo and twist lines ("คอมโบ: ATTACK หนึ่งคู่"), while intents use Thai ("โจมตี", "โล่", "ฮีล"). Pick one rule. I recommend Thai everywhere in text ("คอมโบ: โจมตี หนึ่งคู่"), with the face icon carrying the identity.
- In combat lines, monsters hit "Brother Aldric" and "Varek the Oathbroken" (full titles) while heroes speak as "Aldric". Use `Combat.short_name()` for hero targets in both languages. It is shorter on a phone, too.
- "(แพ้ทาง)" on an enemy hitting a hero is correct but reads ambiguously. Consider "(ไม่ค่อยได้ผล)" / "(ได้ผลดีมาก!)", which say how effective the hit was rather than who is weak.

**CLI-only:** event titles, villager lines, summon results and "JOURNEY OVER" are English with `th` only because `play_cli.gd` prints them without `tr()`. They have Thai lines in `lang_th.json`. The diary's claim that "By the fire, you whittle at your dice" is untranslated is **wrong**: the th replay prints "ข้างกองไฟ คุณนั่งเหลาลูกเต๋า".

---

## 8. Top 10 changes for 3.3

Ranked by impact per effort.

| # | Change | Problem → evidence | Concrete fix | Expected effect | Effort |
|---|---|---|---|---|---|
| 1 | **Make the road worth replaying** | Road 2 is the same Bishop and pays 71 vs 139 for an Isle trip. "felt like a repeat … paid much less" | Announce Curse I after the first win (+25% embers). `per_fight` 1→5. First Bishop kill of the day +40. 2 alternate bosses from Curse II by time of day. +6 events (2 trade Isle materials) | Road 2+ ≈ 120–140 embers. Each run has a next rung | M |
| 2 | **Villager chains: Isle requests early, no duplicate rewards** | "I never saw a villager material request." All `deliver` steps are step 4. Marla offers Vael while she is owned | `deliver` becomes step 2. Rewards resolve to unowned items when offered, or are labelled "(owned → 8 dust)". Hesk 8→5 ghouls plus a night ghoul pack | The Isle has a purpose from the first trip. Rewards feel fair | S |
| 3 | **Thai: route every core string through `tr()` and test it** | "The combo feeds your Fate +1 ชะตา", "(blood magic)", English elite suffix | Wrap the strings in `combat.gd` / `run.gd`. Add a grep test for bare literals in `_log` / `gain_fate` / `_pay_hp` / `+=`. Fix the "พวกเดียวกัน" wording and the face-name rule | A clean Thai log. Regressions caught by CI | S |
| 4 | **Cut the crafting grind** | "6 bear hides … too grindy". Grind 4 → 1 dust | Beast hides 2–3. SR armour 6→4 hides. Grind 2:1. "Need N more · where" in the Forge | One SR armour per 2 trips. Grind becomes a real choice | S |
| 5 | **Trust-bug sweep** | Fate Shard capped, the altar shows shop text, a silent chest | Fate Shard via `gain_fate` (overflow → free reroll) with a shop-card hint. An event carving line. A "+N gold" toast on the map. Fix the GDD version header | Every action states its true result, with no silent losses | S |
| 6 | **Elites that threaten** | Grave Knight: Hesitates, Shield, Hesitates. "weaker than some normal fights" | Elite trait "Relentless": blank → best attack. Or swap the Knight's blank for `attack 4` | The elite risk matches its reward. Routing choices matter | S |
| 7 | **Choose your Isle sharpening** | 5/5 sharpenings went to Aldric. Random, invisible power | After an Isle win, pick 1 of 3 sharpenings for different heroes (reuse the carving modal) | One small decision per Isle fight, consistent with the road | S |
| 8 | **Pet clarity** | "I could not tell whether the '+1 reroll' ever happened." The cat also hits and shields | Separate "Passive" and "Die" lines on the card. "REROLL (3 left · +1 Black Cat)". A start-of-fight passive log line | The first choice of every run is understood | S |
| 9 | **Isle feeds the gacha** | Thornback gave 0 Grave Dice. Isle quests +20/+30 embers "did not make the trip feel worthwhile". 2 dice left at the end | Isle boss first kill +2 Grave Dice, then +1 per day. Isle quests pay dust or dice and are announced on departure | Both modes feed summons. Each trip has a stated goal | S |
| 10 | **CLI parity for playtests** (tooling) | About half the diary lowlights are CLI artefacts (no loot preview, no building desc or costs, raw JSON, no `quests`, `th` skipping events and villagers) | `play_cli.gd`: print `(replaces X Y)` on `loot`. Add `info <building\|hero\|banner\|pet>`. Add `quests`. Show costs in `status`. Pretty-print rewards. `tr()` everything with `th`. Error on wrong-phase commands. Route `goto` around lairs. Print "X is not out now" | The next diary measures the game, not the test tool | S |

**Not in 3.3 (on purpose):** new Isle countries or T3+ content. The player "would keep playing to … push into tier 3", so the content is there. The bottleneck is reasons to replay the road and clarity, not width.
