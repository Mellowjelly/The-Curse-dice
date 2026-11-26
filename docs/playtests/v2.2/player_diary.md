# Cursed Dice v2.2 - Player Diary

Session file: `docs/playtests/v2.2/session.txt` (~600 commands incl. every lock/reroll, ~100 comment lines).
What I did: town + 4 villagers, 2 full Hollow Road journeys (both won), 3 trips to the Cursed Isle
(Ashfall Vale, Elderglade, Marshes of Veyl), 3 world bosses (1 win, 2 losses), crafting x4, summons x4, 2 star upgrades.

## 1. Session log

- **Town start.** `help`, `status`, talked to everyone. Tobin/Marla/Pip each had a road request; Hesk "away". Accepted all three because they all fit one road run. -> Felt like a cosy start, clear goals.
- **`recipes`** dumped 20 recipes at once with material names I'd never seen. -> A bit of a wall, but it told me "go find grave_iron + ashwood".
- **Road #1, pet pick.** Black Cat (+1 reroll). Rolled two movement dice, chose rest over an empty-pocket shop. -> Nice small decision each step.
- **First fight (3 Plague Rats).** Learned lock/reroll; Lys rolled shield 2 three rerolls in a row. Pair of ATTACK = +1 each. -> Simple, readable.
- **Fight 2: TRIPLE ATTACK** (spent 2 Fate on an extra reroll to get it) wiped three rats in one turn, each die auto-retargeting after a kill. -> Best moment of the early game. Felt smart.
- **Twist disaster.** Spent 4 Fate to twist Lys to BLOOD 6, then typed `lock 1` (thinking I was locking it). Twist had already locked it; `lock` is a toggle; my reroll threw the 4-Fate face away. -> Felt cheated by the interface, not the game.
- **Events.** Weeping Statue (took Fate), Drowned Bell (refused, Fate full), **Hanged Man's Purse** ("his fingers twitch") -> took the purse -> ambush. Loved it, great writing.
- **Shop.** Bought a carving to kill Aldric's blank, a tonic. A second tonic silently did nothing (no message).
- **Executioner's Axe (attack8/blank)** from a chest on Varek -> next fights he rolled attack 8 into a natural triple: 16 damage. Weapons visibly reshape the die. -> This is the core fantasy and it works.
- **Boss: Rotting Bishop** died in 3 rounds (66 HP) with triple attacks + twist. Mid-fight line "tears off his vestments. Something underneath was never human." -> Atmospheric, but the fight was too easy.
- **Back in town.** +187 embers, +8 Grave Dice. Claimed 3 rewards (star dust, pets). Tobin's next quest ("go past tile 20") was instantly DONE. Summoned: Sister Vael (new hero), then +35 embers (dupe/fallback). Built smithy + chapel blind (no descriptions).
- **Isle trip 1.** Gathered ashwood/grave iron/an Ember Shard (RARE) by `goto` + `gather`. Fought a dire wolf for pelts. World fights use your BASE dice (road carvings gone) and only 2 rerolls -> fights feel much weaker and slower. A ghoul+nun fight took 6 rounds for 8 embers.
- **Crafted iron hatchet**, "Crafted item #1." No stats shown; only saw its faces (attack4/attack3) once in combat.
- **Upgraded Lys** to 2 stars: silently cost 40 embers + 2 dust, gave +2 max HP (I only noticed later).
- **Ashen Alpha boss** (65 HP): a tense 6-round fight, used every skill, won. Got the **Alpha Fang**! -> Great "hunt the beast for its part" loop.
- **Crafting the Alpha Fang Blade:** 59 embers, need 60. Sold a boar hide for 2. Crafted it: attack7 + cleave3 but it overwrote Varek's shield4/guard2 - he stopped being a tank.
- **Marshes:** `goto 40 76` (country "centre") walked me straight into **The Bog Mother boss (92 HP)** with no warning and no flee. Lost with her on 11 HP. Defeat just sent me to the gate with half HP and my bag. -> Forgiving, but the surprise boss annoyed me.
- **Marshes again (edges):** serpents, bog copper, bogwood, a Drowned Bell Bronze (RARE). Fire hero Lys gets wrecked by water enemies.
- **Quest check:** Hesk "ghouls 0/8" though I killed ghouls on the Isle; Marla "twists 0/4" though I twisted ~5 times on the Isle. Isle fights don't count.
- **`wait`** -> night (+20% enemy HP, +40% embers, +1 Grave Die). Before that it had been "dusk" for the whole Isle session.
- **Road #2 (night)** with new hero Vael. A free starting weapon appeared (smithy?). Crafted Alpha blade came along. Killed an elite Bone Colossus (water Vael took 11 from one hit - element wheel matters a lot). Shrine and Whispering Die events (gambled, won). Learned campfires stop your movement. Beat the Bishop again (79 HP at night, 6 rounds, closer). Reward only +58 embers, +5 Grave Dice.
- **Town:** Marla gave a Lantern Wisp pet. Summoned **Mordecai the Gambler** ("bet his shadow at a crossroads and lost") - best flavour text in the game.
- **Isle trip 3 (Elderglade)** with Varek/Lys/Mordecai (no healer). Spiders -> silk, amberheart. Tried **Thornback (105 HP)**: blood pairs (Lys+Mordecai) hit for 7+11; lost with the boss on 8 HP. Crafted Amber Staff, upgraded Varek. Ended with 33 embers and 1 Grave Die.

