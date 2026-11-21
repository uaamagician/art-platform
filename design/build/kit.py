"""Tiny SVG toolkit for the Art-Platform mockups.

Every screen is a 390 x 844 phone frame. Colors, radii and type sizes mirror
lib/theme/app_theme.dart, so what you import into Figma matches the real app.
"""
import html

INK = '#221E1B'
RED = '#C9402F'
PAPER = '#F8F4EE'
LINE = '#E9E1D6'
MUTED = '#8A8178'
TINT = '#F3E9DD'
PC = '#F8DDD6'  # primary container (light vermilion)
WHITE = '#FFFFFF'
GREEN = '#3F7D5B'
SOFT = '#5C544C'
FONT = "'Noto Sans TC','PingFang TC','Microsoft JhengHei',sans-serif"

TILE_COLORS = ['#F6E3DC', '#E2ECE4', '#E3E8F3', '#F3EBD5', '#EBE1F0']


def tw(s, size):
    """Rough text width: CJK is square, Latin is narrower."""
    w = 0.0
    for ch in s:
        if ord(ch) > 0x2E80:
            w += size
        elif ch == ' ':
            w += size * 0.3
        elif ch.isupper() or ch.isdigit():
            w += size * 0.62
        else:
            w += size * 0.55
    return w


class Canvas:
    def __init__(self, key, w=390, h=844):
        self.key = key
        self.w, self.h = w, h
        self.defs = []
        self.out = []
        self.n = 0
        self.defs.append(
            f'<filter id="{key}-sh" x="-20%" y="-20%" width="140%" height="150%">'
            f'<feDropShadow dx="0" dy="8" stdDeviation="10" flood-color="{INK}" flood-opacity="0.07"/></filter>'
        )
        self.defs.append(
            f'<filter id="{key}-sh2" x="-30%" y="-30%" width="160%" height="180%">'
            f'<feDropShadow dx="0" dy="4" stdDeviation="6" flood-color="{RED}" flood-opacity="0.35"/></filter>'
        )

    def uid(self, p='i'):
        self.n += 1
        return f'{self.key}-{p}{self.n}'

    def add(self, s):
        self.out.append(s)

    # ---- primitives -----------------------------------------------------
    def rect(self, x, y, w, h, fill=None, rx=0, stroke=None, sw=1, op=None, shadow=False, name=None):
        a = f'x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}"'
        a += f' fill="{fill}"' if fill else ' fill="none"'
        if stroke:
            a += f' stroke="{stroke}" stroke-width="{sw}"'
        if op is not None:
            a += f' opacity="{op}"'
        if shadow:
            a += f' filter="url(#{self.key}-sh)"'
        if name:
            a += f' id="{html.escape(name)}"'
        self.add(f'<rect {a}/>')

    def circle(self, cx, cy, r, fill=None, stroke=None, sw=1, op=None):
        a = f'cx="{cx}" cy="{cy}" r="{r}"'
        a += f' fill="{fill}"' if fill else ' fill="none"'
        if stroke:
            a += f' stroke="{stroke}" stroke-width="{sw}"'
        if op is not None:
            a += f' opacity="{op}"'
        self.add(f'<circle {a}/>')

    def line(self, x1, y1, x2, y2, stroke=LINE, sw=1, cap='round', dash=None):
        d = f' stroke-dasharray="{dash}"' if dash else ''
        self.add(f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="{stroke}" stroke-width="{sw}" stroke-linecap="{cap}"{d}/>')

    def path(self, d, fill=None, stroke=None, sw=1, op=None, cap='round'):
        a = f'd="{d}"'
        a += f' fill="{fill}"' if fill else ' fill="none"'
        if stroke:
            a += f' stroke="{stroke}" stroke-width="{sw}" stroke-linecap="{cap}" stroke-linejoin="round"'
        if op is not None:
            a += f' opacity="{op}"'
        self.add(f'<path {a}/>')

    def text(self, x, y, s, size=14, weight=400, fill=INK, anchor='start', op=None, ls=None):
        a = f'x="{x}" y="{y}" font-size="{size}" font-weight="{weight}" fill="{fill}" text-anchor="{anchor}"'
        if op is not None:
            a += f' opacity="{op}"'
        if ls:
            a += f' letter-spacing="{ls}"'
        self.add(f'<text {a}>{html.escape(s)}</text>')

    def lines(self, x, y, rows, size=14, lh=22, weight=400, fill=INK, anchor='start'):
        for i, r in enumerate(rows):
            self.text(x, y + i * lh, r, size, weight, fill, anchor)

    def grad(self, c1, c2, vertical=False):
        gid = self.uid('g')
        x2, y2 = ('0', '1') if vertical else ('1', '1')
        self.defs.append(
            f'<linearGradient id="{gid}" x1="0" y1="0" x2="{x2}" y2="{y2}">'
            f'<stop offset="0" stop-color="{c1}"/><stop offset="1" stop-color="{c2}"/></linearGradient>'
        )
        return gid

    def clip(self, x, y, w, h, rx):
        cid = self.uid('c')
        self.defs.append(f'<clipPath id="{cid}"><rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}"/></clipPath>')
        return cid

    def group(self, name=None, transform=None, clip=None):
        a = ''
        if name:
            a += f' id="{html.escape(name)}"'
        if transform:
            a += f' transform="{transform}"'
        if clip:
            a += f' clip-path="url(#{clip})"'
        self.add(f'<g{a}>')

    def end(self):
        self.add('</g>')

    def svg(self):
        body = '\n'.join(self.out)
        defs = '\n'.join(self.defs)
        return (
            f'<svg xmlns="http://www.w3.org/2000/svg" width="{self.w}" height="{self.h}" '
            f'viewBox="0 0 {self.w} {self.h}" font-family="{FONT}">\n<defs>{defs}</defs>\n{body}\n</svg>\n'
        )


# ---- art placeholders --------------------------------------------------------

ART = {
    'still': ('#D9D5CF', '#8E8A84'),
    'sea': ('#9CC3D5', '#4C7F9A'),
    'warm': ('#F2C9A0', '#C97B5A'),
    'green': ('#BBD8B5', '#5E946B'),
    'violet': ('#CDB9E3', '#7C5FA8'),
    'rose': ('#F3C1C6', '#C9677A'),
}


def art(c, x, y, w, h, kind='warm', rx=16):
    """Illustration placeholder: gradient with a few simple shapes."""
    c1, c2 = ART[kind]
    g = c.grad(c1, c2, vertical=True)
    cid = c.clip(x, y, w, h, rx)
    c.group(clip=cid)
    c.rect(x, y, w, h, f'url(#{g})')
    c.circle(x + w * 0.72, y + h * 0.28, min(w, h) * 0.13, WHITE, op=0.55)
    c.path(f'M{x} {y + h * 0.72} Q{x + w * 0.3} {y + h * 0.5} {x + w * 0.55} {y + h * 0.68} T{x + w} {y + h * 0.6} V{y + h} H{x} Z', fill=WHITE, op=0.28)
    c.path(f'M{x} {y + h * 0.86} Q{x + w * 0.35} {y + h * 0.7} {x + w * 0.7} {y + h * 0.84} T{x + w} {y + h * 0.78} V{y + h} H{x} Z', fill=INK, op=0.18)
    c.end()


def avatar(c, cx, cy, r, letter, ring=False, photo=False):
    if ring:
        c.circle(cx, cy, r + 3, None, stroke=RED, sw=1.5, op=0.45)
    c.circle(cx, cy, r, PC)
    c.text(cx, cy + r * 0.34, letter, int(r * 0.9), 700, '#6B1E14', 'middle')


# ---- layout pieces -----------------------------------------------------------

def phone(c, status=True):
    c.rect(0, 0, c.w if c.w <= 390 else 390, c.h, PAPER, name='background')
    if status:
        status_bar(c)


def status_bar(c, light=False):
    col = WHITE if light else INK
    c.text(24, 28, '9:41', 15, 600, col)
    c.rect(284, 20, 3, 6, col, rx=1)
    c.rect(289, 17, 3, 9, col, rx=1)
    c.rect(294, 14, 3, 12, col, rx=1)
    c.path('M306 20 Q313 13 320 20', stroke=col, sw=1.8)
    c.path('M309 23 Q313 19 317 23', stroke=col, sw=1.8)
    c.circle(313, 26, 1.6, col)
    c.rect(332, 14, 24, 12, None, rx=3.5, stroke=col, sw=1.2, op=0.9)
    c.rect(334, 16, 17, 8, col, rx=2)
    c.rect(357, 18, 2, 4, col, rx=1)


def seal(c, x, y, size=28):
    c.rect(x, y, size, size, RED, rx=size * 0.22)
    c.text(x + size / 2, y + size * 0.72, '藝', int(size * 0.62), 800, WHITE, 'middle')


def appbar(c, title, back=False, right=None, y=44, sub=None):
    if back:
        c.path(f'M30 {y + 30} L21 {y + 21} L30 {y + 12}', stroke=INK, sw=2.2)
    c.text(195, y + 28 if not sub else y + 24, title, 20, 700, INK, 'middle')
    if sub:
        c.text(195, y + 42, sub, 12, 400, MUTED, 'middle')
    if right:
        c.text(374, y + 28, right, 15, 500, RED, 'end')


def bottom_nav(c, selected):
    labels = ['探索', '群組', '主頁', '發布', '個人']
    c.rect(0, 780, 390, 64, WHITE, name='bottom-nav')
    c.line(0, 780.5, 390, 780.5, LINE)
    xs = [39, 117, 195, 273, 351]
    for i, (lab, x) in enumerate(zip(labels, xs)):
        if i == 3:
            c.rect(x - 42, 794, 84, 38, RED, rx=19, name='publish-pill')
            c.rect(x - 42, 794, 84, 38, None, rx=19, op=0)
            c.text(x, 819, lab, 15, 700, WHITE, 'middle')
            continue
        sel = i == selected
        c.text(x, 812, lab, 14, 700 if sel else 500, INK if sel else MUTED, 'middle')
        if sel:
            c.circle(x, 826, 2.5, RED)
    c.rect(135, 834, 120, 4, INK, rx=2, op=0.85)


def chip(c, x, y, label, selected=False, tint=TINT, size=13, h=32):
    w = tw(label, size) + 26
    c.rect(x, y, w, h, PC if selected else tint, rx=h / 2)
    c.text(x + w / 2, y + h / 2 + size * 0.36, label, size, 600 if selected else 400, INK, 'middle')
    return w


def pill(c, x, y, w, h, label, filled=True, size=13, color=RED):
    if filled:
        c.rect(x, y, w, h, color, rx=h / 2)
        c.text(x + w / 2, y + h / 2 + size * 0.36, label, size, 600, WHITE, 'middle')
    else:
        c.rect(x + 0.5, y + 0.5, w - 1, h - 1, WHITE, rx=h / 2, stroke=LINE)
        c.text(x + w / 2, y + h / 2 + size * 0.36, label, size, 500, MUTED, 'middle')


def button(c, x, y, w, h, label, kind='primary', size=15):
    if kind == 'primary':
        c.rect(x, y, w, h, RED, rx=14)
        c.text(x + w / 2, y + h / 2 + size * 0.36, label, size, 600, WHITE, 'middle')
    elif kind == 'tonal':
        c.rect(x, y, w, h, PC, rx=14)
        c.text(x + w / 2, y + h / 2 + size * 0.36, label, size, 600, '#6B1E14', 'middle')
    else:
        c.rect(x + 0.5, y + 0.5, w - 1, h - 1, WHITE, rx=14, stroke=LINE)
        c.text(x + w / 2, y + h / 2 + size * 0.36, label, size, 500, INK, 'middle')


def field(c, x, y, w, h, label=None, value=None, placeholder=None, counter=None):
    c.rect(x + 0.5, y + 0.5, w - 1, h - 1, WHITE, rx=14, stroke=LINE)
    if label:
        c.text(x + 16, y + 20, label, 12, 400, MUTED)
        if value:
            c.text(x + 16, y + h - 14, value, 15, 400, INK)
    elif value:
        c.text(x + 16, y + h / 2 + 5, value, 15, 400, INK)
    elif placeholder:
        c.text(x + 16, y + h / 2 + 5, placeholder, 15, 400, MUTED)
    if counter:
        c.text(x + w - 14, y + h + 16, counter, 11, 400, MUTED, 'end')


def segment(c, x, y, w, labels, sel, h=38):
    c.rect(x, y, w, h, TINT, rx=h / 2)
    cw = (w - 8) / len(labels)
    for i, lab in enumerate(labels):
        cx = x + 4 + cw * i
        if i == sel:
            c.rect(cx, y + 4, cw, h - 8, WHITE, rx=(h - 8) / 2, shadow=False)
            c.rect(cx, y + 4, cw, h - 8, None, rx=(h - 8) / 2)
        c.text(cx + cw / 2, y + h / 2 + 5, lab, 14, 700 if i == sel else 500, INK if i == sel else MUTED, 'middle')


def card(c, x, y, w, h, rx=20, shadow=False):
    c.rect(x + 0.5, y + 0.5, w - 1, h - 1, WHITE, rx=rx, stroke=LINE, shadow=shadow)


def switch(c, x, y, on=False):
    c.rect(x, y, 48, 28, PC if on else '#EFE6DC', rx=14, stroke=RED if on else MUTED, sw=1.5)
    c.circle(x + (34 if on else 14), y + 14, 9 if on else 7, RED if on else MUTED)


def badge(c, x, y, label, color=RED, size=12):
    w = tw(label, size) + 20
    c.rect(x, y, w, 22, color, rx=11, op=0.12)
    c.text(x + w / 2, y + 16, label, size, 700, color, 'middle')
    return w


def seg_icon_dots(c, cx, y, n, sel):
    total = n * 10
    x0 = cx - total / 2 + 5
    for i in range(n):
        c.circle(x0 + i * 10, y, 3, WHITE, op=1 if i == sel else 0.5)


def spotlight(c, x, y, w, h, rx, op=0.62):
    """Dark overlay over the whole phone with a rounded hole (SVG mask, imports into Figma as a mask)."""
    mid = c.uid('m')
    c.defs.append(
        f'<mask id="{mid}"><rect width="390" height="844" fill="white"/>'
        f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" fill="black"/></mask>'
    )
    c.add(f'<rect width="390" height="844" fill="{INK}" opacity="{op}" mask="url(#{mid})"/>')
    c.rect(x - 3, y - 3, w + 6, h + 6, None, rx=rx + 3, stroke=WHITE, sw=2.5)


def mascot(c, cx, cy, s=1.0, mood='smile', beret=True):
    """Placeholder for the 看板娘: a friendly round-faced figure with a beret."""
    g = f'translate({cx} {cy}) scale({s}) translate({-cx} {-cy})'
    c.group(transform=g)
    # hair back
    c.path(f'M{cx - 50} {cy - 6} Q{cx - 56} {cy - 62} {cx} {cy - 64} Q{cx + 56} {cy - 62} {cx + 50} {cy - 6} Q{cx + 56} {cy + 44} {cx + 38} {cy + 52} L{cx - 38} {cy + 52} Q{cx - 56} {cy + 44} {cx - 50} {cy - 6} Z', fill='#3A2A25')
    # face
    c.circle(cx, cy, 42, '#FDE8DA')
    # fringe
    c.path(f'M{cx - 42} {cy - 8} Q{cx - 30} {cy - 44} {cx} {cy - 38} Q{cx + 28} {cy - 46} {cx + 42} {cy - 8} Q{cx + 20} {cy - 24} {cx} {cy - 22} Q{cx - 22} {cy - 24} {cx - 42} {cy - 8} Z', fill='#3A2A25')
    # eyes
    if mood == 'happy':
        c.path(f'M{cx - 22} {cy + 2} Q{cx - 15} {cy - 8} {cx - 8} {cy + 2}', stroke=INK, sw=3)
        c.path(f'M{cx + 8} {cy + 2} Q{cx + 15} {cy - 8} {cx + 22} {cy + 2}', stroke=INK, sw=3)
    elif mood == 'sad':
        c.circle(cx - 15, cy + 3, 4.5, INK)
        c.circle(cx + 15, cy + 3, 4.5, INK)
        c.path(f'M{cx - 24} {cy - 5} L{cx - 8} {cy - 11}', stroke=INK, sw=2)
        c.path(f'M{cx + 24} {cy - 5} L{cx + 8} {cy - 11}', stroke=INK, sw=2)
        c.path(f'M{cx + 31} {cy + 8} q-4 9 0 12 q4 -3 0 -12 Z', fill='#8CC4E8')
    else:
        c.circle(cx - 15, cy + 3, 4.5, INK)
        c.circle(cx + 15, cy + 3, 4.5, INK)
        c.circle(cx - 13.5, cy + 1.5, 1.4, WHITE)
        c.circle(cx + 16.5, cy + 1.5, 1.4, WHITE)
    c.circle(cx - 27, cy + 16, 6, '#F4A9A0', op=0.6)
    c.circle(cx + 27, cy + 16, 6, '#F4A9A0', op=0.6)
    if mood == 'sad':
        c.path(f'M{cx - 8} {cy + 26} Q{cx} {cy + 19} {cx + 8} {cy + 26}', stroke=INK, sw=2.4)
    else:
        c.path(f'M{cx - 8} {cy + 20} Q{cx} {cy + 30} {cx + 8} {cy + 20}', stroke=INK, sw=2.4)
    if beret:
        c.path(f'M{cx - 46} {cy - 30} Q{cx - 40} {cy - 66} {cx + 4} {cy - 62} Q{cx + 52} {cy - 62} {cx + 46} {cy - 30} Q{cx} {cy - 42} {cx - 46} {cy - 30} Z', fill=RED)
        c.circle(cx + 4, cy - 66, 4, '#A8301F')
    c.end()


def wrap(s, size, maxw):
    rows, cur = [], ''
    for ch in s:
        if tw(cur + ch, size) > maxw and cur:
            rows.append(cur)
            cur = ch
        else:
            cur += ch
    if cur:
        rows.append(cur)
    return rows


def note_panel(c, x, title, owner, notes, status='待實現', y=60):
    """Right-hand spec panel for planned screens."""
    w = c.w - x - 20
    c.rect(x, y, w, c.h - y - 40, WHITE, rx=20, stroke=LINE)
    c.rect(x + 20, y + 22, tw(status, 13) + 22, 26, RED, rx=13)
    c.text(x + 31, y + 40, status, 13, 700, WHITE)
    c.text(x + 20, y + 80, title, 20, 800, INK)
    c.text(x + 20, y + 104, '負責：' + owner, 13, 500, MUTED)
    c.line(x + 20, y + 120, x + w - 20, y + 120, LINE)
    cy = y + 148
    maxw = w - 72
    for i, n in enumerate(notes, 1):
        c.circle(x + 30, cy - 5, 11, PC)
        c.text(x + 30, cy - 0.5, str(i), 12, 700, '#6B1E14', 'middle')
        rows = n if isinstance(n, list) else [n]
        k = 0
        for j, r in enumerate(rows):
            for piece in wrap(r, 14, maxw):
                c.text(x + 52, cy + k * 20, piece, 14, 400 if j else 700, INK if j == 0 else SOFT)
                k += 1
        cy += 20 * k + 16
    return c


def callout(c, n, x, y):
    """Numbered marker placed on the phone to match the notes panel."""
    c.circle(x, y, 11, RED)
    c.text(x, y + 4.5, str(n), 12, 700, WHITE, 'middle')
