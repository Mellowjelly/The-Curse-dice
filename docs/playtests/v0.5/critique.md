# Cursed Dice v0.5: Playtest Panel Critique

Sources: `report.md` (300 bot runs per style, plus the 20×20 campaign simulation and the fair pet comparison), `transcript_newbie.txt`, `transcript_tactician.txt`, `transcript_berserker.txt` (all seed 7), `screen_town.png`, `screen_defeat.png`, `data/town.json`, `data/quests.json`, `data/region1.json`, `data/pets.json`, `data/weapons.json`, `data/events.json`, `docs/GDD.md` §10.5, and our own `v0.4/critique.md`. The v0.4 screenshots (map, combat, loot, pet) are taken as still current.
Scope: v0.5 adds the town of Ashfall (Soul Embers, 6 buildings), 10 quests and auto-save on the map. It also ships fixes from the v0.4 critique: gates at 21 and 30, a camp at 13, revive at 40%, a 25% heal after an elite win, Fate overflow turning into free rerolls, carving limited to faces 1–4, softer curses and a pet rebalance.

**Short version:** v0.5 is the biggest jump so far. The newbie is back on target at **73%** (was 62), and the berserker has tripled to **50%** (was 17). Pets are now fair, and every run pays something, even a loss ("+19 Soul Embers" on the defeat screen). Three problems remain:
1. **The headline fix doesn't show up in the transcripts.** `gate_tiles: [21, 30]` is in the data, but none of the three transcripts stops at either tile.
2. **Meta-progress overshoots its own cap.** The campaign newbie reaches 85–95% from run 4 on, and the tactician hits 100%.
3. **Carving has quietly become "+1 to a number".** Blanks now sit in faces 5–6, where carving can't reach them.

---

## Fixed since v0.4

| v0.4 complaint | Status in v0.5 | Evidence |
|---|---|---|
| #1 HP death spiral, skippable shop and camp | **Mostly fixed (numbers). Gates unverified.** | Newbie 62% → **73%**, berserker 17% → **50%**. Revive is 40% and the elite win heals 25%. The camp at 13 is on the board (`fixed_tiles`). **But** all three transcripts walk past 21 and 30 without stopping: newbie "moves 6 -> tile 22" (from 16) and "moves 4 -> tile 32" (from 28); tactician and berserker "moves 3 -> tile 23" (from 20) and "moves 6 -> tile 34" (from 28). |
| #2 Newbie never spends Fate | **Half fixed** | Overflow now pays: "Fate overflows: +1 free reroll next round". But newbie Fate rerolls are still **0.00**, with no Twists. The newbie sat at `fate 5` from tile 22 to the boss. |
| #3 Pet balance | **Fixed** | Fair comparison on the same 150 seeds: newbie 66–76%, tactician 91–97%. Every pet is within about ±5 points of its style's average. (GDD §8 still says Moth heals "every round", but `pets.json` says "after every won fight".) |
| #4 Weapons overwrite carvings; cursed weapons are traps | **Fixed, with a side effect** | Carving now only touches faces 1–4, so weapons no longer erase carvings. Curses are −3/−4 (was −4/−5), and the Thirsting Sword is 91% vs 95% for the tactician, only a mild penalty now. **Side effect:** blanks live in faces 5–6, so every carve in the three transcripts is a "+1" (see #3 below). |
| #5 Risk doesn't pay (berserker 17%) | **Fixed** | Berserker 50%, reaching the boss in 75% of runs (was 40%), with a 5.3-round boss kill. The elite heal shows: the berserker survived a Grave Knight elite at tile 20 and won the run. |
| #6 Readability: hidden enemy shields, wasted Oaths | **Not fixed** | Newbie tile 28: "Weeping Nun wards Weeping Nun (+4 shield)". The next state reads "Weeping Nun 18/18hp (Heal 4)", then "Lys hits Weeping Nun for 0 (3 blocked)". Berserker: "uses broken_oath (incoming 0…)" twice, and "uses hollow_flame (incoming 0, party missing 6 HP)". |
| #7 Line road, silent early tax | **Small step** | A camp was added at 13, but there are still no forks. Early-third deaths are 0 / 0 / 0 again, and the newbie session is still **11 min** (floor is 12). |
| #8 Tone: Crow Feast mismatch, thin events | **Partly fixed** | Crow Feast now uses the `mid` pool: "Something bigger was waiting." leads to Ghoul, Ghoul, Ash Cultist. The boss lines are finally seen in all three transcripts ("Something underneath was never human." / "a bell stops ringing."). Still only 10 events, no hero lines and no art. |
| 0.5 advice: don't fix balance with meta | **Followed for the base game, broken by the campaign** | The base game is fixed without meta (73%). But the campaign newbie runs 85–95% from run 4 onwards (GDD cap: +10–15). |
| 0.5 advice: losing runs must progress | **Fixed** | Embers come from distance, fights and elites (`per_tile 0.4`). Every profile won at least once, and the first win comes on run 1.6 on average. |
| 0.5 advice: save with RNG seed | **Done for the map** | Saves on the map, with the seeded RNG continuing identically. There's no save inside combat, so a phone call mid-boss loses the fight. |
| 0.5 advice: quests as tutorial | **Partly** | "Twist of Fate" and "Bearer of Curses" teach systems. "Rat Catcher (40 rats)" and "Ghoul Hunter (25)" are pure grind. |
| 0.5 advice: unlocks, not raw power | **Not followed** | Chapel (+HP), Fortune (+Fate), Gravesmith (free weapon) and Market (discount) are all raw power. The Kennel is the only sidegrade. |

