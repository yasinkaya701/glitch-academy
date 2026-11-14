#!/usr/bin/env python3
"""Build the original, meter-scale perfusion equipment GLBs in this folder."""
from __future__ import annotations

import json
import math
import struct
from pathlib import Path

OUT = Path(__file__).resolve().parent


class Model:
    def __init__(self):
        self.parts = []
        self.nodes = []
        self.materials = []
        self.mat_ids = {}

    def mat(self, name, color, metallic=0.0, roughness=0.4, alpha=1.0, emissive=None):
        if name not in self.mat_ids:
            pbr = {"baseColorFactor": [*color, alpha], "metallicFactor": metallic, "roughnessFactor": roughness}
            item = {"name": name, "pbrMetallicRoughness": pbr}
            if alpha < 1.0:
                item["alphaMode"] = "BLEND"
                item["doubleSided"] = True
            if emissive:
                item["emissiveFactor"] = emissive
            self.mat_ids[name] = len(self.materials)
            self.materials.append(item)
        return self.mat_ids[name]

    def part(self, name, verts, faces, material, parent=None):
        self.parts.append((name, verts, faces, material, parent))

    def box(self, name, size, center, material, parent=None):
        sx, sy, sz = (v / 2 for v in size)
        x, y, z = center
        facespec = [
            ((0, 0, 1), [(-sx,-sy,sz),(sx,-sy,sz),(sx,sy,sz),(-sx,sy,sz)]),
            ((0, 0,-1), [(sx,-sy,-sz),(-sx,-sy,-sz),(-sx,sy,-sz),(sx,sy,-sz)]),
            ((1, 0, 0), [(sx,-sy,sz),(sx,-sy,-sz),(sx,sy,-sz),(sx,sy,sz)]),
            ((-1,0, 0), [(-sx,-sy,-sz),(-sx,-sy,sz),(-sx,sy,sz),(-sx,sy,-sz)]),
            ((0, 1, 0), [(-sx,sy,sz),(sx,sy,sz),(sx,sy,-sz),(-sx,sy,-sz)]),
            ((0,-1,0), [(-sx,-sy,-sz),(sx,-sy,-sz),(sx,-sy,sz),(-sx,-sy,sz)],),
        ]
        verts, faces = [], []
        for normal, corners in facespec:
            base = len(verts)
            verts.extend([(a+x,b+y,c+z, *normal) for a,b,c in corners])
            faces.extend([(base,base+1,base+2),(base,base+2,base+3)])
        self.part(name, verts, faces, material, parent)

    def cylinder(self, name, radius, length, center, material, axis="y", sides=48, parent=None, caps=True):
        cx, cy, cz = center
        verts, faces = [], []
        for end in (-0.5, 0.5):
            for i in range(sides):
                a = 2 * math.pi * i / sides
                u, v = math.cos(a), math.sin(a)
                if axis == "y":
                    verts.append((cx+radius*u, cy+end*length, cz+radius*v, u, 0, v))
                elif axis == "z":
                    verts.append((cx+radius*u, cy+radius*v, cz+end*length, u, v, 0))
                else:
                    verts.append((cx+end*length, cy+radius*u, cz+radius*v, 0, u, v))
        for i in range(sides):
            j = (i + 1) % sides
            if axis == "y":
                faces.extend([(i,sides+j,j),(i,sides+i,sides+j)])
            else:
                faces.extend([(i,j,sides+j),(i,sides+j,sides+i)])
        if caps:
            for end in (0, 1):
                base = len(verts)
                ysign = -1 if end == 0 else 1
                for i in range(sides):
                    a = 2 * math.pi * i / sides
                    u, v = math.cos(a), math.sin(a)
                    if axis == "y":
                        verts.append((cx+radius*u, cy+(end-0.5)*length, cz+radius*v, 0, ysign, 0))
                    elif axis == "z":
                        verts.append((cx+radius*u, cy+radius*v, cz+(end-0.5)*length, 0, 0, ysign))
                    else:
                        verts.append((cx+(end-0.5)*length, cy+radius*u, cz+radius*v, ysign, 0, 0))
                center_i = len(verts)
                if axis == "y":
                    verts.append((cx,cy+(end-0.5)*length,cz,0,ysign,0))
                elif axis == "z":
                    verts.append((cx,cy,cz+(end-0.5)*length,0,0,ysign))
                else:
                    verts.append((cx+(end-0.5)*length,cy,cz,ysign,0,0))
                for i in range(sides):
                    j = (i+1) % sides
                    if axis == "y":
                        ring_order = (i,j) if end == 0 else (j,i)
                    else:
                        ring_order = (j,i) if end == 0 else (i,j)
                    faces.append((center_i, base+ring_order[0], base+ring_order[1]))
        self.part(name, verts, faces, material, parent)

    def torus(self, name, major, minor, center, material, axis="y", parent=None, n=64, m=12):
        cx, cy, cz = center
        verts, faces = [], []
        for i in range(n):
            a = 2*math.pi*i/n
            for j in range(m):
                b = 2*math.pi*j/m
                c, s = math.cos(a), math.sin(a)
                rb = major + minor*math.cos(b)
                if axis == "y":
                    verts.append((cx+rb*c, cy+minor*s, cz+rb*math.sin(a), math.cos(b)*c, s, math.cos(b)*math.sin(a)))
                elif axis == "x":
                    verts.append((cx+minor*s, cy+rb*c, cz+rb*math.sin(a), s, math.cos(b)*c, math.cos(b)*math.sin(a)))
                else:
                    verts.append((cx+rb*c, cy+rb*math.sin(a), cz+minor*s, math.cos(b)*c, math.cos(b)*math.sin(a), s))
        for i in range(n):
            for j in range(m):
                a=i*m+j; b=((i+1)%n)*m+j; c=i*m+(j+1)%m; d=((i+1)%n)*m+(j+1)%m
                if axis == "y":
                    faces.extend([(a,c,b),(c,d,b)])
                else:
                    faces.extend([(a,b,c),(c,b,d)])
        self.part(name, verts, faces, material, parent)

    def rod(self, name, p0, p1, radius, material, parent=None, sides=20):
        ax,ay,az=p0; bx,by,bz=p1
        dx,dy,dz=bx-ax,by-ay,bz-az
        length=math.sqrt(dx*dx+dy*dy+dz*dz)
        if length == 0: return
        ux,uy,uz=dx/length,dy/length,dz/length
        ref=(0,0,1) if abs(uz)<0.9 else (0,1,0)
        vx=uy*ref[2]-uz*ref[1]; vy=uz*ref[0]-ux*ref[2]; vz=ux*ref[1]-uy*ref[0]
        vl=math.sqrt(vx*vx+vy*vy+vz*vz); vx,vy,vz=vx/vl,vy/vl,vz/vl
        wx=uy*vz-uz*vy; wy=uz*vx-ux*vz; wz=ux*vy-uy*vx
        verts=[]; faces=[]
        for p in (p0,p1):
            for i in range(sides):
                a=2*math.pi*i/sides; c=math.cos(a); s=math.sin(a)
                nx=vx*c+wx*s; ny=vy*c+wy*s; nz=vz*c+wz*s
                verts.append((p[0]+radius*nx,p[1]+radius*ny,p[2]+radius*nz,nx,ny,nz))
        for i in range(sides):
            j=(i+1)%sides; faces.extend([(i,j,sides+j),(i,sides+j,sides+i)])
        self.part(name,verts,faces,material,parent)

    def node(self, name, parent=None, translation=None):
        item={"name":name}
        if translation is not None: item["translation"]=list(translation)
        self.nodes.append(item)
        if parent is not None:
            self.nodes[parent].setdefault("children",[]).append(len(self.nodes)-1)
        return len(self.nodes)-1

    def finish(self, filename):
        binary=bytearray(); views=[]; accessors=[]; meshes=[]
        for name, verts, faces, material, parent in self.parts:
            positions=[v[:3] for v in verts]; normals=[v[3:6] for v in verts]
            while len(binary)%4: binary.append(0)
            off=len(binary)
            for p in positions: binary.extend(struct.pack("<3f",*p))
            views.append({"buffer":0,"byteOffset":off,"byteLength":len(binary)-off,"target":34962})
            pi=len(accessors); accessors.append({"bufferView":len(views)-1,"componentType":5126,"count":len(positions),"type":"VEC3","min":[min(p[k] for p in positions) for k in range(3)],"max":[max(p[k] for p in positions) for k in range(3)]})
            while len(binary)%4: binary.append(0)
            off=len(binary)
            for n in normals: binary.extend(struct.pack("<3f",*n))
            views.append({"buffer":0,"byteOffset":off,"byteLength":len(binary)-off,"target":34962})
            ni=len(accessors); accessors.append({"bufferView":len(views)-1,"componentType":5126,"count":len(normals),"type":"VEC3"})
            while len(binary)%4: binary.append(0)
            off=len(binary); idx=[v for f in faces for v in f]
            use32=len(verts)>65535
            for index in idx: binary.extend(struct.pack("<I" if use32 else "<H",index))
            views.append({"buffer":0,"byteOffset":off,"byteLength":len(binary)-off,"target":34963})
            ii=len(accessors); accessors.append({"bufferView":len(views)-1,"componentType":5125 if use32 else 5123,"count":len(idx),"type":"SCALAR"})
            meshes.append({"name":name,"primitives":[{"attributes":{"POSITION":pi,"NORMAL":ni},"indices":ii,"material":material,"mode":4}]})
            node=self.node(name,parent)
            self.nodes[node]["mesh"]=len(meshes)-1
        roots=[i for i,n in enumerate(self.nodes) if not any(i in node.get("children",[]) for node in self.nodes)]
        doc={"asset":{"version":"2.0","generator":"Glitch Academy original equipment builder"},"scene":0,"scenes":[{"nodes":roots}],"nodes":self.nodes,"meshes":meshes,"materials":self.materials,"accessors":accessors,"bufferViews":views,"buffers":[{"byteLength":len(binary)}]}
        js=json.dumps(doc,separators=(",",":"),ensure_ascii=False).encode()
        js+=b" "*((4-len(js)%4)%4); binary+=b"\0"*((4-len(binary)%4)%4)
        total=12+8+len(js)+8+len(binary)
        path=OUT/filename
        path.write_bytes(struct.pack("<4sII",b"glTF",2,total)+struct.pack("<I4s",len(js),b"JSON")+js+struct.pack("<I4s",len(binary),b"BIN\0")+binary)


