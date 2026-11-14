#!/usr/bin/env python3
"""Draw the issue #3 valve-state sprites as original, reproducible medical art.

Uses Pillow + NumPy only. The output is a transparent 512 px square PNG; no
external images, fonts, or generated raster references are used.
"""
from __future__ import annotations

import math
from pathlib import Path

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter

OUT = Path(__file__).resolve().parent
SIZE = 512
SCALE = 3
N = SIZE * SCALE
CX = CY = N / 2
LIGHT = np.array([-0.46, -0.62, 0.64], dtype=np.float32)
LIGHT /= np.linalg.norm(LIGHT)


def mask_image() -> Image.Image:
    return Image.new("L", (N, N), 0)


def ellipse_mask(rx: float, ry: float, inner_rx: float | None = None, inner_ry: float | None = None) -> Image.Image:
    m = mask_image()
    d = ImageDraw.Draw(m)
    d.ellipse((CX-rx*SCALE, CY-ry*SCALE, CX+rx*SCALE, CY+ry*SCALE), fill=255)
    if inner_rx is not None and inner_ry is not None:
        d.ellipse((CX-inner_rx*SCALE, CY-inner_ry*SCALE, CX+inner_rx*SCALE, CY+inner_ry*SCALE), fill=0)
    return m


def surface_color(mask: Image.Image, color: tuple[int, int, int], *, center=(CX, CY), radius=210*SCALE, strength=0.58, texture=1.0) -> Image.Image:
    """Shade a masked, shallow convex surface with the shared upper-left key."""
    yy, xx = np.mgrid[0:N, 0:N].astype(np.float32)
    x = (xx-center[0]) / radius
    y = (yy-center[1]) / radius
    radial = np.sqrt(x*x+y*y)
    z = np.sqrt(np.maximum(0.04, 1.0-np.minimum(radial, 0.98)**2))
    nx, ny, nz = x, y, z
    norm = np.sqrt(nx*nx+ny*ny+nz*nz)
    diffuse = np.maximum(0.0, (nx*LIGHT[0]+ny*LIGHT[1]+nz*LIGHT[2])/norm)
    rim = np.clip((1.02-radial)*2.2, 0.36, 1.0)
    light = (0.54 + strength*diffuse) * rim
    # Fine, repeatable biological micro-shading; kept subtle enough for 512 px.
    wave = 1.0 + texture*(0.012*np.sin(xx/13.0+np.sin(yy/29.0))*np.sin(yy/17.0))
    noise = 1.0 + texture*((np.sin(xx*0.17+yy*0.09)*np.sin(yy*0.13-xx*0.07))*0.009)
    light = np.clip(light*wave*noise, 0.18, 1.22)
    rgb = np.empty((N, N, 4), dtype=np.uint8)
    for i, c in enumerate(color):
        rgb[:, :, i] = np.clip(c*light, 0, 255).astype(np.uint8)
    rgb[:, :, 3] = np.asarray(mask, dtype=np.uint8)
    return Image.fromarray(rgb, "RGBA")


def blend(dst: Image.Image, src: Image.Image) -> None:
    dst.alpha_composite(src)


def cubic(p0, p1, p2, p3, steps=24):
    points=[]
    for i in range(steps+1):
        t=i/steps; q=1-t
        points.append((q**3*p0[0]+3*q*q*t*p1[0]+3*q*t*t*p2[0]+t**3*p3[0],
                       q**3*p0[1]+3*q*q*t*p1[1]+3*q*t*t*p2[1]+t**3*p3[1]))
    return points


def scale_pts(points):
    return [(round(x*SCALE), round(y*SCALE)) for x,y in points]


def draw_curve(draw, points, color, width=1.0):
    draw.line(scale_pts(points), fill=color, width=max(1, round(width*SCALE)), joint="curve")


def polar(r, angle_deg):
    a=math.radians(angle_deg)
    return (256+r*math.cos(a),256+r*math.sin(a))


def arc_points(radius, a0, a1, steps=24, ry=None):
    ry = radius if ry is None else ry
    return [(256+radius*math.cos(math.radians(a0+(a1-a0)*i/steps)),
             256+ry*math.sin(math.radians(a0+(a1-a0)*i/steps))) for i in range(steps+1)]


