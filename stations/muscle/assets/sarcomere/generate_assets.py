#!/usr/bin/env python3
"""Deterministically generate the Section C sarcomere GLBs (Python stdlib only)."""
import json
import math
import struct
from pathlib import Path

OUT = Path(__file__).resolve().parent
TAU = math.tau

class GLB:
    def __init__(self):
        self.nodes, self.meshes, self.materials = [], [], []
        self.views, self.accessors, self.buffer = [], [], bytearray()
        self.material_ids = {}
        self.animations = []
        self.extras = {"units": "micrometre", "meters_per_unit": 1e-6, "axis": "X is the filament/sarcomere long axis"}

    def material(self, name, color, metallic=0.0, roughness=0.45):
        key = (name, tuple(color), metallic, roughness)
        if key in self.material_ids:
            return self.material_ids[key]
        self.material_ids[key] = len(self.materials)
        self.materials.append({"name": name, "pbrMetallicRoughness": {
            "baseColorFactor": list(color), "metallicFactor": metallic, "roughnessFactor": roughness
        }})
        return self.material_ids[key]

    def accessor(self, data, component_type, kind, count, target=None, bounds=None):
        self.buffer.extend(b"\0" * (-len(self.buffer) % 4))
        offset = len(self.buffer)
        self.buffer.extend(data)
        view = {"buffer": 0, "byteOffset": offset, "byteLength": len(data)}
        if target is not None:
            view["target"] = target
        self.views.append(view)
        acc = {"bufferView": len(self.views) - 1, "componentType": component_type, "count": count, "type": kind}
        if bounds:
            acc.update(min=bounds[0], max=bounds[1])
        self.accessors.append(acc)
        return len(self.accessors) - 1

    @staticmethod
    def normals(vertices, faces):
        n = [[0.0, 0.0, 0.0] for _ in vertices]
        for a, b, c in faces:
            p, q, r = vertices[a], vertices[b], vertices[c]
            u = [q[i] - p[i] for i in range(3)]
            v = [r[i] - p[i] for i in range(3)]
            cross = [u[1]*v[2]-u[2]*v[1], u[2]*v[0]-u[0]*v[2], u[0]*v[1]-u[1]*v[0]]
            for j in (a, b, c):
                for i in range(3):
                    n[j][i] += cross[i]
        for v in n:
            length = math.sqrt(sum(x*x for x in v)) or 1.0
            for i in range(3):
                v[i] /= length
        return n

    def mesh(self, name, vertices, faces, material):
        normals = self.normals(vertices, faces)
        pbytes = struct.pack("<%sf" % (3*len(vertices)), *(x for v in vertices for x in v))
        nbytes = struct.pack("<%sf" % (3*len(normals)), *(x for v in normals for x in v))
        pa = self.accessor(pbytes, 5126, "VEC3", len(vertices), 34962,
                           ([min(v[i] for v in vertices) for i in range(3)], [max(v[i] for v in vertices) for i in range(3)]))
        na = self.accessor(nbytes, 5126, "VEC3", len(normals), 34962)
        indices = [i for f in faces for i in f]
        ct, fmt = (5123, "H") if len(vertices) < 65536 else (5125, "I")
        ia = self.accessor(struct.pack("<%s%s" % (len(indices), fmt), *indices), ct, "SCALAR", len(indices), 34963)
        self.meshes.append({"name": name, "primitives": [{"attributes": {"POSITION": pa, "NORMAL": na}, "indices": ia, "material": material}]})
        return len(self.meshes) - 1

    def node(self, name, mesh=None, parent=None, translation=(0,0,0), rotation=(0,0,0,1), scale=(1,1,1), extras=None):
        item = {"name": name, "translation": list(translation), "rotation": list(rotation), "scale": list(scale)}
        if mesh is not None:
            item["mesh"] = mesh
        if extras:
            item["extras"] = extras
        self.nodes.append((item, parent))
        return len(self.nodes) - 1

    def animation(self, name, tracks):
        """tracks: (node index, [quat at t=0, quat at t=1])"""
        time_acc = self.accessor(struct.pack("<2f", 0.0, 1.0), 5126, "SCALAR", 2, bounds=([0.0], [1.0]))
        samplers, channels = [], []
        for node_index, rotations in tracks:
            out = self.accessor(struct.pack("<8f", *(x for q in rotations for x in q)), 5126, "VEC4", 2)
            samplers.append({"input": time_acc, "output": out, "interpolation": "LINEAR"})
            channels.append({"sampler": len(samplers)-1, "target": {"node": node_index, "path": "rotation"}})
        self.animations.append({"name": name, "samplers": samplers, "channels": channels})

    def export(self, path, scene_name):
        children, roots = [[] for _ in self.nodes], []
        for i, (_, parent) in enumerate(self.nodes):
            (roots if parent is None else children[parent]).append(i)
        nodes = []
        for i, (node, _) in enumerate(self.nodes):
            if children[i]:
                node["children"] = children[i]
            nodes.append(node)
        doc = {"asset": {"version": "2.0", "generator": "generate_assets.py"}, "scene": 0,
               "scenes": [{"name": scene_name, "nodes": roots, "extras": self.extras}],
               "nodes": nodes, "meshes": self.meshes, "materials": self.materials,
               "buffers": [{"byteLength": len(self.buffer)}], "bufferViews": self.views, "accessors": self.accessors}
        if self.animations:
            doc["animations"] = self.animations
        raw = json.dumps(doc, separators=(",", ":")).encode("utf-8")
        raw += b" " * (-len(raw) % 4)
        binary = bytes(self.buffer) + b"\0" * (-len(self.buffer) % 4)
        total = 12 + 8 + len(raw) + 8 + len(binary)
        with open(path, "wb") as f:
            f.write(struct.pack("<4sII", b"glTF", 2, total))
            f.write(struct.pack("<I4s", len(raw), b"JSON")); f.write(raw)
            f.write(struct.pack("<I4s", len(binary), b"BIN\0")); f.write(binary)


