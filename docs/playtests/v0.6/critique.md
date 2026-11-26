# Cursed Dice v0.6: Playtest Panel Critique

**Sources**
- `report.md`: 300 bot runs per style, the 20×20 campaign, hero/party balance from `tools/hero_check.gd`, and the fair pet comparison.
- `transcript_newbie.txt`, `transcript_tactician.txt`, `transcript_berserker.txt` (all seed 7, all with the starter trio).
- Screenshots: `screen_town.png`, `screen_town_summon.png`, `screen_combat.png`.
- Data and design: `data/heroes.json`, `summon.json`, `weapons.json`, `events.json`, `quests.json`, `town.json`, `docs/GDD.md` §11, and our `v0.5/critique.md`.
- The v0.3–v0.5 screenshots (map, events, loot, defeat) are taken as still current.

**Scope of v0.6:** the Summon Roll (Grave Dice, visible rates, pity at 6), 3 new heroes, 3 relics, party selection, Curse levels 0–4, synthesized SFX and drone, and the v0.5 fixes.
**Caveat:** the campaign bots never raise the Curse level, and none of the transcripts uses a summoned hero. So Curse levels and the new heroes are judged only from `hero_check`, the data and the screenshots.

**Short version:** v0.6 fixes almost everything the panel asked for in v0.5, and the gacha is genuinely fair and readable. The game is close to a 1.0 core, with three problems left:
1. **The berserker collapsed from 50% to 32%**, the biggest regression in three versions.
2. **Party choice swings win rate by 46 points**, so the new heroes are not "sidegrades".
3. **It still looks like a spreadsheet on a phone.** No art, and touch targets are tiny.

---

## Fixed since v0.5

