#!/usr/bin/env python3
"""Hand-authored, deterministic Newton sled and night-lab raster assets.

All shapes, materials, light fields, reflections, and fine surface grain are
constructed here with Pillow and NumPy. No external image or text is used.
"""
from __future__ import annotations

from math import exp, sin, cos, pi
from pathlib import Path
import random
from collections import deque

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

OUT = Path(__file__).resolve().parent
SEED = 11017
RNG = random.Random(SEED)

def rgb_gradient(size, stops, horizontal=False):
    w,h=size
    length=w if horizontal else h
    pos=np.linspace(0,1,length,dtype=np.float32)
    result=np.zeros((h,w,3),dtype=np.uint8)
    for i in range(len(stops)-1):
        a,ca=stops[i]; b,cb=stops[i+1]
        t=np.clip((pos-a)/(b-a),0,1)[:,None]
        col=(np.array(ca)[None,:]*(1-t)+np.array(cb)[None,:]*t).astype(np.uint8)
        if horizontal: result[:,:,:]=col[None,:,:]
        else: result[:,:,:]=col[:,None,:]
    return Image.fromarray(result,"RGB").convert("RGBA")

def polygon_material(im, points, stops, horizontal=False, outline=None):
    w,h=im.size
    mat=rgb_gradient((w,h),stops,horizontal)
    mask=Image.new("L",(w,h),0); ImageDraw.Draw(mask).polygon(points,fill=255)
    im.alpha_composite(Image.composite(mat,Image.new("RGBA",im.size,(0,0,0,0)),mask))
    if outline:
        ImageDraw.Draw(im).line(points+[points[0]],fill=outline,width=2,joint="curve")

def vignette_noise(im, seed=SEED, amount=4):
    arr=np.asarray(im.convert("RGB")).astype(np.int16)
    h,w=arr.shape[:2]
    rng=np.random.default_rng(seed)
    noise=rng.normal(0,amount,(h,w,1))
    yy,xx=np.mgrid[0:h,0:w]
    v=np.clip(1-.19*((xx/w-.49)**2)-.16*((yy/h-.45)**2),.63,1)
    arr=np.clip(arr*v[:,:,None]+noise,0,255).astype(np.uint8)
    return Image.fromarray(arr,"RGB").convert("RGBA")

def soft_ellipse(layer, box, color, blur):
    m=Image.new("RGBA",layer.size,(0,0,0,0)); ImageDraw.Draw(m).ellipse(box,fill=color)
    layer.alpha_composite(m.filter(ImageFilter.GaussianBlur(blur)))

def remove_isolated_alpha_specks(im, min_pixels=16):
    """Drop tiny detached transparency components left by sheet extraction."""
    a=np.asarray(im.getchannel("A"))
    active=a>20
    h,w=active.shape
    seen=np.zeros_like(active)
    for sy,sx in zip(*np.where(active & ~seen)):
        if seen[sy,sx]:
            continue
        q=deque([(int(sy),int(sx))]); seen[sy,sx]=True; component=[]
        while q:
            y,x=q.popleft(); component.append((y,x))
            for ny in range(max(0,y-1),min(h,y+2)):
                for nx in range(max(0,x-1),min(w,x+2)):
                    if active[ny,nx] and not seen[ny,nx]:
                        seen[ny,nx]=True; q.append((ny,nx))
        if len(component)<min_pixels:
            for y,x in component: a[y,x]=0
    im.putalpha(Image.fromarray(a,"L"))
    return im

def bolt(d,x,y,r=4):
    d.ellipse((x-r,y-r,x+r,y+r),fill=(38,49,58,255),outline=(170,181,180,230),width=1)
    d.line((x-r*.55,y,x+r*.55,y),fill=(207,208,196,210),width=1)

