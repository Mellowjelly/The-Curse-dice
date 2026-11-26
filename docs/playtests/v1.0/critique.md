# Cursed Dice v1.0 (Release Candidate, Region 1): Playtest Panel Critique

**Sources**
- `report.md`: 300 bot runs per style, the 20×20 campaign, hero/party balance (`tools/hero_check.gd`), and the fair pet comparison.
- `transcript_newbie.txt`, `transcript_tactician.txt`, `transcript_berserker.txt` (all seed 7, all with the starter trio).
- Screenshots: `screen_title`, `screen_town`, `screen_map`, `screen_event`, `screen_combat`, `screen_boss`, `screen_victory`.
- `docs/GDD.md`, `README.md`, `docs/BUILD_ANDROID.md`, `export_presets.cfg`, `data/*.json` (spot checks), and our `v0.6/critique.md`.

**Scope of 1.0:**
- Balance: boss 66 HP, elite heal 35%, Ossuary −3 max HP, sustain faces for the weaker heroes, slightly tougher early fights.
- Phone UI: "tap" wording, 32 px Twist chips with icons, one "FATE IS FULL" banner, a narrower log.
- Systems: a guided Twist (and a newbie bot that follows it), Curse levels as 4 named rules, and a tile-entry save snapshot (save v2).
- Content and housekeeping: 9 pixel face icons, Rat Catcher 20, summon Embers 35, GDD cleanup, and Android/Windows export presets.

**Caveats**
- No screenshot shows the "FATE IS FULL" banner: combat is at Fate 4/5 and the boss at 0/5. So the one-banner change is **unverified** visually.
- No file shows a test on a real phone.
- The save snapshot is judged from code and tests (`SAVE_VERSION := 2`, `test_tile_snapshot_reload`), not from a transcript.

**Short version:** this is the best version we have played.
- The newbie finally uses Fate. The boss no longer eats good runs, and Curse levels now make the game harder in the campaign.
- Saves are robust, and the export setup is done.
- Three things are still weak:
  - The game still *looks* like a debug UI, apart from the 9 icons.
  - Touch targets are bigger but still below phone size.
  - The newbie is now slightly **too** strong, so the skill gap closed to 10 points.

None of these needs another bot round. All three need real players and a real phone.

---

## Balance against the project targets

| Target (CLAUDE.md / v0.6 critique) | v0.6 | v1.0 | Status |
|---|---|---|---|
| Newbie 65–75% | 75% | **80%** | Over by 5 |
| Tactician ~90% | 94% | **90%** | Hit |
| Gap ≥ 15 points | 19 | **10** | Missed (newbie rose, tactician fell) |
| Session 12–20 min | 12 / 19 | 12 / 18 / 11 | Hit |
| Berserker 45–50% | 32% | **35%** | Missed (see Ploy: mostly bot style) |
| Newbie boss deaths ≤ 35 / 300 | 45 | **28** | Hit |
| Party spread within ±10 of the style average | 46–92 / 58–100 | 60–88 / 70–100 | Better, still about ±15 |
| Tactician 60–70% at Curse 4 (campaign) | untested | Curse 4.0, runs 2–20 at **45–85%** (mostly 55–70%) | Hit |

---

## 1. Mint, the newbie (casual, mobile, plays on the bus): **8/10** (was 7)

**What I liked**
- **The game taught me Fate.** My Fate rerolls went from 0.00 to **1.54 per run**. Twice in my transcript I "follows the tip and twists Aldric's blank die" (to HEAL 4) and "twists Varek's blank die" (to ATTACK 8 at the boss). That boss twist hit for 8 and triggered phase 2. I felt smart without reading a manual.
- **The boss is a climax, not a wall.** I reach it in 90% of runs at 98% HP, and only **28** of my runs die there (was 45). In my win, Lys fell to the sweep, Aldric's Last Rite brought her back ("Lys the Hollow rises from death!"), and she landed the killing blow at 7/66. Then: "The Bishop collapses into rot and candle wax. Somewhere, a bell stops ringing." Perfect bus-stop ending, at **12 min**.
- The words match my thumb now: "tap a die to lock / unlock it", "tap Target", "Twist (-4 Fate): tap a face". The face chips have little icons (sword, flame, shield, cross), so I can read a die without reading text.

**What bothered me**
- **The chips are still small for a phone.** In `screen_combat.png` a Twist chip is about 96×30 px at 1280×720. That's around 3 mm tall in landscape on a typical phone, well below a 48 dp thumb. The Curse "−" and "+" in `screen_town.png` are about 20 px and are the smallest buttons in the game.
- **Text collides.**
  - In `screen_boss.png` the phase-2 line "tears off his vestments… was never human" is drawn over the log panel and the party header, and a "-5" damage number sits on top of it ("w5s never human").
  - In `screen_combat.png`, "-6" overlaps "Varek the Oathbroken".
