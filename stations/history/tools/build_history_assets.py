#!/usr/bin/env python3
"""Tarih Meydanı (stations/history/) için 6 tarihî şahsiyetin karakter riglerini
(body.png, face_*, up_*) ve 6 dönem arka planını üretir."""
import json
from pathlib import Path
import numpy as np
from PIL import Image, ImageFilter, ImageEnhance, ImageDraw

HIST_ROOT = Path(__file__).resolve().parents[1]
PHIL_ROOT = HIST_ROOT.parent / "philosophy"
OUT_CHARS = HIST_ROOT / "assets" / "characters"
OUT_BGS = HIST_ROOT / "assets" / "backgrounds"
DATA_CHARS = HIST_ROOT / "data" / "characters.json"

METE_RAW = Path("/Users/afurkanmac/.gemini/antigravity/brain/194e5e14-eca6-4bd6-a698-3999eec856b8/mete_han_raw_base_1794585448361.jpg")
KANUNI_RAW = Path("/Users/afurkanmac/.gemini/antigravity/brain/194e5e14-eca6-4bd6-a698-3999eec856b8/kanuni_sultan_suleyman_1794585452697.jpg")
ATA_RAW = Path("/tmp/hist_ref/ataturk_founder.jpg")


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


def feather_mask(w: int, h: int, feather: int) -> Image.Image:
    mask = Image.new("L", (w, h), 0)
    inner = Image.new("L", (max(w - 2 * feather, 1), max(h - 2 * feather, 1)), 255)
    mask.paste(inner, (feather, feather))
    return mask.filter(ImageFilter.GaussianBlur(feather / 2.2))


def apply_mask(patch: Image.Image, mask: Image.Image) -> Image.Image:
    a = np.asarray(patch.getchannel("A")).astype(np.float32) * np.asarray(mask).astype(np.float32) / 255.0
    patch.putalpha(Image.fromarray(a.clip(0, 255).astype(np.uint8)))
    return patch


def key_dark_bg(img: Image.Image, thresh: float = 16.0) -> Image.Image:
    a = np.asarray(img.convert("RGB")).astype(np.float32)
    h, w, _ = a.shape
    border = np.concatenate([
        a[:14, :, :].reshape(-1, 3),
        a[:, :14, :].reshape(-1, 3),
        a[:, -14:, :].reshape(-1, 3),
    ], axis=0)
    bg_col = np.median(border, axis=0)
    dist = np.linalg.norm(a - bg_col[None, None, :], axis=-1)
    alpha = np.clip((dist - thresh) / 18.0, 0.0, 1.0)
    yy, xx = np.mgrid[0:h, 0:w]
    center_mask = ((xx > w * 0.28) & (xx < w * 0.72) & (yy > h * 0.24)).astype(np.float32)
    alpha = np.maximum(alpha, center_mask * (dist > 6.0))
    im = Image.fromarray(np.dstack([a, alpha * 255.0]).clip(0, 255).astype(np.uint8), "RGBA")
    al = im.getchannel("A").filter(ImageFilter.MinFilter(3)).filter(ImageFilter.GaussianBlur(1.2))
    im.putalpha(al)
    return im