def make_rail_bg_vector_v1():
    w,h=1920,1080
    im=rgb_gradient((w,h),[(0,(9,18,30)),(.48,(15,26,38)),(1,(6,12,22))])
    d=ImageDraw.Draw(im,"RGBA")

    # Deep blue glass at left; clean dark measurement wall on the right.
    d.rectangle((0,0,700,670),fill=(8,18,31,180))
    d.rectangle((1055,0,1920,810),fill=(8,15,25,225))
    # Wall panels only on the background half; no decorative labels or text.
    for x in [1075,1308,1544,1776,1910]:
        d.line((x,0,x,780),fill=(60,78,91,45),width=2)
        d.line((x+4,0,x+4,780),fill=(3,8,15,75),width=3)
    d.line((1058,171,1920,171),fill=(84,99,109,26),width=2)
    d.line((1058,804,1920,804),fill=(88,111,125,54),width=2)
    # Recessed wall bays lend scale while keeping the UI side quiet.
    for x in [1127,1362,1598,1834]:
        d.rounded_rectangle((x,228,x+178,696),radius=4,fill=(11,20,31,112),outline=(54,70,82,50),width=2)
        d.line((x+15,246,x+163,246),fill=(106,127,135,25),width=1)
    # Left window: mullions, distant cold city, night reflections.
    d.rectangle((0,0,560,632),fill=(9,23,42,242),outline=(67,92,111,135),width=5)
    for x in [0,181,366,550]:
        d.rectangle((x-7,0,x+7,640),fill=(16,29,42,255))
        d.line((x-2,0,x-2,637),fill=(117,139,147,74),width=2)
    for y in [0,212,424,635]:
        d.rectangle((0,y-6,560,y+7),fill=(18,31,43,255))
        d.line((0,y-2,558,y-2),fill=(120,143,149,66),width=2)
    # Window reflections and distant soft building silhouettes.
    city=Image.new("RGBA",(w,h),(0,0,0,0)); cd=ImageDraw.Draw(city)
    for x,bh,bw in [(8,106,43),(65,148,49),(122,83,36),(212,126,67),(292,163,50),(377,96,44),(443,144,53),(501,102,40)]:
        cd.rectangle((x,630-bh,x+bw,630),fill=(12,23,37,170))
        for wy in range(630-bh+14,620,29):
            for wx in range(x+8,x+bw-4,15):
                cd.rectangle((wx,wy,wx+4,wy+7),fill=(151,157,135,45 if (wx+wy)%3 else 78))
    city=city.filter(ImageFilter.GaussianBlur(2)); im.alpha_composite(city)
    d=ImageDraw.Draw(im,"RGBA")
    # Ceiling lamp, warm spill is physically concentrated above the sled lane.
    glow=Image.new("RGBA",(w,h),(0,0,0,0))
    soft_ellipse(glow,(230,58,680,567),(246,162,85,42),78)
    soft_ellipse(glow,(338,64,562,340),(245,176,103,28),45)
    im.alpha_composite(glow)
    d=ImageDraw.Draw(im,"RGBA")
    d.line((452,0,452,84),fill=(28,37,45,255),width=9)
    d.ellipse((436,70,468,91),fill=(38,49,57,255),outline=(103,117,119,200),width=2)
    d.polygon([(346,91),(558,91),(611,157),(292,157)],fill=(19,27,34,255),outline=(103,111,108,220))
    d.polygon([(362,145),(542,145),(574,166),(330,166)],fill=(237,161,79,255))
    d.ellipse((371,145,535,166),fill=(255,215,153,255))
    d.line((312,156,590,156),fill=(146,161,158,160),width=3)

    # Floor and bench are layered, softly lit dark steel, not a flat horizon.
    polygon_material(im,[(0,706),(1920,744),(1920,1080),(0,1080)],
        [(0,(11,19,29)),(.55,(7,14,24)),(1,(5,10,18))])
    # Far workbench in shadow, with restrained drawer seams.
    d=ImageDraw.Draw(im,"RGBA")
    d.polygon([(0,687),(1004,700),(1090,745),(0,731)],fill=(23,33,42,245))
    d.line((0,691,1000,704),fill=(111,130,134,70),width=2)
    d.polygon([(0,731),(1090,745),(1090,813),(0,795)],fill=(13,23,33,245))
    for x in range(74,1010,173):
        d.line((x,742,x,795),fill=(59,71,78,102),width=2)
        d.rounded_rectangle((x+39,756,x+81,761),radius=2,fill=(107,122,124,100))
    # Polished bench top reflection where the air track is mounted.
    polygon_material(im,[(0,789),(1090,804),(1090,845),(0,831)],
        [(0,(60,70,75)),(.17,(22,34,44)),(.31,(77,82,78)),(.49,(20,31,40)),(.7,(48,61,67)),(1,(15,26,35))])
    d=ImageDraw.Draw(im,"RGBA")
    d.line((0,790,1090,805),fill=(177,172,148,114),width=2)
    # Bench legs fade toward the foreground.
    for x in [180,720,1018]:
        d.polygon([(x,832),(x+32,832),(x+40,1022),(x-12,1022)],fill=(13,22,31,240))
        d.line((x+4,842,x+28,842),fill=(101,119,123,72),width=2)

    # Track foundation runs long and level: rails, air perforations, and fine scale ticks.
    # Four-layer body creates believable extrusion and a controlled warm reflection.
    d.polygon([(70,680),(1452,658),(1510,725),(72,760)],fill=(20,32,42,255),outline=(114,135,141,180))
    polygon_material(im,[(72,760),(1510,725),(1510,785),(73,827)],
        [(0,(77,89,94)),(.2,(25,37,47)),(.49,(49,62,70)),(.72,(20,31,40)),(1,(67,75,75))])
    d=ImageDraw.Draw(im,"RGBA")
    d.line((75,761,1507,726),fill=(199,191,162,170),width=3)
    d.line((77,776,1509,741),fill=(7,14,21,235),width=7)
    d.line((79,780,1507,745),fill=(101,123,131,160),width=2)
    d.line((76,816,1507,775),fill=(119,132,129,135),width=2)
    # Twin air-bearing ways with bright top bevels and dark separation groove.
    for yoff in [0,30]:
        pts=[(88,682+yoff),(1443,659+yoff),(1480,682+yoff),(93,707+yoff)]
        d.polygon(pts,fill=(72,91,102,255),outline=(174,190,187,210))
        d.line([pts[0],pts[1]],fill=(217,209,182,225),width=3)
        d.line([pts[2],pts[3]],fill=(16,27,37,240),width=3)
        # Repeating air outlets and etched distance divisions (no numerals).
        for i in range(30):
            t=i/29
            x=int(105+t*1320); yy=int(689-t*22+yoff)
            d.ellipse((x-3,yy-2,x+3,yy+2),fill=(12,23,32,255),outline=(145,161,160,145),width=1)
        for i in range(41):
            t=i/40
            x=int(94+t*1370); yy=int(711-t*23+yoff)
            leng=14 if i%5==0 else 7
            d.line((x,yy,x+int(t*4),yy+leng),fill=(186,179,153,135 if i%5==0 else 82),width=1)
    # Rail supports and fasteners beneath the bed.
    for x in range(128,1460,190):
        y=int(766-(x-128)*.028)
        d.polygon([(x,y),(x+32,y-1),(x+37,y+31),(x-5,y+33)],fill=(17,28,38,255),outline=(107,123,127,155))
        bolt(d,x+8,y+16,3); bolt(d,x+25,y+15,3)
    # Target line at the far end: one clear cold photoelectric light.
    d.line((1400,593,1400,760),fill=(93,215,231,26),width=18)
    d.line((1400,600,1400,752),fill=(88,223,240,185),width=3)
    d.ellipse((1393,585,1407,599),fill=(158,235,235,245))
    d.ellipse((1394,753,1406,765),fill=(137,222,229,225))
    # Floor reflections stay local to the line and task lighting.
    reflections=Image.new("RGBA",(w,h),(0,0,0,0)); rd=ImageDraw.Draw(reflections)
    rd.polygon([(1386,760),(1414,760),(1470,1030),(1338,1030)],fill=(57,177,197,17))
    rd.polygon([(350,819),(622,818),(737,845),(275,845)],fill=(240,167,92,21))
    im.alpha_composite(reflections.filter(ImageFilter.GaussianBlur(36)))
    # Fine wall/floor grain, restrained enough not to compete with measurement UI.
    im=vignette_noise(im,SEED,2.4)
    im.save(OUT/"archive"/"rail_bg_procedural_v1.png",optimize=True)

