#!/usr/bin/env python3
"""Build the original Yanlış Dünya Meridian Field display font from hand-drawn glyph strokes.
Requires fontTools. Glyph source lives in tools/meridian_glyphs.py.
"""
from pathlib import Path
import sys
from fontTools.fontBuilder import FontBuilder
from fontTools.pens.ttGlyphPen import TTGlyphPen
sys.path.insert(0, str(Path(__file__).resolve().parent))
from meridian_glyphs import G, advance

UPM=1000
STROKE=58
OUT=Path('assets/fonts/YanlisDunyaMeridian-Display.ttf')

def outline_path(points):
    pts=[(x*6,y*7) for x,y in points]
    polys=[]
    # Machined ends: short chamfers; a small octagonal join keeps the monoline intact.
    for a,b in zip(pts,pts[1:]):
        dx=b[0]-a[0];dy=b[1]-a[1];d=(dx*dx+dy*dy)**.5
        if not d: continue
        nx=-dy/d*STROKE/2;ny=dx/d*STROKE/2
        trim=min(STROKE*.22,d*.15); ux=dx/d*trim;uy=dy/d*trim
        polys.append([(a[0]+ux+nx,a[1]+uy+ny),(b[0]-ux+nx,b[1]-uy+ny),
                      (b[0]-ux-nx,b[1]-uy-ny),(a[0]+ux-nx,a[1]+uy-ny)])
    # chamfered 8-sided caps/joins
    rad=STROKE*.54
    for x,y in pts:
        polys.append([(x+rad*math.cos(math.radians(22.5+i*45)),y+rad*math.sin(math.radians(22.5+i*45))) for i in range(8)])
    return polys

import math
# Keep a deliberately small display repertoire; Inter remains the body and fallback font.
chars=sorted(set(G.keys()), key=ord)
# Dotless i is the stem only; unlike the dotted Latin i.
G['ı']=[[(24,66),(24,0)]]
chars=sorted(set(G.keys()), key=ord)
font_names={ord(ch): f'g{ord(ch):04X}' for ch in chars}
glyph_order=['.notdef','space']+[font_names[ord(ch)] for ch in chars if ch!=' ']
fb=FontBuilder(UPM,isTTF=True);fb.setupGlyphOrder(glyph_order)
glyphs={};metrics={}
def draw_poly(pen,points):
    # TrueType non-zero fill: same winding for every solid stroke fragment.
    area=sum(points[i][0]*points[(i+1)%len(points)][1]-points[(i+1)%len(points)][0]*points[i][1] for i in range(len(points)))
    if area<0:points=list(reversed(points))
    pen.moveTo(points[0])
    for p in points[1:]:pen.lineTo(p)
    pen.closePath()


# notdef: own outline sample in the same cut-terminal language
for gn in glyph_order:
    pen=TTGlyphPen(None)
    if gn=='.notdef':
        contours=[[(70,0),(430,0),(500,70),(500,630),(430,700),(70,700),(0,630),(0,70)],
                  [(90,90),(410,610)],[(410,90),(90,610)]]
        for poly in contours:draw_poly(pen,poly)
        metrics[gn]=(600,0)
    elif gn=='space':metrics[gn]=(360,0)
    else:
        ch=next(c for c in chars if font_names[ord(c)]==gn)
        for path in G[ch]:
            for poly in outline_path(path):draw_poly(pen,poly)
        metrics[gn]=(advance(ch),0)
    glyphs[gn]=pen.glyph()


fb.setupGlyf(glyphs);fb.setupHorizontalMetrics(metrics)
fb.setupHorizontalHeader(ascent=900,descent=-230)
fb.setupCharacterMap({32:'space', **{ord(ch):font_names[ord(ch)] for ch in chars if ch!=' '}})
fb.setupNameTable({'familyName':'Yanlış Dünya Meridian','styleName':'Display','uniqueFontIdentifier':'YanlisDunyaMeridian-Display-1.0','fullName':'Yanlış Dünya Meridian Display','psName':'YanlisDunyaMeridian-Display','version':'Version 1.0'})
fb.font['name'].setName('Copyright 2026 Yanlış Dünya contributors',0,3,1,0x409)
fb.font['name'].setName('Licensed under the SIL Open Font License 1.1. See assets/fonts/LICENSE-Meridian-Display.txt.',13,3,1,0x409)
fb.font['name'].setName('https://openfontlicense.org',14,3,1,0x409)
fb.setupOS2(sTypoAscender=900,sTypoDescender=-230,usWinAscent=900,usWinDescent=230,sxHeight=490,sCapHeight=700,usWeightClass=620)
fb.setupPost();fb.setupMaxp()
OUT.parent.mkdir(parents=True,exist_ok=True);fb.save(OUT)
from fontTools.ttLib import TTFont
check=TTFont(OUT)
cmap=set().union(*(set(table.cmap) for table in check['cmap'].tables if table.isUnicode()))
required='İıŞĞÇÖÜşğçıöü0123456789.,:;!?+-=/%()[]\'"°–—'
missing=[ch for ch in required if ord(ch) not in cmap]
if missing: raise SystemExit('Required display glyphs missing: '+''.join(missing))
print(f'Wrote original outline font {OUT}: {len(chars)} glyphs, including Turkish letters.')
