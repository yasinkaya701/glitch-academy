#!/usr/bin/env python3
"""Deterministic, hand-authored educational heart GLB generator. Run with Python 3 + numpy + Pillow."""
from pathlib import Path
import json, math, struct, random, io
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parent
TOOL=ROOT.parent/'tools'
# Coordinates are metres in the original heart model's +Y-up frame.
SPOTS={'RA':(-.0223,.0697,.0076),'RV':(-.0133,.0339,.0198),'LA':(.0211,.0767,.0080),'LV':(.0198,.0298,.0221)}
VALVES={'Tricuspid':(-.0204,.0559,.0159),'Mitral':(.0184,.0582,.0189),'Aortic':(-.0083,.0888,.0165),'Pulmonary':(.0018,.0752,.0160)}
VALVE_DIR={'Tricuspid':(.12,-1.0,.18),'Mitral':(.10,-1.0,.14),'Aortic':(.44,.9,0.0),'Pulmonary':(.60,.8,0.0)}
VESSELS={
 'Aorta':[(.0023,.1177,.0139),(.0020,.128,.014),(.002,.137,.014),(.007,.141,.014),(.012,.139,.014)],
 'PulmonaryTrunk':[(.0178,.0973,.0194),(.023,.106,.019),(.027,.116,.018),(.025,.125,.018),(.021,.128,.018)],
 'SVC':[(-.021,.1085,.0139),(-.021,.119,.014),(-.021,.129,.014),(-.021,.136,.014)],
 'IVC':[(-.0223,.0697,.0076),(-.024,.061,.008),(-.026,.051,.009),(-.027,.043,.01)],
 'PulmonaryVeinL':[(.0349,.0878,.0095),(.043,.092,.009),(.050,.095,.009),(.057,.098,.009)],
 'PulmonaryVeinR':[(.0211,.0767,.008),(.030,.078,.008),(.039,.080,.008),(.047,.082,.008)],
}
# palette
MATS={
 'Myocardium':('#8e3f43',.72),'AtriumWall':('#8e3f43',.78),'BloodDeoxygenated':('#244967',.24),'BloodOxygenated':('#7a2836',.22),
 'Endocardium':('#d87b73',.54),'VesselWall':('#a84c4c',.7),'Leaflet':('#754247',.82),'Tendon':('#c9ac92',.72),'Annulus':('#54262d',.85),'CavityLip':('#54262d',.88),'Tool':('#687785',.32),'Jaw':('#9ba5aa',.28)}
def ellipsoid(center,radii,lat=20,lon=28,inner=False):
    p=[]; uv=[]; ix=[]
    for i in range(lat+1):
      th=math.pi*i/lat
      for j in range(lon+1):
        ph=2*math.pi*j/lon
        p.append((radii[0]*math.sin(th)*math.cos(ph),radii[1]*math.cos(th),radii[2]*math.sin(th)*math.sin(ph)))
        uv.append((j/lon,i/lat))
    for i in range(lat):
      for j in range(lon):
        a=i*(lon+1)+j;b=a+lon+1
        # Outward-facing winding; the old order made the room shells appear back-face culled.
        ix.extend((a,a+1,b,a+1,b+1,b))
    if inner: ix=[x for k in range(0,len(ix),3) for x in (ix[k],ix[k+2],ix[k+1])]
    return np.array(p),np.array(uv),np.array(ix,dtype=np.uint32)

def open_chamber(radii, lat=28, lon=40, z_limit=.12, reverse=False):
    """Ellipsoid bowl with its anterior (+Z) cap removed for a visible cutaway lumen."""
    p, uv, full = ellipsoid((0,0,0), radii, lat, lon)
    kept=[]
    for tri in full.reshape(-1,3):
        if float(p[tri,2].mean()) <= radii[2]*z_limit:
            if reverse:
                kept.extend((tri[0],tri[2],tri[1]))
            else:
                kept.extend(tri)
    return p, uv, np.asarray(kept,dtype=np.uint32)

