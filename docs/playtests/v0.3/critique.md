# Cursed Dice v0.3: Playtest Panel Critique

Sources: `report.md` (300 bot runs per style), `transcript_newbie.txt`, `transcript_tactician.txt`, `transcript_berserker.txt` (all seed 7, so all three walk the same board), `screen_title.png`, `screen_map.png`, `screen_event.png`, `screen_reward.png`, `screen_combat.png`, `data/*.json`, `docs/GDD.md` (section 10), and our own `v0.2/critique.md`.
Scope: v0.3 is the first full run: a 36-tile board, events, shop, camps, carving after every fight, 4 new monsters and a two-phase boss. There is still no art. The dice roll animation can't be judged from still screenshots, so we don't score it.

**Short version:** this is the first version that feels like a game and not a combat demo. Balance now hits the targets (newbie 74%, tactician 90%, a 16-point gap), the boss is shorter and has a second phase, and carving after every fight finally makes "your dice are your team" real. What holds it back: about half of the movement choices are fake (both dice land on the same tile type), Fate is still unused by casual players, gold has almost nothing to buy, carving keeps producing the same dice, and the first third of the board can't kill anyone.

---

## Fixed since v0.2

| v0.2 complaint | Status in v0.3 | Evidence |
|---|---|---|
| #1 Too easy, skill barely beats luck | **Fixed** | Newbie 74% (target 65–75), tactician 90% (target ~90), gap 16 points (target ≥ 15). In v0.2 it was 91 / 97, a 6-point gap. |
| #2 Boss drags | **Fixed** (mostly) | Boss length when won: 9.0 / 8.5 / 6.7 rounds (was 9.8–12.6). HP is 60, with a phase 2 at 50% and a taunt line. Phase 2 still has a passive `heal 6` face, though ("The Rotting Bishop heals The Rotting Bishop for 6", newbie R6). |
| #3 Fate is dead | **Not fixed** | The reroll now costs 2, but the newbie still makes **0.00 Fate rerolls per run** and sat on `fate 4` for the entire boss fight. The tactician makes 0.38. |
| #4 Skills unreadable / fizzle | **Fixed** | The description and price are on each skill card (`screen_combat.png`). Hollow Flame now ignores shields. Broken Oath now costs 2 HP. Last Rite's revive fires on screen ("Varek the Oathbroken rises from death!"). |
| #5 Burn stacks forever | **Fixed** | Burn caps at 4: the newbie's boss burn ran 2→3→4, then fell back. |
| #6 Dead turns | **Half fixed** | Overheal now becomes shield ("Aldric's prayer wards Varek (+4 shield)"), so the "prays, but everyone is unhurt" line is gone. Enemy dead turns remain: "Ash Cultist heals Ghoul for 0", "Weeping Nun heals Weeping Nun for 0", and Plague Rats with 2 blank faces out of 6. |
| #7 Combos too thin | **Not fixed** | Pairs are still +1. Triple ATTACK is still the only big moment, and it ended both winning boss fights. |
| #8 Presentation | **Partly fixed** | Floating damage numbers are in (`-2`, `-5` in `screen_combat.png`). The boss has a phase line. There are still no portraits or art, and "VICTORY!" is the same for rats and the boss. |
| 0.3 advice: every map reward should change faces | **Mostly** | Carving after every fight, carving events, and the Bone Carver in the shop. Chests are still mostly gold. |
| 0.3 advice: HP carry-over must matter | **Fixed** | There's no auto-heal any more. Party HP at the boss is 87 / 76 / 52%, and camps now carry real weight. |
| 0.3 advice: dice movement needs a decision | **Half** | "Roll 2, pick 1" is in, but 19 of the 39 move choices in the transcripts offered the same tile type twice. |
| 0.3 advice: events sell power at a dark price | **Fixed** | Max HP for a carving (Cracked Shrine), life for gold (Ossuary Merchant), HP for Fate (Drowned Bell). |
| 0.3 advice: sessions 15–20 min | **Short** | 11 / 13 / 10 min, under the 12–20 target for two of the three styles. |

