# Asset List — Batch 1

> **v1.1:** placeholder pixel sprites for all 6 heroes, 7 monsters and the boss (normal + enraged) are now drawn in code by
> `tools/make_sprites.py` → `assets/sprites/<id>.png` (3 frames side by side: idle A, idle B, attack; 32x32, boss 48x48).
> To use real art, replace a PNG with the same layout (3 square frames in a row, facing right). The game picks it up automatically.
> Die-face icons: `tools/make_icons.py` → `assets/icons/`.

Status: `todo` → `generated` → `cleaned` (fixed in Aseprite) → `in game`
Before shipping any asset: confirm the AI tool's plan allows **commercial use** and fill in the "Tool / plan" column.

## วิธีใช้ (สำหรับเจ้าของเกม)
1. คัดลอก **Base prompt** ด้านล่าง แล้วต่อท้ายด้วย prompt ของชิ้นงานที่ต้องการ วางลงในเครื่องมือวาดภาพพิกเซลด้วย AI
2. ตั้งขนาดภาพตามคอลัมน์ Size
3. สุ่มหลาย ๆ ครั้ง แล้วเลือกภาพที่ดีที่สุด
4. เปิดใน Aseprite: ลดสีให้ตรงพาเลต, ลบพิกเซลแปลก ๆ, ทำให้พื้นหลังโปร่งใส, เติมเส้นขอบดำ 1px
5. เซฟเป็น `.png` ตามชื่อไฟล์ในตาราง ลงโฟลเดอร์ `assets/sprites/` แล้วบอก AI ให้ใส่เข้าเกม

**Base prompt (ต้องใส่ทุกครั้ง):**
```
pixel art sprite, dark fantasy, limited palette of muted purples, near-black, bone white,
blood red and ember orange, 1px dark outline, light from top-left, transparent background,
no anti-aliasing, crisp pixels, original character design,
```

## Heroes (48×48, side view facing right, idle pose)
| File | Prompt (append to base) | Status | Tool / plan |
|---|---|---|---|
| `hero_varek.png` | `a tall knight in dented black plate armor, broken chain hanging from his neck, cracked tower shield, tattered red cape, helmet with a split visor, weary stance` | todo | |
| `hero_lys.png` | `a thin pale sorceress in a hooded ash-grey robe, hollow glowing orange eyes, ember flames floating above one hand, cracked porcelain skin on her cheek` | todo | |
| `hero_aldric.png` | `a gaunt middle-aged priest in a frayed brown monk robe, an upside-down holy symbol on a cord, bandaged hands holding a dim lantern, sorrowful face` | todo | |

## Monsters (48×48, side view facing LEFT)
| File | Prompt (append to base) | Status | Tool / plan |
|---|---|---|---|
| `mon_ghoul.png` | `a hunched grey-green ghoul, long clawed fingers, torn burial rags, hungry open jaw` | todo | |
| `mon_cultist.png` | `a robed cultist covered in grey ash, a cracked clay mask, holding a smoking censer` | todo | |
| `mon_bone_hound.png` | `a skeletal hound made of yellowed bones, red ember glowing inside its ribcage, snarling` | todo | |

## Boss (96×96, facing LEFT)
| File | Prompt (append to base) | Status | Tool / plan |
|---|---|---|---|
| `boss_rotting_bishop.png` | `a towering corrupted bishop, rotting flesh under torn golden vestments, a mitre fused to his skull, holding a crozier dripping black ichor, flies around him, menacing` | todo | |

## Dice face icons (16×16, simple symbol, centered)
| File | Prompt (append to base) |
|---|---|
| `face_attack.png` | `icon of a short sword pointing up` |
| `face_fire.png` | `icon of a small orange flame` |
| `face_blood.png` | `icon of a single dark red blood drop` |
| `face_shield.png` | `icon of a steel kite shield` |
| `face_guard.png` | `icon of two overlapping shields` |
| `face_heal.png` | `icon of a green glowing cross` |
| `face_sweep.png` | `icon of a curved purple slash arc` |
| `face_blank.png` | `icon of a faint cracked empty circle` |

## Title background (320×180, scaled ×4 in game)
`title_bg.png` — `pixel art landscape, dark fantasy, a ruined chapel on a hill at night, giant broken stone die half buried in the ground, fog, faint red glow on the horizon, no characters, no text`

## Audio briefs
| File | Brief |
|---|---|
| `music_title.ogg` | Slow, melancholic. Solo cello + distant choir pad + music box motif. 70 BPM, minor key, 1–2 min loop. |
| `music_battle.ogg` | Tense, steady low drums, plucked strings, minor key, 100 BPM, 1–2 min seamless loop. |
| `music_boss.ogg` | Heavy: organ, choir, pounding drums, dissonant brass hits, 110 BPM loop. |
| `sfx_dice_roll.wav` | Bone dice rattling in a cup and clattering on wood, ~0.6 s. The signature sound: make it satisfying. |
| `sfx_hit.wav` | Heavy sword hit on flesh/armor, short. |
| `sfx_fire.wav` | Whoosh + crackle, ~0.5 s. |
| `sfx_skill.wav` | Deep magical swell with a bell, ~1 s. |
