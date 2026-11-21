# 設計稿（Figma 匯入用）

目前已完成與尚未實現的畫面都畫成 SVG（檔名前面的編號是依功能分組排序：登入與主頁、作品、探索與搜尋、群組、個人中心），可直接拖進 Figma；也有一頁可分享的總覽 `gallery.html`（用瀏覽器開，點圖放大）。

```
design/
  png/existing/   已完成畫面的 PNG（2 倍，780 px 寬）← 直接下載、拖進 Figma 就能用
  png/planned/    待實現畫面的 PNG
  svg/existing/   已完成的 50 個畫面：所有頁面、彈窗、選單、空狀態（390 × 844；發布、委託表單、個人檔案分頁是捲動後的全長，所以比較高）
  svg/planned/    待實現的 12 個畫面（760 × 844：左邊手機畫面、右邊規格）
  gallery.html    總覽頁，可寄給組員
  build/          產生器（Python），改了再重跑：python3 design/build/build.py，再 python3 design/build/export_png.py（需要 Mac 的 Google Chrome）更新 PNG
```

## 給設計組：最快的用法

1. 到 GitHub 專案（`design/png/` 資料夾）下載圖片，或整個專案 Download ZIP。
2. 把 `design/png/existing/` 整個資料夾的圖拖進 Figma 畫布，每張會變成一個圖片。
3. PNG 只是參考圖（不能改文字）。要重新設計、要可編輯的圖層，用下面的 SVG 匯入。
4. 每張圖的檔名編號是頁面順序；`P` 開頭是還沒做的功能，右邊那欄是規格。

## 匯入 Figma（可編輯的 SVG 版）

1. 先安裝字型 **Noto Sans TC**（Google Fonts），不然 Figma 會換字，文字寬度會跑掉。
2. 把 `svg/existing/` 或 `svg/planned/` 的檔案整批拖進 Figma 畫布。
3. 每個 SVG 會變成一個 Frame，文字、色塊、圓角、遮罩都是可編輯的圖層。
4. 圖層名稱有 `background`、`bottom-nav`、`publish-pill` 可以直接找到導覽列。
5. 重複的元件（貼文卡片、按鈕、標籤、分段切換）建議在 Figma 轉成 Component，之後美術改一次全部跟著改。
6. 待實現的畫面右側規格面板是給組員看的；實際設計時刪掉，只留左邊手機畫面。

## 設計變數（對應 `lib/theme/app_theme.dart`）

| 名稱 | 色碼 | 用途 |
| --- | --- | --- |
| vermilion 朱紅 | `#C9402F` | 主色、按鈕、強調 |
| ink 墨 | `#221E1B` | 文字 |
| paper 宣紙 | `#F8F4EE` | 頁面底色 |
| line | `#E9E1D6` | 分隔線、卡片外框 |
| muted | `#8A8178` | 次要文字 |
| tint | `#F3E9DD` | 標籤、輸入底色 |
| container | `#F8DDD6` | 淺朱紅（選中、頭像底） |
| green | `#3F7D5B` | 「接單展示」標籤 |

圓角：卡片 20～24、輸入框 14、按鈕 14、標籤與膠囊 全圓。字級：頁面標題 20、卡片標題 17、內文 14、說明 12～13。底部導覽高 64，「發布」是置中的紅色膠囊。

## 注意

- 作品圖用漸層色塊代替，實際是使用者上傳的圖片。
- 看板娘只是示意（圓臉＋紅貝雷帽），正式造型由美術組設計。
- 不放 icon 是刻意的（目前版本全用文字）；要加 icon 的話請美術統一一套。