def vec_add(a,b): return tuple(a[i]+b[i] for i in range(3))
def vec_sub(a,b): return tuple(a[i]-b[i] for i in range(3))
def vec_mul(a,s): return tuple(x*s for x in a)
def dot(a,b): return sum(a[i]*b[i] for i in range(3))
def cross(a,b): return (a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0])
def unit(v):
    n=math.sqrt(dot(v,v)) or 1.0
    return tuple(x/n for x in v)
def q_axis(axis,angle):
    a=unit(axis); s=math.sin(angle/2)
    return (a[0]*s,a[1]*s,a[2]*s,math.cos(angle/2))
def q_mul(a,b):
    x1,y1,z1,w1=a; x2,y2,z2,w2=b
    return (w1*x2+x1*w2+y1*z2-z1*y2, w1*y2-x1*z2+y1*w2+z1*x2, w1*z2+x1*y2-y1*x2+z1*w2, w1*w2-x1*x2-y1*y2-z1*z2)
def q_basis(xaxis,yaxis,zaxis):
    # Matrix columns are local axes in world coordinates.
    m00,m01,m02=xaxis[0],yaxis[0],zaxis[0]; m10,m11,m12=xaxis[1],yaxis[1],zaxis[1]; m20,m21,m22=xaxis[2],yaxis[2],zaxis[2]
    tr=m00+m11+m22
    if tr>0:
        s=math.sqrt(tr+1.0)*2; return ((m21-m12)/s,(m02-m20)/s,(m10-m01)/s,.25*s)
    if m00>m11 and m00>m22:
        s=math.sqrt(1+m00-m11-m22)*2; return (.25*s,(m01+m10)/s,(m02+m20)/s,(m21-m12)/s)
    if m11>m22:
        s=math.sqrt(1+m11-m00-m22)*2; return ((m01+m10)/s,.25*s,(m12+m21)/s,(m02-m20)/s)
    s=math.sqrt(1+m22-m00-m11)*2; return ((m02+m20)/s,(m12+m21)/s,.25*s,(m10-m01)/s)


def box(g, name, dims, material, parent=None, pos=(0,0,0)):
    x,y,z=(v/2 for v in dims)
    v=[(-x,-y,-z),(x,-y,-z),(x,y,-z),(-x,y,-z),(-x,-y,z),(x,-y,z),(x,y,z),(-x,y,z)]
    f=[(0,2,1),(0,3,2),(4,5,6),(4,6,7),(0,1,5),(0,5,4),(1,2,6),(1,6,5),(2,3,7),(2,7,6),(3,0,4),(3,4,7)]
    return g.node(name, g.mesh(name+" mesh",v,f,material),parent,pos)


