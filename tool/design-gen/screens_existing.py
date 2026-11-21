"""Screens that already exist in the app (drawn to match what the code renders)."""
from kit import *


def new(key, h=844):
    c = Canvas(key, h=h)
    phone(c)
    return c


# ---- shared pieces ---------------------------------------------------------

def home_header(c, selected='rec'):
    seal(c, 16, 54)
    c.text(166, 80, '追蹤中', 17, 700 if selected == 'follow' else 400, INK if selected == 'follow' else MUTED, 'middle')
    c.text(232, 80, '推薦', 17, 700 if selected == 'rec' else 400, INK if selected == 'rec' else MUTED, 'middle')
    ux = 166 if selected == 'follow' else 232
    uw = 51 if selected == 'follow' else 34
    c.rect(ux - uw / 2, 92, uw, 2, RED)
    c.text(374, 80, '篩選', 15, 500, RED, 'end')


def feed_card(c, y0, name, bio, title, desc, tags, likes, ago, kind, cat, following=False, liked=False, images=1):
    card(c, 14, y0, 362, 520, rx=24, shadow=True)
    avatar(c, 47, y0 + 38, 19, name[0], ring=True)
    c.text(76, y0 + 34, name, 15, 700)
    c.text(76, y0 + 53, bio, 12.5, 400, MUTED)
    pill(c, 300, y0 + 22, 64, 32, '追蹤中' if following else '追蹤', filled=not following, size=13)
    art(c, 24, y0 + 70, 342, 300, kind, rx=16)
    w = tw(cat, 12) + 20
    c.rect(34, y0 + 334, w, 26, INK, rx=13, op=0.55)
    c.text(34 + w / 2, y0 + 351, cat, 12, 500, WHITE, 'middle')
    if images > 1:
        c.rect(316, y0 + 80, 40, 26, INK, rx=13, op=0.55)
        c.text(336, y0 + 97, f'{images} 張', 12, 500, WHITE, 'middle')
    c.text(30, y0 + 404, title, 17, 700)
    c.text(30, y0 + 430, desc, 14, 400, SOFT)
    c.text(30, y0 + 456, '  '.join('#' + t for t in tags), 13, 600, RED)
    lw = 76
    c.rect(30, y0 + 470, lw, 30, PC if liked else TINT, rx=15)
    c.text(30 + lw / 2, y0 + 490, f"{'已讚' if liked else '讚'} {likes}", 13, 700, RED if liked else SOFT, 'middle')
    c.text(118, y0 + 490, '留言 0', 12.5, 400, MUTED)
    c.text(362, y0 + 490, ago, 12.5, 400, MUTED, 'end')


def search_field(c, y, placeholder):
    c.rect(16.5, y + 0.5, 357, 47, WHITE, rx=24, stroke=LINE)
    c.text(34, y + 30, placeholder, 15, 400, MUTED)


def explore_top(c, tab):
    appbar(c, '探索')
    search_field(c, 100, '搜尋標題、創作者、#標籤')
    c.text(16, 184, '熱門', 13, 800)
    x = 56
    for t in ['#鉛筆素描', '#靜物', '#電繪', '#角色設計']:
        x += chip(c, x, 168, t, size=13, h=34) + 8
    segment(c, 16, 214, 358, ['分類', '創作者', '委託', '改圖'], tab)


def composer(c, placeholder, send='送出', left=None):
    c.rect(0, 780, 390, 64, WHITE)
    c.line(0, 780.5, 390, 780.5, LINE)
    x = 16
    if left:
        c.text(x + 4, 818, left, 15, 500, RED)
        x += 56
    c.rect(x + 0.5, 790.5, 390 - x - 76, 39, WHITE, rx=20, stroke=LINE)
    c.text(x + 18, 816, placeholder, 14, 400, MUTED)
    c.text(374, 816, send, 15, 500, RED, 'end')
    c.rect(135, 834, 120, 4, INK, rx=2, op=0.85)


def commission_card(c, y, kind, title, desc, budget, deadline, tags, name, ago, image=False, closed=False):
    h = 214 if desc else 178
    card(c, 14, y, 362, h)
    col = RED if kind == '委託需求' else GREEN
    w = badge(c, 30, y + 16, kind, col)
    if closed:
        badge(c, 30 + w + 6, y + 16, '已結案', MUTED)
    c.text(362, y + 32, ago, 12, 400, MUTED, 'end')
    c.text(30, y + 66, title, 17, 700)
    yy = y + 66
    if desc:
        c.text(30, y + 92, desc, 14, 400, SOFT)
        yy = y + 92
    if image:
        art(c, 290, y + 50, 72, 72, 'rose', rx=12)
    ix = 30
    if budget:
        c.text(ix, yy + 32, '預算', 13, 400, MUTED)
        c.text(ix + 40, yy + 32, budget, 13, 700)
        ix += 40 + tw(budget, 13) + 18
    if deadline:
        c.text(ix, yy + 32, '期限', 13, 400, MUTED)
        c.text(ix + 40, yy + 32, deadline, 13, 700)
    c.text(30, yy + 58, '  '.join('#' + t for t in tags), 13, 600, RED)
    avatar(c, 41, yy + 84, 11, name[0])
    c.text(60, yy + 89, name, 13, 400, MUTED)