- The Twist row ("Twist (-4 Fate): tap a face") appears under all three heroes at once. That's fine for me now, but it's three rows of 6 chips, 18 targets, on a bus.
- I can still downgrade a die without a warning: "Lys: FIRE 3 -> GUARD 1", then two fights later "GUARD 1 -> BLOOD 7".

**I would quit because…** I wouldn't, on PC. On my phone I'd quit after the third mis-tap on a 3 mm chip in a boss fight.

---

## 2. Krit, the tactician (deckbuilders, tactics): **7/10** (same)

**What I liked**
- **Curse levels finally have teeth.** My campaign starts at 100%, raises Curse after wins, and settles at **45–85%** with Curse 4.0 after 20 runs. The rules have names and flavour in the town ("III. Cold Fires: camps heal 10% less, the fallen rise with 25% HP"; "IV. The Bishop Wakes: … enrages at 70% HP"). That's the long-term goal I asked for.
- **Builds are still a joy.**
  - Two blood dice: "Varek: BLOOD 6 -> BLOOD 7" and "Lys: FIRE 2 -> BLOOD 7".
  - Shield stacking: "SHIELD 4 -> SHIELD 5", which blocks "Sweep … (5 blocked)".
  - A full shop plan at 21: tonic, carving, weapon, fate_shard.
  - Twisting with intent: "twist Lys's die to attack 8" for the phase-2 push. The boss went down in 7 rounds with one hero dead.
- My style is right on target: **90%** in **18 min**, and single heroes sit at 85–94%. Each hero is fine; it's the trios that drift (below).

**What bothered me**
- **Skill matters less than before.** The newbie gained 5 points and I lost 4, so the gap is **10** (target ≥ 15). A player who never locks dice is only 10 points worse than me.
- **Party spread is narrower but not ±10.** Best "varek, aldric, vael" wins 100% / 88%. Worst "varek, lys, mordecai" wins 70% / 60%. That's 30 and 28 points. The worst trio is the one without Aldric's heals, the same pattern as 0.6.
- Curse I and II are still number bumps ("+15% HP", "+1 damage"). Only III and IV change *how* I play.
- The road is still a snake with no forks. My map decisions are mostly "rerolls movement with Fate (options were bad)" and pairs like "[rest, rest]". I make **83.8 rerolls per run**, which is a lot of taps on a phone.

**I would quit because…** after Curse 4 there's nothing new to plan for: same road, same best trio.

---

## 3. Ploy, the berserker (big moments, risk and reward): **5/10** (same)

**What I liked**
- The highs are still the best in the game. "COMBO! Triple ATTACK - values doubled" hit for 4 + 8 + 6 with Lys at 1/20 HP. When I win, the boss dies in **5.0 rounds**, the fastest of any style.
- The 1.0 changes are in the data: boss 66 HP, `elite_heal_percent: 35`, and the Ossuary "loses 3 max HP". I win **35%** (was 32%), with **0** early deaths.
- The Fate engine loves me: **7.31** Fate rerolls per run, the most of any style.

**What bothered me**
- I'm still at 35%, and only **46%** of my runs reach the boss. Deaths: 94 in fights, 69 in elites, and 88 in the middle third.
- **My campaign goes downhill.** I start at 35% and drop to 0–10% from run 13. Curse rises to 2.9 while I earn the fewest embers (45 per run, 6.8 building levels).
- The pet matters a lot more for me: Grave Pup 44% vs Ash Crow 23%. The fair pet check and the hero check still skip my style.

**Is 35% a game problem or a bot problem?** The panel says **mostly bot style**. The transcript shows the berserker refusing every safety valve:
- At tile 11 it picks "fight" over "rest" (Options: ["fight", "rest"]). At tiles 17 and 18 it picks fights over the shop.
- It walks into the tile-20 elite with **Varek 3/28 and Lys 8/20**, while "shop" was the other option, and dies to one "Sweep 6 -> ALL".
- With Aldric alone at 5/22 HP, it twists his HEAL 4 into ATTACK 3.
- It rests **1.3** times per run (newbie 3.0).
- Once it reaches the boss it wins 35/46 = **76%** of those fights, at 75% party HP. So the boss and elites are fair. The losses come from walking in hurt.

The campaign decline happens because the bot raises Curse after any win, even while it keeps losing. A human would lower it again.

