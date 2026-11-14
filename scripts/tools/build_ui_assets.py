#!/usr/bin/env python3
"""
build_ui_assets.py
Generates the complete UI Kit in assets/ui/ according to docs/requests/001-ui-kit.md
and docs/ART_DIRECTION.md.

Produces:
- assets/ui/panel_glass.png (512x512)
- assets/ui/btn_*.png (256x64)
- assets/ui/btn_primary_*.png (320x72)
- assets/ui/tab_*.png (192x48)
- assets/ui/list_row_*.png (512x56)
- assets/ui/badge_*.png (48x48)
- assets/ui/icons/*.png (128x128 for 9 stations)
- assets/ui/panel_info.png (512x768)
- assets/ui/bg_mission_frame.png (1920x1080)
- assets/ui/intro_title_plate.png (1280x360)
"""

import os
import math
from PIL import Image, ImageDraw, ImageFilter

UI_DIR = os.path.abspath("assets/ui")
ICONS_DIR = os.path.join(UI_DIR, "icons")
os.makedirs(ICONS_DIR, exist_ok=True)

# Palette
BG_COLOR = (7, 11, 18)
PANEL_COLOR = (15, 24, 36)
PANEL_RAISED = (22, 37, 56)
EDGE = (44, 69, 96)
EDGE_STRONG = (65, 98, 127)
CYAN_ACCENT = (111, 227, 193)
AMBER_ACCENT = (242, 166, 90)
INK = (232, 241, 242)
MUTED = (143, 166, 179)
DANGER = (229, 100, 90)

SS = 4  # 4x Supersampling for ultra-sharp anti-aliased geometry


