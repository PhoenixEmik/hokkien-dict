import SwiftUI
import TaigiDictCore

public struct SettingsScreen: View {
    @EnvironmentObject private var appLanguageManager: AppLanguageManager
    @State private var viewModel: SettingsViewModel
    @State private var pendingAudioRestart: PendingAudioRestart?
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
        let wordAudioTitle = AppLocalizer.text(.settingsWordAudio, locale: appLocale)
        let sentenceAudioTitle = AppLocalizer.text(.settingsSentenceAudio, locale: appLocale)
        NavigationStack {
            Form {
                Section(AppLocalizer.text(.settingsDisplayLanguageSection, locale: appLocale)) {
                    Picker(appLanguageManager.localized(.settingsInterfaceLanguageLabel), selection: Binding(
                        get: { appLanguageManager.selectedLanguage },
                        set: { language in
                            appLanguageManager.setLanguage(language)
                        }
                    )) {
                        ForEach(AppLanguage.allCases, id: \.self) { language in
                            Text(appLanguageManager.displayName(for: language))
                                .accessibilityIdentifier(language.settingsAccessibilityIdentifier)
                                .tag(language)
                        }
                    }
                    .accessibilityIdentifier("settings.interfaceLanguagePicker")

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

                if viewModel.supportsDictionarySourceResources {
                    Section(AppLocalizer.text(.settingsDictionaryResourcesSection, locale: appLocale)) {
                        DictionarySourceResourceRow(
                            title: AppLocalizer.text(.settingsDictionarySource, locale: appLocale),
                            locale: appLocale,
                            snapshot: viewModel.dictionarySourceSnapshot,
                            isSnapshotLoading: false,
                            isRunningAction: viewModel.isDictionarySourceActionRunning
                        ) { action in
                            handleDictionarySourceAction(action)
                        }
                    }
                }

                Section(AppLocalizer.text(.settingsOfflineAudioSection, locale: appLocale)) {
                    AudioArchiveResourceRow(
                        title: wordAudioTitle,
                        locale: appLocale,
                        snapshot: viewModel.snapshot(for: .word),
                        isSnapshotLoading: !viewModel.hasLoadedAudioSnapshots,
                        isRunningAction: viewModel.isAudioActionRunning(for: .word)
                    ) { action in
                        handleAudioAction(action, for: .word, title: wordAudioTitle)
                    }

                    AudioArchiveResourceRow(
                        title: sentenceAudioTitle,
                        locale: appLocale,
                        snapshot: viewModel.snapshot(for: .sentence),
                        isSnapshotLoading: !viewModel.hasLoadedAudioSnapshots,
                        isRunningAction: viewModel.isAudioActionRunning(for: .sentence)
                    ) { action in
                        handleAudioAction(action, for: .sentence, title: sentenceAudioTitle)
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
        .confirmationDialog(
            AppLocalizer.text(.audioRestartConfirmTitle, locale: appLocale),
            isPresented: Binding(
                get: { pendingAudioRestart != nil },
                set: { isPresented in
                    if !isPresented {
                        pendingAudioRestart = nil
                    }
                }
            ),
            titleVisibility: .visible
        ) {
            Button(AppLocalizer.text(.audioActionRestart, locale: appLocale)) {
                confirmPendingAudioRestart()
            }
            Button(AppLocalizer.text(.commonCancel, locale: appLocale), role: .cancel) {
                pendingAudioRestart = nil
            }
        } message: {
            Text(
                AppLocalizer.formattedText(
                    .audioRestartConfirmBody,
                    locale: appLocale,
                    pendingAudioRestart?.title ?? ""
                )
            )
        }
    }

    private func handleDictionarySourceAction(_ action: SettingsViewModel.DictionarySourceAction) {
        Task {
            await viewModel.runDictionarySourceAction(action)
            onMaintenanceCompleted()
        }
    }

    private func handleAudioAction(
        _ action: SettingsViewModel.AudioResourceAction,
        for type: AudioArchiveType,
        title: String
    ) {
        switch action {
        case .restart:
            pendingAudioRestart = PendingAudioRestart(archiveType: type, title: title)
        case .start, .pause, .resume:
            Task {
                await viewModel.runAudioAction(action, for: type)
            }
        }
    }

    private func confirmPendingAudioRestart() {
        guard let restart = pendingAudioRestart else {
            return
        }

        pendingAudioRestart = nil
        Task {
            await viewModel.runAudioAction(.restart, for: restart.archiveType)
        }
    }
}

private struct PendingAudioRestart {
    let archiveType: AudioArchiveType
    let title: String
}

private extension AppLanguage {
    var settingsAccessibilityIdentifier: String {
        switch self {
        case .system:
            return "settings.interfaceLanguage.system"
        case .zhHant:
            return "settings.interfaceLanguage.zh-Hant"
        case .zhHans:
            return "settings.interfaceLanguage.zh-Hans"
        case .en:
            return "settings.interfaceLanguage.en"
        }
    }
}

private struct DictionarySourceResourceRow: View {
    let title: String
    let locale: AppLocale
    let snapshot: DownloadSnapshot
    let isSnapshotLoading: Bool
    let isRunningAction: Bool
    let runAction: (SettingsViewModel.DictionarySourceAction) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                    Text(snapshotDescription)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 12)

                if isSnapshotLoading || isRunningAction {
                    ProgressView()
                        .controlSize(.small)
                }

                ResourceActionControl(
                    locale: locale,
                    isDisabled: isSnapshotLoading || isRunningAction,
                    actions: availableActions,
                    buttonTitle: { $0.buttonTitle(locale: locale) },
                    systemImage: \.systemImage,
                    runAction: runAction
                )
            }

            if let progress = snapshot.progress {
                ProgressView(value: progress)
            }
        }
        .padding(.vertical, 4)
    }

