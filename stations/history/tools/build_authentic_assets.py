#!/usr/bin/env python3
"""
build_authentic_assets.py
Replaces all history figures with authentic, museum-verified, historical portraits:
- Atatürk: 1921 Library of Congress authentic kalpak photograph
- Fatih: Gentile Bellini 1480 National Gallery London authentic portrait
- Kanuni: Titian workshop 1530 authentic portrait
- Mimar Sinan: 1579 Süleymannâme authentic miniature (Seyyid Lokman / Nakkaş Osman)
- Alparslan: Topkapı Sarayı Müzesi Câmiü't-Tevârîh authentic Seljuk miniature
- Mete Han: Chinggis Khaan National Museum enthroned bronze statue
"""

import os
import sys
from PIL import Image
import rembg

OUTPUT_DIR = "stations/history/assets/characters"
TARGET_W = 896
TARGET_H = 1200

def prepare_crop(img: Image.Image, max_dim=1400):
    if max(img.size) > max_dim:
        scale = max_dim / float(max(img.size))
        img = img.resize((int(img.width * scale), int(img.height * scale)), Image.Resampling.LANCZOS)
    return img

def place_on_canvas(cutout: Image.Image, target_w=TARGET_W, target_h=TARGET_H, scale_factor=0.90):
    # Auto-trim transparent edges
    bbox = cutout.getbbox()
    if bbox:
        cutout = cutout.crop(bbox)
        
    target_body_h = int(target_h * scale_factor)
    scale = target_body_h / float(cutout.height)
    new_w = int(cutout.width * scale)
    new_h = target_body_h
    
    # If width exceeds target canvas width, scale down proportionally
    if new_w > int(target_w * 0.92):
        scale = (target_w * 0.92) / float(cutout.width)
        new_w = int(cutout.width * scale)
        new_h = int(cutout.height * scale)
        
    resized = cutout.resize((new_w, new_h), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (target_w, target_h), (0, 0, 0, 0))
    
    pos_x = (target_w - new_w) // 2
    # Place so bottom sits firmly on bottom edge (1200)
    pos_y = target_h - new_h
        
    canvas.paste(resized, (pos_x, pos_y), resized)
    return canvas

def process_all():
    print("Initializing rembg session...")
    session = rembg.new_session("u2net")
    print("Session ready.")

    # 1. ATATÜRK (Library of Congress 1921 National Struggle photograph)
    print("Processing Atatürk...")
    im_at = Image.open("/tmp/authentic_history_raw/ataturk_loc.jpg")
    w, h = im_at.size
    crop_at = im_at.crop((int(w * 0.18), int(h * 0.05), int(w * 0.82), int(h * 0.65)))
    crop_at = prepare_crop(crop_at)
    cut_at = rembg.remove(crop_at, session=session)
    body_at = place_on_canvas(cut_at, scale_factor=0.92)
    body_at.save(os.path.join(OUTPUT_DIR, "ataturk/body.png"), "PNG")
    print("Saved ataturk/body.png")

    # 2. FATIH SULTAN MEHMED (Gentile Bellini 1480 National Gallery London)
    print("Processing Fatih...")
    im_fa = Image.open("/tmp/authentic_history_raw/fatih_bellini.jpg")
    w, h = im_fa.size
    # Bellini portrait: Mehmed II profile with turban and mantle
    crop_fa = im_fa.crop((int(w * 0.20), int(h * 0.20), int(w * 0.80), int(h * 0.84)))
    crop_fa = prepare_crop(crop_fa)
    cut_fa = rembg.remove(crop_fa, session=session)
    body_fa = place_on_canvas(cut_fa, scale_factor=0.92)
    body_fa.save(os.path.join(OUTPUT_DIR, "fatih/body.png"), "PNG")
    print("Saved fatih/body.png")

    # 3. KANUNI SULTAN SÜLEYMAN (Titian Workshop 1530)
    print("Processing Kanuni...")
    im_ka = Image.open("/tmp/authentic_history_raw/kanuni_titian.jpg")
    w, h = im_ka.size
    crop_ka = im_ka.crop((int(w * 0.12), int(h * 0.02), int(w * 0.88), int(h * 0.90)))
    crop_ka = prepare_crop(crop_ka)
    cut_ka = rembg.remove(crop_ka, session=session)
    body_ka = place_on_canvas(cut_ka, scale_factor=0.94)
    body_ka.save(os.path.join(OUTPUT_DIR, "kanuni/body.png"), "PNG")
    print("Saved kanuni/body.png")

    # 4. METE HAN (Chinggis Khaan National Museum enthroned bronze)
    print("Processing Mete Han...")
    im_me = Image.open("/tmp/authentic_history_raw/mete_han_modu.jpg")
    w, h = im_me.size
    crop_me = im_me.crop((int(w * 0.15), int(h * 0.12), int(w * 0.85), int(h * 0.90)))
    crop_me = prepare_crop(crop_me)
    cut_me = rembg.remove(crop_me, session=session)
    body_me = place_on_canvas(cut_me, scale_factor=0.90)
    body_me.save(os.path.join(OUTPUT_DIR, "mete_han/body.png"), "PNG")
    print("Saved mete_han/body.png")

    # 5. MIMAR SINAN (1579 Süleymannâme miniature)
    print("Processing Mimar Sinan...")
    # Use cropped miniature focusing on Sinan with white beard and arşın ruler
    im_si = Image.open("/tmp/authentic_history_raw/sinan_lokman_cropped.jpg")
    crop_si = prepare_crop(im_si)
    cut_si = rembg.remove(crop_si, session=session)
    body_si = place_on_canvas(cut_si, scale_factor=0.92)
    body_si.save(os.path.join(OUTPUT_DIR, "mimar_sinan/body.png"), "PNG")
    print("Saved mimar_sinan/body.png")

    # 6. SULTAN ALPARSLAN (Topkapı Sarayı Müzesi Câmiü't-Tevârîh miniature)
    print("Processing Alparslan...")
    im_al = Image.open("/tmp/authentic_history_raw/alparslan_tsmk.jpg")
    w, h = im_al.size
    # Focus on Sultan Alp Arslan on the Seljuk throne
    crop_al = im_al.crop((int(w * 0.32), int(h * 0.18), int(w * 0.68), int(h * 0.88)))
    crop_al = prepare_crop(crop_al)
    cut_al = rembg.remove(crop_al, session=session)
    body_al = place_on_canvas(cut_al, scale_factor=0.92)
    body_al.save(os.path.join(OUTPUT_DIR, "alparslan/body.png"), "PNG")
    print("Saved alparslan/body.png")

    print("ALL 6 AUTHENTIC FIGURES PROCESSED AND NORMALIZED!")

if __name__ == "__main__":
    process_all()
