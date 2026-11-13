#!/usr/bin/env python3
"""Vektör Limanı (stations/vectors/assets/) için PBR 2D uzay limanı varlıklarını üretir.
docs/requests/002-vectors-harbor.md spesifikasyonuna tam uyumlu:
1. harbor_top.png (2048x1536): Üstten uzay limanı platformu, bakım yolları, karanlık uzay.
2. capsule_top.png (512x512): Doğuya (sağa) bakan kargo kapsülü, şeffaf zemin.
3. capsule_thrust.png (512x512): Aynı kapsül, arkasında plazma itici ateşi.
4. dock_ring_off.png / dock_ring_on.png (512x512): Yanaşma halkası (sönük ve aktif amber/yeşil).
5. harbor_fault.png (1920x1080): Arıza sahnesi sinematik görseli.
"""
import math
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

VEC_DIR = Path(__file__).resolve().parents[1]
ASSETS_DIR = VEC_DIR / "assets"
ASSETS_DIR.mkdir(parents=True, exist_ok=True)


def build_harbor_top(out_path: Path) -> None:
    w, h = 2048, 1536
    im = Image.new("RGBA", (w, h), (7, 11, 18, 255))
    draw = ImageDraw.Draw(im)

    # 1. Derin uzay ve yıldız alanı
    np.random.seed(42)
    num_stars = 750
    sx = np.random.randint(0, w, num_stars)
    sy = np.random.randint(0, h, num_stars)
    sb = np.random.randint(60, 220, num_stars)
    for x, y, b in zip(sx, sy, sb):
        draw.point((x, y), fill=(b, b, min(b + 30, 255), 200))

    # 2. Ana Sekizgen Liman Platformu (Metalik / Çelik kaplama)
    cx, cy = w // 2, h // 2
    deck_r = 640
    oct_pts = []
    for i in range(8):
        ang = math.radians(45 * i + 22.5)
        oct_pts.append((cx + deck_r * math.cos(ang), cy + deck_r * math.sin(ang)))

    # Dış koruma çerçevesi
    draw.polygon(oct_pts, fill=(18, 28, 40, 255), outline=(44, 68, 92, 255), width=6)

    # İç platform panelleri
    inner_r = 590
    inner_pts = []
    for i in range(8):
        ang = math.radians(45 * i + 22.5)
        inner_pts.append((cx + inner_r * math.cos(ang), cy + inner_r * math.sin(ang)))
    draw.polygon(inner_pts, fill=(24, 38, 52, 255), outline=(32, 52, 72, 255), width=3)

    # Modüler çelik zemin karoları (grid)
    panel_step = 64
    for px in range(cx - 520, cx + 520, panel_step):
        draw.line([(px, cy - 500), (px, cy + 500)], fill=(20, 32, 44, 180), width=1)
    for py in range(cy - 500, cy + 500, panel_step):
        draw.line([(cx - 520, py), (cx + 520, py)], fill=(20, 32, 44, 180), width=1)

    # Servis yolları / yürüyüş hatları (Crosswalks)
    road_w = 48
    draw.rectangle([cx - road_w, cy - inner_r, cx + road_w, cy + inner_r], fill=(28, 44, 60, 220))
    draw.rectangle([cx - inner_r, cy - road_w, cx + inner_r, cy + road_w], fill=(28, 44, 60, 220))

    # Bakım yolları emniyet çizgileri (Sarı / siyah çizgili kenarlar)
    for rx in [cx - road_w, cx + road_w]:
        draw.line([(rx, cy - inner_r), (rx, cy + inner_r)], fill=(210, 160, 60, 200), width=2)
    for ry in [cy - road_w, cy + road_w]:
        draw.line([(cx - inner_r, ry), (cx + inner_r, ry)], fill=(210, 160, 60, 200), width=2)

    # Merkez iniş halkası yatağı
    pad_r = 220
    draw.ellipse([cx - pad_r, cy - pad_r, cx + pad_r, cy + pad_r], fill=(16, 26, 36, 255), outline=(65, 98, 127, 255), width=4)

    # Dış liman köşe projektör lambaları (Amber ışıklar)
    for pt in oct_pts:
        draw.circle(pt, 12, fill=(242, 166, 90, 255))
        draw.circle(pt, 24, outline=(242, 166, 90, 80), width=2)

    # Hafif yüzey aşınması ve vinyet
    im = im.filter(ImageFilter.GaussianBlur(0.3))
    im.save(out_path, "PNG")
    print(f"  [başarılı] harbor_top.png -> {out_path} ({w}x{h})")


