#!/usr/bin/env python3
"""
build_free_fall_assets.py
Generates the visual assets for stations/free_fall/assets/
according to docs/requests/004-free-fall.md.
"""

import os
import math
from PIL import Image, ImageDraw, ImageFilter

ASSET_DIR = os.path.abspath("stations/free_fall/assets")
os.makedirs(ASSET_DIR, exist_ok=True)

SS = 2  # Supersampling factor


def make_chamber_bg():
    w, h = 1920, 1080
    img = Image.new("RGBA", (w, h), (10, 15, 24, 255))
    draw = ImageDraw.Draw(img)
    
    # Overhead soft spotlight cone
    spot = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(spot)
    # Light beam triangle from center top
    beam = [(w // 2 - 80, 0), (w // 2 + 80, 0), (w // 2 + 520, h), (w // 2 - 520, h)]
    sdraw.polygon(beam, fill=(111, 227, 193, 24))
    spot = spot.filter(ImageFilter.GaussianBlur(80))
    img = Image.alpha_composite(img, spot)
    
    draw = ImageDraw.Draw(img)
    # Background lab wall horizontal panelling
    for y in range(120, h, 140):
        draw.line([(0, y), (w, y)], fill=(18, 28, 42, 140), width=1)
        
    # Vertical measurement tick rails in the background
    cx = w // 2
    for offset in [-340, 340]:
        x = cx + offset
        draw.line([(x, 60), (x, h - 80)], fill=(32, 50, 70, 200), width=2)
        for y in range(80, h - 80, 40):
            draw.line([(x - 8, y), (x + 8, y)], fill=(44, 69, 96, 200), width=1)
            
    # Ground metal lab stage floor
    draw.rectangle([(0, h - 90), (w, h)], fill=(14, 20, 32, 255))
    draw.line([(0, h - 90), (w, h - 90)], fill=(44, 69, 96, 255), width=2)
    draw.line([(0, h - 86), (w, h - 86)], fill=(111, 227, 193, 60), width=1)
    
    img.save(os.path.join(ASSET_DIR, "chamber_bg.png"), format="PNG")
    print("Generated: stations/free_fall/assets/chamber_bg.png")


def make_air_fault():
    w, h = 1920, 1080
    img = Image.new("RGBA", (w, h), (12, 16, 26, 255))
    draw = ImageDraw.Draw(img)
    
    # Red alarm ambient glow
    alarm = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    adraw = ImageDraw.Draw(alarm)
    adraw.ellipse([(w//2 - 400, 100), (w//2 + 400, 900)], fill=(229, 100, 90, 45))
    alarm = alarm.filter(ImageFilter.GaussianBlur(120))
    img = Image.alpha_composite(img, alarm)
    
    draw = ImageDraw.Draw(img)
    cx = w // 2
    
    # Glass tube outline with atmospheric air particles
    tube_w = 320
    tube_box = (cx - tube_w//2, 120, cx + tube_w//2, h - 140)
    draw.rounded_rectangle(tube_box, radius=24, outline=(229, 100, 90, 200), width=3)
    
    # Air swirl streamlines
    for y in range(200, 800, 60):
        draw.arc([(cx - 100, y), (cx + 100, y + 40)], start=160, end=380, fill=(242, 166, 90, 80), width=2)
        
    # Falling heavy brass sphere (dropped fast, near bottom)
    sphere_y = h - 260
    draw.ellipse([(cx - 70 - 32, sphere_y - 32), (cx - 70 + 32, sphere_y + 32)], fill=(242, 166, 90), outline=(255, 210, 150), width=2)
    # Downward speed streaks
    for sx in [-80, -60]:
        draw.line([(cx + sx, sphere_y - 120), (cx + sx, sphere_y - 45)], fill=(242, 166, 90, 180), width=3)
        
    # Feather floating slowly near top due to air drag
    feather_y = 280
    fx = cx + 60
    draw.line([(fx - 24, feather_y - 40), (fx + 24, feather_y + 40)], fill=(232, 241, 242), width=3)
    for i in range(-25, 25, 6):
        draw.line([(fx + i, feather_y + i*0.8), (fx + i + 14, feather_y + i*0.8 - 10)], fill=(180, 210, 225, 200), width=2)
        
    # Red Warning timing discrepancy badge at bottom
    warn_box = (cx - 240, h - 120, cx + 240, h - 60)
    draw.rounded_rectangle(warn_box, radius=8, fill=(35, 18, 22, 240), outline=(229, 100, 90), width=2)
    # Sensor miss timing graphic
    draw.line([(cx - 180, h - 90), (cx + 180, h - 90)], fill=(229, 100, 90, 140), width=2)
    draw.ellipse([(cx - 60, h - 96), (cx - 48, h - 84)], fill=(242, 166, 90))
    draw.ellipse([(cx + 90, h - 96), (cx + 102, h - 84)], fill=(229, 100, 90))
    
    img.save(os.path.join(ASSET_DIR, "air_fault.png"), format="PNG")
    print("Generated: stations/free_fall/assets/air_fault.png")


def make_sensor_plate():
    w, h = 512, 512
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    c = (w // 2, h // 2)
    
    # Outer ring
    draw.ellipse([(32, 32), (w - 32, h - 32)], fill=(16, 25, 38, 240), outline=(44, 69, 96, 255), width=4)
    # Inner piezo sensor plate
    draw.ellipse([(72, 72), (w - 72, h - 72)], fill=(22, 36, 54, 255), outline=(111, 227, 193, 200), width=3)
    # Laser / optic trigger crosshair lines
    draw.line([(c[0], 84), (c[0], h - 84)], fill=(111, 227, 193, 100), width=2)
    draw.line([(84, c[1]), (w - 84, c[1])], fill=(111, 227, 193, 100), width=2)
    # Concentric impact shockwave grooves
    for r in [50, 90, 130]:
        draw.arc([(c[0]-r, c[1]-r), (c[0]+r, c[1]+r)], start=0, end=360, fill=(44, 69, 96, 180), width=2)
    # Central target spot
    draw.ellipse([(c[0] - 16, c[1] - 16), (c[0] + 16, c[1] + 16)], fill=(242, 166, 90, 240), outline=(255, 220, 160), width=2)
    
    img.save(os.path.join(ASSET_DIR, "sensor_plate.png"), format="PNG")
    print("Generated: stations/free_fall/assets/sensor_plate.png")


if __name__ == "__main__":
    make_chamber_bg()
    make_air_fault()
    make_sensor_plate()
    print("Free fall assets built successfully.")
