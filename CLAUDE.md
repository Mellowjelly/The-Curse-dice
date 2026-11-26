# Cursed Dice — Project Guide for AI

## The owner
- The owner is the **director** of this game and is a **beginner**: no programming experience, working solo with an AI team.
- **Always reply to the owner in Thai.** Code, code comments, file names and in-game text stay in English (Thai localization comes later).
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

### Folders
```
data/            heroes.json, monsters.json, encounters.json  (content - designers edit these)
scenes/          title.tscn (main scene), combat.tscn
scripts/core/    combat.gd (dice combat rules + hero skills), game_data.gd (JSON loading)
scripts/ui/      title_screen.gd, combat_screen.gd
tests/           run_tests.gd (automated tests + balance simulation)
docs/            GDD.md (design), art/ (art & audio direction), screenshot.png
.claude/agents/  the AI team
```

### Commands
- Run tests (must pass before calling any change done):
  `godot --headless --path . -s tests/run_tests.gd`
  It also prints a naive-play balance line; mention it to the owner when balance changes.
- If `godot` is not on PATH, use the full path to the Godot executable.
- Exporting: make sure the export preset includes `data/*.json` (Export → Resources → "Filters to export non-resource files": `data/*.json`).

## Face types (current)
`attack` damage target · `fire` damage + 2 burn · `blood` big damage, costs caster 2 HP (never kills) ·
`shield` self shield · `guard` shield whole party · `heal` heal lowest-HP ally · `sweep` (monsters) hit all heroes · `blank` nothing, +1 Fate.
Combos: 2 of a type = +1 each, 3 = double. Fate (max 5): 3 Fate buys an extra reroll.
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

For a new feature the usual order is: game-designer → programmer → qa-tester.

## Git
Commit after each working step with a short English message describing what changed.
