# 台語辭典

[![Download APK](https://img.shields.io/github/v/release/PhoenixEmik/taigi-dict?label=Download%20APK&color=success&logo=android)](https://github.com/PhoenixEmik/taigi-dict/releases/latest)

[English README](README.md)

這是一個支援 Android 與 iOS 的 Flutter 台語 / 華語辭典 App。
專案以教育部辭典資料為核心，支援離線查詢，並將大型離線資源直接下載到使用者裝置上。

## 核心體驗

App 目前主要由三個分頁構成：

- `辭典`：查詢台語詞目、台羅拼音與華語釋義，保留搜尋紀錄，並可進入詞條詳細頁
- `書籤`：集中查看已收藏詞條，並以相同的詳細頁體驗重新開啟
- `設定`：管理離線資源、外觀、語言、參考資料與 App 資訊

首次使用流程也屬於 App 體驗的一部分。App 可以先下載教育部 ODS
原始檔，在裝置上建立本機 SQLite 詞典資料庫，之後再以該資料庫提供離線查詢。

## 專案識別

- Dart package name：`taigi_dict`
- App 顯示名稱：`台語辭典`
- Android application ID：`org.taigidict.app`
- iOS bundle identifier：`org.taigidict.app`
- 官方網站：`https://taigidict.org`
- 正式環境資產來源：`https://app.taigidict.org/assets/`

## 功能

- 支援台語詞目、台羅拼音、華語釋義查詢，並保留搜尋紀錄
- 提供加權搜尋排序、詞條詳細頁、釋義內關聯詞跳轉與原生分享
- 提供書籤分頁集中保存與重開詞條
- 支援詞目音檔與例句音檔的離線下載與播放
- 支援下載 `kautian.ods`，並在裝置上建立本機 SQLite 詞典資料庫
- 提供正體中文、簡體中文、英文介面，以及字級與主題切換
- 內建台羅與漢字說明文章，以及關於與授權頁面
- 採用平台自適應 UI，並補強語意標籤、本地化 tooltip 與其他無障礙細節

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
- `lib/app/initialization/`：首次下載與詞典建庫的啟動流程
- `lib/app/shell/`：三分頁主畫面結構
- `lib/core/`：常數、本地化、翻譯與共享偏好設定
- `lib/features/dictionary/`：詞典模型、搜尋、SQLite 建置 / 載入與 UI
- `lib/features/audio/`：離線音檔下載、索引與播放
- `lib/features/bookmarks/`：書籤持久化與畫面
- `lib/features/settings/`：設定 UI、離線資源控制與本地化參考文章
- `lib/features/settings/presentation/content/reference_articles.dart`：台羅與漢字說明文章內容
- `tool/build_dictionary_asset.py`：保留作為參考的 Python 轉換腳本，對照 Dart 端 ODS 到 SQLite 的映射邏輯

## 離線資源流程

- App 不會直接內建預先建好的 SQLite 詞典資料庫
- App 會先下載原始 `kautian.ods`，再於裝置端建立本機詞典資料庫
- 詞典音檔與例句音檔則分別以 ZIP 離線資源管理
- 設定頁提供重新下載離線資源與重建本機詞典資料庫的維護操作

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

## 開發注意事項

- `pubspec.yaml` 目前以 `dependency_overrides` 固定 `path_provider_foundation: 2.6.0`
- 除非你已經針對目前 iOS 專案與 plugin 組合驗證過新的依賴解析結果，否則不要直接移除這個 override
- 本專案的 `spreadsheet_decoder` 來自 git dependency，因此依賴解析不完全只由 pub.dev 決定

## 建置 Release APK

```bash
flutter build apk --release
```

產物位置：

- `build/app/outputs/flutter-apk/app-release.apk`

## 致謝

- 教育部臺灣台語常用詞辭典：`https://sutian.moe.edu.tw/`
- Tauhu-oo（豆腐烏）20.05 字型，用於顯示台語漢字與特定 CJK Extension 字元：`https://github.com/tauhu-tw/tauhu-oo`
- jf open-huninn（jf open 粉圓）字型，用於 App Icon 字樣：`https://github.com/justfont/open-huninn-font`
- Adaptive Platform UI，提供 Material/Cupertino 自適應介面元件：`https://github.com/berkaycatak/adaptive_platform_ui`
- Open Chinese Convert for Flutter，提供執行期 OpenCC 繁簡轉換：`https://github.com/zonble/flutter_open_chinese_convert`

## 授權

- App 程式碼：MIT，請見 `LICENSE`
- 詞典資料：`CC BY-ND 3.0 TW`，請見 `DATA_LICENSE.md`
- 詞典音檔：`CC BY-ND 3.0 TW`，請見 `DATA_LICENSE.md`
- 教育部版權說明：`https://sutian.moe.edu.tw/zh-hant/piantsip/pankhuan-singbing/`
