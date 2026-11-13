#!/usr/bin/env python3
"""Deterministically generate the Three Suns panorama and aligned RGBA layers."""
from math import cos, exp, pi, sin
from pathlib import Path
import random

from PIL import Image, ImageDraw, ImageFilter

OUT = Path(__file__).resolve().parent
W, H = 3840, 1080
SEED = 318

SUNS = [
    # file, panorama center, radius, core, rim
    ("sun_a.png", (770, 389), 142, (245, 176, 87), (255, 229, 169)),
    ("sun_b.png", (1960, 297), 124, (166, 221, 235), (240, 253, 255)),
    ("sun_c.png", (3146, 526), 153, (218, 128, 125), (255, 206, 184)),
]

def rgba(c, a=255):
    return (*c, int(a))

def bezier(p0, p1, p2, p3, n=160):
    pts = []
    for i in range(n + 1):
        t = i / n
        u = 1 - t
        pts.append((u**3*p0[0]+3*u*u*t*p1[0]+3*u*t*t*p2[0]+t**3*p3[0],
                    u**3*p0[1]+3*u*u*t*p1[1]+3*u*t*t*p2[1]+t**3*p3[1]))
    return pts

def draw_curve(draw, points, fill, width=1):
    draw.line(points, fill=fill, width=width, joint="curve")

def make_sun(name, center, radius, core, rim):
    """1024 square sun+glow; local anchor is exactly (512, 512)."""
    im = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    glow = Image.new("RGBA", im.size, (0, 0, 0, 0))
    pix = glow.load()
    for y in range(1024):
        for x in range(1024):
            d = ((x-512)**2 + (y-512)**2)**0.5
            t = max(0.0, 1 - d/495)
            # Broad transparent halo, tighter luminous inner haze.
            a = int(68 * t**2.1 + 62 * exp(-((d-radius*1.28)/(radius*.78))**2))
            if a:
                pix[x, y] = (*core, min(a, 104))
    im.alpha_composite(glow.filter(ImageFilter.GaussianBlur(8)))

    # Restrained broken corona: alternating short and long engraved rays.
    rays = Image.new("RGBA", im.size, (0, 0, 0, 0))
    rd = ImageDraw.Draw(rays)
    for i in range(84):
        a = 2*pi*i/84 + 0.017*sin(i*2.7)
        inner = radius + 9 + 4*sin(i*1.31)
        outer = radius + (28 if i % 4 == 0 else 13 + (i % 3)*2)
        p1 = (512+cos(a)*inner, 512+sin(a)*inner)
        p2 = (512+cos(a)*outer, 512+sin(a)*outer)
        rd.line([p1, p2], fill=rgba(rim, 95 if i%4==0 else 45), width=2 if i%4==0 else 1)
    im.alpha_composite(rays)

    # Disk gradient, with a pearly rim and a quiet off-axis hot spot.
    disk = Image.new("RGBA", im.size, (0, 0, 0, 0))
    dp = disk.load()
    for y in range(512-radius-4, 512+radius+5):
        for x in range(512-radius-4, 512+radius+5):
            dx, dy = x-512, y-512
            d = (dx*dx + dy*dy)**.5
            if d <= radius:
                t = d/radius
                spot = exp(-(((dx+radius*.24)/(radius*.70))**2 + ((dy+radius*.32)/(radius*.62))**2)*2)
                mix = min(.38, .12 + .24*spot + .08*t)
                col = tuple(round(core[k]*(1-mix)+rim[k]*mix) for k in range(3))
                alpha = int(255 * min(1, (radius-d)/2 + .5))
                dp[x, y] = (*col, alpha)
    im.alpha_composite(disk)

    # A small shadowed limb makes each body feel spherical instead of a flat badge.
    shade = Image.new("RGBA", im.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shade)
    sd.ellipse((512-radius*.53, 512-radius*.72, 512+radius*1.12, 512+radius*1.04),
               fill=(17, 28, 43, 49))
    shade = shade.filter(ImageFilter.GaussianBlur(radius*.2))
    im.alpha_composite(shade)
    # Thin optical highlight, interrupted at the poles.
    d = ImageDraw.Draw(im)
    d.arc((512-radius-2, 512-radius-2, 512+radius+2, 512+radius+2), 202, 337,
          fill=rgba(rim, 192), width=2)
    im.save(OUT / name, optimize=True)
    return im

