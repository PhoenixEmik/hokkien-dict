# 台語辭典

<img src="assets/icon/taigi_dict.png" alt="台語辭典 App Icon" width="120" />

[![Download APK](https://img.shields.io/github/v/release/PhoenixEmik/taigi-dict?label=Download%20APK&color=success&logo=android)](https://github.com/PhoenixEmik/taigi-dict/releases/latest)

[English README](README.md)

這個專案以教育部辭典資料為核心，提供台語 / 華語離線辭典體驗。

目前這個 repository 同時包含兩條實作線：

- 根目錄 Flutter app，主要負責 Android 與既有跨平台程式碼
- `ios-native/` 內的原生 Swift / SwiftUI app，作為目前 iOS 的主要開發目標

兩個 app 都圍繞同一組產品能力：離線查詢、可下載音檔、書籤、本地化介面，以及台羅 / 漢字參考資料。

## 目前狀態

- Android：由根目錄 Flutter 專案維護
- iOS：由 `ios-native/` 與 `TaigiDictNative.xcworkspace` 維護
- 舊版 Flutter iOS host：仍保留在 `ios/`，但已不是主要 iOS app 目標

## 核心體驗

產品目前主要由三個分頁構成：

- `辭典`：查詢台語詞目、台羅拼音與華語釋義，保留搜尋紀錄，並可進入詞條詳細頁
- `書籤`：集中查看已收藏詞條，並重新開啟
- `設定`：管理離線資源、外觀、語言、參考資料與 App 資訊

## 專案識別

- Dart package name：`taigi_dict`
- App 顯示名稱：`台語辭典`
- Android application ID：`org.taigidict.app`
- iOS bundle identifier：`org.taigidict.app`
- 目前 Flutter app 版本：`1.3.0+3`
- 官方網站：`https://taigidict.org`
- 正式環境資產來源：`https://app.taigidict.org/assets/`

## 功能

- 支援台語詞目、台羅拼音、華語釋義查詢，並保留搜尋紀錄
- 提供加權搜尋排序、詞條詳細頁、釋義內關聯詞跳轉與原生分享
- 提供書籤分頁集中保存與重開詞條
- 支援詞目音檔與例句音檔的離線下載與播放
- 提供正體中文、簡體中文、英文介面
- 提供主題與字級調整
- 內建台羅與漢字說明文章，以及關於與授權頁面

## 資料與授權

教育部官方參考來源：

- 辭典入口：`https://sutian.moe.edu.tw/zh-hant/siongkuantsuguan/`
- 版權與授權說明：`https://sutian.moe.edu.tw/zh-hant/piantsip/pankhuan-singbing/`
- 原始試算表：`https://sutian.moe.edu.tw/media/senn/ods/kautian.ods`
- 台羅說明：`https://sutian.moe.edu.tw/zh-hant/piantsip/tailo-phiautsu-suatbing/`
- 漢字使用說明：`https://sutian.moe.edu.tw/zh-hant/piantsip/hanji-iongji-guantsik/`

App 實際使用的正式環境離線資源端點：

- 詞目音檔：`https://app.taigidict.org/assets/sutiau-mp3.zip`
- 例句音檔：`https://app.taigidict.org/assets/leku-mp3.zip`
- 詞典原始檔：`https://app.taigidict.org/assets/kautian.ods`

重要發行說明：

- 上游原始資料授權為 `CC BY-ND 3.0 TW`
- Android Flutter app 會內建原始 `kautian.ods`，再於裝置上建立本機 SQLite 詞典資料庫
- 原生 iOS app 使用 `ios-native/Generated/Dictionary/` 下的預先生成詞典資料，不會在執行期解析 `kautian.ods`

## 技術棧

Flutter / Android 實作：

- Flutter 與 Material 3
- `dio`：可續傳下載
- `just_audio`：離線音訊播放
- `flutter_open_chinese_convert`：執行期 OpenCC 繁簡轉換
- `shared_preferences`：使用者設定、書籤與搜尋紀錄
- `spreadsheet_decoder`：解析 `kautian.ods`
- `sqflite`：本機 SQLite 詞典資料庫

原生 iOS 實作：

- SwiftUI
- `GRDB.swift`：SQLite 存取
- `SwiftyOpenCC`：繁簡轉換
- `ZIPFoundation`：離線壓縮資源處理

## 專案結構

- `lib/`：Flutter app 程式碼
- `android/`：Flutter Android host 專案
- `ios/`：遷移期間保留的 Flutter iOS host
- `ios-native/`：原生 Swift / SwiftUI iOS app、本地 Swift package 與測試
- `ios-native/Generated/Dictionary/`：原生 iOS app 使用的預先生成詞典資產
- `assets/dictionary/kautian.ods`：Flutter app 使用的內建原始詞典來源
- `tool/build_dictionary_asset.py`：作為 Flutter 端 ODS 映射參考的轉換腳本

## 執行

Android Flutter app：

```bash
flutter pub get
flutter run -d android
```

原生 iOS app：

- 在 Xcode 開啟 `ios-native/TaigiDictNative.xcworkspace`
- 選擇 `TaigiDictNative` scheme
- 在 iOS 17 模擬器或實機上建置並執行

更多原生 iOS 細節可參考 [`ios-native/README.md`](ios-native/README.md)。

## 驗證

Flutter 專案：

```bash
flutter analyze
flutter test
```

原生 iOS package 與共享邏輯：

```bash
swift test --package-path ios-native
```

## 開發注意事項

- 目前 iOS 正式開發工作在 `ios-native/`
- `ios/` 下的 Flutter iOS host 主要為遷移相容性而保留
- `pubspec.yaml` 目前以 `dependency_overrides` 固定 `path_provider_foundation: 2.6.0`
- `spreadsheet_decoder` 來自 git dependency，因此 Flutter 依賴解析不完全只由 pub.dev 決定

## 建置 Release APK

```bash
flutter build apk --release
```

產物位置：

- `build/app/outputs/flutter-apk/app-release.apk`

## 隱私權政策

- 中英雙語：`PRIVACY_POLICY.md`

## 致謝

- 教育部臺灣台語常用詞辭典：`https://sutian.moe.edu.tw/`
- 豆腐烏 Tauhu-oo 20.05 字型，用於顯示台語漢字與特定 CJK Extension 字元：`https://github.com/tauhu-tw/tauhu-oo`
- jf open 粉圓字型，用於 App Icon 字樣：`https://github.com/justfont/open-huninn-font`
- Open Chinese Convert for Flutter，提供執行期 OpenCC 繁簡轉換：`https://github.com/zonble/flutter_open_chinese_convert`
- GRDB.swift：`https://github.com/groue/GRDB.swift`
- ZIPFoundation：`https://github.com/weichsel/ZIPFoundation`
- SwiftyOpenCC：`https://github.com/PhoenixEmik/SwiftyOpenCC`

## 授權

- App 程式碼：MIT，請見 `LICENSE`
- 詞典資料：`CC BY-ND 3.0 TW`，請見 `DATA_LICENSE.md`
- 詞典音檔：`CC BY-ND 3.0 TW`，請見 `DATA_LICENSE.md`
- 教育部版權說明：`https://sutian.moe.edu.tw/zh-hant/piantsip/pankhuan-singbing/`
