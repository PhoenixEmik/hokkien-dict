#if os(macOS)
import AppKit
import SwiftUI
import TaigiDictCore

public struct MacAboutWindowView: View {
    private let repositoryURL = URL(string: "https://github.com/PhoenixEmik/taigi-dict")!
    private let privacyURL = URL(string: "https://github.com/PhoenixEmik/taigi-dict/blob/main/PRIVACY_POLICY.md")!

    @Environment(\.locale) private var locale
    @Environment(\.openWindow) private var openWindow

    private var appLocale: AppLocale {
        AppLocalizer.appLocale(from: locale)
    }

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                Image(nsImage: NSApplication.shared.applicationIconImage)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 88, height: 88)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(spacing: 4) {
                    Text(AppLocalizer.text(.aboutAppSection, locale: appLocale))
                        .font(.title2.weight(.semibold))

                    if let appVersion {
                        Text("\(AppLocalizer.text(.aboutVersion, locale: appLocale)) \(appVersion)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(spacing: 3) {
                    Text("\(AppLocalizer.text(.aboutAuthor, locale: appLocale))：PhoenixEmik")
                    Text("Copyright © 2026 PhoenixEmik")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 28)
            .padding(.horizontal, 32)

            Spacer(minLength: 24)

            VStack(spacing: 14) {
                HStack(spacing: 10) {
                    Button(AppLocalizer.text(.settingsLicenses, locale: appLocale)) {
                        openWindow(id: LicenseWindow.licenseWindowID)
                    }

                    Button(AppLocalizer.text(.settingsReferences, locale: appLocale)) {
                        openWindow(id: ReferenceArticleViewerWindow.windowID)
                    }
                }
                .controlSize(.regular)

                HStack(spacing: 8) {
                    LinkRow(title: AppLocalizer.text(.aboutGitHub, locale: appLocale), destination: repositoryURL)

                    Text("|")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    LinkRow(title: AppLocalizer.text(.aboutPrivacy, locale: appLocale), destination: privacyURL)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 28)
        }
        .frame(width: 420, height: 360)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var appVersion: String? {
        guard let version = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String, !version.isEmpty else {
            return nil
        }
        return version
    }
}

private struct LinkRow: View {
    let title: String
    let destination: URL

    var body: some View {
        Link(destination: destination) {
            HStack(spacing: 4) {
                Text(title)
                Image(systemName: "arrow.up.right")
                    .font(.caption2)
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
    }
}
#endif
