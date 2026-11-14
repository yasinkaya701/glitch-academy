import json, math, struct, os
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter
import random
ROOT=Path(__file__).resolve().parent.parent
V=ROOT/'valves'; T=ROOT/'tubes'

# Small pure-Python glTF 2.0/GLB writer. Geometry is authored here; no generated imagery.
class GLB:
    def __init__(self, name):
        self.name=name; self.bin=bytearray(); self.views=[]; self.accessors=[]; self.meshes=[]; self.nodes=[]; self.materials=[]; self.animations=[]; self.images=[]; self.textures=[]; self.texture_cache={}
    def texture(self,path):
        path=str(path)
        if path in self.texture_cache:return self.texture_cache[path]
        while len(self.bin)%4:self.bin.append(0)
        data=Path(path).read_bytes(); view=self._view(data)
        image=len(self.images);self.images.append({'name':Path(path).stem,'bufferView':view,'mimeType':'image/png'})
        tex=len(self.textures);self.textures.append({'sampler':0,'source':image});self.texture_cache[path]=tex;return tex
    def material(self,name,color,metallic,roughness,alpha='OPAQUE',double=False,maps=None):
        pbr={'baseColorFactor':color,'metallicFactor':metallic,'roughnessFactor':roughness}
        d={'name':name,'pbrMetallicRoughness':pbr,'alphaMode':alpha,'doubleSided':double}
        if maps:
            pbr['baseColorTexture']={'index':self.texture(maps[0])}
            if len(maps)>1:d['normalTexture']={'index':self.texture(maps[1]),'scale':0.25}
            if len(maps)>2:pbr['metallicRoughnessTexture']={'index':self.texture(maps[2])}
        ix=len(self.materials); self.materials.append(d); return ix
    def _view(self,data,target=None):
        while len(self.bin)%4:self.bin.append(0)
        off=len(self.bin); self.bin.extend(data); d={'buffer':0,'byteOffset':off,'byteLength':len(data)}
        if target:d['target']=target
        i=len(self.views); self.views.append(d); return i
    def _access(self,view,ct,count,typ,mins=None,maxs=None):
        a={'bufferView':view,'componentType':ct,'count':count,'type':typ}
        if mins is not None:a['min']=mins
        if maxs is not None:a['max']=maxs
        i=len(self.accessors);self.accessors.append(a);return i
    def mesh(self,name,positions,faces,mat,normals=None,uv=None):
        if not positions or not faces:return None
        if normals is None:
            normals=[]
            for x,y,z in positions:
                n=math.sqrt(x*x+y*y+z*z) or 1
                normals.append((x/n,y/n,z/n))
        if uv is None:
            uv=[((x+0.02)/0.04,(z+0.02)/0.04) for x,y,z in positions]
        posb=b''.join(struct.pack('<3f',*p) for p in positions)
        nrm=b''.join(struct.pack('<3f',*p) for p in normals)
        uvb=b''.join(struct.pack('<2f',*p) for p in uv)
        flat=[i for f in faces for i in f]
        if max(flat)<65536: ib=struct.pack('<%dH'%len(flat),*flat); ct=5123
        else: ib=struct.pack('<%dI'%len(flat),*flat); ct=5125
        pview=self._view(posb,34962); nview=self._view(nrm,34962); uview=self._view(uvb,34962); iview=self._view(ib,34963)
        mins=[min(p[i] for p in positions) for i in range(3)]; maxs=[max(p[i] for p in positions) for i in range(3)]
        pa=self._access(pview,5126,len(positions),'VEC3',mins,maxs); na=self._access(nview,5126,len(normals),'VEC3'); ua=self._access(uview,5126,len(uv),'VEC2'); ia=self._access(iview,ct,len(flat),'SCALAR',[min(flat)],[max(flat)])
        mi=len(self.meshes);self.meshes.append({'name':name,'primitives':[{'attributes':{'POSITION':pa,'NORMAL':na,'TEXCOORD_0':ua},'indices':ia,'material':mat,'mode':4}]});return mi
    def node(self,name,mesh=None,translation=None,rotation=None,scale=None,children=None):
        d={'name':name}
        if mesh is not None:d['mesh']=mesh
        if translation is not None:d['translation']=list(translation)
        if rotation is not None:d['rotation']=list(rotation)
        if scale is not None:d['scale']=list(scale)
        if children:d['children']=list(children)
        i=len(self.nodes);self.nodes.append(d);return i
    def anim_rot(self,name,node,quat):
        anim=next((a for a in self.animations if a['name']==name),None)
        if anim is None:
            anim={'name':name,'samplers':[],'channels':[]};self.animations.append(anim)
        while len(self.bin)%4:self.bin.append(0)
        tview=self._view(struct.pack('<2f',0,1)); ta=self._access(tview,5126,2,'SCALAR',[0],[1])
        vals=[(0,0,0,1),quat]
        vview=self._view(b''.join(struct.pack('<4f',*q) for q in vals)); va=self._access(vview,5126,2,'VEC4')
        sampler=len(anim['samplers']);anim['samplers'].append({'input':ta,'output':va,'interpolation':'LINEAR'});anim['channels'].append({'sampler':sampler,'target':{'node':node,'path':'rotation'}})
    def save(self,path,scene_nodes):
        doc={'asset':{'version':'2.0','generator':'Codex hand-authored procedural mesh builder'},'scene':0,'scenes':[{'name':self.name,'nodes':scene_nodes}],'nodes':self.nodes,'meshes':self.meshes,'materials':self.materials,'buffers':[{'byteLength':len(self.bin)}],'bufferViews':self.views,'accessors':self.accessors}
        if self.images:doc['images']=self.images;doc['textures']=self.textures;doc['samplers']=[{'magFilter':9729,'minFilter':9987,'wrapS':10497,'wrapT':10497}]
        if self.animations:doc['animations']=self.animations
        js=json.dumps(doc,separators=(',',':')).encode('utf-8'); js+=b' '*((-len(js))%4)
        while len(self.bin)%4:self.bin.append(0)
        total=12+8+len(js)+8+len(self.bin)
        out=struct.pack('<4sII',b'glTF',2,total)+struct.pack('<I4s',len(js),b'JSON')+js+struct.pack('<I4s',len(self.bin),b'BIN\x00')+self.bin
        Path(path).write_bytes(out)