def background():
    # Vertical and horizontal color drift: ink at the edges, mineral blue-green at center.
    im = Image.new("RGBA", (W, H))
    p = im.load()
    for y in range(H):
        vy = y/H
        for x in range(W):
            band = .5 + .5*cos((x/W-.5)*2*pi)
            horizon = exp(-((vy-.63)/.33)**2)
            p[x,y] = (int(5+8*band+4*horizon), int(10+17*band+7*horizon),
                      int(22+24*band+14*horizon), 255)
    return im

def build_panorama(sun_layers):
    im = background()
    d = ImageDraw.Draw(im, "RGBA")
    rng = random.Random(SEED)

    # Huge, delicate orbital ellipses give the sky a navigable structure.
    for box, start, end, color, width in [
        ((-520,-700,4350,1370), 193, 338, (91,158,171,85), 3),
        ((-260,-510,4130,1570), 16, 163, (120,147,184,53), 2),
        ((330,-1040,3530,1190), 26, 153, (197,141,101,58), 2),
        ((-700,-930,2800,1610), 230, 350, (95,117,172,60), 2),
        ((1470,-250,3970,1280), 72, 236, (178,112,115,42), 2),
    ]:
        d.arc(box, start, end, fill=color, width=width)

    # Crossing silk currents: paired edges around broad, asymmetric ribbon strokes.
    ribbons = [
        ((-130,835),(620,220),(1190,1030),(1970,520),(44,107,129,38)),
        ((610,-80),(1110,680),(1810,-150),(2490,480),(111,123,161,34)),
        ((1740,1170),(2340,430),(2920,1160),(3970,190),(137,89,101,31)),
        ((-100,390),(760,1050),(1230,180),(1860,770),(194,137,84,25)),
        ((2240,-100),(2700,760),(3190,110),(3900,750),(66,133,147,28)),
    ]
    for p0,p1,p2,p3,c in ribbons:
        pts = bezier(p0,p1,p2,p3)
        draw_curve(d, pts, c, 38)
        draw_curve(d, pts, (c[0]+25,c[1]+25,c[2]+25,52), 2)
        # parallel fine filament, offset by a slowly changing amount
        for off in (-13, 13):
            shifted = [(x, y+off+6*sin(i/19)) for i,(x,y) in enumerate(pts)]
            draw_curve(d, shifted, (c[0]+35,c[1]+30,c[2]+25,33), 1)

    # Exposed strata: broken, almost topographic bands around the horizon.
    for i in range(19):
        y0 = 590 + i*19
        pts = bezier((-100,y0), (790,y0-220+12*i), (2230,y0+155-6*i), (3970,y0-150+9*i), 220)
        alpha = 13 + (i%4)*5
        draw_curve(d, pts, (72+i*3, 119+i, 147+i*2, alpha), 1 if i%3 else 2)

    # Angular fragments: dark mineral shards, each outlined like a distant moon.
    shards = [
        [(332,270),(405,214),(448,240),(430,301),(374,330)],
        [(1252,718),(1314,667),(1356,702),(1338,766),(1280,779)],
        [(1710,146),(1750,108),(1806,137),(1788,176),(1736,184)],
        [(2560,821),(2611,774),(2665,804),(2650,852),(2592,869)],
        [(3490,293),(3550,246),(3612,266),(3587,320),(3520,332)],
        [(2970,132),(3002,102),(3047,114),(3031,152),(2992,163)],
    ]
    for i,poly in enumerate(shards):
        d.polygon(poly, fill=(12,21,34,214))
        d.line(poly+[poly[0]], fill=(109,143,159,125), width=2)
        d.line([poly[0],poly[2]], fill=(85,115,137,60), width=1)
        d.ellipse((poly[0][0]-3,poly[0][1]-3,poly[0][0]+3,poly[0][1]+3), fill=(213,203,175,130))

    # Fine stars, biased toward small clustered swarms. No random speckle field.
    for cluster in [(500,170,360,230),(1450,330,420,250),(2370,240,400,280),(3390,720,380,220)]:
        cx,cy,rx,ry = cluster
        for _ in range(95):
            x = int(rng.gauss(cx, rx/2.6)); y = int(rng.gauss(cy, ry/2.6))
            if not (0 <= x < W and 0 <= y < H):
                continue
            r = rng.choice([1,1,1,2,2,3])
            col = rng.choice([(181,211,216,105),(236,223,194,120),(127,183,201,120),(229,167,143,100)])
            d.ellipse((x-r,y-r,x+r,y+r), fill=col)
            if r == 3:
                d.line((x-8,y,x+8,y), fill=(*col[:3],80), width=1)
                d.line((x,y-8,x,y+8), fill=(*col[:3],80), width=1)

    # Three small, legible constellations stitched with off-white navigation lines.
    constellations = [
        [(250,520),(292,489),(329,528),(381,502),(418,548)],
        [(1470,170),(1506,205),(1542,164),(1588,197),(1617,153)],
        [(2741,430),(2780,392),(2826,411),(2858,369),(2902,399)],
    ]
    for pts in constellations:
        d.line(pts, fill=(184,205,200,73), width=1)
        for x,y in pts:
            d.ellipse((x-2,y-2,x+2,y+2), fill=(238,227,197,180))

    # Crescent silhouettes and floating orbit beads add scale and a sense of rupture.
    for x,y,r,ang,col in [(1090,904,49,35,(80,116,129,100)),(2250,86,37,210,(113,110,146,105)),(3600,911,58,318,(125,91,100,95))]:
        d.ellipse((x-r,y-r,x+r,y+r), fill=(10,17,31,210), outline=col, width=2)
        d.arc((x-r-10,y-r-10,x+r+10,y+r+10), ang, ang+145, fill=(*col[:3],130), width=2)
        d.ellipse((x+r*.72-4,y-r*.2-4,x+r*.72+4,y-r*.2+4), fill=(225,192,154,150))

    # Compose each anchor so source layers overlay at exactly their stated panorama position.
    for layer, (cx,cy), _, _, _ in zip(sun_layers, [s[1] for s in SUNS], [s[2] for s in SUNS], [s[3] for s in SUNS], [s[4] for s in SUNS]):
        im.alpha_composite(layer, (cx-512, cy-512))

    # Subtle foreground haze, hand-shaped to break the perfect clean horizon.
    haze = Image.new("RGBA", (W,H), (0,0,0,0))
    hd = ImageDraw.Draw(haze)
    for pts, color, width in [
        (bezier((-100,1010),(800,780),(1480,1150),(2220,937)),(73,119,137,23),90),
        (bezier((1620,1030),(2450,790),(3090,1120),(3980,900)),(158,91,92,20),75),
    ]:
        draw_curve(hd,pts,color,width)
    im.alpha_composite(haze.filter(ImageFilter.GaussianBlur(28)))
    return im

def main():
    layers = []
    for name, center, radius, core, rim in SUNS:
        layers.append(make_sun(name, center, radius, core, rim))
    pano = build_panorama(layers)
    pano.save(OUT / "three_suns_panorama.png", optimize=True)
    # Alias retained for callers that used the short name in early issue notes.
    pano.save(OUT / "three_suns.png", optimize=True)

if __name__ == "__main__":
    main()
