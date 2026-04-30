import SwiftUI

struct LicenseSummaryScreen: View {
    var body: some View {
        List {
            Section("授權摘要") {
                Label("App 程式碼：MIT License", systemImage: "checkmark.seal")
                Label("辭典資料：教育部授權條款", systemImage: "checkmark.seal")
                Label("音訊資源：來源授權條款", systemImage: "checkmark.seal")
                Label("第三方套件：各自授權", systemImage: "checkmark.seal")
            }

            Section {
                NavigationLink("查看第三方套件授權清單") {
                    LicenseOverviewScreen()
                }
            }
        }
        .navigationTitle("授權資訊")
    }
}