def save_image(img_ss, path):
    w, h = img_ss.size
    img = img_ss.resize((w // SS, h // SS), Image.Resampling.LANCZOS)
    img.save(path, format="PNG")
    print(f"Generated: {os.path.relpath(path)}")


def draw_chamfered_rect(draw, bbox, chamfer, fill=None, outline=None, width=1):
    x0, y0, x1, y1 = bbox
    c = chamfer
    # Top-left and bottom-right cut corners
    points = [
        (x0 + c, y0),
        (x1, y0),
        (x1, y1 - c),
        (x1 - c, y1),
        (x0, y1),
        (x0, y0 + c)
    ]
    if fill:
        draw.polygon(points, fill=fill)
    if outline and width > 0:
        points.append(points[0])
        draw.line(points, fill=outline, width=width, joint="curve")


def draw_rounded_rect(draw, bbox, radius, fill=None, outline=None, width=1):
    draw.rounded_rectangle(bbox, radius=radius, fill=fill, outline=outline, width=width)


# 1. panel_glass.png (512x512)
def make_panel_glass():
    w, h = 512 * SS, 512 * SS
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    margin = 8 * SS
    chamfer = 24 * SS
    bbox = (margin, margin, w - margin, h - margin)
    
    # Base semi-transparent fill
    fill_color = (15, 24, 36, 215)
    draw_chamfered_rect(draw, bbox, chamfer, fill=fill_color)
    
    # Inner glow / subtle gradient overlay
    glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    draw_chamfered_rect(glow_draw, (margin + 4*SS, margin + 4*SS, w - margin - 4*SS, h - margin - 4*SS),
                        chamfer - 2*SS, fill=(111, 227, 193, 20))
    glow = glow.filter(ImageFilter.GaussianBlur(16 * SS))
    img = Image.alpha_composite(img, glow)
    
    draw = ImageDraw.Draw(img)
    # Border
    draw_chamfered_rect(draw, bbox, chamfer, fill=None, outline=(65, 98, 127, 240), width=2 * SS)
    # Subtle top highlight
    draw.line([(margin + chamfer, margin), (w - margin, margin)], fill=(111, 227, 193, 160), width=2 * SS)
    # Subtle corner accents
    draw.line([(margin, margin + chamfer), (margin + chamfer, margin)], fill=(111, 227, 193, 220), width=3 * SS)
    
    save_image(img, os.path.join(UI_DIR, "panel_glass.png"))


# 2. Buttons (256x64)
def make_buttons():
    w, h = 256 * SS, 64 * SS
    configs = {
        "normal": {"bg": (22, 37, 56, 240), "edge": (44, 69, 96, 255), "top_edge": (65, 98, 127, 255), "glow": 0},
        "hover": {"bg": (28, 47, 70, 255), "edge": (111, 227, 193, 255), "top_edge": (160, 240, 215, 255), "glow": 45},
        "pressed": {"bg": (14, 24, 36, 255), "edge": (65, 98, 127, 200), "top_edge": (20, 32, 48, 255), "glow": 0},
        "disabled": {"bg": (11, 18, 28, 180), "edge": (29, 44, 60, 160), "top_edge": (29, 44, 60, 160), "glow": 0}
    }
    
    for state, cfg in configs.items():
        img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        bbox = (3 * SS, 3 * SS, w - 3 * SS, h - 3 * SS)
        rad = 8 * SS
        
        if cfg["glow"] > 0:
            glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
            gdraw = ImageDraw.Draw(glow)
            draw_rounded_rect(gdraw, bbox, rad, fill=(111, 227, 193, cfg["glow"]))
            glow = glow.filter(ImageFilter.GaussianBlur(8 * SS))
            img = Image.alpha_composite(img, glow)
            draw = ImageDraw.Draw(img)
            
        draw_rounded_rect(draw, bbox, rad, fill=cfg["bg"], outline=cfg["edge"], width=2 * SS)
        draw.line([(bbox[0] + rad, bbox[1]), (bbox[2] - rad, bbox[1])], fill=cfg["top_edge"], width=2 * SS)
        save_image(img, os.path.join(UI_DIR, f"btn_{state}.png"))


# 3. Primary Buttons (320x72)
def make_primary_buttons():
    w, h = 320 * SS, 72 * SS
    configs = {
        "normal": {"bg": (201, 134, 56, 245), "edge": (242, 166, 90, 255), "top_edge": (255, 200, 140, 255), "glow": 25},
        "hover": {"bg": (226, 156, 72, 255), "edge": (255, 210, 140, 255), "top_edge": (255, 240, 190, 255), "glow": 60},
        "pressed": {"bg": (153, 98, 36, 255), "edge": (180, 115, 45, 255), "top_edge": (130, 80, 25, 255), "glow": 0},
        "disabled": {"bg": (68, 48, 32, 180), "edge": (99, 72, 48, 160), "top_edge": (80, 58, 40, 160), "glow": 0}
    }
    
    for state, cfg in configs.items():
        img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        bbox = (3 * SS, 3 * SS, w - 3 * SS, h - 3 * SS)
        rad = 10 * SS
        
        if cfg["glow"] > 0:
            glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
            gdraw = ImageDraw.Draw(glow)
            draw_rounded_rect(gdraw, bbox, rad, fill=(242, 166, 90, cfg["glow"]))
            glow = glow.filter(ImageFilter.GaussianBlur(10 * SS))
            img = Image.alpha_composite(img, glow)
            draw = ImageDraw.Draw(img)
            
        draw_rounded_rect(draw, bbox, rad, fill=cfg["bg"], outline=cfg["edge"], width=2 * SS)
        draw.line([(bbox[0] + rad, bbox[1]), (bbox[2] - rad, bbox[1])], fill=cfg["top_edge"], width=2 * SS)
        save_image(img, os.path.join(UI_DIR, f"btn_primary_{state}.png"))


# 4. Tabs (192x48)
def make_tabs():
    w, h = 192 * SS, 48 * SS
    # Idle
    img_idle = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw_idle = ImageDraw.Draw(img_idle)
    draw_idle.rectangle([(2*SS, 2*SS), (w - 2*SS, h - 2*SS)], fill=(11, 18, 26, 200), outline=(35, 55, 75, 200), width=1*SS)
    save_image(img_idle, os.path.join(UI_DIR, "tab_idle.png"))
    
    # Active
    img_active = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw_active = ImageDraw.Draw(img_active)
    draw_active.rectangle([(2*SS, 2*SS), (w - 2*SS, h - 2*SS)], fill=(22, 37, 56, 240), outline=(65, 98, 127, 240), width=1*SS)
    # Bottom amber bar (3px logical = 12px SS)
    draw_active.rectangle([(2*SS, h - 6*SS), (w - 2*SS, h - 2*SS)], fill=AMBER_ACCENT)
    save_image(img_active, os.path.join(UI_DIR, "tab_active.png"))


# 5. List Row (512x56)
def make_list_rows():
    w, h = 512 * SS, 56 * SS
    # Idle
    img_idle = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw_idle = ImageDraw.Draw(img_idle)
    draw_rounded_rect(draw_idle, (2*SS, 2*SS, w - 2*SS, h - 2*SS), 6*SS, fill=(15, 24, 36, 120), outline=(28, 44, 61, 180), width=1*SS)
    save_image(img_idle, os.path.join(UI_DIR, "list_row_idle.png"))
    
    # Selected
    img_sel = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw_sel = ImageDraw.Draw(img_sel)
    draw_rounded_rect(draw_sel, (2*SS, 2*SS, w - 2*SS, h - 2*SS), 6*SS, fill=(21, 37, 56, 220), outline=(111, 227, 193, 140), width=1*SS)
    # Left amber stripe
    draw_sel.rectangle([(2*SS, 6*SS), (6*SS, h - 6*SS)], fill=AMBER_ACCENT)
    save_image(img_sel, os.path.join(UI_DIR, "list_row_selected.png"))


# 6. Badges (48x48)
def make_badges():
    w, h = 48 * SS, 48 * SS
    center = (w // 2, h // 2)
    rad = 18 * SS
    
    # badge_done.png (Clean checkmark)
    img_done = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img_done)
    d.ellipse([center[0] - rad, center[1] - rad, center[0] + rad, center[1] + rad], fill=(24, 48, 42, 230), outline=(111, 227, 193, 255), width=2*SS)
    # Checkmark polyline
    chk = [
        (center[0] - 8*SS, center[1] + 1*SS),
        (center[0] - 2*SS, center[1] + 7*SS),
        (center[0] + 9*SS, center[1] - 6*SS)
    ]
    d.line(chk, fill=CYAN_ACCENT, width=3*SS, joint="curve")
    save_image(img_done, os.path.join(UI_DIR, "badge_done.png"))
    
    # badge_ready.png (Circular status light)
    img_ready = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img_ready)
    d.ellipse([center[0] - rad, center[1] - rad, center[0] + rad, center[1] + rad], fill=(36, 42, 32, 230), outline=(242, 166, 90, 255), width=2*SS)
    inner_rad = 7 * SS
    d.ellipse([center[0] - inner_rad, center[1] - inner_rad, center[0] + inner_rad, center[1] + inner_rad], fill=AMBER_ACCENT)
    save_image(img_ready, os.path.join(UI_DIR, "badge_ready.png"))
    
    # badge_locked.png (Crisp Padlock)
    img_locked = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img_locked)
    d.ellipse([center[0] - rad, center[1] - rad, center[0] + rad, center[1] + rad], fill=(22, 28, 38, 230), outline=(96, 117, 138, 255), width=2*SS)
    # Shackle
    d.arc([center[0] - 7*SS, center[1] - 11*SS, center[0] + 7*SS, center[1] + 1*SS], start=180, end=0, fill=(143, 166, 179), width=2*SS)
    # Body
    d.rectangle([center[0] - 8*SS, center[1] - 3*SS, center[0] + 8*SS, center[1] + 9*SS], fill=(96, 117, 138), outline=(143, 166, 179), width=1*SS)
    # Keyhole
    d.ellipse([center[0] - 2*SS, center[1] + 1*SS, center[0] + 2*SS, center[1] + 5*SS], fill=(22, 28, 38))
    save_image(img_locked, os.path.join(UI_DIR, "badge_locked.png"))


