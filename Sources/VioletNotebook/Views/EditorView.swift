import SwiftUI

struct EditorView: View {
    @Binding var text: String
    
    var body: some View {
        VStack(spacing: 0) {
            // Edit Toolbar
            HStack(spacing: 8) {
                Button(action: { insertMarkup("**", "**") }) {
                    Image(systemName: "bold")
                }
                .buttonStyle(.plain)
                .help("Fett (**)")
                
                Button(action: { insertMarkup("//", "//") }) {
                    Image(systemName: "italic")
                }
                .buttonStyle(.plain)
                .help("Kursiv (//)")
                
                Button(action: { insertMarkup("__", "__") }) {
                    Image(systemName: "underline")
                }
                .buttonStyle(.plain)
                .help("Unterstrichen (__)")
                
                Button(action: { insertMarkup("--", "--") }) {
                    Image(systemName: "strikethrough")
                }
                .buttonStyle(.plain)
                .help("Durchgestrichen (--)")
                
                Divider().frame(height: 16)
                
                Button(action: { insertLine() }) {
                    Image(systemName: "minus")
                }
                .buttonStyle(.plain)
                .help("Linie einfügen")
                
                Spacer()
            }
            .padding(8)
            .background(Theme.sidebarBackground)
            
            Divider()
            
            // Text Area
            TextEditor(text: $text)
                .font(.system(.body, design: .monospaced))
                .padding(4)
                .scrollContentBackground(.hidden)
                .background(Theme.background)
                .foregroundColor(Theme.text)
            
            Divider()
            
            // Status Bar
            HStack {
                Text("Worte: \(wordCount) | Zeichen: \(text.count)")
                    .font(.caption)
                    .foregroundColor(Theme.textMuted)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Theme.sidebarBackground)
        }
    }
    
    var wordCount: Int {
        text.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
    }
    
    func insertMarkup(_ prefix: String, _ suffix: String) {
        // Simplistic fallback editor insertion
        text += prefix + "text" + suffix
    }
    
    func insertLine() {
        text += "\n====================\n"
    }
}