def sphere(g,name,radii,material,parent=None,pos=(0,0,0),rings=10,sectors=16):
    rx,ry,rz=radii; v=[(0,-ry,0)]
    for j in range(1,rings):
        p=-math.pi/2+math.pi*j/rings
        for i in range(sectors):
            a=2*math.pi*i/sectors
            v.append((rx*math.cos(p)*math.cos(a),ry*math.sin(p),rz*math.cos(p)*math.sin(a)))
    top=len(v);v.append((0,ry,0));f=[]
    for i in range(sectors): f.append((0,1+(i+1)%sectors,1+i))
    for j in range(rings-2):
        a=1+j*sectors;b=a+sectors
        for i in range(sectors):
            k=(i+1)%sectors;f.extend([(a+i,a+k,b+i),(a+k,b+k,b+i)])
    for i in range(sectors): f.append((1+(rings-2)*sectors+i,1+(rings-2)*sectors+(i+1)%sectors,top))
    return g.node(name,g.mesh(name+" mesh",v,f,material),parent,pos)


def cylinder_x(g,name,r,length,material,parent=None,pos=(0,0,0),r2=None,sectors=20):
    r2=r if r2 is None else r2
    v=[]
    for x,rr in [(-length/2,r),(length/2,r2)]:
        for i in range(sectors):
            a=2*math.pi*i/sectors;v.append((x,rr*math.cos(a),rr*math.sin(a)))
    f=[]
    for i in range(sectors):
        j=(i+1)%sectors;f.extend([(i,j,sectors+j),(i,sectors+j,sectors+i)])
    f.extend([(0,i+1,i) for i in range(1,sectors-1)])
    f.extend([(sectors,sectors+i,sectors+i+1) for i in range(1,sectors-1)])
    return g.node(name,g.mesh(name+" mesh",v,f,material),parent,pos)


def tube(g,name,points,radius,material,parent=None,sides=8,closed=False):
    pts=[tuple(p) for p in points];v=[];faces=[]
    for i,p in enumerate(pts):
        tangent=unit(vec_sub(pts[min(i+1,len(pts)-1)],pts[max(i-1,0)]))
        ref=(1,0,0) if abs(tangent[0])<.85 else (0,1,0)
        u=unit(cross(tangent,ref));w=unit(cross(tangent,u))
        for j in range(sides):
            a=2*math.pi*j/sides
            v.append(vec_add(p,vec_mul(vec_add(vec_mul(u,math.cos(a)),vec_mul(w,math.sin(a))),radius)))
    segs=len(pts) if closed else len(pts)-1
    for i in range(segs):
        ni=(i+1)%len(pts)
        for j in range(sides):
            nj=(j+1)%sides
            faces.extend([(i*sides+j,ni*sides+j,i*sides+nj),(i*sides+nj,ni*sides+j,ni*sides+nj)])
    return g.node(name,g.mesh(name+" mesh",v,faces,material),parent)


def rod(g,name,start,end,radius,material,parent=None):
    d=vec_sub(end,start); length=math.sqrt(dot(d,d)); mid=vec_mul(vec_add(start,end),.5)
    # Cylinder is authored on X. Rotate its axis onto the requested vector.
    axis=unit(d); base=(1,0,0); cr=cross(base,axis); mag=math.sqrt(dot(cr,cr))
    q=(0,0,0,1) if mag<1e-8 else q_axis(cr,math.acos(max(-1,min(1,dot(base,axis)))))
    # use generic cylinder along x with an explicit rotation
    mesh=cylinder_x(g,name,radius,length,material,parent,mid)
    g.nodes[mesh][0]["rotation"]=list(q)
    return mesh


# Shared biology palette, keyed to ART_DIRECTION.md and the muscle station.

