"""Generates design/svg/*.svg (import into Figma) and design/gallery.html (share with the team).

Run:  python3 tool/design-gen/build.py
"""
import html
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

from catalog import SECTIONS  # noqa: E402
from screens_planned import PLANNED  # noqa: E402

OUT = os.path.abspath(os.path.join(HERE, '..', '..', 'design'))

OWNERS = {
    '主頁': ('主頁與發布', '林仲辰'),
    '群組': ('群組', '陳森堯'),
    '個人': ('個人中心', '陳亮均'),
    '探索': ('探索與搜尋', '許鈞棠'),
    '美術': ('美術／介面', '林喬琳、林冠呈'),
}


def write_svgs():
    for sub in ('existing', 'planned'):
        os.makedirs(os.path.join(OUT, 'svg', sub), exist_ok=True)
    built = {'existing': [], 'planned': []}
    for sub in ('existing', 'planned'):
        for old in os.listdir(os.path.join(OUT, 'svg', sub)):
            os.remove(os.path.join(OUT, 'svg', sub, old))
    n = 0
    for section, items in SECTIONS:
        for slug, title, fn, note in items:
            n += 1
            fid = f'{n:02d}_{slug}'
            c = fn()
            path = os.path.join(OUT, 'svg', 'existing', fid + '.svg')
            open(path, 'w', encoding='utf-8').write(c.svg())
            built['existing'].append((fid, title, note, c, section))
    for fid, title, fn, owner, note in PLANNED:
        c = fn()
        path = os.path.join(OUT, 'svg', 'planned', fid + '.svg')
        open(path, 'w', encoding='utf-8').write(c.svg())
        built['planned'].append((fid, title, owner, note, c))
    return built


def inline(c, key):
    s = c.svg()
    s = re.sub(r'<svg ([^>]*?)width="\d+" height="\d+"', r'<svg \1', s, count=1)
    s = s.replace('<svg ', '<svg role="img" ', 1)
    s = re.sub(r'id="(background|canvas|bottom-nav|publish-pill)"', rf'id="{key}-\1"', s)
    return s


