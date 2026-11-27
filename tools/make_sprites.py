"""Draws the character sprites into assets/sprites/ (run: python3 tools/make_sprites.py).

Original pixel art, drawn from simple shapes in code. Every character gets 3 frames,
saved side by side in one strip PNG:  [idle A][idle B (breath)][attack (lean forward)]
Heroes face RIGHT. Monsters are drawn facing RIGHT too; the game flips them to face left.
Canvas: 32x32 (boss 48x48). A 1px dark outline is added automatically.
"""
from PIL import Image, ImageDraw

# ---------------------------------------------------------------- palette
K = (14, 11, 18)          # outline / void
SKIN = (214, 180, 150)
SKIN_D = (170, 130, 105)
PALE = (205, 200, 195)
PALE_D = (150, 145, 145)
ST_D = (62, 68, 84)       # dark steel
ST = (120, 128, 146)      # steel
ST_L = (186, 192, 204)    # light steel
RUST = (120, 82, 52)
CAPE = (128, 24, 30)
CAPE_D = (78, 14, 20)
GOLD = (201, 162, 39)
GOLD_D = (140, 105, 25)
EMBER = (230, 120, 40)
FLAME = (252, 214, 90)
ROBE = (92, 88, 100)
ROBE_D = (58, 54, 66)
BROWN = (112, 80, 50)
BROWN_D = (72, 50, 34)
ROT = (112, 142, 92)
ROT_D = (64, 88, 56)
BONE = (218, 208, 194)
BONE_D = (160, 150, 134)
PURP = (98, 52, 112)
PURP_D = (58, 30, 70)
CLOTH = (36, 30, 42)
CLOTH_L = (58, 50, 66)
WHITE = (236, 232, 222)
RED = (200, 40, 36)
GREEN_GLOW = (140, 220, 110)
CLAY = (176, 104, 66)


class Canvas:
    def __init__(self, size=32):
        self.size = size
        self.img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        self.d = ImageDraw.Draw(self.img)

    def px(self, x, y, c):
        if 0 <= x < self.size and 0 <= y < self.size:
            self.img.putpixel((x, y), c + (255,))

    def rect(self, x0, y0, x1, y1, c):
        self.d.rectangle([x0, y0, x1, y1], fill=c + (255,))

    def ell(self, x0, y0, x1, y1, c):
        self.d.ellipse([x0, y0, x1, y1], fill=c + (255,))

    def line(self, pts, c, w=1):
        self.d.line(pts, fill=c + (255,), width=w)

    def poly(self, pts, c):
        self.d.polygon(pts, fill=c + (255,))


def outline(img):
    """Adds a 1px near-black outline around every opaque pixel."""
    w, h = img.size
    src = img.copy()
    out = img.copy()
    for y in range(h):
        for x in range(w):
            if src.getpixel((x, y))[3] > 0:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and src.getpixel((nx, ny))[3] > 0 and src.getpixel((nx, ny))[:3] != K:
                    out.putpixel((x, y), K + (255,))
                    break
    return out


def frames(img, split_y):
    """idle A, idle B (upper body sinks 1px), attack (upper body leans 2px forward)."""
    w, h = img.size
    top = img.crop((0, 0, w, split_y))
    legs = img.crop((0, split_y, w, h))
    b = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    b.paste(legs, (0, split_y))
    b.alpha_composite(top, (0, 1))
    atk = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    atk.paste(legs, (0, split_y))
    atk.alpha_composite(top, (2, 0))
    strip = Image.new("RGBA", (w * 3, h), (0, 0, 0, 0))
    for i, f in enumerate((img, b, atk)):
        strip.paste(outline(f), (i * w, 0))
    return strip


# ---------------------------------------------------------------- heroes

def varek():
    c = Canvas()
    c.rect(7, 13, 11, 29, CAPE_D); c.rect(8, 13, 11, 27, CAPE)              # cape behind
    c.rect(12, 25, 14, 31, ST_D); c.rect(17, 25, 19, 31, ST_D)               # legs
    c.rect(11, 14, 20, 25, ST); c.rect(12, 15, 15, 20, ST_L)                 # torso + shine
    c.rect(11, 22, 20, 23, ST_D)                                              # belt
    c.rect(12, 4, 19, 13, ST); c.rect(12, 4, 14, 7, ST_L)                     # helmet
    c.rect(13, 9, 15, 9, K); c.rect(17, 9, 19, 9, K)                          # split visor
    c.px(14, 9, EMBER)                                                        # an eye in the dark
    for x, y in ((12, 14), (13, 15), (14, 14), (15, 15)):
        c.px(x, y, GOLD)                                                      # broken chain
    c.rect(19, 15, 25, 25, ST_D); c.rect(20, 16, 24, 24, ST)                  # tower shield
    c.line([(21, 17), (23, 20), (22, 23)], K)                                 # crack
    return frames(c.img, 24)


