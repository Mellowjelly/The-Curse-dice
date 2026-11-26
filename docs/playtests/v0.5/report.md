# Playtest report v0.5

300 full runs per bot style (start of the road -> boss).

## Bot: newbie

- **Win rate: 73%**
- Deaths by fight type: { "fight": 35, "boss": 34, "elite": 13 }; by board third (early/mid/late): [0, 9, 73]
- Reached the boss: 84% of runs, party HP when the boss starts: 89%, boss fight length when won: 7.3 rounds
- Per run (avg): 4.2 fights + 0.8 elites won, 2.3 events, 5.6 carvings, 105 gold earned
- Session length estimate: 11 min (34 combat rounds, 29 map decisions)
- Blank faces: 19% of rolls; per run 15.1 rerolls, 0.00 Fate rerolls
- Skills per run: broken_oath 5.7, hollow_flame 3.6, last_rite 2.3
- Tiles landed on per run: chest 1.1, event 2.3, fight 4.1, rest 2.2, shop 1.2, elite 0.9, boss 0.8
- Win rate by pet: Grave Pup 70% (159 runs), Candle Moth 79% (42 runs), Black Cat 76% (45 runs), Ash Crow 74% (54 runs)
- Win rate by weapon held at the end: Ashwood Staff 70% (30), Rusted Blade 69% (32), Censer of Embers 82% (28), Grave Scythe 50% (16), Tower Shield of Dunmere 86% (37), Widow's Lantern 83% (12), The Thirsting Sword 75% (8), Choir Bell 80% (15), Oathkeeper 83% (12), Bone Flail 87% (15), Executioner's Axe 79% (14), Saint's Knuckle 67% (12)

- **Campaign (20 profiles x 20 runs, buying town upgrades):** win rate by run #: 65% 75% 65% 95% 85% 90% 85% 90% 85% 85% 85% 95% 85% 80% 85% 75% 85% 95% 95% 95%
- Campaign: first win on run #1.6 on average (20/20 profiles ever won); 55 embers per run; 8.8 building levels after 20 runs

## Bot: tactician

- **Win rate: 95%**
- Deaths by fight type: { "fight": 3, "boss": 10, "elite": 1 }; by board third (early/mid/late): [0, 2, 12]
- Reached the boss: 99% of runs, party HP when the boss starts: 85%, boss fight length when won: 7.6 rounds
- Per run (avg): 6.7 fights + 1.6 elites won, 2.0 events, 10.5 carvings, 149 gold earned
- Session length estimate: 17 min (53 combat rounds, 36 map decisions)
- Blank faces: 15% of rolls; per run 81.5 rerolls, 5.22 Fate rerolls
- Skills per run: hollow_flame 3.9, broken_oath 2.6, last_rite 2.3
- Tiles landed on per run: chest 0.9, event 2.0, fight 6.4, shop 0.5, elite 1.6, rest 1.1, boss 1.0
- Win rate by pet: Black Cat 94% (125 runs), Candle Moth 95% (123 runs), Grave Pup 100% (23 runs), Ash Crow 97% (29 runs)
- Win rate by weapon held at the end: Grave Scythe 98% (86), Bone Flail 94% (32), Tower Shield of Dunmere 99% (103), Choir Bell 96% (100), Oathkeeper 100% (57), Saint's Knuckle 100% (28), Widow's Lantern 95% (40), Rusted Blade 100% (12), Executioner's Axe 94% (35), Ashwood Staff 100% (22), Censer of Embers 97% (39), The Thirsting Sword 91% (33)

- **Campaign (20 profiles x 20 runs, buying town upgrades):** win rate by run #: 100% 90% 95% 90% 85% 100% 95% 100% 95% 100% 100% 100% 95% 100% 95% 95% 95% 100% 100% 100%
- Campaign: first win on run #1.0 on average (20/20 profiles ever won); 65 embers per run; 10.0 building levels after 20 runs

## Bot: berserker

- **Win rate: 50%**
- Deaths by fight type: { "fight": 44, "boss": 74, "elite": 31 }; by board third (early/mid/late): [0, 24, 125]
- Reached the boss: 75% of runs, party HP when the boss starts: 60%, boss fight length when won: 5.3 rounds
- Per run (avg): 6.3 fights + 1.6 elites won, 2.1 events, 9.5 carvings, 139 gold earned
- Session length estimate: 12 min (37 combat rounds, 30 map decisions)
- Blank faces: 15% of rolls; per run 69.0 rerolls, 8.12 Fate rerolls
- Skills per run: broken_oath 5.8, hollow_flame 2.2, last_rite 1.2
- Tiles landed on per run: chest 0.6, event 2.1, fight 6.1, elite 1.7, rest 1.0, boss 0.8, shop 0.2
- Win rate by pet: Grave Pup 50% (133 runs), Candle Moth 83% (18 runs), Black Cat 48% (123 runs), Ash Crow 42% (26 runs)
- Win rate by weapon held at the end: Tower Shield of Dunmere 67% (105), Choir Bell 56% (77), Oathkeeper 71% (58), Saint's Knuckle 62% (26), Grave Scythe 50% (70), Widow's Lantern 77% (30), Executioner's Axe 50% (22), Bone Flail 59% (34), Rusted Blade 62% (8), Censer of Embers 52% (25), The Thirsting Sword 48% (44), Ashwood Staff 60% (20)

- **Campaign (20 profiles x 20 runs, buying town upgrades):** win rate by run #: 45% 30% 50% 45% 45% 55% 50% 55% 60% 55% 45% 40% 70% 40% 65% 60% 75% 50% 55% 70%
- Campaign: first win on run #2.5 on average (20/20 profiles ever won); 54 embers per run; 8.1 building levels after 20 runs


## Fair pet comparison (same 150 seeds, pet forced; tools/pet_check.gd)
- newbie: ash_crow 66%  grave_pup 74%  candle_moth 76%  black_cat 68%  
- tactician: ash_crow 91%  grave_pup 93%  candle_moth 95%  black_cat 97%  
