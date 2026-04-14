# 台語辭典

[![Download APK](https://img.shields.io/github/v/release/PhoenixEmik/taigi-dict?label=Download%20APK&color=success&logo=android)](https://github.com/PhoenixEmik/taigi-dict/releases/latest)

[English README](README.md)

這是一個支援 Android 與 iOS 的 Flutter 台語 / 華語辭典 App。
專案以教育部辭典資料為核心，支援離線查詢，並將大型離線資源直接下載到使用者裝置上。

## 專案識別

- Dart package name：`taigi_dict`
- App 顯示名稱：`台語辭典`
- Android application ID：`org.taigidict.app`
- iOS bundle identifier：`org.taigidict.app`
- 官方網站：`https://taigidict.org`
- 正式環境資產來源：`https://app.taigidict.org/assets/`

## 目前功能

- 支援台語詞目、台羅拼音、華語釋義的離線查詢
- 支援加權搜尋排序，並可選擇使用 background isolate 執行搜尋
- 提供書籤頁面保存詞條
- 使用 `shared_preferences` 儲存搜尋紀錄
- 提供獨立的詞條詳細頁與原生分享功能
- 支援在釋義中點擊關聯詞並直接開啟對應詞條
- 支援詞目音檔與例句音檔的離線下載
- 透過 `dio` 與 HTTP range requests 支援大型 ZIP 的暫停、續傳與斷點續傳
- 支援下載離線詞典原始檔 `kautian.ods`
- 使用 `spreadsheet_decoder` 與 `sqflite` 在裝置上把 ODS 建成 SQLite 詞典資料庫
- 提供正體中文、簡體中文與英文介面
- 使用原生 OpenCC 引擎做執行期繁簡轉換，並套用台灣詞彙轉換設定
- 已補強語意標籤、複合設定列 merged semantics 與本地化 tooltip 的無障礙支援
- 採用平台自適應 UI：Android 維持品牌化 Material 風格，iOS 使用 Cupertino 導覽與跨平台自適應元件
- 支援閱讀字級調整，以及系統感知的淺色 / 深色 / AMOLED 主題
- 內建 `TauhuOo` fallback font，用於補足系統字型缺少的 CJK Ext-C / D / E 字元

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

- 因為上游原始資料授權為 `CC BY-ND 3.0 TW`，App 不會直接內建轉換好的 SQLite 資料庫。
- App 會先下載原始 `kautian.ods`，再於使用者裝置上建立本機 SQLite 資料庫。
- 執行期載入詞典時，會優先使用 app support 目錄中的本機 SQLite 資料庫；舊版內建 dictionary asset 已不再用於正式執行流程。

## 技術棧

- Flutter
- `dio`：可續傳下載
- `just_audio`：離線音訊播放
- `flutter_open_chinese_convert`：執行期 OpenCC 繁簡轉換
- `adaptive_platform_ui`：跨平台 Material/Cupertino 自適應元件
- `path`、`path_provider`：本機檔案管理
- `shared_preferences`：使用者設定、書籤與搜尋紀錄
- `share_plus`：原生分享
- `spreadsheet_decoder`：解析 `kautian.ods`
- `sqflite`：本機 SQLite 詞典資料庫

## 專案結構

- `lib/main.dart`：App 進入點
- `lib/app/`：App shell、導覽與主題初始化
- `lib/core/`：常數、本地化、翻譯與共享偏好設定
- `lib/features/dictionary/`：詞典模型、搜尋、SQLite 建置 / 載入與 UI
- `lib/features/audio/`：離線音檔下載、索引與播放
- `lib/features/bookmarks/`：書籤持久化與畫面
- `lib/features/settings/`：設定 UI、離線資源控制與本地化參考文章
- `lib/features/settings/presentation/content/reference_articles.dart`：台羅與漢字說明文章內容
- `tool/build_dictionary_asset.py`：保留作為參考的 Python 轉換腳本，對照 Dart 端 ODS 到 SQLite 的映射邏輯

## 執行

```bash
flutter pub get
flutter run
```

## 驗證

```bash
flutter analyze
flutter test
```

## iOS 設定

iOS 專案目前設定為：

- deployment target：`iOS 13.0`
- App metadata 已本地化：`zh-Hant`、`zh-Hans`、`en`
- 使用 Cupertino 導覽與 `adaptive_platform_ui` 建立 iOS 自適應界面

當依賴或 Pods 更新後：

```bash
flutter pub get
cd ios
pod install
cd ..
```

## 建置 Release APK

```bash
flutter build apk --release
```

產物位置：

- `build/app/outputs/flutter-apk/app-release.apk`

## UI 說明

- iOS 使用自適應的 Cupertino 導覽，以及平台感知的導覽列、搜尋列與設定區塊元件。
- Android 不會沿用 iOS palette，而是維持較溫暖的品牌化 Material 風格，以保留平台適配性。

## 致謝

- 教育部臺灣台語常用詞辭典：`https://sutian.moe.edu.tw/`
- Tauhu-oo（豆腐烏）20.05 字型，用於顯示台語漢字與特定 CJK Extension 字元：`https://github.com/tauhu-tw/tauhu-oo`
- jf open-huninn（jf open 粉圓）字型，用於 App Icon 字樣：`https://github.com/justfont/open-huninn-font`
- adaptive_platform_ui，提供 Material/Cupertino 自適應介面元件：`https://github.com/berkaycatak/adaptive_platform_ui`
- Open Chinese Convert for Flutter，提供執行期 OpenCC 繁簡轉換：`https://github.com/zonble/flutter_open_chinese_convert`

## 授權

- App 程式碼：MIT，請見 `LICENSE`
- 詞典資料：`CC BY-ND 3.0 TW`，請見 `DATA_LICENSE.md`
- 詞典音檔：`CC BY-ND 3.0 TW`，請見 `DATA_LICENSE.md`
- 教育部版權說明：`https://sutian.moe.edu.tw/zh-hant/piantsip/pankhuan-singbing/`