def make_rail_bg():
    """Fit the custom-rendered 16:9 lab source to the issue's exact canvas."""
    source=Image.open(OUT/"archive"/"rail_bg_source.png").convert("RGB")
    # Source is 1672x941. Scale to cover then center-crop to the exact 16:9 canvas.
    scale=max(1920/source.width,1080/source.height)
    size=(round(source.width*scale),round(source.height*scale))
    source=source.resize(size,Image.Resampling.LANCZOS)
    x=(source.width-1920)//2; y=(source.height-1080)//2
    source=source.crop((x,y,x+1920,y+1080))
    source=vignette_noise(source.convert("RGBA"),SEED+1,1.25)
    source.save(OUT/"rail_bg.png",optimize=True)

def make_sled_procedural_v1(name, heavy=False):
    w,h=1024,512
    im=Image.new("RGBA",(w,h),(0,0,0,0))
    # Low-contact shadow beneath the levitating sled, soft enough to retain alpha.
    sh=Image.new("RGBA",(w,h),(0,0,0,0)); sd=ImageDraw.Draw(sh)
    sd.ellipse((110,365,920,433),fill=(4,9,15,135))
    im.alpha_composite(sh.filter(ImageFilter.GaussianBlur(22)))
    d=ImageDraw.Draw(im,"RGBA")
    # Shared rectangular air-cushion body; brushed titanium with beveled ends.
    d.rounded_rectangle((136,285,881,374),radius=24,fill=(23,34,43,255),outline=(166,178,175,255),width=5)
    # Luminous upper edge and shaded underside describe the same lab light as the backdrop.
    d.line((166,292,851,292),fill=(227,207,165,235),width=4)
    d.rounded_rectangle((149,347,867,380),radius=14,fill=(13,23,32,255),outline=(77,93,101,255),width=3)
    d.line((177,359,838,359),fill=(66,89,101,255),width=3)
    # Two cross beams and visible air pads, physically separated from the rail.
    for x in [244,744]:
        d.rounded_rectangle((x-26,366,x+26,405),radius=8,fill=(60,76,84,255),outline=(155,168,165,240),width=3)
        d.ellipse((x-28,399,x+28,418),fill=(15,27,36,245),outline=(128,150,152,235),width=3)
        d.line((x-19,408,x+19,408),fill=(116,144,149,180),width=2)
        bolt(d,x-15,316,5); bolt(d,x+15,316,5)
    # Inset side panel with three fine machining grooves.
    d.rounded_rectangle((298,310,709,348),radius=9,fill=(31,48,60,255),outline=(118,142,151,210),width=2)
    for x in [322,328,334]: d.line((x,317,x,341),fill=(122,147,154,120),width=1)
    # Distinctive rear pusher assembly and bell-mouth nozzle at the left end.
    d.rounded_rectangle((95,302,170,356),radius=12,fill=(27,41,51,255),outline=(164,177,175,245),width=3)
    d.polygon([(109,311),(75,317),(59,329),(75,341),(109,347)],fill=(17,28,37,255),outline=(136,158,163,255))
    d.ellipse((53,325,67,337),fill=(7,13,21,255),outline=(208,176,125,240),width=2)
    d.line((117,309,153,309),fill=(222,206,172,220),width=3)
    # Front bumper/target flag on the right, kept compact so the sled reads in profile.
    d.rounded_rectangle((850,302,923,355),radius=10,fill=(25,38,48,255),outline=(166,177,172,245),width=3)
    d.rectangle((910,289,932,368),fill=(91,108,113,255),outline=(194,196,177,235),width=2)
    d.line((916,299,916,357),fill=(216,174,111,240),width=3)
    # PBR-like longitudinal machined facets and restrained cool reflections.
    d.polygon([(176,297),(280,297),(274,306),(166,306)],fill=(242,222,177,90))
    d.polygon([(705,298),(841,297),(852,304),(706,306)],fill=(144,196,204,72))
    d.line((187,369,842,369),fill=(188,197,188,190),width=2)
    d.line((180,334,286,334),fill=(82,116,129,170),width=2)
    if heavy:
        # Three close-fitting calibrated steel masses, firmly seated on the shared sled.
        # The stepped stack is clearly distinguishable without changing the cart body.
        d.rounded_rectangle((404,181,616,286),radius=13,fill=(18,28,37,255),outline=(152,169,169,255),width=4)
        d.rounded_rectangle((419,141,601,258),radius=11,fill=(29,43,52,255),outline=(190,192,176,255),width=4)
        d.rounded_rectangle((437,112,584,224),radius=9,fill=(39,53,60,255),outline=(210,198,167,255),width=4)
        # Precision-cut side grooves and top bevel catches; no lettering.
        for y in [129,138,157,166,185,194,216,225,244,253]:
            d.line((447,y,574,y),fill=(93,115,119,190),width=2)
        d.line((449,116,572,116),fill=(244,220,168,210),width=3)
        for x in [456,565]:
            d.ellipse((x-4,178,x+4,186),fill=(14,24,32,255),outline=(180,181,162,230),width=2)
        d.rounded_rectangle((387,276,635,294),radius=5,fill=(93,104,104,255),outline=(207,190,155,225),width=2)
    else:
        # Matching low-profile deck; bolted plate gives the light cart an engineered finish.
        d.rounded_rectangle((391,252,632,285),radius=8,fill=(44,59,67,255),outline=(154,171,171,245),width=3)
        for x in [411,612]: bolt(d,x,269,4)
        d.line((421,257,603,257),fill=(205,192,160,170),width=2)
    d=ImageDraw.Draw(im,"RGBA")
    # Small amber pilot lamps indicate the active impulse assembly without text.
    d.ellipse((118,315,130,327),fill=(255,177,90,255),outline=(255,228,182,220),width=2)
    d.ellipse((136,315,148,327),fill=(70,117,128,255),outline=(159,199,202,200),width=2)
    im.save(OUT/"archive"/("sled_heavy_procedural_v1.png" if heavy else "sled_light_procedural_v1.png"),optimize=True)

