# Cursed Dice v3.2 - Player Diary

Played through `tools/play_cli.gd` with `docs/playtests/v3.2/session.txt` (about 500 lines, including a few mistyped or wrong-phase commands).
What I covered: two Hollow Road journeys (both won), first Isle trip (gathered, fought, fled the Ashen Alpha), second Isle trip (Elderglade, beat the Thornback boss), Forge crafting and equip, a companion treat, all three summon banners, villager requests, building, star upgrades, bestiary trophy, and the Thai re-run.

## 1. Session log

**Town, first look**
- I ran `status` and talked to everyone. Three villagers have requests: rats (Tobin), rest at campfires (Marla), events (Pip). Captain Hesk is "away" and comes out only at dusk and night. That is a nice touch, the town feels like it has a clock.
- `explore`, `summon heroes` and `recipes` all say "Locked. Finish one journey..." / "Return from the Cursed Isle once...". Clear. I knew right away that the road comes first.
- Six buildings are listed with costs, but nothing tells me what any of them does. I have 0 embers anyway.

**Journey 1 (day)**
- Pet pick: Black Cat ("+1 reroll every round") or Grave Pup. I took the cat. In fights it then *shielded* allies and *hit* enemies at random, and my rerolls stayed at 3 every round. I could not tell whether the "+1 reroll" ever happened. Confused.
- First rest: I carved instead of healing (blank -> ATTACK 3 on Varek). Carving feels great, and you can see your dice getting better.
- First fight vs 3 Plague Rats: lock, reroll, end. Easy and readable. Blood 6 on Lys costing 2 HP is a nice risk.
- Chest: Rusted Blade, I equipped it on Aldric. **No message said which faces it replaced**, I had to compare face lists in the next fight (it replaced faces 5-6, heal2 and attack2).
- Bone Hound fight: I used Fate 4 to **Twist** Lys to ATTACK 4 for a triple-attack combo (values doubled), retargeted to the hound attacking Lys, and one-shot it. Best moment of the run, I felt smart.
- Weeping Nun fight: killed the healer first with another twist. Light vs dark "super effective" and fire vs water "resisted" show in the log, so I learned the elements from the log. Good.
- Varek's Broken Oath (draws every single-target attack, +5 shield) plus Aldric's Last Rite (heal all) saved me. The skills feel strong and each has a price, which fits the tone.
- Elite Grave Knight mostly "Hesitates" and went down in 3 rounds. The elite felt weaker than some normal fights.
- I equipped the rare Grave Scythe on Lys. It silently **replaced her ATTACK 4**, which broke my triple-attack plan for the boss. Again, no warning about which faces get replaced.
- Boss, The Rotting Bishop (72 HP): tense. Phase 2 line "tears off his vestments. Something underneath was never human." is great. I won with Lys and Aldric both at 2 HP. Very satisfying.
- Result: +224 embers, +9 grave dice, five quests completed at once.

**Back in town**
- Marla done. `status` showed Pip as `DONE`, but `claim pip` said "Not finished yet." (Pip was "away" at dusk.) It worked later in the day. The message is wrong or misleading.
- Summons: heroes gave Sister Vael, relics gave "+35 Soul Embers (1/4 toward a guaranteed find)", pets gave Ember Salamander. Pity is shown on the relic banner. Fair. I could not see rates or what is in each banner.
- Built chapel, market, smithy. Still no description of what they do. Max HP went up by 1 afterwards (chapel?), and the next journey began with a free weapon (smithy?). I had to guess both.

**Cursed Isle, trip 1**
- `explore` shows a map with resource nodes, monsters, a BOSS, and seven countries with tiers. Good sense of a big world.
- Gathering is quick (`goto` + `gather`). The fights here use **base dice** (road carvings do not carry over), which is fine for a roguelite.
- Nice: Aldric's heal at full HP turns into a shield ("prayer wards"), and after each Isle win one face "sharpens until you go home".
- Tried the Ashen Alpha boss (65 HP). I only did about 5 damage per round with base dice, so I fled in round 2. `flee` worked: "You break away and run!" No penalty that I could see except being pushed back a few tiles. Good safety valve.
- `home` stored materials and completed "Landfall" (+20 embers).

**Forge, upgrades**
- `recipes` is a big list. Only the Iron Hatchet was craftable. Crafting said exactly "replaces die faces 5-6" (this is the feedback road loot is missing). I equipped it on Aldric and it carried into the road. 
- `upgrade hero varek` -> 2 stars. The cost (embers and star dust) is never shown before you press it.
- Pip's next request rewarded Ember Salamander, which I already owned. It became 8 Star Dust on claim, which is fine, but the request should say so up front.

