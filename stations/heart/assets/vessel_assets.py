#!/usr/bin/env python3
"""Build the authored, seamless vessel tiles and connection-end sprites.

The PNGs are made from explicit geometry and deterministic surface variation;
the sibling SVGs remain editable vector sources. No external images are used.
Run from any directory with Python 3 and Pillow installed.
"""
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parent
S = 3


def smoothstep(a: float, b: float, x: float) -> float:
    t = max(0.0, min(1.0, (x - a) / (b - a)))
    return t * t * (3.0 - 2.0 * t)


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def make_tile(kind: str) -> Image.Image:
    artery = kind == "artery"
    w, h = 512, 128
    px = Image.new("RGBA", (w, h))
    data = []
    # The x-period is 128 px and divides the image exactly four times, making
    # both the painted fiber marks and edge pixels seamless in a repeated tile.
    for y in range(h):
        yn = y / (h - 1)
        top_edge, bottom_edge = (10, 118) if artery else (14, 114)
        alpha = int(255 * smoothstep(top_edge - 2, top_edge + 5, y) * (1 - smoothstep(bottom_edge - 5, bottom_edge + 2, y)))
        for x in range(w):
            phase = 2 * math.pi * x / 128
            fiber = 0.5 * math.sin(phase + 0.28 * math.sin(yn * 8)) + 0.22 * math.sin(2 * phase - yn * 9)
            mottling = 0.035 * math.sin(phase * 3 + yn * 28) * math.sin(yn * 21 + phase)
            if artery:
                outer_hi, outer_mid, outer_low = (224, 109, 99), (158, 48, 53), (73, 27, 35)
                lumen_top, lumen_mid, lumen_low = (52, 21, 27), (21, 13, 18), (41, 19, 24)
                lumen_a, lumen_b = 43, 85
                hue = (1.0, 0.82, 0.78)
                wall_highlight = (249, 173, 151)
            else:
                outer_hi, outer_mid, outer_low = (166, 178, 203), (100, 109, 149), (45, 50, 79)
                lumen_top, lumen_mid, lumen_low = (25, 28, 45), (13, 15, 28), (24, 26, 43)
                lumen_a, lumen_b = 31, 97
                hue = (0.83, 0.88, 1.0)
                wall_highlight = (195, 208, 222)

            # Outer vessel wall: thick muscular artery vs thin-walled vein.
            wall_t = min(1.0, abs(yn - 0.5) / 0.5)
            base = tuple(lerp(outer_hi[i], outer_low[i], smoothstep(0.05, 0.98, wall_t)) for i in range(3))
            for i in range(3):
                base = tuple(v * (1 + fiber * (0.035 if artery else 0.022) + mottling) for v in base)

            lumen_t = smoothstep(lumen_a - 3, lumen_a + 4, y) * (1 - smoothstep(lumen_b - 4, lumen_b + 3, y))
            if lumen_t > 0:
                ly = (y - lumen_a) / max(1, lumen_b - lumen_a)
                inner = tuple(lerp(lumen_top[i], lumen_low[i], smoothstep(0.0, 0.95, ly)) for i in range(3))
                inner = tuple(lerp(inner[i], lumen_mid[i], 0.62) for i in range(3))
                # A faint wet reflection follows the upper lumen wall but does
                # not turn into a glowing stripe.
                upper_reflect = max(0.0, 1 - abs(y - (lumen_a + 6)) / 5.5) * 0.13
                color = tuple(lerp(inner[i], wall_highlight[i], upper_reflect) for i in range(3))
                edge = min(smoothstep(lumen_a - 3, lumen_a + 3, y), 1 - smoothstep(lumen_b - 3, lumen_b + 3, y))
                color = tuple(lerp(base[i], color[i], edge) for i in range(3))
            else:
                color = base

            # Thin lamellar traces repeat at 128 px. This makes the tile feel
            # vascular while keeping the lumen and overlaid flow legible.
            ridge = max(0.0, math.cos(phase + yn * 4.0)) ** 22
            near_surface = 1.0 - smoothstep(0.2, 0.52, abs(yn - 0.5))
            ridge_amt = ridge * near_surface * (4.5 if artery else 2.3)
            rgb = tuple(max(0, min(255, int(c * hue[i] + ridge_amt))) for i, c in enumerate(color))
            data.append((*rgb, alpha))
    px.putdata(data)

    # Fine, physically motivated longitudinal wall folds; period and endpoints
    # match exactly so they do not form a seam when the sprite is tiled.
    d = ImageDraw.Draw(px, "RGBA")
    if artery:
        top_y, bottom_y = 16, 112
        inner_top, inner_bottom = 42, 86
        shade = (76, 28, 35, 72)
        glint = (255, 187, 161, 115)
    else:
        top_y, bottom_y = 19, 109
        inner_top, inner_bottom = 30, 98
        shade = (44, 49, 77, 65)
        glint = (204, 215, 232, 105)
    for n in range(5):
        y = top_y + n * 3
        d.line([(0, y), (w, y)], fill=glint if n == 0 else (glint[0], glint[1], glint[2], 34), width=1)
    for n in range(4):
        y = bottom_y - n * 4
        d.line([(0, y), (w, y)], fill=shade if n == 0 else (shade[0], shade[1], shade[2], 24), width=1)
    d.line([(0, inner_top), (w, inner_top)], fill=(255, 204, 180, 88) if artery else (205, 216, 235, 72), width=1)
    d.line([(0, inner_bottom), (w, inner_bottom)], fill=(11, 9, 15, 140), width=2)
    # Downsample without changing the tile bounds.
    return px.resize((w, h), Image.Resampling.LANCZOS)


