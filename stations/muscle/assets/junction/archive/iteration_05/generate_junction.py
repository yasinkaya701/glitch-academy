#!/usr/bin/env python3
"""Deterministic, hand-authored motor end-plate cutaway. Standard library only."""
from __future__ import annotations
import json, math, struct
from pathlib import Path

OUT = Path(__file__).resolve().parent

class GLB:
    def __init__(self): self.nodes=[]; self.parents=[]; self.meshes=[]; self.materials=[]; self.mi={}; self.views=[]; self.accessors=[]; self.binary=bytearray()
    def material(self,name,color,rough=.58,metal=0.,alpha=1.):
        key=(name,tuple(color),rough,metal,alpha)
        if key in self.mi:return self.mi[key]
        m={'name':name,'pbrMetallicRoughness':{'baseColorFactor':list(color),'metallicFactor':metal,'roughnessFactor':rough}}
        if alpha<1:m.update(alphaMode='BLEND',doubleSided=True)
        idx=len(self.materials);self.materials.append(m);self.mi[key]=idx;return idx
    def _accessor(self,data,component,typ,target=None,limits=False):
        raw=data
        while len(self.binary)%4:self.binary.append(0)
        off=len(self.binary);self.binary.extend(raw)
        view={'buffer':0,'byteOffset':off,'byteLength':len(raw)}
        if target:view['target']=target
        self.views.append(view);a={'bufferView':len(self.views)-1,'componentType':component,'count':self._count,'type':typ}
        if limits:a.update(min=self._min,max=self._max)
        self.accessors.append(a);return len(self.accessors)-1
    def mesh(self,name,vertices,faces,material):
        normals=[[0.,0.,0.] for _ in vertices]
        for tri in faces:
            a,b,c=[vertices[i] for i in tri];u=[b[k]-a[k] for k in range(3)];v=[c[k]-a[k] for k in range(3)];n=(u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0])
            for i in tri:
                for k in range(3):normals[i][k]+=n[k]
        for n in normals:
            q=math.sqrt(sum(x*x for x in n)) or 1
            for k in range(3):n[k]/=q
        vflat=[x for p in vertices for x in p];nflat=[x for p in normals for x in p];indices=[x for f in faces for x in f]
        self._count=len(vertices);self._min=[min(p[k] for p in vertices) for k in range(3)];self._max=[max(p[k] for p in vertices) for k in range(3)]
        pos=self._accessor(struct.pack('<%sf'%len(vflat),*vflat),5126,'VEC3',34962,True)
        norm=self._accessor(struct.pack('<%sf'%len(nflat),*nflat),5126,'VEC3',34962)
        comp=5123 if len(vertices)<65536 else 5125;fmt='H' if comp==5123 else 'I'
        self._count=len(indices);ind=self._accessor(struct.pack('<%s%s'%(len(indices),fmt),*indices),comp,'SCALAR',34963)
        self.meshes.append({'name':name,'primitives':[{'attributes':{'POSITION':pos,'NORMAL':norm},'indices':ind,'material':material}]})
        return len(self.meshes)-1
    def node(self,name,mesh=None,pos=(0,0,0),parent=None,extras=None):
        node={'name':name,'translation':list(pos)}
        if mesh is not None:node['mesh']=mesh
        if extras:node['extras']=extras
        self.nodes.append(node);self.parents.append(parent);return len(self.nodes)-1
    def export(self,path):
        children=[[] for _ in self.nodes];roots=[]
        for i,p in enumerate(self.parents):(roots if p is None else children[p]).append(i)
        for i,kids in enumerate(children):
            if kids:self.nodes[i]['children']=kids
        d={'asset':{'version':'2.0','generator':'generate_junction.py · original deterministic procedural anatomy'},'scene':0,'scenes':[{'name':'Motor end plate · cutaway','nodes':roots}],'nodes':self.nodes,'meshes':self.meshes,'materials':self.materials,'buffers':[{'byteLength':len(self.binary)}],'bufferViews':self.views,'accessors':self.accessors}
        js=json.dumps(d,separators=(',',':')).encode();js+=b' '*((-len(js))%4);bb=bytes(self.binary)+b'\0'*((-len(self.binary))%4);size=12+8+len(js)+8+len(bb)
        path.parent.mkdir(parents=True,exist_ok=True)
        with open(path,'wb') as f:f.write(struct.pack('<4sII',b'glTF',2,size)+struct.pack('<I4s',len(js),b'JSON')+js+struct.pack('<I4s',len(bb),b'BIN\0')+bb)