def dark_pill(c, x, y, w, label):
    c.rect(x, y, w, 46, INK, rx=23, shadow=False)
    c.text(x + w / 2, y + 29, label, 15, 700, WHITE, 'middle')


# ---- screens ---------------------------------------------------------------

def login(key='login'):
    c = new(key)
    c.text(24, 84, '取消', 15, 500, RED)
    seal(c, 153, 280, 84)
    c.text(195, 420, '藝術投稿平台', 30, 800, INK, 'middle', ls=2)
    c.text(195, 448, 'ART · PLATFORM', 12, 400, MUTED, 'middle', ls=5)
    button(c, 85, 500, 220, 50, '使用 Google 登入')
    return c


def home_recommend(key='home'):
    c = new(key)
    home_header(c, 'rec')
    feed_card(c, 108, 'Bob 陳', '素描與水彩，每天一張', '窗邊的靜物', '用 2B 鉛筆畫了一個下午', ['鉛筆素描', '靜物'], 3, '5 分鐘前', 'still', '傳統手繪')
    feed_card(c, 640, 'Carol 王', '角色設計 / 接稿中', '原創角色設定', '', ['電繪'], 1, '15 分鐘前', 'violet', '數位繪圖', images=3)
    bottom_nav(c, 2)
    return c


def home_following_guest(key='home_following'):
    c = new(key)
    home_header(c, 'follow')
    c.text(195, 400, '登入後就能看到你追蹤的創作者的最新作品', 15, 400, SOFT, 'middle')
    button(c, 150, 424, 90, 42, '登入')
    bottom_nav(c, 2)
    return c


def post_detail(key='post_detail'):
    c = new(key)
    appbar(c, '窗邊的靜物', back=True, right='更多')
    art(c, 0, 100, 390, 320, 'still', rx=0)
    seg_icon_dots(c, 195, 404, 3, 0)
    avatar(c, 36, 460, 20, 'B', ring=True)
    c.text(68, 456, 'Bob 陳', 15, 700)
    c.text(68, 475, '素描與水彩，每天一張', 12.5, 400, MUTED)
    pill(c, 300, 444, 64, 32, '追蹤')
    c.text(16, 516, '窗邊的靜物', 21, 800)
    c.text(16, 538, '5 分鐘前', 12.5, 400, MUTED)
    c.text(16, 564, '用 2B 鉛筆畫了一個下午', 14, 400, INK)
    x = 16
    for t in ['傳統手繪', '#鉛筆素描', '#靜物']:
        x += chip(c, x, 580, t) + 8
    for i, lab in enumerate(['讚 3', '收藏', '分享']):
        button(c, 16 + i * 121, 628, 113, 42, lab, 'secondary', 14)
    c.line(16, 692, 374, 692, LINE)
    c.text(16, 722, '留言 1', 16, 800)
    avatar(c, 32, 752, 14, 'A')
    c.text(54, 748, 'Alice 林', 13, 700)
    c.text(112, 748, '剛剛', 11, 400, MUTED)
    c.text(54, 766, '整合測試留言', 14, 400)
    composer(c, '寫下你的留言…')
    return c


