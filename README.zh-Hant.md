# 台語辭典

<img src="assets/site/taigi_dict_banner.png" alt="台語辭典 Taigi Dict banner" width="360" />

[![Download on the App Store](https://img.shields.io/badge/Download_on_the-App_Store-0D96F6?style=for-the-badge&logo=appstore&logoColor=white)](https://apps.apple.com/tw/app/%E5%8F%B0%E8%AA%9E%E8%BE%AD%E5%85%B8/id6763974066)
[![Get it on Google Play](https://img.shields.io/badge/Get_it_on-Google_Play-34A853?style=for-the-badge&logo=googleplay&logoColor=white)](https://play.google.com/store/apps/details?id=org.taigidict.app)
[![Download APK](https://img.shields.io/github/v/release/PhoenixEmik/taigi-dict?label=Download%20APK&style=for-the-badge&color=3DDC84&logo=android&logoColor=white)](https://github.com/PhoenixEmik/taigi-dict/releases/latest)

![Swift](https://img.shields.io/badge/Swift-F05138?style=flat&logo=swift&logoColor=white)
![Kotlin](https://img.shields.io/badge/Kotlin-7F52FF?style=flat&logo=kotlin&logoColor=white)
![iOS 17+](https://img.shields.io/badge/iOS-17%2B-000000?style=flat&logo=apple&logoColor=white)
![macOS 14+](https://img.shields.io/badge/macOS-14%2B-000000?style=flat&logo=apple&logoColor=white)
![Android 7+](https://img.shields.io/badge/Android-7%2B-3DDC84?style=flat&logo=android&logoColor=white)
![License MIT](https://img.shields.io/badge/License-MIT-5E5E5E?style=flat)

[English README](README.md)

這個專案以教育部辭典資料為核心，提供台語 / 華語離線辭典體驗。

## 快速連結

- [iOS 與 macOS app](ios-native/) 與 [Apple 平台說明](ios-native/README.md)
- [Android app](android-native/) 與 [Android 說明](android-native/README.md)
- [隱私權政策](PRIVACY_POLICY.md)、[資料授權](DATA_LICENSE.md) 與 [MIT 授權](LICENSE)

目前這個 repository 包含台語辭典的原生實作與共用工具：

- [ios-native/](ios-native/) 內的原生 Swift / SwiftUI app，作為目前 iOS 與 macOS 的主要開發目標
- [android-native/](android-native/) 內的原生 Kotlin / Jetpack Compose app，作為目前 Android 的主要開發目標

目前兩個原生 app 都圍繞同一組產品能力：離線查詢、可下載音檔、書籤、本地化介面，以及台羅 / 漢字參考資料。

## 目前狀態

- Android：由 [android-native/](android-native/) 原生重寫維護
- iOS 與 macOS：由 [ios-native/](ios-native/) 與 [TaigiDictNative.xcworkspace](ios-native/TaigiDictNative.xcworkspace) 維護

## 核心體驗

產品目前主要由三個分頁構成：

- `辭典`：查詢台語詞目、台羅拼音與華語釋義，保留搜尋紀錄，並可進入詞條詳細頁
- `書籤`：集中查看已收藏詞條，並重新開啟
- `設定`：管理離線資源、外觀、語言、參考資料與 App 資訊

## 專案識別

- App 顯示名稱：`台語辭典`
- Android application ID：`org.taigidict.app`
- iOS 與 macOS bundle identifier：`org.taigidict.app`
- 目前原生 Apple app 版本：`1.3.6`（build `9`）
- 官方網站：[taigidict.org](https://taigidict.org)
- 正式環境資產來源：[app.taigidict.org/assets](https://app.taigidict.org/assets/)

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

- [辭典入口](https://sutian.moe.edu.tw/zh-hant/siongkuantsuguan/)
- [版權與授權說明](https://sutian.moe.edu.tw/zh-hant/piantsip/pankhuan-singbing/)
- [原始試算表](https://sutian.moe.edu.tw/media/senn/ods/kautian.ods)
- [台羅說明](https://sutian.moe.edu.tw/zh-hant/piantsip/tailo-phiautsu-suatbing/)
- [漢字使用說明](https://sutian.moe.edu.tw/zh-hant/piantsip/hanji-iongji-guantsik/)

App 實際使用的正式環境離線資源端點：

- [詞目音檔](https://app.taigidict.org/assets/sutiau-mp3.zip)
- [例句音檔](https://app.taigidict.org/assets/leku-mp3.zip)
- [詞典原始檔](https://app.taigidict.org/assets/kautian.ods)

重要發行說明：

- 上游原始資料授權為 `CC BY-ND 3.0 TW`
- 原生 Android app 使用 [android-native/Generated/Dictionary/](android-native/Generated/Dictionary/) 下的預先生成詞典資料，不會在執行期解析 `kautian.ods`
- 原生 Apple app 使用 [ios-native/Generated/Dictionary/](ios-native/Generated/Dictionary/) 下的預先生成詞典資料，不會在執行期解析 `kautian.ods`

## 技術棧

原生 Android 實作：

- Kotlin 與 Jetpack Compose / Material 3
- AndroidX ViewModel、Kotlin coroutines、Flow / StateFlow
- `Preferences DataStore`：app 設定、書籤與搜尋紀錄，並保留舊偏好設定 migration
- 預設詞典資料層目前仍是自管 SQLite 匯入 / repository，專案內也已包含 Room-backed repository
- `android-opencc`：以 OpenCC 進行繁簡轉換

原生 Apple 實作：

- SwiftUI
- 本地 Swift package，拆分為 `TaigiDictCore` 與 `TaigiDictUI`
- `GRDB.swift`：SQLite 存取
- `SwiftyOpenCC`：繁簡轉換
- `ZIPFoundation`：離線壓縮資源處理

## 專案結構

- [android-native/](android-native/)：原生 Kotlin / Jetpack Compose Android app
- [android-native/Generated/Dictionary/](android-native/Generated/Dictionary/)：原生 Android app 內建的預先生成詞典資料包
- [ios-native/](ios-native/)：原生 Swift / SwiftUI iOS 與 macOS app、本地 Swift package 與測試
- [ios-native/Generated/Dictionary/](ios-native/Generated/Dictionary/)：原生 Apple app 內建的預先生成詞典資料包
- [data/source/kautian.ods](data/source/kautian.ods)：目前詞典轉換流程共用的原始來源檔
- [tool/build_dictionary_asset.py](tool/build_dictionary_asset.py)：目前原生流程仍共用的詞典轉換腳本
- [ios-native/NativeApp/](ios-native/NativeApp/)：原生 iOS 與 macOS app 入口、本地化 bundle 中繼資料與 asset catalog
- [ios-native/Sources/TaigiDictCore/](ios-native/Sources/TaigiDictCore/)：詞典、音訊、書籤與轉換等共享邏輯
- [ios-native/Sources/TaigiDictUI/](ios-native/Sources/TaigiDictUI/)：辭典、書籤、設定與資訊頁的 SwiftUI 畫面

## 執行

原生 iOS app：

- 在 Xcode 開啟 [ios-native/TaigiDictNative.xcworkspace](ios-native/TaigiDictNative.xcworkspace)
- 選擇 `TaigiDictNative` scheme
- 在 iOS 17 模擬器或實機上建置並執行

原生 iOS 命令列建置：

```bash
xcodebuild \
  -workspace ios-native/TaigiDictNative.xcworkspace \
  -scheme TaigiDictNative \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  build
```

更多 Apple 平台細節可參考 [`ios-native/README.md`](ios-native/README.md)。

原生 macOS app：

- 在 Xcode 開啟 [ios-native/TaigiDictNative.xcworkspace](ios-native/TaigiDictNative.xcworkspace)
- 選擇 `TaigiDictNativeMac` scheme
- 在 macOS 14 以上版本建置並執行

原生 macOS 命令列建置：

```bash
xcodebuild \
  -workspace ios-native/TaigiDictNative.xcworkspace \
  -scheme TaigiDictNativeMac \
  -destination 'platform=macOS' \
  build
```

原生 Android app：

```bash
cd android-native
./gradlew app:assembleDebug
```

更多原生 Android 細節可參考 [android-native/README.md](android-native/README.md)。

## 驗證

原生 Apple package 與共享邏輯：

```bash
swift test --package-path ios-native
```

原生 iOS app 建置驗證：

```bash
xcodebuild \
  -workspace ios-native/TaigiDictNative.xcworkspace \
  -scheme TaigiDictNative \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  build
```

原生 macOS app 建置驗證：

```bash
xcodebuild \
  -workspace ios-native/TaigiDictNative.xcworkspace \
  -scheme TaigiDictNativeMac \
  -destination 'platform=macOS' \
  build
```

原生 Android app：

```bash
cd android-native
./gradlew testDebugUnitTest
./gradlew app:assembleDebugAndroidTest
```

可選的 Android Room-backed 驗證：

```bash
cd android-native
./gradlew verifyRoomDebug
```

## 開發注意事項

- 目前 Apple 平台正式開發工作在 [ios-native/](ios-native/)
- 目前 Android 正式開發工作在 [android-native/](android-native/)
- 共用詞典來源資料維持在 [data/source/](data/source/)
- 生成後的詞典資產應透過 [tool/build_dictionary_asset.py](tool/build_dictionary_asset.py) 重建，不要手動修改

## 建置 Release APK

```bash
cd android-native
./gradlew :app:assembleRelease
```

產物位置：

- `android-native/app/build/outputs/apk/release/app-release.apk`

## 隱私權政策

- 中英雙語：[PRIVACY_POLICY.md](PRIVACY_POLICY.md)

## 致謝

- [教育部臺灣台語常用詞辭典](https://sutian.moe.edu.tw/)：詞典資料來源參考
- [豆腐烏 Tauhu-oo 20.05](https://github.com/tauhu-tw/tauhu-oo)：用於顯示台語漢字與特定 CJK Extension 字元的字型
- [jf open 粉圓](https://github.com/justfont/open-huninn-font)：用於 App Icon 字樣的字型
- [android-opencc](https://github.com/xyrlsz/android-opencc)：原生 Android app 的 OpenCC 繁簡轉換
- [GRDB.swift](https://github.com/groue/GRDB.swift)：原生 Apple app 的 SQLite 存取
- [ZIPFoundation](https://github.com/weichsel/ZIPFoundation)：原生 Apple app 的離線壓縮資源處理
- [SwiftyOpenCC](https://github.com/PhoenixEmik/SwiftyOpenCC)：原生 Apple app 的繁簡轉換

## 授權

- App 程式碼：MIT，請見 [LICENSE](LICENSE)
- 詞典資料：`CC BY-ND 3.0 TW`，請見 [DATA_LICENSE.md](DATA_LICENSE.md)
- 詞典音檔：`CC BY-ND 3.0 TW`，請見 [DATA_LICENSE.md](DATA_LICENSE.md)
- [教育部版權說明](https://sutian.moe.edu.tw/zh-hant/piantsip/pankhuan-singbing/)