The part that *is* a game problem: a reckless human gets no warning before a suicidal elite, and the risk pays back too little. Elites drop a weapon and one Grave Die, but there's no "glory" reward for winning hurt. That's a 1.1 feature, not a ship blocker.

**I would quit because…** the game lets me walk into an elite at 3 HP without blinking, and then twenty runs of Curse make me feel worse every time.

---

## 4. Arthit, the dark fantasy fan (atmosphere, story, art): **6/10** (same)

**What I liked**
- The words are excellent and there are more of them.
  - The title: "The gods' dice are broken. Every roll has a price."
  - The event card: "A small girl stands in the road, holding a lantern… She has no shadow."
  - The victory card: "The chapel bells fall silent. One shard of the Dice of Fate glows in the ashes."
  - The boss's two lines are still the best moment in the game.
- **First real art.** The 16×16 face icons (sword, flame, blood drop, cross, tower shield, double shield, the empty blank) are readable and on-palette. The title screen's ember particles and red vignette set the mood in one frame.
- The Curse rules read like lore, not settings: "The Hungry Dead", "Sharpened Bones", "Cold Fires", "The Bishop Wakes".

**What bothered me**
- **Apart from the icons, it's still panels and rectangles.**
  - The map is 43 coloured boxes with words ("Fight", "?", "Camp").
  - The heroes and the Bishop have no faces.
  - The three summon slots still say "??? Not yet summoned", with no silhouette.
  - The biggest moment, phase 2, is red text painted over the UI.
- The fire line is still Varek's `lore` string word for word ("He swore to protect a king…"), the same as in 0.6.
- `screen_victory.png` shows "0 events, … 0 gold earned" with full-HP heroes and bare hands. It looks staged, so we couldn't judge a real end-of-run screen. Capture a real one for the store page.
- The SFX are still synthesized (GDD §11). For an Early Access store page that's acceptable; for a full release it isn't.

**I would quit because…** the store screenshots would sell me a spreadsheet, and I'd never download it to read the beautiful lines inside.

---

## Panel verdict: top 8 changes, ranked by impact (for the post-1.0 updates)

### 1. Real-device test and phone-sized touch targets
- **Problem:** we still can't tell whether the game is comfortable on a phone.
- **Evidence:**
  - Twist chips are about 96×30 px at 720p, below the ≥ 64 px (48 dp) target.
  - The Curse ± buttons are about 20 px, and the tabs about 30 px.
  - The tactician makes 83.8 rerolls per run.
  - No file shows a device test.
- **Suggestion:**
  - Show Twist chips only for the *tapped* die, as a 2×3 grid of 64 px chips in the empty space under the enemy panel (`screen_combat.png` has about 60 px free there, and more with one enemy).
  - Curse ± and tabs at ≥ 64 px.
  - Test on one low-end Android phone: Back button, backgrounding mid-fight (the tile snapshot), and frame rate.
- **Effort:** M.

### 2. The newbie is too strong, and the skill gap is only 10
- **Problem:** after the twist tip, careless play is nearly as good as skilled play.
- **Evidence:** newbie 80% (target 65–75), tactician 90%, gap 10. Newbie campaign 80–100% at Curse 0.0. Grave Pup 81% (fair check) and 86% for the newbie.
- **Suggestion:**
  - Grave Pup opening bite 3 → 2.
  - Hold the twist tip until the *second* run of a profile, or make it a one-time tutorial.
  - Target: newbie 72–75%, tactician 88–90%.
  - Offer Curse I to a profile after 3 wins at Curse 0 ("The dead grow hungry. Raise the Curse?").
- **Effort:** S.

### 3. Overlapping text in the biggest moments
- **Problem:** text collides exactly where the drama is.
- **Evidence:**
  - The phase-2 banner runs over the log and the party header.
  - "-5" lands on top of it ("w5s never human").
  - "-6" overlaps "Varek the Oathbroken".
- **Suggestion:**
  - Wrap the banner to the 990 px combat column and pause floaters while it shows (about 1.5 s).
  - Offset damage numbers above the HP bar.
- **Effort:** S.

### 4. Party spread (the "no Aldric" trios)
- **Problem:** heroes are fine alone, but some trios are much weaker.
- **Evidence:** worst "varek, lys, mordecai" 60% / 70% vs best 88% / 100%. Single heroes are within 9 points of each other.
- **Suggestion:**
  - Give Mordecai one HEAL 2 or GUARD 1 face in place of a blank.
  - Show "No healer: risky" on the Party tab.
  - Target: worst trio ≥ 66% (newbie) and ≥ 80% (tactician).
  - Add the berserker to `hero_check` and `pet_check`.