def lys():
    c = Canvas()
    c.poly([(15, 12), (9, 31), (22, 31), (17, 12)], ROBE)                     # robe
    c.poly([(16, 14), (13, 31), (16, 31)], ROBE_D)                            # robe fold
    c.ell(10, 2, 21, 14, ROBE_D)                                              # hood
    c.ell(12, 6, 19, 13, K)                                                   # hollow face
    c.px(14, 9, EMBER); c.px(17, 9, EMBER)                                    # burning eyes
    c.px(15, 11, PALE)                                                        # crack of porcelain
    c.rect(19, 15, 23, 16, ROBE); c.rect(23, 15, 24, 16, PALE)               # arm + hand
    c.ell(22, 9, 27, 14, EMBER); c.ell(23, 10, 26, 13, FLAME)                # flame
    c.px(24, 8, EMBER); c.px(25, 7, FLAME)
    return frames(c.img, 24)


def aldric():
    c = Canvas()
    c.poly([(14, 12), (10, 31), (21, 31), (18, 12)], BROWN)                   # robe
    c.poly([(16, 14), (14, 31), (16, 31)], BROWN_D)
    c.rect(11, 21, 20, 21, BONE_D)                                            # rope belt
    c.ell(12, 3, 19, 12, SKIN); c.rect(12, 9, 19, 12, SKIN_D)                 # bald head
    c.px(14, 7, K); c.px(17, 7, K); c.px(14, 8, PALE_D); c.px(17, 8, PALE_D)  # tired eyes
    c.rect(15, 10, 16, 10, SKIN_D)
    c.rect(15, 15, 15, 18, GOLD); c.rect(14, 17, 16, 17, GOLD)                # upside-down holy symbol
    c.rect(19, 16, 22, 17, BROWN); c.px(23, 17, SKIN)                         # arm
    c.rect(23, 18, 23, 19, BROWN_D)                                           # lantern chain
    c.rect(22, 20, 25, 24, GOLD_D); c.rect(23, 21, 24, 23, FLAME)            # lantern
    return frames(c.img, 24)


def rook():
    c = Canvas()
    c.rect(22, 5, 22, 25, BROWN); c.rect(20, 25, 24, 30, ST); c.rect(21, 30, 23, 31, ST_L)  # spade
    c.rect(12, 25, 14, 31, CLOTH); c.rect(17, 25, 19, 31, CLOTH)              # legs
    c.rect(11, 13, 20, 26, CLOTH_L); c.rect(15, 13, 16, 26, CLOTH)            # coat
    c.rect(12, 12, 19, 13, CAPE)                                              # scarf
    c.rect(13, 6, 18, 12, PALE); c.rect(13, 10, 18, 12, PALE_D)               # face
    c.px(14, 8, K); c.px(17, 8, K); c.rect(14, 11, 17, 11, K)                 # grim face
    c.rect(9, 5, 22, 6, CLOTH); c.rect(12, 1, 19, 5, CLOTH)                   # wide-brim hat
    c.rect(12, 4, 19, 4, CAPE_D)
    c.rect(20, 16, 22, 17, CLOTH_L)                                           # arm on spade
    return frames(c.img, 24)


def vael():
    c = Canvas()
    c.poly([(13, 12), (9, 31), (22, 31), (19, 12)], CLOTH)                    # long coat
    c.poly([(16, 14), (15, 31), (17, 31)], CLOTH_L)
    c.ell(11, 4, 20, 13, BONE)                                                # mask
    c.poly([(19, 8), (27, 11), (19, 12)], BONE)                               # beak
    c.line([(19, 12), (26, 11)], BONE_D)
    c.ell(14, 6, 16, 8, RED); c.px(15, 7, FLAME)                              # glass eye
    c.rect(9, 3, 22, 4, CLOTH); c.rect(12, 0, 19, 3, CLOTH)                   # hat
    c.rect(19, 18, 22, 19, CLOTH); c.px(23, 19, BONE)                         # arm
    c.rect(23, 20, 23, 21, ST_D); c.ell(21, 22, 25, 26, ST_D)                 # censer
    c.px(22, 21, GREEN_GLOW); c.px(24, 20, GREEN_GLOW); c.px(25, 18, GREEN_GLOW); c.px(24, 16, GREEN_GLOW)
    return frames(c.img, 24)


def mordecai():
    c = Canvas()
    c.rect(12, 25, 14, 31, PURP_D); c.rect(17, 25, 19, 31, PURP_D)            # legs
    c.rect(11, 13, 20, 26, PURP); c.rect(15, 13, 16, 26, PURP_D)              # coat
    c.px(14, 17, GOLD); c.px(14, 20, GOLD); c.px(17, 17, GOLD); c.px(17, 20, GOLD)  # buttons
    c.rect(13, 7, 18, 12, PALE)                                               # face
    c.px(14, 9, K); c.px(17, 9, K)
    c.rect(14, 11, 17, 11, K); c.px(13, 10, K); c.px(18, 10, K)               # wide grin
    c.rect(11, 6, 20, 6, CLOTH); c.rect(13, 0, 18, 5, CLOTH)                  # top hat
    c.rect(13, 4, 18, 4, RED)
    c.rect(19, 15, 22, 16, PURP); c.px(23, 15, PALE)                          # arm
    c.rect(23, 11, 26, 14, WHITE); c.px(24, 12, K); c.px(25, 13, K)           # die
    c.rect(25, 16, 27, 18, WHITE); c.px(26, 17, K)                            # die
    return frames(c.img, 24)