def key_ataturk_portrait(raw_img: Image.Image) -> Image.Image:
    aw, ah = raw_img.size
    crop = raw_img.crop((int(aw * 0.245), int(ah * 0.288), int(aw * 0.745), int(ah * 0.778))).resize(
        (860, 1140), Image.Resampling.LANCZOS
    )
    crop = ImageEnhance.Contrast(crop).enhance(1.12)
    crop = ImageEnhance.Color(crop).enhance(1.08)
    a = np.asarray(crop.convert("RGB")).astype(np.float32)
    h, w, _ = a.shape
    yy, xx = np.mgrid[0:h, 0:w]
    nx = (xx - w * 0.485) / (w * 0.5)
    ny = yy / float(h)

    # Kalpak + head + suit silhouette
    kalpak_d = (nx / 0.205) ** 2 + ((ny - 0.16) / 0.145) ** 2
    head_d = (nx / 0.175) ** 2 + ((ny - 0.30) / 0.125) ** 2
    neck_d = (nx / 0.135) ** 2 + ((ny - 0.42) / 0.075) ** 2
    shld_w = np.clip(0.14 + (ny - 0.41) * 1.45, 0.14, 0.48)
    suit_mask = (ny >= 0.41) & (np.abs(nx) <= shld_w) & (
        (((nx / 0.46) ** 2 + ((ny - 0.74) / 0.36) ** 2) <= 1.06) | (ny > 0.62)
    )
    sil = (kalpak_d <= 1.0) | (head_d <= 1.0) | (neck_d <= 1.0) | suit_mask

    border = np.concatenate([
        a[int(h * 0.06):int(h * 0.34), :45].reshape(-1, 3),
        a[int(h * 0.06):int(h * 0.34), -45:].reshape(-1, 3),
    ], axis=0)
    bg_med = np.median(border, axis=0)
    dist_bg = np.linalg.norm(a - bg_med[None, None, :], axis=-1)
    lum = a.mean(axis=-1)
    is_fg = (lum < 52.0) | ((a[..., 0] - a[..., 2]) > 26.0) | (dist_bg > 30.0)
    core = (kalpak_d <= 0.72) | (head_d <= 0.80) | ((ny > 0.48) & (np.abs(nx) < 0.35))
    mask = (sil & (is_fg | core)).astype(np.float32) * 255.0
    m_im = Image.fromarray(mask.astype(np.uint8), "L").filter(ImageFilter.MedianFilter(5)).filter(
        ImageFilter.GaussianBlur(2.2)
    )
    out = crop.convert("RGBA")
    out.putalpha(m_im)
    return out


def make_alparslan_from_mete(mete_rgba: Image.Image) -> Image.Image:
    """Mete Han zırhlı gövdesini Büyük Selçuklu (turkuaz-gümüş zırh + beyaz Malazgirt kaftanı) stiline dönüştürür."""
    arr = np.asarray(mete_rgba).astype(np.float32)
    h, w, _ = arr.shape
    r, g, b, al = arr[..., 0], arr[..., 1], arr[..., 2], arr[..., 3]
    yy, xx = np.mgrid[0:h, 0:w]
    ny = yy / float(h)

    # Kırmızı kaftanı (r > g*1.35 ve ny > 0.35) Selçuklu beyaz/krem Malazgirt kaftanına ve turkuaz bordüre dönüştür
    red_robe = np.clip((r - np.maximum(g, b) - 18.0) / 45.0, 0.0, 1.0) * (ny > 0.34)
    lum = 0.299 * r + 0.587 * g + 0.114 * b
    white_r = np.clip(lum * 1.45 + 55.0, 0, 245)
    white_g = np.clip(lum * 1.42 + 52.0, 0, 242)
    white_b = np.clip(lum * 1.35 + 44.0, 0, 232)
    r = r * (1.0 - red_robe) + white_r * red_robe
    g = g * (1.0 - red_robe) + white_g * red_robe
    b = b * (1.0 - red_robe) + white_b * red_robe

    # Bronz lameller zırhı Selçuklu turkuaz-gümüş zırh tonuna kaydır (ny > 0.38)
    armor_zone = ((ny > 0.38) & (red_robe < 0.25)).astype(np.float32) * 0.42
    r2 = r * 0.82 + b * 0.18
    g2 = g * 1.05 + 12.0
    b2 = b * 1.18 + 22.0
    r = r * (1.0 - armor_zone) + r2 * armor_zone
    g = g * (1.0 - armor_zone) + g2 * armor_zone
    b = b * (1.0 - armor_zone) + b2 * armor_zone

    out = np.stack([r, g, b, al], axis=-1).clip(0, 255).astype(np.uint8)
    return Image.fromarray(out, "RGBA")


