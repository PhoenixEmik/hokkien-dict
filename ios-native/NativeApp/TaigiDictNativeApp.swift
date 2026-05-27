import SwiftUI
import TaigiDictCore
import TaigiDictUI

@main
struct TaigiDictNativeApp: App {
    private static let appStorage = TaigiDictAppStorage.resolve()

    var body: some Scene {
        WindowGroup {
            TaigiDictAppRootView(
                repository: InstalledDictionaryRepository(
                    sourceDirectory: Self.appStorage.dictionarySourceDirectory,
                    installedDirectory: Self.appStorage.installedDictionaryDirectory,
                    fallbackSourceDirectory: Self.bundledDictionaryDirectory
                ),
                dictionarySourceStore: DictionarySourceResourceStore(
                    bundledDirectory: Self.bundledDictionaryDirectory,
                    localDirectory: Self.appStorage.dictionarySourceDirectory
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
}
