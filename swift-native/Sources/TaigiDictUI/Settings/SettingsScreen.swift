import SwiftUI
import TaigiDictCore

public struct SettingsScreen: View {
    @State private var viewModel: SettingsViewModel
    @Environment(\.locale) private var locale
    private let onMaintenanceCompleted: () -> Void
    private let onSettingsChanged: (AppSettingsSnapshot) -> Void

    public init(
        library: DictionaryLibrary,
        settingsStore: any AppSettingsStoring = UserDefaultsAppSettingsStore(),
        dictionarySourceStore: (any DictionarySourceResourceManaging)? = nil,
        offlineAudioStore: (any OfflineAudioManaging)? = nil,
        initialSettings: AppSettingsSnapshot = AppSettingsSnapshot(),
        onMaintenanceCompleted: @escaping () -> Void = {},
        onSettingsChanged: @escaping (AppSettingsSnapshot) -> Void = { _ in }
    ) {
        _viewModel = State(
            initialValue: SettingsViewModel(
                library: library,
                settingsStore: settingsStore,
                dictionarySourceStore: dictionarySourceStore,
                offlineAudioStore: offlineAudioStore,
                initialSettings: initialSettings
            )
        )
        self.onMaintenanceCompleted = onMaintenanceCompleted
        self.onSettingsChanged = onSettingsChanged
    }

    public var body: some View {
        let appLocale = AppLocalizer.appLocale(from: locale)
        NavigationStack {
            Form {
                Section(AppLocalizer.text(.settingsDisplayLanguageSection, locale: appLocale)) {
                    Picker(AppLocalizer.text(.settingsThemeLabel, locale: appLocale), selection: Binding(
                        get: { viewModel.selectedThemePreference },
                        set: { preference in
                            Task {
                                await viewModel.setThemePreference(preference)
                                onSettingsChanged(viewModel.currentSettingsSnapshot)
                            }
                        }
                    )) {
                        ForEach(AppThemePreference.allCases, id: \.self) { preference in
                            Text(preference.displayName(in: appLocale))
                                .tag(preference)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        LabeledContent(AppLocalizer.text(.settingsReadingTextScaleLabel, locale: appLocale)) {
                            Text(viewModel.readingTextScale.displayScaleLabel(locale: appLocale))
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

                Section(AppLocalizer.text(.settingsDataAndInfoSection, locale: appLocale)) {
                    NavigationLink {
                        AdvancedSettingsScreen(viewModel: viewModel) {
                            onMaintenanceCompleted()
                        }
                    } label: {
                        Label(AppLocalizer.text(.settingsAdvanced, locale: appLocale), systemImage: "wrench.and.screwdriver")
                    }

                    NavigationLink {
                        AboutScreen()
                    } label: {
                        Label(AppLocalizer.text(.settingsAbout, locale: appLocale), systemImage: "info.circle")
                    }

                    NavigationLink {
                        ReferenceArticleListScreen()
                    } label: {
                        Label(AppLocalizer.text(.settingsReferences, locale: appLocale), systemImage: "text.book.closed")
                    }
                }

                Section(AppLocalizer.text(.settingsOfflineAudioSection, locale: appLocale)) {
                    AudioArchiveResourceRow(
                        title: AppLocalizer.text(.settingsWordAudio, locale: appLocale),
                        locale: appLocale,
                        snapshot: viewModel.snapshot(for: .word),
                        isRunningAction: viewModel.isAudioActionRunning(for: .word)
                    ) { action in
                        Task {
                            await viewModel.runAudioAction(action, for: .word)
                        }
                    }

                    AudioArchiveResourceRow(
                        title: AppLocalizer.text(.settingsSentenceAudio, locale: appLocale),
                        locale: appLocale,
                        snapshot: viewModel.snapshot(for: .sentence),
                        isRunningAction: viewModel.isAudioActionRunning(for: .sentence)
                    ) { action in
                        Task {
                            await viewModel.runAudioAction(action, for: .sentence)
                        }
                    }
                }
            }
            .navigationTitle(AppLocalizer.text(.settingsTitle, locale: appLocale))
        }
        .task {
            await viewModel.loadCapabilities()
            onSettingsChanged(viewModel.currentSettingsSnapshot)
        }
        .onAppear {
            viewModel.startAudioSnapshotPolling()
        }
        .onDisappear {
            viewModel.stopAudioSnapshotPolling()
        }
        .confirmationDialog(
            AppLocalizer.text(.settingsClearConfirmTitle, locale: appLocale),
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
            Button(AppLocalizer.text(.commonDelete, locale: appLocale), role: .destructive) {
                Task {
                    if await viewModel.confirmClear() {
                        onMaintenanceCompleted()
                    }
                }
            }
            Button(AppLocalizer.text(.commonCancel, locale: appLocale), role: .cancel) {
                viewModel.cancelClearConfirmation()
            }
        } message: {
            Text(AppLocalizer.text(.settingsClearConfirmBody, locale: appLocale))
        }
    }
}

private struct AudioArchiveResourceRow: View {
    let title: String
    let locale: AppLocale
    let snapshot: DownloadSnapshot
    let isRunningAction: Bool
    let runAction: (SettingsViewModel.AudioResourceAction) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                    Text(snapshotDescription)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isRunningAction {
                    ProgressView()
                        .controlSize(.small)
                }

                Menu {
                    ForEach(availableActions, id: \.self) { action in
                        Button(action.buttonTitle(locale: locale), systemImage: action.systemImage) {
                            runAction(action)
                        }
                    }
                } label: {
                    Label(AppLocalizer.text(.settingsActionsMenu, locale: locale), systemImage: "ellipsis.circle")
                }
                .disabled(isRunningAction || availableActions.isEmpty)
            }

            if let progress = snapshot.progress {
                ProgressView(value: progress)
            }
        }
        .padding(.vertical, 4)
    }

    private var availableActions: [SettingsViewModel.AudioResourceAction] {
        AudioResourcePresentation.actions(for: snapshot)
    }

    private var snapshotDescription: String {
        AudioResourcePresentation.description(for: snapshot, locale: locale)
    }
}

enum AudioResourcePresentation {
    static func actions(for snapshot: DownloadSnapshot) -> [SettingsViewModel.AudioResourceAction] {
        switch snapshot.state {
        case .idle:
            return [.start]
        case .downloading:
            return [.pause, .restart]
        case .paused:
            return [.resume, .restart]
        case .completed:
            return [.restart]
        case .failed:
            return [.restart]
        }
    }

