import SwiftUI
import TaigiDictCore

struct AdvancedSettingsScreen: View {
    @Bindable var viewModel: SettingsViewModel
    @Environment(\.locale) private var locale
    @State private var pendingAudioRestart: PendingAdvancedAudioRestart?
    @State private var isPresentingRebuildConfirmation = false
    var onMaintenanceCompleted: () -> Void

    private var appLocale: AppLocale {
        AppLocalizer.appLocale(from: locale)
    }

    var body: some View {
        Group {
#if os(macOS)
            macAdvancedSettingsForm
#else
            iosAdvancedSettingsList
#endif
        }
        .navigationTitle(AppLocalizer.text(.advancedTitle, locale: appLocale))
        .alert(
            AppLocalizer.text(.settingsRebuildConfirmTitle, locale: appLocale),
            isPresented: $isPresentingRebuildConfirmation
        ) {
            Button(AppLocalizer.text(.advancedRebuild, locale: appLocale)) {
                confirmRebuild()
            }
            Button(AppLocalizer.text(.commonCancel, locale: appLocale), role: .cancel) {}
        } message: {
            Text(AppLocalizer.text(.settingsRebuildConfirmBody, locale: appLocale))
        }
        .alert(
            AppLocalizer.text(.audioRestartConfirmTitle, locale: appLocale),
            isPresented: Binding(
                get: { pendingAudioRestart != nil },
                set: { isPresented in
                    if !isPresented {
                        pendingAudioRestart = nil
                    }
                }
            )
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
#if !os(macOS)
        .alert(
            AppLocalizer.text(.settingsClearConfirmTitle, locale: appLocale),
            isPresented: Binding(
                get: { viewModel.isClearConfirmationPresented },
                set: { isPresented in
                    if !isPresented {
                        viewModel.cancelClearConfirmation()
                    }
                }
            )
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
#endif
    }

#if os(macOS)
    private var macAdvancedSettingsForm: some View {
        Form {
            if viewModel.supportsDataMaintenance {
                LabeledContent(AppLocalizer.text(.advancedMaintenanceSection, locale: appLocale)) {
                    HStack(spacing: 10) {
                        Button(AppLocalizer.text(.advancedRebuild, locale: appLocale)) {
                            isPresentingRebuildConfirmation = true
                        }
                        .disabled(viewModel.isRunningAction)

                        Button(AppLocalizer.text(.advancedClear, locale: appLocale), role: .destructive) {
                            viewModel.requestClearConfirmation()
                        }
                        .disabled(viewModel.isRunningAction)
                    }
                }
            } else {
                LabeledContent(AppLocalizer.text(.advancedMaintenanceSection, locale: appLocale)) {
                    Text(AppLocalizer.text(.advancedMaintenanceUnsupported, locale: appLocale))
                        .foregroundStyle(.secondary)
                }
            }

            if let summary = viewModel.librarySummary {
                LabeledContent(AppLocalizer.text(.advancedEntryCount, locale: appLocale), value: "\(summary.entryCount)")
                LabeledContent(AppLocalizer.text(.advancedSenseCount, locale: appLocale), value: "\(summary.senseCount)")
                LabeledContent(AppLocalizer.text(.advancedExampleCount, locale: appLocale), value: "\(summary.exampleCount)")
            }

            if let builtAt = viewModel.metadataBuiltAtDisplay {
                LabeledContent(AppLocalizer.text(.advancedBuiltAt, locale: appLocale), value: builtAt)
            }

            if let sourceModifiedAt = viewModel.metadataSourceModifiedAtDisplay {
                LabeledContent(AppLocalizer.text(.advancedSourceUpdated, locale: appLocale), value: sourceModifiedAt)
            }

            if viewModel.isRunningAction {
                LabeledContent(AppLocalizer.text(.advancedStatusSection, locale: appLocale)) {
                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                        Text(AppLocalizer.text(.advancedRunning, locale: appLocale))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if let statusMessageKey = viewModel.statusMessageKey {
                LabeledContent(AppLocalizer.text(.advancedStatusSection, locale: appLocale)) {
                    Label(AppLocalizer.text(statusMessageKey, locale: appLocale), systemImage: "checkmark.circle.fill")
                        .labelStyle(.titleAndIcon)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.tint)
                }
            }

            if let errorMessage = viewModel.errorMessage {
                LabeledContent(AppLocalizer.text(.advancedFailedTitle, locale: appLocale)) {
                    Text(errorMessage)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.columns)
        .frame(maxWidth: 500, alignment: .topLeading)
        .padding(30)
    }
#else
    private var iosAdvancedSettingsList: some View {
        List {
            Section(AppLocalizer.text(.advancedMaintenanceSection, locale: appLocale)) {
                if viewModel.supportsDataMaintenance {
                    AdvancedMaintenanceActionRow(
                        title: AppLocalizer.text(.advancedRebuild, locale: appLocale),
                        systemImage: "arrow.clockwise",
                        tint: .accentColor,
                        isRunningAction: viewModel.isRunningAction,
                        isEnabled: !viewModel.isRunningAction
                    ) {
                        isPresentingRebuildConfirmation = true
                    }

                    AdvancedMaintenanceActionRow(
                        title: AppLocalizer.text(.advancedClear, locale: appLocale),
                        systemImage: "trash",
                        tint: .red,
                        isDestructive: true,
                        isRunningAction: viewModel.isRunningAction,
                        isEnabled: !viewModel.isRunningAction
                    ) {
                        viewModel.requestClearConfirmation()
                    }
                } else {
                    Text(AppLocalizer.text(.advancedMaintenanceUnsupported, locale: appLocale))
                        .foregroundStyle(.secondary)
                }
                AdvancedAudioMaintenanceRow(
                    title: AppLocalizer.text(.settingsRedownloadWordAudio, locale: appLocale),
                    status: DownloadSnapshotStatusPresentation.description(
                        for: viewModel.snapshot(for: .word),
                        locale: appLocale,
                        isLoading: !viewModel.hasLoadedAudioSnapshots
                    ),
                    isRunningAction: viewModel.isAudioActionRunning(for: .word),
                    actions: AudioResourcePresentation.maintenanceActions(
                        for: viewModel.snapshot(for: .word),
                        isLoading: !viewModel.hasLoadedAudioSnapshots
                    )
                ) {
                    pendingAudioRestart = PendingAdvancedAudioRestart(
                        archiveType: .word,
                        title: AppLocalizer.text(.settingsRedownloadWordAudio, locale: appLocale)
                    )
                }

                AdvancedAudioMaintenanceRow(
                    title: AppLocalizer.text(.settingsRedownloadSentenceAudio, locale: appLocale),
                    status: DownloadSnapshotStatusPresentation.description(
                        for: viewModel.snapshot(for: .sentence),
                        locale: appLocale,
                        isLoading: !viewModel.hasLoadedAudioSnapshots
                    ),
                    isRunningAction: viewModel.isAudioActionRunning(for: .sentence),
                    actions: AudioResourcePresentation.maintenanceActions(
                        for: viewModel.snapshot(for: .sentence),
                        isLoading: !viewModel.hasLoadedAudioSnapshots
                    )
                ) {
                    pendingAudioRestart = PendingAdvancedAudioRestart(
                        archiveType: .sentence,
                        title: AppLocalizer.text(.settingsRedownloadSentenceAudio, locale: appLocale)
                    )
                }
            }

            if let summary = viewModel.librarySummary {
                Section(AppLocalizer.text(.advancedSummarySection, locale: appLocale)) {
                    LabeledContent(AppLocalizer.text(.advancedEntryCount, locale: appLocale)) {
                        Text("\(summary.entryCount)")
                    }
                    LabeledContent(AppLocalizer.text(.advancedSenseCount, locale: appLocale)) {
                        Text("\(summary.senseCount)")
                    }
                    LabeledContent(AppLocalizer.text(.advancedExampleCount, locale: appLocale)) {
                        Text("\(summary.exampleCount)")
                    }
                }
            }

            if viewModel.libraryMetadata != nil {
                Section(AppLocalizer.text(.advancedSourceTimeSection, locale: appLocale)) {
                    if let builtAt = viewModel.metadataBuiltAtDisplay {
                        LabeledContent(AppLocalizer.text(.advancedBuiltAt, locale: appLocale)) {
                            Text(builtAt)
                        }
                    }

                    if let sourceModifiedAt = viewModel.metadataSourceModifiedAtDisplay {
                        LabeledContent(AppLocalizer.text(.advancedSourceUpdated, locale: appLocale)) {
                            Text(sourceModifiedAt)
                        }
                    }
                }
            }

            if viewModel.isRunningAction {
                Section {
                    HStack {
                        ProgressView()
                        Text(AppLocalizer.text(.advancedRunning, locale: appLocale))
                    }
                }
            }

            if let statusMessageKey = viewModel.statusMessageKey {
                Section(AppLocalizer.text(.advancedStatusSection, locale: appLocale)) {
                    Label(AppLocalizer.text(statusMessageKey, locale: appLocale), systemImage: "checkmark.circle.fill")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.tint)
                }
            }

            if let errorMessage = viewModel.errorMessage {
                Section {
                    ContentUnavailableView(
                        AppLocalizer.text(.advancedFailedTitle, locale: appLocale),
                        systemImage: "exclamationmark.triangle",
                        description: Text(errorMessage)
                    )
                }
            }
        }
    }
#endif

    private func confirmRebuild() {
        Task {
            if await viewModel.run(.rebuild) {
                onMaintenanceCompleted()
            }
        }
    }

    private func confirmPendingAudioRestart() {
        guard let pendingAudioRestart else {
            return
        }

        let archiveType = pendingAudioRestart.archiveType
        self.pendingAudioRestart = nil

        Task {
            await viewModel.runAudioAction(.restart, for: archiveType)
        }
    }
}

#if !os(macOS)
private struct AdvancedAudioMaintenanceRow: View {
    let title: String
    let status: String
    let isRunningAction: Bool
    let actions: [SettingsViewModel.AudioResourceAction]
    let onRestart: () -> Void

    var body: some View {
        AdvancedMaintenanceActionRow(
            title: title,
            subtitle: status,
            systemImage: "arrow.clockwise",
            tint: .accentColor,
            isRunningAction: isRunningAction,
            isEnabled: !isRunningAction && !actions.isEmpty,
            action: onRestart
        )
    }
}

private struct AdvancedMaintenanceActionRow: View {
    let title: String
    var subtitle: String? = nil
    let systemImage: String
    let tint: Color
    var isDestructive = false
    let isRunningAction: Bool
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(tint)
                    .frame(width: 28, alignment: .center)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .foregroundStyle(isDestructive ? .red : .primary)

                    if let subtitle {
                        Text(subtitle)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 12)

                if isRunningAction {
                    ProgressView()
                        .controlSize(.small)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}
#endif

private struct PendingAdvancedAudioRestart {
    let archiveType: AudioArchiveType
    let title: String
}
