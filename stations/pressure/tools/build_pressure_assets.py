#!/usr/bin/env python3
"""
build_pressure_assets.py
Generates visual assets for stations/pressure/assets/
"""

import os
from PIL import Image, ImageDraw, ImageFilter

ASSET_DIR = os.path.abspath("stations/pressure/assets")
os.makedirs(ASSET_DIR, exist_ok=True)


def make_pressure_bg():
    w, h = 1920, 1080
    img = Image.new("RGBA", (w, h), (9, 15, 23, 255))
    draw = ImageDraw.Draw(img)
    
    # Soft hydraulic bay spotlight
    light = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    ldraw = ImageDraw.Draw(light)
    ldraw.ellipse([(w//2 - 450, 80), (w//2 + 450, 750)], fill=(111, 227, 193, 22))
    light = light.filter(ImageFilter.GaussianBlur(95))
    img = Image.alpha_composite(img, light)
    
    draw = ImageDraw.Draw(img)
    # Industrial pipe conduits on wall
    for y in [140, 260]:
        draw.line([(0, y), (w, y)], fill=(30, 48, 68, 180), width=6)
        draw.line([(0, y - 2), (w, y - 2)], fill=(44, 69, 96, 220), width=2)
        
    # Reinforced hydraulic staging platform
    draw.rectangle([(0, h - 140), (w, h)], fill=(14, 21, 32, 255))
    draw.line([(0, h - 140), (w, h - 140)], fill=(44, 69, 96, 255), width=2)
    draw.line([(0, h - 136), (w, h - 136)], fill=(242, 166, 90, 80), width=1)
    
    img.save(os.path.join(ASSET_DIR, "pressure_bg.png"), format="PNG")
    print("Generated: stations/pressure/assets/pressure_bg.png")


def make_fault_pressure():
    w, h = 1920, 1080
    img = Image.new("RGBA", (w, h), (14, 16, 25, 255))
    draw = ImageDraw.Draw(img)
    
    # Red alarm ambient glow
    alarm = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    adraw = ImageDraw.Draw(alarm)
    adraw.ellipse([(w//2 - 380, 120), (w//2 + 380, 880)], fill=(229, 100, 90, 45))
    alarm = alarm.filter(ImageFilter.GaussianBlur(110))
    img = Image.alpha_composite(img, alarm)
    
    draw = ImageDraw.Draw(img)
    cx = w // 2
    cy = h // 2
    
    # Overpressure pipe burst indicator
    draw.rounded_rectangle([(cx - 250, cy - 180), (cx + 250, cy + 200)], radius=16, outline=(229, 100, 90, 200), width=3)
    # Pressure dial in red zone
    draw.ellipse([(cx - 60, cy - 80), (cx + 60, cy + 40)], outline=(229, 100, 90), width=3)
    draw.line([(cx, cy - 20), (cx + 45, cy - 50)], fill=(229, 100, 90), width=4)
    
    # High pressure alert box
    draw.rounded_rectangle([(cx - 220, h - 130), (cx + 220, h - 70)], radius=8, fill=(35, 18, 22, 240), outline=(229, 100, 90), width=2)
    
    img.save(os.path.join(ASSET_DIR, "fault_pressure.png"), format="PNG")
    print("Generated: stations/pressure/assets/fault_pressure.png")


if __name__ == "__main__":
    make_pressure_bg()
    make_fault_pressure()
    print("Pressure assets generated successfully.")