def make_fatih_from_kanuni(kanuni_rgba: Image.Image) -> Image.Image:
    """Osmanlı padişah portresini Fatih Sultan Mehmed'in kızıl-altın kaftanı, genç koyu sakalı ve kızıl taclı kavuğuna dönüştürür."""
    arr = np.asarray(kanuni_rgba).astype(np.float32)
    h, w, _ = arr.shape
    r, g, b, al = arr[..., 0], arr[..., 1], arr[..., 2], arr[..., 3]
    yy, xx = np.mgrid[0:h, 0:w]
    ny = yy / float(h)
    nx = (xx - w * 0.48) / (w * 0.5)

    # Yeşil kaftanı (g > r ve ny > 0.34) Fatih'in meşhur kızıl-bordo ve altın işlemeli kaftanına dönüştür
    green_robe = np.clip((g - r + 10.0) / 38.0, 0.0, 1.0) * (ny > 0.33)
    crim_r = np.clip(g * 1.38 + 28.0, 0, 235)
    crim_g = np.clip(r * 0.62, 0, 180)
    crim_b = np.clip(b * 0.65, 0, 160)
    r = r * (1.0 - green_robe) + crim_r * green_robe
    g = g * (1.0 - green_robe) + crim_g * green_robe
    b = b * (1.0 - green_robe) + crim_b * green_robe

    # Kır sakalı (ny in 0.25..0.35) Fatih'in genç koyu kestane/siyah sakalına dönüştür
    beard_box = np.exp(-((nx / 0.14) ** 2 + ((ny - 0.305) / 0.045) ** 2) * 1.6)
    grayness = np.clip(1.0 - (np.abs(r - g) + np.abs(g - b)) / 36.0, 0.0, 1.0) * (r > 75.0)
    b_mask = beard_box * grayness * 0.72
    r = r * (1.0 - b_mask) + (r * 0.34 + 14.0) * b_mask
    g = g * (1.0 - b_mask) + (g * 0.28 + 10.0) * b_mask
    b = b * (1.0 - b_mask) + (b * 0.25 + 8.0) * b_mask

    # Kavuk tepe ortasına Bellini portresindeki kızıl serpuş (taj) dokunuşu
    taj_mask = np.exp(-((nx / 0.075) ** 2 + ((ny - 0.065) / 0.045) ** 2) * 2.2) * (al > 120) * 0.78
    r = r * (1.0 - taj_mask) + 175.0 * taj_mask
    g = g * (1.0 - taj_mask) + 34.0 * taj_mask
    b = b * (1.0 - taj_mask) + 38.0 * taj_mask

    out = np.stack([r, g, b, al], axis=-1).clip(0, 255).astype(np.uint8)
    return Image.fromarray(out, "RGBA")


