#!/usr/bin/env python3
"""Deterministically author a compact dark perfusion-lab equirectangular HDRI."""
from array import array
from math import exp, pi, sin, cos
from pathlib import Path
import struct

W, H = 2048, 1024
OUT = Path(__file__).parent / 'lab_hdri.hdr'

def wrap_delta(a, b):
    d = abs(a-b)
    return min(d, 1-d)

def rgb_to_rgbe(rgb):
    r,g,b = rgb
    m=max(r,g,b)
    if m < 1e-32:
        return bytes((0,0,0,0))
    mant, exponent = __import__('math').frexp(m)
    scale=mant*256.0/m
    return bytes((max(0,min(255,int(r*scale))), max(0,min(255,int(g*scale))), max(0,min(255,int(b*scale))), exponent+128))

def encode_scanline(row):
    # Radiance per-channel RLE packets; all RGBE values are supplied as bytes.
    out=bytearray((2,2,(W>>8)&255,W&255))
    for channel in range(4):
        data=bytes(px[channel] for px in row)
        i=0
        while i<W:
            run=1
            while i+run<W and data[i+run]==data[i] and run<127:
                run+=1
            if run>=4:
                out.extend((128+run,data[i])); i+=run
                continue
            start=i; i+=run
            while i<W and i-start<127:
                r=1
                while i+r<W and data[i+r]==data[i] and r<127: r+=1
                if r>=4: break
                i+=r
            n=i-start
            out.append(n); out.extend(data[start:i])
    return out

with OUT.open('wb') as f:
    f.write(b'#?RADIANCE\n# Yanlis Dunya procedural dark perfusion lab, linear radiance\nFORMAT=32-bit_rle_rgbe\n\n-Y 1024 +X 2048\n')
    for y in range(H):
        v=(y+.5)/H
        row=[]
        for x in range(W):
            u=(x+.5)/W
            # A near-black navy room with soft, broad ceiling reflections.
            base=0.008 + 0.015*max(0,cos((v-.55)*pi))
            warm=0.0; cool=0.0
            # broad amber surgical task panel above-left, and a long cool fill strip.
            dx=wrap_delta(u,.22); dy=v-.265
            warm=7.5*exp(-((dx/.075)**2+(dy/.038)**2)*1.8)
            warm+=1.3*exp(-((dx/.19)**2+(dy/.13)**2)*2.0)
            dx2=wrap_delta(u,.76); dy2=v-.34
            cool=3.1*exp(-((dx2/.12)**2+(dy2/.045)**2)*1.7)
            # A muted stainless reflection band at the horizon keeps equipment readable.
            band=0.075*exp(-((v-.56)/.09)**2)
            mottling=1.0+0.035*sin(u*2*pi*9+v*21)*sin(v*2*pi*7-u*16)
            r=(base+band+warm*1.0+cool*.36)*mottling
            g=(base*1.04+band*.93+warm*.67+cool*.62)*mottling
            b=(base*1.16+band*.82+warm*.37+cool*.86)*mottling
            row.append(rgb_to_rgbe((r,g,b)))
        f.write(encode_scanline(row))
print(f'Wrote {OUT} ({W}x{H})')
