#!/usr/bin/env python3
"""Deterministic, hand-authored GLB models for the muscle zoom hierarchy."""
from __future__ import annotations
import json, math, struct
from pathlib import Path

OUT = Path(__file__).resolve().parent

class GLB:
    def __init__(self):
        self.nodes=[]; self.parents=[]; self.meshes=[]; self.materials=[]
        self.views=[]; self.accessors=[]; self.binary=bytearray(); self.material_ids={}

    def material(self,name,color,roughness=.55,metallic=0.0,alpha=1.0):
        key=(name,tuple(color),roughness,metallic,alpha)
        if key in self.material_ids: return self.material_ids[key]
        pbr={'baseColorFactor':list(color),'metallicFactor':metallic,'roughnessFactor':roughness}
        m={'name':name,'pbrMetallicRoughness':pbr}
        if alpha < 1.0: m.update(alphaMode='BLEND',doubleSided=True)
        self.material_ids[key]=len(self.materials); self.materials.append(m)
        return self.material_ids[key]

    def _accessor(self,data,component,kind,count,target=None,minimum=None,maximum=None):
        self.binary.extend(b'\0' * ((-len(self.binary)) % 4))
        offset=len(self.binary); self.binary.extend(data)
        view={'buffer':0,'byteOffset':offset,'byteLength':len(data)}
        if target is not None: view['target']=target
        self.views.append(view)
        accessor={'bufferView':len(self.views)-1,'componentType':component,'count':count,'type':kind}
        if minimum is not None: accessor.update(min=minimum,max=maximum)
        self.accessors.append(accessor)
        return len(self.accessors)-1

    def mesh(self,name,vertices,faces,material,translation=(0,0,0),parent=None,extras=None):
        v=vertices
        # Keep authored polygon caps readable in the primitive helpers, then
        # triangulate them as a deterministic fan for glTF.
        faces=[tri if len(tri)==3 else tuple((tri[0],tri[i],tri[i+1]) for i in range(1,len(tri)-1)) for tri in faces]
        faces=[part for face in faces for part in (face if isinstance(face[0],tuple) else (face,))]
        n=[[0.0,0.0,0.0] for _ in v]
        for tri in faces:
            a,b,c=[v[i] for i in tri]
            u=[b[j]-a[j] for j in range(3)]; w=[c[j]-a[j] for j in range(3)]
            q=[u[1]*w[2]-u[2]*w[1],u[2]*w[0]-u[0]*w[2],u[0]*w[1]-u[1]*w[0]]
            for i in tri:
                for j in range(3): n[i][j]+=q[j]
        for q in n:
            length=math.sqrt(sum(x*x for x in q)) or 1.0
            for j in range(3): q[j]/=length
        pbytes=struct.pack('<%sf'%(3*len(v)),*(x for p in v for x in p))
        nbytes=struct.pack('<%sf'%(3*len(v)),*(x for p in n for x in p))
        pa=self._accessor(pbytes,5126,'VEC3',len(v),34962,
                          [min(p[i] for p in v) for i in range(3)],
                          [max(p[i] for p in v) for i in range(3)])
        na=self._accessor(nbytes,5126,'VEC3',len(n),34962)
        indices=[i for tri in faces for i in tri]
        ctype=5123 if len(v)<65536 else 5125
        ibytes=struct.pack('<%s%s'%(len(indices),'H' if ctype==5123 else 'I'),*indices)
        ia=self._accessor(ibytes,ctype,'SCALAR',len(indices),34963)
        self.meshes.append({'name':name,'primitives':[{'attributes':{'POSITION':pa,'NORMAL':na},'indices':ia,'material':material,'mode':4}]})
        node={'name':name,'mesh':len(self.meshes)-1,'translation':list(translation)}
        if extras: node['extras']=extras
        self.nodes.append(node); self.parents.append(parent)
        return len(self.nodes)-1

    def empty(self,name,translation=(0,0,0),parent=None,extras=None):
        node={'name':name,'translation':list(translation)}
        if extras: node['extras']=extras
        self.nodes.append(node); self.parents.append(parent)
        return len(self.nodes)-1

    def export(self,path,scene_name):
        children=[[] for _ in self.nodes]; roots=[]
        for i,parent in enumerate(self.parents):
            (roots if parent is None else children[parent]).append(i)
        nodes=[]
        for i,node in enumerate(self.nodes):
            if children[i]: node['children']=children[i]
            nodes.append(node)
        document={'asset':{'version':'2.0','generator':'generate_structure.py · original procedural anatomy'},
                  'scene':0,'scenes':[{'name':scene_name,'nodes':roots}],
                  'nodes':nodes,'meshes':self.meshes,'materials':self.materials,
                  'buffers':[{'byteLength':len(self.binary)}],'bufferViews':self.views,'accessors':self.accessors}
        js=json.dumps(document,separators=(',',':')).encode('utf8'); js+=b' '*((-len(js))%4)
        binary=bytes(self.binary)+b'\0'*((-len(self.binary))%4)
        total=12+8+len(js)+8+len(binary)
        path.parent.mkdir(parents=True,exist_ok=True)
        with path.open('wb') as f:
            f.write(struct.pack('<4sII',b'glTF',2,total))
            f.write(struct.pack('<I4s',len(js),b'JSON')); f.write(js)
            f.write(struct.pack('<I4s',len(binary),b'BIN\0')); f.write(binary)