---

## 1. Mint, the newbie (casual, mobile, plays on the bus): **7/10** (was 6)

**What I liked**
- Now I can read my skills before I press them: "Gain 5 shield. Every single-target attack this round hits Varek. Costs Varek 2 HP." is right under the button (`screen_combat.png`).
- Picking a move is easy. "Move 6 -> Fight / Move 4 -> Fight" shows where I'll land before I commit (`screen_map.png`). Events spell out their price ("50%: a hero loses 8 HP").
- I win about 3 runs out of 4, and a run is 11 minutes, which fits a bus ride. Two camps in a row before the boss let me walk in at full HP (`Varek 28/28, Lys 18/18, Aldric 22/22`).

**What bothered me**
- I still never use Fate. I had `fate 4` for all 9 rounds of the boss fight, and the report says I make **0.00 Fate rerolls per run**. Nothing tells me *when* spending it is a good idea.
- Half my map "choices" aren't choices. The screenshot itself shows "Move 6 -> Fight / Move 4 -> Fight", and my transcript has `["fight","fight"]`, `["rest","rest"]` and `["chest","chest"]`.
- Some attacks hit for 0 and I don't know why: "Varek hits Weeping Nun for 0 (3 blocked)". The enemy card showed "Heal 4", not a shield. The shield from last round is still there, and the screen doesn't show it.
- The text is tiny for a phone: face lists like "Faces: ATK2 | ATK3 | SHIELD3 | SHIELD4 | GUARD2 | -" and the skill descriptions are small grey text.

**I would quit because…** the game keeps telling me Fate matters, but I never find out how to use it, so the "bad luck is power" hook never reaches me.

---

## 2. Krit, the tactician (deckbuilders, tactics): **7/10** (was 5)

**What I liked**
- Skill now matters: a **16-point** gap (90 vs 74%). I earn 8.8 carvings per run against the newbie's 5.3 because I take more fights and elites.
- The camp is a real decision. At 62% HP before the boss, I carved instead of healing ("Aldric: ATTACK 4 -> ATTACK 5"), and that ATTACK 5 helped the triple that killed the Bishop: "Aldric hits The Rotting Bishop for 10".
- Events with lasting prices give me runs that differ. I took the Cracked Shrine twice, and my party went from 28/18/22 to 24/14/18 max HP for two carvings.

**What bothered me**
- **Carving is shallow.** Each hero has only 3 carve faces (`carve_pool` in `heroes.json`), and there are no new face types. All three bots carved "Varek: blank -> SHIELD 3" and "Lys: blank -> BLOOD 7" first, and most later picks are just "+1". By the late game every Lys is BLOOD 7/8 with Aldric healing her every round. My transcript has Lys casting BLOOD in 17 of the 31 rounds she acted in.
- **The map is a straight line with no forks** (`screen_map.png`), so the only route decision is the 2-dice pick, and in 19 of 39 transcript moves both options were the same tile type.
- **Gold has nowhere to go.** I earn 121 gold per run but land on a shop only 0.5 times. Elites pay 22–30 gold, which doesn't make them worth the risk if I can't spend it.
- **Fate is starved for me.** Carving removes blanks (blank rate drops to 7%), and I sat at `fate 1` from tile 8 to the end of the run. A resource that good play removes isn't a resource.

**I would quit because…** after about five runs every dice set ends up the same (BLOOD Lys, SHIELD Varek, +1s everywhere), and I can't steer the map toward the build I want.

---

## 3. Ploy, the berserker (big moments, risk and reward): **5/10** (was 6)

**What I liked**
- The triple ATTACK is still a jackpot, and now there's a number on screen: "COMBO! Triple ATTACK - values doubled … Ash Cultist falls!" in round 1 of a 3-enemy fight.
- Death and revival make real swings: "Varek the Oathbroken falls!" against the Grave Knight, then "Varek the Oathbroken rises from death!" from Last Rite two rounds later.
- Events are gambles I like: "Roll it. (50%: carve a die and +2 Fate. 50%: a hero loses 8 HP.)"