def mats(g):
    return {
        "myosin":g.material("Myosin · warm amber",(0.79,0.34,0.19,1),.12,.34),
        "myosin_light":g.material("Myosin head · pale amber",(0.95,0.60,0.31,1),.10,.30),
        "actin":g.material("Actin · cool cyan",(0.18,0.62,0.68,1),.08,.32),
        "actin_light":g.material("Actin subunit · pale cyan",(0.36,0.80,0.80,1),.04,.38),
        "tropomyosin":g.material("Tropomyosin · deep teal",(0.10,0.34,0.41,1),.18,.30),
        "troponin":g.material("Troponin complex · connective ivory",(0.78,0.70,0.57,1),.04,.40),
        "disc":g.material("Z-disc · graphite protein lattice",(0.22,0.28,0.31,1),.26,.40),
        "disc_edge":g.material("Z-disc edge · pale steel",(0.48,0.58,0.58,1),.38,.30),
        "mline":g.material("M-line · warm structural protein",(0.70,0.47,0.28,1),.20,.34),
        "titin":g.material("Titin · elastic violet",(0.42,0.34,0.56,1),.04,.38),
        "ca":g.material("Calcium ion · white",(0.92,0.96,0.94,1),.06,.22),
        "atp":g.material("ATP · repair green",(0.29,0.78,0.59,1),.04,.30),
        "atp_dark":g.material("ATP phosphate · deep green",(0.12,0.45,0.37,1),.08,.34),
    }


def build_thick():
    g=GLB();m=mats(g);root=g.node("ThickFilament",extras={"unit":"µm","length_um":1.6,"diameter_visual_exaggeration":"about 3x"})
    cylinder_x(g,"Tail",.026,1.6,m["myosin"],root)
    # Sparse paired coiled-coil grooves describe the myosin rod without turning it into decoration.
    for strand,phase in [("TailStrand_A",0),("TailStrand_B",math.pi)]:
        pts=[]
        for i in range(49):
            x=-.76+1.52*i/48;a=phase+TAU*i/48*8
            pts.append((x,.026*math.cos(a),.026*math.sin(a)))
        tube(g,strand,pts,.0025,m["myosin_light"],root,6)
    open_tracks=[];tense_tracks=[];index=1
    # Two bipolar head arrays; the 0.16 µm central bare zone has no heads.
    for side in (-1,1):
        for xmag in (.14,.56):
            for crown in range(3):
                ang=2*math.pi*crown/3 + (0.22 if xmag>.3 else 0.0)
                radial=(0,math.cos(ang),math.sin(ang))
                lean=(float(side),0,0)
                tangent=unit(cross(lean,radial))
                basis=q_basis(lean,radial,tangent)
                pivot_q=basis
                pivot=g.node(f"Head_{index:02d}",parent=root,translation=(side*xmag,radial[1]*.026,radial[2]*.026),rotation=pivot_q,
                             extras={"pivot":"hinge at the myosin neck; animate rotation around local Z","side":"toward adjacent Z disc"})
                rod(g,"LeverArm",(0,.0,0),(0,.039,0),.006,m["myosin_light"],pivot)
                sphere(g,"MotorDomain",(.022,.026,.018),m["myosin_light"],pivot,(0,.055,0),8,12)
                # A restrained cleft line helps distinguish the motor domain at close range.
                box(g,"ActinBindingCleft",(.009,.008,.018),m["myosin"],pivot,(.013,.061,0))
                q_open=q_mul(pivot_q,q_axis((0,0,1),math.radians(-18)))
                q_tense=q_mul(pivot_q,q_axis((0,0,1),math.radians(48)))
                open_tracks.append((pivot,[q_open,q_open]));tense_tracks.append((pivot,[q_tense,q_tense]))
                index+=1
    assert index==13
    g.animation("Heads_Open",open_tracks);g.animation("Heads_Tense",tense_tracks)
    return g


