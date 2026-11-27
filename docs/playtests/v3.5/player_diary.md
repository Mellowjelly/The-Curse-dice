# Player diary: Cursed Dice v3.5 (returning player, ~588 commands)

Session file: `docs/playtests/v3.5/session.txt`. I played 3 Hollow Road journeys: day (won), dawn (won) and night (stopped mid-elite fight at tile 22 when my time ran out). I made 2 trips to the Cursed Isle (Ashfall Vale, then Elderglade) and beat 1 Isle boss. I also did villager requests, summons, buildings, crafting, equipping and a pet treat. At the end I replayed the whole session once with `th`.

## 1. Session log

- **Town (day).** I started with `help`, `status` and talked to everyone. Tobin, Marla and Pip are out. Hesk is "away" and only comes out at dusk and night, which is a nice touch. All three day requests are road-flavoured (kill rats, rest at 3 campfires, find 3 events). I accepted all of them. Recipes and hero summons are locked until I finish a journey or visit the Isle. That's clear and I liked it.
- **Journey 1 (day): Varek/Lys/Aldric with the Black Cat.** I carved at the first campfire because Marla's request counts rests. The rat fights were quick. Then I hit a Bone Hound + Bone Hound + Ash Cultist fight. All three attacks went at Aldric, and dark vs light is "super effective" in both directions, so he dropped to 5 HP. The skills saved me: Broken Oath pulled every attack onto Varek, Last Rite healed the party and Hollow Flame hit everyone. I felt clever. The Ossuary Merchant (3 max HP for 50 gold) and the Whispering Die (I lost the 50/50) were flavourful. The boss was **The Rotting Bishop**. I won with Varek on 1 HP, and his mid-fight "tears off his vestments" line was a great moment. I got +312 embers, +9 Grave Dice and five auto-quests.
- **Town (dusk).** I claimed Tobin and Marla. Pip had already gone "away", so I had to wait a day to claim. Second requests: Tobin wants 6 Grave Iron (Isle), Marla wants 3 Boar Hides (Isle), Pip wants 1 Ember Shard and Hesk wants 5 ghouls. One summon each: a hero (Sister Vael), embers from the pet banner and a relic (Plague Lance). I built chapel, smithy, market and carver without knowing what any of them do.
- **Isle trip 1 (Ashfall Vale).** Gathering is snappy: I got 6 Grave Iron plus a RARE Ember Shard in 6 commands. My carvings had reset on the Isle, as I expected. Ash Crow is the Isle pet. I don't know why that one, and there is no way to pick. The **post-win sharpening** (pick 1 of 3, +1 until home) is a lovely small dopamine hit. **The Ashen Alpha** boss had a "howls, the whole forest answers" line. I got a triple-ATTACK combo with a Fate twist for a 10-damage hit and it felt great. Rewards were an alpha_fang, iron and a shard. I couldn't find any Boar Hides at all.
- **Town (night, then dawn).** Pip's Ember Shard request paid 60 embers straight away because I already had a shard. Tobin's third request is "go past tile 20" (reward: Gilded Rat pet). Pip's is "carve 5 times in one journey" (reward: Ember Salamander pet). I summoned Osric. Star-dust upgrades (Varek, Lys, Black Cat to 2 stars) cost 4 dust each, but the game never says so.
- **Journey 2 (dawn): Osric/Vael/Aldric with the Grave Pup.** The Grave Pup's opening bite is nice. Osric's Ash Feast did nothing at 4/4 charge (see bugs). Later it "eats Fate" for a big hit. The Grave Knight nearly killed Vael. I bought carvings at two shops and used rests to get Pip's 5 carves, and used `reroll_move` twice to land on a shop. The boss was **The Rotting Bishop again**. I never found the hint about which boss waits and never met the second road boss.
- **Town (day).** I claimed both pet rewards. Tobin's fourth request is "2 elites in one journey" (relic). Pip's is "a night journey to tile 30". Its reward was Mordecai, but I had just summoned him. The text correctly swapped the reward to "rook (instead of mordecai)". Good.
- **Isle trip 2 (Elderglade).** Giant Spiders dropped 6 silk. I gathered Amberheart and Elderwood and saw the **Thornback** boss and a cave bear. Aldric was down to 9 HP, so I went home.
- **Crafting.** I crafted the Amberheart Staff (fire4/heal3) for Aldric, the Grave-Iron Hatchet for Lys, and an Ember Biscuit that I fed to the Black Cat. The gear carries onto the road, which is very satisfying. I summoned a Lantern Wisp.
- **Journey 3 (night): elites for Tobin, tile 30 for Pip.** The night +20% HP makes plain fights drag: a 2 Ghouls + Cultist fight took 9 rounds. The first elite (Grave Knight + Cultist) gave +35% HP and a weapon choice. The second elite, a 78-HP **Bone Colossus** that stacks 8 shield, was at 24/78 in round 6 when my time ran out.

