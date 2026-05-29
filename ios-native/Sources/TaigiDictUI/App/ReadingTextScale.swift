import SwiftUI

private struct TaigiReadingTextScaleKey: EnvironmentKey {
    static let defaultValue = 1.0
}

extension EnvironmentValues {
    var taigiReadingTextScale: Double {
        get { self[TaigiReadingTextScaleKey.self] }
        set { self[TaigiReadingTextScaleKey.self] = newValue }
    }
}

extension View {
    func taigiReadingTextScale(_ scale: Double) -> some View {
        environment(\.taigiReadingTextScale, scale)
    }

    @ViewBuilder
    func taigiReadingFont(
        _ style: Font.TextStyle,
        weight: Font.Weight? = nil
    ) -> some View {
#if os(macOS)
        modifier(MacReadingTextFontModifier(style: style, weight: weight))
#else
        if let weight {
            font(.system(style, weight: weight))
        } else {
            font(.system(style))
        }
#endif
    }
}

#if os(macOS)
private struct MacReadingTextFontModifier: ViewModifier {
    @Environment(\.taigiReadingTextScale) private var readingTextScale

    let style: Font.TextStyle
    let weight: Font.Weight?

    func body(content: Content) -> some View {
        content.font(
            .system(
                size: basePointSize(for: style) * readingTextScale,
                weight: weight
            )
        )
    }

    private func basePointSize(for style: Font.TextStyle) -> CGFloat {
        switch style {
        case .largeTitle:
            return 34
        case .title:
            return 28
        case .title2:
            return 22
        case .title3:
            return 20
        case .headline:
            return 17
        case .subheadline:
            return 15
        case .caption:
            return 12
        case .caption2:
            return 11
        case .footnote:
            return 13
        case .callout:
            return 16
        default:
            return 17
        }
    }
}
#endif
