"""Draws battle backgrounds, the world map and map tile icons (run: python3 tools/make_backgrounds.py).

Original pixel art drawn from shapes in code:
  assets/backgrounds/battle_early.png  (dead forest, moon)      320x180
  assets/backgrounds/battle_mid.png    (graveyard)              320x180
  assets/backgrounds/battle_late.png   (burning village ruins)  320x180
  assets/backgrounds/battle_boss.png   (inside the Chapel of Rot) 320x180
  assets/backgrounds/map.png           (The Hollow Road)        320x180 (game scales x4)
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
                     "battle_boss": battle_boss, "map": world_map}.items():
        fn().convert("RGB").save(f"assets/backgrounds/{name}.png")
        print("wrote", name)
    for name, fn in TILE_ICONS.items():
        outline(icon(fn)).save(f"assets/icons/tile_{name}.png")
    print("wrote tile icons")