def make_sled(name, heavy=False):
    """Crop the matched pair from the authored, transparent render sheet."""
    sheet=Image.open(OUT/"archive"/"sled_sprite_sheet_source.png").convert("RGBA")
    half=sheet.width//2
    x0=half if heavy else 0
    # Equal 3:2 half panels; vertical crop keeps the contact shadow and full flag.
    crop=sheet.crop((x0,90,x0+half,633))
    crop=crop.resize((512,256),Image.Resampling.LANCZOS)
    crop=remove_isolated_alpha_specks(crop)
    crop.save(OUT/name,optimize=True)

def make_thruster():
    w,h=512,256
    im=Image.new("RGBA",(w,h),(0,0,0,0))
    # Local nozzle exit is x=128. Place this same-sized layer 98 px left of the
    # sled origin so the nozzle bloom aligns with the sled sprite's x≈30 nozzle.
    pix=im.load()
    for y in range(h):
        for x in range(512):
            dx=(128-x)/128
            spread=(4+dx*42)
            yy=abs(y-128)
            if x<128 and yy<spread:
                strength=max(0,1-dx**1.4)*max(0,1-(yy/spread)**2)
                a=int(122*strength)
                pix[x,y]=(255,int(115+80*strength),int(54+112*strength),a)
    d=ImageDraw.Draw(im,"RGBA")
    d.polygon([(130,119),(85,110),(42,120),(3,128),(42,136),(85,146),(130,137)],fill=(255,178,91,118))
    d.polygon([(130,124),(89,119),(47,128),(89,137),(130,132)],fill=(255,231,174,195))
    d.ellipse((121,119,137,137),fill=(255,244,198,235))
    im=im.filter(ImageFilter.GaussianBlur(5))
    im.save(OUT/"thruster_glow.png",optimize=True)