def torus(R,r,axis='y',segments=48,sides=8,start=0,end=2*math.pi):
    p=[];n=[];f=[]
    for i in range(segments+1):
        a=start+(end-start)*i/segments
        for j in range(sides+1):
            b=2*math.pi*j/sides
            if axis=='y':
                radial=R+r*math.cos(b); p.append((radial*math.cos(a),r*math.sin(b),radial*math.sin(a))); n.append((math.cos(b)*math.cos(a),math.sin(b),math.cos(b)*math.sin(a)))
            else:
                radial=R+r*math.cos(b); p.append((r*math.sin(b),radial*math.cos(a),radial*math.sin(a))); n.append((math.sin(b),math.cos(b)*math.cos(a),math.cos(b)*math.sin(a)))
    for i in range(segments):
        for j in range(sides):
            a=i*(sides+1)+j;b=a+sides+1;f.extend([(a,b,a+1),(a+1,b,b+1)])
    return p,f,n

def cylinder_y(radius,y0,y1,segments=32,inner=0):
    p=[];n=[];f=[]
    for rad,yy,sign in [(radius,y0,-1),(radius,y1,1)]+([(inner,y0,1),(inner,y1,-1)] if inner else []):
        off=len(p)
        for i in range(segments+1):
            a=2*math.pi*i/segments;x=rad*math.cos(a);z=rad*math.sin(a);p.append((x,yy,z));n.append((math.cos(a),0,math.sin(a)))
        if off==0 or (inner and off==2*(segments+1)):
            for i in range(segments):f.extend([(off+i,off+i+1,off+segments+1+i+1),(off+i,off+segments+1+i+1,off+segments+1+i)])
    return p,f,n

def annulus(Ro,Ri,y0,y1,segments=48):
    p=[];n=[];f=[]
    for rad,y in ((Ro,y0),(Ro,y1),(Ri,y0),(Ri,y1)):
        for i in range(segments+1):
            a=2*math.pi*i/segments;p.append((rad*math.cos(a),y,rad*math.sin(a)));n.append((math.cos(a),0,math.sin(a)))
    k=segments+1
    for i in range(segments):
        f += [(i,i+1,k+i+1),(i,k+i+1,k+i),(2*k+i,3*k+i+1,2*k+i+1),(2*k+i,3*k+i,3*k+i+1)]
        f += [(k+i,k+i+1,3*k+i+1),(k+i,3*k+i+1,3*k+i),(i,2*k+i+1,i+1),(i,2*k+i,2*k+i+1)]
    return p,f,n

