# Cursed Dice v0.4: Playtest Panel Critique

Sources: `report.md` (300 bot runs per style), `transcript_newbie.txt`, `transcript_tactician.txt`, `transcript_berserker.txt` (all seed 7, so all three walk the same board), `screen_combat.png`, `screen_loot.png`, `screen_map.png`, `screen_pet.png`, `data/*.json`, `docs/GDD.md` (sections 7–8), and our own `v0.3/critique.md`.
Scope: v0.4 adds weapons, pets, Fate from combos and victories, Fate Twist, CLEAVE, zone scaling, a 42-tile board with a fixed shop (21) and camp (30), no repeated events, movement re-rolls, bigger carve pools, enemy overheal as shield, and a boss death line. There is still no art.

**Short version:** v0.4 adds real decisions. Fate Twist is used, weapons are clear on screen, carving finally varies between runs, and almost no move offers two of the same tile. But the balance has slid away from the targets. The newbie fell from 74% to **62%** (target 65–75), the berserker from 35% to **17%**, and the newbie–tactician gap grew from 16 to **30 points**. Nearly all deaths happen in the late third, after HP has leaked away with no reliable way to recover: the "fixed" shop and camp can be jumped over, and all three seed-7 transcripts skipped both and lost. The newbie still never spends Fate. Pets are lopsided, and weapons overwrite carvings.

