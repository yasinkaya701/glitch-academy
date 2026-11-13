#!/usr/bin/env python3
"""
build_prism_assets.py
Generates visual assets for stations/prism/assets/
"""

import os
from PIL import Image, ImageDraw, ImageFilter

ASSET_DIR = os.path.abspath("stations/prism/assets")
os.makedirs(ASSET_DIR, exist_ok=True)


def make_prism_bg():
    w, h = 1920, 1080
    img = Image.new("RGBA", (w, h), (11, 16, 25, 255))
    draw = ImageDraw.Draw(img)
    
    # Soft ambient warehouse light
    light = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    ldraw = ImageDraw.Draw(light)
    ldraw.ellipse([(w//2 - 500, -100), (w//2 + 500, 700)], fill=(111, 227, 193, 20))
    light = light.filter(ImageFilter.GaussianBlur(100))
    img = Image.alpha_composite(img, light)
    
    draw = ImageDraw.Draw(img)
    # Storage bay isometric girders in background
    for x in range(160, w, 280):
        draw.line([(x, 0), (x, h - 80)], fill=(22, 35, 50, 140), width=2)
    for y in range(100, h - 80, 120):
        draw.line([(0, y), (w, y)], fill=(18, 28, 40, 100), width=1)
        
    # Heavy cargo platform floor
    draw.rectangle([(0, h - 100), (w, h)], fill=(15, 22, 34, 255))
    draw.line([(0, h - 100), (w, h - 100)], fill=(44, 69, 96, 255), width=2)
    
    img.save(os.path.join(ASSET_DIR, "prism_bg.png"), format="PNG")
    print("Generated: stations/prism/assets/prism_bg.png")


def make_fault_prism():
    w, h = 1920, 1080
    img = Image.new("RGBA", (w, h), (13, 17, 27, 255))
    draw = ImageDraw.Draw(img)
    
    # Red fault glow
    alarm = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    adraw = ImageDraw.Draw(alarm)
    adraw.ellipse([(w//2 - 350, 150), (w//2 + 350, 850)], fill=(229, 100, 90, 40))
    alarm = alarm.filter(ImageFilter.GaussianBlur(110))
    img = Image.alpha_composite(img, alarm)
    
    draw = ImageDraw.Draw(img)
    cx = w // 2
    cy = h // 2
    
    # Depict a toppled, unstable stack of unit cubes tumbling over
    draw.rounded_rectangle([(cx - 260, cy - 180), (cx + 260, cy + 220)], radius=16, outline=(229, 100, 90, 180), width=2)
    # Broken crate lines
    draw.line([(cx - 180, cy + 120), (cx + 20, cy - 40), (cx + 160, cy + 80)], fill=(242, 166, 90), width=3)
    draw.line([(cx - 20, cy + 60), (cx + 120, cy - 80)], fill=(229, 100, 90), width=3)
    
    # Warning plate
    draw.rounded_rectangle([(cx - 200, h - 140), (cx + 200, h - 80)], radius=8, fill=(35, 18, 22, 240), outline=(229, 100, 90), width=2)
    
    img.save(os.path.join(ASSET_DIR, "fault_prism.png"), format="PNG")
    print("Generated: stations/prism/assets/fault_prism.png")


if __name__ == "__main__":
    make_prism_bg()
    make_fault_prism()
    print("Prism assets generated successfully.")
