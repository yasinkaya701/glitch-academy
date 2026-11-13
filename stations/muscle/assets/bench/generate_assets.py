#!/usr/bin/env python3
"""Build the two self-contained bench GLBs from deterministic procedural meshes."""
import json, math, struct
from pathlib import Path
OUT=Path(__file__).resolve().parent
class GLB:
 def __init__(s): s.nodes=[];s.meshes=[];s.mats=[];s.views=[];s.acc=[];s.bin=bytearray();s.mi={}
 def mat(s,n,c,metal=0,rough=.5,alpha=1):
  k=(n,tuple(c),metal,rough,alpha)
  if k in s.mi:return s.mi[k]
  m={'name':n,'pbrMetallicRoughness':{'baseColorFactor':list(c),'metallicFactor':metal,'roughnessFactor':rough}}
  if alpha<1:m.update(alphaMode='BLEND',doubleSided=True)
  i=len(s.mats);s.mats.append(m);s.mi[k]=i;return i
 def accr(s,b,ct,ty,count,target=None,lo=None,hi=None):
  s.bin.extend(b'\0'*((-len(s.bin))%4));o=len(s.bin);s.bin.extend(b);v={'buffer':0,'byteOffset':o,'byteLength':len(b)}
  if target:v['target']=target
  s.views.append(v);a={'bufferView':len(s.views)-1,'componentType':ct,'count':count,'type':ty}
  if lo is not None:a.update(min=lo,max=hi)
  s.acc.append(a);return len(s.acc)-1
 def mesh(s,n,v,f,ma):
  normals=[[0.,0.,0.] for _ in v]
  for tri in f:
   a,b,c=[v[i] for i in tri];u=[b[j]-a[j] for j in range(3)];w=[c[j]-a[j] for j in range(3)];q=[u[1]*w[2]-u[2]*w[1],u[2]*w[0]-u[0]*w[2],u[0]*w[1]-u[1]*w[0]]
   for i in tri:
    for j in range(3):normals[i][j]+=q[j]
  for q in normals:
   z=math.sqrt(sum(a*a for a in q)) or 1
   for j in range(3):q[j]/=z
  pa=s.accr(struct.pack('<%sf'%(3*len(v)),*(x for p in v for x in p)),5126,'VEC3',len(v),34962,[min(p[i] for p in v) for i in range(3)],[max(p[i] for p in v) for i in range(3)])
  na=s.accr(struct.pack('<%sf'%(3*len(v)),*(x for p in normals for x in p)),5126,'VEC3',len(v),34962)
  inds=[x for t in f for x in t];ct=5123 if len(v)<65536 else 5125
  ia=s.accr(struct.pack('<%s%s'%(len(inds),'H' if ct==5123 else 'I'),*inds),ct,'SCALAR',len(inds),34963)
  s.meshes.append({'name':n,'primitives':[{'attributes':{'POSITION':pa,'NORMAL':na},'indices':ia,'material':ma}]});return len(s.meshes)-1
 def node(s,n,mesh=None,t=None,sc=None,parent=None):
  x={'name':n}
  if mesh is not None:x['mesh']=mesh
  if t is not None:x['translation']=list(t)
  if sc is not None:x['scale']=list(sc)
  s.nodes.append((x,parent));return len(s.nodes)-1
 def export(s,path,name):
  children=[[] for _ in s.nodes];roots=[]
  for i,(n,p) in enumerate(s.nodes):(roots if p is None else children[p]).append(i)
  ns=[]
  for i,(n,p) in enumerate(s.nodes):
   if children[i]:n['children']=children[i]
   ns.append(n)
  d={'asset':{'version':'2.0','generator':'generate_assets.py'},'scene':0,'scenes':[{'name':name,'nodes':roots}],'nodes':ns,'meshes':s.meshes,'materials':s.mats,'buffers':[{'byteLength':len(s.bin)}],'bufferViews':s.views,'accessors':s.acc}
  js=json.dumps(d,separators=(',',':')).encode();js+=b' '*((-len(js))%4);b=bytes(s.bin)+b'\0'*((-len(s.bin))%4);size=12+8+len(js)+8+len(b)
  with open(path,'wb') as f:f.write(struct.pack('<4sII',b'glTF',2,size)+struct.pack('<I4s',len(js),b'JSON')+js+struct.pack('<I4s',len(b),b'BIN\0')+b)