def _smooth_profile(profile,steps=4):
    dense=[]
    for i in range(len(profile)-1):
        p0=profile[max(0,i-1)]; p1=profile[i]; p2=profile[i+1]; p3=profile[min(len(profile)-1,i+2)]
        for step in range(steps):
            t=step/steps; t2=t*t; t3=t2*t
            row=[]
            for axis in range(2):
                value=.5*((2*p1[axis])+(-p0[axis]+p2[axis])*t+(2*p0[axis]-5*p1[axis]+4*p2[axis]-p3[axis])*t2+(-p0[axis]+3*p1[axis]-3*p2[axis]+p3[axis])*t3)
                row.append(value)
            dense.append((row[0],max(.025,row[1])))
    dense.append(profile[-1])
    return dense

def fusiform(length,rx,rz,segments=24,profile=None):
    if profile is None: profile=[(-.5,.10),(-.42,.40),(-.25,.78),(0,1),(.25,.78),(.42,.40),(.5,.10)]
    profile=_smooth_profile(profile)
    verts=[]; faces=[]
    for y,r in profile:
        for j in range(segments):
            a=2*math.pi*j/segments
            verts.append((rx*r*math.cos(a),length*y,rz*r*math.sin(a)))
    for i in range(len(profile)-1):
        for j in range(segments):
            a=i*segments+j; b=i*segments+(j+1)%segments
            c=(i+1)*segments+j; d=(i+1)*segments+(j+1)%segments
            faces.extend(((a,c,b),(b,c,d)))
    # Outward-facing caps: bottom points down, top points up.
    faces.append(tuple(range(segments)))
    end=(len(profile)-1)*segments; faces.append(tuple(reversed(range(end,end+segments))))
    return verts,faces

def ellipsoid(rx,ry,rz,lat=14,lon=20):
    verts=[]; faces=[]
    for i in range(lat+1):
        p=-math.pi/2+math.pi*i/lat
        for j in range(lon):
            a=2*math.pi*j/lon
            verts.append((rx*math.cos(p)*math.cos(a),ry*math.sin(p),rz*math.cos(p)*math.sin(a)))
    for i in range(lat):
        for j in range(lon):
            a=i*lon+j; b=i*lon+(j+1)%lon; c=(i+1)*lon+j; d=(i+1)*lon+(j+1)%lon
            faces.extend(((a,c,b),(b,c,d)))
    return verts,faces

