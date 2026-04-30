import SwiftUI

struct AboutScreen: View {
    var body: some View {
        List {
            Section("台語辭典") {
                Text("台語辭典是離線優先的台語查詢工具，提供詞目、義項與例句檢索。")
                LabeledContent("版本") {
                    Text("Swift Native Preview")
                }
            }

            Section("專案") {
                Link("GitHub Repository", destination: URL(string: "https://github.com/PhoenixEmik/hokkien-app")!)
                Link("隱私政策", destination: URL(string: "https://app.taigidict.org/privacy")!)
            }
        }
        .navigationTitle("關於")
    }
}