## 2. Highlights

1. **Combat feels thoughtful.** Locking, rerolling, Fate twists, combos (a triple = double damage) and the elements (super effective / resisted) all matter. Skills with a blood price (Broken Oath, Last Rite, Hollow Flame) gave real "I saved it" moments.
2. **The villager request chains are good.** They step from road tasks to Isle tasks to "go further" or "a night run" challenges. Villager hours (Hesk only at night) give the town life. Pet and hero rewards feel worth it. Star Dust rewards feel weak because I didn't know what dust does.
3. **Boss flavour lines.** The Bishop tearing off his vestments and the Alpha's howl and fall give each boss a short story.
4. **The Isle loop is fast and rewarding.** You walk, gather, fight, sharpen and get recipe materials. Gear crafted on the Isle then changes your dice on the road, and that link between the modes is the best design idea here.
5. **Readable info.** Enemy intents, elements and every hero's faces are always shown. The road map shows the next 8 tiles plus "the party must stop here" warnings. Rewards that would be duplicates are swapped ("instead of mordecai").

## 3. Lowlights

- Fights drag at night and against elites: 7 to 9 rounds of 2–4 damage each against stacked shields.
- The shop is the same 5 items at the same prices every time, and the day "-15%" discount never shows (see bugs).
- Buildings, Star Dust upgrades and summon costs are not explained before you spend.
- I never found the town hint about which road boss waits, so I met the Rotting Bishop twice.
- I never found a Boar Hide, so Marla's request stayed stuck at 0/3.

## 4. Confusions and bugs (with commands)

1. **Ash Feast silently does nothing at full charge.** In journey 2, round 5, Osric had `skill Ash Feast 4/4` with `fate 0`. `skill 0` printed only the combat state again: no "uses", no error, and the charge stayed. Later, with Fate, it printed "Osric eats 3 Fate". It needs a message like "needs Fate".
2. **Day shop discount is not visible.** The status line says "(Open roads: shop prices -15%.)", but the day-1 shop showed `Bitter Tonic (17 gold)`, `Bone Carver (30 gold)`, `Weapon Rack (34)`, `Fate Shard (13)`, `Grave Candle (21)`. The dawn shop and the night shop (after building the market) showed exactly the same prices. Either the discount is already baked in and never changes, or it isn't applied.
3. **The Bone Carver says "Choose 1 of 3" but offers 4** after building the carver. `buy carving` printed pick 0–3, and twice the list had two identical options (`pick 0: Aldric: blank -> SHIELD 3` and `pick 3: Aldric: blank -> SHIELD 3` at a rest).
4. **"Blocked" can be bigger than the hit.** For example, "Dire Wolf hits Lys for 0 (2 blocked)" for an Attack 3 intent. Also "The Ashen Alpha hits Varek for 0 (5 blocked)" from a Sweep 4, and "Plague Rat hits Vael for 0 (4 blocked)" from an Attack 3. It looks like it shows the shield total, not what was absorbed. Also, "Attack 9 -> Lys" became "hits Lys for 3 (resisted) (4 blocked)", so the maths isn't obvious.
5. **The last rest heals on arrival, so `rest heal` is wasted.** `move 0` to tile 41 already showed the party at full HP, and then `rest heal` did nothing new. The UI should say "you are rested, carve instead".
6. **Forced stops are inconsistent.** Sometimes a move says "(the party must stop here)" at a shop or rest, but other moves walk straight past shops (tile 23 → 29 passed 26:shop and 28:shop, and 30 → 33 passed 31:rest). I couldn't learn the rule.
7. **The Black Cat seemed absent in round 1** of the first fight (no pet action in the log) but acted in later rounds. Maybe its d4 rolls something empty, but the log says nothing.
8. **`look` inside an Isle fight** gives "Unknown combat command". A stray `end` after a fight gives "Unknown world command". These are harmless but noisy.
9. **The shop keeps listing a bought item.** `buy tonic` a second time gives "Cannot buy tonic: already bought here", but the item stays in the list.
10. **"+0 dust"** in "FIGHT OVER: VICTORY. +15 embers, +0 dust" reads oddly.
11. **No way to check request progress on the road.** `talk pip` gives "Unknown road command".
12. **No way to choose the Isle pet.** Ash Crow is always the one that follows me.

