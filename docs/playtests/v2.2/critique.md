# Cursed Dice v2.2: Critique of a Real Player's Session

**Critic:** game-critic (mobile roguelites, dice/deck builders, open-world gathering games)
**Primary evidence:** `player_diary.md` and `session.txt` (703 lines, about 600 commands). I replayed the session with `tools/play_cli.gd` and quote that output as "replay". Line numbers refer to that replay.
**Also read:** `GDD.md`, `README.md`, `report.md` (bots), `docs/*.png`, `v1.0/critique.md`, and `scripts/ui/*.gd` (to separate real-UI problems from text-interface-only problems).

> **Caveat for the team.** `scripts/core/*.gd`, `tools/play_cli.gd` and `scripts/ui/world_screen.gd` were changed **during** this review (timestamps 08:12–08:13 UTC). A replay after that point gives different text (for example, `rest carve` now says "By the fire, you whittle at your dice.", and `craft` now prints the item's stats). All evidence below comes from the first replay, which matches the diary line for line, so it is **v2.2 as played**. Before 3.0 work starts, QA should re-check which bugs below are already fixed.

---

## 1. Verdict

**Score: 6.5 / 10.** The player gave 7/10. I mark it down half a point because the problems are structural (economy and mode parity), not polish.

1. The dice combat is excellent. Lock, reroll, twist, combos and weapons that rewrite faces make every turn a readable puzzle, and the writing gives it a real mood.
2. The 2.x layers around it (the Isle, the Forge, stars, the six-element wheel) are wide but thin. Isle fights pay 5–14 embers, embers choke every sink, and the Isle and the road keep separate rules (HP, quests, carvings, time).
3. 3.0 should not add another layer. It should **join the layers into one loop**: one economy, one rule set, one information system. Then fix a short list of trust-breaking bugs.

---

## 2. What works (protect this)

| Strength | Evidence | Why it matters |
|---|---|---|
| **Combo turns** | "Fight 2: TRIPLE ATTACK … wiped three rats in one turn … -> Best moment of the early game. Felt smart." | This is the dopamine core. Never dilute the triple ×2. |
| **Weapons rewrite the die** | "Executioner's Axe (attack8/blank) … natural triple: 16 damage. Weapons visibly reshape the die. -> This is the core fantasy and it works." (replay 1103, 1218 "Varek hits The Rotting Bishop for 16") | It proves the one-liner in GDD §1: building your dice is building your team. |
| **Hunt → trophy → SSR craft** | "Ashen Alpha … Got the **Alpha Fang**! -> Great 'hunt the beast for its part' loop." | This is the best idea in 2.x. Build 3.0's Isle around it. |
| **Writing** | Hanged Man's Purse ("his fingers twitch"), "Something underneath was never human", Mordecai "bet his shadow at a crossroads and lost" | Tone is on target (CLAUDE.md: grim, candle-lit). |
| **Smart no-waste rules** | "Heal on a full-HP hero turns into a shield ('prayer wards') - smart, no wasted die." | Keep this rule pattern: a bad roll is softened, never voided. |
| **Gentle Isle defeat** | "Defeat … sent me to the gate with half HP and my bag. -> Forgiving" | Good for a mobile audience. Keep it for T1–T2. |
| **Near-miss bosses** | Bog Mother lost "with her on 11 HP", Thornback "lost with the boss on 8 HP": "tense, 'one more try' feeling" | Boss HP tuning on the Isle is in a good band. |
| **Road pacing** | "The road run has good pacing"; "Nice small decision each step" | Road fights average 3.5 rounds in the replay; the bots estimate 12–18 min sessions. |
| **Requests that fit one run** | "Accepted all three because they all fit one road run. -> Felt like a cosy start, clear goals." | This is good onboarding. Copy the pattern for the Isle. |

---

## 3. Problems ranked by impact

Format: **problem → evidence → fix → effort**. Each problem is tagged **[GAME]** (in the real game too) or **[CLI]** (text interface only). I checked `scripts/ui/*.gd` to tag them.

### P1. The Isle doesn't pay, so the open world feels like a chore [GAME]
- **Player:** "Isle fights are a slog: base dice only, 2 rerolls, 5-6 rounds for ~8 embers and often no drops."
- **Analysis (replay):**
  - 9 normal Isle wins paid **5, 14, 8, 7, 5, 8, 12, 7, 10 embers** (avg 8.4).
  - 4 of the 9 dropped **nothing** (`drops {}`).
  - Length is *not* the real problem: Isle fights averaged about 3 rounds, about the same as road fights (3.5). The real problem is **reward per minute** and **lost build**. Road carvings don't exist on the Isle: Varek is back to `attack2 attack3 shield3 blank0` there.
  - Code: `world.gd` pays `4*tier + rand(0, 3*tier)` embers per fight.
- **Fix:**
  - Isle embers ×2.5: `10*tier + rand(0, 5*tier)`.
  - Every humanoid group drops 1 tier material, so there are no empty drops.
  - Add an **Isle Whetstone**: each Isle win gives 1 temporary carving, up to 3, that lasts until you return to Ashfall. This brings the carving fantasy to the Isle.
- **Effort:** M

### P2. Embers are the only real bottleneck. Dust and dice pile up, embers never do [GAME]
- **Player:** "Embers are the real bottleneck: crafting, upgrades and buildings all eat them, and only the road gives real amounts."
- **Analysis:** see §5. Sinks total about 1,300 (buildings) + about 480 per hero for stars + 15–160 per recipe. Income is about 50 per road win (the second road paid **+58 at night**, even with +40%). The session ended with **33 embers but 19 Star Dust**, and the player crafted the Alpha blade at **59/60** by selling a hide for 2.
- **Fix:** see Top 10 #2.
- **Effort:** S (data only)

### P3. Two modes, two rule sets [GAME]
- **Evidence:**
  - Quests: "Hesk 'ghouls 0/8' though I killed ghouls on the Isle; Marla 'twists 0/4' though I twisted ~5 times on the Isle" (replay 2848–2853).
  - Max HP: chapel built, then Varek is 29/29 on the road but **28/28 on the Isle** (replay right after `build chapel` → `explore`).
  - Time: it stayed "dusk" through three Isle trips, so the day/night trade-off never reaches the Isle.
  - Fate overflow: on the Isle, Loaded Dice at Fate 5 stays 5 with rerolls unchanged, but GDD §4 says overflow becomes a free reroll.
- **Fix:** one `PartyState` used by both modes (max HP, armour, stars, chapel), one quest event bus (kill/twist/rest/carve events from any combat), and an Isle clock that advances one phase every 4 Isle fights.
- **Effort:** M

### P4. Information gaps (mostly the CLI, but three are real)
- **Player:** "Too much is unexplained: buildings, star upgrades, elements, what a weapon will replace."
- **Checked against the real UI:**
  - **[CLI only]** Building descriptions (`town_screen.gd:234,477` shows `b["desc"]`), star "Next star: …" text (`:713`), and recipe faces (`:812`) already exist in the real game. "Crafted item #1." was a CLI message.
  - **[GAME]** The Forge "Give Varek" button (`town_screen.gd:849`) does **not** preview what it replaces. The road loot modal does ("replaces SHIELD4 GUARD2", `game_screen.gd:409`). The player lost his tank this way: the Alpha blade "overwrote Varek's shield4/guard2 - he stopped being a tank."
  - **[GAME]** The element wheel is never shown. Enemy cards show "weak to Fire" (`combat_view.gd:514`, `screenshot_elements.png`), but hero cards don't show what *hurts them*. Light↔dark is mutual, so Aldric takes +20% from every ghoul and from the Bishop (replay 852, 1208), and the player never found out why. Diary: "I never figured out the bonus."
  - **[GAME]** "super effective!" is printed on 0 damage: "Bone Hound hits Brother Aldric for 0 (super effective!) (2 blocked)" (replay 3019, also 1805).
- **Fix:** see Top 10 #3.
- **Effort:** M

### P5. Walking into a world boss with no warning, no consent and no flee [GAME, verify]
- **Evidence:** `goto 40 76` → "Walked 14 steps. A monster blocks the way! FIGHT in Marshes of Veyl (tier 2) - BOSS!" (replay 2285). It was a 10-round loss.
- **Note:** `world_screen.gd` now has `_challenge_boss` and `_boss_warned` ("bosses only fight when you tap them on purpose"). That file was edited during this review, so check whether it shipped in 2.2. The CLI `goto` path certainly doesn't use it.
- **Fix:**
  - Bosses fight only on an explicit challenge, in both the UI and `goto`.
  - Add a **Flee** button from round 2: the party loses 15% HP and the boss heals fully.
- **Effort:** S

### P6. The twist-then-lock trap [GAME in a milder form, CLI in full]
- **Evidence:** `twist 1 3` → "blood 6 LOCKED", then `lock 1` → unlocked, then `reroll` → "attack 4" (replay 396–418). Four Fate thrown away. "Felt cheated by the interface, not the game."
- **Real UI:** tapping a twisted die also toggles its lock (`toggle_lock`), so a mis-tap on a phone does the same thing.
- **Fix:** a twisted die is **pinned**. It can't be unlocked this round and shows a small pin icon. A tap on it shows "Twisted - pinned".
- **Effort:** S

### P7. Stale reward text on every non-combat carving or loot screen [GAME]
- **Evidence:**
  - `buy carving` → "Victory! +9 gold." (replay 540)
  - `rest carve` → "You pry open a rotten chest: +22 gold. A weapon lies among the bones." (1144)
  - Night `rest carve` and `buy carving` → "Victory! +29 gold. The party catches its breath (+35% HP). The elite drops its arms." (3433, 3354)
- **Cause:** the real UI modal prints `run.last_reward_text` (`game_screen.gd:398,418`), and the shop, rest and event carvings never reset it.
- **Fix:** set or clear `last_reward_text` in `_offer_carving` and `_offer_loot` for every source.
- **Effort:** S

### P8. The first Bishop is too easy once a rare weapon lands. Crafted gear will make the road trivial [GAME]
- **Evidence:** "Rotting Bishop died in 3 rounds (66 HP) … the fight was too easy." The second fight, at night (79 HP), took 6 rounds and was "closer". `report.md` shows a tactician win rate of 87% and boss fights of 7.3 rounds.
- **Analysis:** 2.1 lets Isle-crafted SR/SSR weapons ride on the road ("Crafted Alpha blade came along"). With `attack7 + cleave3` on face 5–6, triples reach 14+. Road difficulty doesn't scale with that gear.
- **Fix:** see Top 10 #6.
- **Effort:** M

### P9. Quests that complete wrongly or can't be done [GAME]
- **Evidence:**
  - Tobin "Go further than tile 20" was accepted in town and showed **DONE before any new journey** (status after `accept tobin`: `tobin(out, DONE)`).
  - Tobin "two elites in one journey": "the road never offered me a second elite in reach."
  - Hesk's ghoul quest can't progress on the Isle (P3).
- **Fix:**
  - Count progress only from the moment of acceptance.
  - Make "2 elites" quests guarantee that an elite tile appears in the roll preview at least twice per run (seeded elite at tiles 12–16 and 26–32).
- **Effort:** S

### P10. Targeting and overkill [GAME]
- **Evidence:** "a 17-damage triple-attack overkilled a 5 HP serpent; I couldn't aim dice separately." Note that auto-retarget does work between dice ("each die auto-retargeting after a kill"). So the loss is only *within* a single big hit.
- **Fix:** overkill on `attack` and `blood` spills 50% to the next living enemy, with a "spills!" label.
- **Effort:** S
- Per-die targeting is an M-sized change and should wait until it's tested on a phone.

### P11. Weak or contradictory content [GAME]
- **Last Rite:** "All allies heal 3" then "Aldric's faith is paid in blood (-3 HP)" (replay 1858–1859). It nets 0 on Aldric at charge 6, so it's the weakest skill in the session.
  - Fix: heal 4, revive at 6 HP, cost 2.
- **Sister Vael:** she is **water** but has three FIRE faces (`fire2 fire3 fire1`), and her bio says "fire cures everything." Her fire damage uses the water multiplier, which teaches the wrong wheel.
  - Fix (pick one): make her fire element and move Lys to another element, or reskin her faces as a water-themed "Miasma" burn.
- **Fair-play report:** "Rerolls frequently produce the identical face." This is **not a bug**: Lys has one `shield2` face in 6, so it's 1/6 per reroll. But the feeling is real.
  - Fix: on a reroll that lands on the same face, play a "the die clatters back…" sound and give **+1 Fate** ("Fate pities you"). This turns a feel-bad into a small gain.

---

## 4. Onboarding and the first 10 minutes

| Minute | What happened | Grade |
|---|---|---|
| 0–2 | Town, talk to 4 villagers, 3 requests that fit one road run | **A**: clear, cosy goals |
| 2 | `recipes` dumps 20 recipes with unknown materials | **C** [mostly CLI]: in the real UI, the Forge should hide recipes until a material of that recipe has been seen |
| 3–8 | Pet pick, rest vs shop, first fights teach lock/reroll, then a triple | **A** |
| 8–10 | First twist is ruined by the lock toggle | **D**: the first use of the signature mechanic punished the player (P6) |
| After road #1 | 187 embers, 8 dice and 10 new verbs at once (summon ×3 banners, build ×6, craft, upgrade, equip, explore, sell, grind) | **C**: "Built smithy + chapel blind" |

**Recommendations:**
1. **Pin twists** (P6). The first twist must feel great.
2. **Staged unlocks after the first Bishop:**
   - Run 1 return: Summon (heroes) and the Chapel only.
   - Run 2: the Isle (Ashfall Vale only) plus a villager request: "Bring me 6 grave iron."
   - First Isle return: the Forge.
   - First craft: stars.
   - Marshes and Elderglade: after the Ashen Alpha.
   - Each unlock gets one sentence from a villager. This reuses the existing villager system and costs no new UI.
3. Tobin should send you to the Isle (the GDD 2.x plan "ชาวบ้านขอแร่", villagers ask for ore). His request becomes the Isle tutorial.

---

## 5. Economy and progression review

### Currencies (as measured in this session)

| Currency | Earned (session) | Main sources | Spent on | End balance | Verdict |
|---|---|---|---|---|---|
| Soul Embers | about 420 (road 187+58, Isle 76 + boss 30, summon fallbacks 70) | road wins (`victory 20`, `per_elite 4`, `per_tile 0.4`), first-time quests | buildings 160, crafts 150, stars 80 | **33** | **Starved**: every sink competes |
| Star Dust | about 21 | quests, Isle drops, boss | stars (2 each) | **19** | **Flooded**: the ember half of the star cost is the real gate |
| Grave Dice | 13 | road (+8, +5), quests | 4 hero summons | 1 | Tight. "Never had 3 Grave Dice spare after the hero banner." The Isle gives **0** dice |
| Road gold | per run | fights, chests | shop | resets | Healthy. The shop decisions read well |
| Materials | plenty of common ones (bog_copper 10, grave_iron 8, amberheart 5) | gather, hides | recipes | surplus | Common mats are fine. Embers block every recipe |

### Sink vs faucet
- **Buildings:** 1,300 embers in total.
- **Stars:** 480 embers per SR hero from 1★ to 5★ (40/80/140/220). With 6 heroes that is about 2,900.
- **Recipes:** 15–160 each, and the SSR recipes are 60–160.
- **Total:** about **5,000 embers** of sinks against about **50 per 15-minute road win** and **8 per Isle fight**. That's about 100 road runs.
- The first star is poor value: +2 max HP for 40 embers (stars.json). The player "only noticed later."
- The night road (+40%) paid **less** in practice (58) than the first road (187) because the first road's quest bonuses carried it. The night bonus is invisible next to quest income.

### Recommendations (numbers)

| Lever | Now | 3.0 | Expected effect |
|---|---|---|---|
| Road win embers (`town.json` embers) | victory 20, elite 4, tile 0.4 | victory **40**, elite **10**, tile **0.6** | about 95 per win instead of 50 |
| Isle fight embers | `4t + r(0,3t)` | `10t + r(0,5t)` | T2 fight about 25, so an Isle trip of 6–8 fights is about 175, close to one road run |
| Isle boss | 30t embers, 0 dice | 40t embers + **1 Grave Die** | Ties the Isle to the gacha |
| Star cost (SR) | [40,2][80,4][140,7][220,12] | **[25,4][50,8][90,12][150,18]** | Moves the gate onto dust, which is in surplus |
| Material sell price | boar_hide = 2 | common 3, rare 15, and shown | Turns surplus into embers without trivialising |
| Pet/Relic banners | 3 dice | **2 dice** | A player touches all three banners every 2 runs |
| First star effect | +2 max HP | +2 max HP **and** +1 to the weakest face | The first upgrade feels like a die change (core fantasy) |

**Targets for QA:**
- Ember income per 15 minutes is within ±20% between the road and the Isle.
- A new player can afford one meaningful sink (a building, a star or a craft) after **every** session.

---

## 6. Top 10 changes for 3.0

Ranked by impact per effort. Effort: S is about 1 day, M is 2–5 days, L is more than a week (for one AI programmer plus a designer).

| # | Change | Concrete spec | Expected effect | Effort |
|---|---|---|---|---|
| 1 | **Isle payout and Whetstones** | Isle embers `10t + r(0,5t)`. Every group drops at least 1 material. Each Isle win gives 1 temporary carving token (max 3 per trip, choose 1 of 3 carvings, lost on return). | The Isle becomes as rewarding as the road. Building your dice works in both modes. Fixes "slog". | M |
| 2 | **Ember economy rebalance** | Road: victory 40, elite 10, tile 0.6. SR stars [25,4][50,8][90,12][150,18]. Show sell prices; common 3, rare 15. Pet/relic banners cost 2 dice. Isle boss gives +1 Grave Die. | Embers stop gating everything. Dust surplus becomes useful. All banners reachable. | S |
| 3 | **Information layer** | (a) Forge equip preview "Varek: SHIELD4 GUARD2 → ATK7 CLEAVE3 (loses all GUARD faces)". (b) Element wheel icon on the combat screen (tap opens a 6-node diagram) plus "weak to" on **hero** cards. (c) Damage numbers "3 (2+1 ◆)", with no "super effective" on 0 damage. (d) A confirm card for build/star/craft showing cost → effect. | Removes the #1 frustration in the diary ("Too much is unexplained"). | M |
| 4 | **One rule set for both modes** | Shared `PartyState` (max HP from chapel/stars/armour). One quest event bus (kills, twists, rests, carvings count everywhere, unless the text says "on the road"). Isle clock: +1 time phase per 4 Isle fights. Fate overflow becomes a free reroll on the Isle too. | Fixes 4 diary complaints at once (#2, #14, #15, the "dusk forever" note). | M |
| 5 | **Combat input safety** | Twisted dice are pinned (can't be unlocked). A rerolled die that lands on the same face gives +1 Fate ("Fate pities you"). Overkill on attack/blood spills 50% to the next enemy. | The signature mechanic never punishes the player. Big hits never feel wasted. | S |
| 6 | **Road difficulty scales with gear** | Road enemies get +6% HP for each crafted SR and +12% for each SSR equipped (cap +30%). Embers scale the same way, so it's a reward, not a tax. The Bishop gets "Unholy Ward": after any single hit ≥12, he gains 6 shield. | First Bishop takes 5–7 rounds instead of 3. Crafting stays exciting without trivialising the road. | M |
| 7 | **World boss consent and flee** | Bosses fight only when challenged (tap or a `challenge` command), with a lair ring shown on the map and minimap. Flee from round 2: lose 15% party HP, boss heals fully. A "Recommended power" number per country (sum of hero HP + face values), shown in the country banner. | No surprise boss. The player knows when T3 is realistic ("I felt too weak and too poor"). | S |
| 8 | **Staged unlocks plus villager Isle requests** | The town reveals systems in order (§4). Each villager gets 1 Isle request: Tobin "6 grave iron", Hesk "8 ghouls anywhere", Marla "rest at an Isle campfire", Pip "bring a rare mineral". Rewards are dust, dice, pets. | A smooth first hour. The Isle has a purpose from minute 1. Delivers the GDD 2.x plan. | M |
| 9 | **Skill and hero pass** | Last Rite: heal 4, revive at 6 HP, cost 2, charge 5. Vael: either fire element (Lys becomes dark/blood) or faces reskinned to "MIASMA" (water). Run `tools/hero_check.gd` and aim for a trio spread of ±10. | Healer trios stop dominating ("no healer" losses). The element wheel teaches correctly. | S |
| 10 | **Feedback and bug sweep** | All confirmed bugs below, plus result cards for every town action ("Lys ★2: max HP 20 → 22, -40 embers, -2 dust"), plus a GDD clean-up (status header still says 1.0, the roadmap rows 1.1–2.x are duplicated, row 1.0 sits after 2.x). | Trust. Every action states its result. | S |

**Not in 3.0 (on purpose):** new countries, dungeons, co-op. The diary shows the player couldn't yet *use* T3+ ("I felt too weak and too poor"). More width would deepen the problem.

---

## 7. Confirmed bugs (from the v2.2 replay)

Each repro replays `docs/playtests/v2.2/session.txt` with `godot --headless --path . -s tools/play_cli.gd -- docs/playtests/v2.2/session.txt 100000`. The line numbers refer to that output **as of 2.2** (see the caveat at the top).

| ID | Bug | Repro | Real game? |
|---|---|---|---|
| B1 | **Stale reward text** on carvings and loot from the shop, rest and events | Road #1 tile 16: `buy carving` → "Victory! +9 gold." (l.540). Tile 41: `rest carve` → "You pry open a rotten chest: +22 gold. A weapon lies among the bones." (l.1144). Road #2 tile 21: `buy carving`, and tile 30: `rest carve` → "Victory! +29 gold. … The elite drops its arms." | **Yes**: `game_screen.gd:398,418` shows `run.last_reward_text` |
| B2 | **Isle combat doesn't count for requests** | Accept Hesk "Thin the Ghouls" and Marla "Bend Your Luck" → kill ghouls and twist on the Isle → `home`, `talk hesk` = "0/8", `talk marla` = "0/4" (l.2848–2853) | Yes (core) |
| B3 | **Request completes retroactively** | After road #1: `accept tobin` ("Walk the Far Fields: go further than tile 20") → `status` shows `tobin(out, DONE)` before any new journey | Yes (core) |
| B4 | **Max HP differs between modes** | `build chapel` → `road`: Varek 29/29. `build chapel` → `explore`: Varek 28/28 | Yes (core) |
| B5 | **Fate gain at 5/5 lost on the Isle** | Elderglade Thornback fight, round 3: Fate 5, `skill 2` (Loaded Dice "+2 Fate") → Fate 5, rerolls still 2. GDD §4: overflow becomes a free reroll | Yes (core) |
| B6 | **"super effective!" on 0 damage** | l.3019 "Bone Hound hits Brother Aldric for 0 (super effective!) (2 blocked)", l.1805 the same for Varek | Yes (log, plus orange number in `combat_view.gd:367`) |
| B7 | **Element bonus missing once** | First Elderglade fight (Ghoul + Weeping Nun), round 1: Varek ATK 2 (earth) vs Nun (water), no combo, no shield → "Varek hits Weeping Nun for 2 (super effective!)" (l.1680). The current `_damage` formula gives 3. The cause isn't found in today's code, so QA should check whether it's already fixed | Likely |
| B8 | **Move preview shows the wrong step count at forced stops** | Road #2 tile 28: "move 0 = 5 steps -> rest", but the party stops at the campfire on tile 30 (2 steps). The player expected tile 33 (shop). Should read "stops at campfire (tile 30)" | Check `game_screen.gd` roll preview |
| B9 | **Twist auto-lock can be toggled off** | Road #1 Ash Cultist fight: `twist 1 3`, then `lock 1`, then `reroll` → the BLOOD 6 is lost (l.396–418) | Yes (`toggle_lock` allows it). Design fix in Top 10 #5 |
| B10 | **Boss fight starts from `goto` with no consent** | Isle trip 2: `goto 40 76` twice → "BOSS!" (l.2285) | CLI for sure. The real UI may already guard it (`_challenge_boss`): verify |
| B11 | **Docs:** GDD header says version 1.0, roadmap rows duplicated and out of order | `docs/GDD.md` top line and the §12 table | Docs |

**Text-interface only (not game bugs):**
- `buy tonic` twice gives no message. The real UI shows "Sold" and disables the button (`game_screen.gd:441`).
- "Crafted item #1." gives no stats.
- `upgrade` and `build` show no effect.
- `sell`, `grind` say "Done." / "Cannot." with no reason.
- `claim pip` works while he is "away".

The CLI was being improved during this review.

**Reported but not a bug:**
- "Blood pays even when target dead": the blood die retargets to the next living enemy and hits it ("Ash Cultist falls! / Lys (blood magic) hits Ghoul for 6 / Lys pays 2 HP", l.487–489).
- "Rerolls repeat the face": this is plain 1-in-6 probability. The feeling is addressed in Top 10 #5.
