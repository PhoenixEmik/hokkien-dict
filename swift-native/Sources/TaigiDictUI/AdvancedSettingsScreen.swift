import SwiftUI

struct AdvancedSettingsScreen: View {
    @Bindable var viewModel: SettingsViewModel
    var onMaintenanceCompleted: () -> Void

    var body: some View {
        List {
            Section("資料維護") {
                if viewModel.supportsDataMaintenance {
                    Button {
                        Task {
                            if await viewModel.run(.rebuild) {
                                onMaintenanceCompleted()
                            }
                        }
                    } label: {
                        Label("重建本機辭典資料", systemImage: "arrow.clockwise")
                    }
                    .disabled(viewModel.isRunningAction)

                    Button(role: .destructive) {
                        viewModel.requestClearConfirmation()
                    } label: {
                        Label("清除本機辭典資料", systemImage: "trash")
                    }
                    .disabled(viewModel.isRunningAction)
                } else {
                    Text("目前資料來源不支援本機維護操作。")
                        .foregroundStyle(.secondary)
                }
            }

            if let summary = viewModel.librarySummary {
                Section("目前資料庫摘要") {
                    LabeledContent("詞目數") {
                        Text("\(summary.entryCount)")
                    }
                    LabeledContent("義項數") {
                        Text("\(summary.senseCount)")
                    }
                    LabeledContent("例句數") {
                        Text("\(summary.exampleCount)")
                    }
                }
            }

            if viewModel.libraryMetadata != nil {
                Section("資料來源時間") {
                    if let builtAt = viewModel.metadataBuiltAtDisplay {
                        LabeledContent("建置時間") {
                            Text(builtAt)
                        }
                    }

                    if let sourceModifiedAt = viewModel.metadataSourceModifiedAtDisplay {
                        LabeledContent("來源更新") {
                            Text(sourceModifiedAt)
                        }
                    }
                }
            }

            if viewModel.isRunningAction {
                Section {
                    HStack {
                        ProgressView()
                        Text("資料維護作業進行中")
                    }
                }
            }

            if let statusMessage = viewModel.statusMessage {
                Section("狀態") {
                    Text(statusMessage)
                        .foregroundStyle(.green)
                }
            }

            if let errorMessage = viewModel.errorMessage {
                Section {
                    ContentUnavailableView(
                        "作業失敗",
                        systemImage: "exclamationmark.triangle",
                        description: Text(errorMessage)
                    )
                }
            }
        }
        .navigationTitle("進階設定")
    }
}