def build_pump():
    m=Model(); case=m.mat("Anodized slate aluminum",(.105,.16,.19),.76,.29); steel=m.mat("Brushed surgical steel",(.62,.68,.68),.84,.24); dark=m.mat("Graphite polymer",(.035,.052,.06),.22,.34); rubber=m.mat("Matte black elastomer",(.018,.024,.026),.05,.72); ceramic=m.mat("Ivory ceramic roller",(.78,.79,.72),.1,.27); glass=m.mat("Port glass",(.18,.33,.35),.1,.16,.32)
    m.box("PumpBody",(.38,.27,.27),(0,.175,-.015),case)
    m.box("LowerFoot",(.43,.025,.30),(0,.022,-.01),dark)
    for x in (-.165,.165):
        m.cylinder("MountFoot",.012,.012,(x,.012,-.01),steel)
    # Peristaltic head is oriented toward +Z. Rotating Rollers turns all three
    # rollers about the central axis without disturbing the head or tubing.
    m.cylinder("PumpHeadBack",.108,.026,(0,.215,.139),dark,axis="z")
    m.torus("HeadRetainingRim",.094,.006,(0,.215,.156),steel,axis="z")
    m.torus("TubeRace",.071,.008,(0,.215,.161),rubber,axis="z")
    rollers=m.node("Rollers",translation=(0,.215,.176))
    for i,a in enumerate((90,210,330),1):
        r=.051; x=r*math.cos(math.radians(a)); y=r*math.sin(math.radians(a))
        m.cylinder(f"Roller_{i}",.014,.036,(x,y,0),ceramic,axis="z",parent=rollers,sides=32)
        m.cylinder(f"RollerAxle_{i}",.004,.040,(x,y,0),steel,axis="z",parent=rollers,sides=24)
    m.cylinder("DriveHub",.025,.038,(0,.215,.179),steel,axis="z")
    m.cylinder("DriveCap",.010,.006,(0,.215,.201),dark,axis="z")
    m.cylinder("TubeEntry",.012,.050,(-.122,.172,.105),steel,axis="x")
    m.cylinder("TubeExit",.012,.050,(.122,.172,.105),steel,axis="x")
    # Simple but legible controls sit outside the circular pump head envelope.
    m.box("ControlInset",(.060,.068,.008),(.139,.225,.123),dark)
    m.box("StatusDisplay",(.042,.026,.003),(.139,.244,.129),glass)
    m.cylinder("RateDial",.011,.008,(.139,.207,.130),steel,axis="z",sides=32)
    m.cylinder("StartButton",.006,.005,(.126,.173,.130),dark,axis="z",sides=24)
    m.cylinder("StopButton",.006,.005,(.152,.173,.130),dark,axis="z",sides=24)
    # Recessed heat-release slots and captive corner screws ground the shell
    # as a serviceable tabletop instrument instead of a featureless block.
    for side in (-1,1):
        for i in range(5):
            y=.095+i*.022
            m.box("CoolingSlot",(.004,.004,.065),(side*.191,y,-.035),dark)
        for y in (.070,.282):
            m.cylinder("CaseScrew",.003,.004,(side*.192,y,.090),steel,axis="x",sides=16)
    m.finish("perfusion_pump.glb")