def box(sx,sy,sz,center=(0,0,0)):
    x,y,z=center;hx=sx/2;hy=sy/2;hz=sz/2
    p=[(x-hx,y-hy,z-hz),(x+hx,y-hy,z-hz),(x+hx,y+hy,z-hz),(x-hx,y+hy,z-hz),(x-hx,y-hy,z+hz),(x+hx,y-hy,z+hz),(x+hx,y+hy,z+hz),(x-hx,y+hy,z+hz)]
    f=[(0,2,1),(0,3,2),(4,5,6),(4,6,7),(0,1,5),(0,5,4),(3,7,6),(3,6,2),(0,4,7),(0,7,3),(1,2,6),(1,6,5)]
    return p,f

def merge_add(g,name,geometry,material,trans=(0,0,0),parent_children=None):
    p,f,n=geometry
    if trans!=(0,0,0):p=[(x+trans[0],y+trans[1],z+trans[2]) for x,y,z in p]
    m=g.mesh(name,p,f,material,n)
    return g.node(name,m) if m is not None else None

def add_ring(g, children, name, R, tube, y, mat):
    p,f,n=torus(R,tube); idx=g.mesh(name,p,f,mat,n); children.append(g.node(name,idx,translation=(0,y,0)))

def add_boxnode(g,children,name,size,center,mat):
    p,f=box(*size,center=(0,0,0));p=[(x+center[0],y+center[1],z+center[2]) for x,y,z in p];mi=g.mesh(name,p,f,mat);children.append(g.node(name,mi))

def leaf_geom(r, side, broken=False):
    # thin, softened trapezoid covering one half of the aperture; local hinge at origin
    outer=r*0.79; inner=r*0.015; zedge=r*0.37
    if side=='left': pts=[(0,-zedge),(0,zedge),(outer,zedge*0.44),(outer,-zedge*0.44)]
    else: pts=[(0,-zedge),(0,zedge),(-outer,zedge*0.44),(-outer,-zedge*0.44)]
    if broken: pts=[(x*.76,z*.78) for x,z in pts]
    # thin plate along Y. Explicit double faces/normals.
    th=r*.06;p=[]
    for yy in (-th/2,th/2):p.extend([(x,yy,z) for x,z in pts])
    f=[(0,1,2),(0,2,3),(4,6,5),(4,7,6)]
    for i in range(4):j=(i+1)%4;f.extend([(i,j,4+j),(i,4+j,4+i)])
    n=[]
    for x,y,z in p:n.append((0,-1 if y<0 else 1,0))
    return p,f,n

def quat_z(deg):
    a=math.radians(deg)/2;return (0,0,math.sin(a),math.cos(a))

