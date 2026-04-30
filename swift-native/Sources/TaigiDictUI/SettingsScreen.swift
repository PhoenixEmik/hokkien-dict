import SwiftUI
import TaigiDictCore

public struct SettingsScreen: View {
    @State private var viewModel: SettingsViewModel
    private let onMaintenanceCompleted: () -> Void
    private let onSettingsChanged: (AppSettingsSnapshot) -> Void

    public init(
        library: DictionaryLibrary,
        settingsStore: any AppSettingsStoring = UserDefaultsAppSettingsStore(),
        onMaintenanceCompleted: @escaping () -> Void = {},
        onSettingsChanged: @escaping (AppSettingsSnapshot) -> Void = { _ in }
    ) {
        _viewModel = State(
            initialValue: SettingsViewModel(
                library: library,
                settingsStore: settingsStore
            )
        )
        self.onMaintenanceCompleted = onMaintenanceCompleted
        self.onSettingsChanged = onSettingsChanged
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("顯示與語言") {
                    Picker("介面語言", selection: Binding(
                        get: { viewModel.selectedLocale },
                        set: { locale in
                            Task {
                                await viewModel.setLocale(locale)
                                onSettingsChanged(viewModel.currentSettingsSnapshot)
                            }
                        }
                    )) {
                        ForEach(AppLocale.allCases, id: \.self) { locale in
                            Text(locale.displayName)
                                .tag(locale)
                        }
                    }

                    Picker("主題", selection: Binding(
                        get: { viewModel.selectedThemePreference },
                        set: { preference in
                            Task {
                                await viewModel.setThemePreference(preference)
                                onSettingsChanged(viewModel.currentSettingsSnapshot)
                            }
                        }
                    )) {
                        ForEach(AppThemePreference.allCases, id: \.self) { preference in
                            Text(preference.displayName)
                                .tag(preference)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        LabeledContent("閱讀字級") {
                            Text(viewModel.readingTextScale.displayScaleLabel)
                                .monospacedDigit()
                        }

                        Slider(
                            value: Binding(
                                get: { viewModel.readingTextScale },
                                set: { value in
                                    Task {
                                        await viewModel.setReadingTextScale(value)
                                        onSettingsChanged(viewModel.currentSettingsSnapshot)
                                    }
                                }
                            ),
                            in: viewModel.minReadingTextScale...viewModel.maxReadingTextScale,
                            step: (viewModel.maxReadingTextScale - viewModel.minReadingTextScale) / Double(viewModel.readingTextScaleDivisions)
                        )
                    }
                }

                Section("資料與說明") {
                    NavigationLink {
                        AdvancedSettingsScreen(viewModel: viewModel) {
                            onMaintenanceCompleted()
                        }
                    } label: {
                        Label("進階設定", systemImage: "wrench.and.screwdriver")
                    }

                    NavigationLink {
                        AboutScreen()
                    } label: {
                        Label("關於", systemImage: "info.circle")
                    }

                    NavigationLink {
                        LicenseSummaryScreen()
                    } label: {
                        Label("授權資訊", systemImage: "doc.text")
                    }

                    NavigationLink {
                        ReferenceArticleListScreen()
                    } label: {
                        Label("參考資料", systemImage: "text.book.closed")
                    }
                }
            }
            .navigationTitle("設定")
        }
        .task {
            await viewModel.loadCapabilities()
            onSettingsChanged(viewModel.currentSettingsSnapshot)
        }
        .confirmationDialog(
            "確定要清除本機辭典資料？",
            isPresented: Binding(
                get: { viewModel.isClearConfirmationPresented },
                set: { isPresented in
                    if !isPresented {
                        viewModel.cancelClearConfirmation()
                    }
                }
            ),
            titleVisibility: .visible
        ) {
            Button("清除", role: .destructive) {
                Task {
                    if await viewModel.confirmClear() {
                        onMaintenanceCompleted()
                    }
                }
            }
            Button("取消", role: .cancel) {
                viewModel.cancelClearConfirmation()
            }
        } message: {
            Text("清除後會移除本機資料，下次使用前會重新初始化。")
        }
    }
}

private extension AppLocale {
    var displayName: String {
        switch self {
        case .traditionalChinese:
            return "正體中文"
        case .simplifiedChinese:
            return "简体中文"
        case .english:
            return "English"
        }
    }
}

private extension AppThemePreference {
    var displayName: String {
        switch self {
        case .system:
            return "跟隨系統"
        case .light:
            return "淺色"
        case .dark:
            return "深色"
        case .amoled:
            return "AMOLED"
        }
    }
}

private extension Double {
    var displayScaleLabel: String {
        String(format: "%.2fx", self)
    }
}
