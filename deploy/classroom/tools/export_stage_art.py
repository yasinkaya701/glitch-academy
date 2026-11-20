"""Export the existing Yanlış Dünya station art for the classroom browser stage."""

import argparse
import json
from pathlib import Path

from PIL import Image


APP = Path(__file__).resolve().parents[1]


def read_json(path):
    return json.loads(path.read_text(encoding="utf-8"))


def write_webp(image, path, size, quality):
    image = image.copy()
    image.thumbnail(size, Image.Resampling.LANCZOS)
    image.save(path, "WEBP", quality=quality, method=6)


def export_character(source, subject, key, portrait, metadata, backdrop):
    target = APP / "public" / "stage" / key
    target.mkdir(parents=True, exist_ok=True)
    body = Image.open(portrait / "body.png").convert("RGBA")
    alpha_box = body.getchannel("A").getbbox()
    if not alpha_box:
        raise ValueError(f"Empty character sprite: {portrait}")
    standing = body.crop(alpha_box)
    write_webp(standing, target / "idle.webp", (580, 720), 83)
    thumb_height = round(standing.height * (0.36 if subject == "philosophy" else 0.31))
    thumb_width = min(standing.width, thumb_height)
    thumb_left = (standing.width - thumb_width) // 2
    thumb = standing.crop((thumb_left, 0, thumb_left + thumb_width, thumb_height))
    write_webp(thumb, target / "thumb.webp", (140, 140), 82)

    if subject == "philosophy":
        x, y, width, height = metadata["face_rect"]
        for file, output in [
            ("up_confused.png", "thinking.webp"),
            ("face_mouth_mid.png", "talk-mid.webp"),
            ("face_mouth_open.png", "talk-open.webp"),
        ]:
            frame = Image.open(portrait / file).convert("RGBA")
            if frame.size != (width, height):
                raise ValueError(f"Frame does not match face geometry: {portrait / file}")
            actor = body.copy()
            actor.alpha_composite(frame, (x, y))
            write_webp(actor.crop(alpha_box), target / output, (580, 720), 83)

    background = Image.open(source / "assets" / "backgrounds" / f"{backdrop}.png").convert("RGB")
    write_webp(background, target / "setting.webp", (1100, 760), 79)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=APP.parents[1],
                        help="Yanlış Dünya repository containing stations/")
    args = parser.parse_args()
    for subject in ("philosophy", "history"):
        source = args.source / "stations" / subject
        metadata = read_json(source / "data" / "characters.json")
        metadata = metadata.get("figures", metadata)
        stage = read_json(source / "data" / "stage.json")
        for key, backdrop in stage.items():
            portrait = source / "assets" / "characters" / key
            export_character(source, subject, key, portrait, metadata[key], backdrop)


if __name__ == "__main__":
    main()