---

## 1. Mint, the newbie (casual, mobile, plays on the bus): **7/10** (was 6)

**What I liked**
- I won my run and the ending felt earned. I rested twice before the boss, started at full HP, and the Bishop "collapses into rot and candle wax. Somewhere, a bell stops ringing." Over 300 runs I win **73%**, and in the campaign I win the first time on run **1.6** on average.
- Losing still gives me something: "+19 Soul Embers" and a big "Return to Ashfall" button (`screen_defeat.png`). The town says plainly "Your last journey earned 38 Soul Embers. Quest complete: First Steps (+15)" (`screen_town.png`).
- Auto-save on the map is exactly what I need on the bus.

**What bothered me**
- The "safe stops" don't feel safe. I went 16 → 22 straight past the shop and 28 → 32 past the camp, then took an elite at tile 36 that left "Varek 2/28, Lys DEAD".
- I still never touch Fate. I had `fate 5` from tile 22 to the end and **0.00** Fate rerolls. The game converts it for me ("Fate overflows: +1 free reroll"), but I never learn what Fate is.
- The defeat screen contradicts itself: "5 fights and 1 elites won, 0 events, **0 carvings, 0 gold earned**". I get a carving after every win, so which number is lying? The hero panel behind it shows full HP (30/30, 20/20, 24/24) and "Weapon: bare hands".
- After a few runs it gets too easy. The campaign newbie wins 85–95% from run 4. Being carried by +HP isn't the same as feeling smart.

**I would quit because…** after about ten runs I win almost every time without understanding Fate, so there's nothing left to learn or chase.

---

## 2. Krit, the tactician (deckbuilders, tactics): **6/10** (was 7)

**What I liked**
- Fate is my engine: 5.22 Fate rerolls per run, with Twists that set up kills ("twist Varek's die to attack 5", then "attack 6"). It's the best system in the game.
- Weapons and carvings no longer fight each other. The Censer of Embers on Aldric and Rusted Blade on Lys sit beside my carved faces.
- The town has a real choice early: Kennel (70) for 3 pets, or Chapel (90), or saving for Fortune (120).

**What bothered me**
- **Carving is now just +1 stacking.** All my carves are bumps: "Varek: ATTACK 2 -> 3 -> 4 -> 5 -> 6", and "SHIELD 3 -> SHIELD 4". The blanks sit in faces 5–6 (Lys "FIRE2 FIRE3 ATK4 BLOOD6 BLANK BLANK"), so "blank -> BLOOD 5" carves from v0.4 can't happen any more. Builds converge again, which was the v0.3 problem.
- **There's no challenge left.** I win 95% fresh, 100% in 9 of the last 12 campaign runs, and I own all 10 building levels after 20 runs. There's nothing to opt into: no harder road and no curse levels.
- The camp choice is a trap. At tile 41 I "rests: carve (party HP 74%)" and started the boss with "Lys 10/18". She fell in round 4. The berserker carved twice at 53% and walked into the boss with "Lys 1/18".
- Still a single snake. Moves are "[event, fight]" or "[rest, fight]", with no fork to plan a route around.

