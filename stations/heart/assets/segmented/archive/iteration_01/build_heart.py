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
 'Myocardium':('#8e3f43',.72),'AtriumWall':('#a65657',.78),'BloodDeoxygenated':('#4a5fa8',.2),'BloodOxygenated':('#d8352f',.2),
 'Endocardium':('#d87b73',.54),'VesselWall':('#a84c4c',.7),'Leaflet':('#e0b5a2',.43),'Tendon':('#e9d5bb',.5),'Annulus':('#b87c65',.5),'Tool':('#687785',.32),'Jaw':('#9ba5aa',.28)}
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
        a=i*(lon+1)+j;b=a+lon+1;ix.extend((a,b,a+1,a+1,b,b+1))
    if inner: ix=[x for k in range(0,len(ix),3) for x in (ix[k],ix[k+2],ix[k+1])]
    return np.array(p),np.array(uv),np.array(ix,dtype=np.uint32)
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
        tri=(a,b,a+1,a+1,b,b+1)
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
       p.append((rr*math.cos(a),h,rr*math.sin(a)));uv.append((i/segments,j/10))
    for i in range(segments):
     for j in range(10):
      a=i*10+j;b=i*10+(j+1)%10;c=(i+1)*10+j;d=(i+1)*10+(j+1)%10;ix.extend((a,c,b,b,c,d))
    return np.array(p),np.array(uv),np.array(ix,dtype=np.uint32)
def leaflet(center,angle,radius,tilt=0):
    # Thin curved triangular cusp in the valve plane; hinge at annular rim.
    verts=[];uv=[];idx=[];steps=8
    for i in range(steps+1):
      t=i/steps
      for j in range(5):
       s=j/4
       rr=radius*(.55+.45*s)*t
       a=angle+(s-.5)*.95
       verts.append((rr*math.cos(a),tilt+.0018*math.sin(t*math.pi),rr*math.sin(a)));uv.append((s,t))
    for i in range(steps):
     for j in range(4):
      a=i*5+j;b=a+5;idx.extend((a,a+1,b,b,a+1,b+1))
    return np.array(verts),np.array(uv),np.array(idx,dtype=np.uint32)
