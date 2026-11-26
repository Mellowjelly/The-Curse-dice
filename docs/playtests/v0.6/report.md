# Playtest report v0.6

300 full runs per bot style (start of the road -> boss).

## Bot: newbie

- **Win rate: 75%**
- Deaths by fight type: { "fight": 22, "boss": 45, "elite": 9 }; by board third (early/mid/late): [0, 8, 68]
- Reached the boss: 90% of runs, party HP when the boss starts: 98%, boss fight length when won: 8.1 rounds
- Per run (avg): 4.0 fights + 0.7 elites won, 2.1 events, 5.4 carvings, 96 gold earned
- Session length estimate: 12 min (34 combat rounds, 31 map decisions)
- Blank faces: 12% of rolls; per run 10.3 rerolls, 0.00 Fate rerolls
- Skills per run: broken_oath 6.0, hollow_flame 3.9, last_rite 2.5
- Tiles landed on per run: chest 1.0, event 2.1, rest 3.0, fight 3.9, shop 1.9, elite 0.7, boss 0.9
- Win rate by pet: Grave Pup 80% (159 runs), Candle Moth 74% (42 runs), Black Cat 67% (45 runs), Ash Crow 67% (54 runs)
- Win rate by weapon held at the end: Widow's Lantern 67% (9), Tower Shield of Dunmere 73% (30), The Thirsting Sword 91% (11), Censer of Embers 79% (24), Ashwood Staff 81% (26), Oathkeeper 82% (11), Grave Scythe 89% (9), Bone Flail 83% (12), Choir Bell 74% (19), Saint's Knuckle 67% (12), Rusted Blade 80% (30), Executioner's Axe 100% (10)

- **Campaign (20 profiles x 20 runs, buying town upgrades):** win rate by run #: 55% 85% 80% 90% 80% 100% 85% 90% 85% 90% 80% 90% 90% 95% 90% 95% 95% 90% 100% 95%
- Campaign: first win on run #1.6 on average (20/20 profiles ever won); 54 embers per run; 9.1 building levels after 20 runs

## Bot: tactician

- **Win rate: 94%**
- Deaths by fight type: { "boss": 15, "elite": 4 }; by board third (early/mid/late): [0, 2, 17]
- Reached the boss: 99% of runs, party HP when the boss starts: 91%, boss fight length when won: 8.0 rounds
- Per run (avg): 7.1 fights + 1.6 elites won, 2.0 events, 12.6 carvings, 156 gold earned
- Session length estimate: 19 min (57 combat rounds, 47 map decisions)
- Blank faces: 5% of rolls; per run 86.7 rerolls, 4.52 Fate rerolls
- Skills per run: hollow_flame 4.3, last_rite 3.4, broken_oath 3.1
- Tiles landed on per run: chest 1.1, event 2.0, fight 6.8, shop 1.4, rest 2.1, elite 1.6, boss 1.0
- Win rate by pet: Black Cat 97% (125 runs), Candle Moth 91% (123 runs), Grave Pup 91% (23 runs), Ash Crow 93% (29 runs)
- Win rate by weapon held at the end: The Thirsting Sword 89% (35), Grave Scythe 89% (64), Oathkeeper 94% (52), Censer of Embers 94% (16), Bone Flail 95% (38), Executioner's Axe 92% (24), Choir Bell 99% (112), Tower Shield of Dunmere 96% (131), Widow's Lantern 97% (68), Ashwood Staff 89% (9), Saint's Knuckle 100% (23), Rusted Blade 100% (1)

- **Campaign (20 profiles x 20 runs, buying town upgrades):** win rate by run #: 100% 95% 85% 85% 95% 100% 95% 100% 100% 100% 100% 100% 95% 95% 95% 100% 95% 95% 100% 100%
- Campaign: first win on run #1.0 on average (20/20 profiles ever won); 65 embers per run; 10.6 building levels after 20 runs

## Bot: berserker

- **Win rate: 32%**
- Deaths by fight type: { "elite": 69, "fight": 95, "boss": 39 }; by board third (early/mid/late): [0, 76, 127]
- Reached the boss: 45% of runs, party HP when the boss starts: 73%, boss fight length when won: 5.1 rounds
- Per run (avg): 5.8 fights + 1.2 elites won, 1.9 events, 9.2 carvings, 119 gold earned
- Session length estimate: 11 min (32 combat rounds, 32 map decisions)
- Blank faces: 7% of rolls; per run 60.9 rerolls, 7.43 Fate rerolls
- Skills per run: broken_oath 4.9, hollow_flame 1.7, last_rite 1.2
- Tiles landed on per run: chest 0.7, event 1.9, fight 5.8, shop 1.2, elite 1.4, rest 1.3, boss 0.5
- Win rate by pet: Grave Pup 38% (133 runs), Candle Moth 33% (18 runs), Black Cat 29% (123 runs), Ash Crow 15% (26 runs)
- Win rate by weapon held at the end: Ashwood Staff 31% (16), Choir Bell 51% (99), Tower Shield of Dunmere 35% (106), Widow's Lantern 58% (53), Grave Scythe 53% (57), Saint's Knuckle 43% (28), Bone Flail 38% (32), Executioner's Axe 48% (25), Oathkeeper 52% (50), The Thirsting Sword 37% (41), Censer of Embers 12% (25), Rusted Blade 0% (1)

- **Campaign (20 profiles x 20 runs, buying town upgrades):** win rate by run #: 45% 30% 25% 30% 30% 35% 15% 35% 45% 35% 55% 40% 25% 30% 40% 25% 40% 50% 60% 30%
- Campaign: first win on run #3.0 on average (20/20 profiles ever won); 47 embers per run; 7.1 building levels after 20 runs


## Hero balance (every party of 3, same seeds; tools/hero_check.gd)
- newbie heroes: varek 69%  lys 63%  aldric 69%  rook 67%  vael 63%  mordecai 61%  
- newbie best: ["varek", "aldric", "vael"] 92% | worst: ["varek", "vael", "mordecai"] 46%
- tactician heroes: varek 81%  lys 79%  aldric 91%  rook 82%  vael 86%  mordecai 83%  
- tactician best: ["varek", "aldric", "vael"] 100% | worst: ["varek", "lys", "rook"] 58%

## Fair pet comparison (tools/pet_check.gd)
- newbie: ash_crow 68%  grave_pup 77%  candle_moth 76%  black_cat 72%  
- tactician: ash_crow 90%  grave_pup 92%  candle_moth 88%  black_cat 88%  