def synthesize_face_variants(head: Image.Image, lm: tuple[int, int, int, int, int, int]) -> dict[str, Image.Image]:
    """head.png ve (cx, brow_y, eye_y, eye_dx, mouth_y, mouth_half_w) ile tüm ifade yamalarını üretir."""
    cx, brow_y, eye_y, eye_dx, mouth_y, m_hw = lm
    w, h = head.size
    fmask = feather_mask(w, h, 18)
    out: dict[str, Image.Image] = {}
    out["face_neutral"] = apply_mask(head.copy(), fmask)

    for kind in ("mouth_mid", "mouth_open", "eyes_closed", "smile", "angry", "confused", "thinking"):
        arr = np.asarray(head.convert("RGBA")).astype(np.float32)
        yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
        src_y = yy.copy()
        src_x = xx.copy()

        if kind in ("mouth_mid", "mouth_open"):
            open_px = (m_hw * 0.28) if kind == "mouth_mid" else (m_hw * 0.56)
            jaw_rx = m_hw * 1.45
            jaw_ry = m_hw * 1.35
            dy_jaw = yy - mouth_y
            dx_jaw = xx - cx
            jaw_mask = (
                np.exp(-((dx_jaw / jaw_rx) ** 2 + (np.maximum(dy_jaw, 0.0) / jaw_ry) ** 2) * 1.65)
                * (dy_jaw > -3.0)
            )
            src_y -= jaw_mask * open_px
            arr = _bilinear_sample(arr, src_y, src_x)

            # Ağız boşluğu ve üst/alt dudak gölgesi
            cav_rx = m_hw * 0.82
            cav_ry = max(open_px * 0.72, 3.5)
            cav_cy = mouth_y + open_px * 0.36
            cav_d2 = ((xx - cx) / cav_rx) ** 2 + ((yy - cav_cy) / cav_ry) ** 2
            cav_w = np.exp(-cav_d2 * 2.1) * (cav_d2 < 1.25)
            cavity_rgb = np.zeros((h, w, 3), dtype=np.float32)
            cavity_rgb[..., 0] = 34.0
            cavity_rgb[..., 1] = 15.0
            cavity_rgb[..., 2] = 14.0
            tongue = np.exp(-(((xx - cx) / (cav_rx * 0.55)) ** 2 + ((yy - (cav_cy + cav_ry * 0.32)) / (cav_ry * 0.45)) ** 2) * 2.2)
            cavity_rgb[..., 0] += tongue * 52.0
            cavity_rgb[..., 1] += tongue * 18.0
            cavity_rgb[..., 2] += tongue * 16.0
            arr[..., :3] = arr[..., :3] * (1.0 - cav_w[..., None] * 0.90) + cavity_rgb * (cav_w[..., None] * 0.90)

        elif kind == "eyes_closed":
            for ex in (cx - eye_dx, cx + eye_dx):
                erx = eye_dx * 0.50
                ery = max(eye_dx * 0.24, 5.5)
                dx = (xx - ex) / erx
                dy = (yy - eye_y) / ery
                d2 = dx * dx + dy * dy
                lid = np.exp(-d2 * 1.7) * (d2 < 1.35)
                lid_src_y = np.clip(eye_y - ery * 0.85 + (yy - eye_y) * 0.22, 0, h - 1)
                lid_rgb = _bilinear_sample(arr, lid_src_y, xx)[..., :3] * 0.93
                lash_y = eye_y + ery * 0.22 - (dx * dx) * 1.4
                lash = np.exp(-((yy - lash_y) / 1.4) ** 2) * np.exp(-dx * dx * 1.4)
                lid_rgb = lid_rgb * (1.0 - lash[..., None] * 0.65) + np.array([28.0, 20.0, 16.0]) * (lash[..., None] * 0.65)
                arr[..., :3] = arr[..., :3] * (1.0 - lid[..., None] * 0.95) + lid_rgb * (lid[..., None] * 0.95)

        elif kind == "smile":
            for side in (-1.0, 1.0):
                corner_x = cx + side * m_hw * 0.92
                w_c = np.exp(-(((xx - corner_x) / (m_hw * 0.65)) ** 2 + ((yy - mouth_y) / (m_hw * 0.65)) ** 2) * 1.6)
                src_y += w_c * (m_hw * 0.24)
                cheek_x = cx + side * eye_dx * 0.92
                cheek_y = (eye_y + mouth_y) * 0.50
                w_ch = np.exp(-(((xx - cheek_x) / (eye_dx * 0.65)) ** 2 + ((yy - cheek_y) / (eye_dx * 0.55)) ** 2) * 1.6)
                src_y += w_ch * (eye_dx * 0.12)
            arr = _bilinear_sample(arr, src_y, src_x)

        elif kind == "angry":
            for side in (-1.0, 1.0):
                inner_x = cx + side * eye_dx * 0.44
                w_in = np.exp(-(((xx - inner_x) / (eye_dx * 0.55)) ** 2 + ((yy - brow_y) / (eye_dx * 0.48)) ** 2) * 1.6)
                src_y -= w_in * (eye_dx * 0.24)
                src_x += w_in * side * (eye_dx * 0.10)
            arr = _bilinear_sample(arr, src_y, src_x)
            furrow = np.exp(-(((xx - cx) / 5.0) ** 2 + ((yy - brow_y) / 9.0) ** 2) * 1.8)
            arr[..., :3] *= (1.0 - furrow[..., None] * 0.26)

        elif kind in ("confused", "thinking"):
            w_l = np.exp(-(((xx - (cx - eye_dx)) / (eye_dx * 0.72)) ** 2 + ((yy - brow_y) / (eye_dx * 0.55)) ** 2) * 1.5)
            w_r = np.exp(-(((xx - (cx + eye_dx)) / (eye_dx * 0.72)) ** 2 + ((yy - brow_y) / (eye_dx * 0.55)) ** 2) * 1.5)
            src_y += w_l * (eye_dx * 0.24)
            src_y -= w_r * (eye_dx * 0.16)
            arr = _bilinear_sample(arr, src_y, src_x)

        im_kind = apply_mask(Image.fromarray(arr.clip(0, 255).astype(np.uint8), "RGBA"), fmask)
        if kind in ("mouth_mid", "mouth_open", "eyes_closed", "smile", "angry", "confused"):
            out[f"face_{kind}"] = im_kind
        if kind in ("smile", "angry", "confused", "thinking"):
            out[f"up_{kind}"] = im_kind

    return out