def build_mech(path,damaged=False):
    g=GLB('Mechanical bileaflet prosthesis — '+('damaged' if damaged else 'serviceable'))
    steel=g.material('Surgical titanium alloy',(.42,.49,.55,1),.84,.28,maps=(V/'textures/satin_steel_albedo.png',V/'textures/satin_steel_normal.png',V/'textures/satin_steel_roughness.png'))
    fabric=g.material('Woven polyester suture cuff',(.22,.17,.13,1),.02,.82,maps=(V/'textures/woven_cuff_albedo.png',V/'textures/woven_cuff_normal.png',V/'textures/woven_cuff_roughness.png'))
    carbon=g.material('Pyrolytic carbon leaflet',(.055,.075,.082,1),.48,.24,maps=(V/'textures/pyrocarbon_albedo.png',V/'textures/pyrocarbon_normal.png',V/'textures/pyrocarbon_roughness.png'))
    calc=g.material('Calcium deposit',(.72,.68,.54,1),.05,.78)
    root=[];R=.009; tube=.00045
    # toroidal metal shell and textile cuff
    add_ring(g,root,'HousingRing',R-tube,tube,0,steel)
    for k,y in enumerate((-.00055,.00055)):
        p,f,n=annulus(R*.98,R*.78,y-.00025,y+.00025,48);m=g.mesh('SutureCuffBand'+str(k+1),p,f,fabric,n);root.append(g.node('SutureCuffBand'+str(k+1),m))
    # central thin seat
    p,f,n=torus(R*.79,.00017);m=g.mesh('LeafletSeat',p,f,steel,n);root.append(g.node('LeafletSeat',m,translation=(0,.0001,0)))
    for i,(name,x,side) in enumerate((('A',-R*.77,'left'),('B',R*.77,'right'))):
        h=g.node('Hinge'+name,translation=(x,0,0),rotation=quat_z(0))
        lp,lf,ln=leaf_geom(R,side,damaged and name=='B');lm=g.mesh('Leaflet'+name,lp,lf,carbon,ln)
        leaf=g.node('Leaflet'+name,lm);g.nodes[h]['children']=[leaf]
        # small visible hinge pins, oriented as Z-axis bars via torus/cylinder around Z approximated with boxes
        root.append(h)
        p,f=box(.00055,.00062,.00038);p=[(a+x,b,c) for a,b,c in p];mi=g.mesh('HingePin'+name,p,f,steel);root.append(g.node('HingePin'+name,mi))
        if damaged and name=='B':
            # rough deposits around torn leaflet root
            for j,(dx,dz) in enumerate(((-.001,.0012),(-.002,-.0008))):
                p,f,n=torus(.00048,.00017,segments=12,sides=6);mi=g.mesh('Calcification'+name+str(j),p,f,calc,n);root.append(g.node('Calcification'+name+str(j),mi,translation=(x+dx,.00018,dz)))
        # animate closed->open around hinge, keeps handed symmetry
        openq=quat_z(68 if name=='A' else -68)
        g.anim_rot('Open',h,openq)
    # flow direction engraved physical arrow on rim: a small raised arrow aligned +Y shown as a subtly contrasting metal tab
    add_boxnode(g,root,'FlowOrientationKey',(.0015,.0002,.0005),(0,.00063,R-.00035),steel)
    rn=g.node('ValveRoot',children=root);g.save(path,[rn])

def build_bio(path,damaged=False):
    g=GLB('Bioprosthetic trileaflet valve — '+('damaged' if damaged else 'serviceable'))
    steel=g.material('Cobalt chrome stent',(.35,.42,.45,1),.78,.32,maps=(V/'textures/satin_steel_albedo.png',V/'textures/satin_steel_normal.png',V/'textures/satin_steel_roughness.png'))
    fabric=g.material('Fabric covered stent cuff',(.35,.24,.19,1),.02,.86,maps=(V/'textures/woven_cuff_albedo.png',V/'textures/woven_cuff_normal.png',V/'textures/woven_cuff_roughness.png'))
    tissue=g.material('Treated pericardial tissue',(.62,.31,.24,1),.03,.43,double=True,maps=(V/'textures/pericardium_albedo.png',V/'textures/pericardium_normal.png',V/'textures/pericardium_roughness.png'))
    calc=g.material('Calcified tissue',(.78,.71,.57,1),.02,.78)
    root=[];R=.006; tube=.00035
    for k,y in enumerate((-.0005,.00025)):
        p,f,n=annulus(R,R*.73,y-.00024,y+.00024,48);mi=g.mesh('FabricCoveredStent'+str(k+1),p,f,fabric,n);root.append(g.node('FabricCoveredStent'+str(k+1),mi))
    # Three metal commissure posts around the ring plus top rail
    for i in range(3):
        a=math.pi/2+i*2*math.pi/3;x=R*.78*math.cos(a);z=R*.78*math.sin(a)
        p,f,n=torus(.00022,.00012,segments=12,sides=6);mi=g.mesh('PostCollar'+str(i+1),p,f,steel,n);root.append(g.node('PostCollar'+str(i+1),mi,translation=(x,.00035,z)))
        add_boxnode(g,root,'CommissurePost'+str(i+1),(.00038,.0015,.00038),(x,.0003,z),steel)
    # Three scalloped leaflet panels meet at the center. Each panel is separately pivoted at a commissure post.
    for i in range(3):
        a=math.pi/2+i*2*math.pi/3
        hx=R*.78*math.cos(a);hz=R*.78*math.sin(a)
        h=g.node('Hinge'+str(i+1),translation=(hx,.0002,hz))
        # segment from central coaptation line to adjacent commissure posts, local coordinates at hinge
        a0=a-2*math.pi/3/2; a1=a+2*math.pi/3/2
        p0=(R*.75*math.cos(a0)-hx,0,R*.75*math.sin(a0)-hz)
        p1=(R*.75*math.cos(a1)-hx,0,R*.75*math.sin(a1)-hz)
        tip=(-hx,.00022,-hz)
        thickness=.00008
        points=[p0,p1,tip]
        p=[(x,y-thickness/2,z) for x,y,z in points]+[(x,y+thickness/2,z) for x,y,z in points]
        f=[(0,1,2),(3,5,4),(0,3,4),(0,4,1),(1,4,5),(1,5,2),(2,5,3),(2,3,0)]
        n=[(0,-1,0)]*3+[(0,1,0)]*3
        lm=g.mesh('Leaflet'+str(i+1),p,f,tissue,n);leaf=g.node('Leaflet'+str(i+1),lm);g.nodes[h]['children']=[leaf];root.append(h)
        # Open each cusp modestly around its post to expose an unobstructed central flow aperture.
        g.anim_rot('Open',h,quat_z((1 if i%2==0 else -1)*32))
        if damaged and i==1:
            # calcification cluster on one cusp, plus a shorter edge to indicate a torn segment
            for j in range(3):
                p,f,n=torus(.00035+j*.00006,.0001,segments=10,sides=5);mi=g.mesh('Calcification'+str(j+1),p,f,calc,n);root.append(g.node('Calcification'+str(j+1),mi,translation=(hx*.55,.00035,hz*.55)))
    # marked flow key at +Y direction: contrasting metal tab
    add_boxnode(g,root,'FlowOrientationKey',(.0007,.0002,.00045),(0,.00055,R-.00022),steel)
    rn=g.node('ValveRoot',children=root);g.save(path,[rn])

