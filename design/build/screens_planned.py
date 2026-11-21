"""Mockups for features that are NOT built yet (taken from the project plan).

Each frame is 760 x 844: the phone on the left, the spec on the right, with numbered
markers on the phone that match the numbered notes.
"""
from kit import *
from screens_existing import (home_header, feed_card, profile_header, stats_and_achievements,
                              explore_top, segment as _seg)


def newp(key):
    c = Canvas(key, w=760)
    c.rect(0, 0, 760, 844, '#ECE5DB', name='canvas')
    phone(c)
    return c


def dim(c, a=0.45, top=0, h=844):
    c.rect(0, top, 390, h, INK, op=a)


def sheet(c, top, title):
    c.rect(0, top, 390, 844 - top + 24, PAPER, rx=24)
    c.rect(165, top + 12, 60, 5, MUTED, rx=3, op=0.5)
    c.text(24, top + 56, title, 18, 800)


def confetti(c):
    """Burst above and beside the card so it never covers text."""
    import random
    rnd = random.Random(7)
    cols = [RED, '#E0A526', '#2F5D9E', GREEN, '#7A4FA3']
    spots = [(rnd.randint(20, 370), rnd.randint(120, 232)) for _ in range(26)]
    spots += [(rnd.choice([rnd.randint(12, 40), rnd.randint(350, 378)]), rnd.randint(250, 560)) for _ in range(12)]
    for x, y in spots:
        col = rnd.choice(cols)
        if rnd.random() < 0.5:
            c.circle(x, y, rnd.randint(3, 6), col, op=0.9)
        else:
            c.rect(x, y, rnd.randint(7, 13), 4, col, rx=2, op=0.9)


# ---- 1. splash + mascot -------------------------------------------------------

def splash():
    c = newp('p_splash')
    c.circle(195, 360, 150, TINT)
    c.circle(195, 360, 100, PC, op=0.6)
    mascot(c, 195, 345, 1.8)
    c.text(195, 520, 'Art-Platform', 28, 800, INK, 'middle', ls=1)
    c.text(195, 548, '一起畫、一起聊、一起成長', 14, 400, MUTED, 'middle')
    c.rect(95, 610, 200, 8, '#E8DED2', rx=4)
    c.rect(95, 610, 124, 8, RED, rx=4)
    c.text(195, 646, '載入中… 62%', 12, 400, MUTED, 'middle')
    c.text(195, 800, '（吉祥物外觀為示意，正式造型由美術組設計）', 11, 400, MUTED, 'middle')
    c.rect(167, 690, 56, 56, RED, rx=14)
    mascot(c, 195, 718, 0.26, 'happy', beret=False)
    c.text(195, 764, 'App Icon', 11, 400, MUTED, 'middle')
    callout(c, 1, 290, 250)
    callout(c, 2, 226, 690)
    note_panel(c, 410, '看板娘與啟動畫面', '美術：冠呈、喬琳', [
        ['看板娘（吉祥物）', '造型由美術組設計，先決定名字與風格；', '之後空狀態、新手導覽、升級畫面都用同一隻'],
        ['App Icon', '用看板娘或印章 Logo 皆可'],
    ])
    return c


