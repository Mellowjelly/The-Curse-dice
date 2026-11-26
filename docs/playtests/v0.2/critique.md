# Cursed Dice v0.2: Playtest Panel Critique

Sources: `report.md` (300 bot runs per style), `transcript_newbie.txt`, `transcript_tactician.txt`, `transcript_berserker.txt` (all seed 1), `screen_title.png`, `screen_combat.png`, `screen_help.png`, `data/*.json`, `CLAUDE.md`, `docs/GDD.md`.
Scope: v0.2 is a 3-fight combat demo. We judge the dice combat that exists and whether it can carry the planned map, weapons, pets and town.

**Short version:** the core loop works. Intent, lock/reroll and skills with a price are clear, and the tactician's choices visibly matter. But the demo is too easy for every play style (91–97% clear rate), the first two fights never kill anyone (0 deaths in 900 runs), the boss drags (10–13 rounds), Fate is nearly unused, and one tactic (stacking FIRE burn) carries careless play. With only 3 dice, building your dice doesn't exist yet. 0.3 has to bring it in, or the map will just be padding.

---

## 1. Mint, the newbie (casual, mobile, plays on the bus): **6/10**

**What I liked**
- The combat screen tells me what's going to happen. "Intent: Attack 5 -> Lys" in red and "Intent: Heal 3" in green (`screen_combat.png`) means I know who's in danger without reading a manual.
- How to Play fits on one screen and the rules are short: "2 of the same face = +1 each. 3 of the same face = DOUBLE."
- I won 91% of the time without thinking much, and the log reads like a story: "Ash Cultist is reduced to ash!"

**What bothered me**
- The skill buttons don't say what they do. The screen shows only "Broken Oath - READY!" and "Hollow Flame (2/5)". The effect and the price are in the data (`"Gain 5 shield. All single-target attacks this round hit Varek."`), not on the button. So I fired skills at the wrong time: `uses broken_oath (incoming 0, party missing 6 HP)` in the boss fight, Round 5.
- I never touched Fate: **0.00 Fate rerolls per run**, even though I always had some (`fate 2` for the whole boss fight, `fate 3` at the end). "Bad luck becomes power" never happened to me.
- My healer wasted turns: "Aldric prays, but everyone is unhurt" (twice in my transcript). It felt like I'd done something wrong.
- The boss took **12.6 rounds** on average. That's longer than fights 1 and 2 put together (4.7 + 5.9) and too long for one bus stop.

**I would quit because…** I can't tell what my skills do until I've wasted them, and the boss fight is too long to finish between stops.

---

## 2. Krit, the tactician (deckbuilders, tactics): **5/10**

**What I liked**
- Holding skills is a real decision. I kept Broken Oath at `chg 4/4` from Round 4 to Round 6 and only used it when `Attack 8 -> Lys` was coming at a 7-HP Lys: "hits Varek the Oathbroken for 0 (8 blocked)". That felt good.
- Intent plus reroll plus target choice makes a nice little puzzle each round: double GUARD when two enemies attack ("Combo: pair of GUARD - +1 each", "+3 shield all"), BLOOD 6 to finish a 1-HP cultist.
- Every skill has a price, and it shapes the timing: Hollow Flame costing 3 HP on an 18-HP mage is a real trade-off.

**What bothered me**
- **Skill barely beats luck.** I did 30.1 rerolls per run against the newbie's 11.7 and won 97% against 91%. A 6-point gap for three times the thinking. Every style clears more than 90%, so my decisions don't matter enough.
- **Fights 1 and 2 can't be lost:** 0 deaths in fights 1–2 across all 900 runs, and the party ends at 83–94% HP. All the risk is in the boss.
- **Combos hardly exist with 3 dice.** A triple only works on ATTACK (Varek has 2 attack faces, Lys 1, Aldric 1; FIRE and HEAL each belong to one hero). Pairs are +1 each, which is small. There's no dice-building yet, so there's no build variety at all.
- **Burn stacking is the one strategy that wins without thinking.** The newbie put FIRE on the boss every round, burn went 2→3→4→5→6→7, and about 35 of the boss's 70 HP came from burn ticks. Burn ignores shields, and the help screen just says "FIRE hit + burn".