def build_thin():
    g=GLB();m=mats(g);root=g.node("ThinFilament",extras={"unit":"µm","length_um":1.0,"actin_chains":2,"diameter_visual_exaggeration":"about 3x"})
    actin=g.node("Actin",parent=root)
    # Two staggered protofilaments form a right-handed F-actin-like double helix.
    for strand,phase in [("ActinChain_A",0),("ActinChain_B",math.pi)]:
        chain=g.node(strand,parent=actin)
        for i in range(25):
            x=-.48+.96*i/24
            angle=phase+2*math.pi*i/13.0
            y=.0025*math.cos(angle);z=.0025*math.sin(angle)
            sphere(g,f"ActinSubunit_{i+1:02d}",(.009,.009,.009),m["actin_light"] if i%3 else m["actin"],chain,(x,y,z),8,12)
    # A subtly twisted backbone links globular actin units but keeps each strand readable.
    for strand,phase in [("ActinBackbone_A",0),("ActinBackbone_B",math.pi)]:
        pts=[]
        for i in range(61):
            x=-.5+i/60;angle=phase+2*math.pi*(x+.5)/.52
            pts.append((x,.0025*math.cos(angle),.0025*math.sin(angle)))
        tube(g,strand,pts,.003,m["actin"],actin,8)
    # Tropomyosin follows the long groove; rotation about X shifts it from blocking to permissive.
    tm=g.node("Tropomyosin",parent=root,rotation=q_axis((1,0,0),math.radians(24)),extras={"closed_degrees_about_X":24,"open_degrees_about_X":-8})
    tm_pts=[]
    for i in range(101):
        x=-.5+i/100;angle=2*math.pi*(x+.5)/.40
        tm_pts.append((x,.017*math.cos(angle),.017*math.sin(angle)))
    tube(g,"TropomyosinStrand",tm_pts,.0035,m["tropomyosin"],tm,8)
    troponin=g.node("Troponin",parent=root)
    for i,x in enumerate((-.32,0,.32),1):
        unit_node=g.node(f"Troponin_{i:02d}",parent=troponin,translation=(x,0,0))
        sphere(g,"TnC_CalciumBindingLobe",(.018,.016,.015),m["troponin"],unit_node,(0,.028,.018),8,12)
        sphere(g,"TnI_ActinBindingLobe",(.015,.012,.012),m["tropomyosin"],unit_node,(0,.020,-.008),8,12)
        rod(g,"TnT_TropomyosinLink",(0,.025,0),(0,.030,.025),.004,m["troponin"],unit_node)
    closed=q_axis((1,0,0),math.radians(24));opened=q_axis((1,0,0),math.radians(-8))
    g.animation("Tropomyosin_Closed",[(tm,[closed,closed])])
    g.animation("Tropomyosin_Open",[(tm,[opened,opened])])
    return g


def build_z_disc():
    g=GLB();m=mats(g);root=g.node("ZDisc",extras={"unit":"µm","thickness_um":0.045,"diameter_um":0.58})
    # A perforated alpha-actinin-like crosslink plate, not a solid wall across the actin entry points.
    box(g,"ZDisc_CenterWeb",(.045,.22,.22),m["disc"],root)
    for radius in (.11,.22,.29):
        for i in range(12):
            a=2*math.pi*i/12
            y=radius*math.cos(a);z=radius*math.sin(a)
            # small criss-cross ties in the plane of the Z disc
            rod(g,f"ZLink_{radius:.2f}_{i:02d}",(-.012,y,z),(.012,y+.018*math.cos(a+.8),z+.018*math.sin(a+.8)),.004,m["disc_edge"],root)
    for i in range(12):
        a=2*math.pi*i/12;y=.24*math.cos(a);z=.24*math.sin(a)
        sphere(g,f"ActinAnchor_{i+1:02d}",(.014,.012,.012),m["actin"],root,(-.025,y,z),6,10)
    return g


def build_m_line():
    g=GLB();m=mats(g);root=g.node("MLine",extras={"unit":"µm","centerline_thickness_um":0.06})
    box(g,"MLine_Core",(.06,.20,.20),m["mline"],root)
    for y in (-.09,0,.09):
        rod(g,"MLine_Bridge",(-.025,y,-.09),(.025,y,.09),.008,m["disc_edge"],root)
        rod(g,"MLine_Bridge",(-.025,y,.09),(.025,y,-.09),.008,m["disc_edge"],root)
    return g


