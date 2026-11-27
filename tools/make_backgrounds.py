"""Draws battle backgrounds, the world map and map tile icons (run: python3 tools/make_backgrounds.py).

Original pixel art drawn from shapes in code:
  assets/backgrounds/battle_early.png  (dead forest, moon)      320x180
  assets/backgrounds/battle_mid.png    (graveyard)              320x180
  assets/backgrounds/battle_late.png   (burning village ruins)  320x180
  assets/backgrounds/battle_boss.png   (inside the Chapel of Rot) 320x180
  assets/backgrounds/map.png           (The Hollow Road)        320x180 (game scales x4)
  assets/backgrounds/map_<dungeon>.png (3.7: each Isle dungeon's own board) 320x180
  assets/icons/tile_<type>.png         16x16 map icons
"""
import math
import os
import random
from PIL import Image, ImageDraw

W, H = 320, 180
BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def sky(img, top, bottom, y0=0, y1=H, bands=6):
    """Banded gradient with ordered dithering between bands (classic pixel-art sky)."""
    px = img.load()
    for y in range(y0, y1):
        t = (y - y0) / max(1, y1 - y0 - 1) * (bands - 1)
        band = int(t)
        frac = t - band
        c0 = lerp(top, bottom, band / (bands - 1))
        c1 = lerp(top, bottom, min(1, (band + 1) / (bands - 1)))
        for x in range(img.width):
            px[x, y] = c1 if frac * 16 > BAYER[y % 4][x % 4] else c0


def ridge(d, rng, base, rough, color, step=4, w=W):
    """Filled silhouette of hills from a random-walk height line."""
    pts = [(0, H)]
    h = base
    for x in range(0, w + step, step):
        h += rng.randint(-rough, rough)
        h = max(base - 3 * rough, min(base + 2 * rough, h))
        pts.append((x, h))
    pts.append((w, H))
    d.polygon(pts, fill=color)