**Journey 2 (dawn)**
- Started with free loot (Tower Shield), took Ash Crow. Did Pip's carve x5 and Marla's twist x4 and Tobin's rats naturally while playing. These requests fit the road well and nudge you to try mechanics (twisting, carving).
- More elites on this road (3 in a row on the map), but I routed around them.
- Shops and rests "force a stop". This is shown on the move choice, which is clear.
- A Fate Shard (+3) at Fate 3 was wasted by the cap of 5 without a warning.
- Same Rotting Bishop again. Won with two heroes at 1 HP. Reward was only +71 embers, +3 dice (the first-time quests are gone). The second road felt like a repeat: same boss, same events pool.

**Cursed Isle, trip 2**
- Took the new Mordecai (Loaded Dice skill, blood 8 face). `goto 40 30` stopped twice next to the Ashen Alpha lair ("guards its lair here") because the path ran past it. I had to walk around it by hand.
- Elderglade (tier 2): spiders (silk), Amberheart, Elderwood. Then I beat **Thornback** (105 HP, T2 boss) with 2-star starters. Its death line, "The old bear lies down. Flowers grow where it fell.", is lovely. Drops: thornback_hide, amberheart, living_sap.
- Cave Bear dropped only 1 bear_hide. The armor needs 6, so that is a lot of grinding.
- HP does not regenerate between Isle fights. That is good tension, it pushes you to go home.
- Home: "A Full Cart" quest (+30 embers).
- Crafted Amber Honeycake and fed it to Ash Crow ("blank face becomes heal2"), then upgraded the crow to 2 stars. `feed` only replies "Fed." with no summary.
- Sold and ground Amberheart: 4 Amberheart ground into just +1 star dust. Grinding feels bad.

## 2. Highlights
1. **Twist + triple combo**: using Fate to twist one die into a triple ATTACK (values doubled) is a real "I'm clever" moment. Fate as a resource you save across fights is good.
2. **Boss fights** (Rotting Bishop phase change, Thornback) are tense, have short, very good flavor lines, and I won both on the last HP.
3. **Hero skills with a price** (Broken Oath taunt, Last Rite, Loaded Dice) work together and fit the grim tone.
4. **Unlock pacing**: road -> Isle/summons -> Forge. Each lock says exactly what opens it. The town's time of day (villagers out at certain hours, night = +20% HP but more loot) adds flavor.
5. **Bestiary text and villager lines** are excellent ("Hounds of the old kennels, rebuilt by someone who never saw a dog.").

## 3. Lowlights
- Road loot (`equip_loot`) never says which faces it replaces, and nothing is printed after equipping. I lost a key face to an "upgrade".
- Buildings have no description of their effect, and upgrade costs are not shown before you pay.
- The second Hollow Road journey felt the same as the first (same boss, same events), and paid much less.
- The Isle quests are invisible: no quest list command, they just pop ("Landfall", "A Full Cart"). Rewards are small (+20/+30 embers). They did not make the trip feel worthwhile on their own. The *materials* and *the boss drops* did.
- I never saw a villager **material request** (none of the 4 villagers asked for Isle materials in my run), so materials only feed the Forge for me.
- Rewards and drops print raw JSON (`-> reward { "kind": "dust", "amount": 3 }`, `drops { "grave_iron": 1 }`).

## 4. Confusions and bugs (with commands)
1. **Pip shows DONE but can't be claimed.** At dusk after journey 1: `status` -> `pip(away, DONE)`; `claim pip` -> `Not finished yet.` It worked at dawn. Message should say "Pip is not out now".
2. **Black Cat description vs behavior.** Pet pick says "Black Cat - d4 of mischief. +1 reroll every round." In combat: `Black Cat shields Varek (2)`, `Black Cat hits Plague Rat for 1`, and rerolls stayed at `rerolls 3` each round. Same with Ash Crow ("Starts every fight with +2 Fate") which also `hits` enemies. I don't know which part is the real effect.
3. **Altar event uses the shop text.** `pick 0` at "The Bleeding Altar" -> "The Bone Carver sets to work on your dice." (there is no carver at an altar).
4. **equip_loot gives no feedback.** `equip_loot 0 2` just returns to the map. `equip_loot 1 1` (Grave Scythe on Lys) replaced `attack4, shield2` without saying so.
5. **Chest gives silent gold.** `move 0` onto a chest at tile 37 -> gold 42 -> 62, no message.
6. **Wrong-phase commands give no error on the road.** `roll` during a reward or event result phase just prints the same state again (`> roll` after `equip_loot 1 1`). In combat, by contrast, `fight` correctly says "Unknown combat command."
7. **Kennel shows `next -1`** after building it once: `kennel lv1 (next -1)`. Probably "max level", but it looks broken.
8. **Requests reward things you already own.** Pip: reward `{ "kind": "pet", "id": "ember_salamander" }` (I already had it from the banner). Marla: reward hero `vael` (already summoned). Pip: reward hero `mordecai` after I summoned him. Converted to dust on claim, but the offer should say so.
9. **Fate Shard wasted at cap.** `buy fate_shard` at Fate 3 -> Fate 5 (cap), 1 point lost, no warning.
10. **goto stops at the boss lair repeatedly.** `goto 40 30` from (22,48) -> "Walked 3 steps. BOSS The Ashen Alpha guards its lair here"; again `goto 40 30` -> "Walked 1 steps. BOSS ...". I had to `goto 30 42` first to route around it.
11. **Face "sharpening" always picked Aldric.** All 5 Isle wins I checked said "Aldric's ... face sharpens". Maybe random, but it looks like it always picks the same hero.
12. `gather` at (39,24), which `look` had listed as `ore at (39, 24) (Amberheart)`, -> "Nothing to gather within 1 cell." (the previous gather at (40,24) probably took it). Then `look` still listed `ore at (42, 24)` after I had gathered there.
13. Ash Cultist has intent `Heal 3` while at full HP (round 3, journey 1).