**I would quit because…** after two runs I'd know that playing well only moves my win rate from 91% to 97%, and there's no build to make me want to play again.

---

## 3. Ploy, the berserker (big moments, risk and reward): **6/10**

**What I liked**
- The triple ATTACK is the best moment in the game: "COMBO! Triple ATTACK - values doubled … Lys hits Bone Hound for 8 … Bone Hound falls!" Two enemies dead in one turn. Against the boss it dealt 18 in one round (6+8+4).
- BLOOD 6 with "Lys pays 2 HP in blood" is exactly the risky button I want to press.
- My style got the most drama: **11 close calls** (won the boss on less than 20% party HP), against the tactician's 2. Win or lose, I had the most exciting runs.

**What bothered me**
- Lots of turns where nothing happens. Bone Hounds have 2 blank faces out of 6, so I got "Bone Hound hesitates / Bone Hound hesitates" in Kennels Round 1, and the boss spends 2 faces out of 6 on HEAL 5 or SHIELD 6.
- My big skill fizzled: "Lys uses Hollow Flame! Lys hits The Rotting Bishop for 0 (4 blocked) / The flame feeds on Lys (-3 HP)". I paid the price and got nothing for it.
- My Fate reroll rolled a blank anyway: "Fate bends: +1 reroll (-3 Fate)" → "Lys rolls nothing... +1 Fate". 0.67 Fate rerolls per run, and one of them was a dud.
- No juice in the screenshots. Dice are flat coloured rectangles ("ATK 2", "FIRE 3"). Nothing on screen shows the triple combo happening except a log line.

**I would quit because…** my best moments live in a text log, and a third of the enemy turns are someone hesitating or healing.

---

## 4. Arthit, the dark fantasy fan (atmosphere, story, art): **4/10**

**What I liked**
- The tagline is excellent: "The gods' dice are broken. Every roll has a price." The red-on-black title with ember particles (`screen_title.png`) sets the mood.
- The log has real voice: "Aldric's faith is paid in blood (-3 HP)", "The flame feeds on Lys", "Varek gains 5 shield and draws every attack to himself".
- The heroes' concepts (an oathbreaker knight, a mage who sold her soul, a priest who lost his faith) and the Rotting Bishop are a strong cast for a grim setting.

**What bothered me**
- There's nothing to look at yet: no hero portraits, monster sprites, chapel or road, only text cards and coloured blocks (`screen_combat.png`). There's no art direction anywhere on screen. (The GDD puts pixel art in 0.3. I'm judging what's here.)
- The prices all feel the same: Hollow Flame −3 HP, Last Rite −3 HP, BLOOD −2 HP. Broken Oath's price ("take the hits for everyone") costs nothing in practice: Varek took "0 (4 blocked)" and "0 (8 blocked)". The heroes' flaws should show in *different kinds* of cost.
- There's no story framing at all. The Rotting Bishop has no entrance and no last words, and "VICTORY!" is the same for a ghoul as for the boss. Last Rite's revive never happened in any transcript, because nobody died.
- The menus use a generic sans-serif and plain buttons, which fights the candle-lit tone.

**I would quit because…** right now it's a well-written combat log with a great tagline. The world isn't on screen yet.

---

## Panel verdict: top 8 changes, ranked by impact

