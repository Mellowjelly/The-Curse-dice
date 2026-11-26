# Playtest report v1.0

300 full runs per bot style (start of the road -> boss).

## Bot: newbie

- **Win rate: 80%**
- Deaths by fight type: { "boss": 28, "fight": 22, "elite": 9 }; by board third (early/mid/late): [0, 12, 47]
- Reached the boss: 90% of runs, party HP when the boss starts: 98%, boss fight length when won: 8.0 rounds
- Per run (avg): 4.0 fights + 0.7 elites won, 2.1 events, 5.3 carvings, 96 gold earned
- Session length estimate: 12 min (36 combat rounds, 31 map decisions)
- Blank faces: 6% of rolls; per run 4.4 rerolls, 1.54 Fate rerolls
- Skills per run: broken_oath 7.0, hollow_flame 4.8, last_rite 3.1
- Tiles landed on per run: chest 1.0, event 2.1, rest 3.0, fight 3.9, shop 1.9, elite 0.7, boss 0.9
- Win rate by pet: Grave Pup 86% (159 runs), Candle Moth 76% (42 runs), Black Cat 71% (45 runs), Ash Crow 76% (54 runs)
- Win rate by weapon held at the end: Widow's Lantern 89% (9), Tower Shield of Dunmere 84% (32), The Thirsting Sword 73% (11), Censer of Embers 81% (26), Ashwood Staff 100% (23), Oathkeeper 83% (12), Grave Scythe 100% (9), Bone Flail 92% (12), Choir Bell 93% (14), Saint's Knuckle 92% (13), Rusted Blade 75% (28), Executioner's Axe 100% (10)

- **Campaign (20 profiles x 20 runs, buying town upgrades):** win rate by run #: 60% 80% 80% 85% 95% 95% 95% 90% 100% 85% 80% 85% 100% 95% 100% 95% 95% 85% 80% 90%
- Campaign: first win on run #1.5 on average (20/20 profiles ever won); 56 embers per run; 9.5 building levels and Curse 0.0 after 20 runs

## Bot: tactician

- **Win rate: 90%**
- Deaths by fight type: { "elite": 5, "boss": 17, "fight": 9 }; by board third (early/mid/late): [0, 5, 26]
- Reached the boss: 95% of runs, party HP when the boss starts: 91%, boss fight length when won: 7.2 rounds
- Per run (avg): 6.9 fights + 1.4 elites won, 2.1 events, 12.4 carvings, 152 gold earned
- Session length estimate: 18 min (55 combat rounds, 46 map decisions)
- Blank faces: 3% of rolls; per run 83.8 rerolls, 4.48 Fate rerolls
- Skills per run: hollow_flame 4.0, last_rite 3.2, broken_oath 2.9
- Tiles landed on per run: chest 1.1, event 2.1, fight 6.7, shop 1.4, rest 2.1, elite 1.5, boss 1.0
- Win rate by pet: Black Cat 90% (125 runs), Candle Moth 88% (123 runs), Grave Pup 91% (23 runs), Ash Crow 93% (29 runs)
- Win rate by weapon held at the end: Grave Scythe 95% (60), The Thirsting Sword 79% (39), Choir Bell 99% (116), Executioner's Axe 100% (23), Bone Flail 87% (38), Tower Shield of Dunmere 95% (113), Oathkeeper 100% (46), Widow's Lantern 90% (50), Ashwood Staff 100% (10), Censer of Embers 90% (21), Saint's Knuckle 100% (21), Rusted Blade 100% (4)

- **Campaign (20 profiles x 20 runs, buying town upgrades):** win rate by run #: 100% 65% 70% 55% 55% 50% 60% 55% 70% 60% 65% 65% 55% 60% 45% 85% 60% 60% 70% 65%
- Campaign: first win on run #1.0 on average (20/20 profiles ever won); 87 embers per run; 11.0 building levels and Curse 4.0 after 20 runs

## Bot: berserker

- **Win rate: 35%**
- Deaths by fight type: { "elite": 69, "fight": 94, "boss": 32 }; by board third (early/mid/late): [0, 88, 107]
- Reached the boss: 46% of runs, party HP when the boss starts: 75%, boss fight length when won: 5.0 rounds
- Per run (avg): 5.7 fights + 1.1 elites won, 1.9 events, 9.1 carvings, 117 gold earned
- Session length estimate: 11 min (32 combat rounds, 32 map decisions)
- Blank faces: 4% of rolls; per run 62.0 rerolls, 7.31 Fate rerolls
- Skills per run: broken_oath 5.1, hollow_flame 1.9, last_rite 1.2
- Tiles landed on per run: chest 0.6, event 1.9, fight 5.7, shop 1.1, elite 1.4, rest 1.3, boss 0.5
- Win rate by pet: Grave Pup 44% (133 runs), Candle Moth 28% (18 runs), Black Cat 29% (123 runs), Ash Crow 23% (26 runs)
- Win rate by weapon held at the end: Ashwood Staff 38% (13), Choir Bell 47% (97), Tower Shield of Dunmere 53% (105), Widow's Lantern 52% (44), Censer of Embers 18% (22), Grave Scythe 61% (57), Saint's Knuckle 37% (27), Bone Flail 39% (38), Oathkeeper 51% (49), The Thirsting Sword 49% (39), Executioner's Axe 54% (24), Rusted Blade 0% (1)

- **Campaign (20 profiles x 20 runs, buying town upgrades):** win rate by run #: 35% 20% 40% 25% 10% 20% 30% 10% 10% 15% 25% 15% 0% 0% 5% 10% 0% 0% 5% 10%
- Campaign: first win on run #3.4 on average (20/20 profiles ever won); 45 embers per run; 6.8 building levels and Curse 2.9 after 20 runs


## Hero balance (every party of 3, same seeds; tools/hero_check.gd)
- newbie heroes: varek 71%  lys 68%  aldric 77%  rook 72%  vael 72%  mordecai 69%  
- newbie best: ["varek", "aldric", "vael"] 88% | worst: ["varek", "lys", "mordecai"] 60%
- tactician heroes: varek 85%  lys 85%  aldric 94%  rook 88%  vael 88%  mordecai 86%  
- tactician best: ["varek", "aldric", "vael"] 100% | worst: ["varek", "lys", "mordecai"] 70%

## Fair pet comparison (tools/pet_check.gd)
- newbie: ash_crow 72%  grave_pup 81%  candle_moth 76%  black_cat 73%  
- tactician: ash_crow 92%  grave_pup 94%  candle_moth 93%  black_cat 90%  