# 7. 9 Station Icons (128x128)
def make_icons():
    w, h = 128 * SS, 128 * SS
    c = (w // 2, h // 2)
    lw = 3 * SS  # 3px line width
    
    # 1. seasons.png (Tilted planet with axis & equator)
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    r = 38 * SS
    d.ellipse([c[0]-r, c[1]-r, c[0]+r, c[1]+r], outline=INK, width=lw)
    # 23.5 degree tilt axis line
    tilt_rad = math.radians(23.5)
    dx = math.sin(tilt_rad) * 52 * SS
    dy = math.cos(tilt_rad) * 52 * SS
    d.line([(c[0] - dx, c[1] + dy), (c[0] + dx, c[1] - dy)], fill=CYAN_ACCENT, width=lw)
    # Equator ellipse arc
    d.arc([c[0]-r, c[1]-14*SS, c[0]+r, c[1]+14*SS], start=0, end=360, fill=MUTED, width=lw-1*SS)
    # Arrow heads on axis
    d.polygon([(c[0]+dx, c[1]-dy), (c[0]+dx-6*SS, c[1]-dy+12*SS), (c[0]+dx+10*SS, c[1]-dy+8*SS)], fill=CYAN_ACCENT)
    save_image(img, os.path.join(ICONS_DIR, "seasons.png"))

    # 2. measurement.png (Ruler with Vernier scale)
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    rx0, ry0, rx1, ry1 = 20*SS, 44*SS, 108*SS, 84*SS
    d.rectangle([rx0, ry0, rx1, ry1], outline=INK, width=lw)
    # Ticks
    for i in range(9):
        x = rx0 + i * (11 * SS)
        tick_h = 16 * SS if i % 2 == 0 else 10 * SS
        d.line([(x, ry0), (x, ry0 + tick_h)], fill=CYAN_ACCENT, width=lw)
    # Sliding jaw
    d.rectangle([54*SS, 32*SS, 74*SS, 96*SS], outline=AMBER_ACCENT, width=lw)
    save_image(img, os.path.join(ICONS_DIR, "measurement.png"))

    # 3. vectors.png (Vector addition triangle with resultant)
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    p0 = (24*SS, 96*SS)
    p1 = (84*SS, 96*SS)
    p2 = (84*SS, 32*SS)
    # Vector A (east)
    d.line([p0, p1], fill=CYAN_ACCENT, width=lw)
    d.polygon([p1, (p1[0]-10*SS, p1[1]-6*SS), (p1[0]-10*SS, p1[1]+6*SS)], fill=CYAN_ACCENT)
    # Vector B (north)
    d.line([p1, p2], fill=MUTED, width=lw)
    d.polygon([p2, (p2[0]-6*SS, p2[1]+10*SS), (p2[0]+6*SS, p2[1]+10*SS)], fill=MUTED)
    # Resultant R (hypotenuse)
    d.line([p0, p2], fill=AMBER_ACCENT, width=lw+1*SS)
    d.polygon([p2, (p2[0]-10*SS, p2[1]+12*SS), (p2[0]+4*SS, p2[1]+14*SS)], fill=AMBER_ACCENT)
    save_image(img, os.path.join(ICONS_DIR, "vectors.png"))

    # 4. bridge.png (Truss bridge triangle)
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Base road
    d.line([(16*SS, 88*SS), (112*SS, 88*SS)], fill=INK, width=lw)
    # Truss struts
    pts = [(16*SS, 88*SS), (40*SS, 40*SS), (64*SS, 88*SS), (88*SS, 40*SS), (112*SS, 88*SS)]
    d.line(pts, fill=CYAN_ACCENT, width=lw)
    d.line([(40*SS, 40*SS), (88*SS, 40*SS)], fill=CYAN_ACCENT, width=lw)
    # Central load arrow pointing down
    d.line([(64*SS, 20*SS), (64*SS, 76*SS)], fill=AMBER_ACCENT, width=lw+1*SS)
    d.polygon([(64*SS, 78*SS), (58*SS, 66*SS), (70*SS, 66*SS)], fill=AMBER_ACCENT)
    save_image(img, os.path.join(ICONS_DIR, "bridge.png"))

    # 5. prism.png (Glass prism with light dispersion)
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Triangle prism
    p_top = (64*SS, 26*SS)
    p_left = (28*SS, 98*SS)
    p_right = (100*SS, 98*SS)
    d.polygon([p_top, p_left, p_right], outline=INK, width=lw)
    # Incident white ray
    d.line([(12*SS, 74*SS), (42*SS, 68*SS)], fill=INK, width=lw)
    # Dispersion fan exiting
    colors = [(255, 100, 100), (255, 180, 80), (100, 220, 180), (100, 160, 255)]
    for i, col in enumerate(colors):
        y_exit = (55 + i * 8) * SS
        d.line([(76*SS, 64*SS), (116*SS, y_exit)], fill=col, width=lw-1*SS)
    save_image(img, os.path.join(ICONS_DIR, "prism.png"))

    # 6. free_fall.png (Vacuum chamber with falling masses)
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Cylinder chamber tube
    d.rounded_rectangle([(36*SS, 16*SS), (92*SS, 112*SS)], radius=12*SS, outline=CYAN_ACCENT, width=lw)
    # Heavy mass (sphere)
    d.ellipse([(54*SS, 66*SS), (74*SS, 86*SS)], fill=AMBER_ACCENT)
    # Feather / light marker
    d.line([(64*SS, 32*SS), (64*SS, 46*SS)], fill=INK, width=lw)
    d.line([(58*SS, 38*SS), (70*SS, 36*SS)], fill=INK, width=lw)
    # Downward motion trails
    d.line([(64*SS, 88*SS), (64*SS, 102*SS)], fill=AMBER_ACCENT, width=lw)
    save_image(img, os.path.join(ICONS_DIR, "free_fall.png"))

    # 7. indicator.png (Erlenmeyer titration flask)
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Flask neck and body
    f_pts = [
        (54*SS, 20*SS), (74*SS, 20*SS),
        (74*SS, 48*SS), (102*SS, 104*SS),
        (26*SS, 104*SS), (54*SS, 48*SS)
    ]
    f_pts.append(f_pts[0])
    d.line(f_pts, fill=INK, width=lw)
    # Liquid level
    d.polygon([(36*SS, 84*SS), (92*SS, 84*SS), (98*SS, 100*SS), (30*SS, 100*SS)], fill=(111, 227, 193, 180))
    # Falling drop from burette
    d.ellipse([(61*SS, 30*SS), (67*SS, 38*SS)], fill=AMBER_ACCENT)
    save_image(img, os.path.join(ICONS_DIR, "indicator.png"))

    # 8. heart.png (4-chamber anatomical heart silhouette)
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Aorta arch
    d.arc([(50*SS, 16*SS), (86*SS, 46*SS)], start=180, end=0, fill=AMBER_ACCENT, width=lw)
    # Heart body curve
    h_pts = [
        (64*SS, 42*SS), (84*SS, 36*SS), (100*SS, 52*SS),
        (96*SS, 78*SS), (64*SS, 108*SS), (32*SS, 78*SS),
        (28*SS, 52*SS), (44*SS, 36*SS), (64*SS, 42*SS)
    ]
    d.line(h_pts, fill=INK, width=lw)
    # Septum division
    d.line([(64*SS, 44*SS), (64*SS, 104*SS)], fill=CYAN_ACCENT, width=lw)
    save_image(img, os.path.join(ICONS_DIR, "heart.png"))

    # 9. pressure.png (Manometer / dial pressure gauge)
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Dial circle
    d.ellipse([(24*SS, 24*SS), (104*SS, 104*SS)], outline=INK, width=lw)
    # Dial ticks
    for deg in range(135, 406, 45):
        rad_tick = math.radians(deg)
        x_in = 64*SS + math.cos(rad_tick) * 28 * SS
        y_in = 64*SS + math.sin(rad_tick) * 28 * SS
        x_out = 64*SS + math.cos(rad_tick) * 36 * SS
        y_out = 64*SS + math.sin(rad_tick) * 36 * SS
        d.line([(x_in, y_in), (x_out, y_out)], fill=CYAN_ACCENT, width=lw)
    # Dial needle pointing towards high pressure
    needle_rad = math.radians(310)
    d.line([(64*SS, 64*SS), (64*SS + math.cos(needle_rad)*26*SS, 64*SS + math.sin(needle_rad)*26*SS)], fill=AMBER_ACCENT, width=lw+1*SS)
    d.ellipse([(60*SS, 60*SS), (68*SS, 68*SS)], fill=INK)
    save_image(img, os.path.join(ICONS_DIR, "pressure.png"))


# 8. panel_info.png (512x768)
def make_panel_info():
    w, h = 512 * SS, 768 * SS
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    margin = 8 * SS
    chamfer = 20 * SS
    bbox = (margin, margin, w - margin, h - margin)
    
    # Base fill
    draw_chamfered_rect(draw, bbox, chamfer, fill=(15, 24, 36, 230), outline=(65, 98, 127, 240), width=2 * SS)
    # Header bar section
    header_h = 56 * SS
    draw.rectangle([(margin, margin + chamfer), (w - margin, margin + header_h)], fill=(22, 37, 56, 255))
    draw.line([(margin, margin + header_h), (w - margin, margin + header_h)], fill=CYAN_ACCENT, width=2 * SS)
    
    save_image(img, os.path.join(UI_DIR, "panel_info.png"))


# 9. bg_mission_frame.png (1920x1080)
def make_mission_frame():
    w, h = 1920, 1080
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Metal console frame around margins
    top_bar = 48
    bottom_bar = 56
    left_bar = 32
    right_bar = 32
    
    # Fill borders
    frame_col = (10, 16, 25, 255)
    draw.rectangle([(0, 0), (w, top_bar)], fill=frame_col)
    draw.rectangle([(0, h - bottom_bar), (w, h)], fill=frame_col)
    draw.rectangle([(0, 0), (left_bar, h)], fill=frame_col)
    draw.rectangle([(w - right_bar, 0), (w, h)], fill=frame_col)
    
    # Crisp cyan/teal accent lines
    draw.line([(left_bar, top_bar), (w - right_bar, top_bar)], fill=(44, 69, 96, 255), width=2)
    draw.line([(left_bar, h - bottom_bar), (w - right_bar, h - bottom_bar)], fill=(44, 69, 96, 255), width=2)
    draw.line([(left_bar, top_bar), (left_bar, h - bottom_bar)], fill=(44, 69, 96, 255), width=2)
    draw.line([(w - right_bar, top_bar), (w - right_bar, h - bottom_bar)], fill=(44, 69, 96, 255), width=2)
    
    # Corner screw markers
    screws = [
        (16, 24), (w - 16, 24),
        (16, h - 28), (w - 16, h - 28)
    ]
    for sx, sy in screws:
        draw.ellipse([(sx - 4, sy - 4), (sx + 4, sy + 4)], fill=(44, 69, 96), outline=(65, 98, 127), width=1)
    
    img.save(os.path.join(UI_DIR, "bg_mission_frame.png"), format="PNG")
    print("Generated: assets/ui/bg_mission_frame.png")


# 10. intro_title_plate.png (1280x360)
def make_title_plate():
    w, h = 1280, 360
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Distressed observatory brushed steel plate
    draw.rectangle([(16, 16), (w - 16, h - 16)], fill=(12, 18, 28, 235), outline=(44, 69, 96, 255), width=2)
    # Subtle inner border
    draw.rectangle([(24, 24), (w - 24, h - 24)], outline=(30, 48, 68, 200), width=1)
    # Diagonal fracture / warning seam in top right
    draw.line([(w - 180, 24), (w - 140, 80), (w - 110, 70), (w - 70, 140)], fill=(229, 100, 90, 220), width=2)
    # Blinking red alert LED on top corner
    draw.ellipse([(w - 48, 36), (w - 36, 48)], fill=(229, 100, 90, 255), outline=(255, 150, 140, 255), width=1)
    
    img.save(os.path.join(UI_DIR, "intro_title_plate.png"), format="PNG")
    print("Generated: assets/ui/intro_title_plate.png")


if __name__ == "__main__":
    print("Building UI assets...")
    make_panel_glass()
    make_buttons()
    make_primary_buttons()
    make_tabs()
    make_list_rows()
    make_badges()
    make_icons()
    make_panel_info()
    make_mission_frame()
    make_title_plate()
    print("ALL UI ASSETS GENERATED SUCCESSFULLY!")