def build_reservoir():
    m=Model(); glass=m.mat("Clear borosilicate",(.55,.74,.73),.05,.16,.20); steel=m.mat("Satin 316 stainless",(.53,.59,.59),.82,.24); dark=m.mat("Polymer gasket",(.07,.09,.09),.1,.56); fluid=m.mat("Perfusate",(.43,.035,.025),.05,.22,.75)
    m.cylinder("ReservoirWall",.076,.390,(0,.218,0),glass,sides=64,caps=False)
    m.torus("NeckRim",.074,.005,(0,.414,0),steel)
    m.torus("BaseRim",.078,.008,(0,.028,0),steel)
    m.cylinder("ReservoirCap",.072,.027,(0,.438,0),dark)
    m.cylinder("CapCollar",.063,.013,(0,.458,0),steel)
    # Ports point radially; their collars are separate, practical connection cues.
    m.cylinder("InletPort",.008,.045,(.088,.355,0),steel,axis="x")
    m.torus("InletFerrule",.011,.003,(.103,.355,0),steel,axis="x")
    m.cylinder("OutletPort",.008,.045,(-.088,.070,0),steel,axis="x")
    m.torus("OutletFerrule",.011,.003,(-.103,.070,0),steel,axis="x")
    liquid=m.node("Liquid",translation=(0,.028,0))
    m.cylinder("PerfusateVolume",.067,.205,(0,.1025,0),fluid,parent=liquid,sides=64)
    m.cylinder("LiquidSurface",.067,.002,(0,.205,0),fluid,parent=liquid,sides=64)
    m.finish("reservoir.glb")