### 1. Difficulty is too low and flat: playing well barely beats playing badly
- **Problem:** every style clears more than 90%, the early fights can't kill you, and good play is barely rewarded.
- **Evidence:** clear rates of 91 / 97 / 94%. 0 deaths in The Hollow Road and Kennels of Bone across 900 runs, with party HP after those fights at 83–94%. Also, the GDD's balance note says naive play wins **58%**, but the newbie bot wins 91%. That gap should be explained before any further tuning.
- **Suggestion:** target newbie **65–75%**, tactician **88–92%**, and make fight 2 a real threat (5–10% of runs dying there). Concretely: add a Ghoul to The Hollow Road (3 enemies), raise Bone Hound HP 11→14, and cut the between-fight heal from +5 to +3 (keep the revive). Re-run the bots after each step.
- **Effort:** S (data only).

### 2. The boss drags and stalls
- **Problem:** the boss is slow, and many of its turns are passive.
- **Evidence:** Chapel of Rot takes 9.8–12.6 rounds against 3.6–5.9 for the other fights. 2 of the boss's 6 faces are passive (HEAL 5, SHIELD 6). The tactician's boss fight had "heals The Rotting Bishop for 5" in back-to-back rounds (R8, R9), and it ended with both hero attacks blocked and burn finishing the kill.
- **Suggestion:** target **7–9 rounds** with a second phase.
  - Replace HEAL 5 with "Rot: sweep 3 + 1 burn on heroes" so every turn threatens something.
  - At 35 HP, the Bishop switches to a nastier die (for example SHIELD 6 → SWEEP 6) with a one-line taunt.
  - HP 70 → 60.
- **Effort:** M (the phase switch needs a small code change plus data).

### 3. Fate is a dead resource
- **Problem:** blanks are almost a quarter of all rolls, but the Fate they give is barely spent.
- **Evidence:** blanks are 22–23% of all rolls. Fate rerolls per run: newbie **0.00**, tactician 0.36, berserker 0.67. The newbie sat on `fate 2–3` for the whole boss fight, and the berserker's one Fate reroll rolled a blank.
- **Suggestion:** make Fate worth spending and easy to read.
  - Reroll costs **2** Fate, not 3.
  - Add a second use: **4 Fate = turn one die to any face of that hero**.
  - Pulse the Fate counter and button when it can be spent.
  - This makes "bad luck becomes power" true, and it gives the map and shop a currency hook later.
- **Effort:** S–M.

### 4. Skills are unreadable and sometimes fizzle
- **Problem:** players can't see what a skill does before using it, and one skill can be wasted entirely.
- **Evidence:** the skill button shows only its name and charge, with no effect or price (`screen_combat.png`). The newbie fired Broken Oath into "incoming 0" twice. Hollow Flame did "0 (4 blocked)" and still cost 3 HP. Last Rite's revive never triggered in the transcripts.
- **Suggestion:**
  - Show the description and price on the button, or in a tooltip on long-press for mobile.
  - Let Hollow Flame **ignore shields**, since it's soul-fire.
  - Give Broken Oath a real price, for example "Varek's die is locked to blank next round".
  - Make Last Rite's heal scale (+1 per fallen ally) so it does more than a 3-HP top-up.
- **Effort:** S (UI text) to M (rule changes plus tests).

### 5. Burn stacks without limit and carries thoughtless play
- **Problem:** spamming FIRE on the boss wins without any thought, and the rule isn't explained anywhere.
- **Evidence:** the newbie's boss burn went 2→3→4→5→6→7 (about 35 of 70 boss HP), just from playing FIRE every round. Burn ignores shields. The help text says only "FIRE hit + burn".
- **Suggestion:** **cap burn at 4**, or have FIRE set burn to max(current, 2) instead of adding to it. Explain the rule in How to Play. Keep burn strong against shield-heavy enemies, but don't let it be the default boss answer.
- **Effort:** S.

### 6. Dead turns on both sides
- **Problem:** many turns, ours and the enemies', do nothing.
- **Evidence:** "Aldric prays, but everyone is unhurt" appears 4 times across the 3 transcripts. Bone Hounds have 2 blank faces out of 6 ("Bone Hound hesitates" twice in one round), and the Ash Cultist has 1.
- **Suggestion:**
  - Overheal becomes shield at a 1:1 ratio.
  - Replace one Bone Hound blank with "Howl: +2 to its next attack", a telegraphed threat instead of a skipped turn.
  - Swap the Cultist's blank for "Ash: 1 burn on target".
