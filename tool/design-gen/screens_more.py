"""Remaining screens, dialogs, sheets and empty states of the app (all already implemented)."""
from kit import *
import screens_existing as E
from screens_existing import new, home_header, composer, grid_posts, grid_card


# ---- shared overlays ---------------------------------------------------------

def overlay(c, a=0.42):
    c.rect(0, 0, 390, c.h, INK, op=a, name='遮罩')


def dialog(c, title, body=None, actions=('取消', '確定'), extra=0):
    """Material AlertDialog. Returns the y where extra content (fields) can start."""
    overlay(c)
    w, x = 318, 36
    lines = wrap(body, 14, w - 30) if body else []
    body_h = len(lines) * 21 + 14 if lines else 14
    h = 24 + 28 + body_h + extra + 20 + 40 + 6
    y = (844 - h) / 2 - 24
    c.rect(x, y, w, h, WHITE, rx=28, name='彈窗底')
    c.text(x + 24, y + 48, title, 20, 700)
    for i, ln in enumerate(lines):
        c.text(x + 24, y + 78 + i * 21, ln, 14, 400, SOFT)
    top = y + 40 + body_h + 8
    ax = x + w - 24
    for a in reversed(actions):
        aw = tw(a, 14) + 24
        c.text(ax - aw / 2 + 4, y + h - 26, a, 14, 600, RED, 'middle')
        ax -= aw + 4
    return top


def sheet_list(c, rows, title=None, sub=None):
    """Bottom sheet with a drag handle and ListTile rows. rows: [(label, color, subtitle)]."""
    overlay(c)
    row_h = [72 if r[2] else 56 for r in rows]
    h = 34 + (44 if title else 0) + sum(row_h) + 34
    top = 844 - h
    c.rect(0, top, 390, h + 24, PAPER, rx=24)
    c.rect(165, top + 12, 60, 5, MUTED, rx=3, op=0.5)
    y = top + 34
    if title:
        c.text(20, y + 24, title, 18, 700)
        y += 44
    for (label, color, subtitle), rh in zip(rows, row_h):
        if subtitle:
            c.text(20, y + 30, label, 16, 400, color)
            c.text(20, y + 52, subtitle, 13, 400, MUTED)
        else:
            c.text(20, y + 34, label, 16, 400, color)
        y += rh
    return top


def empty_msg(c, y, lines, button_label=None):
    for i, ln in enumerate(lines):
        c.text(195, y + i * 24, ln, 15, 400, SOFT if i == 0 else MUTED, 'middle')
    if button_label:
        button(c, 150, y + len(lines) * 24 + 4, 90, 42, button_label)


# ---- 首頁／狀態 -------------------------------------------------------------

def home_following_empty():
    c = new('home_following_empty')
    home_header(c, 'follow')
    empty_msg(c, 390, ['還沒有追蹤任何創作者', '到「推薦」找找喜歡的作品吧'])
    bottom_nav(c, 2)
    return c


def home_loading():
    c = new('home_loading')
    home_header(c, 'rec')
    for i in range(2):
        y = 108 + i * 300
        card(c, 14, y, 362, 280, rx=24)
        c.circle(47, y + 38, 19, TINT)
        c.rect(76, y + 26, 120, 14, TINT, rx=7)
        c.rect(76, y + 48, 190, 12, TINT, rx=6)
        c.rect(24, y + 78, 342, 140, TINT, rx=16)
        c.rect(30, y + 234, 220, 14, TINT, rx=7)
        c.rect(30, y + 258, 150, 12, TINT, rx=6)
    bottom_nav(c, 2)
    return c


def load_error():
    c = new('load_error')
    appbar(c, '粉絲', back=True)
    c.text(195, 400, '讀取失敗，請確認網路連線', 15, 400, INK, 'middle')
    button(c, 150, 424, 90, 42, '重試')
    c.text(195, 520, '所有清單頁（動態、搜尋、委託、諮詢…）共用這個狀態', 12, 400, MUTED, 'middle')
    return c


# ---- 作品 --------------------------------------------------------------------

def post_menu_owner():
    c = E.post_detail('post_menu_owner')
    sheet_list(c, [('編輯作品', INK, None), ('刪除作品', RED, None)])
    return c


def post_menu_other():
    c = E.post_detail('post_menu_other')
    sheet_list(c, [('檢舉作品', INK, None)])
    return c


def report_sheet():
    c = E.post_detail('report_sheet')
    sheet_list(c, [(t, INK, None) for t in ['成人內容未標示', 'AI 內容未標示', '侵權或抄襲', '垃圾訊息或廣告', '騷擾或不當內容', '其他']], title='檢舉原因')
    return c