def wren():
    """3.4 hero: the town's bell-ringer, grey before her time, a hand-bell on a rope."""
    c = Canvas()
    c.poly([(12, 12), (9, 31), (22, 31), (19, 12)], ROBE_D)                   # mourning dress
    c.poly([(15, 13), (14, 31), (17, 31), (16, 13)], ROBE)
    c.ell(12, 4, 19, 12, PALE)                                                # gaunt face
    c.px(14, 8, K); c.px(17, 8, K); c.rect(15, 10, 16, 10, PALE_D)
    c.poly([(11, 3), (15, 0), (20, 3), (21, 14), (19, 6), (12, 6), (10, 14)], PALE_D)  # grey hair, hooded
    c.rect(19, 15, 22, 16, ROBE_D); c.px(23, 16, PALE)                        # arm
    c.line([(23, 17), (23, 20)], BROWN)                                       # bell rope
    c.poly([(21, 21), (25, 21), (26, 26), (20, 26)], GOLD_D)                  # hand-bell
    c.rect(22, 22, 23, 24, GOLD); c.px(23, 27, ST_D)                          # clapper
    return frames(c.img, 24)


def osric():
    """3.4 hero: a big man grey with ash, mouth and hands stained black."""
    c = Canvas()
    c.rect(11, 25, 14, 31, BROWN_D); c.rect(17, 25, 20, 31, BROWN_D)         # legs
    c.rect(9, 13, 22, 26, ROBE); c.rect(10, 14, 13, 20, PALE_D)               # broad ash-grey body
    for x, y in ((12, 22), (18, 17), (20, 23), (15, 15)):
        c.px(x, y, CLOTH)                                                     # soot smudges
    c.rect(11, 12, 20, 13, BROWN)                                             # rope belt across the shoulders
    c.rect(12, 4, 19, 12, PALE_D)                                             # face
    c.px(14, 7, EMBER); c.px(17, 7, EMBER)                                    # eyes still glowing
    c.rect(13, 9, 18, 11, CLOTH); c.px(15, 10, K)                             # ash-black mouth
    c.rect(12, 2, 19, 4, CLOTH_L)                                             # cropped hair
    c.rect(21, 16, 24, 18, ROBE); c.ell(23, 15, 27, 19, CLOTH)                # blackened fist
    for x, y in ((26, 12), (24, 10), (27, 9)):
        c.px(x, y, PALE)                                                      # ash drifting up
    return frames(c.img, 24)


# ---------------------------------------------------------------- monsters (drawn facing right)

def ghoul():
    c = Canvas()
    c.rect(10, 24, 11, 31, ROT_D); c.rect(16, 24, 17, 31, ROT_D)             # thin legs
    c.ell(7, 12, 21, 26, ROT); c.ell(9, 14, 15, 20, ROT_D)                    # hunched body
    c.rect(8, 20, 20, 26, CLOTH_L)                                            # burial rags
    c.ell(17, 9, 25, 17, ROT)                                                 # head thrust forward
    c.px(22, 12, FLAME); c.px(20, 12, FLAME)                                  # eyes
    c.rect(20, 15, 25, 16, K); c.px(21, 15, BONE); c.px(23, 15, BONE)         # open jaw + teeth
    c.line([(19, 19), (25, 22), (27, 25)], ROT, 2)                            # long arm
    c.px(28, 26, BONE); c.px(27, 27, BONE); c.px(26, 27, BONE)                # claws
    return frames(c.img, 23)


def cultist():
    c = Canvas()
    c.poly([(14, 11), (9, 31), (22, 31), (18, 11)], ROBE)                     # ash robe
    for x, y in ((11, 26), (14, 22), (18, 28), (20, 24), (13, 30)):
        c.px(x, y, PALE_D)                                                    # ash flecks
    c.ell(11, 2, 20, 13, ROBE_D)                                              # hood
    c.ell(12, 5, 19, 12, CLAY)                                                # clay mask
    c.px(14, 8, K); c.px(17, 8, K); c.line([(16, 5), (15, 9), (16, 12)], K)   # eye holes + crack
    c.rect(19, 15, 22, 16, ROBE); c.rect(23, 16, 23, 18, ST_D)
    c.ell(21, 19, 25, 22, ST_D)                                               # censer
    c.px(24, 17, PALE); c.px(25, 15, PALE); c.px(24, 13, PALE_D)              # smoke
    return frames(c.img, 24)


def bone_hound():
    c = Canvas()
    for x in (9, 12, 19, 22):
        c.rect(x, 22, x, 31, BONE)                                            # four legs
    c.line([(7, 16), (24, 15)], BONE, 2)                                      # spine
    for x in range(11, 21, 2):
        c.line([(x, 16), (x, 22)], BONE_D)                                    # ribs
    c.ell(13, 18, 18, 21, EMBER); c.px(15, 19, FLAME)                         # ember in the ribcage
    c.line([(7, 16), (3, 12)], BONE)                                          # tail
    c.ell(22, 10, 29, 16, BONE)                                               # skull
    c.px(26, 12, RED)                                                         # eye socket glow
    c.rect(25, 16, 30, 17, BONE_D); c.px(27, 17, K); c.px(29, 17, K)          # jaw
    return frames(c.img, 21)