def box(g,n,dims,ma,pos=(0,0,0),parent=None):
 x,y,z=[v/2 for v in dims];v=[(-x,-y,-z),(x,-y,-z),(x,y,-z),(-x,y,-z),(-x,-y,z),(x,-y,z),(x,y,z),(-x,y,z)];f=[(0,2,1),(0,3,2),(4,5,6),(4,6,7),(0,1,5),(0,5,4),(1,2,6),(1,6,5),(2,3,7),(2,7,6),(3,0,4),(3,4,7)];return g.node(n,g.mesh(n+' mesh',v,f,ma),pos,parent=parent)
def cyl(g,n,r,L,ma,axis='y',parent=None,pos=(0,0,0),r2=None,N=24):
 r2=r if r2 is None else r2;v=[]
 for y,rr in [(-L/2,r),(L/2,r2)]:
  for i in range(N):
   a=2*math.pi*i/N;u=rr*math.cos(a);w=rr*math.sin(a);v.append((u,y,w) if axis=='y' else (u,w,y) if axis=='z' else (y,u,w))
 f=[]
 # Counter-clockwise outer winding is required for outward glTF normals.
 for i in range(N):j=(i+1)%N;f.extend([(i,N+j,j),(i,N+i,N+j)])
 f.extend([(0,i+1,i) for i in range(1,N-1)]);f.extend([(N,N+i,N+i+1) for i in range(1,N-1)]);return g.node(n,g.mesh(n+' mesh',v,f,ma),pos,parent=parent)
def sphere(g,n,r,ma,parent=None,pos=(0,0,0)):
 N=16;R=8;v=[(0,-r,0)]
 for j in range(1,R):
  p=-math.pi/2+math.pi*j/R
  for i in range(N):a=2*math.pi*i/N;v.append((r*math.cos(p)*math.cos(a),r*math.sin(p),r*math.cos(p)*math.sin(a)))
 top=len(v);v.append((0,r,0));f=[]
 for i in range(N):f.append((0,1+(i+1)%N,1+i))
 for j in range(R-2):
  a=1+j*N;b=a+N
  for i in range(N):k=(i+1)%N;f.extend([(a+i,a+k,b+i),(a+k,b+k,b+i)])
 for i in range(N):f.append((1+(R-2)*N+i,1+(R-2)*N+(i+1)%N,top))
 return g.node(n,g.mesh(n+' mesh',v,f,ma),pos,parent=parent)
def build_myograph():
 g=GLB();steel=g.mat('Brushed stainless steel',(.44,.51,.54,1),.78,.28);dark=g.mat('Anodized charcoal',(.08,.12,.14,1),.62,.34);glass=g.mat('Borosilicate glass',(.58,.82,.89,.11),.05,.12,.11);sol=g.mat('Physiological solution',(.035,.16,.22,.06),.02,.16,.06);tissue=g.mat('Gastrocnemius tissue',(.78,.30,.24,1),0,.62);tendon=g.mat('Pale connective tendon',(.82,.70,.56,1),.02,.5);cer=g.mat('Electrode ceramic',(.86,.86,.80,1),.02,.3);metal=g.mat('Platinum iridium',(.68,.73,.71,1),.82,.23)
 stand=box(g,'Stand',(.255,.014,.205),dark,(0,.008,0));cyl(g,'StandPost',.006,.38,steel,parent=stand,pos=(0,.20,-.077));box(g,'StandArm',(.205,.012,.012),steel,(0,.389,-.077),parent=stand);box(g,'TransducerBracket',(.012,.11,.045),steel,(0,.331,-.077),parent=stand)
 bath=g.node('Bath');box(g,'BathBase',(.235,.012,.145),glass,(0,.121,0),bath)
 for n,p,d in [('BathFront',(0,.178,.0715),(.235,.102,.003)),('BathRear',(0,.178,-.0715),(.235,.102,.003)),('BathLeft',(-.116,.178,0),(.003,.102,.143)),('BathRight',(.116,.178,0),(.003,.102,.143))]:box(g,n,d,glass,p,bath)
 box(g,'BathRimFront',(.238,.004,.005),steel,(0,.231,.0715),bath);box(g,'BathRimRear',(.238,.004,.005),steel,(0,.231,-.0715),bath)
 box(g,'Solution',(.226,.096,.136),sol,(0,.176,0))
 tr=g.node('ForceTransducer',t=(0,.270,-.045));box(g,'TransducerBody',(.026,.025,.022),dark,(0,0,0),tr);box(g,'TransducerCap',(.031,.004,.026),steel,(0,.014,0),tr);cyl(g,'TransducerLink',.003,.015,steel,parent=tr,pos=(0,-.020,0))
 top=g.node('TendonTop',t=(0,-.060,0),parent=tr);cyl(g,'Upper tendon',.003,.034,tendon,parent=top,pos=(0,.017,0))
 # The Muscle node owns the spindle mesh so Y scaling is independent and safe over the documented 0.60–1.40 range.
 v=[];profile=[(-.5,.10),(-.40,.36),(-.23,.72),(0,1),(.23,.72),(.40,.36),(.5,.10)];N=24
 for y,r in profile:
  for i in range(N):a=2*math.pi*i/N;v.append((.009*r*math.cos(a),.050*y,.007*r*math.sin(a)))
 f=[]
 for j in range(len(profile)-1):
  for i in range(N):k=(i+1)%N;a=j*N+i;b=j*N+k;c=(j+1)*N+i;d=(j+1)*N+k;f.extend([(a,c,b),(b,c,d)])
 mus=g.node('Muscle',t=(0,-.025,0),sc=(1,1,1),parent=top);g.nodes[mus][0]['mesh']=g.mesh('Fusiform gastrocnemius belly',v,f,tissue)
 bot=g.node('TendonBottom',t=(0,-.0635,0),parent=top);cyl(g,'Lower tendon',.003,.027,tendon,parent=bot)
 cl=g.node('Clamp',t=(0,.150,0));box(g,'Clamp jaw upper',(.022,.006,.018),steel,(0,.012,0),cl);box(g,'Clamp jaw lower',(.022,.006,.018),steel,(0,-.003,0),cl);cyl(g,'Clamp stem',.004,.026,steel,parent=cl,pos=(0,-.022,0))
 cyl(g,'Stretch screw',.003,.045,dark,parent=None,pos=(.050,.183,.080));knob=g.node('StretchKnob',t=(.050,.208,.084));cyl(g,'Knob hub',.008,.008,steel,parent=knob);cyl(g,'Knob grip',.015,.009,dark,axis='z',parent=knob,pos=(0,0,.004))
 for i in range(6):a=i*math.pi/3;box(g,'Knob spoke %d'%i,(.018,.002,.003),steel,(.008*math.cos(a),.008*math.sin(a),.004),knob)
 e=g.node('Electrodes')
 for label,x in [('A',-.018),('B',.018)]:
  arm=g.node('Arm_'+label,t=(x,.215,0),parent=e);cyl(g,'Ceramic shank '+label,.0025,.055,cer,parent=arm,pos=(0,.014,0));cyl(g,'Electrode lead '+label,.0013,.016,metal,parent=arm,pos=(0,-.0195,0));sphere(g,'Tip_'+label,.0018,metal,arm,(0,-.0285,0))
 return g