def onboarding():
    c = newp('p_onboarding')
    home_header(c, 'rec')
    feed_card(c, 108, 'Bob 陳', '素描與水彩，每天一張', '窗邊的靜物', '用 2B 鉛筆畫了一個下午', ['鉛筆素描', '靜物'], 3, '5 分鐘前', 'still', '傳統手繪')
    bottom_nav(c, 2)
    spotlight(c, 231, 794, 84, 38, 19)
    mascot(c, 84, 560, 1.0, 'happy')
    c.rect(140, 470, 226, 142, WHITE, rx=20)
    c.path('M140 560 L124 572 L140 584 Z', fill=WHITE)
    c.text(158, 504, '第一次發布作品', 15, 800)
    c.text(158, 526, '只要 3 步驟！', 15, 800, RED)
    c.lines(158, 554, ['① 選圖片', '② 填標題、選分類', '③ 回答兩題標籤'], 13, 20, 400, SOFT)
    for i in range(5):
        c.circle(150 + i * 14, 640, 4, RED if i == 0 else WHITE, op=1 if i == 0 else 0.6)
    c.text(256, 646, '略過', 14, 500, WHITE, 'end', op=0.9)
    pill(c, 276, 626, 90, 34, '下一步', size=13)
    callout(c, 1, 84, 480)
    callout(c, 2, 312, 800)
    callout(c, 3, 360, 480)
    callout(c, 4, 268, 632)
    note_panel(c, 410, '新手導覽（看板娘教學）', '陳亮均（個人）＋仲辰（導覽觸發）', [
        ['首次登入自動出現，之後可在設定重播', 'users 文件記錄 onboardingDone'],
        ['每步驟聚光燈高亮一個功能', '發布 → 追蹤 → 探索 → 群組 → 個人'],
        ['看板娘台詞與表情', '由美術／文案提供，程式只負責對話框'],
        ['可隨時「略過」', '略過也算完成，不會再次打擾'],
    ])
    return c


def level_up():
    c = newp('p_level_up')
    home_header(c, 'rec')
    feed_card(c, 108, 'Bob 陳', '素描與水彩，每天一張', '窗邊的靜物', '用 2B 鉛筆畫了一個下午', ['鉛筆素描', '靜物'], 3, '5 分鐘前', 'still', '傳統手繪')
    dim(c, 0.55)
    c.rect(45, 240, 300, 360, WHITE, rx=28, shadow=True)
    confetti(c)
    mascot(c, 195, 340, 1.15, 'happy')
    c.text(195, 452, 'Lv.4', 46, 800, RED, 'middle')
    c.text(195, 486, '升級了！', 20, 800, INK, 'middle')
    c.rect(95, 506, 200, 30, PC, rx=15)
    c.text(195, 526, '新成就：多產創作者', 13, 700, '#6B1E14', 'middle')
    button(c, 95, 548, 200, 40, '太棒了', 'primary', 15)
    callout(c, 1, 56, 252)
    callout(c, 2, 300, 452)
    callout(c, 3, 298, 508)
    callout(c, 4, 120, 290)
    note_panel(c, 410, '升級驚喜動畫', '陳亮均（個人中心）', [
        ['觸發時機', '發布、按讚、留言累積到下一級門檻時，', '回到主頁彈出一次'],
        ['只顯示等級，不顯示經驗值', '（目前 utils/level.dart 已能算等級）'],
        ['profiles 記 lastSeenLevel', '大於它才彈，避免重複'],
        ['動畫 1.5 秒內', '看板娘跳起＋彩帶；可關閉動畫'],
    ])
    return c


# ---- 2. profile ---------------------------------------------------------------

