#!/usr/bin/env python3
"""
build_indicator_assets.py
Generates visual assets for stations/indicator/assets/
"""

import os
from PIL import Image, ImageDraw, ImageFilter

ASSET_DIR = os.path.abspath("stations/indicator/assets")
os.makedirs(ASSET_DIR, exist_ok=True)


def make_lab_bg():
    w, h = 1920, 1080
    img = Image.new("RGBA", (w, h), (10, 14, 22, 255))
    draw = ImageDraw.Draw(img)
    
    # Soft chemistry lab workbench spotlight
    light = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    ldraw = ImageDraw.Draw(light)
    ldraw.ellipse([(w//2 - 400, 100), (w//2 + 400, 700)], fill=(111, 227, 193, 24))
    light = light.filter(ImageFilter.GaussianBlur(90))
    img = Image.alpha_composite(img, light)
    
    draw = ImageDraw.Draw(img)
    # Glassware shelf racks in background
    for y in [180, 340]:
        draw.line([(80, y), (w - 80, y)], fill=(28, 44, 62, 160), width=3)
        draw.line([(80, y + 4), (w - 80, y + 4)], fill=(111, 227, 193, 40), width=1)
        
    # Granite lab workbench
    draw.rectangle([(0, h - 160), (w, h)], fill=(14, 20, 30, 255))
    draw.line([(0, h - 160), (w, h - 160)], fill=(44, 69, 96, 255), width=2)
    draw.line([(0, h - 156), (w, h - 156)], fill=(111, 227, 193, 70), width=1)
    
    img.save(os.path.join(ASSET_DIR, "lab_bg.png"), format="PNG")
    print("Generated: stations/indicator/assets/lab_bg.png")


def make_fault_indicator():
    w, h = 1920, 1080
    img = Image.new("RGBA", (w, h), (14, 16, 24, 255))
    draw = ImageDraw.Draw(img)
    
    # Red alarm ambient glow
    alarm = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    adraw = ImageDraw.Draw(alarm)
    adraw.ellipse([(w//2 - 350, 150), (w//2 + 350, 850)], fill=(229, 100, 90, 45))
    alarm = alarm.filter(ImageFilter.GaussianBlur(120))
    img = Image.alpha_composite(img, alarm)
    
    draw = ImageDraw.Draw(img)
    cx = w // 2
    cy = h // 2
    
    # Acid corrosion warning beaker with toxic fumes
    draw.rounded_rectangle([(cx - 240, cy - 180), (cx + 240, cy + 200)], radius=16, outline=(229, 100, 90, 200), width=3)
    # Boiling bubbles & corrosive drip
    draw.line([(cx - 80, cy + 40), (cx + 80, cy + 40)], fill=(242, 166, 90), width=4)
    draw.ellipse([(cx - 40, cy - 20), (cx - 20, cy)], fill=(229, 100, 90))
    draw.ellipse([(cx + 30, cy - 60), (cx + 50, cy - 40)], fill=(242, 166, 90))
    
    # Alert banner
    draw.rounded_rectangle([(cx - 220, h - 130), (cx + 220, h - 70)], radius=8, fill=(35, 18, 22, 240), outline=(229, 100, 90), width=2)
    
    img.save(os.path.join(ASSET_DIR, "fault_indicator.png"), format="PNG")
    print("Generated: stations/indicator/assets/fault_indicator.png")


if __name__ == "__main__":
    make_lab_bg()
    make_fault_indicator()
    print("Indicator assets generated successfully.")