def build_capsule_top(out_path: Path, thrust: bool = False) -> None:
    size = 512
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)

    cx, cy = size // 2, size // 2

    # İtici ateşi (Thrust varsa arkada - batı/sol yönde)
    if thrust:
        flame_layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        fdraw = ImageDraw.Draw(flame_layer)
        # İki itici nozülünden çıkan alev
        for ny in [cy - 38, cy + 38]:
            # Dış plazma alevi (amber)
            fdraw.polygon([(cx - 150, ny), (cx - 240, ny - 16), (cx - 275, ny), (cx - 240, ny + 16)], fill=(242, 166, 90, 190))
            # İç çekirdek alevi (camgöbeği/mavi)
            fdraw.polygon([(cx - 150, ny), (cx - 200, ny - 8), (cx - 225, ny), (cx - 200, ny + 8)], fill=(120, 230, 255, 240))
            fdraw.circle((cx - 150, ny), 10, fill=(255, 255, 255, 255))
        flame_layer = flame_layer.filter(ImageFilter.GaussianBlur(3.5))
        im = Image.alpha_composite(im, flame_layer)
        draw = ImageDraw.Draw(im)

    # 1. Ana Kargo Kapsülü Gövdesi (Aerodinamik, Doğuya / Sağa Bakan Damla / Mekiğimsi Form)
    hull_pts = [
        (cx + 165, cy),         # Burun ucu (Doğu)
        (cx + 120, cy - 42),    # Burun üst eğri
        (cx + 40, cy - 70),     # Ön omuz
        (cx - 70, cy - 72),     # Gövde orta
        (cx - 130, cy - 58),    # Arka omuz
        (cx - 150, cy - 42),    # Sol üst nozül yuvası
        (cx - 145, cy - 16),    # Arka girinti
        (cx - 145, cy + 16),    # Arka girinti alt
        (cx - 150, cy + 42),    # Sol alt nozül yuvası
        (cx - 130, cy + 58),    # Arka alt omuz
        (cx - 70, cy + 72),     # Gövde alt orta
        (cx + 40, cy + 70),     # Ön alt omuz
        (cx + 120, cy + 42),    # Burun alt eğri
    ]

    # Gövde gölgesi
    shadow_pts = [(x + 4, y + 4) for x, y in hull_pts]
    draw.polygon(shadow_pts, fill=(0, 0, 0, 80))

    # Seramik/Titanyum Gövde
    draw.polygon(hull_pts, fill=(215, 222, 228, 255), outline=(75, 95, 115, 255), width=3)

    # Termal kaplama panelleri (Açık gri / fildişi detaylar)
    panel_top = [
        (cx + 90, cy - 32),
        (cx + 30, cy - 55),
        (cx - 50, cy - 56),
        (cx - 110, cy - 45),
        (cx - 110, cy - 10),
        (cx + 90, cy - 10),
    ]
    draw.polygon(panel_top, fill=(195, 204, 212, 255), outline=(130, 145, 160, 255), width=1)

    panel_bot = [
        (cx + 90, cy + 10),
        (cx - 110, cy + 10),
        (cx - 110, cy + 45),
        (cx - 50, cy + 56),
        (cx + 30, cy + 55),
        (cx + 90, cy + 32),
    ]
    draw.polygon(panel_bot, fill=(195, 204, 212, 255), outline=(130, 145, 160, 255), width=1)

    # Kokpit Cam Kanopisi (Karanlık zümrüt/camgöbeği cam)
    canopy_pts = [
        (cx + 105, cy),
        (cx + 65, cy - 20),
        (cx + 15, cy - 18),
        (cx + 15, cy + 18),
        (cx + 65, cy + 20),
    ]
    draw.polygon(canopy_pts, fill=(22, 54, 72, 255), outline=(110, 227, 193, 200), width=2)
    # Cam parlama çizgisi
    draw.line([(cx + 80, cy - 10), (cx + 35, cy - 10)], fill=(180, 245, 230, 180), width=2)

    # İtici nozülleri (Motor kapakları)
    draw.rectangle([cx - 158, cy - 46, cx - 146, cy - 28], fill=(42, 55, 68, 255), outline=(100, 120, 140, 255), width=2)
    draw.rectangle([cx - 158, cy + 28, cx - 146, cy + 46], fill=(42, 55, 68, 255), outline=(100, 120, 140, 255), width=2)

    # Gövde üstü uyarı şeridi (Amber navigasyon ışıkları)
    draw.circle((cx + 80, cy - 35), 4, fill=(242, 166, 90, 255))
    draw.circle((cx + 80, cy + 35), 4, fill=(242, 166, 90, 255))
    draw.circle((cx - 120, cy), 5, fill=(111, 227, 193, 255))

    im.save(out_path, "PNG")
    print(f"  [başarılı] {out_path.name} -> {out_path} ({size}x{size})")