def build_backgrounds() -> None:
    OUT_BGS.mkdir(parents=True, exist_ok=True)
    phil_bgs = PHIL_ROOT / "assets" / "backgrounds"
    mapping = [
        ("steppe_otuken", "epicurus_garden", (1.14, 0.96, 0.82), 1.08),
        ("malazgirt_plain", "agora_athens", (1.12, 1.02, 0.88), 1.06),
        ("topkapi_divan", "cordoba_courtyard", (1.10, 0.95, 0.90), 1.08),
        ("suleymaniye_terrace", "house_of_wisdom_baghdad", (1.05, 1.04, 0.94), 1.05),
        ("selimiye_dome_workshop", "avicenna_study", (1.02, 1.02, 1.06), 1.06),
        ("ankara_first_tbmm", "lyceum_peripatos", (1.08, 0.98, 0.92), 1.08),
    ]
    for target_name, src_name, rgb_mul, contrast in mapping:
        src_path = phil_bgs / f"{src_name}.png"
        if not src_path.exists():
            continue
        im = Image.open(src_path).convert("RGB")
        arr = np.asarray(im).astype(np.float32)
        arr[..., 0] *= rgb_mul[0]
        arr[..., 1] *= rgb_mul[1]
        arr[..., 2] *= rgb_mul[2]
        im_out = Image.fromarray(arr.clip(0, 255).astype(np.uint8), "RGB")
        im_out = ImageEnhance.Contrast(im_out).enhance(contrast)
        im_out.save(OUT_BGS / f"{target_name}.png")
        print("Saved background:", target_name)