def dead_tree(d, x, ground, height, color, rng):
    d.line([(x, ground), (x, ground - height)], fill=color, width=2)
    for i in range(4):
        y = ground - height + i * height // 5 + rng.randint(0, 3)
        dx = rng.choice([-1, 1]) * rng.randint(4, 10)
        d.line([(x, y), (x + dx, y - rng.randint(3, 8))], fill=color, width=1)
        d.line([(x + dx, y - 4), (x + dx + dx // 3, y - 9)], fill=color, width=1)


def fog(img, rng, y_center, color, alpha, count=14):
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ld = ImageDraw.Draw(layer)
    for _ in range(count):
        x = rng.randint(-40, W)
        y = y_center + rng.randint(-8, 8)
        ld.ellipse([x, y, x + rng.randint(50, 110), y + rng.randint(6, 12)], fill=color + (alpha,))
    img.alpha_composite(layer)


def stars(img, rng, n, ymax):
    px = img.load()
    for _ in range(n):
        x, y = rng.randint(0, W - 1), rng.randint(0, ymax)
        px[x, y] = (200, 190, 210, 255)


# ---------------------------------------------------------------- battle backgrounds

def battle_early():
    rng = random.Random(1)
    img = Image.new("RGBA", (W, H))
    sky(img, (12, 10, 26), (58, 40, 70), 0, 120)
    stars(img, rng, 40, 70)
    d = ImageDraw.Draw(img)
    d.ellipse([230, 18, 262, 50], fill=(222, 214, 190))                 # moon
    d.ellipse([238, 22, 266, 48], fill=(40, 30, 52))                    # crescent bite
    ridge(d, rng, 110, 3, (34, 26, 44))                                 # far hills
    for x in range(10, W, 23):
        dead_tree(d, x + rng.randint(-5, 5), 118, rng.randint(25, 45), (26, 20, 34), rng)
    ridge(d, rng, 128, 2, (22, 17, 28))
    d.rectangle([0, 140, W, H], fill=(28, 22, 26))                      # road
    for x in range(0, W, 7):
        d.point((x + rng.randint(0, 4), 141 + rng.randint(0, 30)), fill=(44, 36, 40))
    fog(img, rng, 125, (120, 110, 140), 40)
    return img


def battle_mid():
    rng = random.Random(2)
    img = Image.new("RGBA", (W, H))
    sky(img, (16, 18, 24), (60, 64, 60), 0, 125)
    d = ImageDraw.Draw(img)
    d.ellipse([40, 20, 66, 46], fill=(170, 180, 160))                   # sick moon
    ridge(d, rng, 112, 2, (32, 36, 36))
    # ruined chapel silhouette in the distance
    d.rectangle([200, 70, 240, 112], fill=(24, 26, 28)); d.polygon([(214, 50), (220, 30), (226, 50)], fill=(24, 26, 28))
    d.rectangle([214, 50, 226, 70], fill=(24, 26, 28)); d.point((220, 60), fill=(220, 170, 60))
    ridge(d, rng, 124, 1, (26, 30, 28))
    for i in range(16):                                                 # tombstones and crosses
        x = 8 + i * 20 + rng.randint(-4, 4)
        y = 128 + rng.randint(-3, 6)
        if rng.random() < 0.4:
            d.rectangle([x + 3, y - 14, x + 5, y], fill=(70, 72, 76)); d.rectangle([x, y - 10, x + 8, y - 8], fill=(70, 72, 76))
        else:
            d.rounded_rectangle([x, y - 12, x + 9, y], radius=4, fill=(80, 82, 88))
            d.line([(x + 2, y - 7), (x + 7, y - 7)], fill=(50, 52, 56))
    d.rectangle([0, 138, W, H], fill=(30, 34, 30))
    for x in range(0, W, 5):
        d.line([(x, 138), (x + rng.randint(-1, 1), 135)], fill=(46, 56, 42))
    fog(img, rng, 130, (140, 160, 140), 45, 18)
    return img


def battle_late():
    rng = random.Random(3)
    img = Image.new("RGBA", (W, H))
    sky(img, (20, 8, 12), (140, 50, 24), 0, 125)                        # burning sky
    d = ImageDraw.Draw(img)
    ridge(d, rng, 108, 2, (40, 16, 18))
    for i in range(6):                                                  # ruined houses
        x = 10 + i * 54 + rng.randint(-6, 6)
        w, h = rng.randint(26, 38), rng.randint(22, 34)
        base = 130
        d.rectangle([x, base - h, x + w, base], fill=(30, 14, 16))
        d.polygon([(x - 3, base - h), (x + w // 2, base - h - 14), (x + w + 3, base - h)], fill=(30, 14, 16))
        bite = rng.randint(4, 12)
        d.polygon([(x + w // 2, base - h - 14), (x + w + 3, base - h), (x + w // 2 + bite, base - h + bite)], fill=(110, 40, 24))
        for wx in range(x + 4, x + w - 4, 9):
            d.rectangle([wx, base - h + 8, wx + 3, base - h + 12], fill=(250, 170, 60))
        for f in range(5):                                              # flames
            fx = x + rng.randint(0, w)
            d.polygon([(fx - 3, base - h + 2), (fx, base - h - rng.randint(6, 14)), (fx + 3, base - h + 2)], fill=(240, 120, 40))
    d.rectangle([0, 134, W, H], fill=(26, 14, 14))
    for _ in range(60):                                                 # embers
        d.point((rng.randint(0, W - 1), rng.randint(20, 130)), fill=(255, rng.randint(140, 220), 80))
    fog(img, rng, 118, (60, 30, 30), 70, 12)                            # smoke
    return img


def battle_boss():
    rng = random.Random(4)
    img = Image.new("RGBA", (W, H), (18, 14, 22, 255))
    d = ImageDraw.Draw(img)
    for y in range(0, 140, 8):                                          # stone bricks
        off = 0 if (y // 8) % 2 == 0 else 8
        for x in range(-16, W, 16):
            c = rng.choice([(34, 28, 38), (30, 25, 34), (38, 31, 42)])
            d.rectangle([x + off + 1, y + 1, x + off + 15, y + 7], fill=c)
    for cx in (60, 160, 260):                                           # stained glass windows
        d.rectangle([cx - 14, 20, cx + 14, 90], fill=(14, 10, 18))
        d.ellipse([cx - 14, 8, cx + 14, 36], fill=(14, 10, 18))
        cols = [(150, 30, 40), (40, 60, 140), (180, 140, 40), (60, 110, 60)]
        for gy in range(14, 88, 6):
            for gx in range(cx - 12, cx + 12, 6):
                if (gx - cx) ** 2 / 144 + max(0, 22 - gy) ** 2 / 196 <= 1.2:
                    d.rectangle([gx, gy, gx + 4, gy + 4], fill=rng.choice(cols))
        d.line([(cx, 10), (cx, 90)], fill=(14, 10, 18), width=2)
    for px_ in (12, 110, 210, 308):                                     # pillars
        d.rectangle([px_ - 6, 0, px_ + 6, 140], fill=(46, 40, 52)); d.rectangle([px_ - 6, 0, px_ - 3, 140], fill=(60, 52, 66))
    d.rectangle([0, 132, W, H], fill=(26, 20, 28))                      # floor
    for x in range(0, W, 20):
        d.line([(x, 132), (x - 30, H)], fill=(34, 28, 36))
    d.rectangle([130, 112, 190, 132], fill=(54, 44, 40)); d.rectangle([128, 110, 192, 113], fill=(140, 110, 40))  # altar
    for x in (126, 140, 180, 194, 40, 280):                             # candles
        d.rectangle([x, 104, x + 2, 112], fill=(220, 210, 190)); d.point((x + 1, 102), fill=(255, 220, 90)); d.point((x + 1, 103), fill=(240, 130, 40))
    for _ in range(40):                                                 # rot on the floor
        d.point((rng.randint(0, W - 1), rng.randint(134, H - 1)), fill=(70, 90, 50))
    return img


# ---------------------------------------------------------------- world map (game draws the road and tiles on top)

def world_map():
    rng = random.Random(9)
    img = Image.new("RGBA", (W, H))
    sky(img, (22, 18, 28), (34, 28, 36), 0, 24, 4)
    d = ImageDraw.Draw(img)
    # biome regions follow the road rows; borders wave so it reads as land, not stripes
    biomes = [  # (base border y, colour, colour variation)
        (22, (30, 40, 30)),    # dead forest
        (42, (46, 48, 32)),    # withered fields
        (63, (38, 40, 46)),    # graveyard moor
        (83, (54, 30, 26)),    # burning ruins
        (103, (38, 24, 40)),   # the chapel hill
    ]
    px = img.load()
    for x in range(W):
        borders = [y0 + 3 * math.sin(x / 17 + i * 2) + 2 * math.sin(x / 6.5 + i) for i, (y0, _) in enumerate(biomes)]
        for y in range(22, 132):
            idx = 0
            for i, by in enumerate(borders):
                if y >= by:
                    idx = i
            c = biomes[idx][1]
            n = (math.sin(x * 0.9 + y * 1.7) + math.sin(x * 0.31 - y * 0.53)) * 3
            px[x, y] = tuple(max(0, min(255, int(v + n))) for v in c) + (255,)
    # mountains along the top edge
    for i in range(10):
        x = i * 36 + rng.randint(-8, 8)
        top = 2 + rng.randint(0, 8)
        d.polygon([(x - 26, 26), (x, top), (x + 26, 26)], fill=(46, 40, 54))
        d.polygon([(x, top), (x + 26, 26), (x + 8, 26)], fill=(36, 31, 44))
        d.polygon([(x - 5, top + 6), (x, top), (x + 5, top + 6)], fill=(160, 155, 170))
    # dead forest: pines and bare trees
    for _ in range(90):
        x, y = rng.randint(0, W), rng.randint(26, 44)
        if rng.random() < 0.6:
            d.polygon([(x - 3, y + 6), (x, y - 3), (x + 3, y + 6)], fill=rng.choice([(20, 30, 24), (26, 36, 28)]))
        else:
            d.line([(x, y + 6), (x, y)], fill=(44, 34, 30)); d.point((x - 1, y + 1), fill=(44, 34, 30)); d.point((x + 1, y + 2), fill=(44, 34, 30))
    # withered fields: hay and a winding river
    for _ in range(60):
        x, y = rng.randint(0, W), rng.randint(46, 62)
        d.point((x, y), fill=(84, 78, 46))
    pts = [(x, 54 + 5 * math.sin(x / 23) + 2 * math.sin(x / 7)) for x in range(0, W + 4, 4)]
    d.line(pts, fill=(34, 56, 70), width=3)
    d.line([(x, y - 1) for x, y in pts], fill=(60, 90, 104), width=1)
    # graveyard moor: tombstones and crosses
    for _ in range(40):
        x, y = rng.randint(2, W - 4), rng.randint(66, 82)
        if rng.random() < 0.5:
            d.rectangle([x, y, x + 2, y + 3], fill=(100, 102, 110))
        else:
            d.line([(x + 1, y - 1), (x + 1, y + 3)], fill=(90, 92, 100)); d.line([(x, y), (x + 2, y)], fill=(90, 92, 100))
    # burning ruins: broken houses with fire
    for _ in range(18):
        x, y = rng.randint(2, W - 10), rng.randint(86, 101)
        d.rectangle([x, y, x + 6, y + 4], fill=(28, 14, 14)); d.polygon([(x - 1, y), (x + 3, y - 3), (x + 7, y)], fill=(28, 14, 14))
        d.point((x + 3, y - 4), fill=(250, 150, 50)); d.point((x + 2, y - 2), fill=(240, 100, 40)); d.point((x + 2, y + 2), fill=(250, 200, 90))
    # Ashfall village (start) in the top-left corner
    for hx in (2, 12, 22):
        d.rectangle([hx, 16, hx + 7, 22], fill=(64, 46, 34)); d.polygon([(hx - 1, 16), (hx + 3, 11), (hx + 8, 16)], fill=(100, 42, 30))
        d.point((hx + 3, 19), fill=(250, 200, 90))
    # the Chapel of Rot on its hill (bottom)
    cx = 98  # just right of the boss tile
    d.ellipse([cx - 40, 112, cx + 40, 140], fill=(30, 20, 32))
    d.rectangle([cx - 13, 104, cx + 13, 126], fill=(22, 16, 26)); d.polygon([(cx - 5, 104), (cx, 84), (cx + 5, 104)], fill=(22, 16, 26))
    d.ellipse([cx - 4, 109, cx + 4, 117], fill=(170, 40, 40)); d.point((cx, 83), fill=(201, 162, 39))
    for _ in range(12):
        d.point((rng.randint(cx - 30, cx + 30), rng.randint(112, 128)), fill=(90, 110, 60))
    # the dark below, where the party panel sits
    d.rectangle([0, 130, W, H], fill=(18, 14, 20))
    vig = Image.new("RGBA", img.size, (0, 0, 0, 0))
    vd = ImageDraw.Draw(vig)
    for i in range(12):
        vd.rectangle([i, i, W - 1 - i, H - 1 - i], outline=(0, 0, 0, 130 - i * 10))
    img.alpha_composite(vig)
    return img



# ---------------------------------------------------------------- Isle dungeon boards (3.7)
# A dungeon board is 13 tiles: row 1 runs along art y ~30, row 2 (tiles 10-12) along y ~50 on the right,
# so the boss tile sits near (215, 50). The lair is drawn just below-left of it; the open floor
# below the road carries each dungeon's own scenery. The dark band from y 130 is under the party panel.

def _dungeon_base(rng, wall, wall_d, floor, floor_d, slab=True):
    img = Image.new("RGBA", (W, H))
    sky(img, wall_d, wall, 0, 20, 4)                       # the back wall
    d = ImageDraw.Draw(img)
    px = img.load()
    for y in range(20, 130):                               # the floor, darker towards the back
        t = (y - 20) / 110
        c = lerp(floor_d, floor, t)
        for x in range(W):
            n = (math.sin(x * 0.7 + y * 1.3) + math.sin(x * 0.23 - y * 0.41)) * 2
            px[x, y] = tuple(max(0, min(255, int(v + n))) for v in c) + (255,)
    if slab:                                               # flagstone joints
        for y in range(24, 130, 9):
            d.line([(0, y), (W, y)], fill=floor_d)
            off = 0 if (y // 9) % 2 else 7
            for x in range(off, W, 14):
                d.line([(x, y), (x, y + 8)], fill=floor_d)
    d.line([(0, 19), (W, 19)], fill=(10, 8, 12))
    return img, d


def _arches(d, color, inner, step=32, top=3):
    for x in range(8, W, step):                            # arched windows / niches in the back wall
        d.rectangle([x, top + 5, x + 12, 18], fill=color)
        d.pieslice([x, top, x + 12, top + 10], 180, 360, fill=color)
        d.rectangle([x + 2, top + 6, x + 10, 18], fill=inner)
        d.pieslice([x + 2, top + 2, x + 10, top + 10], 180, 360, fill=inner)


def _pillar(d, x, y, h, color, dark, cap):
    d.rectangle([x, y - h, x + 7, y], fill=color)
    d.rectangle([x + 5, y - h, x + 7, y], fill=dark)
    d.rectangle([x - 1, y - h - 2, x + 8, y - h], fill=cap)
    d.rectangle([x - 1, y, x + 8, y + 2], fill=cap)


def _finish(img):
    d = ImageDraw.Draw(img)
    d.rectangle([0, 130, W, H], fill=(14, 11, 16))
    vig = Image.new("RGBA", img.size, (0, 0, 0, 0))
    vd = ImageDraw.Draw(vig)
    for i in range(14):
        vd.rectangle([i, i, W - 1 - i, H - 1 - i], outline=(0, 0, 0, 150 - i * 10))
    img.alpha_composite(vig)
    return img


def map_sunken_abbey():
    """The Sunken Abbey: a flooded nave, pews in the water, the drowned altar and its bell."""
    rng = random.Random(31)
    img, d = _dungeon_base(rng, (52, 60, 64), (30, 36, 40), (64, 74, 72), (42, 50, 50))
    _arches(d, (70, 80, 82), (16, 26, 34))
    water = Image.new("RGBA", img.size, (0, 0, 0, 0))     # the tide over the lower nave
    wd = ImageDraw.Draw(water)
    for y in range(58, 130):
        wd.line([(0, y), (W, y)], fill=(30, 70, 90, min(200, 60 + (y - 58) * 2)))
    img.alpha_composite(water)
    d = ImageDraw.Draw(img)
    for y in range(62, 128, 6):                            # ripples
        for _ in range(5):
            x = rng.randint(0, W - 12)
            d.line([(x, y), (x + rng.randint(4, 10), y)], fill=(90, 140, 150))
    for row in range(3):                                   # half-sunk pews
        for col in range(4):
            x, y = 14 + col * 40 + row * 6, 70 + row * 18
            d.rectangle([x, y, x + 26, y + 3], fill=(58, 44, 34)); d.rectangle([x, y - 5, x + 2, y + 3], fill=(58, 44, 34))
    for x in (6, 164, 300):
        _pillar(d, x, 120, 54, (92, 100, 98), (66, 72, 72), (110, 118, 116))
    cx, cy = 214, 86                                       # the drowned altar under the boss tile
    d.rectangle([cx - 18, cy, cx + 18, cy + 10], fill=(84, 90, 88)); d.rectangle([cx - 14, cy - 4, cx + 14, cy], fill=(104, 110, 108))
    d.line([(cx, cy - 30), (cx, cy - 12)], fill=(40, 36, 30)); d.ellipse([cx - 6, cy - 14, cx + 6, cy - 2], fill=(176, 140, 70))
    d.point((cx, cy - 1), fill=(220, 190, 110))
    for x in range(cx - 30, cx + 30, 3):                   # black coral at its foot
        if rng.random() < 0.5:
            d.line([(x, cy + 12), (x + rng.randint(-1, 1), cy + 12 - rng.randint(2, 6))], fill=(20, 18, 26))
    for _ in range(14):                                    # candles still floating
        x, y = rng.randint(10, W - 10), rng.randint(64, 126)
        d.point((x, y), fill=(240, 210, 120)); d.point((x, y + 1), fill=(200, 190, 170))
    return _finish(img)


def map_slag_cathedral():
    """The Slag Cathedral: an iron floor split by channels of molten slag, iron pillars, the pouring altar."""
    rng = random.Random(41)
    img, d = _dungeon_base(rng, (48, 36, 36), (24, 18, 20), (52, 44, 46), (32, 26, 28))
    _arches(d, (60, 46, 44), (90, 34, 18))
    for i in range(2):                                     # glowing channels of slag across the floor
        base = 74 + i * 30
        pts = [(x, base + 4 * math.sin(x / 19 + i * 3) + 2 * math.sin(x / 7)) for x in range(0, W + 4, 4)]
        d.line(pts, fill=(120, 30, 14), width=6)
        d.line(pts, fill=(230, 100, 30), width=3)
        d.line([(x, y - 1) for x, y in pts], fill=(255, 200, 90), width=1)
    for _ in range(30):                                    # embers
        x, y = rng.randint(0, W), rng.randint(22, 128)
        d.point((x, y), fill=rng.choice([(250, 150, 50), (230, 90, 30), (255, 210, 120)]))
    for x in (8, 72, 150, 296):
        _pillar(d, x, 124, 50, (70, 58, 60), (46, 38, 42), (90, 76, 76))
        d.line([(x + 2, 100), (x + 3, 112)], fill=(240, 130, 40))   # a molten seam
    cx, cy = 214, 88                                       # the pouring altar: a great iron ladle over a basin
    d.ellipse([cx - 24, cy + 2, cx + 24, cy + 16], fill=(60, 20, 12)); d.ellipse([cx - 18, cy + 4, cx + 18, cy + 13], fill=(240, 120, 30))
    d.ellipse([cx - 10, cy + 6, cx + 10, cy + 11], fill=(255, 200, 90))
    d.line([(cx - 30, cy - 28), (cx - 6, cy - 6)], fill=(40, 32, 34), width=3)
    d.pieslice([cx - 12, cy - 14, cx + 6, cy + 2], 0, 180, fill=(52, 42, 44))
    d.line([(cx - 3, cy + 1), (cx - 3, cy + 6)], fill=(255, 170, 60), width=2)    # the iron still pouring
    return _finish(img)


def map_marrow_vault():
    """The Marrow Vault: shelves of labelled bones along the walls, a dust floor, the toll-stone and ledger."""
    rng = random.Random(51)
    img, d = _dungeon_base(rng, (70, 62, 56), (40, 34, 32), (92, 82, 72), (58, 50, 46), slab=False)
    for x in range(0, W, 2):                               # the back wall is all skulls, row on row
        for y in range(3, 18, 5):
            if (x // 2 + y) % 3 == 0:
                d.ellipse([x, y, x + 3, y + 3], fill=(104, 96, 84)); d.point((x + 1, y + 2), fill=(30, 26, 26))  # dim, so the header reads
    for sx, sy in ((6, 64), (6, 96), (250, 104), (120, 70), (120, 104)):    # free-standing bone shelves
        d.rectangle([sx, sy, sx + 60, sy + 20], fill=(46, 38, 34))
        for k in range(3):
            y = sy + 2 + k * 6
            d.line([(sx + 1, y + 4), (sx + 59, y + 4)], fill=(70, 60, 52))
            for bx in range(sx + 2, sx + 58, 4):
                if rng.random() < 0.8:
                    d.line([(bx, y + 1), (bx + 2, y + 3)], fill=(214, 204, 184))
            d.point((sx + 4 + k * 17, y), fill=(240, 230, 200))           # a little paper label
    for _ in range(80):                                    # dust and stray bones on the floor
        x, y = rng.randint(0, W), rng.randint(24, 128)
        d.point((x, y), fill=rng.choice([(110, 100, 88), (200, 190, 170)]))
    cx, cy = 206, 86                                       # the toll-stone, the ledger and a candle
    d.rectangle([cx - 14, cy, cx + 14, cy + 12], fill=(96, 90, 86)); d.rectangle([cx - 14, cy, cx + 14, cy + 2], fill=(120, 114, 108))
    d.rectangle([cx - 8, cy - 4, cx + 8, cy], fill=(110, 30, 30)); d.line([(cx, cy - 4), (cx, cy)], fill=(70, 16, 16))
    d.line([(cx - 6, cy - 3), (cx - 2, cy - 3)], fill=(230, 220, 190)); d.line([(cx + 2, cy - 3), (cx + 6, cy - 3)], fill=(230, 220, 190))
    d.rectangle([cx + 16, cy - 6, cx + 17, cy], fill=(220, 210, 190)); d.point((cx + 16, cy - 7), fill=(250, 200, 90))
    d.point((cx, cy + 7), fill=(170, 120, 230)); d.point((cx + 1, cy + 6), fill=(200, 160, 250))   # the fate fragment
    return _finish(img)


# ---------------------------------------------------------------- the town of Ashfall
# Building rectangles (art pixels, x4 on screen). town_screen.gd uses the same numbers for hotspots.
TOWN_BUILDINGS = {
    "chapel": (6, 34, 36, 104),
    "smithy": (40, 62, 70, 104),
    "carver": (74, 70, 98, 104),
    "fortune": (102, 72, 126, 104),
    "kennel": (130, 84, 150, 104),
    "market": (112, 116, 156, 142),
}


def town(day=False):
    rng = random.Random(21)
    img = Image.new("RGBA", (W, H))
    if day:
        sky(img, (96, 140, 190), (196, 206, 200), 0, 100)
    else:
        sky(img, (10, 8, 22), (52, 34, 54), 0, 100)
        stars(img, rng, 50, 60)
    d = ImageDraw.Draw(img)
    if day:
        d.ellipse([128, 10, 146, 28], fill=(252, 236, 170)); d.ellipse([131, 13, 143, 25], fill=(255, 250, 220))   # sun
        for cx, cy in ((40, 22), (90, 14), (200, 26), (270, 12)):
            for k in range(4):
                d.ellipse([cx + k * 7, cy - (3 if k % 2 else 0), cx + k * 7 + 14, cy + 7], fill=(236, 238, 240))  # clouds
    else:
        d.ellipse([126, 12, 144, 30], fill=(226, 218, 196)); d.ellipse([131, 11, 147, 28], fill=(26, 20, 40))   # crescent moon
    for i in range(9):                                                   # mountains
        x = i * 40 + rng.randint(-10, 10)
        top = 34 + rng.randint(0, 12)
        d.polygon([(x - 30, 80), (x, top), (x + 30, 80)], fill=(110, 120, 140) if day else (34, 28, 44))
        d.polygon([(x - 5, top + 7), (x, top), (x + 5, top + 7)], fill=(240, 240, 248) if day else (120, 112, 136))
    ridge(d, rng, 92, 2, (70, 96, 64) if day else (26, 20, 32))
    # far houses on the right (behind the UI panel)
    for i in range(9):
        x = 160 + i * 18 + rng.randint(-3, 3)
        h = rng.randint(14, 24)
        d.rectangle([x, 100 - h, x + 14, 104], fill=(118, 96, 84) if day else (30, 22, 30))
        d.polygon([(x - 2, 100 - h), (x + 7, 92 - h), (x + 16, 100 - h)], fill=(120, 58, 46) if day else (44, 26, 30))
        if rng.random() < 0.6:
            d.rectangle([x + 5, 104 - h + 6, x + 7, 104 - h + 9], fill=(60, 50, 56) if day else (230, 170, 70))
    # the town wall and the gate to the Hollow Road
    wall = (128, 120, 118) if day else (48, 42, 50)
    d.rectangle([160, 96, W, 106], fill=wall)
    for x in range(160, W, 6):
        d.rectangle([x, 92, x + 3, 96], fill=wall)
    d.rectangle([286, 84, 310, 106], fill=(108, 100, 100) if day else (40, 34, 44)); d.rectangle([292, 92, 304, 106], fill=(12, 8, 14))
    # cobbled square
    d.rectangle([0, 104, W, H], fill=(92, 84, 80) if day else (40, 34, 38))
    for y in range(106, H, 4):
        off = (y // 4) % 2 * 3
        for x in range(-3, W, 6):
            stones = [(110, 100, 94), (102, 94, 88), (118, 108, 100)] if day else [(48, 41, 44), (44, 38, 42), (52, 45, 46)]
            d.rectangle([x + off, y, x + off + 4, y + 2], fill=rng.choice(stones))
    # --- the six buildings ---
    x0, y0, x1, y1 = TOWN_BUILDINGS["chapel"]                            # Ruined Chapel
    d.rectangle([x0, y0 + 26, x1, y1], fill=(62, 56, 66)); d.rectangle([x0, y0 + 26, x0 + 4, y1], fill=(76, 70, 80))
    d.polygon([(x0 - 2, y0 + 26), ((x0 + x1) // 2, y0 + 8), (x1 + 2, y0 + 26)], fill=(52, 34, 40))
    d.rectangle([(x0 + x1) // 2 - 4, y0, (x0 + x1) // 2 + 4, y0 + 20], fill=(62, 56, 66))
    d.polygon([((x0 + x1) // 2 - 6, y0), ((x0 + x1) // 2, y0 - 10), ((x0 + x1) // 2 + 6, y0)], fill=(52, 34, 40))
    d.rectangle([(x0 + x1) // 2 - 1, y0 - 16, (x0 + x1) // 2 + 1, y0 - 10], fill=(201, 162, 39))
    d.rectangle([(x0 + x1) // 2 - 3, y0 - 14, (x0 + x1) // 2 + 3, y0 - 13], fill=(201, 162, 39))
    d.ellipse([(x0 + x1) // 2 - 6, y0 + 32, (x0 + x1) // 2 + 6, y0 + 44], fill=(160, 50, 60))   # rose window
    d.rectangle([(x0 + x1) // 2 - 4, y1 - 16, (x0 + x1) // 2 + 4, y1], fill=(30, 22, 26))
    d.polygon([(x1 - 6, y0 + 26), (x1, y0 + 30), (x1, y0 + 26)], fill=(10, 8, 14))         # broken corner
    x0, y0, x1, y1 = TOWN_BUILDINGS["smithy"]                            # Gravesmith
    d.rectangle([x0, y0 + 12, x1, y1], fill=(70, 50, 40))
    d.polygon([(x0 - 3, y0 + 12), ((x0 + x1) // 2, y0), (x1 + 3, y0 + 12)], fill=(46, 40, 44))
    d.rectangle([x1 - 8, y0 - 8, x1 - 3, y0 + 6], fill=(56, 50, 54))                         # chimney
    d.rectangle([x0 + 4, y1 - 16, x0 + 16, y1], fill=(250, 140, 50)); d.rectangle([x0 + 6, y1 - 14, x0 + 14, y1 - 2], fill=(252, 210, 90))  # forge
    d.rectangle([x0 + 18, y1 - 7, x0 + 26, y1 - 4], fill=(30, 30, 36)); d.rectangle([x0 + 20, y1 - 4, x0 + 24, y1], fill=(30, 30, 36))  # anvil
    x0, y0, x1, y1 = TOWN_BUILDINGS["carver"]                            # Bone Carver's Hut
    d.rectangle([x0, y0 + 10, x1, y1], fill=(84, 66, 46))
    d.polygon([(x0 - 3, y0 + 10), ((x0 + x1) // 2, y0), (x1 + 3, y0 + 10)], fill=(150, 140, 120))
    for bx in range(x0, x1, 4):
        d.point((bx, y0 + 9), fill=(220, 210, 190))                      # bones on the roof
    d.ellipse([(x0 + x1) // 2 - 3, y0 + 1, (x0 + x1) // 2 + 3, y0 + 7], fill=(225, 215, 198))  # skull sign
    d.point(((x0 + x1) // 2 - 1, y0 + 4), fill=(14, 11, 18)); d.point(((x0 + x1) // 2 + 1, y0 + 4), fill=(14, 11, 18))
    d.rectangle([x0 + 9, y1 - 12, x0 + 15, y1], fill=(36, 26, 22))
    x0, y0, x1, y1 = TOWN_BUILDINGS["fortune"]                           # Fortune Teller's Tent
    d.polygon([(x0, y1), ((x0 + x1) // 2, y0), (x1, y1)], fill=(100, 52, 120))
    for i in range(3):
        d.polygon([(x0 + 4 + i * 7, y1), ((x0 + x1) // 2, y0), (x0 + 7 + i * 7, y1)], fill=(140, 90, 40))
    d.polygon([((x0 + x1) // 2 - 4, y1), ((x0 + x1) // 2, y1 - 12), ((x0 + x1) // 2 + 4, y1)], fill=(20, 10, 26))
    d.point(((x0 + x1) // 2, y0 - 2), fill=(230, 210, 120))
    x0, y0, x1, y1 = TOWN_BUILDINGS["kennel"]                            # Kennel of Strays
    d.rectangle([x0, y0 + 6, x1, y1], fill=(96, 70, 44))
    d.polygon([(x0 - 2, y0 + 6), ((x0 + x1) // 2, y0), (x1 + 2, y0 + 6)], fill=(70, 46, 30))
    d.ellipse([(x0 + x1) // 2 - 4, y1 - 9, (x0 + x1) // 2 + 4, y1 + 3], fill=(16, 10, 12))
    d.point(((x0 + x1) // 2 - 1, y1 - 4), fill=(240, 200, 80)); d.point(((x0 + x1) // 2 + 2, y1 - 4), fill=(240, 200, 80))  # eyes in the dark
    x0, y0, x1, y1 = TOWN_BUILDINGS["market"]                            # Night Market stall
    for i in range(6):
        d.rectangle([x0 + i * 7, y0, x0 + i * 7 + 6, y0 + 5], fill=(150, 40, 40) if i % 2 == 0 else (210, 190, 160))
    d.rectangle([x0 + 1, y0 + 5, x0 + 2, y1], fill=(70, 50, 34)); d.rectangle([x1 - 2, y0 + 5, x1 - 1, y1], fill=(70, 50, 34))
    d.rectangle([x0, y1 - 8, x1, y1 - 4], fill=(90, 64, 40))
    for i in range(6):
        d.ellipse([x0 + 3 + i * 6, y1 - 12, x0 + 7 + i * 6, y1 - 8], fill=rng.choice([(200, 170, 60), (110, 160, 90), (160, 60, 60), (200, 200, 210)]))
    d.rectangle([x0 + 18, y0 + 6, x0 + 22, y0 + 10], fill=(250, 200, 90))        # lantern
    # campfire in the middle of the square (the party stands around it)
    fx, fy = 64, 150
    glow = Image.new("RGBA", img.size, (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    for r, a in (((24, 14), (16, 18)) if day else ((46, 22), (32, 30), (20, 40))):
        gd.ellipse([fx - r, fy - r * 0.6, fx + r, fy + r * 0.6], fill=(240, 130, 40, a))
    img.alpha_composite(glow)
    d = ImageDraw.Draw(img)
    d.line([(fx - 7, fy + 4), (fx + 7, fy)], fill=(90, 60, 36), width=2); d.line([(fx - 7, fy), (fx + 7, fy + 4)], fill=(90, 60, 36), width=2)
    for i in range(7):
        a = i / 7 * math.tau
        d.rectangle([fx + int(10 * math.cos(a)) - 1, fy + 2 + int(4 * math.sin(a)) - 1, fx + int(10 * math.cos(a)) + 1, fy + 2 + int(4 * math.sin(a))], fill=(90, 86, 92))
    d.polygon([(fx - 5, fy + 2), (fx, fy - 12), (fx + 5, fy + 2)], fill=(240, 120, 40))
    d.polygon([(fx - 2, fy + 2), (fx, fy - 6), (fx + 2, fy + 2)], fill=(252, 214, 90))
    vig = Image.new("RGBA", img.size, (0, 0, 0, 0))
    vd = ImageDraw.Draw(vig)
    for i in range(10):
        vd.rectangle([i, i, W - 1 - i, H - 1 - i], outline=(0, 0, 0, (60 if day else 120) - i * (5 if day else 11)))
    img.alpha_composite(vig)
    return img


# ---------------------------------------------------------------- map tile icons (16x16)

def icon(draw_fn):
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    draw_fn(ImageDraw.Draw(img))
    return img


K = (14, 11, 18)
TILE_ICONS = {
    "fight": lambda d: (d.line([(3, 12), (12, 3)], fill=(200, 205, 215), width=2), d.line([(3, 3), (12, 12)], fill=(200, 205, 215), width=2),
                        d.line([(2, 10), (5, 13)], fill=(120, 80, 50), width=2), d.line([(10, 13), (13, 10)], fill=(120, 80, 50), width=2)),
    "elite": lambda d: (d.ellipse([3, 2, 12, 11], fill=(220, 210, 195)), d.rectangle([5, 10, 10, 13], fill=(220, 210, 195)),
                        d.rectangle([5, 6, 6, 7], fill=K), d.rectangle([9, 6, 10, 7], fill=(200, 40, 40)), d.point((7, 12), fill=K), d.point((8, 12), fill=K)),
    "boss": lambda d: (d.rectangle([3, 7, 12, 14], fill=(60, 40, 60)), d.polygon([(5, 7), (7, 1), (10, 7)], fill=(60, 40, 60)),
                       d.ellipse([6, 9, 9, 12], fill=(210, 50, 40)), d.point((7, 0), fill=(201, 162, 39))),
    "event": lambda d: (d.rectangle([5, 2, 10, 3], fill=(200, 170, 240)), d.rectangle([4, 3, 5, 5], fill=(200, 170, 240)),
                        d.rectangle([10, 3, 11, 6], fill=(200, 170, 240)), d.rectangle([8, 6, 10, 7], fill=(200, 170, 240)),
                        d.rectangle([7, 7, 8, 9], fill=(200, 170, 240)), d.rectangle([7, 11, 8, 12], fill=(200, 170, 240))),
    "chest": lambda d: (d.rectangle([2, 6, 13, 13], fill=(120, 80, 40)), d.rectangle([2, 4, 13, 7], fill=(150, 100, 50)),
                        d.rectangle([2, 7, 13, 7], fill=(201, 162, 39)), d.rectangle([7, 7, 8, 9], fill=(201, 162, 39))),
    "shop": lambda d: (d.ellipse([3, 5, 12, 14], fill=(150, 110, 60)), d.rectangle([6, 2, 9, 5], fill=(120, 85, 45)),
                       d.ellipse([6, 8, 9, 11], fill=(240, 200, 80))),
    "rest": lambda d: (d.line([(3, 14), (12, 11)], fill=(110, 75, 45), width=2), d.line([(3, 11), (12, 14)], fill=(110, 75, 45), width=2),
                       d.polygon([(5, 11), (8, 2), (11, 11)], fill=(235, 120, 40)), d.polygon([(7, 11), (8, 6), (9, 11)], fill=(252, 214, 90))),
    "start": lambda d: (d.line([(4, 2), (4, 14)], fill=(150, 120, 90), width=1), d.polygon([(5, 2), (13, 5), (5, 8)], fill=(180, 40, 40))),
}


def outline(img):
    w, h = img.size
    out = img.copy()
    for y in range(h):
        for x in range(w):
            if img.getpixel((x, y))[3]:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and img.getpixel((nx, ny))[3]:
                    out.putpixel((x, y), K + (255,))
                    break
    return out


if __name__ == "__main__":
    os.makedirs("assets/backgrounds", exist_ok=True)
    os.makedirs("assets/icons", exist_ok=True)
    for name, fn in {"battle_early": battle_early, "battle_mid": battle_mid, "battle_late": battle_late,
                     "battle_boss": battle_boss, "map": world_map, "town": town, "town_day": lambda: town(True),
                     "map_sunken_abbey": map_sunken_abbey, "map_slag_cathedral": map_slag_cathedral,
                     "map_marrow_vault": map_marrow_vault}.items():
        fn().convert("RGB").save(f"assets/backgrounds/{name}.png")
        print("wrote", name)
    for name, fn in TILE_ICONS.items():
        outline(icon(fn)).save(f"assets/icons/tile_{name}.png")
    print("wrote tile icons")
