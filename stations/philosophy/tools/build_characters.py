#!/usr/bin/env python3
"""source/<id>/*.jpg|png karelerinden oyun varlıklarını üretir.

Kullanım (repo kökünden):
  python3 stations/philosophy/tools/build_characters.py            # tüm karakterler
  python3 stations/philosophy/tools/build_characters.py socrates   # tek karakter

Girdi: stations/philosophy/source/<id>/<kare>.(jpg|png)
  base_neutral zorunlu. Diğer kare adları tools/frame_manifest.json içinde.
  Tüm kareler aynı tuvalde, aynı kadrajda, düz yeşil perdeli olmalı (docs: CHARACTER_STYLE.md).

Çıktı: stations/philosophy/assets/characters/<id>/
  body.png            yeşil perde silinmiş tam boy gövde (nötr), kırpılmış
  head.png            baş bölgesi kopyası (altı yumuşak): baş boyundan ayrı hareket eder
  face_<ifade>.png    yüz yaması (kenarları yumuşak), gövde üzerine biner
  up_<ifade>.png      yalnızca üst yüz (göz, kaş, yanak): ağız hareket ederken ifadeyi taşır
  pose_<ad>.png       el-kol duruşu yaması (jest), gövde üzerine biner
  data/characters.json   boyutlar, yama konumları, ağız çizgisi
"""
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "source"
OUT = ROOT / "assets" / "characters"
DATA = ROOT / "data" / "characters.json"

HEAD_FRACTION = 0.30     # yüz değişimi yalnızca görüntünün üst %30'unda aranır
DIFF_THRESHOLD = 14
PATCH_PAD = 18
FEATHER = 10
POSE_PAD = 24
POSE_FEATHER = 22
FACE_OPEN_MOUTH = ("mouth_",)  # ağız kareleri: up_ üretilmez


def backdrop_greenness(img: Image.Image) -> float:
    """Perdenin yeşilliğini kenar piksellerinden ölçer (saf #00FF00 olmayabilir)."""
    a = np.asarray(img.convert("RGB")).astype(np.float32)
    border = np.concatenate([a[:20].reshape(-1, 3), a[-20:].reshape(-1, 3),
                             a[:, :20].reshape(-1, 3), a[:, -20:].reshape(-1, 3)])
    return float(np.median(border[:, 1] - np.maximum(border[:, 0], border[:, 2])))


def key_green(img: Image.Image, bg: float) -> Image.Image:
    a = np.asarray(img.convert("RGB")).astype(np.float32)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    greenness = g - np.maximum(r, b)
    lo, hi = bg * 0.30, bg * 0.80
    alpha = 1.0 - np.clip((greenness - lo) / max(hi - lo, 1.0), 0.0, 1.0)
    g2 = np.minimum(g, np.maximum(r, b) * 0.97)  # yeşil sızıntıyı bastır
    rgb = np.stack([r, g2, b], axis=-1)
    im = Image.fromarray(np.dstack([rgb, alpha * 255.0]).clip(0, 255).astype(np.uint8), "RGBA")
    al = im.getchannel("A").filter(ImageFilter.MinFilter(5)).filter(ImageFilter.GaussianBlur(1.0))
    im.putalpha(al)
    return im


def diff_mask(base: Image.Image, other: Image.Image, rows: tuple[int, int]) -> np.ndarray:
    b = np.asarray(base.convert("RGB")).astype(np.int16)[rows[0]:rows[1]]
    o = np.asarray(other.convert("RGB")).astype(np.int16)[rows[0]:rows[1]]
    return np.abs(o - b).sum(axis=2) > DIFF_THRESHOLD * 3


def robust_box(mask: np.ndarray, y_off: int = 0):
    ys, xs = np.where(mask)
    if len(xs) == 0:
        return None
    x0, x1 = np.percentile(xs, [0.5, 99.5]).astype(int)
    y0, y1 = np.percentile(ys, [0.5, 99.5]).astype(int)
    return int(x0), int(y0) + y_off, int(x1), int(y1) + y_off


def feather_mask(w: int, h: int, feather: int) -> Image.Image:
    mask = Image.new("L", (w, h), 0)
    inner = Image.new("L", (max(w - 2 * feather, 1), max(h - 2 * feather, 1)), 255)
    mask.paste(inner, (feather, feather))
    return mask.filter(ImageFilter.GaussianBlur(feather / 2.2))


def apply_mask(patch: Image.Image, mask: Image.Image, extra: np.ndarray | None = None) -> Image.Image:
    a = np.asarray(patch.getchannel("A")).astype(np.float32) * np.asarray(mask).astype(np.float32) / 255.0
    if extra is not None:
        a = a * extra
    patch.putalpha(Image.fromarray(a.clip(0, 255).astype(np.uint8)))
    return patch


def load_frames(cid: str) -> dict[str, Path]:
    d = SRC / cid
    frames = {}
    for p in sorted(d.iterdir()):
        if p.suffix.lower() in (".jpg", ".jpeg", ".png"):
            frames[p.stem] = p
    if "base_neutral" not in frames:
        raise SystemExit(f"{cid}: source/{cid}/base_neutral.* yok")
    return frames