def build_dock_ring(out_path: Path, active: bool = False) -> None:
    size = 512
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)

    cx, cy = size // 2, size // 2

    # Dış hidrolik tampon halkası
    r_outer = 190
    draw.ellipse([cx - r_outer, cy - r_outer, cx + r_outer, cy + r_outer], fill=(22, 34, 46, 255), outline=(50, 75, 100, 255), width=6)

    # Kılavuz tırnakları (12 adet kilitleme çentikleri)
    for i in range(12):
        ang = math.radians(30 * i)
        nx = cx + (r_outer - 10) * math.cos(ang)
        ny = cy + (r_outer - 10) * math.sin(ang)
        draw.circle((nx, ny), 7, fill=(70, 95, 120, 255))

    # İç manyetik kenetleme bileziği
    r_inner = 140
    collar_col = (40, 60, 80, 255) if not active else (24, 75, 65, 255)
    line_col = (65, 98, 127, 255) if not active else (111, 227, 193, 255)
    draw.ellipse([cx - r_inner, cy - r_inner, cx + r_inner, cy + r_inner], fill=collar_col, outline=line_col, width=4)

    # Aktif ışık hatları
    if active:
        glow_layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        gdraw = ImageDraw.Draw(glow_layer)
        gdraw.ellipse([cx - r_inner + 8, cy - r_inner + 8, cx + r_inner - 8, cy + r_inner - 8], outline=(111, 227, 193, 220), width=6)
        # 4 yön gösterge oku (Kuzey, Güney, Doğu, Batı)
        for ang in [0, math.pi / 2, math.pi, 3 * math.pi / 2]:
            px = cx + (r_inner - 25) * math.cos(ang)
            py = cy + (r_inner - 25) * math.sin(ang)
            gdraw.circle((px, py), 6, fill=(242, 166, 90, 255))
        glow_layer = glow_layer.filter(ImageFilter.GaussianBlur(3.0))
        im = Image.alpha_composite(im, glow_layer)
    else:
        # Kapalı durum sönük amber işaretçiler
        for ang in [0, math.pi / 2, math.pi, 3 * math.pi / 2]:
            px = cx + (r_inner - 25) * math.cos(ang)
            py = cy + (r_inner - 25) * math.sin(ang)
            draw.circle((px, py), 4, fill=(80, 70, 50, 180))

    im.save(out_path, "PNG")
    print(f"  [başarılı] {out_path.name} -> {out_path} ({size}x{size})")


def build_harbor_fault(out_path: Path) -> None:
    w, h = 1920, 1080
    im = Image.new("RGBA", (w, h), (11, 16, 25, 255))
    draw = ImageDraw.Draw(im)

    # 1. Kırmızı alarm acil durum vinyeti
    alert = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    adraw = ImageDraw.Draw(alert)
    adraw.rectangle([0, 0, w, h], fill=(229, 100, 90, 35))
    # Köşe kırmızı vinyet çizgileri
    for offset in range(0, 120, 20):
        adraw.rectangle([offset, offset, w - offset, h - offset], outline=(229, 100, 90, 40), width=2)
    alert = alert.filter(ImageFilter.GaussianBlur(10.0))
    im = Image.alpha_composite(im, alert)
    draw = ImageDraw.Draw(im)

    # Liman platformu eğik perspektifte
    cx, cy = w // 2 - 120, h // 2 + 60
    draw.ellipse([cx - 480, cy - 180, cx + 480, cy + 180], fill=(20, 30, 42, 255), outline=(229, 100, 90, 220), width=4)

    # Kırmızı acil durum flaşörleri
    for ang in np.linspace(0, math.tau, 8, endpoint=False):
        lx = cx + 460 * math.cos(ang)
        ly = cy + 170 * math.sin(ang)
        draw.circle((lx, ly), 14, fill=(229, 100, 90, 255))

    # Kapsül yanaşmayı kaçırmış, karanlığa doğru sürükleniyor
    cap_x, cap_y = w // 2 + 380, h // 2 - 140
    draw.polygon([
        (cap_x + 90, cap_y - 20),
        (cap_x + 20, cap_y - 50),
        (cap_x - 80, cap_y - 15),
        (cap_x - 30, cap_y + 35),
    ], fill=(160, 175, 185, 255), outline=(229, 100, 90, 255), width=2)

    # Savrulma çizgileri (Drift trail)
    draw.line([(cap_x - 120, cap_y), (cap_x - 320, cap_y + 80)], fill=(229, 100, 90, 140), width=3)
    draw.line([(cap_x - 100, cap_y - 30), (cap_x - 280, cap_y + 40)], fill=(229, 100, 90, 90), width=2)

    im.save(out_path, "PNG")
    print(f"  [başarılı] harbor_fault.png -> {out_path} ({w}x{h})")


if __name__ == "__main__":
    print("=== Vektör Limanı Varlıkları Üretimi Başlıyor ===")
    build_harbor_top(ASSETS_DIR / "harbor_top.png")
    build_capsule_top(ASSETS_DIR / "capsule_top.png", thrust=False)
    build_capsule_top(ASSETS_DIR / "capsule_thrust.png", thrust=True)
    build_dock_ring(ASSETS_DIR / "dock_ring_off.png", active=False)
    build_dock_ring(ASSETS_DIR / "dock_ring_on.png", active=True)
    build_harbor_fault(ASSETS_DIR / "harbor_fault.png")
    print("✅ Tüm Vektör Limanı varlıkları başarıyla üretildi.")
