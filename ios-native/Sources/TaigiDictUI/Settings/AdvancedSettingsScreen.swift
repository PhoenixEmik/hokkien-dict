import SwiftUI
import TaigiDictCore

struct AdvancedSettingsScreen: View {
    @Bindable var viewModel: SettingsViewModel
    @Environment(\.locale) private var locale
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
    }

#if os(macOS)
    private var macAdvancedSettingsForm: some View {
        Form {
            Section(AppLocalizer.text(.advancedMaintenanceSection, locale: appLocale)) {
                if viewModel.supportsDataMaintenance {
                    HStack(spacing: 12) {
                        Button(AppLocalizer.text(.advancedRebuild, locale: appLocale), systemImage: "arrow.clockwise") {
                            Task {
                                if await viewModel.run(.rebuild) {
                                    onMaintenanceCompleted()
                                }
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(viewModel.isRunningAction)

                        Button(AppLocalizer.text(.advancedClear, locale: appLocale), systemImage: "trash", role: .destructive) {
                            viewModel.requestClearConfirmation()
                        }
                        .buttonStyle(.bordered)
                        .disabled(viewModel.isRunningAction)

                        Spacer()
                    }
                } else {
                    Text(AppLocalizer.text(.advancedMaintenanceUnsupported, locale: appLocale))
                        .foregroundStyle(.secondary)
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
                Section(AppLocalizer.text(.advancedStatusSection, locale: appLocale)) {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text(AppLocalizer.text(.advancedRunning, locale: appLocale))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if let statusMessageKey = viewModel.statusMessageKey {
                Section(AppLocalizer.text(.advancedStatusSection, locale: appLocale)) {
                    LabeledContent("") {
                        Label(AppLocalizer.text(statusMessageKey, locale: appLocale), systemImage: "checkmark.circle.fill")
                            .labelStyle(.titleAndIcon)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.tint)
                    }
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
        .formStyle(.grouped)
        .padding(20)
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
}
