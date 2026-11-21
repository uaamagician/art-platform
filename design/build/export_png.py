"""Exports every SVG in design/svg to a 2x PNG in design/png using headless Chrome.

Run after build.py:  python3 design/build/export_png.py
"""
import os
import re
import subprocess
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.abspath(os.path.join(HERE, '..'))
CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
SCALE = 2


def export(svg_path, png_path):
    head = open(svg_path, encoding='utf-8').read(400)
    w, h = (int(x) for x in re.search(r'width="(\d+)" height="(\d+)"', head).groups())
    with tempfile.TemporaryDirectory() as tmp:
        page = os.path.join(tmp, 'p.html')
        open(page, 'w', encoding='utf-8').write(
            f'<!doctype html><meta charset="utf-8"><style>html,body{{margin:0;background:#fff}}'
            f'img{{display:block;width:{w}px;height:{h}px}}</style><img src="file://{svg_path}">'
        )
        subprocess.run(
            [CHROME, '--headless=new', '--disable-gpu', '--hide-scrollbars', '--allow-file-access-from-files',
             f'--force-device-scale-factor={SCALE}', f'--window-size={w},{h}',
             f'--screenshot={png_path}', f'file://{page}'],
            check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=60,
        )
    return w, h


if __name__ == '__main__':
    count = 0
    for sub in ('existing', 'planned'):
        src = os.path.join(OUT, 'svg', sub)
        dst = os.path.join(OUT, 'png', sub)
        os.makedirs(dst, exist_ok=True)
        for old in os.listdir(dst):
            os.remove(os.path.join(dst, old))
        for name in sorted(os.listdir(src)):
            export(os.path.join(src, name), os.path.join(dst, name[:-4] + '.png'))
            count += 1
    print(f'{count} PNGs')