def plague_rat():
    c = Canvas()
    c.line([(5, 27), (2, 24), (3, 20)], PALE_D)                               # tail
    c.ell(6, 22, 20, 30, BROWN); c.ell(8, 24, 14, 29, BROWN_D)                # body
    c.ell(16, 21, 24, 28, BROWN)                                              # head
    c.px(20, 23, RED); c.px(22, 25, PALE)                                     # eye, tooth
    c.ell(16, 18, 19, 22, PALE_D)                                             # ear
    c.px(11, 24, ROT); c.px(9, 27, ROT)                                       # sores
    c.rect(9, 30, 10, 31, PALE_D); c.rect(17, 30, 18, 31, PALE_D)             # feet
    return frames(c.img, 28)


def weeping_nun():
    c = Canvas()
    c.poly([(13, 11), (8, 31), (23, 31), (19, 11)], CLOTH)                    # habit
    c.ell(10, 2, 21, 15, CLOTH)                                               # veil
    c.ell(12, 4, 19, 14, WHITE)                                               # wimple
    c.ell(13, 6, 18, 12, PALE)                                                # face
    c.px(14, 8, K); c.px(17, 8, K)
    c.rect(14, 9, 14, 12, CAPE_D); c.rect(17, 9, 17, 12, CAPE_D)              # bloody tears
    c.rect(14, 18, 17, 22, PALE)                                              # praying hands
    c.rect(15, 16, 16, 17, GOLD)                                              # rosary
    return frames(c.img, 24)


def grave_knight():
    c = Canvas()
    c.rect(12, 25, 14, 31, RUST); c.rect(17, 25, 19, 31, RUST)
    c.rect(11, 13, 20, 25, ROT_D); c.rect(12, 14, 15, 19, ST)                 # rusted armour
    c.rect(11, 22, 20, 23, RUST)
    c.rect(12, 3, 19, 12, ROT_D); c.rect(12, 3, 13, 6, ST)                    # helm
    c.rect(13, 8, 18, 8, K); c.px(14, 8, GREEN_GLOW); c.px(17, 8, GREEN_GLOW)  # dead eyes
    c.rect(20, 3, 21, 24, ST_L); c.rect(18, 22, 23, 23, RUST)                 # greatsword
    c.rect(20, 24, 21, 27, BROWN_D)
    c.px(13, 17, ROT); c.px(18, 20, ROT); c.px(16, 24, ROT)                   # moss
    return frames(c.img, 24)


def bone_colossus():
    c = Canvas()
    c.rect(9, 22, 12, 31, BONE); c.rect(19, 22, 22, 31, BONE)                 # huge legs
    c.ell(7, 18, 24, 25, BONE_D)                                              # pelvis
    c.rect(14, 8, 17, 20, BONE)                                               # spine
    for y in (10, 13, 16):
        c.line([(8, y), (23, y + 1)], BONE)                                   # ribs
    c.ell(11, 0, 21, 9, BONE)                                                 # skull
    c.px(14, 4, EMBER); c.px(18, 4, EMBER); c.rect(14, 7, 18, 7, K)
    c.line([(23, 10), (28, 17), (29, 24)], BONE, 3)                           # arm
    c.ell(26, 23, 31, 28, BONE_D)                                             # fist of skulls
    c.line([(8, 10), (3, 18), (4, 26)], BONE, 3)
    return frames(c.img, 21)


def rotting_bishop(enraged=False):
    c = Canvas(48)
    vest = CAPE if enraged else GOLD
    vest_d = CAPE_D if enraged else GOLD_D
    c.poly([(19, 18), (8, 47), (39, 47), (29, 18)], vest)                     # vestments
    c.poly([(23, 20), (20, 47), (27, 47), (25, 20)], WHITE if not enraged else CLOTH)  # stole
    c.poly([(9, 40), (14, 47), (6, 47)], vest_d); c.poly([(37, 38), (41, 47), (33, 47)], vest_d)  # tatters
    for x, y in ((14, 30), (31, 34), (17, 41), (29, 26)):
        c.ell(x, y, x + 2, y + 2, ROT)                                        # rot showing through
    c.ell(17, 9, 30, 22, ROT)                                                 # rotting face
    c.ell(18, 15, 22, 20, ROT_D)
    c.px(21, 14, RED if enraged else FLAME); c.px(26, 14, RED if enraged else FLAME)
    c.rect(21, 18, 27, 19, K); c.px(22, 18, BONE); c.px(25, 19, BONE)
    c.poly([(17, 10), (23, 0), (30, 10)], WHITE if not enraged else CLOTH)    # mitre
    c.rect(22, 2, 24, 9, vest); c.rect(19, 6, 28, 7, vest)
    c.rect(36, 4, 37, 44, GOLD_D)                                             # crozier
    c.ell(33, 0, 40, 7, GOLD_D); c.ell(35, 2, 38, 5, (0, 0, 0))
    c.rect(30, 22, 36, 24, vest); c.rect(35, 21, 38, 25, ROT)                 # arm + hand
    for y in (26, 30, 35):
        c.px(37, y, CLOTH)                                                    # dripping ichor
    if enraged:
        for x, y in ((10, 20), (38, 16), (6, 30), (42, 28)):
            c.px(x, y, RED)
    return frames(c.img, 38)


