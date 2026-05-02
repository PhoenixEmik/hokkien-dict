import SwiftUI
import TaigiDictCore
import TaigiDictUI

@main
struct TaigiDictNativeApp: App {
    var body: some Scene {
        WindowGroup {
            TaigiDictAppRootView(
                repository: InstalledDictionaryRepository(
                    sourceDirectory: Self.localDictionarySourceDirectory,
                    installedDirectory: Self.installedDictionaryDirectory,
                    fallbackSourceDirectory: Self.bundledDictionaryDirectory
                ),
                dictionarySourceStore: DictionarySourceResourceStore(
                    bundledDirectory: Self.bundledDictionaryDirectory,
                    localDirectory: Self.localDictionarySourceDirectory
                )
            )
        }
    }

    private static var bundledDictionaryDirectory: URL {
        guard let url = Bundle.main.url(forResource: "Dictionary", withExtension: nil) else {
            preconditionFailure("Bundled dictionary package is missing.")
        }
        return url
    }

    private static var localDictionarySourceDirectory: URL {
        applicationSupportDirectory
            .appendingPathComponent("TaigiDict/DictionarySource", isDirectory: true)
    }

    private static var installedDictionaryDirectory: URL {
        applicationSupportDirectory.appendingPathComponent(
            "TaigiDict/Dictionary",
            isDirectory: true
        )
    }

    private static var applicationSupportDirectory: URL {
        FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
    }
}