def post_delete_dialog():
    c = E.post_detail('post_delete_dialog')
    dialog(c, '刪除這件作品？', '作品、圖片與留言都會一併移除，無法復原。', ('取消', '刪除'))
    return c


def image_viewer():
    c = new('image_viewer')
    c.rect(0, 0, 390, 844, '#000000')
    status_bar(c, light=True)
    art(c, 0, 190, 390, 440, 'still', rx=0)
    c.text(20, 90, '關閉', 16, 500, WHITE)
    c.text(358, 90, '1 / 3', 14, 400, WHITE, 'end')
    c.text(195, 700, '雙指縮放、左右滑動切換圖片', 12, 400, WHITE, 'middle', op=0.6)
    return c


def image_source_sheet():
    c = E.publish('image_source_sheet', h=844)
    sheet_list(c, [('從相簿選擇（可多選）', INK, None), ('拍照', INK, None), ('從檔案選擇', INK, 'JPG、PNG、WebP、GIF、BMP、HEIC')])
    return c


def edit_post():
    c = new('edit_post')
    appbar(c, '編輯作品', back=True, right='儲存')
    field(c, 16, 112, 358, 56, label='標題', value='窗邊的靜物')
    c.rect(16.5, 192.5, 357, 111, WHITE, rx=14, stroke=LINE)
    c.text(32, 214, '作品描述', 12, 400, MUTED)
    c.text(32, 242, '用 2B 鉛筆畫了一個下午', 15, 400, INK)
    c.text(16, 342, '分類', 15, 800)
    x = 16
    for i, t in enumerate(['傳統手繪', '顏料繪畫', '數位繪圖']):
        x += chip(c, x, 356, t, selected=(i == 0), tint=WHITE) + 8
    c.text(16, 424, '標籤', 15, 800)
    x = 16
    for t in ['#鉛筆素描', '#靜物']:
        x += chip(c, x, 438, t + '  ✕') + 8
    field(c, 16, 488, 290, 44, placeholder='自訂標籤，例如：光影練習')
    pill(c, 314, 493, 60, 34, '新增', filled=False)
    c.text(16, 580, '圖片、成人內容與 AI 生成標籤在發布後無法修改。', 12, 400, MUTED)
    return c


# ---- 探索 --------------------------------------------------------------------

def category_posts():
    c = new('category_posts')
    appbar(c, '傳統手繪', back=True)
    grid_posts(c, 102, [('still', '窗邊的靜物', 'Bob 陳', 3, 170), ('sea', '海邊速寫', 'Bob 陳', 1, 120),
                        ('warm', '午後人像', 'Carol 王', 2, 130), ('rose', '玫瑰習作', 'Bob 陳', 0, 180),
                        ('violet', '手部練習', 'Alice 林', 1, 150), ('still', '咖啡杯', 'Alice 林', 0, 110)])
    return c


def search_results():
    c = new('search_results')
    appbar(c, '素描', back=True)
    c.text(16, 128, '創作者', 15, 800)
    for i, (n, bio) in enumerate([('Bob 陳', '素描與水彩，每天一張'), ('小明', '水墨與書法')]):
        y = 140 + i * 64
        avatar(c, 40, y + 32, 22, n[0])
        c.text(76, y + 30, n, 15, 700)
        c.text(76, y + 50, bio, 12.5, 400, MUTED)
        pill(c, 300, y + 16, 64, 32, '追蹤')
    c.text(16, 296, '作品', 15, 800)
    grid_posts(c, 312, [('still', '窗邊的靜物', 'Bob 陳', 3, 170), ('sea', '海邊速寫', 'Bob 陳', 1, 120),
                        ('rose', '玫瑰習作', 'Bob 陳', 0, 150), ('warm', '午後人像', 'Carol 王', 2, 110)])
    c.text(195, 770, '搜尋 #標籤 時只顯示該標籤的作品', 12, 400, MUTED, 'middle')
    return c


def search_empty():
    c = new('search_empty')
    appbar(c, '水彩', back=True)
    c.text(16, 128, '作品', 15, 800)
    c.text(195, 330, '找不到符合「水彩」的作品', 15, 400, SOFT, 'middle')
    c.text(195, 360, '3 件作品因內容篩選被隱藏（有 NSFW／AI 時顯示這行）', 12, 400, MUTED, 'middle')
    return c


def disclaimer_dialog():
    c = E.commission_list('disclaimer_dialog')
    dialog(c, '免責聲明', '本平台僅提供委託資訊的刊登與展示，不介入雙方的溝通、報價、付款與交付，也不經手任何金流，對雙方於站外交易所產生的糾紛與法律責任概不負責。請自行確認對方身分並留意詐騙。', ('知道了',))
    return c


def commission_detail_owner():
    return E.commission_detail('commission_owner', owner=True)