def build_stand():
    m=Model(); steel=m.mat("Brushed stainless steel",(.53,.59,.59),.82,.24); dark=m.mat("Weighted base enamel",(.12,.16,.17),.56,.37); polymer=m.mat("Clamp polymer",(.075,.10,.10),.15,.5)
    m.cylinder("WeightedFoot",.205,.028,(0,.014,0),dark,sides=64)
    m.torus("FootEdge",.196,.004,(0,.027,0),steel)
    m.cylinder("UprightPost",.018,1.42,(0,.742,0),steel,sides=32)
    m.torus("PostCollar",.025,.004,(0,.31,0),dark)
    m.cylinder("HeightLock",.031,.045,(0,.53,0),polymer,sides=32)
    m.cylinder("LockKnob",.012,.035,(.037,.53,0),steel,axis="x",sides=24)
    m.rod("Crossbar",(-.21,1.16,0),(.21,1.16,0),.009,steel)
    for x in (-.17,.17):
        m.cylinder("EquipmentClamp",.022,.052,(x,1.16,0),polymer,sides=32)
        m.cylinder("ClampThumbScrew",.006,.040,(x,1.16,.037),steel,axis="z",sides=16)
    m.finish("stand.glb")


def build_hose_holder():
    m=Model(); steel=m.mat("Satin stainless",(.51,.57,.57),.82,.25); polymer=m.mat("Dark polymer clamp",(.055,.075,.078),.12,.49); rubber=m.mat("Silicone sleeve",(.18,.22,.21),.04,.73)
    m.box("MountingBlock",(.045,.11,.07),(0,0,-.047),polymer)
    m.box("ClampBackplate",(.12,.13,.018),(0,0,-.010),steel)
    m.cylinder("MountBoltLeft",.008,.012,(-.043,-.035,.002),steel,axis="z")
    m.cylinder("MountBoltRight",.008,.012,(.043,-.035,.002),steel,axis="z")
    for y in (-.045,.045):
        m.torus("HoseLoop",.035,.006,(0,y,.038),steel,axis="x",n=40,m=10)
        m.torus("SoftContactLiner",.031,.002,(0,y,.038),rubber,axis="x",n=40,m=8)
    m.box("LowerCradle",(.12,.025,.035),(0,0,.006),polymer)
    m.finish("hose_holder.glb")


