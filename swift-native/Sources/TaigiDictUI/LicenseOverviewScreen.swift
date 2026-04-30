import SwiftUI

struct LicenseOverviewScreen: View {
    var body: some View {
        List {
            Section("核心套件") {
                Label("GRDB.swift", systemImage: "shippingbox")
                Label("SwiftyOpenCC", systemImage: "shippingbox")
            }

            Section("iOS 原生框架") {
                Label("SwiftUI", systemImage: "applelogo")
                Label("Foundation", systemImage: "applelogo")
                Label("AVFoundation (音訊功能預留)", systemImage: "applelogo")
            }
        }
        .navigationTitle("套件授權清單")
    }
}