def commission_delete_dialog():
    c = E.commission_detail('commission_delete', owner=True)
    dialog(c, '刪除這則委託？', '刪除後無法復原。', ('取消', '刪除'))
    return c


def consult_create():
    c = new('consult_create')
    appbar(c, '發布改圖諮詢', back=True, right='發布')
    c.rect(16.5, 112.5, 357, 199, TINT, rx=18, stroke=LINE)
    c.text(195, 218, '點擊選擇要諮詢的作品', 15, 400, SOFT, 'middle')
    field(c, 16, 336, 358, 56, label='標題', placeholder='例如：手的比例總是怪怪的', counter='0/50')
    c.rect(16.5, 420.5, 357, 109, WHITE, rx=14, stroke=LINE)
    c.text(32, 442, '想請大家看哪裡？（選填）', 12, 400, MUTED)
    c.rect(14, 562, 362, 82, TINT, rx=16)
    c.lines(30, 588, ['發布後，其他創作者可以直接用圖片或文字回覆你（蓋', '樓），也就是授權他們在你的作品上畫改圖草稿。'], 12.5, 22, 400, SOFT)
    return c


# ---- 群組 --------------------------------------------------------------------

def group_create_dialog():
    c = E.group_list('group_create_dialog')
    top = dialog(c, '建立群組', None, ('取消', '建立'), extra=214)
    field(c, 60, top, 270, 56, label='群組名稱', counter='0/30')
    c.rect(60.5, top + 90.5, 269, 95, WHITE, rx=14, stroke=LINE)
    c.text(76, top + 112, '簡介（選填）', 12, 400, MUTED)
    c.text(316, top + 202, '0/200', 11, 400, MUTED, 'end')
    return c


def chat_delete_dialog():
    c = E.group_chat('chat_delete_dialog')
    dialog(c, '刪除這則訊息？', None, ('取消', '刪除'))
    c.text(195, 700, '長按自己的訊息（房主可刪任何人的）開啟', 12, 400, WHITE, 'middle', op=0.8)
    return c


def board_clear_dialog():
    c = E.group_board('board_clear_dialog')
    dialog(c, '清空整個白板？', None, ('取消', '確定'))
    return c


def member_kick_dialog():
    c = E.group_members('member_kick_dialog', owner=True)
    dialog(c, '移出 Carol 王？', '對方會立刻失去聊天室與白板的存取權。', ('取消', '確定'))
    return c


def group_dissolve_dialog():
    c = E.group_members('group_dissolve_dialog', owner=True)
    dialog(c, '解散群組？', '聊天紀錄與白板都會一併刪除，無法復原。', ('取消', '確定'))
    return c


def group_members_owner():
    return E.group_members('group_members_owner', owner=True)


# ---- 個人 --------------------------------------------------------------------

def profile_collections():
    return E.my_profile('profile_collections', tab=1)


def profile_commissions():
    return E.my_profile('profile_commissions', tab=2)


def edit_bio_dialog():
    c = E.my_profile('edit_bio_dialog')
    top = dialog(c, '自我介紹', None, ('取消', '儲存'), extra=70)
    field(c, 60, top, 270, 52, placeholder='一句話讓大家認識你', counter='0/40')
    return c


def follow_list(followers=True):
    key = 'follow_followers' if followers else 'follow_following'
    c = new(key)
    appbar(c, '粉絲' if followers else '追蹤中', back=True)
    rows = [('Bob 陳', '素描與水彩，每天一張', False), ('Carol 王', '角色設計 / 接稿中', True), ('小明', '', False), ('Dora 張', '水彩日記', False)]
    for i, (n, bio, on) in enumerate(rows):
        y = 100 + i * 72
        avatar(c, 40, y + 36, 24, n[0])
        c.text(76, y + 32 if bio else y + 41, n, 16, 700)
        if bio:
            c.text(76, y + 54, bio, 13, 400, MUTED)
        pill(c, 300, y + 20, 64, 32, '追蹤中' if on else '追蹤', filled=not on)
        c.line(76, y + 72, 390, y + 72, LINE)
    return c


def follow_followers():
    return follow_list(True)


def follow_following():
    return follow_list(False)


def follow_empty():
    c = new('follow_empty')
    appbar(c, '追蹤中', back=True)
    c.text(195, 420, '還沒有追蹤任何人', 15, 400, MUTED, 'middle')
    return c


def logout_dialog():
    c = E.settings('logout_dialog')
    dialog(c, '登出？', None, ('取消', '登出'))
    return c


# ---- 長頁面（捲動後的全長）------------------------------------------------------
# publish / commission_form / my_profile 的分頁版已在 screens_existing 內以較高的畫布繪製。
