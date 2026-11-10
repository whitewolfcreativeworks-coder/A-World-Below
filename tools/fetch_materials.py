#!/usr/bin/env python3
"""Fetch a small, pinned CC0 material set; no API key, account, or subscription."""
from pathlib import Path
import hashlib
import json
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
ASSET = 'rock_boulder_dry'
FILES = {
    'basalt_albedo.jpg': ('diff', 'da794cd9be3db91e3160cf081109f322'),
    'basalt_normal.jpg': ('nor_gl', '6f1c575ceed560ae253f65518cf748e2'),
    'basalt_roughness.jpg': ('rough', '0c8b15df3e31c15256da5f8e1b0d0759'),
}


def main():
    target = ROOT / 'assets/materials'
    target.mkdir(parents=True, exist_ok=True)
    manifest = []
    for name, (kind, expected) in FILES.items():
        url = f'https://dl.polyhaven.org/file/ph-assets/Textures/jpg/1k/{ASSET}/{ASSET}_{kind}_1k.jpg'
        request = urllib.request.Request(url, headers={'User-Agent': 'AWorldBelow/0.2'})
        data = urllib.request.urlopen(request, timeout=60).read()
        if hashlib.md5(data).hexdigest() != expected:
            raise SystemExit(f'Upstream checksum mismatch: {name}')
        (target / name).write_bytes(data)
        manifest.append({'file': name, 'source': url, 'license': 'CC0-1.0',
                         'sha256': hashlib.sha256(data).hexdigest()})
    (target / 'provenance.json').write_text(json.dumps({
        'asset': 'https://polyhaven.com/a/' + ASSET,
        'license': 'https://polyhaven.com/license',
        'use': 'Rock surface reference; not a photograph of a hydrothermal vent.',
        'files': manifest}, indent=2) + '\n')
    print('Downloaded and verified three CC0 material maps.')


if __name__ == '__main__':
    main()
