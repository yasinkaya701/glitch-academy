"""Validate the delivered reference pack, without modifying the live game."""
import hashlib
import json
from pathlib import Path

root = Path(__file__).resolve().parent
figures = json.loads((root / 'manifest.json').read_text())['figures']
assert len(figures) == 6, 'Expected six archive sources'
for figure, meta in figures.items():
    path = root / meta['file']
    assert hashlib.sha256(path.read_bytes()).hexdigest() == meta['sha256'], figure
    for field in ('credit', 'source_url', 'license', 'license_url', 'nature'):
        assert meta.get(field), f'{figure}: missing {field}'
    print(f'OK {figure}: source bytes, attribution and license')
