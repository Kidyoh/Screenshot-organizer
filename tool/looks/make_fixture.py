"""Rebuilds app/src/test/resources/demo_looks.txt from assets/demo.

Shrinks each sample screenshot the way the phone does (LookStore.kt):
BitmapFactory's power-of-two inSampleSize, then a filtered scale to 24 x 52.
Run from the repo root: python3 tool/looks/make_fixture.py
"""
import glob
import os

from PIL import Image

out = []
for f in sorted(glob.glob('assets/demo/*.jpg')):
    im = Image.open(f).convert('RGB')
    s = 1
    while im.width // (s * 2) >= 48:
        s *= 2
    im = im.reduce(s).resize((24, 52), Image.BILINEAR)
    px = [0xFF000000 | (r << 16) | (g << 8) | b for r, g, b in im.get_flattened_data()]
    out.append(os.path.basename(f)[:-4] + ' ' + ','.join(str(p - (1 << 32) if p >= 1 << 31 else p) for p in px))
with open('app/src/test/resources/demo_looks.txt', 'w') as fh:
    fh.write('\n'.join(out) + '\n')