**What bothered me**
- **Risk isn't rewarded, it's just punished.** My style wins **35%**, reaches the boss in 71% of runs, and arrives at 52% HP. I take as many elites as the tactician (1.1 per run) but get gold I can't spend: shop 0.2 per run.
- My run ended in the boss's first round. I picked carve at the last camp on 38% HP, and "The Rotting Bishop sweeps the whole party! … Lys the Hollow falls!" happened at R1 with Lys on 3 HP. The game gave me no warning that this was suicide.
- Broken Oath still gets wasted: I used it at "incoming 0" twice. The log says "draws every attack to himself", but the tactician used it into a Sweep 6 and Lys and Aldric still took 4 each. The button text ("single-target") and the log line disagree.
- I paid 20 gold at The Confessor for "all heal 10" and got "Varek heals 1 HP. Lys heals 2 HP. Aldric heals 2 HP." Nothing told me I was nearly full.

**I would quit because…** going big only leads to losing big. There's no jackpot for winning an elite, just more gold for a shop I never see.

---

## 4. Arthit, the dark fantasy fan (atmosphere, story, art): **5/10** (was 4)

**What I liked**
- The event writing is the best thing in the build: "A smiling man in a coat of finger bones. 'I buy what you won't miss.'", "A priest without a face sits in a ruined booth… The church accepts donations."
- The prices are finally different in kind: max HP (Cracked Shrine, Ossuary Merchant), HP for Fate (Drowned Bell), gold for mercy (Wounded Knight). That fixes my v0.2 complaint that every cost was "−3 HP".
- The boss gets a moment: "!! The Rotting Bishop tears off his vestments. Something underneath was never human."

**What bothered me**
- It's still all coloured boxes: the board is 36 rectangles labelled "Fight", "?", "Camp" (`screen_map.png`), and the event modal has no illustration (`screen_event.png`). The title screen is unchanged from v0.2.
- The heroes have no voice in the journey. No event mentions Varek's oath, Lys's soul or Aldric's lost faith, and camps are one line: "The party rests by the fire."
- Events repeat inside a single run. The tactician got the Cracked Shrine of Fate at tile 26 and again at tile 34. With only 10 events, at about 2 per run, repeats break the spell quickly.
- The boss dies to "VICTORY!", the same as a Plague Rat. There's no last word and no ending.

**I would quit because…** the writing promises a grim world, but the screen still shows a spreadsheet of coloured tiles.

---

## Panel verdict: top 8 changes, ranked by impact

### 1. Movement choices are often fake, and the road has no forks
- **Problem:** "Roll 2, pick 1" is the only route decision, and about half the time both options are the same.
- **Evidence:** 19 of 39 moves across the three transcripts offered the same tile type twice (`["fight","fight"]`, `["rest","rest"]`, `["chest","chest"]`). `screen_map.png` shows "Move 6 -> Fight / Move 4 -> Fight". The board is a single snake with no branches.
- **Suggestion:**
  - If both dice point at the same tile type, automatically reroll one die once (free).
  - Add **2 forks** to the 36-tile board (around tiles 10 and 24), each a 4–6 tile side path, so one side is risky (elite + chest) and the other safe (camp + event).
  - Show the next 6 tiles' types highlighted when picking.
  - Target: fewer than 15% of moves with identical options.
- **Effort:** S for the reroll, M for the forks.