    private var availableActions: [SettingsViewModel.DictionarySourceAction] {
        DictionarySourceResourcePresentation.actions(isLoading: isSnapshotLoading)
    }

    private var snapshotDescription: String {
        DownloadSnapshotStatusPresentation.description(for: snapshot, locale: locale, isLoading: isSnapshotLoading)
    }
}

private struct AudioArchiveResourceRow: View {
    let title: String
    let locale: AppLocale
    let snapshot: DownloadSnapshot
    let isSnapshotLoading: Bool
    let isRunningAction: Bool
    let runAction: (SettingsViewModel.AudioResourceAction) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                    Text(snapshotDescription)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 12)

                if isSnapshotLoading || isRunningAction {
                    ProgressView()
                        .controlSize(.small)
                }

                ResourceActionControl(
                    locale: locale,
                    isDisabled: isSnapshotLoading || isRunningAction,
                    actions: availableActions,
                    buttonTitle: { $0.buttonTitle(locale: locale) },
                    systemImage: \.systemImage,
                    runAction: runAction
                )
            }

            if let progress = snapshot.progress {
                ProgressView(value: progress)
            }
        }
        .padding(.vertical, 4)
    }

    private var availableActions: [SettingsViewModel.AudioResourceAction] {
        AudioResourcePresentation.actions(for: snapshot, isLoading: isSnapshotLoading)
    }

    private var snapshotDescription: String {
        DownloadSnapshotStatusPresentation.description(for: snapshot, locale: locale, isLoading: isSnapshotLoading)
    }
}

private struct ResourceActionControl<Action: Hashable>: View {
    let locale: AppLocale
    let isDisabled: Bool
    let actions: [Action]
    let buttonTitle: (Action) -> String
    let systemImage: (Action) -> String
    let runAction: (Action) -> Void

    var body: some View {
#if os(macOS)
        HStack(spacing: 8) {
            ForEach(actions, id: \.self) { action in
                Button(buttonTitle(action), systemImage: systemImage(action)) {
                    runAction(action)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .disabled(isDisabled || actions.isEmpty)
#else
        Menu {
            ForEach(actions, id: \.self) { action in
                Button(buttonTitle(action), systemImage: systemImage(action)) {
                    runAction(action)
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 22))
                    .frame(width: 24, height: 24)
                    .accessibilityHidden(true)

                Text(AppLocalizer.text(.settingsActionsMenu, locale: locale))
            }
            .fixedSize(horizontal: true, vertical: true)
        }
        .disabled(isDisabled || actions.isEmpty)
#endif
    }
}

enum DictionarySourceResourcePresentation {
    static func actions(isLoading: Bool = false) -> [SettingsViewModel.DictionarySourceAction] {
        guard !isLoading else {
            return []
        }

        return [.restore, .download]
    }
}

enum AudioResourcePresentation {
    static func actions(for snapshot: DownloadSnapshot, isLoading: Bool = false) -> [SettingsViewModel.AudioResourceAction] {
        guard !isLoading else {
            return []
        }

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
}

enum DownloadSnapshotStatusPresentation {
    static func description(for snapshot: DownloadSnapshot, locale: AppLocale, isLoading: Bool = false) -> String {
        guard !isLoading else {
            return AppLocalizer.text(.audioStatusChecking, locale: locale)
        }

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

private extension SettingsViewModel.DictionarySourceAction {
    func buttonTitle(locale: AppLocale) -> String {
        switch self {
        case .restore:
            return AppLocalizer.text(.dictionarySourceActionRestore, locale: locale)
        case .download:
            return AppLocalizer.text(.dictionarySourceActionDownload, locale: locale)
        }
    }

    var systemImage: String {
        switch self {
        case .restore:
            return "arrow.uturn.backward.circle"
        case .download:
            return "arrow.down.circle"
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
        }
    }
}

private extension Double {
    func displayScaleLabel(locale: AppLocale) -> String {
        AppLocalizer.formattedText(.settingsReadingTextScaleValueFormat, locale: locale, self)
    }
}
