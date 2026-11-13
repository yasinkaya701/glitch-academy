#!/usr/bin/env python3
"""Generate the Yanlış Dünya instrument-console UI PNGs with deterministic vector primitives.

Run from repository root: python3 tools/generate_ui_assets.py
Uses only the Python standard library. Draws at 2x then downsamples for clean edges.
"""
from __future__ import annotations
import math, os, struct, zlib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
UI = os.path.join(ROOT, 'assets', 'ui')
WORLD = os.path.join(ROOT, 'assets', 'world')
S = 2

# Palette from docs/ART_DIRECTION.md
INK = (7, 11, 18, 255)
PANEL = (15, 24, 36, 224)
PANEL2 = (21, 33, 46, 246)
STEEL = (55, 72, 84, 255)
EDGE = (102, 131, 145, 220)
PALE = (232, 241, 242, 255)
MUTED = (144, 165, 174, 220)
CYAN = (111, 227, 193, 255)
AMBER = (242, 166, 90, 255)
RED = (229, 100, 90, 255)
GREEN = (111, 227, 193, 255)
TRANSPARENT = (0, 0, 0, 0)

class C:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.W, self.H = w*S, h*S
        self.p = bytearray(self.W*self.H*4)
    def _blend(self, x, y, col):
        if x < 0 or y < 0 or x >= self.W or y >= self.H: return
        i=(y*self.W+x)*4; a=col[3]
        if a == 255: self.p[i:i+4]=bytes(col); return
        if a == 0: return
        da=self.p[i+3]; oa=a+da*(255-a)//255
        if oa == 0: return
        for k in range(3): self.p[i+k]=(col[k]*a+self.p[i+k]*da*(255-a)//255)//oa
        self.p[i+3]=oa
    def rect(self,x,y,w,h,col):
        x0=max(0,int(x*S)); y0=max(0,int(y*S)); x1=min(self.W,int((x+w)*S)); y1=min(self.H,int((y+h)*S))
        if x1<=x0 or y1<=y0:return
        if col[3]==255:
            row=bytes(col)*(x1-x0)
            for yy in range(y0,y1):
                i=(yy*self.W+x0)*4; self.p[i:i+len(row)]=row
        else:
            for yy in range(y0,y1):
                for xx in range(x0,x1): self._blend(xx,yy,col)
    def poly(self, pts, col):
        pts=[(x*S,y*S) for x,y in pts]
        ymin=max(0,int(min(y for x,y in pts))); ymax=min(self.H,int(max(y for x,y in pts))+1)
        for yy in range(ymin,ymax):
            scan=yy+0.5; xs=[]
            for (x1,y1),(x2,y2) in zip(pts,pts[1:]+pts[:1]):
                if (y1<=scan<y2) or (y2<=scan<y1): xs.append(x1+(scan-y1)*(x2-x1)/(y2-y1))
            xs.sort()
            for a,b in zip(xs[::2],xs[1::2]):
                x0=max(0,int(a)); x1=min(self.W,int(b)+1)
                for xx in range(x0,x1): self._blend(xx,yy,col)
    def line(self,x1,y1,x2,y2,col,width=2):
        x1*=S;y1*=S;x2*=S;y2*=S;r=max(0.5,width*S/2); pad=r+1
        xa=max(0,int(min(x1,x2)-pad)); xb=min(self.W,int(max(x1,x2)+pad+1)); ya=max(0,int(min(y1,y2)-pad)); yb=min(self.H,int(max(y1,y2)+pad+1))
        dx=x2-x1;dy=y2-y1; den=dx*dx+dy*dy
        for yy in range(ya,yb):
            for xx in range(xa,xb):
                t=0 if den==0 else max(0,min(1,((xx+.5-x1)*dx+(yy+.5-y1)*dy)/den))
                if (xx+.5-(x1+t*dx))**2+(yy+.5-(y1+t*dy))**2 <= r*r: self._blend(xx,yy,col)
    def circle(self,cx,cy,r,col,fill=True,width=2):
        cx*=S;cy*=S;r*=S;th=max(1,width*S)
        xa=max(0,int(cx-r-2));xb=min(self.W,int(cx+r+3));ya=max(0,int(cy-r-2));yb=min(self.H,int(cy+r+3))
        for yy in range(ya,yb):
            for xx in range(xa,xb):
                d=(xx+.5-cx)**2+(yy+.5-cy)**2
                if d<=r*r and (fill or d>=(r-th)**2):self._blend(xx,yy,col)
    def ellipse(self,cx,cy,rx,ry,col,fill=True,width=2):
        cx*=S;cy*=S;rx*=S;ry*=S;th=max(1,width*S)
        xa=max(0,int(cx-rx-2));xb=min(self.W,int(cx+rx+3));ya=max(0,int(cy-ry-2));yb=min(self.H,int(cy+ry+3))
        for yy in range(ya,yb):
            for xx in range(xa,xb):
                v=((xx+.5-cx)/rx)**2+((yy+.5-cy)/ry)**2
                if v<=1 and (fill or v>=max(0,1-th/min(rx,ry))): self._blend(xx,yy,col)
    def arc(self,cx,cy,rx,ry,a0,a1,col,width=2):
        n=max(8,int(abs(a1-a0)*max(rx,ry)/24));last=None
        for j in range(n+1):
            a=math.radians(a0+(a1-a0)*j/n);p=(cx+rx*math.cos(a),cy+ry*math.sin(a))
            if last:self.line(*last,*p,col,width)
            last=p
    def png(self,path):
        # Box-filter 2x2 while preserving alpha.
        out=bytearray(self.w*self.h*4)
        for y in range(self.h):
            for x in range(self.w):
                acc=[0,0,0,0]
                for dy in range(S):
                    for dx in range(S):
                        i=(((y*S+dy)*self.W)+(x*S+dx))*4
                        for k in range(4):acc[k]+=self.p[i+k]
                o=(y*self.w+x)*4
                for k in range(4):out[o+k]=(acc[k]+S*S//2)//(S*S)
        def chunk(tag,data): return struct.pack('>I',len(data))+tag+data+struct.pack('>I',zlib.crc32(tag+data)&0xffffffff)
        raw=b''.join(b'\0'+out[y*self.w*4:(y+1)*self.w*4] for y in range(self.h))
        os.makedirs(os.path.dirname(path),exist_ok=True)
        with open(path,'wb') as f:f.write(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>2I5B',self.w,self.h,8,6,0,0,0))+chunk(b'IDAT',zlib.compress(raw,9))+chunk(b'IEND',b''))

def clipped(w,h,cut=12): return [(cut,0),(w-cut,0),(w,cut),(w,h-cut),(w-cut,h),(cut,h),(0,h-cut),(0,cut)]
def stroke_poly(c,pts,col,w=1.5):
    for p,q in zip(pts,pts[1:]+pts[:1]):c.line(*p,*q,col,w)
def outline_rect(c,x,y,w,h,col,width=1,cut=0):
    pts=[(x+cut,y),(x+w-cut,y),(x+w,y+cut),(x+w,y+h-cut),(x+w-cut,y+h),(x+cut,y+h),(x,y+h-cut),(x,y+cut)] if cut else [(x,y),(x+w,y),(x+w,y+h),(x,y+h)]
    stroke_poly(c,pts,col,width)
def tickscale(c,x,y,n,step=8,vertical=False,color=EDGE):
    for i in range(n):
        d=5 if i%5==0 else 2.5
        if vertical:c.line(x,y+i*step,x+d,y+i*step,color,1)
        else:c.line(x+i*step,y,x+i*step,y+d,color,1)

def panel():
    c=C(512,512);pts=clipped(512,512,24);c.poly(pts,(15,24,36,208));stroke_poly(c,pts,EDGE,1)
    outline_rect(c,8,8,496,496,(111,227,193,48),1,18)
    c.line(26,2,76,2,CYAN,1);c.line(436,510,486,510,AMBER,1)
    # sub-surface machining marks stay inside the 9-slice safe region
    c.line(28,32,28,480,(111,227,193,42),1);c.line(484,32,484,480,(111,227,193,28),1)
    tickscale(c,39,468,11,8,False,(120,147,158,105));c.circle(473,39,3,AMBER,True)
    return c

def button(w=256,h=64,kind='normal'):
    c=C(w,h); cut=8; yoff=1 if kind=='pressed' else 0; x=1; y=1+yoff; pts=[(x+cut,y),(w-20,y),(w-1,y+cut),(w-1,h-9+yoff),(w-10,h-1+yoff),(x+cut,h-1+yoff),(x,y+h-9+yoff),(x,y+cut)]
    base={'normal':(17,29,40,248),'hover':(20,36,46,250),'pressed':(10,17,25,255),'disabled':(17,24,30,165)}[kind]
    edge={'normal':EDGE,'hover':CYAN,'pressed':(77,100,112,255),'disabled':(91,104,109,130)}[kind]
    c.poly(pts,base);stroke_poly(c,pts,edge,1.2 if kind!='hover' else 1.8)
    accent={'normal':AMBER,'hover':CYAN,'pressed':(171,116,67,255),'disabled':(92,103,104,130)}[kind]
    c.line(13,12,13,50,accent,2)
    if kind=='disabled':
        for xx in range(22,51,7):c.line(xx,52,xx+3,52,(140,151,153,150),1)
        c.circle(w-19,18,3,(107,118,120,160),False,1)
    else:
        c.circle(w-18,17,3,accent,False,1);c.line(24,12,w-30,12,(226,239,239,28),1)
    # tactile grooves, not glow
    c.line(22,h-8,w-27,h-8,(5,9,13,150),1)
    return c

def tab(active):
    c=C(192,48);pts=[(0,0),(182,0),(192,10),(192,47),(0,47)]
    c.poly(pts,(17,28,39,240) if active else (14,22,31,180));stroke_poly(c,pts,EDGE if not active else (129,150,156,220),1)
    if active:
        c.line(13,45,178,45,AMBER,3);c.line(15,8,44,8,CYAN,1)
    else:c.line(15,45,177,45,(100,119,128,120),1)
    return c

def row(selected):
    c=C(512,56);c.poly([(0,0),(500,0),(512,12),(512,44),(500,56),(0,56)],(18,30,42,220) if selected else (14,23,33,150))
    c.line(0,0,500,0,(112,139,148,90),1);c.line(0,55,500,55,(112,139,148,45),1)
    if selected:
        c.rect(0,0,3,56,AMBER);c.circle(25,28,7,(242,166,90,35),True);c.circle(25,28,3,AMBER,True)
        c.line(40,11,40,45,(111,227,193,85),1)
    else:c.circle(25,28,3,(144,165,174,160),False,1)
    c.line(54,14,54,42,(102,131,145,80),1);c.line(482,28,492,28,(242,166,90,170) if selected else EDGE,1)
    return c

def badge(kind):
    c=C(48,48)
    if kind=='done':
        c.poly([(24,3),(41,12),(41,34),(24,45),(7,35),(7,13)],(15,36,36,230));stroke_poly(c,[(24,3),(41,12),(41,34),(24,45),(7,35),(7,13)],GREEN,1.8)
        c.line(14,24,21,31,GREEN,3);c.line(21,31,35,16,GREEN,3)
    elif kind=='locked':
        c.circle(24,18,10,(144,165,174,210),False,2);c.rect(12,19,24,19,(24,35,45,245));outline_rect(c,12,19,24,19,EDGE,1.5,3);c.circle(24,26,2,PALE,True);c.line(24,28,24,33,PALE,1.5)
    else:
        c.circle(24,24,19,(22,35,46,200),False,1.5);c.circle(24,24,13,(242,166,90,255),False,2);c.circle(24,24,4,AMBER,True);c.line(24,2,24,8,AMBER,2)
    return c

def icon(name,size=128):
    c=C(size,size); k=size/128; w=max(2,3*k); col=PALE
    def L(a,b,color=col,th=w):c.line(a[0]*k,a[1]*k,b[0]*k,b[1]*k,color,th)
    def circ(x,y,r,fill=False,color=col,th=w):c.circle(x*k,y*k,r*k,color,fill,th)
    def ell(x,y,rx,ry,fill=False,color=col,th=w):c.ellipse(x*k,y*k,rx*k,ry*k,color,fill,th)
    def arc(x,y,rx,ry,a,b,color=col,th=w):c.arc(x*k,y*k,rx*k,ry*k,a,b,color,th)
    if name=='seasons':
        circ(64,64,37);L((40,28),(55,27));L((55,27),(69,40));L((69,40),(77,56));L((77,56),(86,70));L((86,70),(85,91));L((85,91),(72,100));L((72,100),(56,98));L((56,98),(44,85));L((44,85),(39,69));L((39,69),(43,50));L((43,50),(55,27));L((47,91),(78,36),CYAN,w)
        L((23,64),(35,64));L((93,64),(105,64))
    elif name=='measurement':
        c.poly([(25*k,42*k),(104*k,42*k),(104*k,85*k),(25*k,85*k)],(15,24,36,0));stroke_poly(c,[(25*k,42*k),(104*k,42*k),(104*k,85*k),(25*k,85*k)],col,w)
        for i in range(9):
            x=(32+i*8)*k;c.line(x,43*k,x,(58 if i%2==0 else 52)*k,col,w*.8)
        L((35,65),(94,65),CYAN,w)
    elif name=='vectors':
        L((28,98),(28,32));L((28,98),(101,98));L((28,98),(87,43),CYAN,w);L((28,98),(94,73),AMBER,w)
        for p,q in [((28,32),(23,42)),((28,32),(33,42)),((101,98),(90,93)),((101,98),(91,103)),((87,43),(73,45)),((87,43),(82,57)),((94,73),(80,72)),((94,73),(89,86))]:L(p,q)
        circ(28,98,3,True)
    elif name=='bridge':
        L((20,90),(108,90));L((27,90),(27,49));L((101,90),(101,49));L((27,49),(64,88),CYAN,w);L((64,88),(101,49),CYAN,w);L((27,49),(101,49));L((64,49),(64,90));L((45,49),(45,69));L((83,49),(83,69));L((17,98),(111,98),AMBER,w)
    elif name=='prism':
        stroke_poly(c,[(37*k,35*k),(91*k,64*k),(37*k,94*k)],col,w);L((15,64),(37,64));L((91,64),(111,51),AMBER,w);L((91,64),(113,64),CYAN,w);L((91,64),(111,77),PALE,w);L((15,59),(15,69))
    elif name=='free_fall':
        circ(64,35,10,False);L((64,49),(64,87),CYAN,w);L((64,87),(55,77));L((64,87),(73,77));L((35,100),(93,100));L((42,94),(42,106));L((86,94),(86,106));L((49,22),(49,15));L((79,22),(79,15))
    elif name=='indicator':
        stroke_poly(c,[(48*k,18*k),(80*k,18*k),(75*k,83*k),(67*k,100*k),(59*k,95*k),(52*k,82*k)],col,w)
        L((52,64),(76,64),CYAN,w);L((58,82),(72,82),AMBER,w);L((55,29),(73,29));L((60,42),(74,42))
    elif name=='heart':
        # clean anatomical heart silhouette with aortic arch, valves, and two vessels
        pts=[(64,103),(47,92),(34,77),(28,61),(32,46),(44,39),(55,43),(64,54),(73,43),(86,39),(98,47),(101,62),(94,79),(80,94),(64,103)]
        stroke_poly(c,[(x*k,y*k) for x,y in pts],col,w);L((56,43),(51,28));L((51,28),(57,20));L((57,20),(67,20));L((67,20),(72,39));L((72,39),(78,49),CYAN,w);L((50,59),(64,67));L((64,67),(74,58));L((64,67),(60,84));L((60,84),(70,91))
    elif name=='pressure':
        arc(64,69,39,39,190,350,col,w);L((25,69),(25,94));L((25,94),(103,94));L((103,94),(103,69));circ(64,66,3,True);L((64,66),(84,43),AMBER,w);L((38,73),(33,70));L((48,49),(44,43));L((64,38),(64,31));L((81,49),(85,43));L((91,73),(97,70))
    elif name.startswith('route_'):
        typ=name[6:]
        if typ=='class':
            stroke_poly(c,[(26*k,36*k),(61*k,36*k),(64*k,42*k),(67*k,36*k),(102*k,36*k),(102*k,90*k),(66*k,90*k),(64*k,95*k),(60*k,90*k),(26*k,90*k)],col,w);L((64,42),(64,90),CYAN,w);L((36,50),(54,50));L((74,50),(92,50));L((36,60),(54,60));L((74,60),(92,60))
        elif typ=='lgs':
            stroke_poly(c,[(37*k,24*k),(82*k,24*k),(94*k,36*k),(94*k,102*k),(37*k,102*k)],col,w);L((82,24),(82,36));L((82,36),(94,36));L((48,52),(82,52));L((48,65),(82,65));L((48,78),(72,78),AMBER,w);L((48,91),(78,91))
        elif typ=='tyt':
            circ(64,64,38);circ(64,64,23,False,CYAN,w);circ(64,64,6,False,AMBER,w);L((64,16),(64,25));L((64,103),(64,112));L((16,64),(25,64));L((103,64),(112,64))
        else:
            circ(64,64,38);circ(64,64,4,True,AMBER);circ(46,47,3,True);circ(82,44,3,True);circ(83,81,3,True);circ(45,83,3,True);L((46,47),(82,44),CYAN,w);L((82,44),(83,81),CYAN,w);L((83,81),(45,83),CYAN,w)
    elif name.startswith('state_'):
        typ=name[6:]
        if typ=='playable':
            circ(64,64,29,False,col,w);stroke_poly(c,[(55*k,47*k),(82*k,64*k),(55*k,81*k)],CYAN,w)
        elif typ=='ready':
            circ(64,64,29,False,AMBER,w);circ(64,64,13,False,col,w);circ(64,64,4,True,AMBER);L((64,23),(64,30),AMBER,w)
        else:
            circ(64,64,29,False,GREEN,w);L((48,64),(60,76),GREEN,w*1.5);L((60,76),(82,50),GREEN,w*1.5);L((43,35),(50,29),GREEN,w)
    return c

def plinth():
    c=C(1024,1024)
    # Floating three-quarter instrument dock: a squat, elliptical machined pedestal.
    c.ellipse(512,670,395,164,(5,8,12,130),True)
    c.poly([(165,515),(860,515),(918,600),(876,755),(512,875),(147,755),(106,600)],(19,29,38,255))
    stroke_poly(c,[(165,515),(860,515),(918,600),(876,755),(512,875),(147,755),(106,600)],(66,83,92,255),4)
    c.ellipse(512,548,368,153,(27,41,51,255),True);c.ellipse(512,548,368,153,(94,117,127,255),False,4)
    c.ellipse(512,526,324,126,(13,22,31,255),True);c.ellipse(512,526,324,126,(153,161,145,200),False,2)
    c.arc(512,526,315,121,195,335,AMBER,3)
    c.ellipse(512,520,244,83,(24,38,48,255),True);c.ellipse(512,520,244,83,(71,93,105,255),False,3)
    # central mounting bed and star-shaped orientation index
    c.poly([(335,466),(689,466),(724,514),(689,571),(335,571),(300,514)],(18,29,39,255));stroke_poly(c,[(335,466),(689,466),(724,514),(689,571),(335,571),(300,514)],(111,227,193,155),2)
    c.ellipse(512,514,97,31,(8,14,21,255),True);c.ellipse(512,514,97,31,(242,166,90,220),False,2)
    for x,y in [(177,548),(847,548),(213,696),(811,696),(512,735)]:
        c.circle(x,y,9,(9,15,21,255),True);c.circle(x,y,4,(110,127,131,255),False,2);c.line(x-3,y,x+3,y,(140,151,148,255),1)
    for i in range(25):
        a=math.radians(198+i*6);x=512+324*math.cos(a);y=526+126*math.sin(a);x2=512+((303 if i%4 else 294)*math.cos(a));y2=526+((117 if i%4 else 110)*math.sin(a));c.line(x,y,x2,y2,(143,158,156,210),1)
    return c

def mission_frame():
    c=C(1920,1080)
    # Peripheral rails only; transparent playable aperture and right-side narrow dock.
    c.poly([(0,0),(1920,0),(1920,30),(1475,30),(1460,46),(132,46),(116,30),(0,30)],(15,24,36,215))
    c.poly([(0,1050),(1920,1050),(1920,1080),(0,1080)],(15,24,36,225))
    c.poly([(0,30),(34,30),(34,1048),(0,1050)],(15,24,36,190));c.poly([(1886,30),(1920,30),(1920,1050),(1886,1050)],(15,24,36,190))
    c.line(36,46,1445,46,EDGE,1);c.line(1475,30,1885,30,AMBER,2);c.line(40,1048,1880,1048,EDGE,1)
    c.line(1460,46,1460,1046,(111,227,193,125),1);c.line(1465,62,1465,170,(242,166,90,185),2)
    # Corner fittings are functional anchors, sparse and outside the main view.
    for x,y in [(18,18),(1902,18),(18,1062),(1902,1062)]:
        c.circle(x,y,7,(7,11,18,255),True);c.circle(x,y,4,EDGE,False,1);c.line(x-2,y,x+2,y,(129,148,154,180),1)
    for i in range(23):c.line(60+i*12,1058,60+i*12,1064,(105,129,139,125),1)
    return c

def info_panel():
    c=C(512,768);pts=clipped(512,768,20);c.poly(pts,(15,24,36,220));stroke_poly(c,pts,EDGE,1)
    c.poly([(20,20),(492,20),(492,74),(20,74)],(22,34,43,240));c.line(20,74,492,74,AMBER,2)
    c.line(36,36,68,36,CYAN,2);c.line(36,55,124,55,(144,165,174,115),1)
    outline_rect(c,8,8,496,752,(111,227,193,35),1,15)
    c.line(28,740,120,740,AMBER,1);tickscale(c,470,110,9,9,True,(116,143,152,90))
    return c

def primary(state):
    c=C(320,72);base=button(320,72,state);c.p=base.p
    # Warm ceramic switch cap with a mechanically framed amber lane.
    if state=='disabled':
        c.poly([(18,7),(294,7),(311,24),(311,49),(294,66),(18,66),(8,56),(8,17)],(42,39,34,200));col=(155,128,94,150)
    else:
        c.poly([(18,7),(294,7),(311,24),(311,49),(294,66),(18,66),(8,56),(8,17)],(50,38,27,248) if state!='pressed' else (31,27,23,255));col=AMBER if state!='hover' else (255,195,119,255)
    stroke_poly(c,[(18,7),(294,7),(311,24),(311,49),(294,66),(18,66),(8,56),(8,17)],col,1.6)
    c.line(20,13,20,59,col,3);c.line(31,15,31,57,(242,166,90,100),1)
    if state=='disabled':
        for x in range(48,102,10):c.line(x,60,x+3,60,(151,129,102,125),1)
    else:c.circle(291,36,4,col,False,1.5)
    return c

def skip(state):
    c=C(160,44);pts=[(8,2),(151,2),(158,9),(158,35),(150,42),(8,42),(2,36),(2,8)]
    c.poly(pts,(16,25,34,200) if state=='normal' else (20,34,43,240));stroke_poly(c,pts,CYAN if state=='hover' else (110,135,145,190),1)
    c.line(13,8,13,36,(242,166,90,180),1.5);c.line(24,10,54,10,(232,241,242,55),1);c.line(147,20,153,20,CYAN if state=='hover' else EDGE,1)
    return c

def title_plate():
    c=C(1280,360);pts=[(48,24),(1190,24),(1244,79),(1244,278),(1202,326),(76,326),(35,284),(35,73)]
    c.poly(pts,(16,24,32,240));stroke_poly(c,pts,(98,122,130,230),2)
    c.poly([(61,42),(1184,42),(1218,77),(1218,271),(1185,304),(93,304),(61,272)],(20,30,37,170));stroke_poly(c,[(61,42),(1184,42),(1218,77),(1218,271),(1185,304),(93,304),(61,272)],(75,98,107,150),1)
    c.line(82,51,311,51,CYAN,1);c.line(885,309,1167,309,AMBER,2)
    # One broken seam, visibly caused by the fault indicator at the upper right.
    crack=[(1141,26),(1120,89),(1148,119),(1117,159),(1135,189),(1107,231),(1134,278)]
    for p,q in zip(crack,crack[1:]):c.line(*p,*q,(137,145,140,190),2)
    c.line(1175,39,1206,39,RED,3);c.circle(1198,59,5,RED,True);c.circle(1198,59,10,(229,100,90,65),False,1)
    for x,y in [(78,64),(1200,290),(78,290)]:c.circle(x,y,4,(7,11,18,255),True);c.circle(x,y,1.5,EDGE,True)
    return c

def flow_arrow():
    c=C(128,64);c.line(8,32,108,32,(232,241,242,235),3);c.line(92,14,110,32,(232,241,242,235),3);c.line(110,32,92,50,(232,241,242,235),3)
    for x in (28,48,68):c.circle(x,32,2,(111,227,193,200),True)
    return c

def generate():
    os.makedirs(UI,exist_ok=True);os.makedirs(os.path.join(UI,'icons'),exist_ok=True);os.makedirs(WORLD,exist_ok=True)
    assets={'panel_glass.png':panel(),'btn_normal.png':button(kind='normal'),'btn_hover.png':button(kind='hover'),'btn_pressed.png':button(kind='pressed'),'btn_disabled.png':button(kind='disabled'),'tab_active.png':tab(True),'tab_idle.png':tab(False),'list_row_idle.png':row(False),'list_row_selected.png':row(True),'badge_done.png':badge('done'),'badge_locked.png':badge('locked'),'badge_ready.png':badge('ready'),'bg_mission_frame.png':mission_frame(),'panel_info.png':info_panel(),'btn_primary_normal.png':primary('normal'),'btn_primary_hover.png':primary('hover'),'btn_primary_pressed.png':primary('pressed'),'btn_primary_disabled.png':primary('disabled'),'btn_skip_normal.png':skip('normal'),'btn_skip_hover.png':skip('hover'),'intro_title_plate.png':title_plate(),'flow_arrow.png':flow_arrow(),'icons/seasons.png':icon('seasons'),'icons/measurement.png':icon('measurement'),'icons/vectors.png':icon('vectors'),'icons/bridge.png':icon('bridge'),'icons/prism.png':icon('prism'),'icons/free_fall.png':icon('free_fall'),'icons/indicator.png':icon('indicator'),'icons/heart.png':icon('heart'),'icons/pressure.png':icon('pressure'),'icons/route_class.png':icon('route_class'),'icons/route_lgs.png':icon('route_lgs'),'icons/route_tyt.png':icon('route_tyt'),'icons/route_ayt.png':icon('route_ayt'),'icons/state_playable.png':icon('state_playable',64),'icons/state_ready.png':icon('state_ready',64),'icons/state_repaired.png':icon('state_repaired',64)}
    for name,canvas in assets.items():canvas.png(os.path.join(UI,name))
    plinth().png(os.path.join(WORLD,'station_plinth.png'))
    print(f'Generated {len(assets)+1} PNG assets in assets/ui and assets/world.')
if __name__=='__main__':generate()