**I would quit because…** once the town is maxed (~19 runs), every run is the same +1 carving on the same face, and I already win.

---

## 3. Ploy, the berserker (big moments, risk and reward): **6/10** (was 4)

**What I liked**
- Going big finally works: **50%** wins (was 17), with a 5.3-round boss kill when I win. I took the elite at tile 20, won it, and kept going.
- The triple is still the best moment: "COMBO! Triple ATTACK - values doubled". Lys hit for 10 and a Bone Hound died outright.
- The boss finale is dramatic now: I won with "Varek 12/28, Lys DEAD, Aldric DEAD" against "The Rotting Bishop 1/63hp". That's a story I'd tell a friend.

**What bothered me**
- Half my deaths are at the boss (74 of 149). I arrive at 60% party HP and have no way to buy a comeback, because I visit the shop **0.2** times per run.
- My skills still fire into nothing: "uses broken_oath (incoming 0…)" twice, and "uses hollow_flame (incoming 0, party missing 6 HP)".
- Black Cat is my most-picked pet (123 runs) and wins **48%** for me, while Candle Moth wins 83% (18 runs, a small sample). The fair comparison skipped my style.
- Meta helps me least: campaign win rate goes 45% → 55–70%, and I earn the fewest embers (54 per run).

**I would quit because…** after a great elite fight I still lose the run to a boss I can't prepare for, and my skill buttons don't tell me when they're wasted.

---

## 4. Arthit, the dark fantasy fan (atmosphere, story, art): **5/10** (was 5)

**What I liked**
- The writing is strongest at the edges of a run. On defeat: "The Hollow Road claims three more souls. The dice keep rolling without you." On the boss: "tears off his vestments. Something underneath was never human."
- Ashfall has good names: "Ruined Chapel", "Kennel of Strays", "Gravesmith", "Night Market", "Thrice Damned".
- Crow Feast no longer lies: "Something bigger was waiting." now brings a mid-pool fight.

**What bothered me**
- The town is a spreadsheet. `screen_town.png` is two text lists and a button: no fire, no faces, no townsfolk. "Ashfall - the last town before the Hollow Road" deserves one line of mood.
- The heroes are still mute. Nobody speaks in town, and "Varek takes up Tower Shield of Dunmere." is a system line, not a voice.
- There are still only 10 events. In a campaign of 20 runs × ~2 events, I'll see each one about 4 times.
- There's still no art or sound. Every screen is coloured rectangles (`screen_defeat.png` map grid).

**I would quit because…** the game's best sentences arrive only at death and at the boss, and everything in between (including my new home town) is a menu.

---

## Panel verdict: top 8 changes, ranked by impact

### 1. The gates at 21 and 30 don't stop the party (in the bot path, at least)
- **Problem:** the main v0.4 fix isn't visible in play.
- **Evidence:**
  - `region1.json` has `"gate_tiles": [21, 30]`, but all three transcripts pass both without stopping: 16→22, 28→32 (newbie); 20→23, 28→34 (tactician and berserker).
  - Shop visits per run are still 1.2 / 0.5 / 0.2.
  - Boss deaths are 34 (newbie) and 74 (berserker).
- **Suggestion:**
  - Check that the gate rule runs in `run.gd` movement, not only in the UI. Add a test: "from tile 17, a move of 6 ends at 21".
  - Log "stopped at gate" in the transcript.
  - Re-run the report afterwards. The win rates may shift up by a few points, so re-tune after.
- **Effort:** S.

