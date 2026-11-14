#!/usr/bin/env python3
"""Deterministically build an articulated educational arm GLB (1 unit = 1 metre)."""
from pathlib import Path
import json, math, struct
import numpy as np

OUT=Path(__file__).resolve().parent/'arm_biceps.glb'

MATERIALS=[
 ("Cortical bone",(0.78,0.70,0.55,1),0.0,0.42),
 ("Articular cartilage",(0.76,0.57,0.48,1),0.0,0.31),
 ("Biceps muscle",(0.42,0.095,0.09,1),0.0,0.53),
 ("Triceps muscle",(0.32,0.07,0.075,1),0.0,0.57),
 ("Tendon",(0.86,0.73,0.58,1),0.0,0.48),
]

def ellipsoid(center,radii,lat=24,lon=32):
    p=[];ix=[]
    for i in range(lat+1):
        th=math.pi*i/lat
        for j in range(lon):
            ph=2*math.pi*j/lon
            p.append((center[0]+radii[0]*math.sin(th)*math.cos(ph),
                      center[1]+radii[1]*math.cos(th),
                      center[2]+radii[2]*math.sin(th)*math.sin(ph)))
    for i in range(lat):
        for j in range(lon):
            a=i*lon+j;b=i*lon+(j+1)%lon;c=(i+1)*lon+j;d=(i+1)*lon+(j+1)%lon
            ix.extend((a,c,b,b,c,d))
    return np.asarray(p,float),np.asarray(ix,np.uint32)

def spindle_y(center_x,center_z,y_top,y_bottom,rx,rz,segments=32,rings=32):
    p=[];ix=[]
    for i in range(rings+1):
        t=i/rings
        y=y_top+(y_bottom-y_top)*t
        bulge=max(0.0002,math.sin(math.pi*t)**0.72)
        for j in range(segments):
            a=math.tau*j/segments
            p.append((center_x+rx*bulge*math.cos(a),y,center_z+rz*bulge*math.sin(a)))
    for i in range(rings):
        for j in range(segments):
            a=i*segments+j;b=i*segments+(j+1)%segments;c=(i+1)*segments+j;d=(i+1)*segments+(j+1)%segments
            ix.extend((a,b,c,b,d,c))
    return np.asarray(p,float),np.asarray(ix,np.uint32)

def tapered_bone(a,b,r0,r1,depth_scale=1.0,sides=24):
    a=np.asarray(a,float);b=np.asarray(b,float);axis=b-a;axis/=np.linalg.norm(axis)
    ref=np.array([0.,0.,1.]) if abs(axis[2])<.88 else np.array([0.,1.,0.])
    u=np.cross(axis,ref);u/=np.linalg.norm(u);v=np.cross(axis,u)
    p=[];ix=[]
    for t,r in [(0,r0),(0.08,r0*.94),(0.42,(r0+r1)*.53),(0.90,r1*1.08),(1,r1)]:
        c=a+(b-a)*t
        for j in range(sides):
            ph=math.tau*j/sides
            p.append(c+r*(math.cos(ph)*u+depth_scale*math.sin(ph)*v))
    for k in range(4):
        for j in range(sides):
            a0=k*sides+j;b0=k*sides+(j+1)%sides;c0=(k+1)*sides+j;d0=(k+1)*sides+(j+1)%sides
            ix.extend((a0,b0,c0,b0,d0,c0))
    # cap disks
    for center_index,ring_index,reverse in [(len(p),0,True),(len(p)+1,4,False)]:
        p.append(tuple(np.asarray(a if ring_index==0 else b,float)))
        for j in range(sides):
            x=ring_index*sides+j;y=ring_index*sides+(j+1)%sides
            ix.extend((center_index,y,x) if reverse else (center_index,x,y))
    return np.asarray(p,float),np.asarray(ix,np.uint32)

def merge(parts):
    ps=[];inds=[];off=0
    for p,ix in parts:
        ps.append(p);inds.append(ix+off);off+=len(p)
    return np.vstack(ps),np.concatenate(inds)

