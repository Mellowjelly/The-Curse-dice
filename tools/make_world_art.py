"""Draws the open-world art (run: python3 tools/make_world_art.py). Original pixel art, drawn in code.

  assets/world/tiles.png            isometric ground tiles, 64x32 each, in a row:
                                    [biome0 v0..v2][biome1 v0..v2]...[water v0, v1]
  assets/world/decor_<biome>_<n>.png  props (trees, rocks...), 32x48, feet at the bottom centre
  assets/world/ore_<mineral>.png      mineral veins 32x32, and ore_depleted.png
"""
import os
import random
from PIL import Image, ImageDraw

BIOMES = ["deadwood", "swamp", "deepforest", "coast", "snow", "volcanic", "wasteland"]
BIOME_COLORS = {
    "deadwood": [(70, 64, 58), (64, 58, 54), (76, 68, 60)],
    "swamp": [(52, 66, 50), (46, 60, 48), (58, 70, 52)],
    "deepforest": [(46, 84, 48), (40, 76, 44), (52, 92, 52)],
    "coast": [(176, 160, 120), (166, 150, 112), (184, 168, 128)],
    "snow": [(214, 222, 232), (200, 210, 224), (226, 232, 240)],
    "volcanic": [(58, 40, 40), (48, 34, 36), (70, 44, 40)],
    "wasteland": [(118, 104, 92), (106, 94, 84), (126, 110, 96)],
}
WATER = [(30, 50, 74), (36, 58, 84)]
K = (14, 11, 18)