def connected_heart_mesh():
    """Continuous tapered myocardium underlay, broad at the ventricles and narrowed at the apex."""
    profile=[
      (-.005,.0015,.0015,.008),(.006,.011,.010,.006),(.023,.023,.018,.003),
      (.036,.034,.023,.001),(.050,.041,.026,0),(.066,.044,.026,0),
      (.080,.041,.024,0),(.094,.034,.020,.001),(.106,.025,.016,.002),
      (.115,.017,.012,.002),(.121,.009,.008,.002),
    ]
    # Catmull-Rom interpolation smooths the silhouette before triangulation.
    dense=[]
    for i in range(len(profile)-1):
      p0=np.asarray(profile[max(0,i-1)],float);p1=np.asarray(profile[i],float)
      p2=np.asarray(profile[i+1],float);p3=np.asarray(profile[min(len(profile)-1,i+2)],float)
      for step in range(18):
        t=step/18;t2=t*t;t3=t2*t
        q=.5*((2*p1)+(-p0+p2)*t+(2*p0-5*p1+4*p2-p3)*t2+(-p0+3*p1-3*p2+p3)*t3)
        q[0]=max(q[0],dense[-1][0]+1e-5 if dense else profile[0][0])
        dense.append(tuple(q))
    dense.append(profile[-1]);profile=dense
    seg=256;verts=[];uv=[]
    zcenter=-.012
    for ri,(y,rx,rz,cx) in enumerate(profile):
      for j in range(seg):
        a=2*math.pi*j/seg
        verts.append((cx+rx*math.cos(a),y,zcenter+rz*math.sin(a)))
        uv.append((j/seg,ri/(len(profile)-1)))
    faces=[]
    # Four true apertures are cut only through the anterior face; the posterior shell stays continuous.
    windows={'RA':(.0090,.0120),'RV':(.0120,.0205),'LA':(.0090,.0120),'LV':(.0135,.0240)}
    def in_window(point):
      x,y,z=point
      if z <= zcenter: return False
      for room,(rx,ry) in windows.items():
        cx,cy,_=SPOTS[room]
        if ((x-cx)/rx)**2+((y-cy)/ry)**2 < 1.0:
          return True
      return False
    for ri in range(len(profile)-1):
      for j in range(seg):
        a=ri*seg+j;b=ri*seg+(j+1)%seg;c=(ri+1)*seg+j;d=(ri+1)*seg+(j+1)%seg
        # Outward around the perimeter.
        for tri in ((a,c,b),(b,c,d)):
          if not in_window(np.mean([verts[k] for k in tri],axis=0)):
            faces.extend(tri)
    # Small top and apex caps close the outer tissue envelope.
    bottom=len(verts);verts.append((profile[0][3],profile[0][0],zcenter));uv.append((.5,0.0))
    top=len(verts);verts.append((profile[-1][3],profile[-1][0],zcenter));uv.append((.5,1.0))
    for j in range(seg):
      k=(j+1)%seg;faces.extend((bottom,j,k,top,(len(profile)-1)*seg+k,(len(profile)-1)*seg+j))
    return np.asarray(verts),np.asarray(uv),np.asarray(faces,dtype=np.uint32)
def tube(points,ro=.004,ri=.0025,sides=20):
    pts=np.array(points,float); rings=[]; uv=[]; idx=[]
    for k,c in enumerate(pts):
      tangent=pts[min(k+1,len(pts)-1)]-pts[max(0,k-1)]; tangent/=np.linalg.norm(tangent)
      ref=np.array([0.,0.,1.]) if abs(tangent[2])<.9 else np.array([1.,0.,0.])
      u=np.cross(tangent,ref);u/=np.linalg.norm(u);v=np.cross(tangent,u)
      for r in (ro,ri):
       for j in range(sides+1):
        a=2*math.pi*j/sides;rings.append(c+r*(math.cos(a)*u+math.sin(a)*v));uv.append((j/sides,k/(len(pts)-1)))
    stride=2*(sides+1)
    # surfaces, inner winding reversed; vessel mouths stay open
    for k in range(len(pts)-1):
      for shell in range(2):
       base=k*stride+shell*(sides+1); nxt=(k+1)*stride+shell*(sides+1)
       for j in range(sides):
        a=base+j;b=nxt+j
        tri=(a,a+1,b,a+1,b+1,b)
        idx.extend(tri if shell==0 else tuple(x for t in range(0,6,3) for x in (tri[t],tri[t+2],tri[t+1])))
    # bridge inside/outside lips at vessel mouths for wall thickness
    for k in (0,len(pts)-1):
      b=k*stride
      for j in range(sides):
       a=b+j;c=b+(sides+1)+j;idx.extend((a,c,a+1,c,c+1,a+1))
    return np.array(rings),np.array(uv),np.array(idx,dtype=np.uint32)