class Builder:
    def __init__(self):
        self.nodes=[];self.meshes=[];self.materials=[];self.views=[];self.accessors=[];self.buf=bytearray()
        for name,color,metal,rough in MATERIALS:
            self.materials.append({"name":name,"pbrMetallicRoughness":{"baseColorFactor":list(color),"metallicFactor":metal,"roughnessFactor":rough}})
    def accessor(self,data,typ,component,target):
        while len(self.buf)%4:self.buf.append(0)
        off=len(self.buf);raw=data.tobytes();self.buf.extend(raw)
        vi=len(self.views);self.views.append({"buffer":0,"byteOffset":off,"byteLength":len(raw),"target":target})
        count={"VEC3":len(data),"SCALAR":len(data)}[typ]
        acc={"bufferView":vi,"componentType":component,"count":count,"type":typ}
        if typ=="VEC3":acc["min"]=data.min(axis=0).tolist();acc["max"]=data.max(axis=0).tolist()
        ai=len(self.accessors);self.accessors.append(acc);return ai
    def add_mesh(self,name,parts,mat):
        p,ix=merge(parts);p=p.astype(np.float32);ix=ix.astype(np.uint32)
        n=np.zeros_like(p)
        for tri in ix.reshape(-1,3):
            a,b,c=p[tri];nn=np.cross(b-a,c-a);n[tri]+=nn
        norm=np.linalg.norm(n,axis=1);n/=np.maximum(norm[:,None],1e-10);n=n.astype(np.float32)
        pos=self.accessor(p,"VEC3",5126,34962);nor=self.accessor(n,"VEC3",5126,34962)
        idx=self.accessor(ix,"SCALAR",5125,34963)
        mi=len(self.meshes);self.meshes.append({"name":name,"primitives":[{"attributes":{"POSITION":pos,"NORMAL":nor},"indices":idx,"material":mat,"mode":4}]})
        return mi
    def node(self,name,mesh=None,translation=(0,0,0),children=None,extras=None):
        node={"name":name,"translation":list(translation)}
        if mesh is not None:node["mesh"]=mesh
        if children:node["children"]=children
        if extras:node["extras"]=extras
        ni=len(self.nodes);self.nodes.append(node);return ni
    def write(self,path,scene_roots):
        doc={"asset":{"version":"2.0","generator":"generate_arm.py · Glitch Academy original procedural anatomy"},"scene":0,
             "scenes":[{"nodes":scene_roots}],"nodes":self.nodes,"meshes":self.meshes,"materials":self.materials,
             "buffers":[{"byteLength":len(self.buf)}],"bufferViews":self.views,"accessors":self.accessors}
        js=json.dumps(doc,separators=(",",":")).encode();js+=b" "*((-len(js))%4)
        bb=bytes(self.buf)+b"\0"*((-len(self.buf))%4);total=12+8+len(js)+8+len(bb)
        with path.open("wb") as f:
            f.write(struct.pack("<4sII",b"glTF",2,total));f.write(struct.pack("<I4s",len(js),b"JSON"));f.write(js);f.write(struct.pack("<I4s",len(bb),b"BIN\0"));f.write(bb)

