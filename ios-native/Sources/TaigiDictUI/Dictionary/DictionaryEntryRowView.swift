import SwiftUI
import TaigiDictCore

struct DictionaryEntryRowView: View {
    var entry: DictionaryEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.hanji)
                .font(.headline)
            Text(entry.romanization)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if !entry.briefSummary.isEmpty {
                Text(entry.briefSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