# Tubing and connectors ---------------------------------------------------------
def build_connector(path,female=False):
    g=GLB('Female threaded luer connector' if female else 'Male threaded luer connector')
    steel=g.material('Brushed surgical stainless steel',(.56,.62,.64,1),.82,.27)
    polymer=g.material('Medical polymer collar',(.78,.81,.79,1),.02,.37)
    rubber=g.material('Silicone sealing face',(.20,.25,.24,1),.0,.48)
    root=[]; ro=.004
    # common mating plane Y=0; axis and tube connection on -Y
    p,f,n=annulus(ro,ro*.58,-.002,0,32);mi=g.mesh('ConnectorBody',p,f,steel,n);root.append(g.node('ConnectorBody',mi))
    for i,y in enumerate((-.00045,-.0010,-.00155)):
        p,f,n=torus(ro*(.92 if not female else 1.06),.00032,segments=32,sides=8);mi=g.mesh('Barb'+str(i+1),p,f,steel,n);root.append(g.node('Barb'+str(i+1),mi,translation=(0,y,0)))
    # knurled finger collar
    p,f,n=annulus(.0049,.0038,-.0027,-.0014,36);mi=g.mesh('LockCollar',p,f,polymer,n);root.append(g.node('LockCollar',mi))
    for i in range(12):
        a=i*math.tau/12;x=.00486*math.cos(a);z=.00486*math.sin(a)
        p,f=box(.00036,.0010,.00034);p=[(u+x,v-.00205,w+z) for u,v,w in p];mi=g.mesh('GripRib'+str(i+1),p,f,steel);root.append(g.node('GripRib'+str(i+1),mi))
    if female:
        # female socket lips, bore is open through to +Y
        p,f,n=annulus(.0046,.0031,-.0002,.0010,36);mi=g.mesh('FemaleSocketLip',p,f,steel,n);root.append(g.node('FemaleSocketLip',mi))
        p,f,n=torus(.00325,.00018,segments=32,sides=8);mi=g.mesh('SocketSeal',p,f,rubber,n);root.append(g.node('SocketSeal',mi,translation=(0,.00028,0)))
        # inner female guide threads as fine ring ridges
        for i in range(3):
            p,f,n=torus(.00345,.00011,segments=32,sides=6);mi=g.mesh('InternalThread'+str(i+1),p,f,steel,n);root.append(g.node('InternalThread'+str(i+1),mi,translation=(0,.00005+i*.00028,0)))
    else:
        p,f,n=torus(.00355,.00019,segments=32,sides=8);mi=g.mesh('MaleSealRing',p,f,rubber,n);root.append(g.node('MaleSealRing',mi,translation=(0,-.00005,0)))
        # conical lead tip composed of a short annular lip
        p,f,n=annulus(.0033,.00235,-.0001,.0012,32);mi=g.mesh('MaleLead',p,f,steel,n);root.append(g.node('MaleLead',mi))
    rootn=g.node('ConnectorRoot',children=root);g.save(path,[rootn])

