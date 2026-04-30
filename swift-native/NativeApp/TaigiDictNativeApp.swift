import SwiftUI
import TaigiDictCore
import TaigiDictUI

@main
struct TaigiDictNativeApp: App {
    var body: some Scene {
        WindowGroup {
            TaigiDictAppRootView(
                repository: InstalledDictionaryRepository(
                    sourceDirectory: Self.dictionaryDirectory,
                    installedDirectory: Self.installedDictionaryDirectory
                )
            )
        }
    }

    private static var dictionaryDirectory: URL {
        guard let url = Bundle.main.url(forResource: "Dictionary", withExtension: nil) else {
            preconditionFailure("Bundled dictionary package is missing.")
        }
        return url
    }

    private static var installedDictionaryDirectory: URL {
        let applicationSupportDirectory = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        return applicationSupportDirectory.appendingPathComponent(
            "TaigiDict/Dictionary",
            isDirectory: true
        )
    }
}