**Is the gentle early third a problem?** Not by itself. A safe opening is fine onboarding for a bus player. The problem is that the early third isn't actually safe: it's a **hidden tax**. Nobody dies there (0 of 900 runs), but HP drains away with almost no healing (early `rest` weight is 5), and the bill arrives in the late third. Berserker Lys was at 3/18 by tile 13, and tactician Lys at 8/18 by tile 18. Deaths in the late third: newbie 96 of 115, berserker 176 of 250. A player who dies at tile 32 from damage taken at tile 13 feels punished, not challenged. Keep the early fights gentle, but make HP loss there visible and recoverable (see #1 and #7).

---

## Fixed since v0.3

| v0.3 complaint | Status in v0.4 | Evidence |
|---|---|---|
| #1 Fake movement choices, no forks | **Mostly fixed** (re-roll); **forks not done** | 0 of 23 moves in the transcripts offered the same tile type twice (v0.3: 19 of 39). But `screen_map.png` still shows "Move 1 -> Fight / Move 4 -> Fight". The board is still one snake with no branches. |
| #2 Fate dead (casual) / starved (skilled) | **Half fixed** | Tactician Fate rerolls went from 0.38 to **4.58** per run, plus Twists ("Fate twists Varek's die to GUARD 2 (-4 Fate)"). Berserker: 6.98. The newbie is still at **0.00** and sat on `fate 5` from tile 13 until death. The FATE REROLL button doesn't pulse at 5/5 (`screen_combat.png`). |
| #3 Gold has no sink, elites don't pay | **Partly fixed** | Weapon Rack (40 gold) is in, and elites drop "1 of 2" weapons (berserker: "equips Grave Scythe on Aldric (gain 6.1)"). But the fixed shop at tile 21 was jumped by all three transcripts (19→23, 18→23, 20→25). Shop visits are still 1.1 / 0.6 / 0.2 per run. |
| #4 Carving converges | **Fixed** | Pools now have 6 faces each, cross-role included. Opening carves now differ: "Varek: blank -> BLOOD 5", "Varek: blank -> ATTACK 3", "Aldric: blank -> ATTACK 3", "Lys: blank -> FIRE 3". Pair bonuses and a value cap were not added. |
| #5 Early third can't kill | **Not fixed** (see the verdict above) | Early-third deaths are still 0 of 900. Plague rats are in the early pool and the board is 42 tiles, but sessions are 11 / 16 / 10 min, so the newbie is still under the 12-minute floor. |
| #6 Enemy dead turns | **Mostly fixed** | "Ash Cultist wards Ghoul (+3 shield)" replaces "heals for 0". The Plague Rat has 1 blank, down from 2. The Bishop's phase 2 has no heal face. "X hesitates" still appears in most fights. |
| #7 Readability holes | **Partly fixed** | The Broken Oath log now says "draws every single-target attack". Not fixed: hidden enemy shields. The tactician spent 4 Fate twisting into "hits Weeping Nun for 1 (4 blocked)" while her intent read "Heal 4". Broken Oath is still fired at "incoming 0" (berserker, elite R4). Newbie Oath use is 5.5 per run against the tactician's 2.5. |
| #8 Tone / presentation | **Small step** | A boss death line exists in data ("…Somewhere, a bell stops ringing."), but no transcript reached the boss, so it's unverified. Events don't repeat. There's still no art, still only 10 events, and still no hero-specific lines. |
| 0.4 advice: weapons shouldn't just fill blanks | **Not followed** | `screen_loot.png`: "Give to Lys (replaces BLANK BLANK)". Weapons delete Fate sources. |
| 0.4 advice: keep pet die out of combos | **Followed** | Pup ATK next to Varek ATK makes no pair (newbie tile 4 R1). |
| 0.4 advice: log win rate per weapon/pet | **Done** | It's in `report.md`, and it already reveals problems (#3, #4). Fate by source, unspent gold and triples by type are still missing. |

---

## 1. Mint, the newbie (casual, mobile, plays on the bus): **6/10** (was 7)

**What I liked**
- Choosing a pet is a cute, clear moment: "Something small and loyal watches you from the ditch." The faces and passive fit on one line (`screen_pet.png`).
- The weapon screen tells me exactly what I lose: "Give to Varek (replaces GUARD2 BLANK)" (`screen_loot.png`).
- My moves are real choices now: "Options: [\"event\", \"rest\"]", "[\"chest\", \"elite\"]".

**What bothered me**
- I lose a lot more: **62%**, down from 74%, and 96 of my 115 deaths are in the late third. My run ended at tile 32, when I entered a 3-enemy fight with "Varek 9/28, Lys 4/18, Aldric 4/22". Lys and Varek both fell in round 1.
- I never got to the "fixed" camp or shop. I moved 19 → 23 past the shop and 29 → 32 past the camp. Nothing told me they were there for me.
- I still never use Fate: **0.00** Fate rerolls. I sat at `fate 5` from tile 13 to my death, so every combo Fate after that was wasted.
- Fallen heroes come back at 25% and die again at once: "Lys 2/18" entered the tile 23 fight and "Lys the Hollow falls!" in round 1.

**I would quit because…** I die at tile 32 for damage I took at tile 13, and the game never warned me or gave me a place to heal.

---

## 2. Krit, the tactician (deckbuilders, tactics): **7/10** (was 7)

**What I liked**
- Fate Twist is a real tactical tool: "Fate twists Varek's die to GUARD 2" completed a GUARD pair (+3 and +2 shield to all), and the combo paid back +1 Fate. My Fate actually cycles now (4.58 rerolls per run).
- Carving differs from run to run. In one run I gave Varek "BLOOD 5", which I couldn't do in v0.3, and CLEAVE gives fights with many enemies a different answer.
- Weapons are a lasting team decision, and the faces they bring are readable.

**What bothered me**
- **Weapons erase my carvings.** Weapons replace faces 5–6, and that's exactly where carving puts its "blank -> X". The berserker carved "Aldric: blank -> ATTACK 3", then took the Grave Scythe on Aldric, and the carve was gone. The newbie's "Varek: blank -> ATTACK 3" was overwritten by the Executioner's Axe, which brings a blank back.
- **Pets decide too much.** Candle Moth wins 98% for me, against 83% for Grave Pup. For the newbie, Moth is 79% against 46% for Ash Crow. With only 2 pets offered, the offer can matter more than my play. Also, `screen_pet.png` says Moth "Heals the weakest hero **2**" with HEAL2/SHIELD2, but `pets.json` says 1 and SHIELD1. I don't know which numbers the bots played.
- **Cursed weapons are a trap.** The Thirsting Sword is my worst weapon (79% vs 92% overall), and the newbie's Bone Flail sits at 40%. The −4/−5 max HP price outweighs two BLOOD faces in a game where HP doesn't come back.
- The map is still a line. I died at tile 23 after choosing between "[fight, elite]" and "[fight, event]" on 12/28 HP and never saw a rest tile from tile 9 to 23.

**I would quit because…** the best build is "take Candle Moth and never put a weapon on a carved hero", and that's bookkeeping, not strategy.

---

## 3. Ploy, the berserker (big moments, risk and reward): **4/10** (was 5)

**What I liked**
- Elites finally give a jackpot: "The elite drops its arms." I took the Grave Scythe, and CLEAVE 3 hit three enemies in one swing.
- The triple is still a thrill, and it now feeds Fate: "COMBO! Triple ATTACK - values doubled / The combo feeds your Fate (+1)", which killed an Ash Cultist outright in the elite fight.
- Fate rerolls and Twists give me more gambles: "Fate bends: +1 reroll (-2 Fate)" four times in one run.

**What bothered me**
- **17% wins** (was 35%), and I reach the boss in only 40% of runs. Going big is now suicide, not a gamble.
- My jackpot came too late to matter. I won the Grave Knight with "Varek 5/28, Lys DEAD", then entered the next real fight on "Varek 5/28, Lys 4/18". Both fell in round 1.
- Black Cat wins **8%** for me (123 runs). More rerolls just feed my greed into worse spots. A pet that hurts its main user is a bad pet.
- Crow Feast promised "Something bigger was waiting." and then sent three Plague Rats. The text sold me danger, and the fight was a letdown.

**I would quit because…** every big moment costs HP I can never get back, so the game punishes the exact playstyle it advertises.

---

## 4. Arthit, the dark fantasy fan (atmosphere, story, art): **5/10** (was 5)

**What I liked**
- Weapon names and lines carry the world: "Tower Shield of Dunmere — A fallen city's last wall.", "Oathkeeper — It remembers every broken vow." It's also a nice touch that Oathkeeper is cursed.
- Cursed weapons cost life (max HP), which is the right kind of dark price and a seed for Corruption.
- The Bishop now has a last line in the data: "The Bishop collapses into rot and candle wax. Somewhere, a bell stops ringing."

**What bothered me**
- It's still coloured rectangles: the board, pets and weapons are text boxes (`screen_map.png`, `screen_loot.png`), and the pet has no face.
- Event text and outcome disagree (Crow Feast: "Something bigger…" leads to rats from the early pool at tile 25).
- There are only 10 events. Now that they don't repeat, about two runs' worth of events have been seen after 5 runs.
- The heroes still have no voice. Nobody reacts when Varek takes up "Oathkeeper", a sword that "remembers every broken vow". That's a free story moment, wasted.

**I would quit because…** the words keep promising a grim world, and the screen keeps showing me a spreadsheet.

---

## Panel verdict: top 8 changes, ranked by impact

### 1. Mid/late HP death spiral, and the "fixed" safety tiles can be skipped
- **Problem:** HP leaks from tile 1 with no reliable recovery, so runs collapse in the late third.
- **Evidence:**
  - Newbie 62% (target 65–75), berserker 17%.
  - Late-third deaths: 96 / 21 / 176.
  - All three transcripts jumped the shop at 21 and the camp at 30 and died (tiles 32, 23, 31).
  - Revive at 25% means "Lys 2/18" and "Lys 4/18" both fell in round 1 of the next fight.
- **Suggestion:**
  - Make tiles 21 and 30 **stop tiles**: passing them stops you there, like the forced camp in v0.3.
  - Raise `revive_after_fight_percent` from 25 to **40**.
  - Raise `rest` weight: early 5 → 10, mid 9 → 12.
  - Soften the mid cliff: mid scaling `hp 1.15 → 1.1`, and `damage +1` only from tile 21 onwards.
  - Targets: newbie back to 68–72%, berserker 30%+.
- **Effort:** S (data and one movement rule).

### 2. The newbie still never spends Fate
- **Problem:** the signature mechanic doesn't reach casual players.
- **Evidence:**
  - **0.00** Fate rerolls per newbie run.
  - The newbie held `fate 5` from tile 13 to the end, so combo and victory Fate was wasted at the cap.
  - Ash Crow (+2 Fate) is the newbie's worst pet at 46%.
- **Suggestion:**
  - At 5/5, pulse the Twist row and show "Fate is full — Twist a blank?".
  - Overflow Fate past 5 becomes 1 free reroll per round.
  - First fight of a run: a one-time tooltip pointing at Fate Twist.
  - Target: newbie at least 1.5 Fate spends per run.
- **Effort:** S–M.

### 3. Pet balance: Candle Moth dominates, and two pets hurt their users
- **Problem:** a 2-pet offer at run start decides too much.
- **Evidence:**
  - Moth is best for every style: 79 / 98 / 39%.
  - Ash Crow 46% (newbie), Black Cat **8%** (berserker, 123 runs).
  - `screen_pet.png` (heal 2, SHIELD2) disagrees with `pets.json` (heal 1, SHIELD1).
- **Suggestion:**
  - Confirm which numbers the bots ran, and re-run with **≥100 runs per pet per style**.
  - Keep Moth at heal 1 at most.
  - Ash Crow: +1 Fate per fight, plus "+1 Fate when you Twist".
  - Black Cat: replace one BLANK with ATK2, and make the extra reroll the first one of each round only.
  - Rule: no pet more than ±8 points from the style average.
- **Effort:** S.

### 4. Weapons overwrite carvings and delete blanks; cursed weapons are traps
- **Problem:** two systems fight over faces 5–6, and the cursed price is too high.
- **Evidence:**
  - "Varek: blank -> ATTACK 3" was then overwritten by the Executioner's Axe, which brings a blank back.
  - Aldric's "blank -> ATTACK 3" was overwritten by the Grave Scythe.
  - "Give to Lys (replaces BLANK BLANK)" removes both of her Fate blanks.
  - Thirsting Sword 79% for the tactician (average 92%). Bone Flail 40% for the newbie.
- **Suggestion:**
  - Carving targets faces 1–4 only, and blanks live in slots 1–4.
  - Or, when a weapon covers a carved face, carry the carving over as **+1 to the weapon face**.
  - Cursed max HP: −4/−5 → **−2/−3**, plus "+1 Fate whenever the cursed face rolls" (bad luck as power).
  - Log carvings lost to weapons.
- **Effort:** M.

### 5. Risk doesn't pay: the berserker collapsed to 17%
- **Problem:** elites now drop weapons, but you collect them on a dying party.
- **Evidence:**
  - The berserker reaches the boss in 40% of runs.
  - Elite won on "Varek 5/28, Lys DEAD". The next fight wiped the party in round 1.
  - 60 elite deaths and 121 fight deaths.
- **Suggestion:**
  - Elite victory also heals all heroes **25%**, so the jackpot includes survival.
  - Before an elite or a wounded fight, show a warning: "Lys can die this round (4 HP vs 7 incoming)".
  - Target: berserker 30–40%, more boss wins in fewer rounds.
- **Effort:** S.

### 6. Readability: hidden enemy shields, wasted Oaths, unmarked weapon faces
- **Problem:** players spend resources on information the screen doesn't show.
- **Evidence:**
  - A Twist into "hits Weeping Nun for 1 (4 blocked)" while her intent read "Heal 4".
  - Broken Oath used at "incoming 0" (berserker). Newbie Oath use is 5.5 per run vs the tactician's 2.5.
  - `screen_combat.png`: weapon faces "CLEAVE3 FIRE3" look the same as hero faces, the floating "-13" overlaps, and the pet result sits in a corner.
  - `screen_map.png` still shows "Move 1 -> Fight / Move 4 -> Fight".
- **Suggestion:**
  - Add a shield badge on enemy cards.
  - Dim Broken Oath when there are no single-target attacks incoming.
  - Give weapon faces a gold border.
  - Show the pet die next to the party row.
  - Check that the identical-move re-roll also runs in the UI path.
- **Effort:** S.

### 7. The road is still a line, and the early third is a silent tax
- **Problem:** there's no route planning, and the early game can't teach danger.
- **Evidence:**
  - 0 early-third deaths in 900 runs, but berserker Lys was at 3/18 by tile 13.
  - The tactician never saw a rest tile from tile 9 to 23.
  - No forks. Newbie session is 11 min (target 12–20).
- **Suggestion:**
  - Add **2 forks**, around tiles 10 and 26, each with a risky side (elite + chest) and a safe side (camp + event).
  - Keep early fights gentle (aim for 2–5% of deaths in the early third, not more), but put a guaranteed camp near tile 13.
  - Show HP bars on the map in red under 30%.
- **Effort:** M.

### 8. Tone: no art, text/outcome mismatches, thin event pool, mute heroes
- **Problem:** the writing still carries the whole mood alone, and it now sometimes lies.
- **Evidence:**
  - Crow Feast says "Something bigger was waiting." and sends three Plague Rats (pool `early`, used at tile 25).
  - 10 events. No hero lines. The boss death line is unverified in the transcripts.
- **Suggestion:**
  - Crow Feast pool `early` → `elite` (or the zone pool).
  - Grow to **15 events**, with 3 that name a hero.
  - One line when a hero equips a cursed weapon ("Oathkeeper hums in Varek's grip.").
  - First art pass: 3 hero portraits, 4 pet sprites, tile icons.
- **Effort:** S (text), L (art).

---

## What 0.5 (town hub, meta-progress, quests, save/load) must get right

1. **Do not fix balance with meta-power.** The newbie is at 62% today. Fix #1 first, then tune all targets on a **fresh profile with zero upgrades**. Cap fully upgraded meta at about +10 points newbie win rate. Prefer **sidegrades and unlocks** (new pets, weapons added to the pool, new events, carve-pool faces) over raw HP and damage, or skill stops mattering.
2. **Losing runs must still progress.** Pay meta-currency by distance and deeds (tiles reached, elites killed, Fate spent), not only by wins. This matters most for the berserker style (17% wins). Make each death feel like "I got further" rather than "wasted 10 minutes".
3. **Save/load is a mobile essential, so Mint needs it.** Save at every map tile and at the start of every combat round. Store dice faces (carvings and weapons), the pet, Fate, gold, current and max HP, the seen-events list, and the **RNG seed**, so quit-and-reload can't re-roll a bad fight. Version the save format, because `data/*.json` changes every release.
4. **Use quests as the tutorial.** "Spend 5 Fate in a run", "Win a fight after a Fate Twist", "Carry a cursed weapon to the boss". These teach the systems the newbie never touches (#2) and push build variety (#3, #4) without extra UI.
5. **Keep the town short and grim.** One-tap "Return to the Road", and no more than 30 seconds between runs for a bus player. Give the hub voice (Varek, Lys and Aldric speaking at the fire) and tie the planned Corruption/Church cleanse (GDD §9) to it, so the hub adds atmosphere instead of menus.
6. **Pets and weapons become the unlock layer.** Start with fewer options, unlock more pets and weapons in town, and keep the "1 of 2" offer at run start. First fix the pet spread (#3), or meta will just unlock the dominant pick.
7. **Extend the bot report:** win rate at meta level 0 / 50% / 100%, meta-currency per run by style, runs needed to unlock everything, Fate gained and spent by source, gold unspent at the boss, carvings lost to weapons, and triples per run by type.
8. **Keep the architecture rule.** Save, meta and quest logic goes in `scripts/core/` as plain data, and the town UI only displays it. That keeps it testable and keeps co-op possible later.

**Is the core still strong enough to build on?** Yes. Fate Twist, weapons and cross-role carving made the dice-building richer. But v0.4 traded balance for content: the newbie and the berserker both fell well below target. Fix the HP spiral (#1), Fate for newbies (#2) and pet spread (#3) before building the town, or meta-progression will be used to paper over them.
