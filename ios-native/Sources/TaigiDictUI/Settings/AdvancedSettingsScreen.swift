import SwiftUI
import TaigiDictCore

struct AdvancedSettingsScreen: View {
    @Bindable var viewModel: SettingsViewModel
    @Environment(\.locale) private var locale
    @State private var pendingAudioRestart: PendingAdvancedAudioRestart?
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

#if os(macOS)
    private var macAdvancedSettingsForm: some View {
        Form {
            if viewModel.supportsDataMaintenance {
                LabeledContent(AppLocalizer.text(.advancedMaintenanceSection, locale: appLocale)) {
                    HStack(spacing: 10) {
                        Button(AppLocalizer.text(.advancedRebuild, locale: appLocale)) {
                            Task {
                                if await viewModel.run(.rebuild) {
                                    onMaintenanceCompleted()
                                }
                            }
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
                    Button {
                        Task {
                            if await viewModel.run(.rebuild) {
                                onMaintenanceCompleted()
                            }
                        }
                    } label: {
                        Label(AppLocalizer.text(.advancedRebuild, locale: appLocale), systemImage: "arrow.clockwise")
                    }
                    .disabled(viewModel.isRunningAction)

                    Button(role: .destructive) {
                        viewModel.requestClearConfirmation()
                    } label: {
                        Label(AppLocalizer.text(.advancedClear, locale: appLocale), systemImage: "trash")
                    }
                    .disabled(viewModel.isRunningAction)
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
        Button(action: onRestart) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .foregroundStyle(.primary)
                        Text(status)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 12)

                    if isRunningAction {
                        ProgressView()
                            .controlSize(.small)
                    } else if !actions.isEmpty {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(.tint)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isRunningAction || actions.isEmpty)
    }
}
#endif

private struct PendingAdvancedAudioRestart {
    let archiveType: AudioArchiveType
    let title: String
}