class G:
 def __init__(self):self.nodes=[];self.meshes=[];self.materials=[];self.bin=bytearray();self.views=[];self.access=[];self.matidx={};self.tex=[];self.images=[];self.textures=[]
 def add_mat(self,name):
  if name not in self.matidx:
   col,rough=MATS[name];c=[int(col[i:i+2],16)/255 for i in (1,3,5)]
   mat={'name':name,'pbrMetallicRoughness':{'baseColorFactor':c+[1.0],'metallicFactor':0.0,'roughnessFactor':rough}}
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
 def mesh(self,name,parts,material,translation=(0,0,0),extras=None):
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
  if extras:node['extras']=extras
  self.nodes.append(node);return ni
 def empty(self,name,translation,extras=None):
  ni=len(self.nodes);node={'name':name,'translation':list(translation)}
  if extras:node['extras']=extras
  self.nodes.append(node);return ni
 def write(self,path):
  doc={'asset':{'version':'2.0','generator':'build_heart.py · original procedural anatomy'},'scene':0,'scenes':[{'nodes':list(range(len(self.nodes)))}],'nodes':self.nodes,'meshes':self.meshes,'materials':self.materials,'buffers':[{'byteLength':len(self.bin)}],'bufferViews':self.views,'accessors':self.access,'images':self.images,'textures':self.textures,'samplers':[{'magFilter':9729,'minFilter':9987,'wrapS':10497,'wrapT':10497}]}
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
 # Hollow cavity shells have separate room-center origins; each wall is a closed two-surface ellipsoid shell.
 specs={'RA':((.010,.013,.009),'AtriumWall'),'RV':((.011,.020,.010),'Myocardium'),'LA':((.010,.011,.009),'AtriumWall'),'LV':((.013,.025,.011),'Myocardium')}
 for room,((rx,ry,rz),mat) in specs.items():
  center=SPOTS[room];outer=ellipsoid((0,0,0),(rx,ry,rz),20,28);inner=ellipsoid((0,0,0),(rx*.73,ry*.70,rz*.72),20,28,True)
  g.mesh('Wall'+room,[(*outer,mat),(*inner,'Endocardium')],mat,translation=center,extras={'pivot':'room center','unit':'m'})
  blood=ellipsoid((0,0,0),(rx*.67,ry*.62,rz*.64),18,24)
  bm='BloodDeoxygenated' if room in ('RA','RV') else 'BloodOxygenated'
  g.mesh('Blood'+room,[(*blood,bm)],bm,translation=center,extras={'pivot':'room center; scale about this origin','fill_range':[0.35,1.0],'unit':'m'})
 # Vessels use an open lumen, open mouths and a visible annular wall cross-section.
 radii={'Aorta':.0055,'PulmonaryTrunk':.0052,'SVC':.0045,'IVC':.0047,'PulmonaryVeinL':.0034,'PulmonaryVeinR':.0034}
 for name,path in VESSELS.items():
  center=np.array(path[0]);local=(np.array(path)-center).tolist();ro=radii[name];parts=[(*tube(local,ro,ro*.66), 'VesselWall')]
  g.mesh(name,parts,'VesselWall',translation=tuple(center),extras={'lumen':'open','wall_thickness_m':round(ro*.34,5)})
  g.empty('ClampPoint',tuple(path[-1]),extras={'vessel':name,'purpose':'interaction attachment point'})
 # Named annuli, separate leaflets, and individual hinge origins.
 counts={'Tricuspid':3,'Mitral':2,'Aortic':3,'Pulmonary':3};rads={'Tricuspid':.0092,'Mitral':.0085,'Aortic':.0058,'Pulmonary':.0056}
 for valve,c in VALVES.items():
  ctr=np.array(c);r=rads[valve]
  g.mesh('Annulus'+valve,[(*ring((0,0,0),r,.0010),'Annulus')],'Annulus',translation=tuple(ctr),extras={'pivot':'annulus center','unit':'m'})
  for i in range(counts[valve]):
   a=2*math.pi*i/counts[valve]+math.pi/counts[valve]
   hinge=ctr+np.array((r*math.cos(a),0,r*math.sin(a)))
   # leaky artifact leaves one cusp partly open by shifting its free edge axially.
   tilt=(.0022 if leaky==valve and i==0 else 0.)
   local,uv,ix=leaflet((0,0,0),a,r*.84,tilt)
   # center vertices locally at the hinge for a useful pivot; surface sits in annular plane.
   local[:,0]-=hinge[0]-ctr[0];local[:,2]-=hinge[2]-ctr[2]
   lname=f'Leaflet{valve}{i+1}';g.mesh(lname,[(local,uv,ix,'Leaflet')],'Leaflet',translation=tuple(ctr),extras={'hinge':'Hinge'+valve+str(i+1),'closure':'partial' if tilt else 'coaptation'})
   g.empty('Hinge'+valve+str(i+1),tuple(hinge),extras={'pivot':'leaflet hinge'})
  # chordae connect leaflet tips to two separate papillary muscle bodies in ventricles
  base=np.array(SPOTS['RV' if valve=='Tricuspid' else 'LV'])
  for i in range(2):
   pap=base+np.array(((-.003 if i==0 else .003),-.009,.002))
   g.mesh(f'Papillary{valve}{i+1}',[(*ellipsoid((0,0,0),(.0024,.006,.0024),10,14),'Myocardium')],'Myocardium',translation=tuple(pap),extras={'role':'papillary muscle'})
  for i in range(counts[valve]):
   a=2*math.pi*i/counts[valve]+math.pi/counts[valve];tip=ctr+np.array((r*.72*math.cos(a),-.002,r*.72*math.sin(a)))
   pap=base+np.array(((-.003 if i%2==0 else .003),-.009,.002)); pts=[tip,(tip+pap)*.5,pap]
   g.mesh(f'Chordae{valve}{i+1}',[(*tube([tuple(x-ctr) for x in pts],.00035,.00018,6),'Tendon')],'Tendon',translation=tuple(ctr),extras={'role':'tendon'})
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
