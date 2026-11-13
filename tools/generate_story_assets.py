#!/usr/bin/env python3
"""Generate the authored, deterministic bitmap assets for request 009.

Pillow only; no downloaded, traced, or AI-generated visual source is used.
"""
from __future__ import annotations

import math
import os
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
RNG = random.Random(19009)


def save(im: Image.Image, rel: str) -> None:
    path = ROOT / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    im.save(path, optimize=True)


def lerp(a, b, t):
    return a + (b - a) * t


def radial(size, center, stops, mode="RGBA"):
    w, h = size
    cx, cy = center
    out = Image.new(mode, size)
    pix = out.load()
    maxr = math.sqrt(max(cx, w-cx)**2 + max(cy, h-cy)**2)
    for y in range(h):
        for x in range(w):
            r = math.sqrt((x-cx)**2+(y-cy)**2)/maxr
            for i in range(len(stops)-1):
                if r <= stops[i+1][0]:
                    t = max(0, min(1, (r-stops[i][0])/(stops[i+1][0]-stops[i][0])))
                    c = tuple(round(lerp(stops[i][1][j], stops[i+1][1][j], t)) for j in range(len(stops[i][1])))
                    pix[x,y] = c
                    break
            else:
                pix[x,y] = stops[-1][1]
    return out


def draw_signature():
    p = "assets/world/signature/"
    specs = [
        ("tear_01.png", "h", 11, (105, 224, 229, 205), (235, 93, 151, 95), 7),
        ("tear_02.png", "h", 5, (91, 205, 227, 184), (230, 115, 162, 76), 19),
        ("tear_03.png", "v", 9, (105, 224, 229, 182), (235, 93, 151, 90), 31),
        ("tear_04.png", "v", 4, (94, 187, 221, 170), (225, 113, 173, 90), 43),
    ]
    for name, axis, width, cyan, mag, seed in specs:
        rng = random.Random(seed)
        im = Image.new("RGBA", (1920,1080))
        d = ImageDraw.Draw(im)
        if axis == "h":
            y = rng.randrange(180,900)
            for band, color, off in [(cyan,cyan,0),(mag,mag,2)]:
                x = 0
                while x < 1920:
                    length = rng.randint(34,230)
                    yj = y + off + rng.randint(-3,3)
                    d.line((x,yj,min(1920,x+length),yj+rng.randint(-2,2)), fill=color, width=width)
                    x += length + rng.randint(7,52)
        else:
            x = rng.randrange(300,1600)
            for color, off in [(cyan,0),(mag,3)]:
                y = 0
                while y < 1080:
                    length = rng.randint(28,155)
                    d.line((x+off,y,x+off+rng.randint(-2,2),min(1080,y+length)), fill=color, width=width)
                    y += length + rng.randint(9,48)
        im = im.filter(ImageFilter.GaussianBlur(0.45))
        save(im, p+name)
    noise = Image.new("RGBA", (1920,1080))
    d = ImageDraw.Draw(noise)
    rng = random.Random(71)
    for _ in range(440):
        y = rng.randrange(1080)
        h = rng.choice([1,1,2,3,5,8])
        x = rng.randrange(-200,1920)
        w = rng.randrange(16,560)
        alpha = rng.randrange(14,68)
        c = rng.choice([(91,205,227,alpha),(236,94,147,alpha),(204,225,231,alpha)])
        d.rectangle((x,y,x+w,y+h), fill=c)
    save(noise, p+"glitch_noise.png")
    ring = Image.new("RGBA", (512,512))
    d = ImageDraw.Draw(ring)
    box=(87,87,425,425)
    d.arc((box[0]-4,box[1],box[2]-4,box[3]), 8, 348, fill=(79,209,224,170), width=3)
    d.arc((box[0]+4,box[1]+3,box[2]+4,box[3]+3), 190, 170, fill=(227,91,151,142), width=2)
    d.arc((101,101,411,411), 18, 126, fill=(206,230,232,85), width=1)
    for x,y in [(148,88),(372,424),(424,180)]:
        d.ellipse((x-2,y-2,x+2,y+2), fill=(220,239,236,160))
    save(ring, p+"ghost_ring.png")


