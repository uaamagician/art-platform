# 本機 Firebase 模擬器工具

不用碰共用資料庫就能測規則和跑整套流程。需要 Java 21、Node 20+、Firebase CLI。

```bash
cd tool/emulator
npm install
```

## 1. 測 Firestore／Storage 安全規則（約 150 項）

```bash
npm run rules-test
```

## 2. 在 Android 模擬器上跑整合測試

開三個終端機（或背景執行）：

```bash
npm run start          # 先同步規則檔，再啟動 Auth / Firestore / Storage 模擬器
./reset.sh             # 清空並塞入測試資料（Alice、Bob、Carol 與貼文、委託、群組…），每次重跑測試前都要做
cd ../.. && flutter test integration_test/app_flow_test.dart -d <Android 模擬器代號>
```

測試帳號密碼都是 `password`：`alice@test.com`、`bob@test.com`、`carol@test.com`。
Android 模擬器用 `10.0.2.2` 連到你電腦；debug 版已經允許 http 連線（`android/app/src/debug/AndroidManifest.xml`）。