def ellipsoid(rx,ry,rz,lat=36,lon=80,open_front=False,opening=.80):
    v=[];f=[]
    for i in range(lat+1):
        th=math.pi*i/lat
        for j in range(lon):
            ph=2*math.pi*j/lon;v.append((rx*math.sin(th)*math.cos(ph),ry*math.cos(th),rz*math.sin(th)*math.sin(ph)))
    for i in range(lat):
        for j in range(lon):
            a=i*lon+j;b=i*lon+(j+1)%lon;c=(i+1)*lon+j;d=(i+1)*lon+(j+1)%lon
            for tri in ((a,c,b),(b,c,d)):
                center=tuple(sum(v[k][q] for k in tri)/3 for q in range(3))
                # A finite anterior window keeps sidewall and depth; do not remove the whole front hemisphere.
                if open_front and center[2] > 0.02 and (center[0]/rx)**2+(center[1]/ry)**2 < opening**2: continue
                f.append(tri)
    return v,f

def tube(path,ro,ri=None,sides=18):
    """Hollow swept tube, with local frames and open ends unless a ring is visible."""
    pts=[tuple(map(float,p)) for p in path];v=[];f=[]
    for k,p in enumerate(pts):
        before=pts[max(0,k-1)];after=pts[min(len(pts)-1,k+1)];t=[after[q]-before[q] for q in range(3)];ln=math.sqrt(sum(x*x for x in t)) or 1;t=[x/ln for x in t]
        ref=(0,0,1) if abs(t[2])<.88 else (0,1,0);u=(t[1]*ref[2]-t[2]*ref[1],t[2]*ref[0]-t[0]*ref[2],t[0]*ref[1]-t[1]*ref[0]);ln=math.sqrt(sum(x*x for x in u)) or 1;u=[x/ln for x in u];w=(t[1]*u[2]-t[2]*u[1],t[2]*u[0]-t[0]*u[2],t[0]*u[1]-t[1]*u[0])
        for r in (ro,ri or ro*.66):
            for j in range(sides):
                a=2*math.pi*j/sides;v.append(tuple(p[q]+r*(math.cos(a)*u[q]+math.sin(a)*w[q]) for q in range(3)))
    stride=sides*2
    for k in range(len(pts)-1):
        for shell in range(2):
            s=k*stride+shell*sides;n=(k+1)*stride+shell*sides
            for j in range(sides):
                a=s+j;b=s+(j+1)%sides;c=n+j;d=n+(j+1)%sides
                tris=((a,c,b),(b,c,d)) if shell==0 else ((a,b,c),(b,d,c))
                f.extend(tris)
    return v,f

def box(x,y,z):
    v=[(-x,-y,-z),(x,-y,-z),(x,y,-z),(-x,y,-z),(-x,-y,z),(x,-y,z),(x,y,z),(-x,y,z)]
    f=[(0,2,1),(0,3,2),(4,5,6),(4,6,7),(0,1,5),(0,5,4),(1,2,6),(1,6,5),(2,3,7),(2,7,6),(3,0,4),(3,4,7)]
    return v,f

def torus(rx,rz,r,segments=44,sides=8):
    v=[];f=[]
    for i in range(segments):
        a=2*math.pi*i/segments
        for j in range(sides):
            b=2*math.pi*j/sides;v.append(((rx+r*math.cos(b))*math.cos(a),r*math.sin(b),(rz+r*math.cos(b))*math.sin(a)))
    for i in range(segments):
        for j in range(sides):
            a=i*sides+j;b=i*sides+(j+1)%sides;c=((i+1)%segments)*sides+j;d=((i+1)%segments)*sides+(j+1)%sides;f.extend(((a,c,b),(b,c,d)))
    return v,f