def paint_leaflet(canvas: Image.Image, points, palette, *, damaged=False, detail_seed=0):
    m=mask_image(); ImageDraw.Draw(m).polygon(scale_pts(points), fill=255)
    layer=surface_color(m,palette,center=(N*.43,N*.36),radius=N*.72,strength=.43,texture=1.0)
    blend(canvas,layer)
    d=ImageDraw.Draw(canvas)
    # Fibrous collagen runs from the insertion arc toward the free edge.
    # The same number and weight of lines keeps open/closed states registered.
    xs=[p[0] for p in points]; ys=[p[1] for p in points]
    bbox=(min(xs),min(ys),max(xs),max(ys))
    fibers=Image.new("RGBA",(N,N),(0,0,0,0)); fd=ImageDraw.Draw(fibers)
    for k in range(11):
        t=(k+1)/12
        x0=bbox[0]+(bbox[2]-bbox[0])*t
        y0=bbox[1]+(bbox[3]-bbox[1])*.80
        x1=256+(x0-256)*.20
        y1=256+(y0-256)*.20
        path=cubic((x0,y0),(x0+(x1-x0)*.25,y0-10),(x0+(x1-x0)*.70,y1+7),(x1,y1),10)
        draw_curve(fd,path,(255,226,212,55),0.75)
    fibers.putalpha(ImageChops.multiply(fibers.getchannel("A"),m))
    blend(canvas,fibers)
    # Fine coaptation seam, or stress line if this cusp is torn.
    if damaged:
        xmid=(bbox[0]+bbox[2])*.5
        ymid=(bbox[1]+bbox[3])*.55
        crack=[(xmid-5,ymid-24),(xmid+2,ymid-11),(xmid-7,ymid+1),(xmid+4,ymid+14),(xmid-1,ymid+28)]
        draw_curve(d,crack,(83,49,50,220),1.2)


def sector_leaflet(index, count, kind, opened, damaged=False):
    # Native leaflets have broad insertions on the annulus and curved free edges.
    center_angle=-90 + index*360/count
    if kind in ("pulmonary","aortic"):
        outer=145; base_half=60
        inner=83 if opened else 0
    elif kind=="mitral":
        # Anterior and posterior leaflets oppose across the valve's central line.
        outer=146; base_half=91
        inner=91 if opened else 0
    else:
        outer=145; base_half=60
        inner=(82 if opened else 0)
    if kind=="mitral":
        # Broad anterior leaflet and shorter posterior leaflet sit opposite one another.
        center_angle=-90 if index==0 else 90
        start=center_angle-base_half
        end=center_angle+base_half
    else:
        start=center_angle-base_half
        end=center_angle+base_half
    # Shorten one damaged cusp and leave a visible irregular coaptation gap.
    if damaged and index==0:
        inner=max(inner,56 if not opened else 103)
    outer_arc=arc_points(outer,start,end,28,ry=outer*.96)
    tip_angle=center_angle
    p_tip=polar(inner,tip_angle)
    if inner <= 1:
        # Closed leaflets taper to a common coaptation point; no artificial centre hole.
        pts=outer_arc+[(256,256)]
    else:
        # In the open state the free edge is folded outward, leaving a real central lumen.
        inner_start=polar(inner,start+17)
        inner_end=polar(inner,end-17)
        edge_a=cubic(outer_arc[-1],polar(outer*.66,end-18),polar(inner*1.04,end-4),inner_end,18)
        inner_arc=arc_points(inner,end-17,start+17,22,ry=inner*.94)
        edge_b=cubic(inner_start,polar(inner*1.04,start+4),polar(outer*.66,start+18),outer_arc[0],18)
        pts=outer_arc+edge_a[1:]+inner_arc[1:]+edge_b[1:]
    return pts


