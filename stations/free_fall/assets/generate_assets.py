#!/usr/bin/env python3
"""Generate procedural meshes, sensor states, and PBR maps for the Free Fall Room.

The delivered scene backdrops are separate raster art and are intentionally left
untouched by this script.
"""
from __future__ import annotations

import json
import math
import random
import struct
import zlib
from pathlib import Path

OUT = Path(__file__).resolve().parent
OUT.mkdir(parents=True, exist_ok=True)


class Canvas:
    def __init__(self, w: int, h: int, rgba=(0, 0, 0, 0)):
        self.w, self.h = w, h
        self.p = bytearray(bytes(rgba) * (w * h))

    def blend(self, x, y, c):
        if not (0 <= x < self.w and 0 <= y < self.h):
            return
        i = (y * self.w + x) * 4
        a = c[3] / 255.0
        if a >= 1:
            self.p[i:i+4] = bytes(c)
        elif a > 0:
            ia = 1 - a
            self.p[i] = int(c[0] * a + self.p[i] * ia)
            self.p[i+1] = int(c[1] * a + self.p[i+1] * ia)
            self.p[i+2] = int(c[2] * a + self.p[i+2] * ia)
            self.p[i+3] = min(255, int(c[3] + self.p[i+3] * ia))

    def rect(self, x0, y0, x1, y1, c):
        for y in range(max(0, int(y0)), min(self.h, int(y1))):
            start = (y * self.w + max(0, int(x0))) * 4
            end = (y * self.w + min(self.w, int(x1))) * 4
            if c[3] == 255:
                self.p[start:end] = bytes(c) * ((end - start) // 4)
            else:
                for x in range(max(0, int(x0)), min(self.w, int(x1))):
                    self.blend(x, y, c)

    def circle(self, cx, cy, r, c, fill=True, width=1):
        x0, x1 = max(0, int(cx-r-width)), min(self.w, int(cx+r+width+1))
        y0, y1 = max(0, int(cy-r-width)), min(self.h, int(cy+r+width+1))
        rr = r*r
        inner = max(0, r-width) ** 2
        outer = (r+width) ** 2
        for y in range(y0, y1):
            for x in range(x0, x1):
                d = (x-cx)**2 + (y-cy)**2
                if (fill and d <= rr) or (not fill and inner <= d <= outer):
                    self.blend(x, y, c)

    def line(self, x0, y0, x1, y1, c, width=2):
        dx, dy = x1-x0, y1-y0
        steps = max(1, int(max(abs(dx), abs(dy))))
        for n in range(steps+1):
            t = n / steps
            self.circle(x0+dx*t, y0+dy*t, width/2, c, True)

    def polygon(self, pts, c):
        ymin = max(0, int(min(y for _, y in pts)))
        ymax = min(self.h-1, int(max(y for _, y in pts)))
        for y in range(ymin, ymax+1):
            xs = []
            for i, (x1, y1) in enumerate(pts):
                x2, y2 = pts[(i+1) % len(pts)]
                if (y1 <= y < y2) or (y2 <= y < y1):
                    xs.append(x1 + (y-y1) * (x2-x1) / (y2-y1))
            xs.sort()
            for i in range(0, len(xs)-1, 2):
                self.rect(int(xs[i]), y, int(xs[i+1])+1, y+1, c)

    def save(self, path):
        raw = b"".join(b"\0" + bytes(self.p[y*self.w*4:(y+1)*self.w*4]) for y in range(self.h))
        def chunk(tag, data):
            return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag+data) & 0xffffffff)
        data = b"\x89PNG\r\n\x1a\n"
        data += chunk(b"IHDR", struct.pack(">IIBBBBB", self.w, self.h, 8, 6, 0, 0, 0))
        data += chunk(b"IDAT", zlib.compress(raw, 8)) + chunk(b"IEND", b"")
        Path(path).parent.mkdir(parents=True, exist_ok=True)
        Path(path).write_bytes(data)


