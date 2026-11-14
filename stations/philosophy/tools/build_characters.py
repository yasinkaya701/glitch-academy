#!/usr/bin/env python3
"""source/<id>/*.jpg|png karelerinden oyun varlıklarını üretir.

Her karakter için:
1. Yeşil perdeyi temizler, gövdeyi kırpar (body.png) ve baş kutusunu (face_rect) kafa silüetinden bulur.
2. source/<id>/ altındaki mevcut AI ifade karelerini (mouth_open, mouth_mid, angry, eyes_closed vb.) işler.
3. Henüz ham AI karesi olmayan ifadeler için head.png piksel koordinatlarında doğrulanmış hassas göz, kaş
   ve dudak noktaları (HEAD_LM) + gerçek AI ağız/göz dokusu aktarımıyla doğal yüz yamalarını üretir.
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

HEAD_FRACTION = 0.28
DIFF_THRESHOLD = 14
PATCH_PAD = 18
POSE_PAD = 24
POSE_FEATHER = 22
FACE_OPEN_MOUTH = ("mouth_",)

# head.png koordinatlarında birebir doğrulanmış (cx, brow_y, eye_y, eye_dx, mouth_y, mouth_half_w):
HEAD_LM = {
    "socrates":  (201, 80,  96, 27, 140, 18),
    "plato":     (186, 74,  88, 25, 138, 17),
    "aristotle": (134, 76,  90, 23, 145, 15),
    "epicurus":  (131, 84,  98, 24, 154, 17),
    "kindi":     (145, 92, 105, 22, 153, 15),
    "farabi":    (145, 90, 104, 24, 153, 15),
    "ibn_sina":  (143, 92, 105, 22, 151, 15),
    "ibn_rushd": (156, 92, 105, 23, 154, 15),
}


def backdrop_greenness(img: Image.Image) -> float:
    a = np.asarray(img.convert("RGB")).astype(np.float32)
    border = np.concatenate([
        a[:20].reshape(-1, 3), a[-20:].reshape(-1, 3),
        a[:, :20].reshape(-1, 3), a[:, -20:].reshape(-1, 3),
    ])
    return float(np.median(border[:, 1] - np.maximum(border[:, 0], border[:, 2])))


def key_green(img: Image.Image, bg: float) -> Image.Image:
    a = np.asarray(img.convert("RGB")).astype(np.float32)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    greenness = g - np.maximum(r, b)
    lo, hi = bg * 0.30, bg * 0.80
    alpha = 1.0 - np.clip((greenness - lo) / max(hi - lo, 1.0), 0.0, 1.0)
    g2 = np.minimum(g, np.maximum(r, b) * 0.97)
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


def _bilinear_sample(arr: np.ndarray, src_y: np.ndarray, src_x: np.ndarray) -> np.ndarray:
    h, w, _ = arr.shape
    y = np.clip(src_y, 0.0, h - 1.001)
    x = np.clip(src_x, 0.0, w - 1.001)
    y0 = np.floor(y).astype(np.int32)
    x0 = np.floor(x).astype(np.int32)
    y1 = np.minimum(y0 + 1, h - 1)
    x1 = np.minimum(x0 + 1, w - 1)
    wy = (y - y0)[..., None]
    wx = (x - x0)[..., None]
    p00 = arr[y0, x0]
    p01 = arr[y0, x1]
    p10 = arr[y1, x0]
    p11 = arr[y1, x1]
    return (1.0 - wy) * ((1.0 - wx) * p00 + wx * p01) + wy * ((1.0 - wx) * p10 + wx * p11)


def synthesize_expression(
    base_patch: Image.Image,
    cid: str,
    kind: str,
    open_patch_ref: Image.Image | None = None,
) -> Image.Image:
    """head.png içindeki tam göz, kaş ve dudak koordinatlarından doğal ifade yaması üretir."""
    arr = np.asarray(base_patch.convert("RGBA")).astype(np.float32)
    h, w, _ = arr.shape
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)

    cx, brow_y, eye_y, edx, mouth_y, mw = [
        float(v) for v in HEAD_LM.get(cid, (w // 2, 86, 100, 24, 148, 16))
    ]
    lx, rx = cx - edx, cx + edx

    src_y = yy.copy()
    src_x = xx.copy()

    if kind == "mouth_mid" and open_patch_ref is not None:
        op = np.asarray(open_patch_ref.convert("RGBA")).astype(np.float32)
        below = np.clip((yy - (mouth_y - 4.0)) / 48.0, 0.0, 1.0) * (1.0 - np.clip((yy - (mouth_y + 52.0)) / 30.0, 0.0, 1.0))
        horiz = np.exp(-0.5 * ((xx - cx) / (mw * 1.6)) ** 2)
        half_warp = _bilinear_sample(arr, yy - 4.0 * below * horiz, xx)
        blend = 0.58 * horiz[..., None] * np.exp(-0.5 * ((yy - (mouth_y + 6.0)) / 18.0) ** 2)[..., None]
        out = half_warp * (1.0 - blend) + op * blend
        return Image.fromarray(out.clip(0, 255).astype(np.uint8), "RGBA")

    if kind in ("mouth_mid", "mouth_open"):
        drop_px = 6.5 if kind == "mouth_mid" else 12.0
        # Yalnızca dudak birleşim çizgisi (mouth_y) altındaki alt dudak, çene ve sakalı aşağı indir
        below = np.clip((yy - (mouth_y - 1.5)) / 12.0, 0.0, 1.0)
        fade_chin = 1.0 - np.clip((yy - (mouth_y + 42.0)) / 32.0, 0.0, 1.0)
        horiz = np.exp(-0.5 * ((xx - cx) / (mw * 1.45)) ** 2)
        src_y -= drop_px * below * fade_chin * horiz
        warped = _bilinear_sample(arr, src_y, src_x)

        # Dudakların ayrıldığı boşluk: tam (cx, mouth_y + drop_px*0.38) merkezinde
        cav_cy = mouth_y + drop_px * 0.38
        cav_ry = max(drop_px * 0.40, 2.6)
        cav_rx = mw * (0.72 if kind == "mouth_mid" else 0.88)
        nx = (xx - cx) / cav_rx
        ny = (yy - (cav_cy + 0.9 * nx * nx)) / cav_ry
        dist = np.sqrt(nx * nx + ny * ny)
        cav_mask = np.clip(1.0 - np.clip((dist - 0.42) / 0.58, 0.0, 1.0), 0.0, 1.0)

        # Karakterin kendi gölge tonuna uyumlu doğal koyu ağız içi + hafif üst diş/alt dudak gölgesi
        inner = np.zeros((h, w, 3), dtype=np.float32)
        inner[..., 0] = 24.0
        inner[..., 1] = 13.0
        inner[..., 2] = 12.0
        teeth = np.exp(-0.5 * ((ny + 0.42) / 0.24) ** 2) * np.exp(-0.5 * (nx / 0.55) ** 2)
        inner[..., 0] += teeth * 85.0
        inner[..., 1] += teeth * 78.0
        inner[..., 2] += teeth * 68.0

        warped[..., :3] = warped[..., :3] * (1.0 - 0.90 * cav_mask[..., None]) + inner * (0.90 * cav_mask[..., None])
        return Image.fromarray(warped.clip(0, 255).astype(np.uint8), "RGBA")

    if kind == "eyes_closed":
        # Her iki gözde (lx, rx, eye_y): üst göz kapağı derisini (eye_y - 6px) göz bebeğinin üstüne örter
        warped = arr.copy()
        for ex in (lx, rx):
            dx = (xx - ex) / 11.5
            dy = (yy - eye_y) / 5.2
            r2 = dx * dx + dy * dy
            lid_mask = np.clip(1.0 - np.clip((np.sqrt(r2) - 0.55) / 0.45, 0.0, 1.0), 0.0, 1.0)
            # Üst göz kapağı derisinden (eye_y - 6px) yumuşak örnekleme
            skin_src_y = np.clip(eye_y - 6.0 + (yy - eye_y) * 0.25, 0.0, h - 1.001)
            lid_skin = _bilinear_sample(arr, skin_src_y, xx)
            # Göz kapağı kıvrımı ve alt kirpik çizgisi
            lash_y = eye_y + 2.2 - 0.8 * (dx * dx)
            lash = np.clip(1.0 - dx * dx, 0.0, 1.0) * np.exp(-0.5 * ((yy - lash_y) / 1.1) ** 2)
            lid_skin[..., :3] *= (1.0 - 0.48 * lash[..., None])
            warped[..., :3] = warped[..., :3] * (1.0 - lid_mask[..., None]) + lid_skin[..., :3] * lid_mask[..., None]
        return Image.fromarray(warped.clip(0, 255).astype(np.uint8), "RGBA")

    if kind == "angry":
        # İç kaşları (brow_y) aşağı ve ortaya doğru çat
        brow_band = np.exp(-0.5 * ((yy - brow_y) / 9.0) ** 2) * np.exp(-0.5 * ((xx - cx) / 34.0) ** 2)
        inner_w = np.exp(-0.5 * ((xx - cx) / 20.0) ** 2)
        src_y -= 5.8 * brow_band * inner_w
        src_x += np.sign(xx - cx) * 3.5 * brow_band
        # Ağız köşelerini hafif aşağı çek
        corners = np.exp(-0.5 * ((yy - mouth_y) / 8.0) ** 2) * (
            np.exp(-0.5 * ((xx - (cx - mw)) / 8.0) ** 2)
            + np.exp(-0.5 * ((xx - (cx + mw)) / 8.0) ** 2)
        )
        src_y -= 3.5 * corners
        warped = _bilinear_sample(arr, src_y, src_x)
        # Kaş arası çatma çizgisi (glabella)
        glabella = np.exp(-0.5 * ((xx - cx) / 3.0) ** 2) * np.exp(-0.5 * ((yy - brow_y) / 7.0) ** 2)
        warped[..., :3] *= (1.0 - 0.30 * glabella[..., None])
        # Elmacık kemiklerinde hafif sıcaklık
        cheek_y = eye_y + 16.0
        cheek = np.exp(-0.5 * ((yy - cheek_y) / 8.0) ** 2) * (
            np.exp(-0.5 * ((xx - lx) / 12.0) ** 2) + np.exp(-0.5 * ((xx - rx) / 12.0) ** 2)
        )
        skin_mask = np.clip((warped[..., 0] - warped[..., 2]) / 35.0, 0.0, 1.0)
        flush = cheek * skin_mask
        warped[..., 0] = np.clip(warped[..., 0] + flush * 20.0, 0, 255)
        warped[..., 1] = np.clip(warped[..., 1] - flush * 8.0, 0, 255)
        warped[..., 2] = np.clip(warped[..., 2] - flush * 8.0, 0, 255)
        return Image.fromarray(warped.clip(0, 255).astype(np.uint8), "RGBA")

    if kind == "confused":
        lb = np.exp(-0.5 * ((xx - lx) / 14.0) ** 2) * np.exp(-0.5 * ((yy - brow_y) / 9.0) ** 2)
        rb = np.exp(-0.5 * ((xx - rx) / 14.0) ** 2) * np.exp(-0.5 * ((yy - brow_y) / 9.0) ** 2)
        src_y += 5.5 * lb - 3.2 * rb
        warped = _bilinear_sample(arr, src_y, src_x)
        return Image.fromarray(warped.clip(0, 255).astype(np.uint8), "RGBA")

    if kind == "smile":
        corners = np.exp(-0.5 * ((yy - mouth_y) / 10.0) ** 2) * (
            np.exp(-0.5 * ((xx - (cx - mw)) / 10.0) ** 2)
            + np.exp(-0.5 * ((xx - (cx + mw)) / 10.0) ** 2)
        )
        src_y += 4.8 * corners
        warped = _bilinear_sample(arr, src_y, src_x)
        return Image.fromarray(warped.clip(0, 255).astype(np.uint8), "RGBA")

    return base_patch


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

    bg = backdrop_greenness(base_img)
    keyed = key_green(base_img, bg)
    bbox = keyed.getchannel("A").point(lambda v: 255 if v > 40 else 0).getbbox()
    crop = (max(bbox[0] - 8, 0), max(bbox[1] - 8, 0), min(bbox[2] + 8, size[0]), min(bbox[3] + 8, size[1]))

    head_rows = (crop[1], crop[1] + int((crop[3] - crop[1]) * HEAD_FRACTION))
    if faces:
        union = np.zeros((head_rows[1], size[0]), dtype=bool)
        for im in faces.values():
            union |= diff_mask(base_img, im, (0, head_rows[1]))
        b = robust_box(union)
        box = (b[0] - PATCH_PAD, b[1] - PATCH_PAD, b[2] + PATCH_PAD, b[3] + PATCH_PAD)
    else:
        top_alpha = np.asarray(keyed.getchannel("A"))[crop[1]:crop[1] + int((crop[3] - crop[1]) * 0.22), :] > 60
        b = robust_box(top_alpha, crop[1])
        box = (b[0] - 16, crop[1], b[2] + 16, head_rows[1])
    box = (max(box[0], crop[0]), max(box[1], crop[1]), min(box[2], crop[2]), min(box[3], crop[3]))

    out_dir = OUT / cid
    out_dir.mkdir(parents=True, exist_ok=True)
    for old in out_dir.glob("*.png"):
        old.unlink()
    keyed.crop(crop).save(out_dir / "body.png")

    pw, ph = box[2] - box[0], box[3] - box[1]
    patch_offset = (box[0] - crop[0], box[1] - crop[1])

    yy, xx = np.mgrid[0:ph, 0:pw].astype(np.float32)
    nx = (xx - pw * 0.50) / (pw * 0.34)
    ny = (yy - ph * 0.45) / (ph * 0.39)
    ellipse = 1.0 - np.clip((np.sqrt(nx * nx + ny * ny) - 0.64) / 0.32, 0.0, 1.0)
    mask = Image.fromarray((ellipse * 255.0).clip(0, 255).astype(np.uint8), "L")

    _, _, _, _, mouth_y_h, _ = HEAD_LM.get(cid, (pw // 2, 86, 100, 24, 148, 16))
    mouth_y = int(mouth_y_h)

    ramp = np.ones((ph, pw), dtype=np.float32)
    top, bottom = max(mouth_y - 22, 0), min(mouth_y + 2, ph)
    ramp[top:bottom, :] = np.linspace(1.0, 0.0, bottom - top, dtype=np.float32)[:, None]
    ramp[bottom:, :] = 0.0

    base_crop_rgba = keyed.crop(box)
    head = apply_mask(base_crop_rgba.copy(), mask)
    head.save(out_dir / "head.png")

    open_ref = key_green(faces["mouth_open"], bg).crop(box) if "mouth_open" in faces else None

    target_expressions = ["mouth_mid", "mouth_open", "eyes_closed", "angry", "confused", "smile"]
    for extra_name in faces.keys():
        if extra_name not in target_expressions:
            target_expressions.append(extra_name)

    saved, ups = [], []
    for name in target_expressions:
        if name in faces:
            raw_rgba = key_green(faces[name], bg).crop(box)
        else:
            raw_rgba = synthesize_expression(base_crop_rgba, cid, name, open_ref)
        patch = apply_mask(raw_rgba.copy(), mask)
        patch.save(out_dir / f"face_{name}.png")
        saved.append(name)
        if not name.startswith(FACE_OPEN_MOUTH):
            up = apply_mask(raw_rgba.copy(), mask, ramp)
            up.save(out_dir / f"up_{name}.png")
            ups.append(name)

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
        "face_rect": [patch_offset[0], patch_offset[1], pw, ph],
        "neck": [round(pw * 0.5, 1), round(ph * 0.66, 1)],
        "mouth_y": mouth_y,
        "expressions": sorted(saved),
        "upper": sorted(ups),
        "poses": pose_meta,
    }
    DATA.write_text(json.dumps(data, indent=2, ensure_ascii=False, sort_keys=True) + "\n")
    print(f"{cid}: yüz {len(saved)} (üst {len(ups)}), kutu {pw}x{ph}, ağız çizgisi {mouth_y}")


if __name__ == "__main__":
    ids = sys.argv[1:] or sorted(p.name for p in SRC.iterdir() if p.is_dir())
    for i in ids:
        build(i)
