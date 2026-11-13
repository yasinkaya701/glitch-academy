#!/usr/bin/env python3
"""Deterministically paint the Collision Track sprites with Pillow; no external art."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter
import math
OUT=Path(__file__).resolve().parent
S=3

def canvas(w,h,bg=(0,0,0,0),scale=S):
 im=Image.new('RGBA',(w*scale,h*scale),bg);return im,ImageDraw.Draw(im)
def xy(v):return int(round(v*S))
def rect(d,box,fill,outline=None,width=1,r=0):
 b=tuple(xy(x) for x in box)
 if r:d.rounded_rectangle(b,radius=xy(r),fill=fill,outline=outline,width=xy(width))
 else:d.rectangle(b,fill=fill,outline=outline,width=xy(width))
def line(d,pts,fill,width=1):d.line([(xy(x),xy(y)) for x,y in pts],fill=fill,width=xy(width),joint='curve')
def ellipse(d,box,fill,outline=None,width=1):d.ellipse(tuple(xy(x) for x in box),fill=fill,outline=outline,width=xy(width))
def poly(d,pts,fill,outline=None,width=1):d.polygon([(xy(x),xy(y)) for x,y in pts],fill=fill); 
def glow(im,center,r,color):
 lay=Image.new('RGBA',im.size,(0,0,0,0));d=ImageDraw.Draw(lay);x,y=center;d.ellipse((xy(x-r),xy(y-r),xy(x+r),xy(y+r)),fill=color);lay=lay.filter(ImageFilter.GaussianBlur(xy(r*.58)));im.alpha_composite(lay)
def finish(im,path,opaque=False):
 if opaque:im=im.convert('RGB')
 im.resize((im.width//S,im.height//S),Image.Resampling.LANCZOS).save(path,optimize=True)
def tire(d,cx,cy,r):
 # layered dark tire, turned alloy hub and bearing dot
 ellipse(d,(cx-r,cy-r,cx+r,cy+r),(12,19,23,255),(73,83,83,255),2)
 ellipse(d,(cx-r*.72,cy-r*.72,cx+r*.72,cy+r*.72),(33,44,47,255),(147,153,143,255),2)
 ellipse(d,(cx-r*.34,cy-r*.34,cx+r*.34,cy+r*.34),(100,112,109,255),(192,190,171,255),2)
 ellipse(d,(cx-2,cy-2,cx+2,cy+2),(24,32,35,255))
def cart(w,h,basecolor,heavy=False,name='cart'):
 im,d=canvas(w,h)
 glow(im,(w/2,h*.62),76,(81,166,197,34));d=ImageDraw.Draw(im)
 # isolated drop shadow and cast contact shadow
 ellipse(d,(39,141,w-39,172),(0,0,0,54))
 # wheels: front/back pairs aligned to the air-track runners
 for x in [82,w-82]:tire(d,x,137,21)
 # chassis with tapered aluminum lip
 poly(d,[(34,119),(48,103),(w-48,103),(w-34,118),(w-45,136),(45,136)],(66,80,83,255),(178,184,173,255),2)
 line(d,[(47,108),(w-48,108)],(215,215,193,255),2)
 rect(d,(53,119,w-53,127),(31,43,47,255),(99,111,108,255),1,2)
 # instrument top deck, rounded metal frame
 rect(d,(55,68,w-55,113),(32,46,50,255),(151,160,150,255),2,7)
 # central low-profile mass housing in role color
 c=basecolor
 rect(d,(77,76,w-77,105),(*c,255),(211,211,188,255),2,5)
 rect(d,(85,81,w-85,85),(239,234,211,210),r=2)
 rect(d,(85,90,w-85,99),(max(0,c[0]-27),max(0,c[1]-27),max(0,c[2]-27),255),r=3)
 # heavy cart has two accurately stacked ballast blocks, with machined seams and handles.
 if heavy:
  for y0,y1,shade in [(39,66,(167,115,56,255)),(20,46,(194,142,71,255))]:
   rect(d,(111,y0,w-111,y1),shade,(226,194,130,255),2,5)
   line(d,[(119,y0+5),(w-119,y0+5)],(248,207,135,220),2)
   for x in [126,w-126]:ellipse(d,(x-2,y0+10,x+2,y0+14),(50,52,48,255))
  # locking rail lips visibly retain the ballast rather than let it float.
  rect(d,(101,43,110,69),(103,112,106,255),(198,195,169,255),1,2);rect(d,(w-110,43,w-101,69),(103,112,106,255),(198,195,169,255),1,2)
 else:
  # Small fixed test mass and two fasteners make the lighter cart legible, not a bare box.
  rect(d,(137,52,w-137,69),(91,103,98,255),(173,179,163,255),2,4)
  for x in [146,w-146]:ellipse(d,(x-2,57,x+2,61),(30,37,38,255))
 # calibrated-looking but unlettered end faces, symmetric bump contacts
 for x,dir in [(42,-1),(w-42,1)]:
  rect(d,(x-10,86,x+10,105),(38,48,50,255),(173,181,169,255),2,3)
  ellipse(d,(x-5,91,x+5,101),(216,163,87,255),(246,202,124,255),2)
 # polished edge highlight and small corner fasteners
 line(d,[(60,72),(w-60,72)],(217,220,199,240),1)
 for x in [66,w-66]:ellipse(d,(x-2,108,x+2,112),(198,195,175,255))
 finish(im,OUT/f'{name}.png')
def stuck_pair():
 w,h=512,192;im,d=canvas(w,h);glow(im,(256,112),70,(244,166,90,35));d=ImageDraw.Draw(im)
 # Cast shadow; two carts nose-to-nose, equal contact height and a compact magnetic latch.
 ellipse(d,(27,145,485,176),(0,0,0,55))
 def half(left):
  if left:
   rect(d,(24,86,247,120),(40,56,62,255),(158,167,157,255),2,6);rect(d,(41,58,228,88),(54,82,96,255),(175,185,174,255),2,6);rect(d,(55,67,220,82),(94,130,145,255),(222,224,203,255),2,4);rect(d,(86,37,203,58),(89,104,99,255),(186,186,166,255),2,4);wheels=[61,210];
  else:
   rect(d,(265,86,488,120),(40,56,62,255),(158,167,157,255),2,6);rect(d,(284,58,471,88),(70,71,56,255),(185,165,126,255),2,6);rect(d,(292,67,463,82),(163,113,52,255),(235,192,113,255),2,4);rect(d,(322,30,431,59),(194,142,71,255),(230,198,130,255),2,5);rect(d,(332,14,421,34),(177,126,61,255),(230,198,130,255),2,4);wheels=[302,451]
  for x in wheels:tire(d,x,139,20)
 half(True);half(False)
 # joining bridge is the visible inelastic latch. Tiny amber seam keeps contact easy to spot.
 rect(d,(240,79,272,108),(23,33,37,255),(193,157,94,255),2,4);rect(d,(246,85,266,102),(77,89,81,255),(235,183,94,255),2,3);line(d,[(255,86),(255,101)],(245,209,139,255),2)
 line(d,[(37,64),(232,64)],(219,223,202,220),1);line(d,[(287,64),(464,64)],(230,213,174,230),1)
 finish(im,OUT/'cart_stuck.png')
def spring():
 w,h=256,192;im,d=canvas(w,h);glow(im,(128,94),80,(243,166,89,40));d=ImageDraw.Draw(im)
 # mounting pads and guidance rods keep a real spring aligned with the cart's travel axis
 rect(d,(22,54,48,136),(48,60,62,255),(166,174,164,255),2,5);rect(d,(208,54,234,136),(48,60,62,255),(166,174,164,255),2,5)
 for y in [65,124]:line(d,[(47,y),(209,y)],(122,134,130,255),3);line(d,[(49,y-1),(207,y-1)],(210,208,190,190),1)
 # coil: alternating bright/dark segments create a continuous helical spring silhouette, with end collars
 pts=[]
 for i in range(100):
  x=52+152*i/99;y=95+21*math.sin(i*2*math.pi/13)
  pts.append((x,y))
 line(d,pts,(26,34,37,255),13);line(d,pts,(141,151,142,255),8);line(d,pts[:-1],(216,213,190,255),3)
 for x in [53,199]:rect(d,(x-5,71,x+5,119),(88,101,99,255),(206,208,190,255),2,4)
 ellipse(d,(114,89,142,101),(241,177,93,255),(255,219,145,255),2)
 finish(im,OUT/'bumper_spring.png')
if __name__=='__main__':
 # track_bg.png is an intentionally preserved photoreal source image; this script rebuilds sprites only.
 cart(384,192,(65,124,154),False,'cart_a');cart(384,192,(179,123,57),True,'cart_b');stuck_pair();spring();print('Wrote four transparent collision-track sprites.')