def build_kymograph():
 g=GLB();steel=g.mat('Brushed stainless steel',(.44,.51,.54,1),.78,.28);dark=g.mat('Anodized charcoal',(.08,.12,.14,1),.65,.34);paper=g.mat('Matte recording paper',(.83,.79,.68,1),0,.82);ink=g.mat('Graphite index marks',(.22,.25,.24,1),.02,.7);brass=g.mat('Warm brass adjustment',(.62,.43,.20,1),.76,.26)
 box(g,'Base',(.25,.018,.16),dark,(0,.009,0));box(g,'RearFrame',(.012,.17,.012),steel,(0,.095,-.055));box(g,'TopBridge',(.20,.012,.012),steel,(0,.174,-.055))
 drum=g.node('Drum',t=(0,.105,.004));cyl(g,'DrumCore',.040,.073,dark,'y',drum);cyl(g,'PaperSurface',.041,.073,paper,'y',drum)
 # The paper surface stays blank so the experiment can draw its own trace.
 cyl(g,'DrumAxle',.005,.105,steel,'y',drum)
 for x in [-.055,.055]:box(g,'Bearing block',(.019,.028,.025),dark,(x,.105,-.039));cyl(g,'Bearing boss',.010,.008,brass,'x',None,(x,.105,.004))
 st=g.node('Stylus',t=(.055,.105,.085));box(g,'Stylus carriage',(.025,.018,.012),dark,(0,0,0),st);cyl(g,'Stylus pivot',.004,.018,brass,'z',st,(0,0,-.008));box(g,'Stylus arm',(.050,.005,.008),steel,(-.025,0,-.030),st);cyl(g,'Stylus nib',.0014,.010,brass,parent=st,pos=(-.055,0,-.039));sphere(g,'Stylus contact point',.0018,dark,st,(-.055,0,-.044));cyl(g,'Adjustment knob',.010,.008,brass,'x',None,(.083,.105,.004))
 return g
if __name__=='__main__':
 OUT.mkdir(parents=True,exist_ok=True);build_myograph().export(OUT/'myograph.glb','Myograph bench apparatus');build_kymograph().export(OUT/'kymograph.glb','Kymograph recorder');print('Wrote myograph.glb and kymograph.glb')