def wick_mother(enraged=False):
    """3.4 road boss: an old chandler with a crown of candles and a dipping pole."""
    c = Canvas(48)
    tallow, tallow_d = (196, 178, 130), (140, 120, 84)
    dress = CLOTH_L if enraged else tallow_d
    c.poly([(17, 20), (7, 47), (37, 47), (29, 20)], dress)                     # long dress
    c.poly([(20, 24), (16, 47), (28, 47), (26, 24)], CLOTH)                    # apron, stiff with wax
    for x, y in ((11, 38), (33, 40), (19, 30), (25, 36)):
        c.rect(x, y, x, y + 4, tallow)                                         # wax runs down the dress
    c.ell(15, 9, 30, 23, PALE if not enraged else tallow)                      # face of soft wax
    c.rect(17, 20, 18, 25, PALE); c.rect(27, 21, 28, 27, PALE)                 # drips off the chin
    c.rect(18, 14, 20, 16, K); c.rect(24, 14, 26, 16, K)                       # sunken eye-holes
    c.px(19, 15, RED if enraged else EMBER); c.px(25, 15, RED if enraged else EMBER)
    c.rect(20, 19, 24, 21, K); c.px(21, 19, PALE_D); c.px(23, 21, PALE_D)      # a mouth melted open
    for i, x in enumerate((15, 19, 23, 27)):                                    # crown of candles
        top = 4 + (i % 2) * 2
        c.rect(x, top, x + 2, 10, WHITE)
        c.px(x + 1, top - 1, FLAME); c.px(x + 1, top - 2, EMBER)
    c.rect(30, 22, 35, 24, dress); c.rect(34, 21, 36, 25, PALE)                # arm + hand
    c.rect(35, 2, 36, 46, BROWN_D)                                             # dipping pole
    c.rect(32, 2, 42, 3, BROWN_D)                                              # cross-bar
    for x in (33, 40):
        c.line([(x, 4), (x, 10)], BONE_D)                                      # wicks
        c.ell(x - 2, 10, x + 2, 18, tallow)                                    # something dipped in tallow
        c.px(x, 9, FLAME)
    if enraged:
        for x, y in ((12, 6), (14, 2), (30, 3), (32, 8), (11, 12), (22, 1)):
            c.px(x, y, EMBER); c.px(x, y + 1, FLAME)                           # her hair is burning
    return frames(c.img, 36)


# ---------------------------------------------------------------- pets (small creatures, bottom of a 32x32 canvas)

def ash_crow():
    c = Canvas()
    c.ell(10, 18, 22, 27, CLOTH); c.ell(18, 13, 25, 20, CLOTH)              # body, head
    c.poly([(24, 16), (29, 17), (24, 18)], GOLD_D)                          # beak
    c.px(22, 15, EMBER)                                                     # eye
    c.poly([(10, 20), (3, 24), (11, 25)], CLOTH_L)                          # tail
    c.poly([(12, 19), (17, 14), (19, 22)], CLOTH_L)                         # wing
    c.rect(14, 27, 14, 30, GOLD_D); c.rect(18, 27, 18, 30, GOLD_D)          # legs
    for x, y in ((6, 12), (9, 9), (26, 9)):
        c.px(x, y, PALE_D)                                                  # drifting ash
    return frames(c.img, 26)


def grave_pup():
    c = Canvas()
    c.rect(9, 26, 10, 31, BONE); c.rect(19, 26, 20, 31, BONE)
    c.ell(7, 17, 22, 28, BONE_D); c.ell(9, 19, 15, 25, BONE)                # skeletal body
    c.line([(9, 21), (20, 21)], K)
    c.ell(18, 12, 27, 20, BONE)                                             # skull head
    c.px(23, 15, EMBER); c.rect(24, 18, 27, 18, K)
    c.poly([(19, 13), (20, 8), (22, 13)], BONE_D)                           # ear
    c.line([(7, 20), (3, 16)], BONE)                                        # wagging tail
    return frames(c.img, 24)


def candle_moth():
    c = Canvas()
    c.ell(4, 10, 15, 22, (230, 200, 140)); c.ell(17, 10, 28, 22, (230, 200, 140))   # wings
    c.ell(6, 12, 13, 20, (250, 230, 170)); c.ell(19, 12, 26, 20, (250, 230, 170))
    c.ell(14, 12, 18, 26, BROWN)                                            # body
    c.rect(15, 6, 17, 11, WHITE); c.px(16, 4, FLAME); c.px(16, 5, EMBER)    # candle on its head
    c.px(15, 13, K); c.px(17, 13, K)
    return frames(c.img, 24)


