import SwiftUI
import TaigiDictCore

public struct ThirdPartyLicenseCatalog {
    public static let directDependencies: [ThirdPartyLicenseEntry] = [
        ThirdPartyLicenseEntry(
            name: "GRDB.swift",
            version: "7.10.0",
            licenseName: "MIT License",
            repositoryURL: URL(string: "https://github.com/groue/GRDB.swift")!,
            includedVia: nil,
            noteKey: nil,
            licenseResourceName: "grdb_mit"
        ),
        ThirdPartyLicenseEntry(
            name: "SwiftyOpenCC",
            version: "1.3.1",
            licenseName: "MIT License",
            repositoryURL: URL(string: "https://github.com/PhoenixEmik/SwiftyOpenCC")!,
            includedVia: nil,
            noteKey: nil,
            licenseResourceName: "swiftyopencc_mit"
        ),
        ThirdPartyLicenseEntry(
            name: "ZIPFoundation",
            version: "0.9.20",
            licenseName: "MIT License",
            repositoryURL: URL(string: "https://github.com/weichsel/ZIPFoundation")!,
            includedVia: nil,
            noteKey: nil,
            licenseResourceName: "zipfoundation_mit"
        ),
    ]

    public static let bundledComponents: [ThirdPartyLicenseEntry] = [
        ThirdPartyLicenseEntry(
            name: "OpenCC",
            version: nil,
            licenseName: "Apache License 2.0",
            repositoryURL: URL(string: "https://github.com/BYVoid/OpenCC")!,
            includedVia: "SwiftyOpenCC",
            noteKey: nil,
            licenseResourceName: "opencc_apache_2_0"
        ),
        ThirdPartyLicenseEntry(
            name: "libmarisa",
            version: nil,
            licenseName: "BSD-2-Clause",
            repositoryURL: URL(string: "https://github.com/s-yata/marisa-trie")!,
            includedVia: "OpenCC",
            noteKey: .licenseMarisaNotice,
            licenseResourceName: "marisa_bsd_2_clause"
        ),
    ]

    public static var allEntries: [ThirdPartyLicenseEntry] {
        directDependencies + bundledComponents
    }

    public static func entry(id: String) -> ThirdPartyLicenseEntry? {
        allEntries.first { $0.id == id }
    }
}

public struct ThirdPartyLicenseEntry: Identifiable, Hashable {
    public let name: String
    public let version: String?
    public let licenseName: String
    public let repositoryURL: URL
    public let includedVia: String?
    public let noteKey: AppLocalizedStringKey?
    public let licenseResourceName: String

    public init(
        name: String,
        version: String?,
        licenseName: String,
        repositoryURL: URL,
        includedVia: String?,
        noteKey: AppLocalizedStringKey?,
        licenseResourceName: String
    ) {
        self.name = name
        self.version = version
        self.licenseName = licenseName
        self.repositoryURL = repositoryURL
        self.includedVia = includedVia
        self.noteKey = noteKey
        self.licenseResourceName = licenseResourceName
    }

    public var id: String {
        [name, version, includedVia]
            .compactMap { $0 }
            .joined(separator: "::")
    }

    public func summaryText() -> String {
        if let version, !version.isEmpty {
            return "\(version) • \(licenseName)"
        }
        return licenseName
    }

    public func licenseText() -> String {
        let candidateURL = Bundle.module.url(
            forResource: licenseResourceName,
            withExtension: "txt"
        ) ?? Bundle.module.url(
            forResource: licenseResourceName,
            withExtension: "txt",
            subdirectory: "ThirdPartyLicenses"
        )

        guard
            let url = candidateURL,
            let contents = try? String(contentsOf: url, encoding: .utf8)
        else {
            assertionFailure("Missing bundled license resource: \(licenseResourceName)")
            return ""
        }
        return contents
    }
}

public struct ThirdPartyLicenseDetailScreen: View {
    public let entry: ThirdPartyLicenseEntry

    @Environment(\.locale) private var locale

    private var appLocale: AppLocale {
        AppLocalizer.appLocale(from: locale)
    }

    public init(entry: ThirdPartyLicenseEntry) {
        self.entry = entry
    }

    public var body: some View {
        List {
            Section(AppLocalizer.text(.licenseMetadataSection, locale: appLocale)) {
                LabeledContent {
                    Text(entry.licenseName)
                        .foregroundStyle(.secondary)
                } label: {
                    Text(AppLocalizer.text(.licenseAgreement, locale: appLocale))
                }

                if let version = entry.version {
                    LabeledContent {
                        Text(version)
                            .foregroundStyle(.secondary)
                    } label: {
                        Text(AppLocalizer.text(.licenseVersion, locale: appLocale))
                    }
                }

                LabeledContent {
                    Link(entry.repositoryURL.absoluteString, destination: entry.repositoryURL)
                        .font(.footnote)
                } label: {
                    Text(AppLocalizer.text(.licenseRepository, locale: appLocale))
                }

                if let includedVia = entry.includedVia {
                    LabeledContent {
                        Text(includedVia)
                            .foregroundStyle(.secondary)
                    } label: {
                        Text(AppLocalizer.text(.licenseIncludedVia, locale: appLocale))
                    }
                }

                if let noteKey = entry.noteKey {
                    Text(AppLocalizer.text(noteKey, locale: appLocale))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section(AppLocalizer.text(.licenseTextSection, locale: appLocale)) {
                Text(verbatim: entry.licenseText())
                    .font(.system(.footnote, design: .monospaced))
                    .textSelection(.enabled)
            }
        }
        .listStyle(.inset)
#if os(iOS)
        .navigationTitle(entry.name)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }
}