def main():
    g=GLB()
    terminal_mat=g.material('Motor terminal · warm copper',(.67,.255,.205,1),.68)
    terminal_inner=g.material('Presynaptic interior',(.255,.105,.11,1),.82)
    vesicle_mat=g.material('Synaptic vesicle membrane',(.91,.59,.27,1),.35,.12)
    ach_mat=g.material('Acetylcholine packet',(.98,.80,.47,1),.42)
    cleft_mat=g.material('Synaptic cleft fluid',(.28,.62,.67,.3),.23,0,.30)
    membrane_mat=g.material('Sarcolemma · warm rose',(.56,.235,.26,1),.58)
    fiber_mat=g.material('Muscle fiber cutaway',(.36,.105,.14,1),.74)
    receptor_mat=g.material('ACh receptor · cool enamel',(.24,.68,.69,1),.28,.18)
    pore_mat=g.material('Receptor pore',(.045,.15,.18,1),.62)
    tubule_mat=g.material('T-tubule lumen',(.08,.34,.40,1),.38,.05)
    sr_mat=g.material('Sarcoplasmic reticulum',(.34,.64,.66,1),.38,.04)
    ca_mat=g.material('Calcium ion',(.88,.92,.89,1),.25,.06)

    # Broad cutaway muscle fiber shell; the anterior face is removed to expose the triad.
    fiber_v,fiber_f=ellipsoid(4.8,2.25,3.20,40,96,open_front=True,opening=.78)
    fiber=g.node('MuscleFiber',g.mesh('MuscleFiber cutaway',fiber_v,fiber_f,fiber_mat),(0,-2.10,-.12),extras={'unit':'µm','role':'skeletal muscle fiber cutaway'})
    # A thick, curved membrane cap follows the upper contour of the fiber, rather than a flat disk.
    membrane_v,membrane_f=ellipsoid(4.55,.42,2.93,18,64)
    membrane=g.node('Sarcolemma',g.mesh('Curved sarcolemma cap',membrane_v,membrane_f,membrane_mat),(0,.10,-.12),extras={'pivot':'fiber membrane center','unit':'µm','role':'curved postsynaptic membrane with visible thickness'})
    # The cleft occupies a real volume between the bouton and curved muscle surface.
    cleft_v,cleft_f=ellipsoid(2.95,.16,1.72,12,48)
    g.node('SynapticCleft',g.mesh('Cleft fluid volume',cleft_v,cleft_f,cleft_mat),(0,.54,0),extras={'gap_um':.20,'role':'extracellular synaptic space; gap exaggerated for visibility'})

    # Presynaptic bouton has its camera-facing cap removed: its vesicles remain inside the terminal wall.
    bouton_v,bouton_f=ellipsoid(2.95,1.72,1.95,40,96,open_front=True,opening=.83)
    term=g.node('Terminal',g.mesh('Motor bouton cutaway',bouton_v,bouton_f,terminal_mat),(0,2.35,0),extras={'pivot':'bouton center','unit':'µm','role':'motor neuron terminal'})
    axon_v,axon_f=ellipsoid(.48,1.75,.48,22,32)
    g.node('Axon',g.mesh('Motor axon',axon_v,axon_f,terminal_mat),(0,2.18,.58),parent=term,extras={'role':'motor axon continuous with terminal'})
    # A dark inner membrane trace emphasizes the open cut edge without decorative trim.
    inner_v,inner_f=ellipsoid(2.72,1.49,1.72,36,80,open_front=True,opening=.88)
    g.node('TerminalInterior',g.mesh('Bouton inner surface',inner_v,inner_f,terminal_inner),(0,0,0),parent=term,extras={'role':'recessed terminal lining'})

    # Each vesicle is its own transform. Local target coordinates sit immediately above the cleft.
    vesicles=[(-1.93,-.72,-.30),(-.67,-.90,-.52),(.72,-.82,-.58),(1.95,-.63,-.30),(-1.25,.43,-.52),(.20,.49,-.48),(1.38,.38,-.40)]
    for i,p in enumerate(vesicles,1):
        name=f'Vesicle_{i:02d}';v,f=ellipsoid(.37,.37,.37,16,24)
        idx=g.node(name,g.mesh(name+' membrane',v,f,vesicle_mat),p,parent=term,extras={'pivot':'vesicle center','unit':'µm','motion':'translate local Y from listed rest point into SynapticCleft'})
        # Three dim, fixed ACh beads inside each vesicle make its contents readable at close scale.
        for j,off in enumerate(((-.11,.02,.08),(.10,-.07,.02),(.02,.11,-.08)),1):
            av,af=ellipsoid(.055,.055,.055,8,12)
            g.node(f'ACh_{i:02d}_{j}',g.mesh('ACh packet',av,af,ach_mat),off,parent=idx)

    # Receptors are separated oligomer-like channel assemblies along the postsynaptic face.
    for i,x in enumerate((-2.25,-1.35,-.45,.45,1.35,2.25),1):
        rname=f'Receptor_{i:02d}';ri=g.node(rname,pos=(x,.28,0),parent=membrane,extras={'unit':'µm','role':'acetylcholine-gated channel'})
        for sub in range(5):
            a=2*math.pi*sub/5;sv,sf=ellipsoid(.14,.27,.14,12,18)
            # Subunits sit as children with their own small radial offsets in local space.
            g.node(f'{rname}_Subunit_{sub+1}',g.mesh('Receptor subunit',sv,sf,receptor_mat),(.16*math.cos(a),0,.16*math.sin(a)),parent=ri,extras={'subunit_index':sub+1})
        pv,pf=ellipsoid(.065,.25,.065,12,16)
        g.node(f'{rname}_Pore',g.mesh('Ion channel pore',pv,pf,pore_mat),(0,.01,0),parent=ri)

    # T-tubule is a hollow surface invagination; an opening is at the sarcolemma and its lumen continues inward.
    tub_v,tub_f=tube([(0,.48,.18),(0,-.35,.18),(0,-1.20,.18),(0,-2.05,.18),(0,-2.72,.18)],.37,.25,24)
    tt=g.node('TTubule',g.mesh('T-tubule wall and lumen',tub_v,tub_f,tubule_mat),(0,0,0),extras={'unit':'µm','role':'transverse sarcolemma invagination','pivot':'mouth at sarcolemma'})
    # Open terminal cisternae flank the tubule as the muscle triad.
    sr=g.node('SR',extras={'unit':'µm','role':'sarcoplasmic reticulum terminal cisternae; Ca2+ release source'})
    for side,label in ((-1,'L'),(1,'R')):
        sv,sf=ellipsoid(.78,.31,.46,18,32)
        g.node(f'SR_Cisterna_{label}',g.mesh('SR terminal cisterna',sv,sf,sr_mat),(side*1.38,-1.56,-.12),parent=sr)
        for j,x in enumerate((.90,1.35,1.80),1):
            g.node(f'Ca2_ParticleSocket_{label}{j}',pos=(side*x,-1.52,-.08),parent=sr,extras={'particle':'Ca2+','role':'release animation socket','unit':'µm'})
            cv,cf=ellipsoid(.065,.065,.065,8,12)
            g.node(f'Ca2_Particle_{label}{j}',g.mesh('Calcium ion particle',cv,cf,ca_mat),(side*x,-1.52,-.08),parent=sr,extras={'particle':'Ca2+','role':'stored calcium visualization','unit':'µm'})
    # One mouth socket pair enables an optional incoming depolarization cue without embedded symbols.
    for i,x in enumerate((-.34,.34),1):g.node(f'Ca2_ParticleSocket_TT_{i}',pos=(x,-2.30,.18),parent=tt,extras={'particle':'Ca2+','role':'T-tubule/cytosol observation point','unit':'µm'})

    g.export(OUT/'neuromuscular_junction.glb')
    print('Wrote neuromuscular_junction.glb')

if __name__=='__main__':main()