- **Effort:** S–M.

### 5. A safety net and a reward for reckless play
- **Problem:** going big has no warning on the way in and no reward on the way out.
- **Evidence:**
  - The berserker entered an elite at 3/28 + 8/20 HP with the shop as the other option.
  - The berserker campaign falls 35% → 0–10% as Curse rises to 2.9.
  - Boss conversion is 76% once there.
- **Suggestion:**
  - A red warning on Elite move buttons when party HP < 40% ("The dead smell your blood").
  - A "Blood Glory" bonus: win an elite below 30% party HP for +1 Grave Die.
  - Fix the campaign bot to lower Curse after 3 straight losses.
  - Target: berserker 40–45%.
- **Effort:** S (warning, bot), M (bonus).

### 6. The first real art pass
- **Problem:** the screenshots won't sell the game.
- **Evidence:** only the 9 face icons are art. Map tiles are text boxes, there are no portraits, and the summon slots show "???".
- **Suggestion, in order of store-page value:**
  1. 6 hero portraits (64×64) for the combat cards and Party tab.
  2. The Bishop, plus 8 monster sprites.
  3. 7 tile icons (fight, elite, ?, chest, shop, camp, boss).
  4. An Ashfall backdrop.
  5. Replace the 8 most-heard SFX with real files.
- **Effort:** L.

### 7. Voice: fire lines and skill barks
- **Problem:** the heroes barely speak.
- **Evidence:** the town line repeats `heroes.json` lore verbatim. The heroes never react to their own dark prices.
- **Suggestion:** 3 fire lines per hero (18 total) that rotate and reflect the last run ("Lys came back from death again. She did not thank Aldric."), plus 1 short bark per skill.
- **Effort:** S.

### 8. Road forks and depth for veterans
- **Problem:** veterans have nothing new to plan once they reach Curse 4.
- **Evidence:** the road is a single snake. The tactician uses Fate to escape "bad options". Curse I and II are only stat bumps.
- **Suggestion:**
  - One fork at tile ~26: a risky lane (elite + chest) and a safe lane (camp + event).
  - Turn Curse I into a rule, e.g. "the first fight of each third has an extra Plague Rat".
- **Effort:** M.

---

## Must-have list status (v0.6 "must-have for 1.0")

| # | Must-have | Status | Evidence |
|---|---|---|---|
| 1 | Berserker back to 45–50% (boss HP, Ossuary, elite heal A/B) | **Partly** | All three levers are in the data: "The Rotting Bishop 66/66hp", `elite_heal_percent: 35`, Ossuary "loses 3 max HP". The win rate only moved 32 → **35%**. The panel judges the remaining gap as **mostly bot style** (fights over rests and shops; an elite at 3/28 HP; 76% boss conversion). Berserker hero and pet checks are still missing. |
| 2 | Party spread within ±10, sustain faces for weak heroes | **Partly** | Lys now has SHIELD 2 in place of a blank (`screen_town.png`: "FIRE2 FIRE3 BLANK BLOOD6 ATK4 SHIELD2"). Spread shrank 46 → **28** points (newbie) and 42 → **30** (tactician), not to ±10. Worst trio is still the Aldric-less "varek, lys, mordecai". |
| 3 | Phone UI: 48 dp targets, one Fate prompt, "tap", device test | **Partly** | "tap" everywhere: done. Face icons on chips: done. Narrower log (about 230 px): done. Chips are 30–32 px, not ≥ 64 px. Curse ± about 20 px. The single "FATE IS FULL" banner is not shown in any screenshot (unverified). There's no device test evidence, and floating numbers overlap text. |
| 4 | Guided first Twist and a bot that twists | **Done** | Newbie Fate rerolls 0.00 → **1.54**/run; "[NEWBIE] follows the tip and twists Aldric's blank die"; newbie boss deaths 45 → **28**. (A free first Twist wasn't added, and isn't needed.) |
| 5 | Curse levels as rules, campaign with Curse raised | **Done (mostly)** | 4 named rules in the town and in `run.gd` `CURSE_RULES`; III and IV are real rule changes, I and II are still +15% HP / +1 damage. The campaign tactician reaches Curse 4.0 at 45–85%; the berserker reaches 2.9. The newbie bot never raises it (0.0). |
| 6 | Save that survives a phone call, a save version, a migration test | **Done** | `tile_snapshot` is taken "BEFORE entering the tile: reloading re-enters the same tile with the same dice". `SAVE_VERSION := 2` ("v1 saves (0.5-0.6) load fine"); `test_tile_snapshot_reload()` is in the test suite. It isn't proven on a device (backgrounding / OS kill); add that to the device test. |
| 7 | Minimum art (portraits, enemies, town, tile and face icons) and 8 real SFX | **Not done** (1 of 5 art items) | Only the 9 face icons exist (`assets/icons/face_*.png`, generated by `tools/make_icons.py` per the README). No portraits, monsters, town backdrop or tile icons, and the SFX are still synthesized. |
| 8 | Housekeeping: export filter, GDD §11, summon pace in report, Rat Catcher | **Partly** | Export filter: done (`include_filter="data/*.json"` in both presets). Rat Catcher: 40 → **20** (still a grind quest, not a deed). Summon Embers 20 → 35. "Runs to unlock all heroes" is still not in `report.md`. **The GDD is still inconsistent** (see below). |