def y_cylinder(radius,length,segments=20,radius2=None):
    r2=radius if radius2 is None else radius2
    verts=[]; faces=[]
    for y,r in [(-length/2,radius),(length/2,r2)]:
        for j in range(segments):
            a=2*math.pi*j/segments; verts.append((r*math.cos(a),y,r*math.sin(a)))
    for j in range(segments):
        k=(j+1)%segments; faces.extend(((j,segments+j,k),(k,segments+j,segments+k)))
    faces.append(tuple(range(segments))); faces.append(tuple(reversed(range(segments,2*segments))))
    return verts,faces

def open_sheath(length,rx,rz,thickness=.12,rows=24,sides=28,cut_center_deg=90,cut_width_deg=110):
    """Hollow longitudinal sleeve with a front cutaway window, local axis Y."""
    verts=[]; faces=[]
    # Smooth spindle envelope with slightly tapered ends.
    prof=[(-.5,.28),(-.46,.60),(-.34,.88),(-.16,1),(0,1),(.16,1),(.34,.88),(.46,.60),(.5,.28)]
    # Keep a broad angular strip away from +Z (the viewing/cutaway side).
    start=math.radians(cut_center_deg+cut_width_deg/2)
    span=math.radians(360-cut_width_deg)
    for layer,rscale in enumerate((1.0,1.0-thickness)):
        base=len(verts)
        for yi,rad in prof:
            for j in range(sides+1):
                a=start+span*j/sides
                verts.append((rx*rad*rscale*math.cos(a),length*yi,rz*rad*rscale*math.sin(a)))
        for i in range(len(prof)-1):
            for j in range(sides):
                a=base+i*(sides+1)+j; b=a+1; c=a+(sides+1); d=c+1
                if layer==0: faces.extend(((a,c,b),(b,c,d)))
                else: faces.extend(((a,b,c),(b,d,c)))
        # close front cut lips for each side of the open sector
        for edge_j in (0,sides):
            for i in range(len(prof)-1):
                a=base+i*(sides+1)+edge_j; b=a+(sides+1)
                inner=a+len(prof)*(sides+1); inner_next=b+len(prof)*(sides+1)
                if layer==0: faces.extend(((a,b,inner),(b,inner_next,inner)))
    return verts,faces

def _tissue(g,name,color,rough=.62): return g.material(name,(*color,1.0),rough)

def build_muscle_belly():
    g=GLB()
    red=_tissue(g,'Gastrocnemius tissue',(0.78,.30,.24),.62)
    fascicles=[_tissue(g,'Fascicle tissue',(0.85,.39,.31),.64),_tissue(g,'Fascicle highlight',(0.90,.47,.37),.60)]
    epi=g.material('Epimysium translucent collagen',(0.89,.68,.56,.55),.48,alpha=.55)
    tendon=_tissue(g,'Pale connective tendon',(0.82,.70,.56),.50)
    root=g.empty('MuscleBelly',(0,0,0),extras={'pivot':'belly center','unit':'m','envelope_m':[.018,.050,.013]})
    shell,faces=open_sheath(.050,.009,.0065,.10,cut_center_deg=90,cut_width_deg=98)
    g.mesh('Epimysium',shell,faces,epi,parent=root,extras={'role':'outer fascia; anterior cutaway'})
    # Seven whole-length fascicles sit within the belly; one is brought forward into the viewing window.
    positions=[(0,0,.0022),(-.0040,0,.0005),(.0040,0,.0005),(-.0034,0,-.0026),(.0034,0,-.0026),(0,0,-.0035),(0,0,.0040)]
    for i,pos in enumerate(positions):
        node=g.empty('Fascicle_%02d'%(i+1),pos,parent=root,extras={'zoom_target':'fascicle.glb','approx_diameter_m':.0018})
        v,f=fusiform(.048,.00165,.00115,28)
        g.mesh('Fascicle bundle %02d'%(i+1),v,f,fascicles[i%2],parent=node)
    # The two collagen tendons continue the long axis from each tapered end.
    top=g.empty('TendonTop',(0,.025,0),parent=root,extras={'pivot':'proximal attachment'})
    v,f=fusiform(.010,.0020,.00155,16,profile=[(-.5,.88),(-.35,1),(.2,.9),(.5,.68)])
    g.mesh('TendonTop collagen',v,f,tendon,translation=(0,.005,0),parent=top)
    bottom=g.empty('TendonBottom',(0,-.025,0),parent=root,extras={'pivot':'distal attachment'})
    v,f=fusiform(.010,.0020,.00155,16,profile=[(-.5,.68),(-.2,.9),(.35,1),(.5,.88)])
    g.mesh('TendonBottom collagen',v,f,tendon,translation=(0,-.005,0),parent=bottom)
    return g