def build_titin():
    g=GLB();m=mats(g);root=g.node("Titin",extras={"unit":"µm","rest_length_um":0.30,"stretch_axis":"X","scale_range_recommended":[0.75,1.45]})
    g.node("ZAttachment",parent=root,translation=(0,0,0))
    pts=[]
    for i in range(121):
        t=i/120;x=.30*t;angle=2*math.pi*7*t
        r=.021*(.8+.2*math.sin(math.pi*t))
        pts.append((x,r*math.cos(angle),r*math.sin(angle)))
    tube(g,"Titin_ElasticCoil",pts,.0055,m["titin"],root,8)
    sphere(g,"ThickFilamentAttachment",(.018,.016,.016),m["titin"],root,(.30,0,0),8,12)
    return g


def build_calcium():
    g=GLB();m=mats(g);root=g.node("CaIon",extras={"ion":"Ca2+","unit":"µm","visual_diameter_um":0.045})
    sphere(g,"CalciumCore",(.0225,.0225,.0225),m["ca"],root,rings=12,sectors=20)
    sphere(g,"CalciumSoftHighlight",(.007,.007,.007),m["actin_light"],root,(.010,.011,.011),8,12)
    return g


def build_atp():
    g=GLB();m=mats(g);root=g.node("ATP",extras={"molecule":"adenosine triphosphate","unit":"µm","visual_scale":"schematic molecular detail, not atomically scaled"})
    # Three connected phosphates, ribose, and a fused adenine ring; no letter glyphs.
    phosphate=[(.055,0,0),(.095,.018,0),(.135,0,0)]
    for i,p in enumerate(phosphate,1):
        sphere(g,f"Phosphate_{i}",(.020,.018,.018),m["atp"],root,p,8,12)
    for i in range(2):rod(g,f"PhosphateBridge_{i+1}",phosphate[i],phosphate[i+1],.006,m["atp_dark"],root)
    sphere(g,"Ribose",(.023,.021,.020),m["atp_dark"],root,(.018,0,0),8,12)
    # Purine is a fused two-ring silhouette made of bonded green beads.
    purine=[(-.032,0,0),(-.052,.018,0),(-.073,0,.006),(-.052,-.018,0),(-.032,0,.026),(-.085,.018,.026),(-.106,0,.026),(-.085,-.018,.026)]
    for i,p in enumerate(purine,1):
        sphere(g,f"AdenineNode_{i:02d}",(.012,.010,.010),m["atp"],root,p,6,10)
    for a,b in [(0,1),(1,2),(2,3),(3,0),(0,4),(4,5),(5,6),(6,7),(7,4)]:
        rod(g,"AdenineBond",purine[a],purine[b],.0035,m["atp_dark"],root)
    rod(g,"Ribose_Adenine",(-.005,0,0),(-.024,0,.008),.005,m["atp_dark"],root)
    return g


def read_mesh(src, mesh_index):
    mesh=src.meshes[mesh_index]; prim=mesh["primitives"][0]
    pa=src.accessors[prim["attributes"]["POSITION"]]; bv=src.views[pa["bufferView"]]; off=bv.get("byteOffset",0)
    values=struct.unpack("<%sf"%(pa["count"]*3),bytes(src.buffer[off:off+bv["byteLength"]]))
    verts=[tuple(values[i:i+3]) for i in range(0,len(values),3)]
    ia=src.accessors[prim["indices"]]; ibv=src.views[ia["bufferView"]]; io=ibv.get("byteOffset",0)
    fmt="H" if ia["componentType"]==5123 else "I"
    indices=struct.unpack("<%s%s"%(ia["count"],fmt),bytes(src.buffer[io:io+ibv["byteLength"]]))
    faces=[tuple(indices[i:i+3]) for i in range(0,len(indices),3)]
    mat=src.materials[prim["material"]]
    return mesh["name"],verts,faces,mat