def black_cat():
    c = Canvas()
    c.line([(8, 26), (4, 18), (6, 14)], CLOTH, 2)                           # tail up
    c.ell(7, 19, 21, 30, CLOTH)                                             # body
    c.ell(17, 13, 26, 22, CLOTH)                                            # head
    c.poly([(18, 14), (18, 9), (21, 13)], CLOTH); c.poly([(22, 13), (25, 9), (25, 14)], CLOTH)  # ears
    c.px(20, 17, (230, 220, 80)); c.px(23, 17, (230, 220, 80))              # eyes
    c.px(21, 19, PALE_D)
    return frames(c.img, 24)


def ember_salamander():
    c = Canvas()
    c.line([(4, 26), (9, 24)], EMBER, 2)                                    # tail
    c.ell(8, 21, 22, 28, CAPE); c.ell(10, 22, 20, 26, EMBER)                # body
    for x in (11, 15, 19):
        c.px(x, 21, FLAME)                                                  # glowing spots
    c.ell(19, 18, 27, 25, CAPE); c.px(24, 20, FLAME)                        # head, eye
    c.rect(10, 28, 11, 30, CAPE_D); c.rect(18, 28, 19, 30, CAPE_D)
    c.px(26, 16, FLAME); c.px(25, 14, EMBER)                                # little flame breath
    return frames(c.img, 26)


def lantern_wisp():
    c = Canvas()
    c.ell(9, 8, 23, 22, (120, 170, 220)); c.ell(11, 10, 21, 20, (190, 225, 245))   # glowing orb
    c.ell(13, 12, 19, 18, WHITE)
    c.px(14, 14, ST_D); c.px(18, 14, ST_D)                                  # little face
    c.poly([(12, 21), (16, 30), (20, 21)], (120, 170, 220))                 # wispy tail
    for x, y in ((6, 6), (25, 10), (8, 24), (24, 26)):
        c.px(x, y, (190, 225, 245))
    return frames(c.img, 24)


def gilded_rat():
    c = Canvas()
    c.line([(5, 27), (2, 23), (4, 19)], GOLD_D)                             # tail
    c.ell(6, 21, 20, 29, GOLD); c.ell(8, 23, 14, 28, GOLD_D)                # golden body
    c.ell(16, 20, 24, 27, GOLD); c.px(20, 22, RED)
    c.ell(16, 17, 19, 21, GOLD_D)
    c.ell(22, 25, 27, 30, (250, 220, 90)); c.px(24, 27, GOLD_D)             # a coin
    return frames(c.img, 27)


# ---------------------------------------------------------------- villagers (town life)

def villager_farmer():
    c = Canvas()
    c.rect(12, 25, 14, 31, BROWN_D); c.rect(17, 25, 19, 31, BROWN_D)
    c.rect(11, 14, 20, 26, (110, 90, 60)); c.rect(11, 22, 20, 23, BROWN_D)
    c.rect(13, 7, 18, 13, SKIN); c.px(14, 9, K); c.px(17, 9, K)
    c.rect(10, 5, 21, 6, (190, 160, 90)); c.rect(12, 2, 19, 5, (190, 160, 90))   # straw hat
    c.line([(21, 6), (23, 29)], BROWN); c.poly([(19, 6), (23, 2), (27, 6)], ST)    # pitchfork
    return frames(c.img, 24)


def villager_woman():
    c = Canvas()
    c.poly([(14, 13), (9, 31), (22, 31), (18, 13)], (120, 50, 50))           # dress
    c.rect(11, 20, 20, 21, (200, 190, 170))                                  # apron string
    c.rect(13, 6, 18, 12, SKIN); c.px(14, 8, K); c.px(17, 8, K)
    c.ell(11, 3, 20, 9, (90, 60, 40))                                        # hair / headscarf
    c.rect(19, 18, 22, 19, (120, 50, 50)); c.ell(20, 19, 27, 25, BROWN)      # basket
    c.px(22, 20, (200, 60, 60)); c.px(24, 20, (90, 150, 70))
    return frames(c.img, 24)


def villager_child():
    c = Canvas()
    c.rect(13, 26, 14, 31, BROWN_D); c.rect(17, 26, 18, 31, BROWN_D)
    c.rect(12, 18, 19, 26, (70, 90, 120))
    c.rect(13, 11, 18, 17, SKIN); c.px(14, 13, K); c.px(17, 13, K); c.px(15, 15, SKIN_D)
    c.rect(12, 9, 19, 11, (140, 90, 50))
    c.ell(20, 20, 25, 25, (180, 60, 50))                                     # a ball
    return frames(c.img, 26)