    static func description(for snapshot: DownloadSnapshot, locale: AppLocale) -> String {
        let downloaded = ByteCountFormatter.string(fromByteCount: snapshot.downloadedBytes, countStyle: .file)
        let total = snapshot.totalBytes.map { ByteCountFormatter.string(fromByteCount: $0, countStyle: .file) } ?? "--"

        switch snapshot.state {
        case .idle:
            return AppLocalizer.text(.audioStatusIdle, locale: locale)
        case .downloading:
            return "\(AppLocalizer.text(.audioStatusDownloading, locale: locale)) · \(downloaded) / \(total)"
        case .paused:
            return "\(AppLocalizer.text(.audioStatusPaused, locale: locale)) · \(downloaded) / \(total)"
        case .completed:
            return "\(AppLocalizer.text(.audioStatusCompleted, locale: locale)) · \(downloaded)"
        case .failed(let message):
            return "\(AppLocalizer.text(.audioStatusFailed, locale: locale)) · \(message)"
        }
    }
}

private extension SettingsViewModel.AudioResourceAction {
    func buttonTitle(locale: AppLocale) -> String {
        switch self {
        case .start:
            return AppLocalizer.text(.audioActionStart, locale: locale)
        case .pause:
            return AppLocalizer.text(.audioActionPause, locale: locale)
        case .resume:
            return AppLocalizer.text(.audioActionResume, locale: locale)
        case .restart:
            return AppLocalizer.text(.audioActionRestart, locale: locale)
        }
    }

    var systemImage: String {
        switch self {
        case .start:
            return "arrow.down.circle"
        case .pause:
            return "pause.circle"
        case .resume:
            return "play.circle"
        case .restart:
            return "arrow.clockwise.circle"
        }
    }
}

private extension AppThemePreference {
    func displayName(in locale: AppLocale) -> String {
        switch self {
        case .system:
            return AppLocalizer.text(.themeSystem, locale: locale)
        case .light:
            return AppLocalizer.text(.themeLight, locale: locale)
        case .dark:
            return AppLocalizer.text(.themeDark, locale: locale)
        case .amoled:
            return AppLocalizer.text(.themeAmoled, locale: locale)
        }
    }
}

private extension Double {
    func displayScaleLabel(locale: AppLocale) -> String {
        AppLocalizer.formattedText(.settingsReadingTextScaleValueFormat, locale: locale, self)
    }
}
