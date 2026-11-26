# Cursed Dice v3.0: Developer Analysis

**Author:** game-developer agent · **Build analysed:** v3.0 (commit 5540b11) plus the 3.1 additions listed in §8
**Sources:** all of `scripts/`, `data/`, `tools/`, `tests/`, `docs/GDD.md`, `docs/playtests/v2.2/{player_diary,critique}.md`, `docs/playtests/v3.0/report.md`, `export_presets.cfg`, `project.godot`.

---

## 1. Summary

- **The core is strong and well protected.** The dice combat (lock, reroll, Fate, Twist, combos, weapons that rewrite faces) is the best part of the game, and it has the most tests.
- **The architecture rule (core/UI split) is kept.** All rules live in `scripts/core` as `RefCounted` scripts, so the 980 test checks and three bot styles can play the whole game headless. This is the project's biggest technical asset. Keep it.
- **The game is wide, not deep.** There are 4 layers (road, town, Isle, Forge) and 3 currencies plus materials. Each layer has a little content. v3.0 joined the layers (one economy, shared rules). The next step is **depth inside the layers**, not new layers.
- **It is not ready for a store launch yet.** Missing pieces: Thai text and a Thai font, a first-time tutorial, a settings screen, safe saving on a phone, Android back/pause handling, store setup (package name, version, privacy policy, closed test). None is hard. Together they are about one update of work.

---

## 2. Architecture and code quality

| Area | State | Notes |
|---|---|---|
| Core/UI split | Good | `combat.gd`, `run.gd`, `world.gd`, `profile.gd` have no nodes. UI forwards clicks. |
| Content in data | Good | 13 JSON files. Skills are the exception by design (a `match` on `skill.id`). |
| Tests | Good | `tests/run_tests.gd`: 43 test functions, 980 checks. UI scripts are compile-checked. `tools/run_tests.sh` also fails on SCRIPT ERROR. |
| Balance tooling | Good | `tools/playtest.gd` (3 bots × 300 runs, plus a 20-run campaign), `hero_check.gd`, `pet_check.gd`, `world_check.gd`, `time_check.gd`, and the deterministic CLI `play_cli.gd` for AI players. |
| `profile.gd` | Getting large | About 700 lines: town, quests, gacha, villagers, stars, materials, Forge, Bestiary, time of day, run save. It works, but it is a "god object". Split it once it passes about 900 lines (for example `forge.gd`, `villagers.gd`) and keep `Profile` as the save owner. |
| Data loading | Risk on low-end phones | `GameData.load_json` reads and parses the file on **every** call. `recipes()`, `item_def()`, `locked_heroes()`, `bestiary_entries()` and others call it inside loops, and the town UI rebuilds every tab after every click. Fine on desktop; it may stutter on a cheap Android phone. Fix: a static cache in `GameData` that returns `duplicate(true)` copies. |
| Saving | Risk | `Profile.save()` writes with `store_var` straight over `user://profile.save`. If Android kills the app during the write, the save can be lost. No backup, and `"version"` is written but never read. Fix: write to `profile.tmp` and rename, keep `profile.bak`, and add a `migrate(d)` step keyed on version. |
| Android lifecycle | Missing | No handling of `NOTIFICATION_APPLICATION_PAUSED` / `WM_GO_BACK_REQUEST`. The road auto-saves on each map step and the Isle saves after each action, so the loss is small, but the Android back button should open a menu and not quit. |
| UI layout | OK for landscape | 1280×720 landscape, `canvas_items` stretch, `keep` aspect. About 20 labels use 11–12 px text, which is small on a 6" phone. Tall phones (20:9) get side bars because of `keep`. Consider `expand` and anchoring the town panel. |
| Repo hygiene | Fix | `cursed-dice-v2.2.zip` (20 MB) sits in the project root. It isn't exported (the export only includes resources plus `data/*.json`), but it bloats git history. Move it to a GitHub release. |

---

## 3. Systems and how they connect (after v3.0)

```
Hollow Road run ──embers, grave dice, star dust, kills──┐
     ▲   (gear, stars, chapel, pets, time of day)        ▼
     └────────────── Ashfall (town) ◄──── materials, kills, boss dice ──── Cursed Isle
                     buildings · summon (3 banners, pity 4) · stars · Forge · villagers · quests · Bestiary
```

- One economy now: Isle fights pay `10×tier` embers, the road pays `victory 40`, star costs lean on Star Dust, and Isle bosses pay a Grave Die.
- Shared rules: the Chapel, stars and gear apply in both modes, and Isle kills count for requests and (now) the Bestiary.
- Still separate: time of day only moves on a return to town. Road carvings and Isle "sharpenings" are separate (by design).
- **Before 3.1 there was a gap: nothing in town asked for Isle materials except the Forge.** Common materials piled up. 3.1 adds villager deliveries and companion treats as sinks for common materials, and the Bestiary as a long-term hunting goal.

---

## 4. Content volume

| Content | Count | Verdict |
|---|---|---|
| Heroes | 6 (3 starters + 3 summonable) | Thin for a gacha-style collection. Target 10–12 at launch. |
| Monsters | 23 (8 road incl. 2 elites + Bishop, 9 beasts, 6 Isle bosses) | OK |
| Weapons (road) | 17 incl. relics | Good |
| Pets | 7 | OK |
| Events | 14 | Repeats appear after about 5 runs. Target 25+. |
| Recipes | 24 (9 weapons, 11 armour, **4 treats new**) | Good |
| Countries (Isle) | 7 with 7 biomes | Wide. T3–T5 have little reason to visit yet. |
| Villagers | 4, with **4 requests each** (was 3) | The chains end after about 5 hours of play. |
| Quests | 10 (one-time) | No repeatable goals except the Bestiary (new). |
| Road regions | 1 (Hollow Road, 42 tiles + boss) | **The biggest content gap.** The GDD lists 6 regions. |