def draw_power_icons():
    root = "assets/ui/powers/"
    names = ["sar", "yavaslat", "ayir", "gor"]
    for state in ["normal", "pressed"]:
        for name in names:
            im = Image.new("RGBA", (96,96))
            d = ImageDraw.Draw(im)
            pressed = state == "pressed"
            fg = (111,227,193,255) if pressed else (207,225,230,245)
            soft = (111,227,193,90) if pressed else (127,182,245,105)
            shift = 1 if pressed else 0
            # A quiet inset perimeter makes pressed state legible without adding UI chrome.
            if pressed:
                d.rounded_rectangle((9,9,87,87), radius=16, outline=(111,227,193,125), width=1)
            ox, oy = shift, shift
            if name == "sar":
                d.arc((22+ox,22+oy,74+ox,74+oy), 40, 319, fill=fg, width=3)
                d.polygon([(23+ox,39+oy),(22+ox,25+oy),(36+ox,30+oy)], fill=fg)
                d.line((48+ox,34+oy,48+ox,45+oy), fill=fg, width=2)
                d.line((43+ox,45+oy,53+ox,45+oy), fill=fg, width=2)
                d.polygon([(44+ox,51+oy),(52+ox,51+oy),(50+ox,63+oy),(46+ox,63+oy)], fill=soft)
                d.line((44+ox,51+oy,52+ox,51+oy), fill=fg, width=2)
                d.line((46+ox,65+oy,50+ox,65+oy), fill=fg, width=2)
            elif name == "yavaslat":
                d.ellipse((21+ox,21+oy,75+ox,75+oy), outline=fg, width=3)
                d.pieslice((23+ox,23+oy,73+ox,73+oy), 90, 270, fill=soft)
                d.line((48+ox,22+oy,48+ox,74+oy), fill=fg, width=2)
                d.line((48+ox,48+oy,48+ox,27+oy), fill=fg, width=3)
            elif name == "ayir":
                d.rounded_rectangle((22+ox,22+oy,74+ox,74+oy), radius=3, outline=fg, width=3)
                d.line((31+ox,65+oy,65+ox,31+oy), fill=fg, width=3)
                d.line((47+ox,48+oy,69+ox,26+oy), fill=(7,11,18,255), width=5)
                d.line((49+ox,47+oy,68+ox,28+oy), fill=fg, width=2)
            elif name == "gor":
                d.arc((17+ox,29+oy,79+ox,67+oy), 180, 360, fill=fg, width=3)
                d.arc((17+ox,29+oy,79+ox,67+oy), 0, 180, fill=fg, width=3)
                d.ellipse((39+ox,36+oy,57+ox,60+oy), outline=fg, width=2)
                d.ellipse((45+ox,43+oy,51+ox,51+oy), fill=fg)
                for x in (31,39,47,55,63): d.line((x+ox,34+oy,x+ox,61+oy), fill=(111,227,193,48) if pressed else (127,182,245,42), width=1)
            if pressed:
                d.line((29,82,67,82), fill=(111,227,193,120), width=1)
            save(im, root+f"{name}_{state}.png")


def sphere_sprite(base, highlight, shadow, seed=0):
    size=256
    im=Image.new("RGBA",(size,size))
    # Supersampled sphere shading, with a small amount of material-specific grain.
    px=im.load(); rng=random.Random(seed)
    for y in range(size):
        for x in range(size):
            nx=(x-128)/91; ny=(y-128)/91
            r2=nx*nx+ny*ny
            if r2<=1:
                nz=math.sqrt(1-r2)
                light=max(0,(-nx*.44-ny*.54+nz*.72))
                edge=max(0,min(1,(1-math.sqrt(r2))/.08))
                grain=rng.choice([-2,-1,0,0,0,1,2]) if base[0]>150 else rng.choice([-3,-1,0,0,1,2])
                col=tuple(max(0,min(255,int((base[k]*(.20+.80*light)+shadow[k]*(1-light)) + grain))) for k in range(3))
                alpha=round(255*edge)
                px[x,y]=(*col,alpha)
    # Broad softbox reflection, clipped to the sphere rather than a graphic ring.
    gloss=Image.new("RGBA",(size,size)); gd=ImageDraw.Draw(gloss)
    gd.ellipse((68,62,131,92),fill=(*highlight,68))
    gloss=gloss.filter(ImageFilter.GaussianBlur(12))
    im=Image.alpha_composite(im,gloss)
    im=im.filter(ImageFilter.GaussianBlur(.35))
    return im


def draw_capsule():
    im=Image.new("RGBA",(256,256)); d=ImageDraw.Draw(im)
    d.rounded_rectangle((75,34,181,224), radius=52, fill=(123,151,161,255), outline=(215,229,226,255), width=3)
    d.rounded_rectangle((80,40,176,126), radius=44, fill=(177,74,69,255))
    d.rectangle((81,81,175,127), fill=(177,74,69,255))
    d.rectangle((81,126,175,134), fill=(185,205,205,255))
    d.rounded_rectangle((80,132,176,218), radius=42, fill=(219,228,221,255))
    d.rectangle((80,165,176,179), fill=(219,228,221,255))
    d.line((93,68,93,183), fill=(250,246,220,120), width=6)
    d.line((166,56,166,194), fill=(49,66,77,145), width=5)
    d.arc((75,34,181,224),190,345, fill=(244,247,233,190), width=2)
    save(im,"stations/free_fall/assets/capsule.png")


