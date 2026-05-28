import SwiftUI
import TaigiDictCore

public struct SettingsScreen: View {
    @EnvironmentObject private var appLanguageManager: AppLanguageManager
    @State private var viewModel: SettingsViewModel
    @State private var pendingAudioRestart: PendingAudioRestart?
#if os(macOS)
    @State private var selectedReferenceKind: ReferenceArticleKind = .taiLo
#endif
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
        Group {
#if os(macOS)
            macSettingsContent(
                locale: appLocale,
                wordAudioTitle: wordAudioTitle,
                sentenceAudioTitle: sentenceAudioTitle
            )
#else
            NavigationStack {
                settingsContent(
                    locale: appLocale,
                    wordAudioTitle: wordAudioTitle,
                    sentenceAudioTitle: sentenceAudioTitle
                )
                .navigationTitle(AppLocalizer.text(.settingsTitle, locale: appLocale))
            }
#endif
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

    @ViewBuilder
    private func settingsContent(
        locale: AppLocale,
        wordAudioTitle: String,
        sentenceAudioTitle: String
    ) -> some View {
        Form {
            Section(AppLocalizer.text(.settingsDisplayLanguageSection, locale: locale)) {
                interfaceLanguagePicker
                themePicker(locale: locale)
                readingTextScaleControl(locale: locale)
            }

            Section(AppLocalizer.text(.settingsDataAndInfoSection, locale: locale)) {
                NavigationLink {
                    AdvancedSettingsScreen(viewModel: viewModel) {
                        onMaintenanceCompleted()
                    }
                } label: {
                    Label(AppLocalizer.text(.settingsAdvanced, locale: locale), systemImage: "wrench.and.screwdriver")
                }

                NavigationLink {
                    AboutScreen()
                } label: {
                    Label(AppLocalizer.text(.settingsAbout, locale: locale), systemImage: "info.circle")
                }

                NavigationLink {
                    ReferenceArticleListScreen()
                } label: {
                    Label(AppLocalizer.text(.settingsReferences, locale: locale), systemImage: "text.book.closed")
                }
            }

            Section(AppLocalizer.text(.settingsOfflineAudioSection, locale: locale)) {
                AudioArchiveResourceRow(
                    title: wordAudioTitle,
                    locale: locale,
                    snapshot: viewModel.snapshot(for: .word),
                    isSnapshotLoading: !viewModel.hasLoadedAudioSnapshots,
                    isRunningAction: viewModel.isAudioActionRunning(for: .word)
                ) { action in
                    handleAudioAction(action, for: .word, title: wordAudioTitle)
                }

                AudioArchiveResourceRow(
                    title: sentenceAudioTitle,
                    locale: locale,
                    snapshot: viewModel.snapshot(for: .sentence),
                    isSnapshotLoading: !viewModel.hasLoadedAudioSnapshots,
                    isRunningAction: viewModel.isAudioActionRunning(for: .sentence)
                ) { action in
                    handleAudioAction(action, for: .sentence, title: sentenceAudioTitle)
                }
            }
        }
    }

#if os(macOS)
    private func macSettingsContent(
        locale: AppLocale,
        wordAudioTitle: String,
        sentenceAudioTitle: String
    ) -> some View {
        TabView {
            macSettingsTabContainer {
                Form {
                    Section(AppLocalizer.text(.settingsDisplayLanguageSection, locale: locale)) {
                        LabeledContent(appLanguageManager.localized(.settingsInterfaceLanguageLabel)) {
                            interfaceLanguagePicker
                                .labelsHidden()
                                .pickerStyle(.menu)
                        }

                        LabeledContent(AppLocalizer.text(.settingsThemeLabel, locale: locale)) {
                            themePicker(locale: locale)
                                .labelsHidden()
                                .pickerStyle(.menu)
                        }

                        readingTextScaleControl(locale: locale)
                    }
                }
                .formStyle(.grouped)
            }
            .tabItem {
                Label(AppLocalizer.text(.settingsGeneralTab, locale: locale), systemImage: "gearshape")
            }

            macSettingsTabContainer {
                Form {
                    Section(AppLocalizer.text(.settingsOfflineAudioSection, locale: locale)) {
                        AudioArchiveResourceRow(
                            title: wordAudioTitle,
                            locale: locale,
                            snapshot: viewModel.snapshot(for: .word),
                            isSnapshotLoading: !viewModel.hasLoadedAudioSnapshots,
                            isRunningAction: viewModel.isAudioActionRunning(for: .word)
                        ) { action in
                            handleAudioAction(action, for: .word, title: wordAudioTitle)
                        }

                        AudioArchiveResourceRow(
                            title: sentenceAudioTitle,
                            locale: locale,
                            snapshot: viewModel.snapshot(for: .sentence),
                            isSnapshotLoading: !viewModel.hasLoadedAudioSnapshots,
                            isRunningAction: viewModel.isAudioActionRunning(for: .sentence)
                        ) { action in
                            handleAudioAction(action, for: .sentence, title: sentenceAudioTitle)
                        }
                    }
                }
                .formStyle(.grouped)
            }
            .tabItem {
                Label(AppLocalizer.text(.settingsResourcesTab, locale: locale), systemImage: "internaldrive")
            }

            macSettingsTabContainer {
                VStack(alignment: .leading, spacing: 16) {
                    Picker(AppLocalizer.text(.settingsReferences, locale: locale), selection: $selectedReferenceKind) {
                        Text(AppLocalizer.text(.referenceTaiLoTitle, locale: locale))
                            .tag(ReferenceArticleKind.taiLo)
                        Text(AppLocalizer.text(.referenceHanjiTitle, locale: locale))
                            .tag(ReferenceArticleKind.hanji)
                    }
                    .pickerStyle(.segmented)

                    LocalizedReferenceArticleScreen(
                        kind: selectedReferenceKind,
                        fallbackTitle: selectedReferenceKind == .taiLo
                            ? AppLocalizer.text(.referenceTaiLoTitle, locale: locale)
                            : AppLocalizer.text(.referenceHanjiTitle, locale: locale)
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .padding(20)
            }
            .tabItem {
                Label(AppLocalizer.text(.settingsReferences, locale: locale), systemImage: "text.book.closed")
            }

            AdvancedSettingsScreen(viewModel: viewModel) {
                onMaintenanceCompleted()
            }
            .tabItem {
                Label(AppLocalizer.text(.settingsAdvanced, locale: locale), systemImage: "wrench.and.screwdriver")
            }
        }
        .frame(minWidth: 760, minHeight: 560)
    }

    private func macSettingsTabContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
#endif

    private var interfaceLanguagePicker: some View {
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
    }

    private func themePicker(locale: AppLocale) -> some View {
        Picker(AppLocalizer.text(.settingsThemeLabel, locale: locale), selection: Binding(
            get: { viewModel.selectedThemePreference },
            set: { preference in
                Task {
                    await viewModel.setThemePreference(preference)
                    onSettingsChanged(viewModel.currentSettingsSnapshot)
                }
            }
        )) {
            ForEach(AppThemePreference.allCases, id: \.self) { preference in
                Text(preference.displayName(in: locale))
                    .tag(preference)
            }
        }
    }

    private func readingTextScaleControl(locale: AppLocale) -> some View {
#if os(macOS)
        LabeledContent(AppLocalizer.text(.settingsReadingTextScaleLabel, locale: locale)) {
            VStack(alignment: .leading, spacing: 8) {
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
                ) {
                    EmptyView()
                } minimumValueLabel: {
                    Text("A")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                } maximumValueLabel: {
                    Text("A")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Text(viewModel.readingTextScale.displayScaleLabel(locale: locale))
                    .font(.footnote)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            .frame(minWidth: 240, maxWidth: 300, alignment: .leading)
        }
#else
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(AppLocalizer.text(.settingsReadingTextScaleLabel, locale: locale))
                Spacer()
                Text(viewModel.readingTextScale.displayScaleLabel(locale: locale))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
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
#endif
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

            if let progress = progressValue {
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

    private var progressValue: Double? {
        guard !isSnapshotLoading,
              snapshot.state == .downloading || snapshot.state == .paused,
              let progress = snapshot.progress,
              progress < 1
        else {
            return nil
        }

        return progress
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