def villager_guard():
    c = Canvas()
    c.rect(12, 25, 14, 31, ST_D); c.rect(17, 25, 19, 31, ST_D)
    c.rect(11, 14, 20, 26, (80, 40, 40)); c.rect(12, 15, 19, 20, ST)         # tabard + mail
    c.rect(13, 7, 18, 13, SKIN); c.px(14, 9, K); c.px(17, 9, K)
    c.rect(12, 3, 19, 7, ST); c.rect(11, 6, 20, 7, ST_D)                     # kettle helm
    c.line([(9, 2), (9, 30)], BROWN); c.poly([(7, 4), (9, 0), (11, 4)], ST_L)  # spear
    c.rect(20, 17, 22, 18, (80, 40, 40)); c.rect(22, 18, 22, 19, ST_D)
    c.rect(21, 20, 24, 24, GOLD_D); c.rect(22, 21, 23, 23, FLAME)            # lantern
    return frames(c.img, 24)


# ---------------------------------------------------------------- beasts of the Cursed Isle

def dire_wolf(fur=(92, 88, 96), dark=(58, 54, 62), eye=(230, 70, 50)):
    c = Canvas()
    for x in (9, 12, 20, 23):
        c.rect(x, 24, x + 1, 31, dark)                                   # legs
    c.ell(6, 15, 25, 26, fur); c.ell(8, 17, 16, 23, dark)                # body
    c.poly([(6, 18), (1, 13), (4, 21)], fur)                             # tail
    c.ell(20, 10, 30, 19, fur); c.poly([(27, 14), (31, 16), (27, 18)], dark)  # head, snout
    c.poly([(21, 11), (22, 6), (24, 11)], dark)                          # ear
    c.px(25, 13, eye); c.px(29, 17, WHITE)
    return frames(c.img, 23)


def wild_boar(hide=(110, 76, 56), dark=(70, 46, 34)):
    c = Canvas()
    for x in (9, 13, 19, 23):
        c.rect(x, 25, x + 1, 31, dark)
    c.ell(6, 14, 26, 27, hide); c.line([(9, 15), (22, 13)], dark, 2)    # bristles
    c.ell(21, 16, 30, 25, hide); c.rect(28, 20, 30, 22, (190, 140, 120))  # snout
    c.poly([(26, 23), (29, 26), (27, 22)], BONE)                         # tusk
    c.px(24, 18, K); c.poly([(22, 15), (23, 11), (25, 16)], dark)
    return frames(c.img, 24)


def marsh_serpent(skin=(70, 110, 60), belly=(170, 160, 90), eye=(240, 200, 60)):
    c = Canvas()
    c.ell(3, 24, 17, 31, skin); c.ell(10, 21, 24, 29, skin)              # coils
    c.ell(5, 26, 14, 30, belly)
    c.line([(20, 23), (22, 14)], skin, 4)                                # rearing neck
    c.ell(18, 8, 28, 16, skin); c.px(24, 11, eye)                        # head
    c.line([(28, 14), (31, 13)], RED); c.px(31, 12, RED)                 # tongue
    for x, y in ((7, 26), (13, 24), (19, 25)):
        c.px(x, y, (40, 70, 40))
    return frames(c.img, 22)


def giant_spider(body=(46, 36, 52), mark=(190, 40, 40)):
    c = Canvas()
    for side in (-1, 1):
        for i, (dx, dy) in enumerate(((6, -4), (9, 0), (9, 4), (6, 8))):
            x0, y0 = 16 + side * 4, 21 + i - 1
            c.line([(x0, y0), (x0 + side * dx, y0 + dy - 6), (x0 + side * (dx + 3), y0 + dy + 4)], body)
    c.ell(9, 15, 23, 27, body); c.ell(12, 18, 20, 24, mark)              # abdomen with mark
    c.ell(13, 11, 19, 17, body)
    for x in (14, 15, 17, 18):
        c.px(x, 13, RED)                                                 # many eyes
    return frames(c.img, 24)


def cave_bear(fur=(96, 66, 44), dark=(62, 40, 28), eye=(30, 20, 20)):
    c = Canvas()
    c.rect(7, 24, 10, 31, dark); c.rect(20, 24, 23, 31, dark)
    c.ell(4, 10, 27, 28, fur); c.ell(7, 13, 16, 22, dark)                # huge body
    c.ell(18, 5, 29, 16, fur); c.ell(16, 3, 20, 7, fur); c.ell(25, 3, 29, 7, fur)  # head, ears
    c.ell(24, 10, 30, 15, (170, 130, 100)); c.px(29, 11, K)               # muzzle
    c.px(22, 9, eye); c.px(26, 9, eye)
    c.poly([(28, 24), (31, 27), (27, 27)], BONE)                         # claws
    return frames(c.img, 23)


def sand_crab(shell=(190, 80, 50), dark=(130, 50, 34)):
    c = Canvas()
    for x in (7, 10, 21, 24):
        c.line([(x, 24), (x + (-3 if x < 16 else 3), 30)], dark)
    c.ell(7, 16, 25, 27, shell); c.ell(9, 17, 17, 22, (220, 120, 80))
    c.ell(1, 10, 9, 17, shell); c.ell(23, 9, 31, 16, shell)               # claws
    c.line([(5, 13), (8, 11)], K)
    c.rect(13, 13, 13, 16, dark); c.rect(18, 13, 18, 16, dark); c.px(13, 12, K); c.px(18, 12, K)
    return frames(c.img, 24)