### 2. Fate is still dead for casual players and starved for skilled ones
- **Problem:** the signature resource is still unused, and good play removes its only source.
- **Evidence:** newbie **0.00** Fate rerolls per run, sitting on `fate 4` for the whole boss fight. Tactician 0.38 rerolls, stuck at `fate 1` from tile 8 to the end of the run. Carving removes blanks, so the blank rate falls from 15% (newbie) to 7% (tactician).
- **Suggestion:**
  - Add a second Fate source that doesn't need blanks: **+1 Fate per combo** or **+1 Fate per fight won**.
  - Add the v0.2 idea of **4 Fate = set one die to any of its faces**.
  - Pulse the FATE REROLL button whenever Fate ≥ 2 and a die shows blank or would miss a lethal block.
  - Target: newbie at least 1.5 Fate spends per run, tactician at least 2.
- **Effort:** S–M.

### 3. Gold has no sink, so risk (elites) doesn't pay
- **Problem:** the reward for risky play is a currency you almost never get to spend.
- **Evidence:** 94–121 gold earned per run against 0.2–0.7 shop visits per run. Berserker: 1.1 elites per run, 35% wins. Elite gold is 22–30.
- **Suggestion:**
  - Make one shop **forced**, like the last camp: a mid-board Bone Market at about tile 18.
  - Let camps also sell one Bone Carver for 35 gold.
  - Make elites drop a **rare carving** (from a 4th, stronger pool entry per hero) instead of only gold. That gives the berserker a jackpot.
  - Target: average gold left unspent at the boss under 30.
- **Effort:** S.

### 4. Carving converges: every run builds the same dice
- **Problem:** dice-building is now real, but it's narrow.
- **Evidence:** only 3 `carve_pool` faces per hero. All three runs opened with "Varek: blank -> SHIELD 3" and "Lys: blank -> BLOOD 7". Late carvings are mostly "+1". The BLOOD-plus-Aldric-heal loop carries fights: tactician Lys casts BLOOD in 17 of 31 rounds, and BLOOD never kills ("Lys pays 1 HP in blood" at 2 HP).
- **Suggestion:**
  - Grow `carve_pool` to **5–6 per hero**, including **cross-role faces** so new pairs and triples exist: FIRE on Varek, GUARD on Lys, BLOOD on Aldric.
  - Give pairs a type bonus: pair FIRE = +1 burn, pair HEAL = splash heal 2, pair BLOOD = cost refunded.
  - Cap any single face value at 8 from carving.
- **Effort:** M.

