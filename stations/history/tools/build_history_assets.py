#!/usr/bin/env python3
"""Tarih Meydanı (stations/history/) için 6 tarihî şahsiyetin karakter riglerini
(source/<figure>/base_neutral.jpg) ve dönem arka planlarını üretir."""
import json
import os
from pathlib import Path
import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage

HIST_ROOT = Path(__file__).resolve().parents[1]
SRC_DIR = HIST_ROOT / "source"
OUT_CHARS = HIST_ROOT / "assets" / "characters"
OUT_BGS = HIST_ROOT / "assets" / "backgrounds"
DATA_CHARS = HIST_ROOT / "data" / "characters.json"

FIGURES = ["mete_han", "alparslan", "fatih", "kanuni", "mimar_sinan", "ataturk"]


def build_characters() -> None:
    manifest = {"figures": {}}
    for fig in FIGURES:
        raw_p = SRC_DIR / fig / "base_neutral.jpg"
        if not raw_p.exists():
            print(f"UYARI: {raw_p} bulunamadı!")
            continue

        im = Image.open(raw_p).convert("RGB")
        w, h = im.size
        arr = np.asarray(im).astype(np.float32)
        yy, xx = np.mgrid[0:h, 0:w]

        # Üst köşelerden arka plan rengi örnekleme
        c_tl = arr[:30, :60].reshape(-1, 3)
        c_tr = arr[:30, -60:].reshape(-1, 3)
        bg_sample = np.concatenate([c_tl, c_tr], axis=0)
        bg_color = np.median(bg_sample, axis=0)
        dist = np.linalg.norm(arr - bg_color[None, None, :], axis=-1)
        lum = arr.mean(axis=-1)

        if fig == "fatih":
            is_bg_seed = (dist < 36.0) | ((lum < 42.0) & (yy < 125)) | ((yy < 30) & (dist < 48.0))
        elif fig == "mimar_sinan":
            is_bg_seed = (dist < 34.0) | ((lum < 48.0) & (yy < 132)) | ((yy < 25) & (dist < 46.0))
        elif fig == "ataturk":
            is_bg_seed = (dist < 32.0) | ((lum < 24.0) & ((xx < 260) | (xx > 636) | (yy < 8)))
        elif fig in ("alparslan", "mete_han"):
            is_bg_seed = (dist < 26.0) | ((lum < 38.0) & (yy < 95))
        elif fig == "kanuni":
            is_bg_seed = (dist < 25.0) | ((lum < 32.0) & (yy < 28))
        else:
            is_bg_seed = dist < 24.0

        labeled, _ = ndimage.label(is_bg_seed)
        top_labels = set(np.unique(labeled[0, :])) | set(np.unique(labeled[:5, 0])) | set(np.unique(labeled[:5, -1]))
        top_labels.discard(0)
        bg_mask = np.isin(labeled, list(top_labels))
        fg_mask = ndimage.binary_fill_holes(~bg_mask)

        dist_inside = ndimage.distance_transform_edt(fg_mask)
        dist_outside = ndimage.distance_transform_edt(~fg_mask)
        signed_dist = dist_inside - dist_outside
        alpha = np.clip((signed_dist + 2.5) / 5.0, 0.0, 1.0)

        if fig == "fatih":
            alpha[:100] = 0.0
        elif fig == "mimar_sinan":
            alpha[:115] = 0.0
        elif fig == "ataturk":
            alpha_padded = np.zeros_like(alpha)
            alpha_padded[25:] = alpha[:-25]
            alpha = alpha_padded
            arr_padded = np.zeros_like(arr)
            arr_padded[25:] = arr[:-25]
            arr = arr_padded

        # Doğal alt gövde geçişi (y > %88)
        bot_fade = np.clip((h - yy) / (h * 0.12), 0.0, 1.0)
        alpha = alpha * bot_fade

        # Doğal kenar yumuşatma (14 px)
        side_fade = np.clip(xx / 14.0, 0.0, 1.0) * np.clip((w - 1.0 - xx) / 14.0, 0.0, 1.0)
        alpha = alpha * side_fade

        alpha_im = Image.fromarray((alpha * 255.0).astype(np.uint8), mode="L").filter(ImageFilter.GaussianBlur(0.8))
        out = Image.fromarray(arr.astype(np.uint8), mode="RGB").convert("RGBA")
        out.putalpha(alpha_im)

        fig_out_dir = OUT_CHARS / fig
        fig_out_dir.mkdir(parents=True, exist_ok=True)
        body_path = fig_out_dir / "body.png"
        out.save(body_path)

        a_arr = np.array(alpha_im)
        nz = np.nonzero(a_arr > 15)
        ymin, ymax = int(nz[0].min()), int(nz[0].max())
        xmin, xmax = int(nz[1].min()), int(nz[1].max())

        manifest["figures"][fig] = {
            "body_size": [w, h],
            "face_rect": [xmin + (xmax - xmin) // 4, ymin, (xmax - xmin) // 2, (ymax - ymin) // 3],
            "faces": ["neutral"],
            "uppers": {},
        }
        print(f"  [başarılı] {fig:12s} -> {body_path} (bbox: {xmin},{ymin} - {xmax},{ymax})")

    DATA_CHARS.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print("✅ Tarih karakterleri ve characters.json başarıyla güncellendi.")


if __name__ == "__main__":
    build_characters()