## 5. What I wanted to do but could not

- Meet the second road boss. I never saw the town hint, and both finished journeys ended at the Rotting Bishop.
- Find Boar Hides for Marla and the boar jerky treat.
- Reach the Sunken Abbey dungeon (T3, at 65,84). My party was too weak, and my time ran out.
- Try `flee` on the Isle, and the Thornback boss.
- Finish the night journey for Pip (tile 30) and Tobin's 2-elite request. I stopped at elite #2 on tile 22.
- Understand what chapel, fortune, smithy, market and kennel actually change.

## 6. Thai replay (`... session.txt 80 th`)

**Translated well:** combat log (hits, burn, combos, skills, Fate twists, "ชนะทาง!" / "แพ้ทาง"), boss phase lines, enemy intents, rest/carver flavour, hero summon flavour, pet summon, embers-from-dice, the elite reward line and quest-claim currencies.

**Still English:**
- **Every road EVENT is fully English: title, story and choices.** Examples: "EVENT The Ossuary Merchant: A smiling man ...", "pick 0: Sell life (a hero loses 3 max HP) for 50 gold.", "pick 1: Refuse.", The Whispering Die, The Pilgrim's Fire, The Hollow Well, The Ash Mirror and Crow Feast. Only the RESULT line is Thai.
- **All villager dialogue is English:** greetings ("The fields grow nothing but bones these days."), "Asks: ..." texts, "Working on ...", "Request accepted: Rats in the Grain", "X is not in town right now (out at: dawn, day)".
- **Skill cost line for Miasma:** "The plague bites Vael (-2 HP)". It is English, while Vael's skill line ("* Vael ใช้ ไอพิษ!") and the fog line are Thai.
- **Isle and town messages:** "FIGHT OVER: VICTORY. +15 embers, +0 dust, drops { "grave_iron": 1 }", "JOURNEY OVER: VICTORY at tile 42 ... quests: First Steps, The Last Campfire ...", "BATTLE-HARDENED: pick 1 sharpening ...", "Lys's FIRE face sharpens to 4", "Gathered 2 Grave Iron", "Walked 7 steps", "Built chapel.", "hero varek is now 2 stars.", "Quest complete: Landfall", "Time passes. It is now dawn. First light: ...", the "(Open roads: ...)" time hints, the zone blurb "Grey forests around the last town...", "BOSS The Ashen Alpha guards its lair here", "Relic unlocked: Plague Lance", "Crafted item #1 ...", "Fed.", "Equipped.".
- **Shop items and descriptions:** Bitter Tonic, "Heal all heroes 8 HP.", and the rest of the shop list. Pet pick descriptions are English too ("Grave Pup - Its d4 bites enemies. Passive: ..."), even though the summon line for the Lantern Wisp is Thai.
- **Carving picks** use English face words ("Varek: blank -> ATTACK 3"), and the twist line mixes languages ("ชะตาบิดเต๋าของ Lys เป็น BLOOD 7").
- **Mixed-language claims:** "Reward: +3 ผงดาว".

**Reads badly:**
- **The Ash Mirror RESULT** reads "HP สูงสุดของ Osric เหลือ 31". "เหลือ" means "is down to", but this was a max-HP **gain** (27 → 31). It is correct for the Ossuary Merchant's loss, but should be something like "เพิ่มเป็น" for gains.
- **Enemy names don't match.** The combat-state line keeps English enemy names ("Plague Rat 7/7 hp ... intent: โจมตี 2"), while the log uses Thai ("หนูโรคระบาด ตี Aldric"). A Thai player can't easily match the two.

## 7. Would I keep playing? 7/10

The dice combat and the road ↔ Isle ↔ crafting loop are genuinely good. Villager chains gave me goals every time I came back to town, and the boss lines are memorable. Several things hold it back:
- long, shield-stacking fights at night and against elites
- a shop that never changes
- unexplained buildings and costs
- a hidden road-boss hint I never found
- Thai being half-done exactly where the story is (events and villagers)
