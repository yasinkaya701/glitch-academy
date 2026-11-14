#!/usr/bin/env python3
"""Deterministically draw the Measurement Workshop asset set with Pillow.
All geometry, lighting, and surfaces are authored here; no external image or model is used.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter
import math, random
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'stations/measurement/assets'
S=2

def canvas(w,h,bg=(7,11,18,255)):
    return Image.new('RGBA',(w*S,h*S),bg)
def sc(p): return tuple(int(round(v*S)) for v in p)
def poly(d,pts,fill,outline=None,width=1): d.polygon([sc(p) for p in pts],fill=fill); \
    d.line([sc(p) for p in pts+[pts[0]]],fill=outline,width=width*S,joint='curve') if outline else None
def rect(d,box,fill,outline=None,width=1): d.rectangle(sc(box),fill=fill,outline=outline,width=width*S)
def ellipse(d,box,fill,outline=None,width=1): d.ellipse(sc(box),fill=fill,outline=outline,width=width*S)
def line(d,pts,fill,width=1): d.line([sc(p) for p in pts],fill=fill,width=max(1,width*S),joint='curve')
def rounded(d,box,r,fill,outline=None,width=1): d.rounded_rectangle(sc(box),radius=r*S,fill=fill,outline=outline,width=width*S)
def grad_bg(w,h,top,bottom):
    im=Image.new('RGBA',(w*S,h*S)); p=im.load()
    for y in range(h*S):
        t=y/(h*S-1)
        c=tuple(int(top[i]*(1-t)+bottom[i]*t) for i in range(4))
        for x in range(w*S): p[x,y]=c
    return im

def save(im,name):
    if S!=1: im=im.resize((im.width//S,im.height//S),Image.Resampling.LANCZOS)
    im.save(OUT/name,optimize=True)

def make_bg():
    w,h=1920,1080; im=grad_bg(w,h,(10,20,31,255),(4,8,14,255)); d=ImageDraw.Draw(im,'RGBA')
    # Deep, quiet instrument bay; broad warm task light on the left, annotation wall stays open on right.
    for i in range(22):
        x=70+i*22; line(d,[(x,80),(x+80,600)],(90,150,175,8),1)
    rounded(d,(88,82,930,606),10,(10,19,29,255),(42,64,78,180),2)
    # Wall panels / shadow seams
    for x in [120,340,560,780]: line(d,[(x,92),(x,592)],(62,82,93,70),2)
    for y in [210,410]: line(d,[(98,y),(920,y)],(51,69,83,60),1)
    # Practical warm work lamp pool
    glow=Image.new('RGBA',im.size,(0,0,0,0)); gd=ImageDraw.Draw(glow)
    gd.ellipse(sc((10,190,910,930)),fill=(237,145,72,28)); glow=glow.filter(ImageFilter.GaussianBlur(95*S)); im=Image.alpha_composite(im,glow); d=ImageDraw.Draw(im,'RGBA')
    # Bench top and front edge
    poly(d,[(0,680),(1125,640),(1920,690),(1920,785),(1130,742),(0,795)],(68,49,38,255),(141,99,64,255),2)
    poly(d,[(0,795),(1130,742),(1920,785),(1920,1080),(0,1080)],(22,27,32,255),(73,67,57,200),2)
    # Grain and edge glints
    random.seed(9)
    for _ in range(100):
        x=random.randint(0,1120); y=random.randint(686,785); ln=random.randint(8,90)
        line(d,[(x,y),(x+ln,y-random.randint(0,7))],(180,127,79,random.randint(9,35)),1)
    line(d,[(0,685),(1125,645),(1920,694)],(245,182,120,135),2)
    # Precision ruler laid in perspective along rear bench
    poly(d,[(140,642),(792,618),(950,637),(297,665)],(157,173,174,255),(218,223,213,255),2)
    for i in range(41):
        t=i/40; x=154+t*632; y=643-t*24
        hh=15 if i%10==0 else (10 if i%5==0 else 5)
        line(d,[(x,y),(x+1,y-hh)],(21,34,40,225),1)
    # analytical balance - plinth, pan, column, instrument window
    poly(d,[(390,520),(532,510),(575,532),(429,548)],(61,74,77,255),(132,156,157,255),2)
    poly(d,[(429,548),(575,532),(571,640),(425,660)],(28,39,45,255),(99,122,128,255),2)
    rounded(d,(445,556,547,587),4,(6,17,21,255),(102,158,162,255),1)
    line(d,[(456,574),(471,567),(482,573),(496,564),(509,570),(526,563)],(111,227,193,245),2)
    # pan
    line(d,[(487,511),(487,478)],(175,190,189,255),3); ellipse(d,(429,463,545,485),(135,151,151,255),(218,224,215,255),2)
    # small calibration weight on pan
    rounded(d,(476,438,499,464),5,(136,147,144,255),(223,214,191,255),2)
    ellipse(d,(482,433,493,441),(184,190,179,255),(230,223,208,255),1)
    # stopwatch: physical case, crown, dial, hands
    ellipse(d,(708,449,839,580),(32,42,47,255),(166,178,170,255),4)
    rounded(d,(761,430,787,454),5,(114,126,119,255),(201,197,177,255),2)
    ellipse(d,(721,462,826,567),(11,20,25,255),(99,131,137,255),2)
    for i in range(60):
        a=math.pi*2*i/60-math.pi/2; r1=47 if i%5==0 else 49; r2=40
        line(d,[(773+math.cos(a)*r1,514+math.sin(a)*r1),(773+math.cos(a)*r2,514+math.sin(a)*r2)],(198,209,194,210),1)
    line(d,[(773,514),(789,486)],(242,166,90,255),2); line(d,[(773,514),(752,501)],(230,240,232,245),2); ellipse(d,(768,509,778,519),(227,239,232,255))
    # mounted rail with sensor gate silhouettes
    rounded(d,(102,735,770,751),5,(111,126,130,255),(190,205,199,255),2)
    for x in [200,635]:
        rounded(d,(x,653,x+18,744),4,(35,48,55,255),(120,143,147,255),2)
        line(d,[(x+3,660),(x+15,660)],(111,227,193,220),2)
    # right wall keeps readable dark negative space for live labels
    for y in range(150,600,80): line(d,[(1120,y),(1880,y)],(38,55,70,55),1)
    save(im,'bench_bg.png')

def make_ruler():
    w,h=640,128; im=canvas(w,h,(0,0,0,0)); d=ImageDraw.Draw(im,'RGBA')
    # Brushed steel blade, bevels, machined dark edge
    poly(d,[(24,25),(607,25),(624,39),(624,99),(607,113),(24,113),(12,100),(12,38)],(117,136,139,255),(221,228,218,255),2)
    line(d,[(26,30),(604,30),(618,41)],(241,243,228,200),2); line(d,[(26,107),(604,107)],(51,67,71,210),2)
    for i in range(51):
        x=28+i*11.5; ht=42 if i%10==0 else (29 if i%5==0 else 17)
        line(d,[(x,39),(x,39+ht)],(16,28,33,240),2 if i%10==0 else 1)
        if i%10==0: ellipse(d,(x-2,91,x+2,95),(37,52,55,255))
    # edge grip detail
    for x in range(38,95,8): line(d,[(x,46),(x+6,46)],(191,204,198,170),1)
    save(im,'ruler.png')

def make_balance():
    w=h=512; im=canvas(w,h,(0,0,0,0)); d=ImageDraw.Draw(im,'RGBA')
    # soft contact shadow
    ellipse(d,(73,425,441,478),(0,0,0,115))
    # cast-metal base and tapered shoulders
    poly(d,[(92,337),(420,337),(454,390),(424,442),(88,442),(57,390)],(35,49,55,255),(146,170,170,255),3)
    poly(d,[(78,389),(435,389),(424,431),(91,431)],(19,29,35,255),(87,112,119,255),2)
    rounded(d,(145,356,367,410),8,(7,17,22,255),(86,144,149,255),2)
    rounded(d,(167,368,346,398),4,(5,14,18,255),(52,93,101,255),1)
    # quiet segmented trace not numeric readout
    line(d,[(187,384),(211,384),(220,376),(237,389),(258,378),(280,384),(321,384)],(111,227,193,230),3)
    for x in [126,385]: ellipse(d,(x-8,408,x+8,424),(11,19,23,255),(98,119,120,255),2)
    # pedestal and pan
    poly(d,[(226,329),(286,329),(299,352),(212,352)],(87,103,105,255),(179,191,181,255),2)
    line(d,[(256,336),(256,224)],(139,154,151,255),8); line(d,[(250,233),(262,233)],(213,220,204,255),2)
    ellipse(d,(102,199,410,244),(104,119,117,255),(226,230,216,255),3)
    ellipse(d,(116,204,396,229),(176,188,179,255),(83,100,101,255),2)
    # compact calibration mass
    rounded(d,(221,125,292,199),17,(121,131,124,255),(226,218,197,255),3)
    ellipse(d,(238,113,275,131),(165,173,159,255),(229,222,201,255),2)
    line(d,[(235,142),(277,142)],(72,86,83,230),2)
    # controlled cool rim
    line(d,[(106,203),(178,198)],(152,218,218,150),2)
    save(im,'balance.png')

def make_stopwatch():
    w=h=320; im=canvas(w,h,(0,0,0,0)); d=ImageDraw.Draw(im,'RGBA')
    ellipse(d,(47,77,273,302),(0,0,0,110))
    rounded(d,(137,29,183,82),10,(95,112,111,255),(201,213,203,255),3)
    ellipse(d,(54,65,266,278),(39,51,56,255),(187,199,188,255),7)
    ellipse(d,(74,85,246,257),(9,19,25,255),(102,137,141,255),3)
    # physical minute hashes and analog hands
    for i in range(60):
        a=2*math.pi*i/60-math.pi/2; r1=76 if i%5==0 else 80; r2=68
        line(d,[(160+math.cos(a)*r1,171+math.sin(a)*r1),(160+math.cos(a)*r2,171+math.sin(a)*r2)],(216,226,214,220),2 if i%5==0 else 1)
    line(d,[(160,171),(190,126)],(242,166,90,255),4); line(d,[(160,171),(120,147)],(234,241,228,255),3)
    ellipse(d,(152,163,168,179),(232,240,228,255))
    # side start/reset buttons
    rounded(d,(34,106,61,147),8,(77,92,95,255),(181,195,189,255),2)
    rounded(d,(259,108,286,149),8,(77,92,95,255),(181,195,189,255),2)
    line(d,[(103,238),(217,238)],(75,101,106,150),1)
    save(im,'stopwatch.png')

def make_rail_piece():
    w,h=512,256; im=canvas(w,h,(0,0,0,0)); d=ImageDraw.Draw(im,'RGBA')
    # aluminum extrusion in three-quarter view, repeatable end-to-end
    poly(d,[(45,83),(405,83),(465,112),(105,112)],(188,202,197,255),(236,240,225,255),3)
    poly(d,[(105,112),(465,112),(465,178),(105,178)],(72,92,99,255),(185,205,202,255),3)
    poly(d,[(45,83),(105,112),(105,178),(45,146)],(45,61,68,255),(156,175,173,255),3)
    # recessed top track and twin raised shoulders
    poly(d,[(73,91),(395,91),(428,106),(106,106)],(48,64,70,255),(120,142,143,255),2)
    poly(d,[(93,91),(137,91),(169,106),(124,106)],(127,149,149,255),(211,222,213,255),2)
    poly(d,[(300,91),(344,91),(376,106),(332,106)],(127,149,149,255),(211,222,213,255),2)
    line(d,[(112,120),(449,120)],(206,220,214,150),2)
    # end connector tongue and bolt recesses
    for x,y in [(75,121),(75,151),(426,131),(426,160)]:
        ellipse(d,(x-7,y-6,x+7,y+6),(23,37,43,255),(133,156,157,255),2); line(d,[(x-4,y),(x+4,y)],(183,197,191,170),1)
    save(im,'rail_piece.png')

def make_rail_slot():
    w,h=512,256; im=canvas(w,h,(0,0,0,0)); d=ImageDraw.Draw(im,'RGBA')
    # sensor gate mounting shoe, designed to slide into the rail extrusion
    poly(d,[(91,146),(421,146),(450,165),(121,165)],(91,110,111,255),(207,219,208,255),3)
    poly(d,[(121,165),(450,165),(450,195),(121,195)],(40,56,63,255),(144,166,165,255),2)
    # dovetail shoe
    poly(d,[(147,137),(353,137),(382,151),(176,151)],(164,181,178,255),(232,236,222,255),2)
    poly(d,[(176,151),(382,151),(373,164),(168,164)],(89,112,115,255),(187,202,194,255),2)
    # gate upright + emitter/receiver window
    poly(d,[(204,137),(220,42),(286,42),(309,137)],(48,67,75,255),(177,198,199,255),3)
    rounded(d,(218,67,291,111),9,(9,23,31,255),(119,154,158,255),2)
    rounded(d,(232,79,277,99),5,(55,123,130,255),(157,222,216,255),2)
    line(d,[(238,89),(270,89)],(193,250,229,240),2)
    for x in [137,401]:
        ellipse(d,(x-9,166,x+9,183),(15,27,33,255),(170,187,181,255),2)
    # subtle glass top edge
    line(d,[(223,52),(279,52)],(218,230,222,175),2)
    save(im,'rail_slot.png')

def make_preview():
    # Exact-size contact sheet to inspect composition, with no textual labels.
    W,H=1600,900; im=Image.new('RGBA',(W,H),(7,11,18,255)); d=ImageDraw.Draw(im,'RGBA')
    bg=Image.open(OUT/'bench_bg.png').convert('RGBA').resize((960,540),Image.Resampling.LANCZOS); im.alpha_composite(bg,(0,0))
    for fname,box in [('ruler.png',(1000,55,1540,150)),('balance.png',(1060,185,1260,385)),('stopwatch.png',(1310,180,1465,335)),('rail_piece.png',(1000,450,1280,590)),('rail_slot.png',(1300,450,1570,590))]:
        a=Image.open(OUT/fname).convert('RGBA'); a.thumbnail((box[2]-box[0],box[3]-box[1]),Image.Resampling.LANCZOS); im.alpha_composite(a,(box[0]+(box[2]-box[0]-a.width)//2,box[1]+(box[3]-box[1]-a.height)//2))
    im.convert('RGB').save(OUT/'measurement_preview.jpg',quality=94,optimize=True)

def main():
    OUT.mkdir(parents=True,exist_ok=True)
    make_bg(); make_ruler(); make_balance(); make_stopwatch(); make_rail_piece(); make_rail_slot(); make_preview()
if __name__=='__main__': main()