def build(cid: str) -> None:
    frames = load_frames(cid)
    base_img = Image.open(frames["base_neutral"]).convert("RGB")
    size = base_img.size
    poses, faces = {}, {}
    for name, path in frames.items():
        if name == "base_neutral":
            continue
        im = Image.open(path).convert("RGB")
        if im.size != size:
            im = im.resize(size, Image.LANCZOS)
        (poses if name.startswith("pose_") else faces)[name] = im

    head_rows = (0, int(size[1] * HEAD_FRACTION))
    if faces:
        union = np.zeros((head_rows[1], size[0]), dtype=bool)
        for im in faces.values():
            union |= diff_mask(base_img, im, head_rows)
        b = robust_box(union)
        box = (b[0] - PATCH_PAD, b[1] - PATCH_PAD, b[2] + PATCH_PAD, b[3] + PATCH_PAD)
    else:  # ifade kareleri henüz yok: geçici yüz bölgesi
        box = (0, 0, size[0], head_rows[1])
    box = (max(box[0], 0), max(box[1], 0), min(box[2], size[0]), min(box[3], size[1]))

    bg = backdrop_greenness(base_img)
    keyed = key_green(base_img, bg)
    bbox = keyed.getchannel("A").point(lambda v: 255 if v > 40 else 0).getbbox()
    crop = (max(bbox[0] - 8, 0), max(bbox[1] - 8, 0), min(bbox[2] + 8, size[0]), min(bbox[3] + 8, size[1]))
    box = (max(box[0], crop[0]), max(box[1], crop[1]), min(box[2], crop[2]), min(box[3], crop[3]))

    out_dir = OUT / cid
    out_dir.mkdir(parents=True, exist_ok=True)
    for old in out_dir.glob("*.png"):
        old.unlink()
    keyed.crop(crop).save(out_dir / "body.png")

    pw, ph = box[2] - box[0], box[3] - box[1]
    # Eliptik yüz maskesi: yalnızca yüz ve sakal bölgesini alır, omuz/göğüs kumaşına hiç taşmaz
    yy, xx = np.mgrid[0:ph, 0:pw].astype(np.float32)
    nx = (xx - pw * 0.50) / (pw * 0.30)
    ny = (yy - ph * 0.43) / (ph * 0.36)
    ellipse = 1.0 - np.clip((np.sqrt(nx * nx + ny * ny) - 0.62) / 0.34, 0.0, 1.0)
    mask = Image.fromarray((ellipse * 255.0).clip(0, 255).astype(np.uint8), "L")

    # ağız çizgisi: ağız karelerinin nötr kareden güçlü farkının tepe noktasından bulunur (yama koordinatı)
    mouth_y = int(ph * 0.50)
    b_patch = np.asarray(base_img.convert("RGB"))[box[1]:box[3], box[0]:box[2]].astype(np.int16)
    mouth_diffs = [np.abs(np.asarray(im.convert("RGB"))[box[1]:box[3], box[0]:box[2]].astype(np.int16) - b_patch).sum(axis=2)
                   for n, im in faces.items() if n.startswith(FACE_OPEN_MOUTH)]
    if mouth_diffs:
        md = np.maximum.reduce(mouth_diffs)
        row_energy = (md > 90).sum(axis=1)
        row_energy[:int(ph * 0.35)] = 0
        if row_energy.max() > 4:
            peak_y = int(np.argmax(row_energy))
            mouth_y = max(peak_y - 14, int(ph * 0.42))

    # üst yüz maskesi: göz ve yanakları tam korur, bıyık/dudak üstünde yumuşakça sıfırlanır
    ramp = np.ones((ph, pw), dtype=np.float32)
    top, bottom = max(mouth_y - 22, 0), min(mouth_y + 2, ph)
    ramp[top:bottom, :] = np.linspace(1.0, 0.0, bottom - top, dtype=np.float32)[:, None]
    ramp[bottom:, :] = 0.0

    saved, ups = [], []
    for name, im in faces.items():
        patch = apply_mask(key_green(im, bg).crop(box), mask)
        patch.save(out_dir / f"face_{name}.png")
        saved.append(name)
        if not name.startswith(FACE_OPEN_MOUTH):
            up = apply_mask(key_green(im, bg).crop(box), mask, ramp)
            up.save(out_dir / f"up_{name}.png")
            ups.append(name)

    # baş katmanı: yüz yamalarıyla aynı eliptik maske
    head = apply_mask(keyed.crop(box), mask)
    head.save(out_dir / "head.png")

    # duruş (jest) yamaları: baş bölgesinin altındaki fark
    pose_meta = {}
    body_rows = (box[3], size[1])
    for name, im in poses.items():
        pm = diff_mask(base_img, im, body_rows)
        pb = robust_box(pm, body_rows[0])
        if not pb:
            continue
        r = (max(pb[0] - POSE_PAD, crop[0]), max(pb[1] - POSE_PAD, box[3] - 40),
             min(pb[2] + POSE_PAD, crop[2]), min(pb[3] + POSE_PAD, crop[3]))
        patch = apply_mask(key_green(im, bg).crop(r), feather_mask(r[2] - r[0], r[3] - r[1], POSE_FEATHER))
        patch.save(out_dir / f"{name}.png")
        pose_meta[name] = [r[0] - crop[0], r[1] - crop[1], r[2] - r[0], r[3] - r[1]]

    DATA.parent.mkdir(parents=True, exist_ok=True)
    data = json.loads(DATA.read_text()) if DATA.exists() else {}
    data[cid] = {
        "body_size": [crop[2] - crop[0], crop[3] - crop[1]],
        "face_rect": [box[0] - crop[0], box[1] - crop[1], pw, ph],
        "neck": [round(pw * 0.5, 1), round(ph * 0.66, 1)],
        "mouth_y": mouth_y,
        "expressions": sorted(saved),
        "upper": sorted(ups),
        "poses": pose_meta,
    }
    DATA.write_text(json.dumps(data, indent=2, ensure_ascii=False, sort_keys=True) + "\n")
    print(f"{cid}: yüz {len(saved)} (üst {len(ups)}), duruş {len(pose_meta)}, ağız çizgisi {mouth_y}")


if __name__ == "__main__":
    ids = sys.argv[1:] or sorted(p.name for p in SRC.iterdir() if p.is_dir())
    for i in ids:
        build(i)