def ring(center,radius,tube_r,plane='y',segments=32):
    # toroidal annulus, plane normal default Y
    p=[];uv=[];ix=[]
    for i in range(segments+1):
      a=2*math.pi*i/segments
      for j in range(10):
       b=2*math.pi*j/10
       rr=radius+tube_r*math.cos(b); h=tube_r*math.sin(b)
       p.append((rr*math.cos(a),rr*math.sin(a),h));uv.append((i/segments,j/10))
    for i in range(segments):
     for j in range(10):
      a=i*10+j;b=i*10+(j+1)%10;c=(i+1)*10+j;d=(i+1)*10+(j+1)%10;ix.extend((a,c,b,b,c,d))
    return np.array(p),np.array(uv),np.array(ix,dtype=np.uint32)

def quat_from_to(source,target):
    """GLTF quaternion that rotates a local +Z valve-plane normal onto blood flow."""
    a=np.asarray(source,dtype=float);a/=np.linalg.norm(a)
    b=np.asarray(target,dtype=float);b/=np.linalg.norm(b)
    dot=float(np.clip(np.dot(a,b),-1.0,1.0))
    if dot < -0.999999:
      return (0.0,1.0,0.0,0.0)
    xyz=np.cross(a,b);q=np.array((xyz[0],xyz[1],xyz[2],1.0+dot),dtype=float)
    q/=np.linalg.norm(q)
    return tuple(float(v) for v in q)

def heart_front_z(x,y):
    profile=[(-.005,.0015,.0015,.008),(.006,.011,.010,.006),(.023,.023,.018,.003),(.036,.034,.023,.001),(.050,.041,.026,0),(.066,.044,.026,0),(.080,.041,.024,0),(.094,.034,.020,.001),(.106,.025,.016,.002),(.115,.017,.012,.002),(.121,.009,.008,.002)]
    if profile[0][0] <= y <= profile[-1][0]:
      i=next((i for i in range(len(profile)-1) if profile[i][0] <= y <= profile[i+1][0]),len(profile)-2)
      p0=np.asarray(profile[max(0,i-1)],float);p1=np.asarray(profile[i],float);p2=np.asarray(profile[i+1],float);p3=np.asarray(profile[min(len(profile)-1,i+2)],float)
      t=(y-p1[0])/(p2[0]-p1[0]);t2=t*t;t3=t2*t
      q=.5*((2*p1)+(-p0+p2)*t+(2*p0-5*p1+4*p2-p3)*t2+(-p0+3*p1-3*p2+p3)*t3)
      rx,rz,cx=q[1:];return -.012+rz*math.sqrt(max(.01,1-((x-cx)/rx)**2))
    return .004

def oval_lip(rx,ry,tube_r,cx,cy,segments=96,sides=10):
    p=[];uv=[];ix=[]
    for i in range(segments+1):
      a=2*math.pi*i/segments;nx=math.cos(a)/rx;ny=math.sin(a)/ry;nl=math.hypot(nx,ny);nx/=nl;ny/=nl
      for j in range(sides):
       b=2*math.pi*j/sides;rad=tube_r*math.cos(b);z=tube_r*math.sin(b)
       x=rx*math.cos(a)+rad*nx;y=ry*math.sin(a)+rad*ny
       p.append((x,y,heart_front_z(cx+x,cy+y)+z));uv.append((i/segments,j/sides))
    for i in range(segments):
      for j in range(sides):
       a=i*sides+j;b=i*sides+(j+1)%sides;c=(i+1)*sides+j;d=(i+1)*sides+(j+1)%sides
       ix.extend((a,c,b,b,c,d))
    return np.asarray(p),np.asarray(uv),np.asarray(ix,dtype=np.uint32)
def leaflet(center,angle,radius,tilt=0):
    # Thin curved triangular cusp in the anterior facing valve plane; hinge at annular rim.
    verts=[];uv=[];idx=[];steps=8
    for i in range(steps+1):
      t=i/steps
      for j in range(5):
       s=j/4
       rr=radius*(.55+.45*s)*t
       a=angle+(s-.5)*.95
       verts.append((rr*math.cos(a),rr*math.sin(a),tilt+.0018*math.sin(t*math.pi)));uv.append((s,t))
    for i in range(steps):
     for j in range(4):
      a=i*5+j;b=a+5;idx.extend((a,a+1,b,b,a+1,b+1))
    return np.array(verts),np.array(uv),np.array(idx,dtype=np.uint32)
