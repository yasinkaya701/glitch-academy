#!/usr/bin/env python3
"""Verify unmodified archive images. Use --download to restore missing files.

No keying, recolouring, face generation or dependency on temporary source files.
"""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--download', action='store_true')
    args = parser.parse_args()
    figures = json.loads((ROOT / 'data/characters.json').read_text())['figures']
    for figure, meta in figures.items():
        path = ROOT / meta['image'].removeprefix('res://stations/history/')
        if args.download and not path.exists():
            path.parent.mkdir(parents=True, exist_ok=True)
            temporary = path.with_suffix('.download')
            try:
                subprocess.run(['curl', '-fLsS', '--retry', '2', '--max-time', '60',
                                '-A', 'Mozilla/5.0', meta['download_url'],
                                '-o', str(temporary)], check=True)
                if hashlib.sha256(temporary.read_bytes()).hexdigest() != meta['sha256']:
                    raise ValueError(f'{figure}: source changed; review before accepting')
                temporary.replace(path)
            finally:
                temporary.unlink(missing_ok=True)
        if hashlib.sha256(path.read_bytes()).hexdigest() != meta['sha256']:
            raise ValueError(f'{figure}: archive checksum mismatch')
        for field in ('source_url', 'license', 'license_url', 'credit', 'caption', 'nature'):
            if not meta.get(field):
                raise ValueError(f'{figure}: missing {field}')
        print(f'OK {figure}: original bytes, source and license verified')


if __name__ == '__main__':
    main()
