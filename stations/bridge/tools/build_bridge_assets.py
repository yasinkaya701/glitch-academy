#!/usr/bin/env python3
"""
build_bridge_assets.py
Generates visual assets for stations/bridge/assets/
"""

import os
from PIL import Image, ImageDraw, ImageFilter

ASSET_DIR = os.path.abspath("stations/bridge/assets")
os.makedirs(ASSET_DIR, exist_ok=True)


def make_bridge_bg():
    w, h = 1920, 1080
    img = Image.new("RGBA", (w, h), (10, 16, 26, 255))
    draw = ImageDraw.Draw(img)
    
    # Atmospheric moonlight / river canyon mist
    mist = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    mdraw = ImageDraw.Draw(mist)
    mdraw.ellipse([(w//2 - 600, h - 350), (w//2 + 600, h + 100)], fill=(111, 227, 193, 20))
    mist = mist.filter(ImageFilter.GaussianBlur(100))
    img = Image.alpha_composite(img, mist)
    
    draw = ImageDraw.Draw(img)
    # Suspension cables & canyon silhouettes in background
    for i in range(-4, 5):
        cx = w // 2 + i * 220
        draw.line([(cx, 80), (cx + 80, h - 200)], fill=(24, 38, 54, 120), width=2)
        
    # River water reflection at bottom
    draw.rectangle([(0, h - 140), (w, h)], fill=(12, 22, 34, 255))
    draw.line([(0, h - 140), (w, h - 140)], fill=(44, 69, 96, 255), width=2)
    draw.line([(0, h - 136), (w, h - 136)], fill=(111, 227, 193, 60), width=1)
    
    img.save(os.path.join(ASSET_DIR, "bridge_bg.png"), format="PNG")
    print("Generated: stations/bridge/assets/bridge_bg.png")


def make_fault_bridge():
    w, h = 1920, 1080
    img = Image.new("RGBA", (w, h), (14, 16, 25, 255))
    draw = ImageDraw.Draw(img)
    
    # Red alarm ambient glow
    alarm = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    adraw = ImageDraw.Draw(alarm)
    adraw.ellipse([(w//2 - 400, 150), (w//2 + 400, 850)], fill=(229, 100, 90, 45))
    alarm = alarm.filter(ImageFilter.GaussianBlur(110))
    img = Image.alpha_composite(img, alarm)
    
    draw = ImageDraw.Draw(img)
    cx = w // 2
    cy = h // 2
    
    # Broken open drawbridge span
    draw.rounded_rectangle([(cx - 280, cy - 160), (cx + 280, cy + 200)], radius=16, outline=(229, 100, 90, 180), width=3)
    # Jagged sheared beam fracture
    draw.line([(cx - 160, cy + 100), (cx - 40, cy - 20)], fill=(242, 166, 90), width=5)
    draw.line([(cx + 40, cy - 40), (cx + 160, cy + 100)], fill=(229, 100, 90), width=5)
    
    # Alert banner
    draw.rounded_rectangle([(cx - 240, h - 130), (cx + 240, h - 70)], radius=8, fill=(35, 18, 22, 240), outline=(229, 100, 90), width=2)
    
    img.save(os.path.join(ASSET_DIR, "fault_bridge.png"), format="PNG")
    print("Generated: stations/bridge/assets/fault_bridge.png")


if __name__ == "__main__":
    make_bridge_bg()
    make_fault_bridge()
    print("Bridge assets generated successfully.")