Session length (bots): 11–18 minutes per road run, on target.

---

## 5. Economy

- Faucets per road win: about 95 embers, 2–4 Grave Dice, 1–2 Star Dust. Isle trip: about 150–200 embers plus materials.
- Sinks: buildings 1,300 embers, stars about 300 embers per SR item, recipes 10–160 embers, and now villager deliveries and treats.
- The bot campaign earns 91–124 embers per run and maxes all 11 building levels in about 20 runs. **Buildings are done too early for a long-lived game.** Stars and gear carry the late game.
- The gacha is fair: everything is earnable, odds are shown, pity is 4, there are no duplicate stat boosts, and story heroes are free (villager rewards). Keep it this way.

---

## 6. Balance (from `docs/playtests/v3.0/report.md`, not changed by 3.1)

| Bot | Win rate | Target | Notes |
|---|---|---|---|
| newbie | 72% | 65–75% | ✅ |
| tactician | 84% | about 90% | ❌ The gap is 12, the target is ≥ 15 |
| berserker | 31% | (no target) | Dies mid-board, as expected |

**Why the tactician gap is small** (reading the report): the tactician dies in fights and at the boss (25 + 21), not at elites. It takes about 7 fights per run against the newbie's 4. The extra fights pay carvings, but the attrition kills it mid/late board. Its campaign win rate also *falls* (95% → about 50%) because it climbs to Curse IV. That part is intended.
**Recommendation:** don't nerf the newbie. Give skill more room. For example, (a) let Fate overflow on a won fight become +1 rest heal % (rewards careful play), or (b) let the tactician bot avoid optional fights when party HP < 50%. That is a bot fix, not a game change, so check which one a real player would do. Rerun `tools/playtest.gd` after any change.

The 3.1 additions don't change the bots' runs: bots don't craft treats, claim Bestiary pages or deliver materials. Treats are excluded from the road's gear scaling, because they're small (one d4 face).

---

## 7. Mobile and store readiness checklist

| Item | State |
|---|---|
| Renderer `gl_compatibility`, landscape, touch emulation | ✅ |
| Export preset with `data/*.json` | ✅ |
| Package name | ❌ `com.example.curseddice`. It must change before the first upload, and it can never change afterwards |
| Version | ❌ The preset says `1.0.0` / code 1, the project says `3.0.0`. Sync them |
| Thai language and font | ❌ No `tr()` calls. The default font has no Thai glyphs, so bundle Noto Sans Thai (OFL) |
| First-time tutorial | ⚠️ Staged unlocks exist. There is no guided first fight |
| Settings (volume, language, text size) | ❌ |
| Safe save + back button + pause | ❌ (see §2) |
| Privacy policy, Data safety form, content rating | ❌ No data is collected and `internet=false`, so this is easy |
| Google Play closed test (new personal accounts: 12 testers × 14 days) | ❌ Plan it early, because it takes 2+ weeks of calendar time |
| Target API level (Play requires a recent one) | Check the Godot 4.3+ template default when exporting |
| Low-end device performance test | ❌ Not done (see the data-loading risk) |

---

## 8. What I added in this pass (3.1, part 1)

1. **Villagers ask for Isle materials**: `data/villagers.json` gets a 4th request per villager. A new goal scope `"deliver"` in `profile.gd` counts what is in Storage and hands it over on claim. Old saves keep their `npc_step` indexes, because the requests were appended. The UI and CLI show the progress and a "counts what is in Storage" note.
2. **Bestiary**: `data/bestiary.json` (lore for all 23 monsters, plus milestone ladders for common/elite/boss). `Profile.bestiary_entries() / claim_bestiary()` add a new saved field `bestiary_claimed`, which defaults to `{}`. The page is in the town's Quests tab, and the tab title shows "(N!)" when something can be claimed. CLI: `bestiary`, `trophy <monster>`. Old saves with many kills can claim their milestones at once.
3. **Companion treats** (pet food crafting): 4 `"slot": "treat"` recipes from common materials. `Profile.feed_treat()` stores a treat as gear under `"pet:<id>"`. `Run.apply_pet_treat()` turns the pet's blank d4 face into the treat's face on the road and the Isle. A 5★ pet gets +1 on its weakest face instead. It has its own "Treats" tab in the Forge and "Feed <pet>" buttons in the Armory. CLI: `feed <pet> <uid>`.

Tests: `test_v31_delivery_requests`, `test_v31_bestiary`, `test_v31_pet_treats`, and the updated `test_villager_requests`. The total is 980 checks, 0 failed.

---

## 9. Top recommendations (ordered)

1. **Launch foundations (3.2):** safe saving, back button, settings, Thai localisation and font, tutorial, store setup. Without these, content doesn't matter.
2. **A second road region** (the "Ash Desert") using the same `run.gd` with a new `region2.json`. This is the biggest content-per-effort lever, and it's mostly data.
3. **Isle dungeons** as short board runs: reuse `run.gd` with a small 12-tile board and a material reward table. This gives T3–T5 a reason to exist.
4. **Cache `GameData` loads** before testing on a low-end phone.
5. **Close the tactician gap** with a skill-rewarding rule, not a newbie nerf.
6. **Do Corruption (GDD §9)** only after 1–5. It's a big rules change and touches every system.