- **Effort:** S.

### 7. With 3 dice, dice-building and combos are too thin
- **Problem:** the core idea, that your team *is* your dice, can't be felt yet, and combos are too rare and too small.
- **Evidence:** a triple is only possible on ATTACK (FIRE and HEAL each exist on one hero only). A pair is +1 each. The only "wow" moments in 3 transcripts were triple ATTACK combos.
- **Suggestion:** make face changes the main reward from 0.3 onwards (see below).
  - Make pairs worth more: +2 each, or a pair-specific bonus (pair FIRE = +1 burn, pair HEAL = also heal a second ally).
  - Make a triple blank do something ("Fate surge: +3 Fate").
  - Show a big banner or flash when a combo triggers.
- **Effort:** M.

### 8. Presentation doesn't deliver the tone yet
- **Problem:** the best tone in the game is in the log text and the title, and almost none of it is on the combat screen.
- **Evidence:** flat colour-block dice, no portraits, no hit feedback, the same "VICTORY!" for a ghoul as for the boss, plain buttons (`screen_combat.png`). The strongest atmosphere lives in log lines and the title tagline.
- **Suggestion:** spend the 0.3 art budget on combat first:
  - a dice roll and tumble animation;
  - floating damage numbers;
  - hero and boss portraits;
  - a 1–2 line boss intro and death line;
  - a unique victory text per encounter;
  - a themed font for headers.
- **Effort:** M–L.

---

## What 0.3 (board map, dice movement, events, chests, rest, shop) must get right

1. **Every map reward must change dice faces.** Building your dice is the core of the game, and right now it doesn't exist. Chests, events and the shop should give face swaps (for example "replace a blank with FIRE 3", "upgrade HEAL 2 → HEAL 3"), not just HP or gold. If 0.3 only adds gold and potions, the map is padding around the same fixed 18 faces.
2. **Retune difficulty *before* adding rest and shop.** At a 91% newbie clear rate, rest nodes and potions will push it to about 100%. Fix items 1–2 first, then budget each rest node as roughly "+X% clear rate" in the bot sim.
3. **HP carry-over must matter.** Today the party leaves fights at 83–94% HP, so attrition doesn't exist and a rest node has nothing to fix. Lower the auto-heal between fights and let rest nodes be the main way to recover.
4. **Dice movement needs a decision.** "Roll d6 and walk" is just watching. Use the GDD's "roll 2, pick 1" from the start, and lay out forks so the choice is real: risky fight + chest vs. a safe rest.
5. **Events should sell power at a dark price.** That's the tone, and it fixes Arthit's "the prices all feel the same" problem. For example, "The shrine offers BLOOD 8 on Lys; she loses 4 max HP." Avoid events that are just +HP or −HP.
6. **Give Fate a place on the map.** Let it be spent at shops, events or on movement rerolls, so the 22% blank rate feeds a meaningful economy (and change #3 above pays off).
7. **Keep sessions mobile-sized.** The demo is about 22 rounds of combat. Aim for a full map run of **15–20 minutes**, with save/resume between nodes, even if save files officially come in 0.5.
8. **Extend the bot playtest to the map.** Log which nodes each bot picks, its HP when it reaches the boss, and the faces it ended with. A decent tactician should beat a newbie by **20 or more points** of clear rate. Right now the gap is 6.

**Is the core strong enough to build on?** Yes, with conditions. Intent plus lock/reroll plus skills with a price is a solid, readable base, and the tactician transcript shows real decisions. But fix balance (items 1–3) and readability (item 4) before the map lands. Otherwise 0.3 will stack new systems on a fight you can't lose.