def make_sensor(name, triggered):
    c = Canvas(512, 512)
    c.circle(256, 256, 220, (16,28,37,255), True)
    c.circle(256, 256, 210, (68,88,92,255), False, 8)
    c.circle(256, 256, 176, (25,43,49,255), True)
    c.circle(256, 256, 158, (65,102,103,240) if triggered else (50,79,84,235), False, 12)
    c.circle(256, 256, 116, (255,175,74,150) if triggered else (39,64,69,255), True)
    c.circle(256, 256, 82, (255,196,101,255) if triggered else (23,39,45,255), True)
    c.circle(256, 256, 57, (255,224,166,255) if triggered else (72,104,106,255), False, 8)
    for i in range(12):
        a = math.radians(i*30)
        x1, y1 = 256+math.cos(a)*178, 256+math.sin(a)*178
        x2, y2 = 256+math.cos(a)*196, 256+math.sin(a)*196
        c.line(x1,y1,x2,y2,(255,190,94,235) if triggered else (121,148,146,220),5)
    for x,y in ((104,104),(408,104),(104,408),(408,408)):
        c.circle(x,y,10,(145,158,154,255),True)
        c.circle(x,y,4,(38,51,54,255),True)
    if triggered:
        for r in (138, 151):
            c.circle(256,256,r,(255,174,73,100),False,3)
    c.save(OUT/name)


def texture(name, kind, seed=1):
    w=h=2048
    rng=random.Random(seed)
    tw=th=512
    tile=bytearray()
    # Build a modest tile, then repeat it for a seamless 2048 PBR map.
    for y in range(th):
        line=bytearray()
        for x in range(tw):
            wave=(math.sin(x/512*math.tau*4)+math.sin(y/512*math.tau*3))*0.5
            grain=rng.randint(-4,4)
            if kind == "metal_albedo":
                b=max(0,min(255,int(68+wave*7+grain)))
                line.extend((b,b+8,b+15,255))
            elif kind == "metal_normal":
                line.extend((128+int(wave*5),128+int(math.cos(x/74)*5),250,255))
            elif kind == "metal_roughness":
                v=max(0,min(255,int(190+wave*8+grain)))
                line.extend((v,v,v,255))
            elif kind == "glass_albedo":
                v=max(0,min(255,int(24+wave*4+grain)))
                line.extend((v,v+10,v+13,255))
            elif kind == "glass_normal":
                line.extend((128+int(wave*2),128+int(math.sin(y/110)*2),255,255))
            else:
                v=max(0,min(255,int(38+wave*3+grain)))
                line.extend((v,v,v,255))
        tile.extend(line)
    c=Canvas(w,h)
    c.p=tile*16
    c.save(OUT/(name+".png"))


# ---------- Minimal glTF 2.0 binary builder ----------
class GLB:
    def __init__(self):
        self.bin=bytearray(); self.views=[]; self.accessors=[]; self.meshes=[]; self.nodes=[]; self.materials=[]
    def material(self,name,color,metallic=0.1,roughness=0.35,alpha=1.0,emissive=None):
        m={"name":name,"pbrMetallicRoughness":{"baseColorFactor":[*color,alpha],"metallicFactor":metallic,"roughnessFactor":roughness}}
        if alpha < 1: m["alphaMode"]="BLEND"; m["doubleSided"]=True
        if emissive: m["emissiveFactor"]=emissive
        self.materials.append(m); return len(self.materials)-1
    def _accessor(self,data,fmt,component,count,typ,target=None,minimum=None,maximum=None):
        while len(self.bin)%4: self.bin.append(0)
        offset=len(self.bin); self.bin.extend(struct.pack("<"+fmt*len(data),*data))
        v={"buffer":0,"byteOffset":offset,"byteLength":len(self.bin)-offset}
        if target: v["target"]=target
        self.views.append(v)
        a={"bufferView":len(self.views)-1,"componentType":component,"count":count,"type":typ}
        if minimum is not None: a["min"]=minimum; a["max"]=maximum
        self.accessors.append(a); return len(self.accessors)-1
    def add_mesh(self,name,positions,normals,indices,mat):
        mins=[min(p[i] for p in positions) for i in range(3)]; maxs=[max(p[i] for p in positions) for i in range(3)]
        pa=self._accessor([q for p in positions for q in p],"f",5126,len(positions),"VEC3",34962,mins,maxs)
        na=self._accessor([q for p in normals for q in p],"f",5126,len(normals),"VEC3",34962)
        ia=self._accessor(indices,"I" if len(positions)>65535 else "H",5125 if len(positions)>65535 else 5123,len(indices),"SCALAR",34963)
        self.meshes.append({"name":name,"primitives":[{"attributes":{"POSITION":pa,"NORMAL":na},"indices":ia,"material":mat,"mode":4}]})
        self.nodes.append({"name":name,"mesh":len(self.meshes)-1})
    def add_empty(self,name,translation=(0,0,0)):
        self.nodes.append({"name":name,"translation":list(translation)})
    def finish(self,path,scene_nodes=None):
        doc={"asset":{"version":"2.0","generator":"Glitch Academy procedural asset builder"},"scene":0,"scenes":[{"nodes":scene_nodes if scene_nodes is not None else list(range(len(self.nodes)))}],"nodes":self.nodes,"meshes":self.meshes,"materials":self.materials,"accessors":self.accessors,"bufferViews":self.views,"buffers":[{"byteLength":len(self.bin)}]}
        js=json.dumps(doc,separators=(",",":"),ensure_ascii=False).encode("utf-8")
        js+=b" "*((4-len(js)%4)%4); bn=bytes(self.bin)+b"\0"*((4-len(self.bin)%4)%4)
        total=12+8+len(js)+8+len(bn)
        out=struct.pack("<4sII",b"glTF",2,total)+struct.pack("<I4s",len(js),b"JSON")+js+struct.pack("<I4s",len(bn),b"BIN\0")+bn
        Path(path).write_bytes(out)


