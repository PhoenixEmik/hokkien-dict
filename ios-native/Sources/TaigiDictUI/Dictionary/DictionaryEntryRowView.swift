import SwiftUI
import TaigiDictCore

struct DictionaryEntryRowView: View {
    enum LayoutStyle {
        case standard
        case sidebarCompact

        var hanjiLineLimit: Int {
            switch self {
            case .standard:
                return 1
            case .sidebarCompact:
                return 1
            }
        }

        var romanizationLineLimit: Int {
            switch self {
            case .standard:
                return 1
            case .sidebarCompact:
                return 1
            }
        }

        var summaryLineLimit: Int {
            switch self {
            case .standard:
                return 2
            case .sidebarCompact:
                return 1
            }
        }
    }

    var entry: DictionaryEntry
    var layoutStyle: LayoutStyle = .standard

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.hanji)
                .taigiReadingFont(.headline, weight: .semibold)
                .lineLimit(layoutStyle.hanjiLineLimit)
                .truncationMode(.tail)
            Text(entry.romanization)
                .taigiReadingFont(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(layoutStyle.romanizationLineLimit)
                .truncationMode(.tail)
            if !entry.briefSummary.isEmpty {
                Text(entry.briefSummary)
                    .taigiReadingFont(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(layoutStyle.summaryLineLimit)
                    .truncationMode(.tail)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