### 2. Meta-progress overshoots its own cap and has no ceiling content
- **Problem:** after about 4 runs, the town makes the game too easy.
- **Evidence:**
  - Campaign newbie: 65 / 75 / 65 for runs 1–3, then 85–95% (GDD §10.5 cap: +10–15).
  - The tactician reaches 100% and owns all 10 levels after 20 runs.
  - All building costs add up to 1,210 embers, against 55–65 per run, so the town is maxed in ~19–22 runs and embers then have no use.
- **Suggestion:**
  - Chapel: +2 → **+1 max HP per level**.
  - Fortune Teller: "+1 Fate in the first fight of each zone", not every fight.
  - Turn the Gravesmith Lv2 and Carver Lv2 into **unlocks** (new weapons in the pool, new carve faces) instead of free power.
  - Add an opt-in **"Curse level" (ascension)** at the town gate: each level adds one rule (e.g. "+1 enemy damage", "camps heal 20%") and **+20% embers**.
  - Target: fully upgraded newbie ≤ 85%, and curse levels exist for the tactician.
- **Effort:** M.

### 3. Carving collapsed into "+1 on the same face"
- **Problem:** limiting carving to faces 1–4 fixed the weapon conflict, but blanks live in 5–6, so carving can no longer *create* faces.
- **Evidence:**
  - Every carve in the three transcripts is a bump.
  - The tactician took Varek ATTACK from 2 to 6 across four carves.
  - The defeat screen shows the blanks in the last slots ("…BLOOD6 BLANK BLANK").
- **Suggestion:**
  - Move one blank per hero into faces 1–4. For example, Lys becomes `FIRE2 FIRE3 ATK4 BLANK | BLOOD6 BLANK`, and Varek and Aldric each get a blank in slot 4, with that face's value folded into a weapon-slot face.
  - Make at least 1 of every 3 carve offers a **new face** ("blank -> X" or "type swap").
  - Cap hero faces at **value 7** (8 for BLOOD).
  - Log carves by kind (new / +1 / swap).
- **Effort:** M.

### 4. The newbie still never learns Fate
- **Problem:** overflow makes Fate silently useful, but the casual player never makes a Fate decision.
- **Evidence:**
  - Newbie Fate rerolls 0.00 and Twists 0.
  - `fate 5` from tile 22 to the boss.
  - The "Twist of Fate" quest (10 Twists) is unreachable for this player.
- **Suggestion:**
  - At 5/5, pulse the Twist row with "Fate is full — twist a blank into any face?".
  - Make the first Twist of a profile free (0 Fate).
  - Change the quest to "Use Fate Twist **3** times" (+25), with a second quest at 10.
  - Target: ≥ 1.5 newbie Fate spends per run.
- **Effort:** S.

### 5. Readability: hidden enemy shields, wasted skills, a self-contradicting defeat screen
- **Problem:** players act on wrong information.
- **Evidence:**
  - "Weeping Nun wards Weeping Nun (+4 shield)" is followed by a state of just "(Heal 4)" and then "hits … for 0 (3 blocked)".
  - Berserker Oath ×2 and Flame ×1 fired at "incoming 0".
  - `screen_defeat.png`: "5 fights and 1 elites won … 0 carvings, 0 gold earned" (5 wins should mean ≥5 carvings and 40+ gold), the hero panel at full HP with base faces and "bare hands", and "1 elites".
- **Suggestion:**
  - Add a shield badge on enemy cards.
  - Dim Broken Oath and Hollow Flame when incoming = 0 and enemies are healthy, or give them a confirm.
  - Fix the run-summary counters and show the party as it fell.
  - Pluralise correctly.
- **Effort:** S.

### 6. The camp choice before the boss is a trap, and boss deaths dominate
- **Problem:** the forced last camp at 40–41 lets you carve instead of heal, and the boss is where runs end.
- **Evidence:**
  - Berserker "rests: carve (party HP 53%)" twice, then started the boss with "Lys 1/18" and she fell in round 2.
  - The tactician carved at 74% and lost Lys in boss round 4.
  - Boss deaths: 34 / 10 / 74, about half of all berserker deaths.
- **Suggestion:**
  - The final camp gives **both** a 30% heal and the choice of carve or second heal.
  - Show "Lys 1/18 — the Bishop hits for 7–11" on the camp screen.
  - Keep the boss at 63 HP.
  - Target: berserker 55%, with boss deaths ≤ 40% of their deaths.
