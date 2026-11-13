#!/usr/bin/env python3
"""Draw the issue #3 glass/metal perfusion-port state sprites (Pillow, 4x supersampling)."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

OUT = Path(__file__).resolve().parent
S = 4
SIZE = 128


def col(c, a=255):
    return (*c, a)


def gradient_ellipse(img, box, top, mid, bottom, outline=(31, 42, 48, 255), outline_w=1):
    """Layer a softly brushed vertical-metal ellipsoid with a lit upper edge."""
    x0, y0, x1, y1 = [int(v * S) for v in box]
    w, h = max(1, x1-x0), max(1, y1-y0)
    layer = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    px = layer.load()
    for y in range(h):
        t = y / max(1, h-1)
        c0, c1, u = (top, mid, t/0.52) if t < 0.52 else (mid, bottom, (t-0.52)/0.48)
        for x in range(w):
            nx = (x / max(1,w-1) - 0.5) * 2
            edge = max(0.0, 1.0 - nx*nx - (t-0.5)*(t-0.5)*2)
            spec = 16 * max(0.0, 1.0 - abs(t-0.10)/0.08) * max(0, 1-nx*nx)
            br = 0.90 + 0.10*edge + spec/255
            px[x,y] = tuple(max(0,min(255,int((c0[i]*(1-u)+c1[i]*u)*br))) for i in range(3)) + (255,)
    mask = Image.new('L',(w,h),0); ImageDraw.Draw(mask).ellipse((0,0,w-1,h-1),fill=255)
    img.alpha_composite(Image.composite(layer, Image.new('RGBA',(w,h)), mask),(x0,y0))
    d=ImageDraw.Draw(img)
    d.ellipse((x0,y0,x1-1,y1-1),outline=outline,width=max(1,int(outline_w*S)))


def line(draw, pts, fill, width=1):
    draw.line([(int(x*S),int(y*S)) for x,y in pts], fill=fill, width=max(1,int(width*S)), joint='curve')


def ellipse(draw, box, fill=None, outline=None, width=1):
    coords=tuple(int(v*S) for v in box)
    draw.ellipse(coords, fill=fill, outline=outline, width=max(1,int(width*S)))


def polygon(draw, pts, fill):
    draw.polygon([(int(x*S),int(y*S)) for x,y in pts],fill=fill)


def screw(d, x, y, r=2.2):
    ellipse(d,(x-r,y-r,x+r,y+r),fill=(28,38,44,255),outline=(112,127,130,255),width=.65)
    line(d,[(x-r*.55,y),(x+r*.55,y)],(16,23,27,255),.45)


def base_port():
    im=Image.new('RGBA',(SIZE*S,SIZE*S),(0,0,0,0))
    d=ImageDraw.Draw(im)
    # Soft contact shadow, confined to the transparent cutout.
    sh=Image.new('RGBA',im.size,(0,0,0,0));sd=ImageDraw.Draw(sh)
    sd.ellipse((22*S,80*S,106*S,111*S),fill=(2,7,11,110))
    im.alpha_composite(sh.filter(ImageFilter.GaussianBlur(5*S)))
    # Short housing barrel visible below the circular fitting.
    polygon(d,[(41,66),(87,66),(83,94),(76,102),(51,102),(44,94)],(28,40,47,255))
    for y in (76,82,88,94):
        line(d,[(46,y),(82,y)],(92,111,116,255),1)
        line(d,[(48,y+1),(80,y+1)],(15,24,30,255),.6)
    # Main flange face, machined lip and recessed glass/metal port well.
    gradient_ellipse(im,(22,18,106,93),(163,177,174),(82,101,105),(30,43,51),outline=(22,33,40,255),outline_w=1.3)
    d=ImageDraw.Draw(im)
    ellipse(d,(27,22,101,87),outline=(193,199,188,255),width=1.6)
    ellipse(d,(31,26,97,83),outline=(42,56,62,255),width=2.4)
    ellipse(d,(34,29,94,80),fill=(49,63,68,255),outline=(146,159,156,255),width=1)
    # Concentric bevel makes the glass seat read as a physical counterbore.
    ellipse(d,(39,33,89,76),fill=(14,25,32,255),outline=(171,179,169,255),width=1.1)
    # Four small recessed fasteners, kept symmetric for accurate coupling.
    for x,y in ((38,34),(90,34),(38,72),(90,72)):
        screw(d,x,y,1.8)
    # Controlled light streak, upper left only; no emissive outline.
    line(d,[(34,24),(50,20),(70,20)],(235,226,202,220),.8)
    return im


def port_out():
    im=base_port(); d=ImageDraw.Draw(im)
    # Male flow spigot projects from the seat toward the viewer; tapered and hollow.
    polygon(d,[(49,44),(76,44),(80,58),(77,68),(70,73),(53,70),(48,63)],(135,147,142,255))
    line(d,[(51,47),(74,47),(77,58)],(225,222,207,255),1.2)
    for y in (52,57,62):
        line(d,[(50,y),(77,y+1)],(55,69,75,255),1.3)
        line(d,[(51,y-1),(76,y)],(185,191,178,255),.55)
    ellipse(d,(53,61,74,78),fill=(9,17,22,255),outline=(194,199,188,255),width=1)
    ellipse(d,(57,65,70,74),fill=(27,34,39,255),outline=(69,82,87,255),width=.7)
    line(d,[(53,76),(54,88),(62,92)],(93,109,112,255),1)
    return im


def port_in():
    im=base_port();d=ImageDraw.Draw(im)
    # Female receiver: deep, stepped socket with internal guide splines and a seal.
    ellipse(d,(42,34,86,73),fill=(31,42,48,255),outline=(205,207,194,255),width=1.2)
    ellipse(d,(47,38,81,69),fill=(10,17,23,255),outline=(89,106,110,255),width=1.4)
    ellipse(d,(52,42,76,65),fill=(22,29,34,255),outline=(129,143,143,255),width=1)
    # Recessed internal guide ribs, visibly inside the socket rather than on top.
    for x in (57,64,71):
        line(d,[(x,45),(x,61)],(167,175,164,220),.8)
    # Soft gasket crescent at the mouth and two mechanical locking ears.
    line(d,[(48,43),(50,39),(55,37)],(214,196,159,255),1.4)
    polygon(d,[(27,47),(35,47),(36,54),(31,58),(26,55)],(73,87,91,255))
    polygon(d,[(93,47),(85,47),(84,54),(89,58),(94,55)],(73,87,91,255))
    line(d,[(29,49),(34,49)],(186,193,182,255),.75)
    line(d,[(91,49),(86,49)],(186,193,182,255),.75)
    return im


def port_connected():
    im=base_port();d=ImageDraw.Draw(im)
    # Interlocked two-piece coupling: female body stays behind, male nose enters its bore.
    # The visible split, lock collar and opposed bayonet tabs make connection state legible.
    polygon(d,[(43,42),(74,42),(78,51),(75,60),(68,64),(50,61),(45,55)],(117,132,130,255))
    line(d,[(47,44),(72,44),(75,51)],(231,224,203,255),1.1)
    for y in (49,54):
        line(d,[(47,y),(75,y)],(45,59,65,255),1.1)
        line(d,[(48,y-1),(74,y)],(181,188,176,255),.55)
    # Lock collar bridges the port rim and male body; center seam is the coupling joint.
    polygon(d,[(40,53),(48,49),(53,53),(53,62),(47,67),(40,63)],(63,78,84,255))
    polygon(d,[(88,53),(80,49),(75,53),(75,62),(81,67),(88,63)],(63,78,84,255))
    line(d,[(41,54),(47,51),(50,54)],(218,211,190,255),.8)
    line(d,[(87,54),(81,51),(78,54)],(218,211,190,255),.8)
    line(d,[(53,63),(76,64)],(25,35,41,255),1)
    # A subtle transparent-looking glass collar sits behind the lock ears.
    ellipse(d,(42,34,86,72),outline=(152,185,184,210),width=1)
    return im


def save(name, image):
    image.resize((SIZE,SIZE),Image.Resampling.LANCZOS).save(OUT/f'{name}.png', optimize=True)


if __name__ == '__main__':
    save('port_out',port_out())
    save('port_in',port_in())
    save('port_connected',port_connected())