def draw_chordae(canvas: Image.Image, kind: str, opened: bool):
    if kind not in ("tricuspid","mitral"):
        return
    d=ImageDraw.Draw(canvas)
    # Chordae tendineae run from the AV leaflets to two papillary muscle heads.
    insertion_angles=([132,148,164,16,32,48] if kind=="tricuspid" else [135,157,23,45])
    papillary=[(207,306),(305,306)]
    for j,a in enumerate(insertion_angles):
        p0=polar(122,a)
        p1=papillary[0] if j < len(insertion_angles)//2 else papillary[1]
        p2=((p0[0]+p1[0])*.5+(10 if j%2 else -10), (p0[1]+p1[1])*.5-4)
        path=cubic(p0,p2,p2,p1,12)
        draw_curve(d,path,(217,174,156,150 if opened else 75),0.9)
    # Papillary muscle ends sit on the ventricular side, not on the annulus.
    for x,y in papillary:
        d.ellipse(((x-15)*SCALE,(y-8)*SCALE,(x+15)*SCALE,(y+8)*SCALE),fill=(133,68,67,220),outline=(225,163,148,230),width=2*SCALE)


def add_calcification(canvas: Image.Image, kind: str):
    d=ImageDraw.Draw(canvas)
    # A localized, chalky mineral patch on one damaged leaflet; restrained in area.
    cx,cy=polar(88,-92)
    seed=sum((i+1)*ord(ch) for i,ch in enumerate(kind))
    rng=np.random.default_rng(seed)
    for i in range(20):
        a=float(rng.uniform(0,2*math.pi)); r=float(rng.uniform(2,17))
        x=cx+math.cos(a)*r; y=cy+math.sin(a)*r*.75
        rx=float(rng.uniform(1.5,4.5)); ry=float(rng.uniform(1.2,3.2))
        shade=int(rng.integers(178,222))
        d.ellipse(((x-rx)*SCALE,(y-ry)*SCALE,(x+rx)*SCALE,(y+ry)*SCALE),fill=(shade,177,157,205),outline=(119,99,91,105),width=SCALE)