def build_manometer():
    m=Model(); steel=m.mat("Gauge bezel stainless",(.58,.64,.63),.82,.22); dark=m.mat("Gauge case",(.045,.065,.07),.35,.39); face=m.mat("Warm white ceramic dial",(.78,.77,.69),.06,.52); ink=m.mat("Dial markings",(.055,.075,.075),.04,.61); warning=m.mat("Operating band",(.75,.22,.08),.1,.48); glass=m.mat("Optical cover glass",(.72,.84,.83),.0,.10,.24); red=m.mat("Needle lacquer",(.72,.12,.08),.25,.24)
    m.cylinder("GaugeCase",.062,.032,(0,0,0),dark,axis="z",sides=64)
    m.torus("Bezel",.059,.006,(0,0,.020),steel,axis="z",n=64,m=12)
    m.cylinder("DialFace",.052,.003,(0,0,.018),face,axis="z",sides=64)
    # Scale arcs are individually modeled, with a restrained warning sector.
    for i in range(21):
        a=math.radians(220+i*7.0)
        r0=.040 if i%5 else .036; r1=.047
        p0=(r0*math.cos(a),r0*math.sin(a),.021); p1=(r1*math.cos(a),r1*math.sin(a),.021)
        m.rod(f"Tick_{i:02d}",p0,p1,.0008,warning if i>15 else ink,sides=6)
    m.torus("CoverSeal",.052,.0018,(0,0,.025),dark,axis="z",n=64,m=8)
    m.cylinder("Glass",.051,.0015,(0,0,.027),glass,axis="z",sides=64)
    needle=m.node("Needle",translation=(0,0,.031))
    # Needle points to the 11 o'clock quadrant at rest; pivot remains at dial center.
    m.rod("NeedleArm",(0,0,0),(-.025,.031,0),.0013,red,parent=needle,sides=8)
    m.cylinder("NeedleHub",.003,.002,(0,0,.001),steel,axis="z",parent=needle,sides=24)
    m.cylinder("PressureSocket",.008,.046,(0,-.075,-.006),steel,axis="y",sides=24)
    m.torus("SocketFerrule",.010,.002,(0,-.052,-.006),dark)
    m.finish("manometer.glb")


def build_lamp():
    m=Model(); steel=m.mat("Lamp arm chrome",(.48,.56,.56),.82,.22); enamel=m.mat("Lamp shade enamel",(.105,.17,.19),.72,.27); inner=m.mat("Warm reflector",(.72,.49,.26),.45,.28); bulb=m.mat("Frosted bulb",(.94,.66,.35),.06,.24,.8,(.28,.12,.035)); dark=m.mat("Clamp polymer",(.045,.061,.064),.18,.47)
    m.box("ClampJaw",(.09,.045,.085),(0,0,0),dark)
    m.cylinder("ClampScrew",.008,.075,(.055,-.006,0),steel,axis="x",sides=24)
    m.rod("LowerArm",(.025,.04,0),(.13,.19,0),.006,steel)
    m.cylinder("ElbowJoint",.019,.025,(.13,.19,0),dark,axis="z")
    m.rod("UpperArm",(.13,.19,0),(.25,.24,0),.005,steel)
    m.cylinder("ShadeNeck",.009,.060,(.265,.222,0),steel,axis="y")
    m.cylinder("ShadeBody",.061,.055,(.29,.258,0),enamel,axis="y",sides=48)
    m.torus("ShadeRim",.060,.004,(.29,.229,0),steel,axis="y")
    m.cylinder("Reflector",.051,.004,(.29,.226,0),inner,axis="y")
    m.cylinder("Bulb",.018,.018,(.29,.215,0),bulb,axis="y")
    m.finish("side_lamp.glb")


if __name__ == "__main__":
    build_pump()
    build_reservoir()
    build_stand()
    build_hose_holder()
    build_manometer()
    build_lamp()
    print(f"Wrote six meter-scale equipment models to {OUT}")