## 2. Highlights and lowlights

Highlights
- Triple-attack turns: big doubled numbers, auto-retarget after kills. Peak dopamine.
- Weapons and carvings physically rewriting the die faces is clear and satisfying. Building the die = building the team, I felt it.
- Writing: Hanged Man's purse ambush, "Something underneath was never human", Mordecai's bio, villagers' one-liners.
- The hunt -> rare part -> SSR weapon loop (Ashen Alpha -> Alpha Fang Blade).
- Heal on a full-HP hero turns into a shield ("prayer wards") - smart, no wasted die.
- Two boss losses by 8-11 HP: tense, "one more try" feeling.
- Defeat on the Isle is gentle (back to gate, keep bag).

Lowlights
- Isle fights are a slog: base dice only, 2 rerolls, 5-6 rounds for ~8 embers and often no drops.
- Embers are the real bottleneck: crafting, upgrades and buildings all eat them, and only the road gives real amounts.
- The first Bishop fight was trivially easy after triple attacks; the second was fine.
- Lots of rerolls land on the same face again; reroll often feels like it did nothing.
- Too much is unexplained: buildings, star upgrades, elements, what a weapon will replace.

## 3. Confusions and bugs (with commands)

1. **Twist then lock unlocks:** `twist 1 3` auto-locks the die; `lock 1` then UNLOCKS it and `reroll` throws away the 4-Fate face. No warning. (Road #1, Ash Cultist fight.)
2. **Isle progress not counted for requests:** after killing 2 ghouls and twisting ~5 times on the Isle, `talk hesk` -> "Thin the Ghouls: 0/8", `talk marla` -> "Bend Your Luck: 0/4". (Marla's did complete on road #2.) Either a bug or needs to say "on the road".
3. **Stale text on reward screens:** `buy carving` in a shop shows "Victory! +9 gold."; `rest carve` shows "You pry open a rotten chest: +22 gold. A weapon lies among the bones."; shrine/whispering-die carvings show "Victory! +29 gold. The party catches its breath (+35% HP). The elite drops its arms."
4. **Second purchase silently fails:** `buy tonic` twice in the same shop - second does nothing, no message.
5. **Move preview misleading:** at tile 28, "move 0 = 5 steps -> rest" (tile 33 is a shop). Turns out campfires stop you - fine, but it should say "stops at rest (tile 30)".
6. **`goto` into a country centre = surprise boss fight** (`goto 40 76` -> Bog Mother). No "Boss ahead, fight? y/n", no flee.
7. **`grind ember_shard 1` -> "Cannot."** with no reason. `sell boar_hide 1` -> "Done." without saying how much I got (it was 2 embers).
8. **`craft ...` -> "Crafted item #1."** No name, rarity or faces. `upgrade hero lys` doesn't say cost or effect. Buildings (`build smithy`) have no descriptions at all.
9. **Element damage numbers are inconsistent/unreadable:** "Varek hits Weeping Nun for 2 (super effective!)" from a plain attack 2; "Bone Hound hits Aldric for 0 (super effective!) (2 blocked)". I never figured out the bonus. The element wheel (earth>water>fire>wind?, light<->dark) is never shown.
10. **Blood magic pays even when the target is already dead** (e.g. "Lys pays 2 HP in blood" after the cultist fell from an earlier die).
11. **Target is global:** a 17-damage triple-attack overkilled a 5 HP serpent; I couldn't aim dice separately.
12. **Rerolls frequently produce the identical face** (Lys shield2 x3; Vael fire2 + Aldric guard1 both unchanged in one reroll). Possibly just luck, but it felt off.
13. Claimed Pip's reward while he was "away" (`claim pip`) - works, but contradicts "not out now" for `talk`.
14. Max HP numbers drift: Varek 29/29 on road #2 start, 28/28 on the Isle after (chapel bonus only on road?). Arrived at the last campfire already healed 18->26 without knowing why.
15. Loaded Dice gave +2 Fate when Fate was already 5/5 - wasted silently.
16. Aldric's Last Rite: "All allies heal 3" then "-3 HP" - on himself it nets 0; 6 charges for that feels weak.

## 4. What I wanted to do but could not

- See a hero's die faces / skill text outside combat (e.g. `hero vael`), and preview what a weapon will replace before equipping.
- Read what buildings and stars do before paying.
- Flee or decline a world fight, especially a boss.
- Target per die, or at least "overflow to next enemy" for single big hits.
- Afford the pet/relic banners: never had 3 Grave Dice spare after the hero banner.
- Finish Hesk's ghoul quest on the Isle, and Tobin's "two elites in one journey" (the road never offered me a second elite in reach).
- Go to tier 3+ countries (Drowned Coast, Frosthold, Cindermaw, Bonewastes) - I felt too weak and too poor.

## 5. Would I keep playing?

**Score: 7/10.** The dice combat is genuinely good: lock/reroll/twist decisions, combos and weapons that rewrite faces make every turn feel like a small puzzle, and the writing gives it a strong mood. The road run has good pacing. What holds it back is the layer around the dice: the Isle is slow and stingy, embers choke every system, and the interface hides too much (no item stats, no building/upgrade info, toggle-lock trap, stale reward text, quests silently not counting). Fix the information gaps and make Isle fights pay better, and this is an 8+.