| v0.5 complaint | Status in v0.6 | Evidence |
|---|---|---|
| #1 Gates at 21/30 don't stop the party | **Fixed** | Tactician at 19: "moves 4 -> tile 21 (shop). Options: ["shop", "elite"]". Berserker at 20: "moves 4 -> tile 21 (shop). Options: ["shop", "shop"]". Berserker at 29: "moves 1 -> tile 30 (rest). Options: ["rest", "rest"]". The last camp also stops the party: "moves 5 -> tile 41 (rest). Options: ["rest", "rest"]". |
| #2 Meta overshoots the cap | **Partly fixed** | Chapel is +1 HP per level, and Curse levels exist. But the campaign newbie still runs **80–100% from run 2** (base 75%, cap +10–15 → ≤ 85–90%), and the tactician runs 85–100%. Curse level 1 only adds "+12% HP". |
| #3 Carving collapsed into +1 | **Fixed** | New-face and swap carves now appear: "Lys: blank -> SHIELD 3", "Varek: blank -> CLEAVE 2", "Lys: FIRE 2 -> BLOOD 7", "Aldric: GUARD 1 -> ATTACK 3". The cap at 7 holds ("BLOOD 6 -> BLOOD 7", "ATTACK 6 -> ATTACK 7"). The blanks now sit in faces 1–4 (`heroes.json`). |
| #4 The newbie never learns Fate | **UI done, behaviour unproven** | `screen_combat.png` shows "FATE IS FULL - twist a die! (-4)", and the quest is now 3 Twists. But the newbie bot still makes **0.00** Fate rerolls and 0 Twists, and sits at "fate 5" from tile 31 to the boss. The bot can't see a pulse, so this needs a human test. |
| #5 Readability: shields, wasted skills, defeat screen | **Mostly fixed** | Enemy shields now show in the state: "Bone Colossus 17/52hp shield 8", "Ash Cultist 3/13hp shield 3". The Broken Oath hint is in the UI, but the newbie bot still fires "broken_oath (incoming 0…)" three times. The defeat-screen counters have no new screenshot, so they're **unverified**. |
| #6 Last camp is a trap | **Fixed** | "The last campfire warms you (+30% HP)." comes before the choice. The berserker carved at 72% *after* the heal, and won. Boss deaths: newbie 45, tactician 15, berserker 39 (was 34 / 10 / 74). |
| #7 Tactician too comfortable; no forks | **Not fixed** | Tactician at **94%** (target ~90), with 100% in 9 of the 20 campaign runs. Early-third deaths are 0 / 0 / 0 again. The road is still a single snake. |
| #8 Ashfall soulless; thin event pool | **Partly fixed** | There are 14 events, and a hero line at the fire (`screen_town.png`). But that line is Varek's `lore` string verbatim. The "Rat Catcher 40" grind quest is still there. Still no art. |
| 0.6 advice: gacha fair and visible | **Done** | "Rates: Hero 20%, Relic 30%, Embers 50%. Pity: a new hero is guaranteed within 6 rolls (now 3/6)." and "No other currency, ever." The base three win at 75% / 94%. |
| 0.6 advice: per-party balance data | **Done, and it shows a problem** | Party spread is 46–92% (newbie) and 58–100% (tactician). The ±8 rule is badly broken (see #2 below). |
| 0.6 advice: save versioning, mid-combat save | **No evidence** | Nothing in the files shows either one. |

---

## 1. Mint, the newbie (casual, mobile, plays on the bus): **7/10** (was 7)

**What I liked**
- I won, and the safe stops are safe now. I rested at 13 and 15 ("party HP 100%"), the shop at 21 caught me, and the last camp healed me before I chose ("The last campfire warms you (+30% HP)"). Over 300 runs I win **75%**, in a **12 min** session.
- The Summon tab tells me everything in one screen: the price ("3 Grave Dice"), the odds, and "now 3/6" pity. I never feel tricked.
- Carving is easy to read: "blank -> SHIELD 3" means I made something out of nothing.

**What bothered me**
- The combat screen shouts "FATE IS FULL - twist a die! (-4)" **three times**, once under each hero. It never says *which* die is worth twisting, so I still didn't twist: fate 5 from tile 31 to the boss, and 0.00 Fate rerolls per run.
- The face buttons under each die are tiny. In the 1280×720 shot, a chip like "SHIELD3" is about 90×20 px. That's roughly 4 mm tall on a phone, and I'll mis-tap on the bus.
- Half the Summon Rolls give me "Embers" (50%, 20 embers). Spending 3 dice to get 20 embers feels like a blank.
- I lose most at the boss: 45 of my 76 deaths, even though I arrive at **98% HP**. The boss takes 8.1 rounds now (72 HP), and in my win Lys and Aldric both died.

**I would quit because…** the boss eats a run I played well for 10 minutes, and the screen never taught me the one tool (Fate) that would have saved it.

---

## 2. Krit, the tactician (deckbuilders, tactics): **7/10** (was 6)

**What I liked**
- Carving creates builds again. "Lys: FIRE 2 -> BLOOD 7" plus "Varek: BLOOD 5 -> 6 -> 7" gave me a blood pair ("Combo: pair of BLOOD"), and Twists feed it ("twist Varek's die to BLOOD 7").
- Party selection is a real decision on paper: six different face mixes, and Mordecai's "Loaded Dice" creates Fate on purpose.
- The gates fixed my routing. Shop at 21 means a planned "carving, weapon, fate_shard" buy, every run.

**What bothered me**
- **The heroes aren't sidegrades.** My best party (varek, aldric, vael) wins **100%** and my worst (varek, lys, rook) **58%**. Newbie: 92% vs 46%. Aldric alone is 91% vs Lys 79%. The worst parties look like no-healer or double-glass builds, so there's one right answer, not six.
- **Curse levels are a damage sponge.** "+12% HP (+1 damage at 2 and 4)" makes fights longer, not more interesting. My session is already **19 min** at the top of the target, with 57 combat rounds and **86.7 rerolls**. Curse 4 (+48% HP) pushes that past 25 min. Nobody (bots included) has tested it.
- Still 94%, still no forks, still 0 early deaths. Moves remain "[rest, fight]" pairs.
- Swap carves can be downgrades the game lets you make: the newbie did "FIRE 3 -> GUARD 1" and then "GUARD 1 -> BLOOD 7".

**I would quit because…** once I know the best party and Curse is just "more HP", every run is the same solved run, only longer.

---

## 3. Ploy, the berserker (big moments, risk and reward): **5/10** (was 6)

**What I liked**
- When it works it's glorious. The boss fell in 4 rounds to "COMBO! Triple ATTACK - values doubled", then Last Rite ("Lys the Hollow rises from death!"), then a kill at 6/72.
- I won an elite with **one hero standing**: "Varek 2/28hp … Bone Colossus 5/52hp", then "Bone Colossus falls!". That's the story I tell friends.
- The Fate engine finally feeds my style: 7.43 Fate rerolls per run and "Fate bends: +1 reroll (-2 Fate)" three times in the boss fight.

**What bothered me**
- **I win 32% (was 50%)**, and only 45% of my runs reach the boss (was 75%). My deaths moved to normal fights: 95 in fights, 69 in elites, and only 39 at the boss, with 76 in the middle third. Something in 0.6 punishes going big before the boss.
- **Meta doesn't save me.** My campaign is 45% at run 1 and 30% at run 20 (range 15–60%). After 20 runs I'm no better. I earn the fewest embers (47 per run) and the fewest Grave Dice, because the 2-dice victory bonus rarely lands.
- The new events bleed me further. Both the tactician and I take "Sell life (a hero loses 5 max HP) for 50 gold". I walked into the boss with Lys at 15 max HP.
- Weapons by style: Censer of Embers wins 12% for me (25 runs), and Ash Crow 15% (26 runs). The fair pet check still skips my style.

**I would quit because…** I lose two of every three runs in ordinary fights, and twenty runs of town upgrades didn't change that.

---

## 4. Arthit, the dark fantasy fan (atmosphere, story, art): **6/10** (was 5)

**What I liked**
- Ashfall finally speaks: "At the fire, Varek the Oathbroken stares into the embers: 'He swore to protect a king. The king is dead; the oath is not.'"
- The gacha is in-world: "Roll the Bone Dice of the Crossroads", "Relic unlocked: Gambler's Bones. It can now appear on the road." The new heroes have real hooks ("He buried the town twice. The second time, some of them were still breathing.").
- 14 events now, including "The Gravedigger's Bet", "A Lost Child" and "The Burning Library". Sound exists at last, with a drone and stings for combos, Fate and boss phase 2 (GDD §11).

**What bothered me**
- It's still rectangles. All three screenshots are text on dark panels. The summoned hero slots say "??? Not yet summoned", with no silhouette. A summon reveal is a single purple text line. The right third of `screen_combat.png` is an empty panel.
- The fire line is just the lore blurb from `heroes.json`, word for word. In a 20-run campaign I'll see it again and again.
- The 6 heroes never talk to each other or react to their own skills' "dark price". The boss's two lines are still the only scripted drama on the road.
- The SFX are synthesized placeholders (the GDD says they can be replaced at `assets/audio/<name>.ogg`). That's fine for a prototype, thin for a store page.

**I would quit because…** the writing promises a candle-lit, grim world, and the screen shows me a settings menu.

---

## Panel verdict: top 8 changes, ranked by impact

### 1. Berserker regression: risky play dies in ordinary fights
- **Problem:** 0.6 made risk-taking lose again.
- **Evidence:**
  - Win rate 50% → **32%**. Boss reached 75% → 45%.
  - Deaths: fight 95, elite 69, boss 39. Middle third 76.
  - Campaign flat at 15–60% with no upward trend.
  - Likely suspects, from the files:
    - the boss went from 63 to **72 HP** ("The Rotting Bishop 72/72hp");
    - the new HP-cost events ("Sell life … loses 5 max HP");
    - blanks moved into the early faces, so an aggressive roll is more often empty.
- **Suggestion:**
  - Run `hero_check` / `pet_check` for the berserker too.
  - A/B test three changes on the same seeds: boss back to 66 HP; Ossuary at −3 max HP instead of −5; elite heal 25% → 35%.
  - Target: berserker **45–50%** fresh, and the campaign rising by ≥10 points over 20 runs.
- **Effort:** S (data) to M (tests).

### 2. Party spread breaks the "sidegrade" promise
- **Problem:** the new heroes are not sidegrades.
- **Evidence:**
  - Newbie best 92% vs worst 46%; tactician 100% vs 58%.
  - Single heroes: Aldric 91 vs Lys 79 (tactician), Mordecai 61 (newbie).
  - The two worst parties lack Aldric, and one has no heal at all.
- **Suggestion:**
  - Apply the pet rule: every party within **±10 points** of its style average.
  - Give each non-Aldric hero one sustain face. For example, Rook carves "heal 2" and Lys gets "shield 2" in place of a blank.
  - Nerf Aldric's HEAL4 to HEAL3, or raise Last Rite's cost from 6 to 7.
  - Show a soft hint in the Party tab ("No healer: risky").
- **Effort:** M.

### 3. Mobile readability and touch: the 1.0 blocker nobody has tested
- **Problem:** the UI is not yet built for a phone.
- **Evidence:**
  - Face chips are about 90×20 px at 1280×720.
  - The quest text and party help say "click".
  - "FATE IS FULL" appears three times.
  - About a third of the combat screen is an empty right panel.
  - The tactician makes **86.7 rerolls per run**, which means a lot of taps.
- **Suggestion:**
  - Minimum touch target 48 dp, so chips ≥ 64 px tall at 720p. Use the empty right panel for a 2×3 face grid of the *selected* die only.
  - Show the Fate prompt once, above the dice, and highlight the blank die.
  - Change "click" to "tap".
  - Test on one low-end Android device: frame rate, Back button, pausing mid-fight.
- **Effort:** M.

### 4. Fate is still untaught (the newbie never twists)
- **Problem:** the pulsing Twist prompt hasn't changed what the newbie does.
- **Evidence:** newbie Fate rerolls 0.00 and Twists 0. "fate 5" for the whole second half of the run. Boss deaths are 45 of 76.
- **Suggestion:**
  - The first time Fate hits 5, show a one-step guided Twist: highlight the blank die and the best face, with the text "Tap HEAL4 to twist".
  - Make the first Twist of a profile free.
  - Teach the bot the same rule: "twist any blank when fate = 5".
  - Target: newbie ≥ 1 Twist per run, and boss deaths ≤ 35 of 300.
- **Effort:** S.

### 5. Meta still overshoots, and Curse levels are only HP
- **Problem:** the town still makes the game too easy, and Curse levels add length instead of difficulty.
- **Evidence:**
  - Campaign newbie 80–100% from run 2. Tactician 85–100%.
  - Duplicates and 50% Ember rolls pour more embers into the town.
  - Curse is "+12% HP (+1 damage at 2 and 4)", and it's untested by bots.
- **Suggestion:**
  - Cap the town's effect: Fortune Teller only in the first fight of each third.
  - Make each Curse level a **rule** rather than a sponge:
    - L1: elites +1 damage;
    - L2: camps heal 20%;
    - L3: boss phase 2 at 60%;
    - L4: the shop at 21 is no longer a gate.
  - Keep +6% HP per level at most.
  - Run the campaign bot with "raise Curse after a win". Target: tactician 75–85% at Curse 2, 60–70% at Curse 4, session ≤ 22 min.
- **Effort:** M.

### 6. Summon Roll: the Embers result feels like a blank, and the endgame is empty
- **Problem:** half the rolls feel wasted, and the dice lose their purpose once the pool is empty.
- **Evidence:**
  - Embers have a 50% chance at 20 embers, for 3 dice.
  - Grave Dice come in at about 1 + 0.7 + 1.5 ≈ 3.2 per newbie run, so about **one roll per run**.
  - There are only 3 heroes and 3 relics to find, so after roughly 10–15 rolls everything left converts to embers.
  - The report has no "runs to unlock everything" line.
- **Suggestion:**
  - Embers 50% → 30%, and add a 20% "cosmetic / hero line" result (a new fire line or a dice skin).
  - Add a reveal: a dice-roll animation plus a hero portrait or silhouette.
  - Report "runs until all 6 heroes" (target ≤ 12 runs for the newbie).
  - Remove the stale "5★ every 50 / shards" plan from GDD §11.
- **Effort:** S (data and report) to M (reveal).

### 7. Presentation: first art pass and voice before the store page
- **Problem:** the game still has no art, and the heroes have only one line each.
- **Evidence:**
  - All screenshots are text panels. Hero slots read "???".
  - The fire line repeats `heroes.json` lore. The SFX are synthesized.
- **Suggestion:**
  - Minimum art for 1.0: 6 hero portraits, 9 monster sprites plus the boss, a town backdrop, a board-tile icon set, and face icons on the dice.
  - Write 3 fire lines per hero (18 total) and 1 bark per skill.
  - Replace the 8 most-heard SFX with real files (dice roll, hit, combo, Twist, victory, defeat, boss phase 2, summon).
- **Effort:** L (art), S (text).

### 8. Tactician headroom and route choice
- **Problem:** the skilled player has nothing left to beat, and the road has no choices.
- **Evidence:** tactician 94%, 0 early deaths in 900 runs, no forks. Moves are always a pair.
- **Suggestion:**
  - One fork at tile ~26: a risky lane (elite + chest) and a safe lane (camp + event).
  - Let Curse levels (#5) carry the difficulty curve.
- **Effort:** M. Can ship after 1.0 if #5 lands.

---

## Must-have for 1.0 (Android, region 1) vs later

**Must-have in the one remaining round**
1. Berserker back to 45–50%, by A/B testing boss HP, Ossuary and the elite heal (#1).
2. Party spread within ±10, with a sustain face for the weak heroes (#2).
3. Phone UI: 48 dp touch targets, one Fate prompt, "tap" wording, and a device test (#3).
4. A guided first Twist, and a bot that twists (#4).
5. Curse levels as rules, plus a campaign run with Curse raised (#5).
6. A save that survives a phone call: a save at the start of each combat round, a save version number, and a migration test. Nothing in v0.6 shows either one.
7. Minimum art: portraits, enemies, town, tile and face icons. Real files for the 8 key SFX (#7).
8. Housekeeping: the export filter for `data/*.json`, GDD §11 cleaned up, the summon unlock pace in `report.md`, and the "Rat Catcher 40" grind swapped for a deed quest.

**Can wait for 1.x updates**
- Map forks and an early mini-elite (#8).
- Summon cosmetics and dice skins; extra hero banter beyond 3 lines each.
- More events (14 is enough to launch), music beyond the drone, and Thai localization.
- New heroes, region 2, co-op, the Tower of Fate.

**Is the core ready?** Yes. The board, carving, Fate, town and summon loops all work and are fair. 1.0 now needs tuning (berserker, parties, curses), a phone-ready UI and a first coat of paint, not new systems. **Add no new features in this round.**