class G:
 def __init__(self):self.nodes=[];self.parents=[];self.meshes=[];self.materials=[];self.bin=bytearray();self.views=[];self.access=[];self.matidx={};self.tex=[];self.images=[];self.textures=[]
 def add_mat(self,name):
  if name not in self.matidx:
   col,rough=MATS[name];c=[int(col[i:i+2],16)/255 for i in (1,3,5)]
   alpha=.82 if name in ('BloodDeoxygenated','BloodOxygenated') else 1.0
   mat={'name':name,'pbrMetallicRoughness':{'baseColorFactor':c+[alpha],'metallicFactor':0.0,'roughnessFactor':rough}}
   if name in ('BloodDeoxygenated','BloodOxygenated'):
    mat['alphaMode']='BLEND';mat['doubleSided']=True
   elif name in ('Leaflet','Endocardium','CavityLip'):
    mat['doubleSided']=True
   key={'Myocardium':'myocardium','AtriumWall':'myocardium','VesselWall':'vessel_wall'}.get(name)
   if key:
    mat['pbrMetallicRoughness']['baseColorTexture']={'index':self.texture(key+'_albedo.png')}
    mat['normalTexture']={'index':self.texture(key+'_normal.png')}
    mat['pbrMetallicRoughness']['metallicRoughnessTexture']={'index':self.texture(key+'_roughness.png')}
   self.matidx[name]=len(self.materials);self.materials.append(mat)
  return self.matidx[name]
 def texture(self,filename):
  if filename in self.tex:return self.tex.index(filename)
  b=io.BytesIO();Image.open(ROOT/filename).save(b,format='PNG')
  while len(self.bin)%4:self.bin.append(0)
  off=len(self.bin);raw=b.getvalue();self.bin.extend(raw)
  vi=len(self.views);self.views.append({'buffer':0,'byteOffset':off,'byteLength':len(raw)})
  ii=len(self.images);self.images.append({'name':filename,'bufferView':vi,'mimeType':'image/png'})
  ti=len(self.textures);self.textures.append({'source':ii,'sampler':0});self.tex.append(filename);return ti
 def acc(self,data,typ,comp,target=None):
  while len(self.bin)%4:self.bin.append(0)
  off=len(self.bin);raw=data.tobytes(order='C');self.bin.extend(raw);vi=len(self.views);v={'buffer':0,'byteOffset':off,'byteLength':len(raw)}
  if target:v['target']=target
  self.views.append(v);count=len(data);a={'bufferView':vi,'componentType':comp,'count':count,'type':typ}
  if typ=='VEC3' and comp==5126:a['min']=data.min(axis=0).astype(float).tolist();a['max']=data.max(axis=0).astype(float).tolist()
  ai=len(self.access);self.access.append(a);return ai
 def mesh(self,name,parts,material,translation=(0,0,0),extras=None,parent=None,rotation=(0,0,0,1),scale=(1,1,1)):
  prim=[]
  for p,uv,ix,mat in parts:
   p=np.asarray(p,dtype=np.float32);uv=np.asarray(uv,dtype=np.float32);ix=np.asarray(ix,dtype=np.uint32)
   # Smooth vertex normals from triangle accumulation.
   n=np.zeros_like(p)
   for tri in ix.reshape(-1,3):
    a,b,c=p[tri];nn=np.cross(b-a,c-a);n[tri]+=nn
   lens=np.linalg.norm(n,axis=1);n/=np.maximum(lens[:,None],1e-12)
   pos=self.acc(p,'VEC3',5126,34962);nor=self.acc(n,'VEC3',5126,34962);tex=self.acc(uv,'VEC2',5126,34962);ind=self.acc(ix,'SCALAR',5125,34963)
   prim.append({'attributes':{'POSITION':pos,'NORMAL':nor,'TEXCOORD_0':tex},'indices':ind,'material':self.add_mat(mat or material),'mode':4})
  mi=len(self.meshes);self.meshes.append({'name':name,'primitives':prim});ni=len(self.nodes);node={'name':name,'mesh':mi,'translation':list(translation)}
  if tuple(rotation)!=(0,0,0,1):node['rotation']=list(rotation)
  if tuple(scale)!=(1,1,1):node['scale']=list(scale)
  if extras:node['extras']=extras
  self.nodes.append(node);self.parents.append(parent);return ni
 def empty(self,name,translation,extras=None,parent=None,rotation=(0,0,0,1),scale=(1,1,1)):
  ni=len(self.nodes);node={'name':name,'translation':list(translation)}
  if tuple(rotation)!=(0,0,0,1):node['rotation']=list(rotation)
  if tuple(scale)!=(1,1,1):node['scale']=list(scale)
  if extras:node['extras']=extras
  self.nodes.append(node);self.parents.append(parent);return ni
 def append_reference_heart(self,path):
  """Embed the bundled CC0 cutaway GLB as the visible anatomical base."""
  raw=path.read_bytes();json_len=struct.unpack_from('<I',raw,12)[0];doc=json.loads(raw[20:20+json_len]);bin_start=20+json_len+8;src_bin=raw[bin_start:bin_start+doc['buffers'][0]['byteLength']]
  while len(self.bin)%4:self.bin.append(0)
  byte_base=len(self.bin);self.bin.extend(src_bin);view_base=len(self.views)
  for view in doc.get('bufferViews',[]):
   view=dict(view);view['buffer']=0;view['byteOffset']=view.get('byteOffset',0)+byte_base;self.views.append(view)
  acc_base=len(self.access)
  for accessor in doc.get('accessors',[]):
   accessor=dict(accessor);accessor['bufferView']=accessor.get('bufferView',0)+view_base;self.access.append(accessor)
  image_base=len(self.images)
  for image in doc.get('images',[]):
   image=dict(image);image['bufferView']=image.get('bufferView',0)+view_base;self.images.append(image)
  texture_base=len(self.textures)
  for texture in doc.get('textures',[]):
   texture=dict(texture);texture['source']=texture['source']+image_base;self.textures.append(texture)
  material_base=len(self.materials)
  for material in doc.get('materials',[]):
   material=json.loads(json.dumps(material))
   for pbrkey in ('baseColorTexture','metallicRoughnessTexture'):
    if pbrkey in material.get('pbrMetallicRoughness',{}):material['pbrMetallicRoughness'][pbrkey]['index']+=texture_base
   for texkey in ('normalTexture','occlusionTexture','emissiveTexture'):
    if texkey in material:material[texkey]['index']+=texture_base
   self.materials.append(material)
  mesh_base=len(self.meshes)
  for mesh in doc.get('meshes',[]):
   mesh=json.loads(json.dumps(mesh))
   for primitive in mesh.get('primitives',[]):
    for semantic,index in primitive['attributes'].items():primitive['attributes'][semantic]=index+acc_base
    if 'indices' in primitive:primitive['indices']+=acc_base
    if 'material' in primitive:primitive['material']+=material_base
   self.meshes.append(mesh)
  for node in doc.get('nodes',[]):
   if 'mesh' in node:
    ni=self.empty('HeartBody',(0,0,0),extras=node.get('extras',{'license':'CC0-1.0','source':'stations/heart/assets/model/heart_cutaway_light.glb'}));self.nodes[ni]['mesh']=node['mesh']+mesh_base
 def write(self,path):
  kids=[[] for _ in self.nodes];roots=[]
  for i,parent in enumerate(self.parents):
   if parent is None:roots.append(i)
   else:kids[parent].append(i)
  for i,children in enumerate(kids):
   if children:self.nodes[i]['children']=children
  doc={'asset':{'version':'2.0','generator':'build_heart.py · original procedural anatomy'},'scene':0,'scenes':[{'nodes':roots}],'nodes':self.nodes,'meshes':self.meshes,'materials':self.materials,'buffers':[{'byteLength':len(self.bin)}],'bufferViews':self.views,'accessors':self.access,'images':self.images,'textures':self.textures,'samplers':[{'magFilter':9729,'minFilter':9987,'wrapS':10497,'wrapT':10497}]}
  js=json.dumps(doc,separators=(',',':')).encode();js+=b' '*((-len(js))%4);bb=bytes(self.bin)+b'\0'*((-len(self.bin))%4);total=12+8+len(js)+8+len(bb)
  path.parent.mkdir(parents=True,exist_ok=True)
  with path.open('wb') as f:f.write(struct.pack('<4sII',b'glTF',2,total));f.write(struct.pack('<I4s',len(js),b'JSON'));f.write(js);f.write(struct.pack('<I4s',len(bb),b'BIN\0'));f.write(bb)