def valve(kind: str, state: str) -> Image.Image:
    opened=state=="open"
    damaged=state=="damaged"
    canvas=Image.new("RGBA",(N,N),(0,0,0,0))
    # Soft contact shadow, separated from transparent canvas.
    shadow=Image.new("RGBA",(N,N),(0,0,0,0)); sd=ImageDraw.Draw(shadow)
    sd.ellipse((78*SCALE,83*SCALE,438*SCALE,440*SCALE),fill=(3,8,13,105))
    shadow=shadow.filter(ImageFilter.GaussianBlur(10*SCALE));blend(canvas,shadow)

    # Vascular cuff/anulus: warm fibrous tissue with a pale inner endocardial rim.
    ring_rx=176 if kind=="pulmonary" else 190
    ring_ry=168 if kind=="pulmonary" else 181
    ring_inner_x=139 if kind=="pulmonary" else 150
    ring_inner_y=133 if kind=="pulmonary" else 143
    outer=ellipse_mask(ring_rx,ring_ry,inner_rx=ring_inner_x,inner_ry=ring_inner_y)
    ring_color=(167,111,103) if kind=="pulmonary" else (177,105,98)
    blend(canvas,surface_color(outer,ring_color,center=(N*.38,N*.32),radius=198*SCALE,strength=.53,texture=1.0))
    # Raised fibrous collar lip.
    d=ImageDraw.Draw(canvas)
    d.ellipse(((256-ring_rx)*SCALE,(256-ring_ry)*SCALE,(256+ring_rx)*SCALE,(256+ring_ry)*SCALE),outline=(91,54,53,220),width=2*SCALE)
    d.ellipse(((256-ring_inner_x)*SCALE,(256-ring_inner_y)*SCALE,(256+ring_inner_x)*SCALE,(256+ring_inner_y)*SCALE),outline=(218,162,146,245),width=8*SCALE)
    d.ellipse(((256-ring_inner_x+7)*SCALE,(256-ring_inner_y+7)*SCALE,(256+ring_inner_x-7)*SCALE,(256+ring_inner_y-7)*SCALE),outline=(244,204,185,225),width=2*SCALE)

    # Deep lumen and endocardial shadow provide contrast for the native leaflets.
    lumen_rx=ring_inner_x-5; lumen_ry=ring_inner_y-5
    lumen_mask=ellipse_mask(lumen_rx,lumen_ry)
    blend(canvas,surface_color(lumen_mask,(27,31,40),center=(N*.41,N*.34),radius=140*SCALE,strength=.45,texture=.1))
    d=ImageDraw.Draw(canvas)
    d.ellipse(((256-lumen_rx)*SCALE,(256-lumen_ry)*SCALE,(256+lumen_rx)*SCALE,(256+lumen_ry)*SCALE),outline=(111,64,60,235),width=4*SCALE)
    if kind=="aortic":
        # Coronary ostia arise from two aortic sinuses, above the valve plane.
        for x,y in (polar(164,-144),polar(164,-36)):
            d.ellipse(((x-8)*SCALE,(y-8)*SCALE,(x+8)*SCALE,(y+8)*SCALE),fill=(110,61,60,210),outline=(233,181,162,220),width=2*SCALE)
            d.ellipse(((x-4)*SCALE,(y-4)*SCALE,(x+4)*SCALE,(y+4)*SCALE),fill=(26,30,39,255),outline=(87,57,58,255),width=1*SCALE)

    count=2 if kind=="mitral" else 3
    draw_chordae(canvas,kind,opened)
    # Behind-layer line communicates the septal/anterior anchor, not a UI marker.
    if kind in ("tricuspid","mitral"):
        d=ImageDraw.Draw(canvas)
        d.arc((171*SCALE,270*SCALE,341*SCALE,402*SCALE),10,170,fill=(184,112,100,195),width=9*SCALE)

    palette=(235,181,164) if kind in ("tricuspid","mitral") else (230,190,169)
    indices=list(range(count))
    # Stable draw order makes each state register to the same annulus.
    for i in indices:
        pts=sector_leaflet(i,count,kind,opened,damaged)
        paint_leaflet(canvas,pts,palette,damaged=(damaged and i==0),detail_seed=i)
        d=ImageDraw.Draw(canvas)
        d.line(scale_pts(pts+[pts[0]]),fill=(132,75,72,96),width=1*SCALE,joint="curve")

    d=ImageDraw.Draw(canvas)
    # Commissures and coaptation lines: three-rayed for semilunar/tricuspid,
    # single oblique line for mitral. These are anatomical seams, not symbols.
    if not opened:
        if kind=="mitral":
            draw_curve(d,cubic((146,249),(208,251),(305,261),(366,251),24),(105,58,59,195),1.3)
        else:
            for a in (-90,30,150):
                p0=polar(4,a); p1=polar(135,a)
                draw_curve(d,cubic(p0,polar(48,a),polar(91,a),p1,14),(110,65,63,180),1.0)

    # Collagen bundles follow the tissue grain in three localized, irregular runs.
    d=ImageDraw.Draw(canvas)
    for offset in (0,8,16):
        path=cubic((119,151+offset),(147,127+offset),(182,117+offset),(211,126+offset),18)
        draw_curve(d,path,(244,196,172,48),0.8)
    for offset in (0,9):
        path=cubic((108,282+offset),(137,295+offset),(157,304+offset),(183,305+offset),15)
        draw_curve(d,path,(244,196,172,38),0.7)

    # Soft glancing highlight on the upper-left cuff edge.
    d.arc(((256-ring_rx+3)*SCALE,(256-ring_ry+3)*SCALE,(256+ring_rx-3)*SCALE,(256+ring_ry-3)*SCALE),188,259,fill=(255,221,195,205),width=2*SCALE)
    if damaged:
        add_calcification(canvas,kind)
        # A frayed leaflet edge and small coaptation gap on the damaged cusp.
        x0,y0=polar(58,-90); x1,y1=polar(116,-86)
        draw_curve(d,[(x0,y0),(x0-6,y0+9),(x0+7,y0+17),(x1,y1)],(238,195,172,225),1.4)

    result=canvas.resize((SIZE,SIZE),Image.Resampling.LANCZOS)
    if kind=="pulmonary":
        # Pulmonary annulus is naturally smaller and thinner than the aortic root.
        inner=result.resize((round(SIZE*.94),round(SIZE*.94)),Image.Resampling.LANCZOS)
        output=Image.new("RGBA",(SIZE,SIZE),(0,0,0,0))
        output.alpha_composite(inner,((SIZE-inner.width)//2,(SIZE-inner.height)//2))
        result=output
    return result


def main():
    kinds=("tricuspid","mitral","pulmonary","aortic")
    for kind in kinds:
        for state in ("open","closed","damaged"):
            img=valve(kind,state)
            img.save(OUT/f"valve_{kind}_{state}.png",optimize=True)
    print("Wrote 12 512x512 transparent valve sprites.")


if __name__=="__main__":
    main()