def build():
    g=Builder()
    # Bone chain: shoulder at y=.335m, elbow at origin; +Z faces the anatomy view.
    hum_p,hum_i=merge([
        tapered_bone((0,.035,0),(0,.305,0),.019,.013,1.0),
        # Compact humeral head landmark; keep the joint from reading as a shoulder ball.
        ellipsoid((0,.315,0),(.026,.025,.026)),
        ellipsoid((0,.025,0),(.028,.031,.026)),
    ])
    hum=g.add_mesh("HumerusMesh",[(hum_p,hum_i)],0)
    hum_node=g.node("Humerus",hum,extras={"unit":"m","landmarks":"shoulder to elbow"})
    # Deltoid insertion and two separate, independently scalable muscle bellies.
    # Keep the flexor on the anterior plane so the posterior extensor does not
    # appear as a second arm-width spindle in the flexion composition.
    bp,bi=spindle_y(.016,.057,.304,.045,.038,.030)
    biceps=g.add_mesh("BicepsMesh",[(bp,bi)],2)
    bi_node=g.node("Biceps",biceps,translation=(0,0,0),extras={"pivot":"proximal origin near shoulder","scale_axis":"Y","action":"shortening flexes the elbow"})
    # The triceps long head sits posterior to the shaft and slightly medial.
    tp,ti=spindle_y(-.004,-.060,.302,.035,.036,.025)
    tri=g.add_mesh("TricepsMesh",[(tp,ti)],3)
    tri_node=g.node("Triceps",tri,extras={"pivot":"proximal origin near shoulder","scale_axis":"Y","action":"shortening extends the elbow"})
    # Tendons follow the front and back contours from the muscle bellies to insertions.
    bt_parts=[tapered_bone((.026,.052,.047),(.036,.005,.055),.0038,.0022,0.8)]
    tt_parts=[tapered_bone((-.027,.043,-.046),(-.008,.005,-.025),.0035,.0022,0.8)]
    bt=g.add_mesh("BicepsTendonMesh",bt_parts,4);tn1=g.node("Tendon_Biceps",bt,extras={"role":"biceps distal tendon"})
    tt=g.add_mesh("TricepsTendonMesh",tt_parts,4);tn2=g.node("Tendon_Triceps",tt,extras={"role":"triceps insertion on olecranon"})
    # Elbow pivot and forearm bones are children, so rotation carries both as a unit.
    radius_parts=merge([
        ellipsoid((.025,-.012,.006),(.014,.018,.014)),
        tapered_bone((.025,-.012,.006),(.268,-.043,.012),.012,.007,0.82),
        ellipsoid((.272,-.043,.012),(.012,.019,.011)),
    ])
    radius_mesh=g.add_mesh("RadiusMesh",[(radius_parts[0],radius_parts[1])],0)
    radius_node=g.node("Radius",radius_mesh,extras={"unit":"m","pivot":"Elbow"})
    ulna_parts=merge([
        ellipsoid((-.016,-.012,-.006),(.016,.022,.015)),
        tapered_bone((-.016,-.010,-.006),(.249,-.055,-.009),.012,.007,0.85),
        ellipsoid((.251,-.055,-.009),(.010,.017,.009)),
    ])
    ulna_mesh=g.add_mesh("UlnaMesh",[(ulna_parts[0],ulna_parts[1])],0)
    ulna_node=g.node("Ulna",ulna_mesh,extras={"unit":"m","pivot":"Elbow"})
    # Flexor/extensor tendons continue into the wrist as separate named parts.
    flexor=g.add_mesh("ForearmTendonMesh",[tapered_bone((.03,-.01,.025),(.24,-.04,.019),.0035,.0018,.7)],4)
    flexor_node=g.node("Tendon_Flexor",flexor,extras={"pivot":"Elbow"})
    extensor=g.add_mesh("ExtensorTendonMesh",[tapered_bone((-.02,-.01,-.023),(.24,-.05,-.017),.003,.0016,.7)],4)
    extensor_node=g.node("Tendon_Extensor",extensor,extras={"pivot":"Elbow"})
    elbow=g.node("Elbow",None,translation=(0,0,0),children=[radius_node,ulna_node,flexor_node,extensor_node],extras={"pivot_origin_m":[0,0,0],"hinge_axis":"Z","extension_deg":-8,"flexion_direction":"positive rotation around +Z lifts forearm"})
    root=g.node("ArmBiceps",children=[hum_node,bi_node,tri_node,tn1,tn2,elbow],extras={"units":"metres","orientation":"+Y up, +Z anterior","neutral_elbow_deg":-8,"source":"original deterministic procedural anatomy"})
    g.write(OUT,[root])

if __name__=="__main__":
    OUT.parent.mkdir(parents=True,exist_ok=True);build()