def build(leaky=None,tool=False):
 g=G()
 if tool:
  # Educational demonstration clamp: two independent hinged handles/jaws, no contact with anatomy.
  for nm,sign in [('JawA',-1),('JawB',1)]:
   g.mesh(nm,[( *ellipsoid((0,0,0),(.018,.003,.003),8,16), 'Tool')], 'Tool',translation=(sign*.012,0,0),extras={'pivot':'hinge at local origin','purpose':'demonstration prop; not for clinical use'})
   g.empty(nm+'HingePivot',(sign*.012,0,0))
  g.mesh('HandleA',[( *ellipsoid((0,0,0),(.002,.035,.002),8,12), 'Tool')],'Tool',translation=(-.015,-.033,0))
  g.mesh('HandleB',[( *ellipsoid((0,0,0),(.002,.035,.002),8,12), 'Tool')],'Tool',translation=(.015,-.033,0))
  g.write(TOOL/'clamp_vessel.glb');return
 # Preserve the anatomically credible CC0 cutaway as the visible base; named intervention meshes sit in its cavities.
 g.append_reference_heart(ROOT.parent/'model'/'heart_cutaway_light.glb')
 # Cavity walls are anterior-open bowls; the old closed ellipsoids completely hid their blood volumes.
 # Their overlapping lower/upper envelopes meet at the septal and atrioventricular planes.
 specs={'RA':((.012,.016,.010),'AtriumWall'),'RV':((.016,.026,.013),'Myocardium'),'LA':((.012,.016,.010),'AtriumWall'),'LV':((.018,.030,.016),'Myocardium')}
 for room,((rx,ry,rz),mat) in specs.items():
  center=SPOTS[room]
  # The cavity lining is a recessed posterior bowl inside each opening, sharing the continuous body's material.
  # It terminates before the anterior surface, so it cannot read as a cup pasted onto the heart.
  wall=open_chamber((rx,ry,rz),lat=48,lon=64,z_limit=-.10)
  g.mesh('Wall'+room,[(*wall,mat)],mat,translation=center,extras={'pivot':'room center','unit':'m','role':'recessed cavity wall'})
  # Broad, shallow blood volume sits just behind the anterior opening. Uniform
  # scaling from .35–1.0 leaves a visible low-fill pool while staying inside the lining.
  blood=ellipsoid((0,0,0),(rx*.78,ry*.72,rz*.68),28,36)
  bm='BloodDeoxygenated' if room in ('RA','RV') else 'BloodOxygenated'
  front=heart_front_z(center[0],center[1])
  blood_center=(center[0],center[1],front-rz*.72)
  g.mesh('Blood'+room,[(*blood,bm)],bm,translation=blood_center,extras={'pivot':'cavity center; scale uniformly for 35–100% fill','fill_range':[0.35,1.0],'unit':'m'})
  lip_sizes={'RA':(.00935,.01235),'RV':(.01235,.02085),'LA':(.00935,.01235),'LV':(.01385,.02435)}
  lrx,lry=lip_sizes[room]
  g.mesh('CavityLip'+room,[(*oval_lip(lrx,lry,.00035,center[0],center[1]),'CavityLip')],'CavityLip',translation=(center[0],center[1],0),extras={'role':'cut myocardium edge'})
 # Each vessel starts inside the shared myocardium; its first open end is buried, not floating outside.
 roots={
  'Aorta':(.0023,.100,-.020),'PulmonaryTrunk':(.012,.080,-.020),
  'SVC':(-.021,.096,-.020),'IVC':(-.0223,.060,-.020),
  'PulmonaryVeinL':(.025,.086,-.020),'PulmonaryVeinR':(.0211,.0767,-.020),
 }
 # Vessels use an open lumen, open mouths and a visible annular wall cross-section.
 radii={'Aorta':.0055,'PulmonaryTrunk':.0052,'SVC':.0045,'IVC':.0047,'PulmonaryVeinL':.0034,'PulmonaryVeinR':.0034}
 for name,base_path in VESSELS.items():
  path=[roots[name]]+base_path
  center=np.array(path[0]);local=(np.array(path)-center).tolist();ro=radii[name];parts=[(*tube(local,ro,ro*.66), 'VesselWall')]
  g.mesh(name,parts,'VesselWall',translation=tuple(center),extras={'lumen':'open','wall_thickness_m':round(ro*.34,5)})
  g.empty('ClampPoint',tuple(path[-1]),extras={'vessel':name,'purpose':'interaction attachment point'})
 # Each annulus plane is normal to its own physiological flow vector. Local +Z
 # is the valve normal; AV roots point down, semilunar roots point up/outward.
 counts={'Tricuspid':3,'Mitral':2,'Aortic':3,'Pulmonary':3};rads={'Tricuspid':.0092,'Mitral':.0085,'Aortic':.0058,'Pulmonary':.0056}
 for valve,c in VALVES.items():
  ctr=np.array(c);r=rads[valve];q=quat_from_to((0,0,1),VALVE_DIR[valve])
  frame=g.empty('Valve'+valve+'Frame',tuple(ctr),extras={'flow_direction':list(VALVE_DIR[valve]),'plane_normal':'aligned to flow'},rotation=q)
  g.mesh('Annulus'+valve,[(*ring((0,0,0),r,.0010),'Annulus')],'Annulus',extras={'pivot':'annulus center','unit':'m'},parent=frame)
  for i in range(counts[valve]):
   a=2*math.pi*i/counts[valve]+math.pi/counts[valve]
   hinge=np.array((r*math.cos(a),r*math.sin(a),0))
   # leaky artifact leaves one cusp partly open by shifting its free edge axially.
   tilt=(.0040 if leaky==valve and i==0 else 0.)
   local,uv,ix=leaflet((0,0,0),a,r*.84,tilt)
   # Child transform preserves the authored pose while making the hinge a functional pivot.
   hidx=g.empty('Hinge'+valve+str(i+1),tuple(hinge),extras={'pivot':'leaflet hinge'},parent=frame)
   lname=f'Leaflet{valve}{i+1}';g.mesh(lname,[(local,uv,ix,'Leaflet')],'Leaflet',translation=tuple(-hinge),extras={'hinge':'Hinge'+valve+str(i+1),'closure':'partial' if tilt else 'coaptation'},parent=hidx)
  # Only AV valves have chordae; use two short, clear ties to papillary muscles near the ventricular roof.
  if valve in ('Tricuspid','Mitral'):
   vent=np.array(SPOTS['RV' if valve=='Tricuspid' else 'LV'])
   for i in range(2):
    pap=np.array((vent[0]+(-.003 if i==0 else .003),ctr[1]-.008,vent[2]+.003))
    g.mesh(f'Papillary{valve}{i+1}',[(*ellipsoid((0,0,0),(.0022,.004,.0022),10,14),'Myocardium')],'Myocardium',translation=tuple(pap),extras={'role':'papillary muscle'})
    a=2*math.pi*i/2+math.pi/2;tip=ctr+np.array((r*.80*math.cos(a),r*.80*math.sin(a),0))
    pts=[tip,(tip+pap)*.5,pap]
    g.mesh(f'Chordae{valve}{i+1}',[(*tube([tuple(x-ctr) for x in pts],.00024,.00013,6),'Tendon')],'Tendon',translation=tuple(ctr),extras={'role':'tendon'})
 # give variants stable identical structural node names; only leaflet free edge geometry differs
 suffix=f'_{leaky.lower()}_leaky' if leaky else ''
 g.write(ROOT/f'heart_segmented{suffix}.glb')
if __name__=='__main__':
 # Reproducible subtle procedural 2K PBR maps; maps have no baked text or anatomical markings.
 rng=np.random.default_rng(731)
 def maps(prefix,base):
  n=2048; noise=rng.normal(0,3,(n,n,1)); arr=np.clip(np.array(base,dtype=float)[None,None,:]+noise,0,255).astype('uint8');Image.fromarray(arr,'RGB').save(ROOT/f'{prefix}_albedo.png',optimize=True)
  normal=np.zeros((n,n,3),dtype=np.uint8);normal[:]=[128,128,255];Image.fromarray(normal,'RGB').save(ROOT/f'{prefix}_normal.png',optimize=True)
  rough=np.empty((n,n,3),dtype=np.uint8);rough[:]=[0,190,0];Image.fromarray(rough,'RGB').save(ROOT/f'{prefix}_roughness.png',optimize=True)
 maps('myocardium',(142,63,67));maps('vessel_wall',(168,76,76))
 build();
 for v in VALVES:build(v)
 build(tool=True)
