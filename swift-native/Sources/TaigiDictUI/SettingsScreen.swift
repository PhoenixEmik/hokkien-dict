import SwiftUI
import TaigiDictCore

public struct SettingsScreen: View {
    @State private var viewModel: SettingsViewModel
    private let onMaintenanceCompleted: () -> Void

    public init(
        library: DictionaryLibrary,
        onMaintenanceCompleted: @escaping () -> Void = {}
    ) {
        _viewModel = State(initialValue: SettingsViewModel(library: library))
        self.onMaintenanceCompleted = onMaintenanceCompleted
    }

    public var body: some View {
        NavigationStack {
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

                if let metadata = viewModel.libraryMetadata {
                    Section("資料來源時間") {
                        if let builtAt = metadata.builtAt {
                            LabeledContent("建置時間") {
                                Text(builtAt)
                            }
                        }
                        if let sourceModifiedAt = metadata.sourceModifiedAt {
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
                    Section {
                        Text(statusMessage)
                            .foregroundStyle(.green)
                    } header: {
                        Text("狀態")
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
            .navigationTitle("設定")
        }
        .task {
            await viewModel.loadCapabilities()
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