def torus_arc(R,r,start,end,segments=24,sides=8):return torus(R,r,'y',segments,sides,start,end)
def build_clamp(path,opened):
    g=GLB('Tube clamp — '+('open' if opened else 'closed'))
    metal=g.material('Anodized surgical aluminium',(.22,.29,.32,1),.76,.33)
    pad=g.material('Soft jaw liner',(.12,.18,.18,1),.02,.72)
    root=[];r=.0046
    # Two independent semicircular jaws around an 8 mm OD tube; hinges are at outer ±X.
    gap=math.radians(40 if opened else 7)
    arcs=[(gap/2,math.pi-gap/2,'A',-r),(math.pi+gap/2,2*math.pi-gap/2,'B',r)]
    for a0,a1,n,x in arcs:
        h=g.node('Hinge'+n,translation=(x,0,0))
        pp,ff,nn=torus_arc(r-.00035,.00048,a0,a1,segments=24,sides=8)
        # Localize geometry at hinge pivot for stable rotation in Godot.
        pp=[(px-x,py,pz) for px,py,pz in pp]
        mi=g.mesh('Jaw'+n,pp,ff,metal,nn);jaw=g.node('Jaw'+n,mi)
        # contact pad sits on the inside of each jaw
        padp,padf,padn=torus_arc(r-.00082,.00012,a0,a1,segments=24,sides=6);padp=[(px-x,py,pz) for px,py,pz in padp]
        pmi=g.mesh('Jaw'+n+'Liner',padp,padf,pad,padn);padnode=g.node('Jaw'+n+'Liner',pmi)
        g.nodes[h]['children']=[jaw,padnode];root.append(h)
        # thumb wings at gap endpoints
        for k,ang in enumerate((a0,a1)):
            xx=r*math.cos(ang);zz=r*math.sin(ang)
            add_boxnode(g,root,'ThumbWing'+n+str(k+1),(.0010,.0011,.0010),(xx,0,zz),metal)
    rootn=g.node('ClampRoot',children=root);g.save(path,[rootn])

def build_cannula(path):
    g=GLB('Aortic perfusion cannula')
    steel=g.material('Surgical stainless connector',(.46,.54,.56,1),.76,.3)
    polymer=g.material('Medical-grade translucent polymer',(.48,.68,.69,.48),.03,.2,'BLEND',True)
    rubber=g.material('Soft silicone gasket',(.15,.24,.24,1),.01,.6)
    root=[]
    # Overall length 41 mm (Y=-19 mm to +22 mm), +Y points from luer inlet to tapered insertion tip; hollow lumen 2.7 mm.
    p,f,n=cylinder_y(.0021,-.015,.021,32,inner=.00135);mi=g.mesh('CannulaTube',p,f,polymer,n);root.append(g.node('CannulaTube',mi))
    # tapered atraumatic tip rings and distal side ports
    for i in range(4):
        y=.019+i*.00055;r=.00165-i*.00022
        p,f,n=torus(r,.00012,segments=24,sides=6);mi=g.mesh('TipRib'+str(i+1),p,f,polymer,n);root.append(g.node('TipRib'+str(i+1),mi,translation=(0,y,0)))
    # lateral perfusion ports: four short collars around the distal shaft
    for i,a in enumerate((0,math.pi/2,math.pi,3*math.pi/2)):
        x=.0017*math.cos(a);z=.0017*math.sin(a)
        p,f,n=torus(.00024,.00010,axis='x',segments=10,sides=5);mi=g.mesh('PerfusionPort'+str(i+1),p,f,polymer,n);root.append(g.node('PerfusionPort'+str(i+1),mi,translation=(x,.018,z)))
    # proximal locking collar and gasket
    p,f,n=annulus(.0042,.0020,-.019,-.015,32);mi=g.mesh('LuerHub',p,f,steel,n);root.append(g.node('LuerHub',mi))
    p,f,n=torus(.0035,.00042,segments=32,sides=8);mi=g.mesh('HubGrip',p,f,steel,n);root.append(g.node('HubGrip',mi,translation=(0,-.016,0)))
    p,f,n=torus(.0021,.00030,segments=28,sides=8);mi=g.mesh('SiliconeGasket',p,f,rubber,n);root.append(g.node('SiliconeGasket',mi,translation=(0,-.0146,0)))
    for i in range(3):
        p,f,n=torus(.0026,.00020,segments=24,sides=6);mi=g.mesh('ConnectorBarb'+str(i+1),p,f,steel,n);root.append(g.node('ConnectorBarb'+str(i+1),mi,translation=(0,-.018+i*.0012,0)))
    rootn=g.node('CannulaRoot',children=root);g.save(path,[rootn])

