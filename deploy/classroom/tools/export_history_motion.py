"""Build subtle, transparent mouth-motion frames from the classroom idle portraits."""

from pathlib import Path

from PIL import Image, ImageDraw


APP = Path(__file__).resolve().parents[1]
FIGURES = {
    # Mouth centers and widths are measured against each character's exported idle.webp.
    "mete_han": (138.0, 82.0, 5.1, (74, 47, 35), (39, 25, 22), (124, 74, 57)),
    "alparslan": (177.0, 86.0, 5.4, (78, 48, 37), (38, 24, 21), (137, 91, 70)),
    "fatih": (167.0, 97.0, 5.4, (83, 51, 40), (40, 25, 22), (143, 91, 71)),
    "kanuni": (169.0, 107.0, 4.8, (101, 83, 67), (49, 39, 34), (169, 136, 112)),
    "mimar_sinan": (161.0, 103.0, 4.8, (113, 99, 86), (57, 48, 43), (194, 169, 147)),
    "ataturk": (115.0, 95.0, 5.0, (96, 63, 48), (43, 29, 24), (157, 108, 84)),
}
SCALE = 4


def mouth_frame(base: Image.Image, center_x: float, center_y: float, radius_x: float,
                lip_color: tuple[int, int, int], cavity_color: tuple[int, int, int],
                inner_color: tuple[int, int, int], opened: bool) -> Image.Image:
    width, height = base.size
    layer = Image.new("RGBA", (width * SCALE, height * SCALE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    x, y, rx = center_x * SCALE, center_y * SCALE, radius_x * SCALE

    # Small curved mouth seam in the resting frame; the open frame enlarges the same contour.
    if not opened:
        points = [
            (x - rx, y), (x - rx * 0.63, y - 0.55 * SCALE),
            (x, y - 0.25 * SCALE), (x + rx * 0.67, y - 0.45 * SCALE),
            (x + rx, y), (x + rx * 0.52, y + 0.5 * SCALE),
            (x, y + 0.62 * SCALE), (x - rx * 0.62, y + 0.42 * SCALE),
        ]
        draw.polygon(points, fill=(*lip_color, 215))
        draw.line((x - rx * 0.75, y + 0.02 * SCALE, x + rx * 0.72, y + 0.02 * SCALE),
                  fill=(*cavity_color, 240), width=max(3, round(0.58 * SCALE)))
        draw.line((x - rx * 0.48, y + 0.73 * SCALE, x, y + 0.9 * SCALE, x + rx * 0.45, y + 0.68 * SCALE),
                  fill=(*inner_color, 110), width=max(2, round(0.35 * SCALE)))
    else:
        ry = 2.15 * SCALE
        draw.ellipse((x - rx - SCALE * 0.4, y - ry - SCALE * 0.35,
                      x + rx + SCALE * 0.4, y + ry + SCALE * 0.55),
                     fill=(*lip_color, 230))
        draw.ellipse((x - rx * 0.78, y - ry * 0.62, x + rx * 0.78, y + ry * 0.8),
                     fill=(*cavity_color, 247))
        draw.ellipse((x - rx * 0.44, y + 0.95 * SCALE, x + rx * 0.46, y + 1.55 * SCALE),
                     fill=(*inner_color, 195))
        # A narrow upper-lip highlight and lower-lip edge retain the portrait's natural contrast.
        draw.line((x - rx * 0.52, y - 1.65 * SCALE, x, y - 1.86 * SCALE, x + rx * 0.5, y - 1.58 * SCALE),
                  fill=(255, 230, 208, 85), width=max(2, round(0.35 * SCALE)))

    return layer.resize(base.size, Image.Resampling.LANCZOS)


def main() -> None:
    for figure, (x, y, rx, lip, cavity, inner) in FIGURES.items():
        target = APP / "public" / "stage" / figure
        idle_path = target / "idle.webp"
        if not idle_path.exists():
            raise FileNotFoundError(idle_path)
        with Image.open(idle_path) as source:
            idle = source.convert("RGBA")
        mid = mouth_frame(idle, x, y, rx, lip, cavity, inner, opened=False)
        opened = mouth_frame(idle, x, y, rx, lip, cavity, inner, opened=True)
        for name, frame in (("talk-mid.webp", mid), ("talk-open.webp", opened)):
            frame.save(target / name, "WEBP", lossless=True, quality=100, method=6, exact=True)


if __name__ == "__main__":
    main()
