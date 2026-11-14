#!/usr/bin/env python3
"""Regenerate the authored Godot lab backdrop and the Pillow game sprites."""
from __future__ import annotations

import math
import random
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

OUT = Path(__file__).resolve().parent


def save(image: Image.Image, name: str) -> None:
    image.save(OUT / name, optimize=True)


def gradient(size, top, bottom):
    w,h=size
    im=Image.new("RGB",size)
    pix=im.load()
    for y in range(h):
        t=y/max(1,h-1)
        c=tuple(round(top[i]*(1-t)+bottom[i]*t) for i in range(3))
        for x in range(w): pix[x,y]=c
    return im


def add_grain(im, amount=2, seed=45):
    rng=random.Random(seed)
    px=im.load(); w,h=im.size
    for _ in range(w*h//2):
        x=rng.randrange(w); y=rng.randrange(h)
        r,g,b=px[x,y]; delta=rng.randint(-amount,amount)
        px[x,y]=(max(0,min(255,r+delta)),max(0,min(255,g+delta)),max(0,min(255,b+delta)))
    return im


def glow(size, center, radius, color, alpha=120):
    w,h=size; cx,cy=center
    layer=Image.new("RGBA",size); p=layer.load()
    for y in range(max(0,int(cy-radius*2)),min(h,int(cy+radius*2))):
        for x in range(max(0,int(cx-radius*2)),min(w,int(cx+radius*2))):
            d=math.hypot(x-cx,y-cy)/radius
            a=round(alpha*math.exp(-d*d*1.15))
            p[x,y]=(*color,a)
    return layer


def rounded_gradient(im, box, top, bottom, radius, outline=None, width=1):
    x1,y1,x2,y2=box; rw=x2-x1+1; rh=y2-y1+1
    layer=Image.new("RGBA",(rw,rh)); p=layer.load()
    for y in range(rh):
        t=y/max(1,rh-1); c=tuple(round(top[i]*(1-t)+bottom[i]*t) for i in range(3))
        for x in range(rw): p[x,y]=(*c,255)
    mask=Image.new("L",(rw,rh)); ImageDraw.Draw(mask).rounded_rectangle((0,0,rw-1,rh-1),radius=radius,fill=255)
    layer.putalpha(mask); im.alpha_composite(layer,(x1,y1))
    if outline: ImageDraw.Draw(im).rounded_rectangle(box,radius=radius,outline=outline,width=width)


def draw_background():
    """Render the hand-authored Godot 3D night lab to the root asset folder."""
    import os
    import shutil
    import subprocess

    root=OUT.parents[2]
    configured=os.environ.get("GODOT_BIN")
    candidates=[configured, "/private/tmp/Godot.app/Contents/MacOS/Godot", "godot", "godot4"]
    executable=None
    for candidate in candidates:
        if not candidate:
            continue
        found=shutil.which(candidate) if candidate in ("godot", "godot4") else candidate
        if found and Path(found).is_file():
            executable=found
            break
    if executable is None:
        raise RuntimeError("Godot 4 is required for range_bg.png; set GODOT_BIN to its executable")
    subprocess.run([
        executable, "--path", str(root),
        "res://stations/projectile/assets/generate_range_bg.tscn",
    ], check=True, cwd=root)

def metallic_ball(color, rim, seed):
    size=128; im=Image.new("RGBA",(size,size)); p=im.load(); rng=random.Random(seed)
    cx=cy=63.5; radius=49
    for y in range(size):
        for x in range(size):
            nx=(x-cx)/radius; ny=(y-cy)/radius; rr=nx*nx+ny*ny
            if rr<=1:
                nz=math.sqrt(max(0,1-rr)); dot=max(0,-.48*nx-.55*ny+.68*nz)
                limb=math.sqrt(max(0,1-rr))
                grain=rng.choice((-3,-1,0,0,1,2))
                shade=.24+.76*dot
                col=tuple(max(0,min(255,round(color[k]*shade+grain))) for k in range(3))
                alpha=255 if rr<.985 else round(255*(1-(rr-.985)/.015))
                p[x,y]=(*col,alpha)
    # Broad softbox and narrow amber key glints, clipped by the silhouette.
    spec=Image.new("RGBA",(size,size)); sd=ImageDraw.Draw(spec)
    sd.ellipse((23,18,62,37),fill=(255,246,220,96))
    sd.line((32,23,51,20),fill=(255,255,241,100),width=3)
    spec=spec.filter(ImageFilter.GaussianBlur(7))
    alpha=im.getchannel("A"); spec.putalpha(Image.eval(spec.getchannel("A"),lambda v:v))
    clip=Image.new("L",(size,size)); ImageDraw.Draw(clip).ellipse((14,14,113,113),fill=255)
    from PIL import ImageChops
    spec.putalpha(ImageChops.multiply(spec.getchannel("A"),clip))
    im=Image.alpha_composite(im,spec)
    d=ImageDraw.Draw(im)
    # Painted identification band is part of the physical object, not an overlay label.
    d.arc((16,15,112,112),198,255,fill=(*rim,220),width=4)
    d.arc((21,20,107,107),205,249,fill=(255,245,220,130),width=1)
    return im.filter(ImageFilter.GaussianBlur(.25))


def draw_launcher():
    w,h=640,384; im=Image.new("RGBA",(w,h)); d=ImageDraw.Draw(im)
    # Soft contact shadow under the base.
    shadow=Image.new("RGBA",(w,h)); sh=ImageDraw.Draw(shadow)
    sh.ellipse((22,318,618,361),fill=(0,0,0,135)); shadow=shadow.filter(ImageFilter.GaussianBlur(12)); im=Image.alpha_composite(im,shadow); d=ImageDraw.Draw(im)
    # Heavy base casting with feet, slotted rail and precision mounting points.
    rounded_gradient(im,(42,284,598,331),(80,94,96),(16,27,34),8,(115,131,133,255),3)
    d=ImageDraw.Draw(im)
    d.polygon([(53,327),(587,327),(568,349),(74,349)],fill=(12,19,24,255),outline=(72,85,90,255))
    d.line((65,291,578,291),fill=(196,169,119,165),width=2)
    for x in range(81,580,70):
        d.ellipse((x,306,x+13,319),fill=(9,15,20,255),outline=(112,128,130,210),width=2)
        d.ellipse((x+4,310,x+9,315),fill=(204,177,127,160))
    # Pneumatic launcher body points right, with a machined barrel, feed block and coupler seams.
    rounded_gradient(im,(69,157,430,224),(147,159,151),(32,47,56),18,(186,196,184,255),3)
    d=ImageDraw.Draw(im)
    rounded_gradient(im,(77,166,417,213),(48,64,72),(11,21,28),13,(105,125,132,255),2)
    d=ImageDraw.Draw(im)
    d.rectangle((101,173,393,206),fill=(17,27,34,255))
    d.ellipse((376,168,435,212),fill=(74,91,98,255),outline=(205,205,183,255),width=3)
    d.ellipse((390,176,432,204),fill=(7,13,18,255),outline=(105,128,135,255),width=3)
    d.ellipse((402,181,429,199),fill=(13,25,32,255))
    d.line((89,162,391,162),fill=(239,203,144,210),width=3)
    # Two brass locking collars and a pressure chamber with heat-darkened rings.
    for x in (123,331):
        d.rounded_rectangle((x,149,x+20,232),radius=4,fill=(124,104,73,255),outline=(224,197,147,255),width=2)
        d.line((x+4,154,x+4,226),fill=(246,215,159,145),width=2)
        d.line((x+15,155,x+15,226),fill=(42,50,52,220),width=2)
    rounded_gradient(im,(164,226,296,270),(78,94,98),(21,34,40),7,(145,161,158,255),2)
    d=ImageDraw.Draw(im)
    d.line((174,235,286,235),fill=(207,186,145,150),width=2)
    for x in (177,283): d.ellipse((x,246,x+9,255),fill=(8,14,19,255),outline=(132,146,142,255),width=2)
    # Pressure hose exits to the rear and loops into a regulator block.
    d.line([(78,187),(48,187),(35,198),(35,246),(65,257),(101,257)],fill=(77,91,95,255),width=13,joint="curve")
    d.line([(78,184),(48,184),(39,197),(39,242),(67,252),(101,252)],fill=(181,172,143,210),width=3,joint="curve")
    d.rounded_rectangle((80,242,145,278),radius=5,fill=(50,63,68,255),outline=(157,170,160,255),width=2)
    d.ellipse((99,247,129,274),fill=(18,27,31,255),outline=(214,181,124,255),width=2)
    d.line((114,260,122,252),fill=(244,183,109,255),width=2)
    # Adjustable stand and small electromagnetic release head above the muzzle.
    d.rectangle((435,139,450,286),fill=(42,57,63,255),outline=(151,164,159,255),width=2)
    d.polygon([(422,138),(466,138),(458,154),(430,154)],fill=(82,98,102,255),outline=(210,207,184,255))
    d.rounded_rectangle((421,100,469,141),radius=7,fill=(35,50,58,255),outline=(180,192,180,255),width=3)
    d.ellipse((428,130,462,149),fill=(116,139,143,255),outline=(218,214,188,255),width=2)
    d.ellipse((434,138,456,145),fill=(18,28,33,255))
    d.line((445,97,445,75),fill=(119,139,140,255),width=5)
    d.line((445,77,510,77),fill=(112,128,128,255),width=5)
    d.line((510,77,510,97),fill=(119,139,140,255),width=5)
    d.rounded_rectangle((492,95,529,121),radius=5,fill=(47,64,70,255),outline=(187,197,183,255),width=2)
    d.ellipse((500,115,521,124),fill=(204,161,90,220),outline=(241,215,158,255),width=2)
    # Amber status bead indicates the release coil has power; it is functional, not decoration.
    d.ellipse((504,101,510,107),fill=(242,166,90,255))
    # Top-side air-valve and braided wire.
    d.rounded_rectangle((237,131,294,158),radius=4,fill=(41,53,59,255),outline=(154,165,160,255),width=2)
    d.arc((247,114,284,147),180,360,fill=(145,159,156,255),width=3)
    d.line([(263,129),(263,115),(317,115),(317,145)],fill=(96,124,131,255),width=4,joint="curve")
    d.line((268,119,310,119),fill=(198,201,181,120),width=1)
    save(im,"launcher.png")


def draw_target():
    # Low-profile floor receiver: segmented aluminum rim around a flush glass light guide.
    w,h=512,192
    im=Image.new("RGBA",(w,h)); d=ImageDraw.Draw(im)
    # base shadow and gasket
    d.ellipse((43,55,469,163),fill=(0,0,0,130))
    d.ellipse((52,37,460,147),fill=(12,20,25,255),outline=(106,123,124,255),width=4)
    d.ellipse((74,44,438,135),fill=(26,37,41,255),outline=(71,87,91,255),width=3)
    # Interrupted metal annulus with recessed bolt heads.
    d.arc((59,41,453,143),185,355,fill=(207,192,156,235),width=6)
    d.arc((59,41,453,143),5,175,fill=(132,148,149,230),width=6)
    for x in (93,156,255,354,417):
        y=100-int(28*math.sqrt(max(.05,1-((x-255)/202)**2)))
        d.ellipse((x-5,y-4,x+5,y+4),fill=(13,20,25,255),outline=(187,178,147,220),width=2)
    d.ellipse((118,55,394,122),fill=(8,15,19,255),outline=(59,75,79,255),width=2)
    d.ellipse((159,65,353,111),outline=(61,77,82,190),width=2)
    # Fine crosshair is physically engraved into the flush diffuser.
    d.line((255,69,255,108),fill=(127,145,146,100),width=2)
    d.line((178,88,332,88),fill=(127,145,146,85),width=1)
    # On-state light is a soft mint/amber hybrid, restrained and localized to the ring.
    light=Image.new("RGBA",(w,h)); ld=ImageDraw.Draw(light)
    ld.arc((62,42,450,141),186,354,fill=(242,166,90,230),width=8)
    ld.arc((62,42,450,141),6,174,fill=(111,227,193,205),width=6)
    light=light.filter(ImageFilter.GaussianBlur(8)); im=Image.alpha_composite(im,light); d=ImageDraw.Draw(im)
    d.arc((62,42,450,141),186,354,fill=(242,166,90,255),width=4)
    d.arc((62,42,450,141),6,174,fill=(111,227,193,220),width=3)
    save(im,"target_ring_on.png")
    # Off state: same precision hardware, unpowered and matte; retain exactly aligned placement.
    off=im.copy(); off=Image.new("RGBA",(w,h)); od=ImageDraw.Draw(off)
    od.ellipse((43,55,469,163),fill=(0,0,0,130))
    od.ellipse((52,37,460,147),fill=(12,20,25,255),outline=(106,123,124,255),width=4)
    od.ellipse((74,44,438,135),fill=(26,37,41,255),outline=(71,87,91,255),width=3)
    od.arc((59,41,453,143),185,355,fill=(179,171,148,195),width=6); od.arc((59,41,453,143),5,175,fill=(111,126,129,190),width=6)
    for x in (93,156,255,354,417):
        y=100-int(28*math.sqrt(max(.05,1-((x-255)/202)**2)))
        od.ellipse((x-5,y-4,x+5,y+4),fill=(13,20,25,255),outline=(165,160,143,200),width=2)
    od.ellipse((118,55,394,122),fill=(8,15,19,255),outline=(59,75,79,190),width=2)
    od.ellipse((159,65,353,111),outline=(61,77,82,165),width=2)
    od.line((255,69,255,108),fill=(127,145,146,90),width=2); od.line((178,88,332,88),fill=(127,145,146,72),width=1)
    od.arc((62,42,450,141),186,354,fill=(157,119,75,175),width=3); od.arc((62,42,450,141),6,174,fill=(90,125,118,145),width=2)
    save(off,"target_ring.png")


def draw_assets():
    save(metallic_ball((189,125,72),(243,178,102),3),"ball_launch.png")
    save(metallic_ball((145,175,183),(111,227,193),4),"ball_drop.png")
    draw_launcher(); draw_target()


if __name__ == "__main__":
    draw_background(); draw_assets()