def cylinder(r,h,y=0,n=32,cap=True):
    pos=[]; norm=[]; idx=[]
    for yy in (y-h/2,y+h/2):
        for i in range(n):
            a=2*math.pi*i/n; x=r*math.cos(a); z=r*math.sin(a)
            pos.append((x,yy,z)); norm.append((math.cos(a),0,math.sin(a)))
    for i in range(n):
        j=(i+1)%n; idx.extend((i,j,n+j,i,n+j,n+i))
    if cap:
        for top in (False,True):
            base=len(pos); yy=y+(h/2 if top else -h/2); normal=(0,1 if top else -1,0)
            pos.append((0,yy,0)); norm.append(normal)
            ring=n if top else 0
            for i in range(n):
                j=(i+1)%n; idx.extend((base,ring+i,ring+j) if top else (base,ring+j,ring+i))
    return pos,norm,idx


def sphere(r,center=(0,0,0),n=24,m=16):
    pos=[]; norm=[]; idx=[]
    for j in range(m+1):
        v=math.pi*j/m
        for i in range(n+1):
            u=2*math.pi*i/n
            nx=math.sin(v)*math.cos(u); ny=math.cos(v); nz=math.sin(v)*math.sin(u)
            pos.append((center[0]+r*nx,center[1]+r*ny,center[2]+r*nz)); norm.append((nx,ny,nz))
    for j in range(m):
        for i in range(n):
            a=j*(n+1)+i; b=a+n+1; idx.extend((a,b,a+1,a+1,b,b+1))
    return pos,norm,idx


def box(sx,sy,sz,center=(0,0,0)):
    x,y,z=center; hx,hy,hz=sx/2,sy/2,sz/2
    faces=[((0,0,1),[(-hx,-hy,hz),(hx,-hy,hz),(hx,hy,hz),(-hx,hy,hz)]),((0,0,-1),[(hx,-hy,-hz),(-hx,-hy,-hz),(-hx,hy,-hz),(hx,hy,-hz)]),((1,0,0),[(hx,-hy,hz),(hx,-hy,-hz),(hx,hy,-hz),(hx,hy,hz)]),((-1,0,0),[(-hx,-hy,-hz),(-hx,-hy,hz),(-hx,hy,hz),(-hx,hy,-hz)]),((0,1,0),[(-hx,hy,hz),(hx,hy,hz),(hx,hy,-hz),(-hx,hy,-hz)]),((0,-1,0),[(-hx,-hy,-hz),(hx,-hy,-hz),(hx,-hy,hz),(-hx,-hy,hz)])]
    pos=[];norm=[];idx=[]
    for no,vs in faces:
        base=len(pos)
        for v in vs: pos.append((v[0]+x,v[1]+y,v[2]+z)); norm.append(no)
        idx.extend((base,base+1,base+2,base,base+2,base+3))
    return pos,norm,idx


def torus(R,r,y,n=48,m=10):
    pos=[];norm=[];idx=[]
    for i in range(n):
        u=2*math.pi*i/n
        for j in range(m):
            v=2*math.pi*j/m
            nx=math.cos(v)*math.cos(u); ny=math.sin(v); nz=math.cos(v)*math.sin(u)
            pos.append(((R+r*math.cos(v))*math.cos(u),y+r*math.sin(v),(R+r*math.cos(v))*math.sin(u)))
            norm.append((nx,ny,nz))
    for i in range(n):
        for j in range(m):
            a=i*m+j; b=((i+1)%n)*m+j; c=i*m+(j+1)%m; d=((i+1)%n)*m+(j+1)%m
            idx.extend((a,b,c,c,b,d))
    return pos,norm,idx