### 5. The first third of the board can't kill you, and the boss is the whole difficulty
- **Problem:** the early game is still risk-free, and the session is a bit short.
- **Evidence:** deaths in the early third: **0** across 900 runs. The boss accounts for 38 of 77 newbie losses, 27 of 31 tactician losses and 108 of 194 berserker losses. Sessions run 10–13 min against a target of 12–20.
- **Suggestion:**
  - Change the early pool `["ghoul"]` to `["ghoul","plague_rat"]`.
  - Allow a 5% elite weight from tile 8 onwards.
  - Aim for 3–6% of newbie deaths in the early third.
  - Grow the board to about 42 tiles (with the forks from #1) to reach 13–15 min.
  - Re-run the bots after each change so the newbie stays at 65–75%.
- **Effort:** S (data).

### 6. Enemy dead turns, including the boss in phase 2
- **Problem:** many enemy turns do nothing, which drains tension.
- **Evidence:** "Ash Cultist heals Ghoul for 0", "Ash Cultist heals Bone Hound for 0", "Weeping Nun heals Weeping Nun for 0". Plague Rats have 2 blanks out of 6 ("Plague Rat hesitates / Plague Rat hesitates"). The phase-2 Bishop has a passive `heal 6`.
- **Suggestion:**
  - Enemy HEAL with no wounded ally becomes shield of the same value. The heroes already have this rule, so mirror it.
  - Replace one Plague Rat blank with "Plague: 1 burn".
  - In phase 2, replace the Bishop's `heal 6` with "Rot: sweep 3 + 1 burn on all heroes".
- **Effort:** S.

### 7. Readability holes: hidden enemy shields, misleading Broken Oath log, no danger warnings
- **Problem:** players lose damage and HP to information the screen doesn't show.
- **Evidence:**
  - "Varek hits Weeping Nun for 0 (3 blocked)" while her intent said "Heal 4". Last round's shield carried over, and the enemy card and state line don't show shield.
  - The Broken Oath log says "draws every attack to himself", but sweeps still hit everyone (tactician boss R5).
  - Broken Oath is used at "incoming 0" (berserker, twice). The newbie uses it 6.0 times per run against the tactician's 1.9.
  - The Confessor healed 5 total HP for 20 gold.
  - The berserker carved at 38% HP and lost Lys (3 HP) in boss round 1.
- **Suggestion:**
  - Show an enemy shield badge on each enemy card.
  - Change the log line to "draws every single-target attack".
  - Dim the skill card with "(no attacks to draw)" when nothing single-target is incoming.
  - In events, show the real value ("heals 5 total").
  - At the forced camp, warn when any hero is under the boss's smallest sweep (4).
- **Effort:** S.

### 8. Tone isn't on screen: art, hero voice, event variety, boss ending
- **Problem:** the writing is strong, but none of it is visual, and the content repeats.
- **Evidence:** board and events are plain boxes (`screen_map.png`, `screen_event.png`). The same event appeared twice in one run (Cracked Shrine, tactician). There are no hero-specific lines. The boss ends on a generic "VICTORY!".
- **Suggestion:**
  - Allow no repeat events within a run, and grow to 15 events, with 3 that name a hero ("Varek's old order hails him…").
  - Add a 2-line boss death text and a run-end screen with the final dice.
  - The first art pass should cover 3 hero portraits, the Bishop in both phases, and tile icons instead of words.
- **Effort:** S for text, L for art.

---

## What 0.4 (weapons and pets) must get right

1. **Weapons must not just "replace a blank".** Carving already eats blanks (7–8% blank rate for skilled play), and blanks are the only Fate source. If weapons also fill blanks, Fate dies completely. Make each weapon replace a **specific non-blank face** (for example "Ember Blade: ATK2 → FIRE 4"), or bring a **cursed face** that acts as a blank-plus-price. That's a natural first step toward Corruption (GDD §9).
2. **Use weapons to open new combos.** Today only triple ATTACK is a realistic jackpot. Each weapon should put a face type on a hero who lacks it (FIRE on Varek, HEAL on Lys), so that pairs and triples of FIRE, GUARD and BLOOD become possible. The bots should report **triples per run by type**.
3. **The pet d4 is a 4th die, and it changes combo math.** Four dice make pairs and triples much more common, and triple ATTACK will snowball. Either keep the pet die out of combos, or give it its own types (Crow: "peek", Wolf: "+1 ATK to a hero"), and re-run the sim. Budget: the newbie must stay at **65–75%** and the tactician at **≈90%** with a weapon and a pet equipped.
4. **Power needs a price, and both need a source.** Sell weapons in the Bone Market and drop them from elites. That fixes gold (#3) and the berserker's missing jackpot in one step. Cursed weapons should cost max HP or add a self-harm face, matching the tone the events already set.
5. **Watch the dominant build.** The BLOOD-and-heal loop is already the default. No weapon should raise BLOOD values on Lys or make BLOOD cheaper. Log the win rate per weapon and per pet. Anything above +8 points of win rate over the average gets nerfed before release.
6. **Keep the combat screen readable on a phone.** The combat screen already holds 3 hero cards, face lists, skill text and a log in small grey type. A pet die and weapon-changed faces need their own clear slot. Mark weapon faces (an icon or border) in the face list, and show the pet's passive as one line under its die.
7. **Extend the bot report:** Fate gained and spent by source, gold left unspent at the boss, identical-option move rate, triples per run by type, enemy dead turns per fight, and win rate per weapon and pet.

**Is the core strong enough to build on?** Yes. v0.3 met the balance targets and made dice-building real. Before stacking weapons and pets on top, fix the three things that make choices fake: identical moves (#1), dead Fate (#2) and dead gold (#3). Otherwise 0.4 adds power without adding decisions.
