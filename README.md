# Art Platform 
仲辰的貼心提醒

## 環境需求

在開始之前，請先在自己的電腦上安裝好：

- Flutter SDK(https://docs.flutter.dev/get-started/install)
- 若要測試 iOS：需要 Mac + Xcode
- 若要測試 Android：需要 Android Studio（要有 Android SDK）

安裝完成後確認下環境沒問題就能pull了：

```bash
flutter doctor
```

## 取得專案

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