def fascicle_positions():
    pts=[]
    spacing=150.0
    for iz in range(-4,5):
        for ix in range(-4,5):
            x=ix*spacing; z=iz*spacing
            if (x/570.0)**2+(z/500.0)**2 <= 0.90:
                pts.append((x,z))
    # Deterministic ordering from center outward, then angle.
    pts.sort(key=lambda p:(p[0]*p[0]+p[1]*p[1],math.atan2(p[1],p[0])))
    return pts[:37]

def build_fascicle():
    g=GLB()
    peri=g.material('Perimysium pale collagen sheath',(.83,.65,.54,.58),.48,alpha=.58)
    fiber_colors=[(0.79,.29,.25),(0.85,.36,.30),(0.73,.25,.23),(0.89,.43,.35)]
    fiber_mats=[_tissue(g,'Muscle fiber tissue %02d'%(i+1),c,.63) for i,c in enumerate(fiber_colors)]
    root=g.empty('Fascicle',(0,0,0),extras={'pivot':'fascicle center','unit':'µm','envelope_um':[1400,50000,1200],'zoom_target':'fiber.glb'})
    shell,faces=open_sheath(50000,700,600,.08,cut_center_deg=90,cut_width_deg=92)
    g.mesh('Perimysium',shell,faces,peri,parent=root,extras={'role':'fascicle sheath; longitudinal cutaway'})
    for i,(x,z) in enumerate(fascicle_positions()):
        pivot=g.empty('Fiber_%02d'%(i+1),(x,0,z),parent=root,extras={'cell':'skeletal muscle fiber','pivot':'fiber long axis'})
        v,f=fusiform(49000,63,52,12)
        g.mesh('Fiber cell %02d'%(i+1),v,f,fiber_mats[i%len(fiber_mats)],parent=pivot)
    return g

def fiber_myofibril_positions():
    # A compact hexagonal packing with a small central lumen for mitochondria.
    pts=[(0.0,0.0)]
    for radius,count in ((14,6),(27,12)):
        for i in range(count):
            a=2*math.pi*i/count
            pts.append((radius*math.cos(a),radius*math.sin(a)))
    return pts

