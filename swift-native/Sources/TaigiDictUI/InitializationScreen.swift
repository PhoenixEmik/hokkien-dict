import SwiftUI

struct InitializationScreen: View {
    var state: InitializationViewModel.State
    var retry: () -> Void

    var body: some View {
        switch state {
        case .failed(let message):
            ContentUnavailableView {
                Label("初始化失敗", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button("重試", action: retry)
            }
        case .idle, .loading, .ready:
            ContentUnavailableView {
                Label("載入中", systemImage: "book")
            } description: {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("正在初始化辭典資料")
                }
            }
        }
    }
}