**GDD contradictions still present** (developer-facing, not player-facing):
- §4 says a Fate reroll costs **3**; §8, the README and the UI say **2** ("FATE REROLL (-2 Fate)").
- The revive value is stated three ways: "+5 HP / revive 5 HP" (§4), "25%" (§10) and "40%" (§10.5).
- §5 lists Lys at **18 HP** with two blanks; the game has 20 HP and SHIELD 2. §5 also lists only 3 heroes.
- The boss HP is **70** in §5 and §6; the game has 66.
- §10 describes a **36**-tile board with **10** events; the game has 42 tiles and 14 events.
- §11 still describes Curse as "+12% HP per level"; the game has 4 rules, I at +15%.
- §10.5 says the game saves "on the map"; the new tile snapshot isn't described.
- The §12 roadmap has two "after 1.0" rows on either side of the 1.0 row, and "pixel art" is listed as after 1.0.

---

## Release verdict: **SHIP 1.0 as Early Access**

Ship to Google Play closed testing, then open Early Access, as "Early Access, Region 1".

**Why it's ready**
- Every core system works and is fair: board, carving, Fate, weapons, pets, town, gacha with pity, Curse, and save.
- Two of the three styles hit their targets. The newbie finally learns the game's key tool, and the boss is a climax rather than a wall.
- The remaining balance issues are a few points each, and the berserker gap is mostly bot style.

**Why it's Early Access and not a full release**
- Apart from the face icons there's no art yet.
- Touch targets are still below phone size.
- No device test is on file.

None of this needs another *bot* round. It needs human players on phones, which is exactly what Early Access is for.

**Do these before uploading (1–2 days, no new features):**
1. Change `package/unique_name` from `com.example.curseddice` (it can't be changed after the first upload; see `BUILD_ANDROID.md` §3).
2. Play one full run on a real low-end Android phone. Check: chips tappable? Back button? Background the app mid-fight and come back (tile snapshot)? Frame rate?
3. Fix the phase-2 banner and damage-number overlaps (#3 above).
4. Take real store screenshots (a real victory screen, a boss fight in phase 2), not the staged `screen_victory.png`.
5. Mark the store page "Early Access: art in progress", and declare in the Play Console that the gacha uses no real money.

---

## First 3 updates after 1.0

### 1.1: "Fit for the thumb" (2–3 weeks, driven by Early Access feedback)
- 64 px touch targets, with the Twist grid shown only for the tapped die; bigger Curse ± and tabs (#1).
- Newbie tuning back into 72–75%, and the skill gap back to ≥ 15: Grave Pup bite 2, a one-time Twist tutorial, a Curse I offer after 3 wins (#2).
- Elite danger warning; berserker in `hero_check` and `pet_check`; the campaign bot lowers Curse after losses (#5).
- Clean up the GDD contradictions; add "runs to unlock all heroes" to the report.

### 1.2: "Faces in the dark" (first art and voice)
- 6 hero portraits, the Bishop and 8 monster sprites, 7 tile icons, an Ashfall backdrop (#6).
- 8 real SFX.
- 18 fire lines and 6 skill barks (#7).
- Summon silhouettes in place of "???", and a short reveal.

### 1.3: "The road forks"
- A map fork at tile ~26 (risk lane / safe lane).
- Curse I as a real rule, and a Curse V for veterans (#8).
- Party balance pass: Mordecai sustain face, "No healer" hint, worst trio ≥ 66% (#4).
- A "Blood Glory" reward for winning hurt (#5).
- **Thai localization** groundwork: move the UI strings out of the scripts into a translation table.

After that: Region 2, Corruption (GDD §9), co-op, and the Tower of Fate.
