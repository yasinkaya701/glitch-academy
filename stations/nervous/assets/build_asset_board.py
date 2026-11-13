#!/usr/bin/env python3
"""Build an honest, labeled review board from the authored nervous-system PNGs.

Requires Pillow. This is documentation only; labels and board background are not
part of any in-game texture. Run from the repository root:
  python3 stations/nervous/assets/build_asset_board.py
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[3]
ASSETS = ROOT / "stations/nervous/assets"
OUTPUT = ROOT / "docs/review/nervous_asset_board.png"
BG = (7, 11, 18, 255)
PANEL = (15, 24, 36, 255)
EDGE = (52, 70, 84, 255)
TEXT = (232, 241, 242, 255)
MUTED = (142, 164, 175, 255)
ACCENT = (111, 227, 193, 255)
W, H = 2600, 1670

font_path = "/System/Library/Fonts/Supplemental/Arial.ttf"
try:
    FONT = ImageFont.truetype(font_path, 28)
    SMALL = ImageFont.truetype(font_path, 20)
    TITLE = ImageFont.truetype(font_path, 46)
except OSError:
    FONT = SMALL = TITLE = ImageFont.load_default()

board = Image.new("RGBA", (W, H), BG)
draw = ImageDraw.Draw(board)
draw.text((72, 44), "REFLEX CENTRE  /  ASSET BOARD", font=TITLE, fill=TEXT)
draw.text((74, 108), "Authored transparent PNGs · composite samples · review board, not a running-scene screenshot", font=SMALL, fill=MUTED)


def card(x, y, w, h, label, subtitle=None):
    draw.rounded_rectangle((x, y, x + w, y + h), radius=16, fill=PANEL, outline=EDGE, width=2)
    draw.text((x + 24, y + 18), label, font=FONT, fill=TEXT)
    if subtitle:
        draw.text((x + 24, y + 54), subtitle, font=SMALL, fill=MUTED)
    return (x + 20, y + 92, w - 40, h - 110)


def image_on_card(path, box, contain=True):
    img = (path.copy() if isinstance(path, Image.Image) else Image.open(path)).convert("RGBA")
    max_w, max_h = box[2], box[3]
    img.thumbnail((max_w, max_h), Image.Resampling.LANCZOS)
    px = box[0] + (max_w - img.width) // 2
    py = box[1] + (max_h - img.height) // 2
    board.alpha_composite(img, (px, py))

# Composite the authored neuron layers in the exact order documented in README.
neuron = Image.new("RGBA", (2048, 1024), (0, 0, 0, 0))
for name in ("dendrites", "axon", "myelin", "nodes", "soma", "terminals"):
    neuron.alpha_composite(Image.open(ASSETS / f"neuron_layers_{name}.png").convert("RGBA"))
neuron_box = card(72, 176, 1290, 635, "Neuron · aligned six-layer composite", "dendrites → axon → myelin → Ranvier nodes → soma → terminals")
image_on_card(neuron, neuron_box)

synapse = Image.open(ASSETS / "synapse.png").convert("RGBA")
synapse.alpha_composite(Image.open(ASSETS / "vesicles.png").convert("RGBA"))
synapse_box = card(1384, 176, 790, 635, "Synapse · base + movable vesicles", "Presynaptic bouton on left; receptor membrane on right")
image_on_card(synapse, synapse_box)

cord_box = card(2196, 176, 332, 635, "Spinal cord", "Dorsal ↑ / ventral ↓")
image_on_card(ASSETS / "spinal_cord.png", cord_box)

hand_box = card(72, 839, 900, 704, "Reflex hand states · aligned swap", "Contact pose / withdrawn pose; same forearm anchor")
hand_pair = Image.new("RGBA", (4096, 1024), (0, 0, 0, 0))
hand_pair.alpha_composite(Image.open(ASSETS / "hand_arm.png").convert("RGBA"), (0, 0))
hand_pair.alpha_composite(Image.open(ASSETS / "hand_withdrawn.png").convert("RGBA"), (2048, 0))
image_on_card(hand_pair, hand_box)

muscle_box = card(994, 839, 900, 704, "Effector muscle states · aligned swap", "Relaxed / contracted")
muscle_pair = Image.new("RGBA", (4096, 1024), (0, 0, 0, 0))
muscle_pair.alpha_composite(Image.open(ASSETS / "muscle_relaxed.png").convert("RGBA"), (0, 0))
muscle_pair.alpha_composite(Image.open(ASSETS / "muscle_contracted.png").convert("RGBA"), (2048, 0))
image_on_card(muscle_pair, muscle_box)

stove_box = card(1916, 839, 612, 704, "Hot plate", "Isolated interaction prop")
image_on_card(ASSETS / "stove_hot.png", stove_box)

OUTPUT.parent.mkdir(parents=True, exist_ok=True)
board.convert("RGB").save(OUTPUT, optimize=True)
print(f"Wrote {OUTPUT.relative_to(ROOT)} ({W}×{H})")