def publish(key='publish', h=1230):
    c = new(key, h)
    appbar(c, '發布作品', back=True, right='發布')
    c.text(16, 134, '作品圖片（1/10）', 15, 700)
    c.text(150, 134, '第一張為封面', 12, 400, MUTED)
    art(c, 16, 148, 104, 104, 'warm', rx=10)
    c.rect(20, 152, 40, 20, RED, rx=10)
    c.text(40, 166, '封面', 10, 600, WHITE, 'middle')
    c.text(68, 272, '移除', 12, 500, RED, 'middle')
    c.rect(128, 148, 104, 104, '#EFE9E1', rx=10)
    c.text(180, 205, '新增圖片', 14, 400, SOFT, 'middle')
    field(c, 16, 288, 358, 56, placeholder='標題', counter='0/50')
    field(c, 16, 372, 358, 100, placeholder='作品描述（選填）', counter='0/2000')
    c.text(16, 520, '分類', 15, 700)
    x = 16
    for i, t in enumerate(['傳統手繪', '顏料繪畫', '數位繪圖']):
        x += chip(c, x, 534, t, selected=(i == 0), tint=WHITE) + 8
    c.text(16, 592, '標籤（2/10）', 15, 700)
    c.text(128, 592, '可選媒材標籤，也能自訂', 12, 400, MUTED)
    x = 16
    for i, t in enumerate(['3D數位雕刻', '乾壁畫', '鉛筆素描']):
        x += chip(c, x, 606, t, selected=(i == 2), tint=WHITE) + 8
    field(c, 16, 656, 290, 44, placeholder='自訂標籤，例如：光影練習')
    pill(c, 314, 662, 60, 34, '新增', filled=False, size=13)
    x = 16
    for t in ['#光影練習', '#靜物']:
        x += chip(c, x, 714, t + '  ✕', tint=TINT) + 8
    c.text(16, 784, '圖層檔／附件（選填）', 15, 700)
    c.text(16, 804, 'PSD、CLIP、KRA、Procreate…單檔上限 100MB', 12, 400, MUTED)
    button(c, 16, 820, 358, 44, '新增檔案（0/5）', 'secondary', 14)
    card(c, 16, 896, 358, 262, rx=16)
    c.text(32, 926, '安全標籤（必填）', 15, 700)
    c.text(32, 946, '兩項都需要回答，讓大家自行選擇是否要看到', 12, 400, MUTED)
    for i, (t, h) in enumerate([('成人內容（NSFW）', '含裸露、性暗示、血腥等請選「是」'), ('AI 生成內容', '以 AI 產生或主要由 AI 生成的圖像請選「是」')]):
        yy = 982 + i * 90
        c.text(32, yy, t, 14, 700)
        c.text(32, yy + 18, h, 12, 400, MUTED)
        segment(c, 32, yy + 30, 326, ['是', '否'], -1, h=38)
    return c


