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
                            Task {
                                if await viewModel.run(.clear) {
                                    onMaintenanceCompleted()
                                }
                            }
                        } label: {
                            Label("清除本機辭典資料", systemImage: "trash")
                        }
                        .disabled(viewModel.isRunningAction)
                    } else {
                        Text("目前資料來源不支援本機維護操作。")
                            .foregroundStyle(.secondary)
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
    }
}
