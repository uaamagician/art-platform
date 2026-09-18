# Art Platform 
仲辰的貼心提醒
這次專案打算做的是一個美術平台能丟自己作品上去並透過討論區和評價以及個人喜好做推算篩選 還會多開一些部分給區域的聊天或是私人的討論區像是美術課作業上傳地方
現在仍缺許多 分工的部分看要怎麼分配 介面設計的部分可能就要先麻煩冠呈跟喬琳 可能看用Figma之類的工具用上傳頁面、瀏覽頁面、留言區、聊天室的部分畫面  程式的部分我個人因為Firebase跟登入都我架的，我可以用部分「圖片上傳 + 分類 + 標籤」

我想分一個大的標題是美術種類（素描、油畫、電繪）然後再分小標（＃我推的孩子 ＃有馬佳奈 等等） 然後下面可評價 留言等等  搜索設定（關聯性、評價）

另外有人要負責聊天室/私訊：這塊可以獨立開發晚點再加入就好
評分 + 搜尋篩選可能也一個人用這比較快


大概這樣吧其實我也還沒做尚未確定好要怎麼分
如果有任何意見或是不想做這個或是不會用可以再跟我講
真要改也能即時改
也可以帶電腦去學餐搞

下面給一下設定教學
## 環境需求

在開始之前，請先在自己的電腦上安裝好：

- Flutter SDK(https://docs.flutter.dev/get-started/install)
- 若要測試 iOS：需要 Mac + Xcode
- 若要測試 Android：需要 Android Studio（要有 Android SDK） (https://developer.android.com/studio)

安裝完成後確認下環境沒問題就能pull了：


按下鍵盤 Win + R，輸入 powershell 並按 Enter。
貼上執行：

```bash
flutter doctor
```
只要都有打勾就可以了


## 取得專案

# 1. 自動前往桌面如果你要自己改地方也可以
```bash
cd "$env:USERPROFILE\Desktop"
```


# 2. 下載專案到桌面
```bash
git clone https://github.com/uaamagician/art-platform.git
```

# 3. 進入專案下載
```bash
cd art-platform
flutter pub get
```
第三步：開啟專案（二選一）
看你習慣用哪個編譯器
VS Code：
打開 VS Code，點選左上角 File → Open Folder...
選 art-platform 就好
Android Studio：
打開 Android Studio，點選 Open
選桌面上的 art-platform 資料夾


```bash
git clone https://github.com/uaamagician/art-platform.git
cd art-platform
flutter pub get
```

## 資料庫（Firebase）

這專案都用我 Firebase（Authentication、Firestore、Storage），設定檔在專案裡（`firebase_options.dart`、`google-services.json`、`GoogleService-Info.plist`），**不需要另外申請或設定資料庫**，`git clone` 下來就行。

## 執行專案

如果用安著的人直接接手機（沒有的用android studio就能開模擬器/emulator   ），執行：

```bash
flutter run
```

若同時偵測到多台裝置，可以加上 `-d` 指定裝置：

```bash
flutter devices        # 查看裝置代號
flutter run -d <裝置代號>
```

## 如果要測試 Google 登入（only安著）

Google 登入會檢查你電腦上簽章憑證的指紋（SHA-1），**每台電腦產生的憑證都不一樣**，所以第一次在自己的電腦上測試 Android 版本時，需要用點東東

1. 先生一次簽章憑證：
```bash
   flutter build apk --debug
```
2. 拿 SHA-1 指紋：
```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```
3. 把印出來的 **SHA-1** 給我就能把你加到 Firebase Console裡面再執行 `flutter run` 才可用 Google 登入

> 現在只影響自己電腦上用 debug 模式測試，之後 App 正式發布給一般使用者無關

## 如果要測試 iOS 版

再說應該沒人有mac吧 如果要用iphone測試的可以用我電腦我可以帶過去

## 專案結構
