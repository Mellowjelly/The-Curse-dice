# Cursed Dice — Project Guide for AI

## The owner
- The owner is the **director** of this game and is a **beginner**: no programming experience, working solo with an AI team.
- **Always reply to the owner in Thai.** Code, code comments and file names stay in English. In-game text is written in English and translated in `data/lang_th.json`.
- Explain what you changed in plain language, as you would to a non-programmer. Give the owner a way to see it (what to click, what to watch for).
- Work in small steps. One feature at a time, test it, then move on. Do not refactor things nobody asked about.
- When a decision is about *fun, tone or story*, offer 2–3 options with a recommendation and let the owner choose. When it is purely technical, decide yourself and say what you chose.

## The game
Dark fantasy dice adventure, 2D pixel art, for Android (Google Play) first.
The gods' Dice of Fate were shattered and cursed; the player is a "Roller" who summons heroes from the fragments.
Every hero, weapon and pet **changes the faces of your dice** — building your dice IS building your team.
Full design: `docs/GDD.md`. Read it before any design or content work.

Tone: grim, melancholy, candle-lit, hopeful only in small ways. Heroes are flawed (oathbreakers, the faithless, the hollow). Power has a price.

Monetization is NOT a goal. Gacha must be fair: all currency earnable by playing, pity system, story heroes are free.

## Tech
- **Godot 4.3+**, GDScript, renderer `gl_compatibility` (works on low-end Android and web).
- Viewport 1280×720, `canvas_items` stretch, nearest-neighbour filtering (for pixel art).

### Architecture rules
- `scripts/core/` = game rules. **No UI, no nodes**: plain `RefCounted` scripts that communicate through signals.
  This separation is deliberate: it makes rules testable and lets us add co-op multiplayer later.
- `scripts/ui/` = screens. They display state and forward clicks to core. **No game rules in UI.**
- `data/*.json` = all content (heroes, monsters, encounters). Never hard-code content in scripts.
- Use `preload()` constants rather than `class_name` for cross-script references, so headless tests work without an editor import.
- **Translation (Thai):** `data/lang_th.json` maps English text -> Thai. Any new player-facing text (UI or data) needs a Thai line there.
  UI code wraps text in `tr()` (formatted text: `tr("Round %d") % n`); data fields shown on screen are wrapped too (`tr(m["name"])`).
  Keep `%s/%d` placeholders in the same order. Hero and place names stay English. A test fails if story text has no Thai line.

### Folders
```
data/            heroes.json, monsters.json, region1.json (board, encounter pools, shop), events.json
scenes/          title.tscn (main scene), game.tscn (a run: map + combat)
scripts/core/    combat.gd (dice combat + skills), run.gd (board, events, shop, rest, carving), game_data.gd
scripts/ui/      ui_kit.gd (palette + widgets), title_screen.gd, game_screen.gd (map + panels), combat_view.gd
tools/           playtest.gd (bot playtests -> docs/playtests/<ver>/), bots/player_bot.gd (3 bot styles)
tests/           run_tests.gd (automated tests + balance simulation)
docs/            GDD.md (design), art/ (art & audio direction), screenshot.png
.claude/agents/  the AI team
```

### Playtest loop (every version)
1. `godot --headless --path . -s tools/playtest.gd -- v0.X` (bots play 300 runs per style, writes docs/playtests/v0.X/)
2. Add screenshots `screen_*.png` to that folder.
3. Ask the `playtester` agent to critique it -> `critique.md`. Fix the top issues in the next version.
Balance targets: newbie bot 65-75% wins, tactician ~90%, gap >= 15 points, session 12-20 min.

### Commands
- Run tests (must pass before calling any change done):
  `tools/run_tests.sh` (wraps `godot --headless --path . -s tests/run_tests.gd` and also fails on SCRIPT ERROR)
  It also prints a naive-play balance line; mention it to the owner when balance changes.
- If `godot` is not on PATH, use the full path to the Godot executable.
- Exporting: make sure the export preset includes `data/*.json` (Export → Resources → "Filters to export non-resource files": `data/*.json`).

## Face types (current)
`attack` damage target · `fire` damage + 2 burn · `blood` big damage, costs caster 2 HP (never kills) ·
`shield` self shield · `guard` shield whole party · `heal` heal lowest-HP ally · `sweep` (monsters) hit all heroes · `blank` nothing, +1 Fate.
Combos: 2 of a type = +1 each, 3 = double. Fate (max 5, from blanks, combos and wins): 2 Fate = extra reroll, 4 Fate = Twist a die to any face; overflow = free reroll.
Skills: heroes gain +1 charge per round (+1 more if their face is in a combo); a skill is used during planning when charge = cost.
Skill effects are matched by `skill.id` in `combat.gd` (`use_skill`); numbers are constants at the top of that file.
Every skill has a dark price. Adding a skill = data entry in heroes.json + a `match` branch + a test.
Adding a face type = update `GameData.FACE_TYPES`, `combat.gd`, the UI colour/name tables, a test, and the GDD.

## The AI team (`.claude/agents/`)
| Agent | Use for |
|---|---|
| `game-designer` | mechanics, numbers, balance, new heroes/monsters/weapons/pets (edits `data/` and `docs/GDD.md`) |
| `programmer` | implementing features and fixing bugs in GDScript |
| `writer` | lore, names, dialogue, item descriptions |
| `art-director` | pixel art specs and prompts for AI art tools, palette, music & SFX briefs |
| `qa-tester` | running tests, writing tests, hunting bugs, balance reports |
| `playtester` | panel of 4 personas critiquing bot playtest reports |
| `game-player` | an AI player that really plays through `tools/play_cli.gd` and keeps a diary |
| `game-critic` | professional critique of a player's diary -> ranked improvements |
| `game-developer` | senior dev: analyses the whole game, adds missing pieces, writes `docs/ROADMAP.md` |

Text interface for playing the whole game (used by `game-player`): `godot --headless --path . -s tools/play_cli.gd -- session.txt [tail]`
(one command per line; the session is replayed each run because the game is deterministic; `help` lists commands).

For a new feature the usual order is: game-designer → programmer → qa-tester.

## Git
Commit after each working step with a short English message describing what changed.
