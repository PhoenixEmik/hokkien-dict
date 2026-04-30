import SwiftUI

struct ReferenceArticleListScreen: View {
    var body: some View {
        List {
            NavigationLink {
                ReferenceArticleScreen(
                    title: "臺羅標注說明",
                    paragraphs: [
                        "臺羅是台語常見拼寫系統，重點在聲調與音節分界。",
                        "搜尋時可輸入有調或無調格式，系統會做正規化處理。",
                    ],
                    bullets: [
                        "可使用連字號分隔音節",
                        "大小寫不影響搜尋",
                        "數字調號會在搜尋正規化中處理",
                    ],
                    tableRows: [
                        ("oo", "o-dot-right"),
                        ("nn", "superscript-n"),
                    ]
                )
            } label: {
                Label("臺羅標注說明", systemImage: "character.book.closed")
            }

            NavigationLink {
                ReferenceArticleScreen(
                    title: "漢字用字原則",
                    paragraphs: [
                        "辭典內容以教育部資料來源為準。",
                        "同音異字、異用字會在詞條中提供對照。",
                    ],
                    bullets: [
                        "優先採用主流教育體系常見用字",
                        "異體與俗字會在詞條標示",
                    ],
                    tableRows: []
                )
            } label: {
                Label("漢字用字原則", systemImage: "textformat.abc")
            }
        }
        .navigationTitle("參考資料")
    }
}

struct ReferenceArticleScreen: View {
    var title: String
    var paragraphs: [String]
    var bullets: [String]
    var tableRows: [(String, String)]

    var body: some View {
        List {
            if !paragraphs.isEmpty {
                Section("內文") {
                    ForEach(paragraphs, id: \.self) { paragraph in
                        Text(paragraph)
                    }
                }
            }

            if !bullets.isEmpty {
                Section("重點") {
                    ForEach(bullets, id: \.self) { bullet in
                        Label(bullet, systemImage: "circle.fill")
                            .symbolRenderingMode(.monochrome)
                            .font(.body)
                    }
                }
            }

            if !tableRows.isEmpty {
                Section("對照") {
                    ForEach(Array(tableRows.enumerated()), id: \.offset) { _, row in
                        LabeledContent(row.0) {
                            Text(row.1)
                        }
                    }
                }
            }
        }
        .navigationTitle(title)
    }
}
