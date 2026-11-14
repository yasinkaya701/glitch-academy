#!/usr/bin/env python3
"""
build_history_assets.py
Tarih Meydanı için 6 tarihî şahsiyetin karakter riglerini (source/<figure>/base_neutral.jpg)
yüksek çözünürlüklü ve pürüzsüz u2net matting ile üretir.
"""

import json
import os
from pathlib import Path
from PIL import Image
import rembg

HIST_ROOT = Path(__file__).resolve().parents[1]
SRC_DIR = HIST_ROOT / "source"
OUT_CHARS = HIST_ROOT / "assets" / "characters"
DATA_CHARS = HIST_ROOT / "data" / "characters.json"

FIGURES = ["mete_han", "alparslan", "fatih", "kanuni", "mimar_sinan", "ataturk"]

# Standard face focus rects [x, y, w, h] for 896x1200 portraits
FACE_RECTS = {
    "mete_han": [262, 104, 410, 362],
    "alparslan": [250, 102, 429, 362],
    "fatih": [225, 99, 445, 363],
    "kanuni": [279, 29, 374, 387],
    "mimar_sinan": [224, 114, 446, 358],
    "ataturk": [224, 26, 445, 388]
}

def build_characters() -> None:
    print("Loading rembg session...")
    session = rembg.new_session("u2net")
    manifest = {"figures": {}}

    for fig in FIGURES:
        raw_p = SRC_DIR / fig / "base_neutral.jpg"
        if not raw_p.exists():
            print(f"UYARI: {raw_p} bulunamadı!")
            continue

        im = Image.open(raw_p)
        print(f"İşleniyor: {fig}...")
        out = rembg.remove(im, session=session)
        if out.size != (896, 1200):
            out = out.resize((896, 1200), Image.Resampling.LANCZOS)

        fig_out_dir = OUT_CHARS / fig
        fig_out_dir.mkdir(parents=True, exist_ok=True)
        body_path = fig_out_dir / "body.png"
        out.save(body_path, "PNG")

        manifest["figures"][fig] = {
            "body_size": [896, 1200],
            "face_rect": FACE_RECTS.get(fig, [224, 50, 440, 380]),
            "faces": ["neutral"],
            "uppers": {}
        }
        print(f"  [başarılı] {fig:12s} -> {body_path}")

    DATA_CHARS.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print("✅ Tarih karakterleri ve characters.json başarıyla güncellendi.")

if __name__ == "__main__":
    build_characters()