def build_fiber():
    g=GLB()
    sarco=g.material('Sarcolemma cool translucent cell membrane',(.42,.67,.70,.38),.28,alpha=.38)
    cytoplasm=_tissue(g,'Sarcoplasm warm coral',(.67,.23,.23),.68)
    myofibril=_tissue(g,'Myofibril core tissue',(.58,.18,.20),.53)
    nucleus=_tissue(g,'Peripheral myonucleus',(.31,.18,.31),.45)
    mito=g.material('Mitochondrion amber matrix',(.89,.48,.19,1.0),.38)
    root=g.empty('MuscleFiber',(0,0,0),extras={'pivot':'fiber center','unit':'µm','envelope_um':[90,50000,80],'zoom_target':'myofibril.glb'})
    shell,faces=open_sheath(50000,45,40,.10,cut_center_deg=90,cut_width_deg=110)
    g.mesh('Sarcolemma',shell,faces,sarco,parent=root,extras={'role':'cell membrane; longitudinal cutaway'})
    core,corefaces=fusiform(49000,39,34,22)
    g.mesh('Sarcoplasm',core,corefaces,cytoplasm,parent=root)
    # Myofibrils run parallel to the fiber axis and are visible through the cutaway and at the cut end.
    for i,(x,z) in enumerate(fiber_myofibril_positions()):
        piv=g.empty('Myofibril_%02d'%(i+1),(x,0,z),parent=root,extras={'zoom_target':'myofibril.glb','unit':'µm'})
        v,f=y_cylinder(4.2,47500,14)
        g.mesh('Myofibril longitudinal %02d'%(i+1),v,f,myofibril,parent=piv)
    # Six elongated nuclei sit peripherally beneath the sarcolemma, not in the central contractile core.
    for i,y in enumerate((-20500,-12300,-4100,4100,12300,20500)):
        side=-1 if i%2==0 else 1
        angle=math.radians(66 if side>0 else 114)
        pos=(39*math.cos(angle),y,34*math.sin(angle))
        v,f=ellipsoid(7.5,2600,1.8,12,18)
        g.mesh('Nucleus_%d'%(i+1),v,f,nucleus,translation=pos,parent=root,extras={'location':'peripheral'})
    # Mitochondria occupy intermyofibrillar spaces, elongated along the fiber.
    mito_positions=[(-19,-9000),(-19,9000),(19,-19000),(19,19000),(0,-15500),(0,15500),(-30,0),(30,0)]
    for i,(x,y) in enumerate(mito_positions):
        z=4.0 if i%2==0 else -4.0
        v,f=ellipsoid(3.1,1700,2.0,10,16)
        g.mesh('Mitochondrion_%02d'%(i+1),v,f,mito,translation=(x,y,z),parent=root)
    return g

def build_myofibril():
    g=GLB()
    core=_tissue(g,'Myofibril axial core',(.62,.22,.23),.54)
    band_a=_tissue(g,'BandA',(.51,.12,.16),.48)
    band_i=_tissue(g,'BandI',(.91,.45,.37),.66)
    zline=_tissue(g,'ZLine',(.92,.78,.62),.44)
    hzone=_tissue(g,'H zone',(.68,.26,.27),.62)
    root=g.empty('Myofibril',(0,0,0),extras={'pivot':'myofibril center','unit':'µm','envelope_um':[.95,6.0,.95],'sarcomere_count':3})
    v,f=y_cylinder(.34,6.0,32);g.mesh('Myofibril continuous profile',v,f,core,parent=root)
    # Three 2 µm sarcomeres: a 1.48 µm A band, split I bands, and narrow Z discs.
    for s,center in enumerate((-2.0,0.0,2.0),1):
        # A band is in two flanks around the central H zone, avoiding coplanar overlays.
        for side,cy in [('L',center-.42),('R',center+.42)]:
            v,f=y_cylinder(.44,.64,32);g.mesh('BandA_%02d_%s'%(s,side),v,f,band_a,translation=(0,cy,0),parent=root)
        for side,cy in [('L',center-.865),('R',center+.865)]:
            v,f=y_cylinder(.44,.22,32);g.mesh('BandI_%02d_%s'%(s,side),v,f,band_i,translation=(0,cy,0),parent=root)
        v,f=y_cylinder(.44,.20,32);g.mesh('H zone_%02d'%s,v,f,hzone,translation=(0,center,0),parent=root)
    # Z discs bisect I bands at every sarcomere boundary.
    for i,y in enumerate((-3.0,-1.0,1.0,3.0),1):
        v,f=y_cylinder(.48,.04,32);g.mesh('ZLine_%02d'%i,v,f,zline,translation=(0,y,0),parent=root)
    return g

def main():
    OUT.mkdir(parents=True,exist_ok=True)
    outputs=[('muscle_belly.glb',build_muscle_belly(),'Muscle belly cutaway'),
             ('fascicle.glb',build_fascicle(),'Fascicle and muscle fibers'),
             ('fiber.glb',build_fiber(),'Skeletal muscle fiber cutaway'),
             ('myofibril.glb',build_myofibril(),'Myofibril band structure')]
    for filename,g,name in outputs: g.export(OUT/filename,name)
    print('Wrote 4 muscle structure GLBs to',OUT)

if __name__=='__main__': main()