def edit_profile():
    c = newp('p_edit_profile')
    appbar(c, '編輯個人檔案', back=True, right='儲存')
    avatar(c, 195, 176, 48, 'A', ring=True)
    pill(c, 120, 238, 70, 32, '相簿', filled=False)
    pill(c, 200, 238, 70, 32, '拍照', filled=False)
    c.text(195, 304, '或選一個預設人像', 13, 700, SOFT, 'middle')
    shades = [PC, '#E2ECE4', '#E3E8F3', '#F3EBD5', '#EBE1F0', '#F6E3DC', '#DDE9EE', '#F1E4EF']
    for i, col in enumerate(shades):
        cx = 62 + (i % 4) * 88
        cy = 346 + (i // 4) * 72
        c.circle(cx, cy, 28, col, stroke=RED if i == 2 else None, sw=3)
        c.circle(cx, cy - 4, 10, WHITE, op=0.75)
        c.path(f'M{cx - 16} {cy + 22} Q{cx} {cy + 2} {cx + 16} {cy + 22}', fill=WHITE, op=0.75)
    field(c, 16, 474, 358, 60, label='名稱', value='Alice 林')
    field(c, 16, 550, 358, 60, label='自我介紹', value='一句話讓大家認識你', counter='9/40')
    c.rect(16.5, 640.5, 357, 40, TINT, rx=14)
    c.text(32, 666, 'Email', 12, 400, MUTED)
    c.text(110, 666, 'alice@test.com（不可修改）', 14, 400, SOFT)
    c.rect(16.5, 692.5, 357, 40, TINT, rx=14)
    c.text(32, 718, '加入時間', 12, 400, MUTED)
    c.text(110, 718, '2026/09/18', 14, 400, SOFT)
    button(c, 16, 754, 358, 50, '儲存')
    callout(c, 1, 244, 140)
    callout(c, 2, 335, 326)
    callout(c, 3, 350, 706)
    callout(c, 4, 350, 500)
    note_panel(c, 410, '編輯檔案、自訂大頭貼', '陳亮均（個人中心）', [
        ['自訂頭像', '相簿／拍照 → 裁成正方形、2MB 內', '存 Storage avatars/{uid}.jpg'],
        ['預設人像 8～12 張', '由美術組提供；選了就寫入 photoUrl'],
        ['顯示註冊時間', '計畫書個人檔案欄位（目前沒顯示）'],
        ['名稱、簡介可改', '改了要同步 posts 上的 userName／', 'userPhotoUrl（比照現有 updateBio）'],
    ])
    return c


def switch_account():
    c = newp('p_switch_account')
    appbar(c, '個人檔案', right='設定')
    y = profile_header(c, 'Alice 林', '一句話讓大家認識你', edit=True, email='alice@test.com')
    stats_and_achievements(c, y, 1, 0, 1)
    bottom_nav(c, 4)
    dim(c, 0.4)
    sheet(c, 470, '切換帳號')
    rows = [('Alice 林', 'alice@test.com', True), ('Bob 陳', 'bob@test.com', False)]
    for i, (n, em, cur) in enumerate(rows):
        y0 = 540 + i * 64
        avatar(c, 46, y0 + 20, 22, n[0])
        c.text(80, y0 + 16, n, 15, 700)
        c.text(80, y0 + 36, em, 12.5, 400, MUTED)
        if cur:
            badge(c, 290, y0 + 8, '目前使用', RED)
    c.text(24, 690, '＋ 新增帳號', 15, 500, RED)
    c.line(24, 708, 366, 708, LINE)
    c.text(24, 740, '登出', 15, 500, MUTED)
    callout(c, 1, 350, 488)
    callout(c, 2, 10, 552)
    callout(c, 3, 10, 616)
    note_panel(c, 410, '切換帳號', '陳亮均（個人中心）', [
        ['同一支手機多個 Google 帳號', '個人頁右上「設定」或長按頭像開啟'],
        ['技術：切換＝登出後用帳號選擇器重登', 'authStateChanges 會自動重載追蹤／按讚清單'],
        ['最近使用的帳號記在本機', '只存 email 與名稱，不存密碼'],
    ])
    return c


def achievements():
    c = newp('p_achievements')
    appbar(c, '成就與等級', back=True)
    c.circle(195, 200, 62, None, stroke=TINT, sw=12)
    c.path('M195 138 A62 62 0 1 1 138 224', stroke=RED, sw=12)
    c.text(195, 212, 'Lv.3', 34, 800, INK, 'middle')
    c.text(195, 292, '再多互動一點就能升級', 14, 400, SOFT, 'middle')
    c.text(195, 312, '（不顯示經驗值）', 11, 400, MUTED, 'middle')
    card(c, 16, 332, 358, 56, rx=16)
    c.text(32, 366, '目前稱號', 13, 400, MUTED)
    c.text(110, 366, '初次發布 ▾', 15, 700)
    rows = [('初次發布', '2026/09/18 解鎖', 1.0, True), ('熱心讀者', '按讚 20 件作品', 0.55, False), ('人氣新星', '獲得 10 位粉絲', 0.1, False), ('多產創作者', '發布 10 件作品', 0.3, False)]
    for i, (t, d, p, on) in enumerate(rows):
        y = 404 + i * 70
        card(c, 16, y, 358, 60, rx=16)
        c.rect(30, y + 12, 36, 36, PC if on else TINT, rx=12)
        c.text(48, y + 36, '★' if on else '○', 16, 700, RED if on else MUTED, 'middle')
        c.text(80, y + 26, t, 14, 700)
        c.text(80, y + 46, d, 12, 400, MUTED)
        if not on:
            c.rect(250, y + 26, 100, 6, TINT, rx=3)
            c.rect(250, y + 26, 100 * p, 6, RED, rx=3)
    card(c, 16, 686, 358, 60, rx=16)
    c.text(32, 722, '？？？  隱藏成就（達成前不公開）', 14, 500, MUTED)
    callout(c, 1, 270, 138)
    callout(c, 2, 352, 352)
    callout(c, 3, 362, 478)
    callout(c, 4, 362, 716)
    callout(c, 5, 362, 410)
    note_panel(c, 410, '成就與稱號頁', '陳亮均（個人中心）', [
        ['等級環只畫進度，不顯示數字', '（隱藏式經驗值）'],
        ['稱號', '從已解鎖成就挑一個顯示在名稱旁'],
        ['未解鎖成就顯示進度條', '不顯示確切數字，保留神祕感'],
        ['隱藏成就 ???', '驚喜型，例如「深夜創作」'],
        ['成就清單擴充', '目前 6 個（utils/level.dart），可加到 12+'],
    ])
    return c


def notifications():
    c = newp('p_notifications')
    appbar(c, '通知')
    segment(c, 16, 108, 358, ['全部', '互動', '追蹤', '系統'], 0)
    rows = [
        ('B', 'Bob 陳 讚了你的作品「窗邊的靜物」', '5 分鐘前', True),
        ('C', 'Carol 王 回覆了你的改圖諮詢（3 樓）', '20 分鐘前', True),
        ('D', 'Dave 追蹤了你', '1 小時前', False),
        ('藝', '你升到 Lv.3，解鎖「初次發布」', '昨天', False),
        ('藝', '你的委託「徵 VTuber 立繪」被檢舉 1 次', '昨天', False),
    ]
    for i, (a, t, ago, unread) in enumerate(rows):
        y = 164 + i * 84
        if unread:
            c.rect(16, y, 358, 74, PC, rx=18, op=0.5)
        avatar(c, 46, y + 37, 22, a)
        for k, piece in enumerate(wrap(t, 14, 220)[:2]):
            c.text(80, y + 32 + k * 20, piece, 14, 600 if unread else 400)
        c.text(362, y + 22, ago, 11, 400, MUTED, 'end')
        if unread:
            c.circle(356, y + 52, 5, RED)
    bottom_nav(c, 4)
    callout(c, 1, 10, 201)
    callout(c, 2, 10, 285)
    callout(c, 3, 372, 796)
    callout(c, 4, 10, 127)
    note_panel(c, 410, '通知中心', '仲辰（資料）＋陳亮均（入口）', [
        ['通知來源', '讚、留言、追蹤、蓋樓、升級、檢舉處理'],
        ['資料：users/{uid}/notifications', '誰觸發就由誰寫入（規則要加）'],
        ['入口', '個人或主頁右上角紅點；未讀數字'],
        ['推播（FCM）為選做', '作業可先做 App 內通知'],
    ], status='待實現（計畫書未列，建議）')
    return c


# ---- 3. group -----------------------------------------------------------------

def board_base(c, board_h=300):
    appbar(c, '速寫小聚', back=True, sub='3 位成員')
    segment(c, 16, 108, 358, ['聊天', '白板', '成員'], 1)
    c.rect(16, 160, 358, board_h, WHITE, rx=14, stroke=LINE, shadow=True)
    c.path('M70 220 Q140 300 210 270 T330 230', stroke=RED, sw=5)
    c.path('M90 330 Q150 300 220 350 T320 320', stroke='#2F5D9E', sw=5)


def board_layers():
    c = newp('p_board_layers')
    board_base(c, 300)
    c.text(24, 488, '圖層', 15, 800)
    c.text(366, 488, '＋ 新增圖層', 14, 500, RED, 'end')
    rows = [('圖層 3', 'Alice', False, False, True), ('圖層 2', 'Bob', False, False, False), ('背景', '房主', True, True, False)]
    for i, (n, who, locked, hidden, mine) in enumerate(rows):
        y = 504 + i * 66
        card(c, 16, y, 358, 58, rx=14)
        c.rect(30, y + 10, 38, 38, TINT, rx=8)
        c.path(f'M36 {y + 40} L50 {y + 22} L62 {y + 36}', stroke=RED if i == 0 else '#2F5D9E', sw=3)
        c.text(82, y + 28, n, 14, 700)
        c.text(82, y + 46, f'{who}', 12, 400, MUTED)
        pill(c, 224, y + 14, 56, 30, '隱藏' if not hidden else '顯示', filled=False, size=12)
        pill(c, 288, y + 14, 70, 30, '已鎖定' if locked else '鎖定', filled=locked, size=12, color=INK)
    c.rect(16, 704, 358, 50, TINT, rx=14)
    c.text(32, 734, '目前在「圖層 3」作畫；被房主鎖定的圖層只能看', 12.5, 400, SOFT)
    callout(c, 1, 10, 488)
    callout(c, 2, 10, 533)
    callout(c, 3, 10, 599)
    callout(c, 4, 10, 665)
    note_panel(c, 410, '白板圖層', '陳森堯（群組）', [
        ['每位成員有自己的圖層', '可隱藏、重新排序；上限 8 層'],
        ['房主可鎖定任何圖層', '鎖定後只有房主能編輯（計畫書：鎖定圖層）'],
        ['資料', 'strokes 加 layerId；groups/{id}/layers 存順序與鎖定'],
        ['匯出 PNG 時依圖層順序合成', '隱藏的圖層不輸出（renderBoardPng 要改）'],
    ])
    return c


def owner_tools():
    c = newp('p_owner_tools')
    board_base(c, 400)
    dim(c, 0.4, 100)
    sheet(c, 400, '房主工具')
    items = [('鎖定整個白板', 'switch', False), ('鎖定圖層', '›', None), ('存檔目前版本', '›', None), ('版本歷史', '3 個 ›', None), ('發布為作品', '›', None), ('移交房主', '›', None)]
    for i, (t, r, on) in enumerate(items):
        y = 468 + i * 48
        c.text(24, y + 22, t, 15, 400)
        if r == 'switch':
            switch(c, 318, y + 4, on)
        else:
            c.text(366, y + 22, r, 14, 400, MUTED, 'end')
        c.line(24, y + 38, 366, y + 38, LINE)
    c.text(24, 782, '清空白板', 15, 500, RED)
    callout(c, 1, 10, 490)
    callout(c, 2, 10, 586)
    callout(c, 3, 10, 634)
    callout(c, 4, 10, 722)
    note_panel(c, 410, '房主權限面板', '陳森堯（群組）', [
        ['房主掌握存檔主導權', '只有房主能存檔、還原、發布'],
        ['存檔版本', '縮圖＋時間＋存檔者；groups/{id}/snapshots', '圖片存 Storage'],
        ['版本歷史可還原', '還原前提示並自動再存一份目前版本'],
        ['移交房主', '離開前可移交；規則要允許改 ownerId'],
    ])
    return c


def group_invite():
    c = newp('p_group_invite')
    appbar(c, '建立群組', back=True, right='建立')
    field(c, 16, 112, 358, 56, label='群組名稱', value='速寫小聚')
    field(c, 16, 184, 358, 96, label='簡介', value='每週一起畫速寫', counter='7/200')
    c.text(16, 322, '加入方式', 15, 700)
    segment(c, 16, 336, 358, ['公開', '私人（邀請碼）'], 1)
    card(c, 16, 396, 358, 150, rx=18)
    c.text(195, 430, '邀請碼', 13, 400, MUTED, 'middle')
    c.text(195, 484, 'A7K9Q2', 40, 800, RED, 'middle', ls=6)
    pill(c, 100, 504, 80, 32, '複製', filled=False)
    pill(c, 210, 504, 80, 32, '重新產生', filled=False)
    c.text(32, 586, '加入需房主同意', 15, 400)
    switch(c, 310, 566, True)
    c.line(24, 606, 366, 606, LINE)
    c.text(32, 640, '成員可邀請朋友', 15, 400)
    switch(c, 310, 620, False)
    button(c, 16, 700, 358, 50, '建立群組')
    callout(c, 1, 10, 352)
    callout(c, 2, 10, 432)
    callout(c, 3, 10, 578)
    callout(c, 4, 10, 724)
    note_panel(c, 410, '私人群組與邀請碼', '陳森堯（群組）', [
        ['公開／私人', '公開出現在「探索群組」；', '私人只能用邀請碼加入'],
        ['邀請碼 6 碼', 'groups.inviteCode；「探索群組」上方加輸入框'],
        ['加入需同意', '申請清單放在成員頁，房主同意後才進 memberIds'],
        ['規則要補', '用邀請碼加入的驗證（Cloud Function 或規則比對）'],
    ])
    return c


# ---- 4. explore / safety --------------------------------------------------------

def search_filter():
    c = newp('p_search_filter')
    appbar(c, '#水彩畫', back=True)
    segment(c, 16, 108, 358, ['關聯性', '最新', '評價'], 0)
    x = 16
    for lab in ['分類 ▾', '媒材 ▾', '含 AI', '含成人']:
        x += chip(c, x, 160, lab, selected=(lab == '分類 ▾'), tint=WHITE) + 8
    c.text(16, 226, '創作者', 15, 800)
    for i, n in enumerate(['Bob 陳', 'Carol 王']):
        avatar(c, 40 + i * 120, 262, 22, n[0])
        c.text(40 + i * 120 + 30, 266, n, 13, 600)
    c.text(16, 322, '作品', 15, 800)
    kinds = ['sea', 'green', 'warm', 'rose']
    heights = [190, 150, 150, 190]
    ys = [336, 336, 536, 496]
    for i in range(4):
        x0 = 16 + (i % 2) * 187
        y0 = [336, 336, 536 if i == 2 else 496, 0][i]
        y0 = 336 if i < 2 else (336 + heights[i - 2] + 40 + 8)
        art(c, x0, y0, 171, heights[i], kinds[i], rx=16)
        c.text(x0 + 4, y0 + heights[i] + 20, ['雨後街景', '春日山徑', '水彩練習', '花與窗'][i], 13, 700)
        c.text(x0 + 4, y0 + heights[i] + 38, '讚 ' + str([12, 8, 5, 3][i]), 11, 400, MUTED)
    callout(c, 1, 10, 128)
    callout(c, 2, 10, 176)
    callout(c, 3, 10, 86)
    callout(c, 4, 10, 760)
    note_panel(c, 410, '搜尋排序與篩選', '許鈞棠（探索與搜尋）', [
        ['排序', '關聯性（標籤符合＋熱度）／最新／評價（讚數）'],
        ['篩選', '分類、媒材標籤、是否含 AI／成人', '預設跟隨設定頁開關'],
        ['搜尋歷史與建議', '最近 5 筆；輸入時列出相符標籤'],
        ['規模變大再換 Algolia／Typesense', '作業階段沿用現有查詢即可'],
    ])
    return c


def label_review():
    c = newp('p_label_review')
    appbar(c, '窗邊的靜物', back=True, right='更多')
    c.rect(16, 108, 358, 118, PC, rx=18)
    c.text(32, 138, '有 2 位使用者回報這件作品的標籤', 14, 700, '#6B1E14')
    c.text(32, 158, '可能不正確（AI 生成內容未標示）', 14, 700, '#6B1E14')
    pill(c, 32, 176, 130, 34, '查看並更正標籤', size=13)
    pill(c, 172, 176, 76, 34, '我要申訴', filled=False, size=13)
    art(c, 0, 240, 390, 220, 'still', rx=0)
    card(c, 16, 480, 358, 96, rx=18)
    c.text(32, 510, '安全標籤', 14, 800)
    chip(c, 32, 526, '成人內容：否', tint=TINT)
    chip(c, 150, 526, 'AI 生成：否', tint=PC, selected=True)
    c.text(32, 566, '回報人數 2／需要 3 位才會自動標示', 11, 400, MUTED)
    sheet(c, 600, '回報標籤不正確')
    for i, t in enumerate(['這是 AI 生成的作品', '含有成人內容', '其他原因']):
        y = 684 + i * 44
        c.circle(36, y + 12, 9, WHITE, stroke=RED if i == 0 else MUTED, sw=2)
        if i == 0:
            c.circle(36, y + 12, 4.5, RED)
        c.text(56, y + 18, t, 14, 400)
    callout(c, 1, 360, 118)
    callout(c, 2, 360, 510)
    callout(c, 3, 254, 176)
    callout(c, 4, 360, 612)
    note_panel(c, 410, '標籤審查流程', '仲辰（發布）＋許鈞棠', [
        ['⚠ 需求待確認', '計畫書「雙重安全審查標籤（全票通過機制）」', '目前實作成「發布者必須回答兩題」。', '若要社群審查，建議這個流程：'],
        ['達到 N 人回報 → 通知作者', '作者 7 天內更正，否則系統自動標示'],
        ['作者可申訴', '申訴期間先套用回報結果'],
        ['回報 sheet', '三個選項；每人每作品一次（沿用 reports 集合）'],
    ], status='待確認需求')
    return c


PLANNED = [
    ('P01_splash_mascot', '看板娘與啟動畫面（先示意）', splash, '美術', '造型由美術組決定，這裡只放位置'),
    ('P02_onboarding', '新手導覽', onboarding, '個人', '聚光燈＋看板娘教學，3 步驟發布'),
    ('P03_level_up', '升級驚喜動畫', level_up, '個人', '只顯示等級，不公開經驗值'),
    ('P04_edit_profile', '編輯檔案／自訂大頭貼', edit_profile, '個人', '相簿、拍照、預設人像、註冊時間'),
    ('P05_switch_account', '切換帳號', switch_account, '個人', '同一支手機多帳號'),
    ('P06_achievements', '成就與稱號', achievements, '個人', '進度條不顯示數字、隱藏成就'),
    ('P07_notifications', '通知中心', notifications, '主頁', '讚、留言、追蹤、蓋樓、升級'),
    ('P08_board_layers', '白板圖層', board_layers, '群組', '每人一層，房主可鎖定圖層'),
    ('P09_owner_tools', '房主權限面板', owner_tools, '群組', '存檔主導權、版本歷史、移交房主'),
    ('P10_group_invite', '私人群組與邀請碼', group_invite, '群組', '公開／私人、加入需同意'),
    ('P11_search_filter', '搜尋排序與篩選', search_filter, '探索', '關聯性／最新／評價'),
    ('P12_label_review', '標籤審查流程', label_review, '主頁', '需求待確認：全票通過機制'),
]