def diamond(color, rng, speck):
    img = Image.new("RGBA", (64, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.polygon([(32, 0), (63, 15), (32, 31), (0, 15)], fill=color + (255,))
    # light from the top-left edge, shadow on the bottom-right edge
    d.line([(0, 15), (32, 0)], fill=tuple(min(255, v + 14) for v in color) + (255,))
    d.line([(32, 31), (63, 15)], fill=tuple(max(0, v - 16) for v in color) + (255,))
    px = img.load()
    for _ in range(40):
        x, y = rng.randint(4, 59), rng.randint(3, 28)
        if px[x, y][3]:
            px[x, y] = tuple(max(0, min(255, v + rng.randint(-speck, speck))) for v in color) + (255,)
    return img


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


def canvas(w=32, h=48):
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


def shadow(d, cx=16, cy=45, rx=9):
    d.ellipse([cx - rx, cy - 3, cx + rx, cy + 2], fill=(0, 0, 0, 70))


# ---------------------------------------------------------------- props per biome

def dead_tree():
    img, d = canvas(); shadow(d)
    d.line([(16, 46), (16, 14)], fill=(52, 40, 34, 255), width=3)
    for y, dx in ((18, -7), (22, 8), (28, -6), (14, 5)):
        d.line([(16, y), (16 + dx, y - 6)], fill=(52, 40, 34, 255), width=1)
        d.line([(16 + dx, y - 6), (16 + dx + (2 if dx > 0 else -2), y - 10)], fill=(52, 40, 34, 255))
    return outline(img)


def dead_bush():
    img, d = canvas(); shadow(d, rx=7)
    for dx in (-5, -2, 2, 5):
        d.line([(16, 46), (16 + dx, 36)], fill=(70, 58, 48, 255))
    return outline(img)


def reeds():
    img, d = canvas(); shadow(d, rx=7)
    for dx, h in ((-5, 14), (-2, 18), (1, 12), (4, 16), (6, 10)):
        d.line([(16 + dx, 46), (16 + dx, 46 - h)], fill=(80, 100, 56, 255))
        d.rectangle([15 + dx, 46 - h, 16 + dx, 49 - h], fill=(110, 80, 50, 255))
    return outline(img)


def mossy_stump():
    img, d = canvas(); shadow(d)
    d.rectangle([10, 34, 22, 45], fill=(74, 56, 40, 255)); d.ellipse([10, 31, 22, 37], fill=(96, 74, 52, 255))
    d.ellipse([9, 36, 15, 42], fill=(70, 110, 60, 255))
    return outline(img)


def green_tree():
    img, d = canvas(); shadow(d, rx=10)
    d.rectangle([14, 30, 18, 45], fill=(70, 50, 36, 255))
    d.ellipse([4, 6, 28, 30], fill=(40, 96, 46, 255)); d.ellipse([7, 8, 20, 20], fill=(60, 120, 60, 255))
    return outline(img)


def mushroom():
    img, d = canvas(); shadow(d, rx=7)
    d.rectangle([14, 34, 18, 45], fill=(220, 210, 190, 255))
    d.ellipse([7, 26, 25, 38], fill=(170, 50, 60, 255))
    for x, y in ((11, 30), (17, 29), (21, 32)):
        d.point((x, y), fill=(240, 230, 220, 255))
    return outline(img)


def driftwood():
    img, d = canvas(); shadow(d, rx=11)
    d.line([(5, 44), (27, 38)], fill=(140, 120, 96, 255), width=3)
    d.line([(10, 43), (8, 38)], fill=(140, 120, 96, 255), width=2)
    return outline(img)


def coast_rock():
    img, d = canvas(); shadow(d, rx=10)
    d.ellipse([6, 30, 26, 46], fill=(96, 100, 110, 255)); d.ellipse([9, 32, 18, 39], fill=(130, 134, 144, 255))
    d.point((20, 40), fill=(220, 220, 230, 255))
    return outline(img)


def snow_pine():
    img, d = canvas(); shadow(d, rx=9)
    d.rectangle([15, 38, 17, 45], fill=(70, 50, 36, 255))
    for y, w in ((8, 4), (16, 7), (24, 10), (31, 12)):
        d.polygon([(16, y), (16 - w, y + 10), (16 + w, y + 10)], fill=(40, 70, 64, 255))
        d.line([(16, y), (16 - w, y + 10)], fill=(236, 240, 248, 255))
    return outline(img)


def ice_rock():
    img, d = canvas(); shadow(d, rx=9)
    d.polygon([(8, 45), (12, 30), (18, 26), (24, 34), (24, 45)], fill=(150, 190, 220, 255))
    d.line([(12, 30), (18, 26)], fill=(230, 245, 255, 255))
    return outline(img)


def obsidian_spike():
    img, d = canvas(); shadow(d, rx=8)
    d.polygon([(10, 45), (15, 18), (22, 45)], fill=(30, 24, 40, 255))
    d.line([(15, 18), (12, 40)], fill=(120, 90, 160, 255))
    return outline(img)


def lava_vent():
    img, d = canvas(); shadow(d, rx=10)
    d.ellipse([7, 36, 25, 46], fill=(50, 36, 36, 255)); d.ellipse([11, 38, 21, 43], fill=(240, 110, 40, 255))
    d.point((16, 40), fill=(252, 214, 90, 255)); d.point((14, 32), fill=(110, 100, 100, 255)); d.point((17, 27), fill=(90, 84, 84, 255))
    return outline(img)


def bone_pile():
    img, d = canvas(); shadow(d, rx=10)
    for (x0, y0, x1, y1) in ((6, 44, 24, 38), (9, 40, 26, 44), (12, 36, 20, 44)):
        d.line([(x0, y0), (x1, y1)], fill=(218, 208, 194, 255), width=2)
    d.ellipse([18, 32, 25, 39], fill=(218, 208, 194, 255)); d.point((20, 35), fill=K + (255,))
    return outline(img)


def ribcage():
    img, d = canvas(); shadow(d, rx=11)
    d.line([(6, 44), (26, 44)], fill=(200, 190, 176, 255), width=2)
    for x in range(8, 26, 4):
        d.arc([x - 3, 26, x + 5, 50], 180, 300, fill=(218, 208, 194, 255), width=2)
    return outline(img)


def dungeon_entrance():
    """3.5: the Sunken Abbey: a drowned stone arch with a dark doorway and a bell (48x64)."""
    img = Image.new("RGBA", (48, 64), (0, 0, 0, 0)); d = ImageDraw.Draw(img)
    d.ellipse([4, 54, 44, 62], fill=(30, 50, 74, 200))                               # tide pool around the steps
    stone, stone_d = (120, 124, 120, 255), (84, 88, 88, 255)
    d.rectangle([8, 22, 16, 58], fill=stone); d.rectangle([32, 22, 40, 58], fill=stone)   # pillars
    d.pieslice([8, 6, 40, 38], 180, 360, fill=stone)                                  # the arch
    d.pieslice([16, 14, 32, 30], 180, 360, fill=K + (255,))
    d.rectangle([16, 22, 32, 58], fill=K + (255,))                                   # the dark doorway
    d.rectangle([22, 2, 26, 8], fill=stone_d); d.ellipse([20, 6, 28, 14], fill=(176, 140, 70, 255))  # bell
    for y in (30, 40, 50):
        d.line([(8, y), (16, y)], fill=stone_d); d.line([(32, y + 3), (40, y + 3)], fill=stone_d)
    for x, y in ((10, 46), (36, 36), (12, 28)):
        d.point((x, y), fill=(60, 120, 90, 255)); d.point((x + 1, y + 1), fill=(60, 120, 90, 255))  # weed
    d.rectangle([14, 56, 34, 58], fill=(110, 150, 170, 255))                          # water at the door
    return outline(img)



def slag_door():
    """3.7: the Slag Cathedral: an iron gate in a black glass wall, lit from inside (48x64)."""
    img = Image.new("RGBA", (48, 64), (0, 0, 0, 0)); d = ImageDraw.Draw(img)
    d.ellipse([4, 54, 44, 62], fill=(90, 30, 20, 200))                                # cooling slag at the steps
    iron, iron_d, glow = (70, 58, 60, 255), (44, 36, 40, 255), (240, 130, 40, 255)
    d.polygon([(6, 58), (6, 20), (24, 4), (42, 20), (42, 58)], fill=iron)            # a pointed iron facade
    d.polygon([(14, 58), (14, 26), (24, 14), (34, 26), (34, 58)], fill=K + (255,))   # the doorway
    for x in (18, 24, 30):
        d.line([(x, 24 if x != 24 else 18), (x, 58)], fill=iron_d, width=1)          # gate bars
    d.rectangle([16, 46, 32, 57], fill=(200, 90, 30, 255))                           # the furnace glow behind the bars
    d.rectangle([20, 50, 28, 57], fill=glow)
    for x, y in ((9, 30), (38, 40), (10, 48)):
        d.line([(x, y), (x + 1, y + 6)], fill=glow)                                   # molten seams in the wall
    d.rectangle([22, 0, 26, 6], fill=iron_d)                                           # a small iron spire
    return outline(img)


def bone_door():
    """3.7: the Marrow Vault: a gate stacked from bones and skulls, with a toll-stone (48x64)."""
    img = Image.new("RGBA", (48, 64), (0, 0, 0, 0)); d = ImageDraw.Draw(img)
    d.ellipse([4, 54, 44, 62], fill=(80, 70, 62, 200))
    bone, bone_d = (214, 204, 184, 255), (150, 140, 124, 255)
    d.rectangle([6, 18, 15, 58], fill=bone); d.rectangle([33, 18, 42, 58], fill=bone)   # stacked bone pillars
    for y in range(20, 58, 5):
        d.line([(6, y), (15, y)], fill=bone_d); d.line([(33, y + 2), (42, y + 2)], fill=bone_d)
    d.rectangle([6, 12, 42, 18], fill=bone_d)                                          # the lintel
    for x in (10, 19, 28, 37):                                                         # skulls on the lintel
        d.ellipse([x - 3, 7, x + 3, 15], fill=bone); d.rectangle([x - 2, 10, x - 1, 11], fill=K + (255,)); d.rectangle([x + 1, 10, x + 2, 11], fill=K + (255,))
    d.rectangle([15, 18, 33, 58], fill=K + (255,))                                    # the dark doorway
    d.rectangle([18, 52, 30, 58], fill=(96, 90, 86, 255))                              # the toll-stone
    d.point((24, 54), fill=(170, 120, 230, 255)); d.point((23, 55), fill=(170, 120, 230, 255))  # a fate fragment's glint
    return outline(img)


DECOR = {
    "deadwood": [dead_tree, dead_bush], "swamp": [reeds, mossy_stump], "deepforest": [green_tree, mushroom],
    "coast": [driftwood, coast_rock], "snow": [snow_pine, ice_rock], "volcanic": [obsidian_spike, lava_vent],
    "wasteland": [bone_pile, ribcage],
}


# ---------------------------------------------------------------- mineral veins

MINERALS = {
    "grave_iron": [(150, 140, 140), (120, 60, 50)], "bog_copper": [(200, 120, 60), (80, 140, 90)],
    "amberheart": [(240, 170, 50), (180, 110, 30)], "sea_pearl": [(240, 236, 228), (180, 200, 220)],
    "frost_silver": [(220, 232, 245), (140, 180, 220)], "obsidian": [(60, 40, 90), (150, 110, 200)],
    "soulstone": [(150, 80, 220), (230, 180, 255)],
}


def ore(colors):
    img, d = canvas(32, 32)
    d.ellipse([3, 25, 29, 31], fill=(0, 0, 0, 70))
    d.ellipse([3, 14, 29, 30], fill=(84, 80, 90, 255)); d.ellipse([6, 15, 18, 23], fill=(110, 106, 116, 255))
    for (x, y, h) in ((9, 18, 8), (15, 13, 12), (21, 17, 9)):
        d.polygon([(x - 3, y + h), (x, y), (x + 3, y + h)], fill=colors[0] + (255,))
        d.line([(x, y), (x - 2, y + h - 1)], fill=colors[1] + (255,))
    d.point((16, 12), fill=(255, 255, 255, 255))
    return outline(img)


def depleted():
    img, d = canvas(32, 32)
    d.ellipse([3, 25, 29, 31], fill=(0, 0, 0, 60))
    d.ellipse([5, 18, 27, 30], fill=(70, 66, 74, 255)); d.ellipse([8, 19, 16, 24], fill=(90, 86, 94, 255))
    return outline(img)


# ---------------------------------------------------------------- trees you can chop (bigger, with a cut mark)

TREES = {
    "ashwood": ((70, 60, 54), (110, 100, 96)), "bogwood": ((60, 52, 40), (70, 96, 60)),
    "elderwood": ((80, 56, 36), (50, 120, 54)), "driftwood": ((150, 130, 104), (90, 120, 90)),
    "frostpine": ((70, 50, 36), (220, 230, 240)), "charwood": ((40, 30, 30), (220, 100, 40)),
    "bonewood": ((210, 200, 186), (150, 140, 130)),
}


def chop_tree(trunk, crown):
    img, d = canvas(40, 56)
    d.ellipse([8, 49, 32, 55], fill=(0, 0, 0, 70))
    d.rectangle([17, 30, 23, 52], fill=trunk + (255,))
    d.ellipse([4, 4, 36, 34], fill=crown + (255,))
    d.ellipse([9, 8, 24, 20], fill=tuple(min(255, v + 25) for v in crown) + (255,))
    d.line([(24, 40), (20, 44)], fill=(240, 220, 170, 255), width=2)     # an axe notch: this one can be chopped
    return outline(img)


def stump():
    img, d = canvas(40, 56)
    d.ellipse([10, 48, 30, 54], fill=(0, 0, 0, 60))
    d.rectangle([15, 42, 25, 51], fill=(80, 60, 44, 255)); d.ellipse([15, 39, 25, 45], fill=(150, 120, 90, 255))
    return outline(img)


if __name__ == "__main__":
    os.makedirs("assets/world", exist_ok=True)
    rng = random.Random(3)
    tiles = Image.new("RGBA", (64 * (len(BIOMES) * 3 + 2), 32), (0, 0, 0, 0))
    i = 0
    for b in BIOMES:
        for v in range(3):
            tiles.paste(diamond(BIOME_COLORS[b][v], rng, 10), (i * 64, 0)); i += 1
    for v in range(2):
        tiles.paste(diamond(WATER[v], rng, 6), (i * 64, 0)); i += 1
    tiles.save("assets/world/tiles.png")
    for b, fns in DECOR.items():
        for n, fn in enumerate(fns):
            fn().save(f"assets/world/decor_{b}_{n}.png")
    for m, cols in MINERALS.items():
        ore(cols).save(f"assets/world/ore_{m}.png")
    depleted().save("assets/world/ore_depleted.png")
    for t, (trunk, crown) in TREES.items():
        chop_tree(trunk, crown).save(f"assets/world/tree_{t}.png")
    stump().save("assets/world/tree_stump.png")
    dungeon_entrance().save("assets/world/dungeon_entrance.png")
    slag_door().save("assets/world/dungeon_slag_cathedral.png")
    bone_door().save("assets/world/dungeon_marrow_vault.png")
    print("world art done")