def merge_model(src,dst,parent,root_translation=(0,0,0),root_rotation=(0,0,0,1),suffix=""):
    mapping={}
    for old_index,(nd,par) in enumerate(src.nodes):
        if par is None:
            p=parent;t=root_translation;r=root_rotation
        else:
            p=mapping[par];t=tuple(nd.get("translation",(0,0,0)));r=tuple(nd.get("rotation",(0,0,0,1)))
        mesh=None
        if "mesh" in nd:
            name,verts,faces,material=read_mesh(src,nd["mesh"])
            pm=material["pbrMetallicRoughness"]
            col=pm["baseColorFactor"]
            mesh=dst.mesh(name,verts,faces,dst.material(material["name"],col,pm.get("metallicFactor",0),pm.get("roughnessFactor",.45)))
        mapping[old_index]=dst.node(nd["name"]+suffix,mesh,p,t,r,tuple(nd.get("scale",(1,1,1))),nd.get("extras"))
    for anim in src.animations:
        tracks=[]
        for ch in anim["channels"]:
            sampler=anim["samplers"][ch["sampler"]];acc=src.accessors[sampler["output"]];bv=src.views[acc["bufferView"]];off=bv.get("byteOffset",0)
            vals=struct.unpack("<8f",bytes(src.buffer[off:off+bv["byteLength"]]))
            tracks.append((mapping[ch["target"]["node"]],[tuple(vals[:4]),tuple(vals[4:])]))
        dst.animation(anim["name"]+suffix,tracks)


def add_z_disc(g,parent,name):
    m=mats(g);node=g.node(name,parent=parent)
    box(g,"ZDisc_Web",(.045,.22,.22),m["disc"],node)
    for radius in (.11,.22,.29):
        for i in range(12):
            a=2*math.pi*i/12;y=radius*math.cos(a);z=radius*math.sin(a)
            rod(g,"ZDisc_Crosslink",(-.012,y,z),(.012,y+.018*math.cos(a+.8),z+.018*math.sin(a+.8)),.004,m["disc_edge"],node)
    for i in range(12):
        a=2*math.pi*i/12
        sphere(g,f"ActinAnchor_{i+1:02d}",(.014,.012,.012),m["actin"],node,(-.025,.24*math.cos(a),.24*math.sin(a)),6,10)
    return node


def add_m_line(g,parent,name="MLine"):
    m=mats(g);node=g.node(name,parent=parent)
    box(g,"MLine_Core",(.06,.20,.20),m["mline"],node)
    for y in (-.09,0,.09):
        rod(g,"MLine_Bridge",(-.025,y,-.09),(.025,y,.09),.008,m["disc_edge"],node)
        rod(g,"MLine_Bridge",(-.025,y,.09),(.025,y,-.09),.008,m["disc_edge"],node)
    return node


def build_sarcomere():
    g=GLB();root=g.node("Sarcomere",extras={"unit":"µm","rest_length_um":2.2,"thick_filament_length_um":1.6,"thin_filament_length_um":1.0,"diameters":"schematic exaggerated about 3x; axial lengths preserve micrometre scale"})
    zleft=add_z_disc(g,root,"ZDisc_Left");g.nodes[zleft][0]["translation"]=[-1.1,0,0]
    zright=add_z_disc(g,root,"ZDisc_Right");g.nodes[zright][0]["translation"]=[1.1,0,0]
    merge_model(build_thick(),g,root)
    for side,suffix in [(-1,"_Left"),(1,"_Right")]:
        rootn=g.node("ThinSegment"+suffix,parent=root,translation=(side*.6,.082,0),rotation=q_axis((0,1,0),math.pi if side>0 else 0))
        merge_model(build_thin(),g,rootn,suffix=suffix)
    for side,suffix in [(-1,"_Left"),(1,"_Right")]:
        wrapper=g.node("TitinSegment"+suffix,parent=root,translation=(side*1.1,0,.10),rotation=q_axis((0,1,0),math.pi if side>0 else 0))
        merge_model(build_titin(),g,wrapper,suffix=suffix)
    add_m_line(g,root)
    return g


def generate():
    OUT.mkdir(parents=True,exist_ok=True)
    build_sarcomere().export(OUT/"sarcomere.glb","Sarcomere · Z disc to Z disc")
    build_thick().export(OUT/"thick_filament.glb","Myosin thick filament")
    build_thin().export(OUT/"thin_filament.glb","Actin thin filament")
    build_z_disc().export(OUT/"z_disc.glb","Z disc")
    build_m_line().export(OUT/"m_line.glb","M line")
    build_titin().export(OUT/"titin.glb","Titin elastic segment")
    build_calcium().export(OUT/"ca_ion.glb","Calcium ion · Ca2+")
    build_atp().export(OUT/"atp.glb","ATP molecule")
    print("Wrote 8 deterministic sarcomere GLBs")

if __name__ == "__main__":
    generate()