def _ellipse(draw: ImageDraw.ImageDraw, box, fill, outline=None, width=1):
    draw.ellipse(tuple(int(v * S) for v in box), fill=fill, outline=outline, width=max(1, int(width * S)))


def _poly(draw: ImageDraw.ImageDraw, pts, fill):
    draw.polygon([(int(x * S), int(y * S)) for x, y in pts], fill=fill)


def make_cap(kind: str, attached: bool) -> Image.Image:
    artery = kind == "artery"
    im = Image.new("RGBA", (512 * S, 512 * S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im, "RGBA")
    if artery:
        hi, mid, low = (232, 127, 115, 255), (155, 52, 58, 255), (78, 28, 38, 255)
        dark, glint = (22, 12, 17, 255), (255, 190, 168, 230)
        rad_y = 112
    else:
        hi, mid, low = (179, 191, 214, 255), (103, 113, 151, 255), (47, 52, 84, 255)
        dark, glint = (15, 18, 32, 255), (208, 219, 236, 230)
        rad_y = 86

    # One-piece vessel stem enters from left. The flattened side view keeps a
    # common baseline/scale across all open and attached states.
    _poly(d, [(40, 171), (273, 171), (332, 192), (332, 320), (273, 341), (40, 341)], mid)
    d.line([(42*S, 178*S), (268*S, 178*S), (321*S, 196*S)], fill=hi, width=4*S)
    d.line([(45*S, 334*S), (270*S, 334*S), (321*S, 315*S)], fill=low, width=7*S)
    # Subtle longitudinal collagen grooves on the outside wall.
    for y in (196, 207, 305, 316):
        d.line([(76*S, y*S), (245*S, y*S)], fill=(hi[0], hi[1], hi[2], 66), width=2*S)

    # The attachment collar is an actual mechanical interface, with indexed
    # locking lugs and a circumferential gasket. The open end remains visible.
    if attached:
        _poly(d, [(218, 148), (335, 148), (376, 177), (376, 335), (335, 364), (218, 364)], (76, 91, 104, 255))
        _poly(d, [(226, 158), (329, 158), (360, 181), (360, 331), (329, 354), (226, 354)], (150, 164, 171, 255))
        d.line([(234*S, 163*S), (324*S, 163*S), (353*S, 184*S)], fill=(230, 235, 234, 255), width=4*S)
        for y in (187, 207, 295, 315, 335):
            d.line([(237*S, y*S), (342*S, y*S)], fill=(67, 81, 92, 220), width=3*S)
        # Clamp handles and rivets stay asymmetric to communicate a real lock.
        _poly(d, [(286, 130), (314, 130), (324, 163), (307, 174), (286, 162)], (105, 118, 126, 255))
        _poly(d, [(286, 350), (307, 338), (324, 349), (314, 382), (286, 382)], (83, 98, 108, 255))
        _ellipse(d, (302, 176, 314, 188), (222, 184, 127, 255), (44, 56, 66, 255), 2)
        _ellipse(d, (302, 324, 314, 336), (222, 184, 127, 255), (44, 56, 66, 255), 2)

    # Angled end face: layered wall, dark lumen and inner wet rim are all
    # separate shapes so the cut section reads as a real open vessel.
    _ellipse(d, (284, 256-rad_y, 424, 256+rad_y), low, (47, 56, 67, 255), 4)
    _ellipse(d, (294, 256-rad_y+10, 415, 256+rad_y-10), hi, (246, 203, 184, 220) if artery else (220, 227, 239, 210), 3)
    if attached:
        _ellipse(d, (306, 256-rad_y+23, 406, 256+rad_y-23), (75, 89, 102, 255), (206, 212, 209, 255), 4)
        inner_top, inner_bottom = 256-(rad_y-35), 256+(rad_y-35)
    else:
        inner_top, inner_bottom = 256-(rad_y-26), 256+(rad_y-26)
    _ellipse(d, (318, inner_top, 395, inner_bottom), dark, (73, 35, 40, 255) if artery else (34, 40, 64, 255), 3)
    # Inner wall crescent and a small wet highlight; no emissive/glow effect.
    d.arc((320*S, inner_top*S, 393*S, inner_bottom*S), 190, 278, fill=glint, width=3*S)
    d.line([(338*S, (inner_top+10)*S), (356*S, (inner_top+6)*S)], fill=(255, 222, 206, 92), width=2*S)
    return im.resize((512, 512), Image.Resampling.LANCZOS)


def svg_tile(kind: str) -> str:
    artery = kind == "artery"
    if artery:
        outer = "#9b343a"; highlight = "#e07b70"; lumen = "#180d12"; wall = 31; lumen_top = 43; lumen_bottom = 85
    else:
        outer = "#656f97"; highlight = "#a6b2cb"; lumen = "#0f1220"; wall = 17; lumen_top = 31; lumen_bottom = 97
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="512" height="128" viewBox="0 0 512 128">
<defs><linearGradient id="wall" x2="0" y2="1"><stop stop-color="{highlight}"/><stop offset=".4" stop-color="{outer}"/><stop offset="1" stop-color="{lumen}"/></linearGradient>
<linearGradient id="lumen" x2="0" y2="1"><stop stop-color="#3b1c22"/><stop offset=".45" stop-color="{lumen}"/><stop offset="1" stop-color="#32191e"/></linearGradient>
<pattern id="fiber" width="128" height="128" patternUnits="userSpaceOnUse"><path d="M5 18 C35 12 79 25 123 16 M0 28 C38 21 78 36 128 26" fill="none" stroke="{highlight}" stroke-opacity=".22" stroke-width="1.2"/><path d="M8 105 C41 99 82 112 124 103" fill="none" stroke="#130f18" stroke-opacity=".24" stroke-width="2"/><path d="M28 0 Q40 42 32 128 M94 0 Q82 64 96 128" fill="none" stroke="{highlight}" stroke-opacity=".06"/></pattern></defs>
<rect x="0" y="{wall}" width="512" height="{128-2*wall}" fill="url(#wall)"/>
<rect x="0" y="{lumen_top}" width="512" height="{lumen_bottom-lumen_top}" fill="url(#lumen)"/>
<rect width="512" height="128" fill="url(#fiber)"/>
<path d="M0 {lumen_top} H512" stroke="{highlight}" stroke-opacity=".5"/><path d="M0 {lumen_bottom} H512" stroke="#08080e" stroke-opacity=".78" stroke-width="2"/>
</svg>'''


def svg_cap(kind: str, attached: bool) -> str:
    is_art = kind == "artery"
    high, mid, low = ("#e87f73", "#9b343a", "#4e1c26") if is_art else ("#b3bfd6", "#677197", "#2f3454")
    cy, ry = 256, (112 if is_art else 86)
    collar = '''<path d="M218 148h117l41 29v158l-41 29H218z" fill="#96a4ab" stroke="#374751" stroke-width="8"/><path d="M234 162h91l28 21v146l-28 21h-91z" fill="#586773" stroke="#d2d8d5" stroke-width="4"/>''' if attached else ''
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
<defs><linearGradient id="tissue" x2="0" y2="1"><stop stop-color="{high}"/><stop offset=".5" stop-color="{mid}"/><stop offset="1" stop-color="{low}"/></linearGradient><radialGradient id="lumen"><stop stop-color="#090a10"/><stop offset=".82" stop-color="#17131a"/><stop offset="1" stop-color="{low}"/></radialGradient></defs>
<path d="M40 171h233l59 21v128l-59 21H40z" fill="url(#tissue)"/><path d="M44 180h225l45 17M45 333h224l45-17" fill="none" stroke="{high}" stroke-opacity=".72" stroke-width="6"/>
<path d="M75 198h166M76 207h160M75 305h166" fill="none" stroke="{high}" stroke-opacity=".19" stroke-width="3"/>{collar}
<ellipse cx="354" cy="{cy}" rx="70" ry="{ry}" fill="{low}" stroke="#37434d" stroke-width="8"/><ellipse cx="354" cy="{cy}" rx="59" ry="{ry-10}" fill="{high}" stroke="#eee0d5" stroke-opacity=".8" stroke-width="4"/>
<ellipse cx="357" cy="{cy}" rx="39" ry="{ry-31}" fill="url(#lumen)" stroke="{low}" stroke-width="4"/><path d="M325 {cy-39}a37 {ry-34} 0 0 0 5 53" fill="none" stroke="#f2c5b6" stroke-opacity=".7" stroke-width="4"/>
</svg>'''


def main() -> None:
    for kind in ("artery", "vein"):
        png = make_tile(kind)
        png.save(OUT / f"vessel_{kind}_tile.png", optimize=True)
        (OUT / f"vessel_{kind}_tile.svg").write_text(svg_tile(kind), encoding="utf-8")
        for state in ("open", "attached"):
            stem = f"vessel_cap_{kind}_{state}"
            make_cap(kind, state == "attached").save(OUT / f"{stem}.png", optimize=True)
            (OUT / f"{stem}.svg").write_text(svg_cap(kind, state == "attached"), encoding="utf-8")
    print("Generated two 512x128 seamless vessel tiles and four 512x512 RGBA connection caps.")


if __name__ == "__main__":
    main()