def lava_lizard(scale=(150, 40, 30), glow=(250, 150, 50)):
    c = Canvas()
    c.line([(2, 25), (9, 22)], scale, 3)
    c.ell(7, 18, 23, 27, scale)
    for x in (10, 14, 18):
        c.px(x, 19, glow); c.px(x + 1, 22, glow)
    c.ell(19, 14, 29, 22, scale); c.px(25, 16, FLAME)
    c.rect(9, 26, 10, 30, scale); c.rect(19, 26, 20, 30, scale)
    c.px(29, 18, glow); c.px(30, 16, FLAME)
    return frames(c.img, 25)


def bone_vulture(feather=(60, 50, 56), bone=BONE):
    c = Canvas()
    c.poly([(2, 12), (14, 16), (12, 22)], feather); c.poly([(30, 12), (18, 16), (20, 22)], feather)  # wings
    c.ell(11, 14, 21, 26, feather)
    c.line([(16, 14), (18, 8)], bone, 2); c.ell(16, 4, 23, 10, bone)     # bare neck and skull
    c.poly([(22, 7), (26, 9), (22, 10)], GOLD_D); c.px(19, 6, RED)
    c.rect(14, 26, 14, 30, GOLD_D); c.rect(18, 26, 18, 30, GOLD_D)
    return frames(c.img, 25)


def recolor(strip, mapping):
    """Bosses: the same creatures, recoloured and grown 1.5x (48x48 frames)."""
    from PIL import Image as _I
    w, h = strip.size
    big = strip.resize((w * 3 // 2, h * 3 // 2), _I.NEAREST)
    px = big.load()
    for y in range(big.height):
        for x in range(big.width):
            r, g, b, a = px[x, y]
            if a and (r, g, b) != K:
                nr, ng, nb = mapping(r, g, b)
                px[x, y] = (max(0, min(255, nr)), max(0, min(255, ng)), max(0, min(255, nb)), a)
    return big


BOSSES = {
    "ashen_alpha": (dire_wolf, lambda r, g, b: (r + 70, g + 30, b + 20)),            # pale ash wolf
    "bog_mother": (marsh_serpent, lambda r, g, b: (g // 2, g + 10, b + 60)),          # drowned blue-green
    "thornback": (cave_bear, lambda r, g, b: (r // 2, g + 40, b // 2)),                # moss-grown bear
    "tidecrusher": (sand_crab, lambda r, g, b: (b, g + 20, r + 40)),                  # deep-sea crab
    "pale_matriarch": (lambda: dire_wolf((200, 214, 230), (130, 150, 180), (120, 200, 255)), lambda r, g, b: (r, g, b + 10)),
    "cinder_drake": (lava_lizard, lambda r, g, b: (r + 40, g // 2, b // 3)),
    "drowned_abbot": (weeping_nun, lambda r, g, b: (r // 2, g + 30, b + 70)),           # 3.5: drowned, sea-green
    "slag_saint": (grave_knight, lambda r, g, b: (r + 90, g // 2 + 20, b // 4)),        # 3.7: iron saint, still glowing
    "tithe_taker": (bone_colossus, lambda r, g, b: (r * 2 // 3, g * 3 // 5, b * 3 // 4 + 10)),  # 3.7: ledger-grey bones, a little violet
}


SPRITES = {
    "varek": varek, "lys": lys, "aldric": aldric, "rook": rook, "vael": vael, "mordecai": mordecai, "wren": wren, "osric": osric,
    "ghoul": ghoul, "cultist": cultist, "bone_hound": bone_hound, "plague_rat": plague_rat,
    "weeping_nun": weeping_nun, "grave_knight": grave_knight, "bone_colossus": bone_colossus,
    "rotting_bishop": rotting_bishop, "rotting_bishop_enraged": lambda: rotting_bishop(True),
    "wick_mother": wick_mother, "wick_mother_enraged": lambda: wick_mother(True),
    "ash_crow": ash_crow, "grave_pup": grave_pup, "candle_moth": candle_moth, "black_cat": black_cat,
    "ember_salamander": ember_salamander, "lantern_wisp": lantern_wisp, "gilded_rat": gilded_rat,
    "villager_farmer": villager_farmer, "villager_woman": villager_woman, "villager_child": villager_child,
    "villager_guard": villager_guard,
    "dire_wolf": dire_wolf, "wild_boar": wild_boar, "marsh_serpent": marsh_serpent, "giant_spider": giant_spider,
    "cave_bear": cave_bear, "frost_wolf": lambda: dire_wolf((200, 214, 230), (130, 150, 180), (120, 200, 255)),
    "sand_crab": sand_crab, "lava_lizard": lava_lizard, "bone_vulture": bone_vulture,
}

if __name__ == "__main__":
    import os
    os.makedirs("assets/sprites", exist_ok=True)
    for name, fn in SPRITES.items():
        fn().save(f"assets/sprites/{name}.png")
        print("wrote", name)
    for name, (fn, mapping) in BOSSES.items():
        recolor(fn(), mapping).save(f"assets/sprites/{name}.png")
        print("wrote boss", name)
