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
        Form {
            Section {
                interfaceLanguagePicker
                    .pickerStyle(.menu)

                themePicker(locale: locale)
                    .pickerStyle(.menu)

                readingTextScaleControl(locale: locale)
            } header: {
                settingsSectionHeader(AppLocalizer.text(.settingsGeneralTab, locale: locale))
            } footer: {
                settingsSectionDivider
            }

            Section {
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
            } header: {
                settingsSectionHeader(AppLocalizer.text(.settingsResourcesTab, locale: locale))
            } footer: {
                settingsSectionDivider
            }

            Section {
                if viewModel.supportsDataMaintenance {
                    LabeledContent(AppLocalizer.text(.advancedMaintenanceSection, locale: locale)) {
                        ControlGroup {
                            Button(AppLocalizer.text(.advancedRebuild, locale: locale)) {
                                Task {
                                    if await viewModel.run(.rebuild) {
                                        onMaintenanceCompleted()
                                    }
                                }
                            }
                            .controlSize(.small)
                            .disabled(viewModel.isRunningAction)

                            Button(AppLocalizer.text(.advancedClear, locale: locale), role: .destructive) {
                                viewModel.requestClearConfirmation()
                            }
                            .controlSize(.small)
                            .disabled(viewModel.isRunningAction)
                        }
                        .controlSize(.small)
                    }
                } else {
                    LabeledContent(AppLocalizer.text(.advancedMaintenanceSection, locale: locale)) {
                        Text(AppLocalizer.text(.advancedMaintenanceUnsupported, locale: locale))
                            .foregroundStyle(.secondary)
                    }
                }

                if let summary = viewModel.librarySummary {
                    macSettingsValueRow(AppLocalizer.text(.advancedEntryCount, locale: locale), value: "\(summary.entryCount)", monospaced: true)
                    macSettingsValueRow(AppLocalizer.text(.advancedSenseCount, locale: locale), value: "\(summary.senseCount)", monospaced: true)
                    macSettingsValueRow(AppLocalizer.text(.advancedExampleCount, locale: locale), value: "\(summary.exampleCount)", monospaced: true)
                }

                if let builtAt = viewModel.metadataBuiltAtDisplay {
                    macSettingsValueRow(AppLocalizer.text(.advancedBuiltAt, locale: locale), value: builtAt)
                }

                if let sourceModifiedAt = viewModel.metadataSourceModifiedAtDisplay {
                    macSettingsValueRow(AppLocalizer.text(.advancedSourceUpdated, locale: locale), value: sourceModifiedAt)
                }

                if viewModel.isRunningAction {
                    LabeledContent(AppLocalizer.text(.advancedStatusSection, locale: locale)) {
                        HStack(spacing: 8) {
                            ProgressView()
                                .controlSize(.small)
                            Text(AppLocalizer.text(.advancedRunning, locale: locale))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if let statusMessageKey = viewModel.statusMessageKey {
                    LabeledContent(AppLocalizer.text(.advancedStatusSection, locale: locale)) {
                        Label(AppLocalizer.text(statusMessageKey, locale: locale), systemImage: "checkmark.circle.fill")
                            .labelStyle(.titleAndIcon)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.tint)
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    LabeledContent(AppLocalizer.text(.advancedFailedTitle, locale: locale)) {
                        Text(errorMessage)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                settingsSectionHeader(AppLocalizer.text(.settingsAdvanced, locale: locale))
            }
        }
        .formStyle(.columns)
        .frame(width: 450)
        .padding(.horizontal, 24)
        .padding(.vertical, 22)
    }

    private func settingsSectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption2.weight(.semibold))
            .textCase(nil)
            .foregroundStyle(.secondary)
            .padding(.top, 2)
            .padding(.bottom, 2)
    }

    private var settingsSectionDivider: some View {
        Divider()
            .padding(.top, 10)
    }

    private func macSettingsValueRow(_ title: String, value: String, monospaced: Bool = false) -> some View {
        LabeledContent(title) {
            if monospaced {
                Text(value)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            } else {
                Text(value)
                    .foregroundStyle(.secondary)
            }
        }
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
            HStack(spacing: 12) {
                Image(systemName: "textformat.size.smaller")
                    .font(.callout)
                    .foregroundStyle(.secondary)

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
                }
                .controlSize(.regular)
                .frame(width: 170)

                Text(viewModel.readingTextScale.displayScaleLabel(locale: locale))
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .frame(width: 48, alignment: .trailing)

                Image(systemName: "textformat.size.larger")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 270, alignment: .leading)
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
#if os(macOS)
        LabeledContent(title) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(snapshotDescription)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .layoutPriority(1)

                        if isSnapshotLoading || isRunningAction {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }

                    Spacer(minLength: 8)

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
                        .frame(width: 160, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
#else
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
#endif
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
                Button(buttonTitle(action)) {
                    runAction(action)
                }
                .controlSize(.mini)
                .fixedSize()
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