# deterministic tileable maps, intentionally subtle and procedural
random.seed(701)
def texture_set(folder,prefix,size,kind):
    folder.mkdir(parents=True,exist_ok=True);w,h=size
    base={'glass':(122,163,166),'steel':(118,133,139),'fabric':(94,73,60),'tissue':(142,69,60)}[kind]
    im=Image.new('RGB',(w,h));pix=im.load()
    # periodic noise and a fine axial pattern avoid seams; no photorealistic baked scene.
    for y in range(h):
        for x in range(w):
            wave=math.sin(2*math.pi*x/max(1,w/9))*3 + math.cos(2*math.pi*y/max(1,h/7))*2
            grain=random.uniform(-4,4)
            if kind=='fabric': grain += (3 if (x+y)%5==0 else -1)
            if kind=='glass': grain += 2*math.sin(2*math.pi*y/max(1,h/3))
            pix[x,y]=tuple(max(0,min(255,int(c+wave+grain))) for c in base)
    im.save(folder/(prefix+'_albedo.png'),optimize=True)
    # OpenGL tangent-space normal map, near-flat micro structure.
    no=Image.new('RGB',(w,h));np=no.load()
    for y in range(h):
        for x in range(w):
            v=128+int(4*math.sin(x*math.tau/max(1,w/8))*math.cos(y*math.tau/max(1,h/6)))
            np[x,y]=(v,128,255)
    no.save(folder/(prefix+'_normal.png'),optimize=True)
    rough=Image.new('L',(w,h),{'glass':34,'steel':80,'fabric':214,'tissue':110}[kind]);rough.save(folder/(prefix+'_roughness.png'),optimize=True)

def tube_maps():
    w,h=512,128
    # Subtle translucent, cool vascular film with a wet central specular band.
    im=Image.new('RGBA',(w,h));p=im.load()
    for y in range(h):
        band=math.exp(-((y-h*.48)/(h*.18))**2)
        for x in range(w):
            n=math.sin(x*math.tau/48)*2+math.cos(x*math.tau/17)*1.1
            p[x,y]=(max(0,min(255,int(89+18*band+n))),max(0,min(255,int(136+20*band+n))),max(0,min(255,int(142+22*band+n))),255)
    im.save(T/'tube_glass_tile.png',optimize=True)
    no=Image.new('RGB',(w,h));q=no.load()
    for y in range(h):
        for x in range(w):q[x,y]=(128+int(3*math.sin(x*.08)),128+int(7*math.cos(y*.13)),255)
    no.save(T/'tube_glass_tile_normal.png',optimize=True)
    Image.new('L',(w,h),38).save(T/'tube_glass_tile_roughness.png',optimize=True)

# valve textures: shared 2K tile maps, referenced by material note for authoring pipeline
texture_set(V/'textures','satin_steel',(2048,2048),'steel')
texture_set(V/'textures','woven_cuff',(2048,2048),'fabric')
texture_set(V/'textures','pyrocarbon',(2048,2048),'steel')
texture_set(V/'textures','pericardium',(2048,2048),'tissue')
tube_maps()

build_mech(V/'mech_bileaflet.glb',False)
build_mech(V/'mech_bileaflet_damaged.glb',True)
build_bio(V/'bio_trileaflet.glb',False)
build_bio(V/'bio_trileaflet_damaged.glb',True)
build_connector(T/'connector_male.glb',False)
build_connector(T/'connector_female.glb',True)
build_clamp(T/'clamp_open.glb',True)
build_clamp(T/'clamp_closed.glb',False)
build_cannula(T/'cannula.glb')
print('wrote',len(list(V.glob('*.glb'))),'valves and',len(list(T.glob('*.glb'))),'tube GLBs')