def explore_categories(key='explore_cat'):
    c = new(key)
    explore_top(c, 0)
    names = ['傳統手繪', '顏料繪畫', '數位繪圖', '版畫印刷', '特殊技法']
    for i, n in enumerate(names):
        x = 16 + (i % 2) * 187
        y = 270 + (i // 2) * 138
        c.rect(x, y, 171, 126, TILE_COLORS[i], rx=20)
        c.text(x + 171 - 6, y + 150 - 28, n[0], 86, 900, INK, 'end', op=0.07)
        c.text(x + 16, y + 106, n, 17, 800)
    bottom_nav(c, 0)
    return c


def explore_creators(key='explore_creators'):
    c = new(key)
    explore_top(c, 1)
    rows = [('Bob 陳', '素描與水彩，每天一張', '4 件作品'), ('Carol 王', '角色設計 / 接稿中', '2 件作品'), ('Alice 林', '一句話讓大家認識你', '1 件作品'), ('小明', '水墨與書法', '1 件作品')]
    for i, (n, bio, cnt) in enumerate(rows):
        y = 264 + i * 76
        avatar(c, 40, y + 34, 24, n[0])
        c.text(76, y + 30, n, 16, 700)
        c.text(76, y + 52, bio, 13, 400, MUTED)
        pill(c, 300, y + 18, 64, 32, '追蹤')
        c.line(76, y + 74, 390, y + 74, LINE)
    bottom_nav(c, 0)
    return c


def commission_list(key='commission_list'):
    c = new(key)
    explore_top(c, 2)
    segment(c, 16, 262, 358, ['全部', '委託需求', '接單展示'], 0)
    c.rect(14, 314, 362, 52, TINT, rx=16)
    c.text(30, 337, '平台只刊登委託資訊，交易與付款請在站外', 12.5, 400, SOFT)
    c.text(30, 355, '自行確認。', 12.5, 400, SOFT)
    c.text(360, 346, '免責聲明', 14, 700, RED, 'end')
    commission_card(c, 378, '委託需求', '徵 VTuber 立繪', '需要全身立繪與表情差分', 'NT$3000 起', '2026/10/29', ['立繪'], 'Carol 王', '11 分鐘前')
    commission_card(c, 606, '接單展示', '頭像接單中', '', 'NT$800', None, ['頭像'], 'Bob 陳', '41 分鐘前', image=True)
    dark_pill(c, 262, 708, 112, '發布委託')
    bottom_nav(c, 0)
    return c


def commission_detail(key='commission_detail', owner=False):
    c = new(key)
    appbar(c, '委託詳情', back=True)
    badge(c, 16, 108, '委託需求', RED, 13)
    c.text(16, 170, '徵 VTuber 立繪', 23, 800)
    avatar(c, 38, 214, 20, 'C', ring=True)
    c.text(70, 210, 'Carol 王', 15, 700)
    c.text(70, 230, '11 分鐘前', 12, 400, MUTED)
    if not owner:
        pill(c, 300, 198, 64, 32, '追蹤')
    card(c, 16, 252, 358, 96, rx=18)
    c.text(34, 288, '預算', 14, 400, MUTED)
    c.text(110, 288, 'NT$3000 起', 14, 700)
    c.text(34, 322, '期限', 14, 400, MUTED)
    c.text(110, 322, '2026/10/29（剩 20 天）', 14, 700)
    c.text(16, 386, '需要全身立繪與表情差分', 15, 400)
    chip(c, 16, 404, '#立繪')
    c.rect(16, 458, 358, 96, PC, rx=18)
    c.text(34, 486, '站外聯絡方式', 13, 700)
    c.text(34, 520, 'IG: @seed', 16, 700)
    c.text(340, 522, '複製', 14, 500, RED, 'end')
    c.rect(16, 568, 358, 176, TINT, rx=18)
    c.text(34, 596, '免責聲明', 13, 700)
    c.lines(34, 620, ['本平台僅提供委託資訊的刊登與展示，不介入雙方', '的溝通、報價、付款與交付，也不經手任何金流，', '對雙方於站外交易所產生的糾紛與法律責任概不', '負責。請自行確認對方身分並留意詐騙。'], 12.5, 20, 400, SOFT)
    if owner:
        button(c, 16, 764, 172, 46, '標示為已結案', 'tonal', 14)
        button(c, 202, 764, 172, 46, '刪除委託', 'secondary', 14)
    else:
        c.text(195, 776, '檢舉這則委託', 14, 400, MUTED, 'middle')
    return c


def commission_form(key='commission_form'):
    c = new(key, 1330)
    appbar(c, '發布委託', back=True, right='發布')
    segment(c, 16, 110, 358, ['我要委託（徵稿）', '我要接單（展示）'], 0)
    field(c, 16, 168, 358, 56, placeholder='標題', counter='0/50')
    field(c, 16, 252, 358, 110, placeholder='需求內容', counter='0/2000')
    field(c, 16, 392, 358, 56, placeholder='預算', counter='0/30')
    c.text(16, 484, '期限（選填）', 15, 400, MUTED)
    pill(c, 276, 466, 98, 34, '選擇日期', filled=False, size=13)
    c.text(16, 540, '分類（選填）', 15, 700)
    x = 16
    for t in ['傳統手繪', '顏料繪畫', '數位繪圖']:
        x += chip(c, x, 554, t, tint=WHITE) + 8
    c.text(16, 624, '標籤', 15, 700)
    field(c, 16, 638, 290, 44, placeholder='輸入標籤，例如：光影練習')
    pill(c, 314, 643, 60, 34, '新增', filled=False)
    x = 16
    for t in ['原創角色', '頭像', '立繪']:
        x += chip(c, x, 698, '#' + t, tint=TINT) + 8
    c.text(16, 760, '參考圖（0/4，選填）', 15, 700)
    button(c, 16, 776, 358, 44, '新增圖片', 'secondary', 14)
    field(c, 16, 852, 358, 56, label='站外聯絡方式（必填）', placeholder='LINE ID／IG／Email 等')
    c.rect(16, 936, 358, 212, TINT, rx=16)
    c.text(32, 964, '免責聲明', 13, 700)
    c.lines(32, 988, ['本平台僅提供委託資訊的刊登與展示，不介入雙方', '的溝通、報價、付款與交付，也不經手任何金流，', '對雙方於站外交易所產生的糾紛與法律責任概不', '負責。請自行確認對方身分並留意詐騙。'], 12.5, 20, 400, SOFT)
    c.rect(32.5, 1094.5, 20, 20, WHITE, rx=5, stroke=MUTED, sw=1.5)
    c.text(62, 1110, '我已閱讀並同意', 14, 400)
    c.text(16, 1196, '成人內容（必填）', 15, 700)
    c.text(16, 1216, '涉及裸露、性暗示或血腥的委託請選「是」', 12, 400, MUTED)
    segment(c, 16, 1232, 358, ['是', '否'], -1, h=40)
    return c


def consult_list(key='consult_list'):
    c = new(key)
    explore_top(c, 3)
    c.rect(14, 262, 362, 72, TINT, rx=16)
    c.lines(30, 290, ['在這裡發布的作品視為開放改圖：其他創作者可在下', '方以圖片或文字回覆（蓋樓），一起討論怎麼畫得更好。'], 12.5, 20, 400, SOFT)
    card(c, 14, 346, 362, 118)
    art(c, 26, 358, 92, 92, 'sea', rx=14)
    c.text(132, 384, '手的比例總是怪怪的', 16, 700)
    c.text(132, 408, '請問手掌和手指的長度怎麼抓？', 13, 400, MUTED)
    avatar(c, 142, 436, 10, 'B')
    c.text(158, 440, 'Bob 陳', 12.5, 400, MUTED)
    c.text(362, 440, '1 樓 · 46 分鐘前', 12, 400, MUTED, 'end')
    dark_pill(c, 262, 708, 112, '發布諮詢')
    bottom_nav(c, 0)
    return c


def consult_detail(key='consult_detail'):
    c = new(key)
    appbar(c, '改圖諮詢', back=True)
    c.rect(0, 100, 390, 250, TINT)
    art(c, 70, 100, 250, 250, 'sea', rx=0)
    avatar(c, 36, 384, 20, 'B', ring=True)
    c.text(68, 380, 'Bob 陳', 15, 700)
    c.text(68, 399, '46 分鐘前', 12, 400, MUTED)
    pill(c, 300, 368, 64, 32, '追蹤')
    c.text(16, 444, '手的比例總是怪怪的', 21, 800)
    c.text(16, 470, '請問手掌和手指的長度怎麼抓？', 14, 400)
    c.line(16, 494, 374, 494, LINE)
    c.text(16, 522, '回覆 1', 16, 800)
    card(c, 16, 540, 358, 116, rx=18)
    c.rect(30, 554, 52, 24, INK, rx=12)
    c.text(56, 571, '1 樓', 12, 700, WHITE, 'middle')
    avatar(c, 102, 566, 12, 'C')
    c.text(122, 571, 'Carol 王 · 31 分鐘前', 12.5, 400, MUTED)
    c.lines(30, 604, ['手掌長度大約等於中指長度，', '可以先用方塊概括。'], 14, 22, 400)
    composer(c, '寫下你的建議，或附上改圖…', '蓋樓', '附圖')
    return c


def group_list(key='group_list'):
    c = new(key)
    appbar(c, '群組', right='建立')
    segment(c, 16, 108, 358, ['我的群組', '探索群組'], 0)
    rows = [('速寫小聚', '歡迎新朋友', '3 人', '15 分鐘前'), ('水彩日常', '本週主題：雨天', '8 人', '2 小時前'), ('Live2D 研究室', '每週五晚上交流', '5 人', '昨天')]
    for i, (n, last, cnt, ago) in enumerate(rows):
        y = 164 + i * 96
        card(c, 14, y, 362, 84)
        c.rect(28, y + 16, 52, 52, TILE_COLORS[i], rx=16)
        c.text(54, y + 51, n[0], 22, 900, INK, 'middle')
        c.text(94, y + 38, n, 16, 700)
        c.text(94, y + 60, last, 13, 400, MUTED)
        c.text(362, y + 38, cnt, 12, 400, MUTED, 'end')
        c.text(362, y + 58, ago, 11, 400, MUTED, 'end')
    bottom_nav(c, 1)
    return c


def group_chat(key='group_chat'):
    c = new(key)
    appbar(c, '速寫小聚', back=True, sub='3 位成員')
    segment(c, 16, 108, 358, ['聊天', '白板', '成員'], 0)

    def other(y, name, text):
        avatar(c, 32, y + 14, 16, name[0])
        c.text(56, y + 8, name, 12, 400, MUTED)
        w = tw(text, 14) + 28
        c.rect(56, y + 16, w, 40, WHITE, rx=18, stroke=LINE)
        c.text(70, y + 41, text, 14)
        c.text(56, y + 72, '15 分鐘前', 11, 400, MUTED)

    def mine(y, text):
        w = tw(text, 14) + 28
        c.rect(374 - w, y, w, 40, PC, rx=18)
        c.text(374 - w + 14, y + 25, text, 14)
        c.text(374, y + 56, '剛剛', 11, 400, MUTED, 'end')

    other(170, 'Bob 陳', '歡迎新朋友')
    other(262, 'Carol 王', '今天的主題是手部素描')
    mine(354, '大家好，我是新成員')
    other(430, 'Bob 陳', '白板上先畫幾個姿勢吧')
    composer(c, '傳訊息給大家…')
    return c


def group_board(key='group_board'):
    c = new(key)
    appbar(c, '速寫小聚', back=True, sub='3 位成員')
    segment(c, 16, 108, 358, ['聊天', '白板', '成員'], 1)
    c.rect(16, 160, 358, 440, WHITE, rx=14, stroke=LINE, shadow=True)
    c.path('M70 250 Q140 360 210 330 T330 270', stroke=RED, sw=6)
    c.path('M90 420 Q150 380 220 440 T320 400', stroke='#2F5D9E', sw=6)
    c.path('M120 500 L150 470 L190 520', stroke=GREEN, sw=6)
    cols = [INK, RED, '#2F5D9E', GREEN, '#E0A526', '#7A4FA3', '#8A5A3C', WHITE]
    for i, col in enumerate(cols):
        x = 31 + i * 46
        c.circle(x, 636, 15, col, stroke=RED if i == 0 else LINE, sw=3 if i == 0 else 1.5)
    c.text(31 + 7 * 46, 640, '擦', 11, 400, MUTED, 'middle')
    for i, w in enumerate(['細', '中', '粗']):
        c.rect(16 + i * 52, 668, 44, 30, PC if i == 1 else TINT, rx=15)
        c.text(38 + i * 52, 688, w, 13, 500, INK, 'middle')
    c.text(366, 688, '復原', 15, 500, RED, 'end')
    c.text(16, 736, '鎖定白板', 14, 500, RED)
    c.text(100, 736, '清空', 14, 500, RED)
    c.text(160, 736, '發布為作品', 14, 500, RED)
    c.text(16, 764, '（以上三個只有房主看得到）', 11, 400, MUTED)
    return c


def group_members(key='group_members', owner=False):
    c = new(key)
    appbar(c, '速寫小聚', back=True, sub='3 位成員')
    segment(c, 16, 108, 358, ['聊天', '白板', '成員'], 2)
    c.rect(16, 164, 358, 52, TINT, rx=16)
    c.text(32, 196, '每週一起畫速寫', 14, 400)
    c.text(16, 252, '成員 3', 15, 800)
    rows = [('Bob 陳', '素描與水彩，每天一張', True), ('Carol 王', '角色設計 / 接稿中', False), ('Alice 林', '', False)]
    for i, (n, bio, is_owner) in enumerate(rows):
        y = 272 + i * 66
        avatar(c, 38, y + 28, 22, n[0])
        c.text(72, y + 26, n, 15, 700)
        if is_owner:
            c.rect(72 + tw(n, 15) + 8, y + 12, 38, 20, RED, rx=10)
            c.text(72 + tw(n, 15) + 27, y + 26, '房主', 11, 700, WHITE, 'middle')
        if bio:
            c.text(72, y + 46, bio, 12.5, 400, MUTED)
        if owner and not is_owner:
            c.text(366, y + 34, '移出', 14, 500, RED, 'end')
    if owner:
        c.rect(16.5, 500.5, 357, 45, WHITE, rx=14, stroke=LINE)
        c.text(195, 529, '解散群組', 15, 500, RED, 'middle')
    else:
        button(c, 16, 500, 358, 46, '退出群組', 'secondary', 15)
    return c


def profile_header(c, name, bio, edit=False, email=None, follow=False):
    avatar(c, 195, 180, 44, name[0], ring=True)
    c.text(195, 252, name, 21, 800, INK, 'middle')
    pw = 52
    c.rect(195 - 85, 266, pw, 24, RED, rx=12)
    c.text(195 - 85 + pw / 2, 283, 'Lv.3', 12, 800, WHITE, 'middle')
    c.rect(195 - 22, 274, 110, 6, TINT, rx=3)
    c.rect(195 - 22, 274, 40, 6, RED, rx=3)
    y = 304
    if edit:
        c.rect(20.5, y + 0.5, 349, 47, WHITE, rx=18, stroke=LINE)
        c.text(38, y + 30, bio, 14, 400, INK)
        c.text(352, y + 30, '編輯', 15, 500, RED, 'end')
        y += 56
        if email:
            c.text(195, y + 14, email, 12, 400, MUTED, 'middle')
            y += 26
    else:
        c.text(195, y + 14, bio, 14, 400, SOFT, 'middle')
        pill(c, 155, y + 34, 80, 34, '追蹤')
        y += 82
    return y


def stats_and_achievements(c, y, posts, followers, following, unlocked=1):
    card(c, 16, y, 358, 70, rx=18)
    for i, (lab, v) in enumerate([('作品', posts), ('粉絲', followers), ('追蹤中', following)]):
        x = 16 + 358 / 6 + i * 119.3
        c.text(x, y + 34, str(v), 20, 800, INK, 'middle')
        c.text(x, y + 54, lab, 12.5, 400, MUTED, 'middle')
    y += 86
    card(c, 16, y, 358, 196, rx=18)
    c.text(32, y + 30, f'成就  {unlocked} / 6', 15, 800)
    items = [('初次發布', '發布第一件作品'), ('多產創作者', '發布 10 件作品'), ('人氣新星', '獲得 10 位粉絲'), ('熱心讀者', '按讚 20 件作品'), ('話題製造機', '留言 20 次'), ('社群之友', '追蹤 10 位創作者')]
    for i, (t, d) in enumerate(items):
        x = 30 + (i % 2) * 168
        yy = y + 46 + (i // 2) * 48
        on = i < unlocked
        c.rect(x, yy, 158, 42, PC if on else TINT, rx=12, op=1 if on else 0.6)
        c.text(x + 10, yy + 18, t, 13, 800, INK, op=1 if on else 0.55)
        c.text(x + 10, yy + 34, d, 11, 400, SOFT, op=1 if on else 0.55)
    return y + 212


def my_profile(key='my_profile', tab=0):
    c = new(key, 844 if tab == 0 else 1250)
    appbar(c, '個人檔案', right='設定')
    y = profile_header(c, 'Alice 林', '一句話讓大家認識你', edit=True, email='alice@test.com')
    y = stats_and_achievements(c, y, 1, 0, 1)
    segment(c, 16, y + 2, 358, ['作品', '收藏', '委託'], tab)
    if tab == 1:
        grid_posts(c, y + 56, [('still', '窗邊的靜物', 'Bob 陳', 3, 170), ('sea', '海邊速寫', 'Carol 王', 1, 120),
                               ('violet', '原創角色設定', 'Carol 王', 2, 130), ('rose', '玫瑰習作', 'Bob 陳', 0, 160)])
    elif tab == 2:
        commission_card(c, y + 58, '接單展示', '頭像接單中', '', 'NT$800', None, ['頭像'], 'Alice 林', '1 天前', image=True)
        commission_card(c, y + 286, '委託需求', '徵 Live2D 模型師', '角色已有立繪，需要拆件與基本綁定', 'NT$8000', '2026/12/20', ['Live2D'], 'Alice 林', '3 天前', closed=True)
    else:
        bottom_nav(c, 4)
    return c


def grid_card(c, x, y, w, ch, kind, title, name, likes):
    card(c, x, y, w, ch + 72, rx=16)
    art(c, x, y, w, ch + 16, kind, rx=16)
    c.rect(x + 1, y + ch - 0.5, w - 2, 17.5, WHITE)
    c.text(x + 10, y + ch + 26, title, 14, 700)
    avatar(c, x + 20, y + ch + 50, 10, name[0])
    c.text(x + 36, y + ch + 54, name, 12, 400, MUTED)
    c.text(x + w - 10, y + ch + 54, f'讚 {likes}', 12, 400, MUTED, 'end')
    return ch + 72


def grid_posts(c, y, items):
    """Two-column masonry, like PostMasonry."""
    ys = [y, y]
    for kind, title, name, likes, ch in items:
        col = 0 if ys[0] <= ys[1] else 1
        x = 8 + col * 191
        ys[col] += grid_card(c, x, ys[col], 183, ch, kind, title, name, likes) + 8
    return max(ys)


def user_profile(key='user_profile'):
    c = new(key)
    appbar(c, 'Bob 陳', back=True)
    y = profile_header(c, 'Bob 陳', '素描與水彩，每天一張')
    y = stats_and_achievements(c, y, 4, 0, 0)
    c.text(20, y + 8, '作品', 16, 800)
    art(c, 16, y + 22, 171, 200, 'still', rx=16)
    art(c, 203, y + 22, 171, 150, 'sea', rx=16)
    return c


def settings(key='settings'):
    c = new(key)
    appbar(c, '設定', back=True)
    c.text(20, 130, '內容設定', 15, 800)
    card(c, 16, 146, 358, 150, rx=18)
    c.text(32, 184, '顯示成人內容（NSFW）', 15, 400)
    c.text(32, 204, '預設隱藏', 12, 400, MUTED)
    switch(c, 310, 178, False)
    c.line(32, 226, 358, 226, LINE)
    c.text(32, 258, '顯示 AI 生成內容', 15, 400)
    c.text(32, 278, '預設隱藏', 12, 400, MUTED)
    switch(c, 310, 252, False)
    c.text(20, 336, '帳號', 15, 800)
    card(c, 16, 352, 358, 126, rx=18)
    c.text(32, 384, 'Alice 林', 15, 700)
    c.text(32, 404, 'alice@test.com', 13, 400, MUTED)
    button(c, 32, 420, 100, 40, '登出', 'secondary', 14)
    c.text(20, 516, '關於', 15, 800)
    card(c, 16, 532, 358, 120, rx=18)
    c.lines(32, 562, ['Art-Platform 是給繪圖創作者的社群：展示作品、', '追蹤喜歡的創作者、在群組裡一起畫畫聊天，也能', '在委託專區找到合作對象。'], 13, 22, 400, SOFT)
    c.text(20, 690, '委託免責聲明', 15, 800)
    card(c, 16, 706, 358, 112, rx=18)
    c.lines(32, 736, ['本平台僅提供委託資訊的刊登與展示，不介入雙方的', '溝通、報價、付款與交付，也不經手任何金流，對雙', '方於站外交易所產生的糾紛與法律責任概不負責。'], 13, 22, 400, SOFT)
    return c


def filter_sheet(key='filter_sheet'):
    c = new(key)
    home_header(c, 'rec')
    feed_card(c, 108, 'Bob 陳', '素描與水彩，每天一張', '窗邊的靜物', '用 2B 鉛筆畫了一個下午', ['鉛筆素描', '靜物'], 3, '5 分鐘前', 'still', '傳統手繪')
    c.rect(0, 0, 390, 844, INK, op=0.4)
    c.rect(0, 540, 390, 304, PAPER, rx=24)
    c.rect(0, 580, 390, 264, PAPER)
    c.rect(165, 552, 60, 5, MUTED, rx=3, op=0.5)
    c.text(24, 598, '內容篩選', 18, 800)
    c.text(24, 644, '顯示成人內容（NSFW）', 15, 400)
    c.text(24, 664, '預設隱藏', 12, 400, MUTED)
    switch(c, 318, 636, False)
    c.text(24, 716, '顯示 AI 生成內容', 15, 400)
    c.text(24, 736, '預設隱藏', 12, 400, MUTED)
    switch(c, 318, 708, True)
    c.text(24, 776, '登入後設定會儲存到你的帳號', 12, 400, MUTED)
    return c


EXISTING = [
    ('01_login', '登入', login, '訪客只有在發布、按讚、追蹤、留言時才會被帶到這頁'),
    ('02_home_recommend', '主頁：推薦', home_recommend, '依你的作品、按讚、收藏的標籤排序；左右滑可切到「追蹤中」'),
    ('03_home_following_guest', '主頁：追蹤中（訪客）', home_following_guest, '登入後顯示追蹤對象的最新作品'),
    ('04_post_detail', '作品詳情', post_detail, '多圖輪播、按讚／收藏／分享、留言、作者可編輯刪除'),
    ('05_publish', '發布作品', publish, '最多 10 張圖、附件（圖層檔）、標籤、成人／AI 兩題必答'),
    ('06_explore_categories', '探索：分類', explore_categories, '搜尋列、熱門標籤、四個分頁'),
    ('07_explore_creators', '探索：創作者名錄', explore_creators, '依作品數排序，可直接追蹤'),
    ('08_commission_list', '探索：委託', commission_list, '委託需求／接單展示，3 次檢舉自動隱藏'),
    ('09_commission_detail', '委託詳情', commission_detail, '站外聯絡方式、免責聲明、檢舉；作者可結案或刪除'),
    ('10_commission_form', '發布委託', commission_form, '必填聯絡方式與成人內容題，需同意免責聲明'),
    ('11_consult_list', '探索：改圖諮詢', consult_list, '發布者開放他人用圖片或文字回覆'),
    ('12_consult_detail', '改圖諮詢詳情（蓋樓）', consult_detail, '樓層編號固定，可附圖'),
    ('13_group_list', '群組列表', group_list, '我的群組／探索群組'),
    ('14_group_chat', '群組聊天室', group_chat, '只有群組聊天，沒有一對一私訊'),
    ('15_group_board', '共享白板', group_board, '即時同步；房主可鎖定、清空、發布為作品'),
    ('16_group_members', '群組成員', group_members, '房主可移出成員、解散；其他人可退出'),
    ('17_my_profile', '個人檔案（本人）', my_profile, '等級（不顯示經驗值）、成就、作品／收藏／委託'),
    ('18_user_profile', '個人檔案（他人）', user_profile, '追蹤、粉絲列表、作品'),
    ('19_settings', '設定', settings, '成人／AI 內容預設隱藏'),
    ('20_filter_sheet', '內容篩選面板', filter_sheet, '主頁右上「篩選」開啟'),
]


# name the page-level pieces too
for _n, _label in {
    'home_header': '主頁上方分頁',
    'feed_card': lambda a, k: '貼文卡片 ' + str(a[3] if len(a) > 3 else ''),
    'search_field': '搜尋列',
    'explore_top': '探索上方（搜尋＋分頁）',
    'composer': '底部輸入列',
    'commission_card': lambda a, k: '委託卡片 ' + str(a[2] if len(a) > 2 else ''),
    'dark_pill': '黑色浮動按鈕',
    'profile_header': '個人檔案上方',
    'stats_and_achievements': '統計與成就',
    'grid_card': lambda a, k: '作品小卡 ' + str(a[5] if len(a) > 5 else ''),
}.items():
    globals()[_n] = named(_label)(globals()[_n])