def main() -> None:
    OUT_CHARS.mkdir(parents=True, exist_ok=True)
    build_backgrounds()

    mete_full = key_dark_bg(Image.open(METE_RAW))
    kanuni_full = key_dark_bg(Image.open(KANUNI_RAW))
    alparslan_full = make_alparslan_from_mete(mete_full)
    fatih_full = make_fatih_from_kanuni(kanuni_full)
    ata_full = key_ataturk_portrait(Image.open(ATA_RAW))

    # Mimar Sinan için Osmanlı başmimarı rigi (farabi gövde + çivit/taş mimar kaftanı + gerçek AI ifadeler)
    sinan_src_dir = PHIL_ROOT / "assets" / "characters" / "farabi"
    sinan_body = Image.open(sinan_src_dir / "body.png").convert("RGBA")
    s_arr = np.asarray(sinan_body).astype(np.float32)
    sh, sw, _ = s_arr.shape
    syy, _ = np.mgrid[0:sh, 0:sw]
    sny = syy / float(sh)
    # Kaftanı Mimar Sinan'ın çivit-kehribar mimar cübbesine dönüştür
    robe_w = (sny > 0.28).astype(np.float32) * 0.45
    sr, sg, sb = s_arr[..., 0], s_arr[..., 1], s_arr[..., 2]
    s_arr[..., 0] = sr * (1.0 - robe_w) + (sb * 0.85 + 22.0) * robe_w
    s_arr[..., 1] = sg * (1.0 - robe_w) + (sg * 0.95 + 14.0) * robe_w
    s_arr[..., 2] = sb * (1.0 - robe_w) + (sr * 1.12 + 28.0) * robe_w
    sinan_body = Image.fromarray(s_arr.clip(0, 255).astype(np.uint8), "RGBA")

    phil_meta = json.loads((PHIL_ROOT / "data" / "characters.json").read_text()).get("farabi", {})

    specs = [
        ("mete_han", mete_full, (244, 140, 160, 44, 258, 28), 0.34),
        ("alparslan", alparslan_full, (244, 140, 160, 44, 258, 28), 0.34),
        ("fatih", fatih_full, (135, 228, 250, 34, 332, 24), 0.34),
        ("kanuni", kanuni_full, (135, 228, 250, 34, 332, 24), 0.34),
        ("ataturk", ata_full, (101, 212, 232, 34, 326, 23), 0.36),
    ]

    manifest = {"figures": {}}

    for cid, full_im, lm, head_frac in specs:
        al = np.asarray(full_im.getchannel("A"))
        ys, xs = np.where(al > 24)
        body = full_im.crop((int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())))
        bw, bh = body.size
        hy1 = int(bh * head_frac)
        mal = np.asarray(body.getchannel("A"))[:hy1]
        hys, hxs = np.where(mal > 35)
        hx0 = max(0, int(np.percentile(hxs, 1)) - 18)
        hx1 = min(bw, int(np.percentile(hxs, 99)) + 18)
        hy0 = max(0, int(np.percentile(hys, 1)) - 18)
        hy1_pad = min(bh, hy1 + 18)

        head = body.crop((hx0, hy0, hx1, hy1_pad))
        cdir = OUT_CHARS / cid
        cdir.mkdir(parents=True, exist_ok=True)
        body.save(cdir / "body.png")

        variants = synthesize_face_variants(head, lm)
        faces_list = []
        uppers_meta = {}
        rect_list = [int(hx0), int(hy0), int(hx1 - hx0), int(hy1_pad - hy0)]
        for k, vim in variants.items():
            vim.save(cdir / f"{k}.png")
            if k.startswith("face_"):
                faces_list.append(k[5:])
            elif k.startswith("up_"):
                uppers_meta[k[3:]] = {"rect": rect_list}

        manifest["figures"][cid] = {
            "body_size": [int(bw), int(bh)],
            "face_rect": rect_list,
            "faces": sorted(faces_list),
            "uppers": uppers_meta,
        }
        print(f"{cid:12s} body={bw}x{bh} face_rect={rect_list}")

    # Mimar Sinan
    sdir = OUT_CHARS / "mimar_sinan"
    sdir.mkdir(parents=True, exist_ok=True)
    sinan_body.save(sdir / "body.png")
    for png in (PHIL_ROOT / "assets" / "characters" / "farabi").glob("*.png"):
        if png.name != "body.png":
            Image.open(png).save(sdir / png.name)
    manifest["figures"]["mimar_sinan"] = phil_meta
    print("mimar_sinan  copied full expression rig")

    DATA_CHARS.parent.mkdir(parents=True, exist_ok=True)
    DATA_CHARS.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n")
    print("Wrote", DATA_CHARS)


if __name__ == "__main__":
    main()