def draw_feather():
    im=Image.new("RGBA",(256,256)); d=ImageDraw.Draw(im)
    # Offset stem creates a readable, physical quill silhouette.
    d.line((71,203,187,51), fill=(224,226,212,220), width=4)
    d.polygon([(187,50),(164,61),(135,75),(105,100),(81,134),(67,169),(71,191),(85,187),(112,165),(135,139),(157,107),(177,77)], fill=(183,201,194,245), outline=(227,234,223,255))
    for t in range(10):
        x=177-t*9; y=67+t*12
        d.line((x,y,x-30,y+18), fill=(85,139,148,185), width=2)
        d.line((x-2,y+3,x+18,y+10), fill=(229,235,219,155), width=1)
    d.line((72,195,188,50), fill=(237,240,224,230), width=3)
    d.ellipse((65,188,79,202), fill=(237,240,224,215))
    save(im,"stations/free_fall/assets/feather.png")


def draw_hammer():
    im=Image.new("RGBA",(256,256)); d=ImageDraw.Draw(im)
    d.polygon([(111,92),(139,89),(173,197),(145,207)], fill=(119,83,55,255), outline=(199,154,103,255))
    d.line((120,105,151,195), fill=(221,180,125,160), width=4)
    d.rounded_rectangle((49,49,205,111), radius=9, fill=(100,116,123,255), outline=(223,231,225,255), width=3)
    d.rectangle((55,56,99,102), fill=(147,160,160,255))
    d.polygon([(170,53),(198,53),(199,105),(174,105)], fill=(73,89,99,255))
    d.line((66,60,185,60), fill=(246,244,223,160), width=3)
    d.line((158,73,158,99), fill=(207,220,216,100), width=2)
    save(im,"stations/free_fall/assets/hammer.png")


def draw_glass_highlight():
    w,h=160,600
    im=Image.new("RGBA",(w,h)); px=im.load()
    for y in range(h):
        # Long reflection with broken shoulders and softer center falloff.
        fade=min(1,y/25,(h-1-y)/25)
        for x in range(w):
            u=x/(w-1)
            a=math.exp(-((u-.29)/.055)**2)*82 + math.exp(-((u-.36)/.014)**2)*72
            a+=math.exp(-((u-.77)/.025)**2)*24
            if 260<y<390: a*=.24
            if 105<y<133 or 448<y<472: a*=.25
            a=max(0,min(130,round(a*fade)))
            px[x,y]=(151,218,225,a)
    save(im,"stations/free_fall/assets/glass_highlight.png")


def draw_freefall():
    p="stations/free_fall/assets/"
    save(sphere_sprite((177,187,186),(247,251,240),(53,64,70),3),p+"ball_steel.png")
    foam=sphere_sprite((226,205,157),(255,243,199),(95,83,60),11)
    d=ImageDraw.Draw(foam)
    rng=random.Random(10)
    for _ in range(130):
        x=rng.randrange(49,207); y=rng.randrange(49,207)
        if (x-128)**2+(y-128)**2<72**2:
            d.ellipse((x,y,x+1,y+1), fill=(162,139,95,100))
    save(foam,p+"ball_foam.png")
    draw_capsule(); draw_feather(); draw_hammer(); draw_glass_highlight()


def clear_chamber():
    """Make a quieter empty-vessel plate from the approved #4 chamber render."""
    source=Path(os.environ.get(
        "GLITCH_FREEFALL_REFERENCE",
        str(ROOT / "stations/free_fall/assets/chamber_bg.png"),
    ))
    im=Image.open(source).convert("RGB")
    # Preserve the original scene; reduce only interior residue/reflections in the glass
    # volume so the free chamber reads as empty beneath superimposed objects.
    px=im.load()
    for y in range(275,818):
        for x in range(500,627):
            # Keep the steel rails and glass boundary untouched; soften reflected objects
            # only within the chamber's central open volume.
            if 516 <= x <= 610:
                r,g,b=px[x,y]
                target=(14,23,28)
                blend=.18
                px[x,y]=tuple(round(lerp((r,g,b)[k],target[k],blend)) for k in range(3))
    # The broad right-side label field is intentionally darker and visually even.
    # A restrained overlay leaves the original wall texture intact.
    overlay=Image.new("RGBA",im.size,(0,0,0,0)); op=overlay.load()
    for x in range(960,1920):
        # A broad dark label field with a soft inward transition; preserves wall texture.
        t=min(1,(x-960)/180)
        alpha=round(52*t)
        for y in range(0,900):
            op[x,y]=(3,7,13,alpha)
    im=Image.alpha_composite(im.convert("RGBA"),overlay).convert("RGB")
    save(im,"stations/free_fall/assets/chamber_bg_clear.png")


if __name__ == "__main__":
    draw_signature(); draw_power_icons(); draw_freefall(); clear_chamber()