def make_gate_procedural_v1(name, opened):
    w,h=512,512
    im=Image.new("RGBA",(w,h),(0,0,0,0)); d=ImageDraw.Draw(im,"RGBA")
    # Soft anchor shadow and two machined uprights straddling the air rail.
    sh=Image.new("RGBA",(w,h),(0,0,0,0)); ImageDraw.Draw(sh).ellipse((62,427,453,474),fill=(3,7,12,130))
    im.alpha_composite(sh.filter(ImageFilter.GaussianBlur(13))); d=ImageDraw.Draw(im,"RGBA")
    for x in [78,391]:
        d.polygon([(x+8,78),(x+82,78),(x+73,433),(x,433)],fill=(19,31,41,255),outline=(152,167,167,245))
        d.polygon([(x+14,88),(x+32,88),(x+28,419),(x+8,419)],fill=(83,101,110,255))
        d.polygon([(x+57,91),(x+76,91),(x+68,419),(x+52,419)],fill=(11,21,31,255))
        d.line((x+17,93,x+13,408),fill=(204,192,159,170),width=3)
        for y in [110,398]:
            d.rounded_rectangle((x+19,y,x+63,y+23),radius=5,fill=(38,52,60,255),outline=(150,165,163,230),width=2)
            bolt(d,x+41,y+11,4)
        d.rounded_rectangle((x+18,428,x+70,448),radius=5,fill=(36,50,59,255),outline=(156,168,160,230),width=2)
    # Heavy top beam with clear optical transmitter and receiver housings.
    d.rounded_rectangle((111,55,406,130),radius=14,fill=(22,35,44,255),outline=(180,184,168,255),width=4)
    d.line((127,61,389,61),fill=(231,206,157,245),width=4)
    d.polygon([(130,70),(381,70),(365,113),(145,113)],fill=(34,50,59,255))
    d.rounded_rectangle((218,79,300,119),radius=8,fill=(10,21,31,255),outline=(113,139,148,220),width=2)
    d.ellipse((237,87,258,108),fill=(93,207,223,245) if opened else (238,95,63,255),outline=(221,237,220,210),width=2)
    d.ellipse((266,87,287,108),fill=(117,225,230,255) if opened else (255,161,79,250),outline=(224,238,218,210),width=2)
    # Retractable stop bar: raised/open leaves the optical path clear.
    if opened:
        d.rounded_rectangle((157,136,356,174),radius=12,fill=(53,68,73,255),outline=(203,193,164,255),width=3)
        d.line((173,143,341,143),fill=(240,213,161,220),width=3)
        # Recessed hinge arms show how the bar lifts; no extra indication text.
        for x in [155,340]:
            d.line((x,132,x+(-6 if x<200 else 6),167),fill=(173,184,174,255),width=7)
            d.ellipse((x-8,126,x+8,142),fill=(23,36,45,255),outline=(207,196,162,255),width=3)
    else:
        d.rounded_rectangle((105,300,407,346),radius=12,fill=(30,42,49,255),outline=(215,200,163,255),width=4)
        d.line((127,309,389,309),fill=(253,171,90,255),width=4)
        d.line((134,338,380,338),fill=(94,112,117,255),width=2)
        for x in [122,389]: bolt(d,x,323,5)
    # Feet and a crisp laser plane aligned to the central track.
    d.polygon([(68,431),(162,431),(172,471),(53,471)],fill=(19,29,38,255),outline=(115,133,137,230))
    d.polygon([(354,431),(451,431),(466,471),(340,471)],fill=(19,29,38,255),outline=(115,133,137,230))
    d.line((90,462,430,462),fill=(179,190,179,190),width=3)
    if opened:
        d.line((126,254,386,254),fill=(113,232,235,175),width=3)
        d.line((129,260,383,260),fill=(76,196,214,85),width=8)
    else:
        d.line((127,367,384,367),fill=(242,158,85,35),width=5)
    im.save(OUT/"archive"/("finish_gate_open_procedural_v1.png" if opened else "finish_gate_closed_procedural_v1.png"),optimize=True)

