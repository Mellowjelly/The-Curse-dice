# Art & Audio Style Guide (draft)

## Visual
- **Style:** 2D pixel art, dark fantasy, candle-lit, fog, desaturated with warm accent light.
- **Palette:** limited, max 32 colours. Base: deep purples/near-blacks (#0e0b12, #1c1622, #3a2f45), bone (#d8cfc4), blood red (#8e1c1c, #b3261e), ember orange (#c2571a), tarnished gold (#c9a227), sick green (#3f6e3a), cold steel blue (#3b5876).
  Pick a final palette (e.g. build one in Aseprite) and save it as `docs/art/palette.png` / `.gpl`, then use it everywhere.
- **Sizes:**
  - Heroes and normal monsters: 48×48 px canvas
  - Bosses: 96×96 px
  - Pets: 24×24 px
  - Dice face icons: 16×16 px
  - Item and weapon icons: 24×24 px
- **Rules:** 1px dark outline (#0e0b12), light from top-left, no anti-aliasing against transparency, no gradients.
- **Animation:** idle 4 frames, attack 4–6 frames, hit 2 frames, death 4–6 frames, at 8–10 fps.
- **Display:** scaled up by whole numbers only (x2, x3), nearest-neighbour filtering (already set in project).

## Prompt template for AI pixel-art tools
```
pixel art, {SUBJECT}, dark fantasy, {SIZE}x{SIZE} sprite, side view facing right,
limited palette of muted purples, bone white, blood red and ember orange,
1px dark outline, light from top-left, transparent background, no anti-aliasing,
original character design
```

## Audio
- **Music:** slow, sparse, melancholic. Low strings, choir pads, harpsichord or music box for "fate" motifs, distant bells. Battle tracks: steady percussion, minor key, loopable 1–2 min.
- **SFX:** chunky and readable. Dice rattle and clack (the signature sound), heavy sword hits, crackling fire, wet blood magic, low gong for boss intents.