def gallery(built):
    done = []
    sections = []
    for fid, title, note, c, section in built['existing']:
        if not sections or sections[-1][0] != section:
            sections.append((section, []))
        sections[-1][1].append(
            f'<figure class="shot" data-kind="done"><div class="frame">{inline(c, fid)}</div>'
            f'<figcaption><b>{html.escape(fid.split("_", 1)[0])}　{html.escape(title)}</b><span>{html.escape(note)}</span></figcaption></figure>'
        )
        done.append(fid)
    done_html = ''.join(
        f'<h3>{html.escape(sec)}（{len(items)}）</h3><div class="grid">{"".join(items)}</div>'
        for sec, items in sections
    )
    todo = []
    for fid, title, owner, note, c in built['planned']:
        label, who = OWNERS[owner]
        todo.append(
            f'<figure class="shot wide" data-owner="{owner}"><div class="frame">{inline(c, fid)}</div>'
            f'<figcaption><b>{html.escape(title)}</b><span>{html.escape(note)}</span>'
            f'<em>{html.escape(label)}｜{html.escape(who)}</em></figcaption></figure>'
        )
    chips = ''.join(
        f'<button class="chip" data-f="{k}">{v[0]}</button>' for k, v in OWNERS.items()
    )
    swatches = ''.join(
        f'<div class="sw"><i style="background:{hexv}"></i><b>{name}</b><span>{hexv}</span></div>'
        for name, hexv in [
            ('朱紅 vermilion', '#C9402F'), ('墨 ink', '#221E1B'), ('宣紙 paper', '#F8F4EE'),
            ('線 line', '#E9E1D6'), ('淡字 muted', '#8A8178'), ('底色 tint', '#F3E9DD'),
            ('淺朱 container', '#F8DDD6'), ('綠 green', '#3F7D5B'),
        ]
    )
    return f'''<!doctype html>
<html lang="zh-Hant">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Art-Platform 設計稿</title>
<style>
:root {{
  --bg: #F8F4EE; --surface: #FFFFFF; --text: #221E1B; --muted: #7A7167; --line: #E4DACD;
  --accent: #C9402F; --accent-soft: #F8DDD6; --tint: #F3E9DD;
}}
@media (prefers-color-scheme: dark) {{
  :root:not([data-theme="light"]) {{
    --bg: #171412; --surface: #221E1B; --text: #F2ECE4; --muted: #A89F95; --line: #3A332D;
    --accent: #E4604E; --accent-soft: #4A2620; --tint: #2C2622;
  }}
}}
:root[data-theme="dark"] {{
  --bg: #171412; --surface: #221E1B; --text: #F2ECE4; --muted: #A89F95; --line: #3A332D;
  --accent: #E4604E; --accent-soft: #4A2620; --tint: #2C2622;
}}
* {{ box-sizing: border-box; }}
html, body {{ margin: 0; background: var(--bg); color: var(--text);
  font-family: 'Noto Sans TC','PingFang TC','Microsoft JhengHei',system-ui,sans-serif; line-height: 1.6; }}
main {{ max-width: 1240px; margin: 0 auto; padding: 40px 20px 80px; }}
header h1 {{ font-size: clamp(28px, 5vw, 44px); margin: 0 0 8px; letter-spacing: .02em; }}
header p {{ margin: 0; color: var(--muted); max-width: 62ch; }}
.seal {{ display: inline-grid; place-items: center; width: 44px; height: 44px; border-radius: 10px;
  background: var(--accent); color: #fff; font-weight: 800; font-size: 26px; margin-bottom: 14px; }}
h2 {{ font-size: 26px; margin: 56px 0 6px; }}
h2 + p {{ margin: 0 0 20px; color: var(--muted); }}
h3 {{ font-size: 18px; margin: 36px 0 14px; padding-left: 10px; border-left: 4px solid var(--accent); }}
.tokens {{ display: grid; grid-template-columns: repeat(auto-fill, minmax(150px, 1fr)); gap: 10px; margin-top: 24px; }}
.sw {{ background: var(--surface); border: 1px solid var(--line); border-radius: 14px; padding: 10px; display: grid; gap: 2px; font-size: 12px; }}
.sw i {{ height: 34px; border-radius: 8px; border: 1px solid var(--line); }}
.sw span {{ color: var(--muted); }}
.bar {{ display: flex; flex-wrap: wrap; gap: 8px; margin: 12px 0 20px; }}
.chip {{ font: inherit; font-size: 14px; border: 1px solid var(--line); background: var(--surface); color: var(--text);
  padding: 6px 14px; border-radius: 999px; cursor: pointer; }}
.chip[aria-pressed="true"] {{ background: var(--accent); border-color: var(--accent); color: #fff; }}
.grid {{ display: grid; gap: 28px 20px; grid-template-columns: repeat(auto-fill, minmax(220px, 1fr)); }}
.grid.planned {{ grid-template-columns: repeat(auto-fill, minmax(min(440px, 100%), 1fr)); }}
figure {{ margin: 0; }}
.frame {{ background: var(--surface); border: 1px solid var(--line); border-radius: 22px; overflow: hidden; cursor: zoom-in;
  box-shadow: 0 10px 30px rgba(0,0,0,.06); }}
.frame svg {{ display: block; width: 100%; height: auto; }}
figcaption {{ display: grid; gap: 2px; padding: 10px 4px 0; font-size: 14px; }}
figcaption span {{ color: var(--muted); font-size: 13px; }}
figcaption em {{ font-style: normal; color: var(--accent); font-size: 13px; font-weight: 600; }}
dialog {{ border: 0; padding: 0; background: transparent; max-width: 96vw; max-height: 96vh; }}
dialog::backdrop {{ background: rgba(0,0,0,.7); }}
dialog .box {{ background: var(--surface); border-radius: 18px; overflow: auto; max-height: 94vh; }}
dialog svg {{ display: block; height: min(90vh, 844px); width: auto; max-width: 94vw; }}
footer {{ margin-top: 60px; color: var(--muted); font-size: 13px; }}
.theme {{ position: fixed; top: 14px; right: 14px; }}
</style>
</head>
<body>
<button class="chip theme" id="theme" type="button">深色／淺色</button>
<main>
<header>
  <div class="seal">藝</div>
  <h1>Art-Platform 設計稿</h1>
  <p>繪圖創作者社群 App。這是給大家看大概長怎樣的草稿，不是定案，美術、介面可以整個重做。上半是還沒做的功能的想法（右邊有說明），下半是目前 App 的畫面。點圖可放大。</p>
  <div class="tokens">{swatches}</div>
</header>

<h2>還沒做的功能（草稿 {len(todo)} 張）</h2>
<p>右邊是我們目前的想法，紅色數字對應說明的編號。都可以改。</p>
<div class="bar" id="owners"><button class="chip" data-f="" aria-pressed="true">全部</button>{chips}</div>
<div class="grid planned" id="planned">
{''.join(todo)}
</div>

<h2>目前 App 的畫面（{len(done)} 張，參考用）</h2>
<p>App 現在大概長這樣，含各頁面、彈窗、選單與空狀態，依功能分組。顏色與版面只是目前的暫時版本。</p>
{done_html}

<footer>色票、圓角、字級來自 lib/theme/app_theme.dart。圖檔在 design/png 和 design/svg，可以拖進 Figma 參考。</footer>
</main>
<dialog id="dlg"><div class="box" id="box"></div></dialog>
<script>
(function () {{
  var dlg = document.getElementById('dlg'), box = document.getElementById('box');
  document.addEventListener('click', function (e) {{
    var f = e.target.closest('.frame');
    if (!f) return;
    box.innerHTML = f.innerHTML;
    dlg.showModal();
  }});
  dlg.addEventListener('click', function (e) {{ if (e.target === dlg || e.target === box) dlg.close(); }});
  var chips = document.querySelectorAll('#owners .chip');
  chips.forEach(function (b) {{
    b.addEventListener('click', function () {{
      chips.forEach(function (x) {{ x.setAttribute('aria-pressed', x === b ? 'true' : 'false'); }});
      var f = b.getAttribute('data-f');
      document.querySelectorAll('#planned .shot').forEach(function (s) {{
        s.style.display = (!f || s.getAttribute('data-owner') === f) ? '' : 'none';
      }});
    }});
  }});
  document.getElementById('theme').addEventListener('click', function () {{
    var r = document.documentElement, dark = r.getAttribute('data-theme') === 'dark' ||
      (!r.getAttribute('data-theme') && matchMedia('(prefers-color-scheme: dark)').matches);
    r.setAttribute('data-theme', dark ? 'light' : 'dark');
  }});
}})();
</script>
</body>
</html>
'''


if __name__ == '__main__':
    built = write_svgs()
    open(os.path.join(OUT, 'gallery.html'), 'w', encoding='utf-8').write(gallery(built))
    print(f"{len(built['existing'])} existing + {len(built['planned'])} planned screens")