def transform(mesh,offset=(0,0,0),scale=(1,1,1)):
    p,n,idx=mesh; ox,oy,oz=offset; sx,sy,sz=scale
    return ([(x*sx+ox,y*sy+oy,z*sz+oz) for x,y,z in p],[(x,y,z) for x,y,z in n],idx)


def add_chamber():
    g=GLB()
    steel=g.material("Brushed steel",(0.21,0.29,0.34),0.72,0.31)
    steel_dark=g.material("Dark steel",(0.09,0.15,0.19),0.68,0.38)
    glass=g.material("Blue green borosilicate glass",(0.35,0.75,0.76),0.0,0.14,0.24,(0.02,0.09,0.10))
    amber=g.material("Sensor amber",(1.0,0.48,0.12),0.2,0.22,1.0,(0.75,0.22,0.03))
    red=g.material("Release markers",(0.72,0.18,0.14),0.15,0.32)
    # 5 m total envelope: base starts at 0.10 m and top cap ends at 5.00 m.
    g.add_mesh("Base",*transform(cylinder(.72,.52,.26,48),scale=(1,1,1)),steel)
    g.add_mesh("Base_Rim",*transform(torus(.69,.045,.63,48,8)),steel_dark)
    g.add_mesh("Glass",*transform(cylinder(.46,4.18,2.77,48,False)),glass)
    g.add_mesh("TopCap",*transform(cylinder(.55,.18,4.91,48),),steel)
    g.add_mesh("BottomCap",*transform(cylinder(.54,.14,.64,48),),steel)
    g.add_mesh("Top_Glass_Rim",*transform(torus(.46,.035,4.86,48,8)),steel_dark)
    g.add_mesh("Bottom_Glass_Rim",*transform(torus(.46,.035,.69,48,8)),steel_dark)
    # Pump line and compact valve body on the right side.
    p1=transform(cylinder(.045,2.45,1.85,16),offset=(.58,0,0),scale=(1,1,1))
    g.add_mesh("PumpTube",*p1,glass)
    g.add_mesh("PumpLine_Lower",*transform(box(.28,.09,.09,(.48,1.85,0))),glass)
    g.add_mesh("PumpLine_Upper",*transform(box(.28,.09,.09,(.48,3.05,0))),glass)
    g.add_mesh("PumpBody",*transform(cylinder(.18,.34,1.06,24),offset=(.58,0,0)),steel_dark)
    g.add_mesh("Sensor_Plate",*transform(cylinder(.30,.055,.77,32),),amber)
    g.add_mesh("Release_Left",*transform(box(.20,.16,.20,(-.20,4.49,0))),red)
    g.add_mesh("Release_Right",*transform(box(.20,.16,.20,(.20,4.49,0))),red)
    # Reference empties are useful attachment points for falling masses.
    g.add_empty("Release_Left_Anchor",(-.20,4.34,0)); g.add_empty("Release_Right_Anchor",(.20,4.34,0))
    g.finish(OUT/"chamber.glb")


def add_mass(name, color, metallic, roughness, accent):
    g=GLB(); label="Aluminum" if name=="MassLight" else "Brass"; main=g.material(label+" PBR",color,metallic,roughness); band=g.material(label+" machined accent",accent,metallic,roughness*.7)
    g.add_mesh(name,*transform(cylinder(.18,.34,0,48),),main)
    g.add_mesh("Top_Rim",*transform(torus(.16,.018,.172,48,8)),band)
    g.add_mesh("Bottom_Rim",*transform(torus(.16,.018,-.172,48,8)),band)
    g.add_mesh("Top_Face",*transform(cylinder(.145,.012,.173,48),),band)
    g.finish(OUT/("mass_light.glb" if name=="MassLight" else "mass_heavy.glb"))


def main():
    make_sensor("sensor_plate_off.png",False)
    make_sensor("sensor_plate_on.png",True)
    add_chamber()
    add_mass("MassLight",(0.67,0.76,0.80),0.82,0.24,(0.88,0.93,0.96))
    add_mass("MassHeavy",(0.64,0.39,0.16),0.74,0.27,(0.90,0.62,0.28))
    for nm,kd,seed in (("tex_metal_albedo","metal_albedo",4),("tex_metal_normal","metal_normal",5),("tex_metal_roughness","metal_roughness",6),("tex_glass_albedo","glass_albedo",7),("tex_glass_normal","glass_normal",8),("tex_glass_roughness","glass_roughness",9)):
        texture(nm,kd,seed)
    print("Generated Free Fall Room assets in",OUT)


if __name__ == "__main__":
    main()