## 5. What I wanted to do but could not
- See what a building, a banner or a hero does before spending (`info <thing>` / hero sheet).
- See my active requests and Isle quests in one list.
- Choose which faces a road weapon replaces, or at least preview them.
- Make the bear armor or the Thornback Carapace: too many bear hides needed for one trip.
- Get Captain Hesk's 8 ghouls done: ghouls are rare on the Isle, so this crawls (2/8).

## Thai text (run with `... session.txt 80 th`)
- The combat log is mostly in Thai and reads well: "Varek ตี หนูโรคระบาด 3 ดาเมจ", "หนูโรคระบาด ล้มลง!", "บิชอปเน่า กวาดทั้งทีม!", "Varek คุ้มกันทีม (+2 โล่ทุกคน)", "คำภาวนาของ Aldric ปกป้อง Varek (+3 โล่)". The intents "โจมตี 5", "ลังเล", "กวาด 6", "ฮีล 4", "โล่ 3" are short and clear.
- The boss lines are translated and keep the mood: "!! บิชอปเน่าฉีกอาภรณ์ทิ้ง สิ่งที่อยู่ข้างใต้ไม่เคยเป็นมนุษย์", "!! หมีชราล้มตัวลงนอน ดอกไม้ผลิบานตรงที่มันล้ม".
- **Untranslated / mixed lines in combat:**
  - "The combo feeds your Fate +1 ชะตา" (half English, appears in almost every fight)
  - "Lys (blood magic) ตี ..." ("(blood magic)" stays English)
  - "Aldric rolls nothing... +1 ชะตา"
  - "Luck is never free for Mordecai (-3 HP)"
  - "Loaded Dice: +2 ชะตา" / "Loaded Dice: ชะตาล้น: ทอยใหม่ฟรี +1 ในรอบหน้า" (the skill name stays English here, but elsewhere it is "เต๋าถ่วง")
  - Combo lines keep the face names in English: "คอมโบ: ATTACK หนึ่งคู่ - +1 ทุกลูก", "ชะตาบิดเต๋าของ Varek เป็น ATTACK 4". This is OK if faces are meant to stay English, but it looks mixed.
- **Awkward wording:**
  - "พวกเดียวกันทุกคนฮีล 4" (Last Rite, all allies heal 4): "พวกเดียวกัน" sounds like "the same gang". "พันธมิตรทุกคนฟื้น 4 HP" or "ทุกคนในทีมฟื้นพลัง 4" would read better.
  - "(ชนะทาง!)" for super effective and "(แพ้ทาง)" for resisted are understandable. "(แพ้ทาง)" on an *enemy* hitting a hero ("หลังหนาม ตี Mordecai ... (แพ้ทาง)") reads as if the bear is weak, which is correct but took me a second.
  - Enemy names in the log are Thai while the hero full names stay English ("หนูโรคระบาด ตี Brother Aldric 3 ดาเมจ"). That follows the rule that hero names stay English, but "Brother Aldric" next to Thai looks odd. Using only "Aldric" (as in the heroes' own lines) would be smoother.
- **Not translated at all in the CLI with `th`:** event titles and texts ("EVENT The Bleeding Altar: ..."), event results, the rest and carve lines ("By the fire, you whittle at your dice."), "Victory! +8 gold.", the villager greetings and requests, summon results ("A new hero joins you: ..."), and "JOURNEY OVER" / "FIGHT OVER". Maybe the CLI just does not pass these through translation, but the brief said some story text should be Thai, so this is worth checking.
- I saw no garbled characters or broken placeholders.

## 6. Would I keep playing? Score: 7/10
The core dice combat is genuinely good: locking, rerolling, saving Fate to twist into a triple combo, and skills with a blood price all make each round a small puzzle, and the bosses gave me two great last-HP wins. The town clock, villagers and bestiary text give the world a lot of character for very few words. What holds it back is **information**: I spent embers, dust and dice on buildings, banners and upgrades without knowing what they do or cost, road loot silently overwrote my best face, and the Isle quests and drops come out as raw JSON with no quest log. The second road run was the same as the first and paid much less, so the long-term hook is the Isle and the Forge. Those are promising (Thornback was a highlight), but the material counts (6 bear hides) make crafting feel grindy. I would keep playing to build a Mordecai team and push into tier 3, but I would want an info/preview command first.
