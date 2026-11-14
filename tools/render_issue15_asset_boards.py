#!/usr/bin/env python3
"""Render review boards for issue #15; these are explicitly not game screenshots."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/"docs/review"
FONT=ImageFont.truetype(str(ROOT/"assets/fonts/Inter.ttf"),20)
SMALL=ImageFont.truetype(str(ROOT/"assets/fonts/Inter.ttf"),15)
TITLE=ImageFont.truetype(str(ROOT/"assets/fonts/Inter.ttf"),30)
BG=(8,13,21); CARD=(15,24,36); LINE=(51,70,83); TEXT=(225,235,236); MUTED=(139,163,173)


def card(draw, box, label):
    draw.rounded_rectangle(box, radius=10, fill=CARD, outline=LINE, width=1)
    x1,y1,x2,y2=box
    draw.text((x1+12,y2-30),label,font=SMALL,fill=MUTED)


def contain(path, size):
    im=Image.open(path).convert("RGBA")
    im.thumbnail(size,Image.Resampling.LANCZOS)
    return im


def board_abc():
    w,h=1600,1280
    im=Image.new("RGB",(w,h),BG); d=ImageDraw.Draw(im)
    d.text((54,30),"ISSUE #15 · A/B/C ASSET BOARD",font=TITLE,fill=TEXT)
    d.text((54,72),"Asset preview · not a running scene screenshot",font=FONT,fill=(242,166,90))

    d.text((54,122),"A · GUEST SIGNATURE",font=FONT,fill=TEXT)
    names=["tear_01.png","tear_02.png","tear_03.png","tear_04.png","glitch_noise.png","ghost_ring.png"]
    x=54
    for name in names:
        box=(x,157,x+235,302); card(d,box,name)
        sample=contain(ROOT/"assets/world/signature"/name,(210,104))
        # Transparency is shown over the same restrained, flat dark field for clarity.
        im.paste(sample,(x+12,box[1]+12),sample)
        x+=250

    d.text((54,326),"B · POWER STRIP ICON STATES",font=FONT,fill=TEXT)
    powers=[("sar","↶"),("yavaslat","◐"),("ayir","□"),("gor","eye")]
    x=54
    for key,_ in powers:
        for state in ("normal","pressed"):
            name=f"{key}_{state}.png"; box=(x,362,x+175,493); card(d,box,name)
            sample=contain(ROOT/"assets/ui/powers"/name,(84,84))
            im.paste(sample,(x+45,box[1]+5),sample)
            x+=190

    d.text((54,518),"C · FREE FALL",font=FONT,fill=TEXT)
    # Large chamber plate shows the derived empty-background treatment.
    chamber=contain(ROOT/"stations/free_fall/assets/chamber_bg_clear.png",(870,490))
    im.paste(chamber,(54,555))
    d.text((54,1055),"chamber_bg_clear.png · 1920×1080",font=SMALL,fill=MUTED)
    # Physical objects, each shown over a dark card so transparent boundaries remain apparent.
    citems=["ball_steel.png","ball_foam.png","capsule.png","feather.png","hammer.png"]
    x0=960
    for i,name in enumerate(citems):
        x=x0+(i%2)*286; y=555+(i//2)*170
        box=(x,y,x+262,y+150); card(d,box,name)
        sample=contain(ROOT/"stations/free_fall/assets"/name,(108,108))
        im.paste(sample,(x+77,y+5),sample)
    box=(1246,900,1522,1080); card(d,box,"glass_highlight.png")
    sample=contain(ROOT/"stations/free_fall/assets/glass_highlight.png",(80,140))
    im.paste(sample,(1344,909),sample)
    d.text((960,1110),"Board contents are individual assets, not an in-game composition.",font=SMALL,fill=MUTED)
    OUT.mkdir(parents=True,exist_ok=True)
    im.save(OUT/"issue15_abc_asset_board.png",optimize=True)


def board_d():
    w,h=1600,800
    im=Image.new("RGB",(w,h),BG); d=ImageDraw.Draw(im)
    d.text((54,30),"ISSUE #15 · D ASSET BOARD",font=TITLE,fill=TEXT)
    d.text((54,72),"Asset preview · not a running scene screenshot",font=FONT,fill=(242,166,90))
    pano=contain(ROOT/"assets/world/three_suns/three_suns_panorama.png",(1492,420))
    im.paste(pano,(54,121))
    d.text((54,545),"three_suns_panorama.png · 3840×1080 · full panorama",font=SMALL,fill=MUTED)
    labels=[("sun_a.png","amber"),("sun_b.png","cool white"),("sun_c.png","pale red")]
    x=54
    for name,tone in labels:
        box=(x,584,x+270,770); d.rounded_rectangle(box,radius=10,fill=CARD,outline=LINE,width=1)
        layer=contain(ROOT/"assets/world/three_suns"/name,(150,150))
        im.paste(layer,(x+9,box[1]+10),layer)
        d.text((x+171,box[1]+58),name,font=SMALL,fill=TEXT)
        d.text((x+171,box[1]+83),tone,font=SMALL,fill=MUTED)
        x+=290
    d.text((954,687),"Three source layers match the panorama anchors listed in the source README.",font=SMALL,fill=MUTED)
    im.save(OUT/"issue15_d_asset_board.png",optimize=True)


if __name__=="__main__":
    board_abc(); board_d()