- **Effort:** S.

### 7. The tactician is too comfortable, and the road has no routes
- **Problem:** skill no longer has room to show above the newbie, and the map has no planning.
- **Evidence:**
  - Tactician 95% (target ~90), 100% in the campaign.
  - Early-third deaths 0 / 0 / 0 (900 runs).
  - Newbie session 11 min (floor 12).
  - No forks: moves are always a pair like "[rest, fight]".
- **Suggestion:**
  - Add **2 forks** (around tiles 10 and 26): a risky lane (elite + chest + shop) and a safe lane (camp + event).
  - Add one early elite-lite (e.g. a Bone Hound pair with +2 damage) so 2–5% of deaths happen early.
  - Use curse levels (#2) as the tactician's real difficulty.
- **Effort:** M.

### 8. Ashfall needs a soul; the event pool is too thin for a campaign
- **Problem:** the meta loop multiplies how often players see the same content.
- **Evidence:**
  - `screen_town.png` is two lists and a button.
  - 10 events across a 20-run campaign.
  - No hero lines.
  - The quests include pure grind (40 Plague Rats).
- **Suggestion:**
  - One rotating line per visit from Varek, Lys or Aldric at the fire (3 per hero to start).
  - Grow to **16 events**, 4 of them tied to town buildings.
  - Swap "Rat Catcher 40" for a deed quest ("Win a fight using only 2 heroes").
  - First art pass: town backdrop, 3 portraits, tile icons.
- **Effort:** S (text), L (art).

---

## What 0.6 (Summon Roll gacha, 2–3 new heroes, party of 3, sound hooks) must get right

1. **The gacha must not become meta-power #2.** Fix #2 first. A hero or weapon from a summon should be a **sidegrade**: a different dice shape, not bigger numbers. Duplicates may unlock a cosmetic or an alternate skill, never "+stats per star". Otherwise it stacks with Chapel HP and the game becomes trivial.
2. **Fairness has to be visible.** Show the rates on the summon screen. Show the pity counter ("Guaranteed 5★ in 37 rolls", GDD §11: every 50). Let duplicates convert to shards you can spend on a chosen hero. Story heroes must stay free. The base 3 must be able to win, so check that the bots' fresh-profile win rate with Varek, Lys and Aldric doesn't drop when the new heroes arrive.
3. **Use a separate currency, earned by deeds, not grinding.** Keep Soul Embers for the town. Pay summon currency from quests, first boss kills and curse levels (#2), not from daily logins or long kill counts. Bots should report "runs per summon" and "runs to see every hero" (target: every hero within ~25 runs without spending luck on dupes).
4. **Party-of-3 needs balance data per composition.** Add to `report.md`: win rate by party (every 3-hero combo, ≥100 runs each), and win rate when the team has **no healer** or **no tank**. Rule: no party more than ±8 points from the style average, the same rule that fixed pets. Each new hero needs a distinct face mix and a dark-price skill (CLAUDE.md), and at least one should create blanks or Fate on purpose so Fate builds exist.
5. **Party choice must stay quick on mobile.** Default to the last party, with one tap to "Set out". Keep the newbie's path from town to the first fight under 30 seconds.
6. **Sound hooks go on the big moments first:** triple combo, Fate overflow and Twist, a hero falling or rising, boss phase 2, the boss death line, and the defeat sting. These are the transcript lines players will remember. Add a separate hook for "enemy shield gained", so #5 has an audio tell too.
7. **Version the save.** The roster, shards, pity counter and party choice all have to survive data changes in `data/*.json`. Carry a save version and a migration test. Saving mid-combat (at round start) is still missing for the phone-call case.
8. **Fix #1, #3 and #5 before adding heroes.** New heroes multiply every existing hole: more blank-slot problems (#3), more wasted skill buttons (#5), more ways to walk past a gate that isn't stopping anyone (#1).

**Is the core still strong enough to build on?** Yes, more than ever. Balance is on target for a fresh profile, pets are fair, and losing still pays. The risk for 0.6 is stacking a second power layer (summons) on a town that already overshoots, while carving has gone flat underneath.