def make_gate(name, opened):
    """Use the consistent closed/open transparent source pair."""
    sheet=Image.open(OUT/"archive"/"finish_gate_sprite_sheet_source.png").convert("RGBA")
    half=sheet.width//2
    x0=half if opened else 0
    crop=sheet.crop((x0,0,x0+half,sheet.height))
    crop=crop.resize((512,512),Image.Resampling.LANCZOS)
    crop=remove_isolated_alpha_specks(crop)
    crop.save(OUT/name,optimize=True)

def make_previews():
    bg=Image.open(OUT/"rail_bg.png").convert("RGBA")
    for sled,gate,label in [
        ("sled_light.png","finish_gate_closed.png","preview_light.png"),
        ("sled_heavy.png","finish_gate_open.png","preview_heavy.png"),
    ]:
        scene=bg.copy()
        cart=Image.open(OUT/sled).convert("RGBA")
        scene.alpha_composite(cart,(265,390))
        portal=Image.open(OUT/gate).convert("RGBA").resize((256,256),Image.Resampling.LANCZOS)
        scene.alpha_composite(portal,(1260,382))
        scene.convert("RGB").save(OUT/label,optimize=True)

def main():
    OUT.mkdir(parents=True,exist_ok=True)
    make_rail_bg()
    make_sled("sled_light.png",False)
    make_sled("sled_heavy.png",True)
    make_thruster()
    make_gate("finish_gate_closed.png",False)
    make_gate("finish_gate_open.png",True)
    # Short name means the closed physical stop state, retained for scene wiring.
    (OUT/"finish_gate.png").write_bytes((OUT/"finish_gate_closed.png").read_bytes())
    make_previews()

if __name__=="__main__":
    main()
