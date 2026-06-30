import SwiftUI

struct SidebarView: View {
    @ObservedObject var journal: Journal
    @Binding var selectedDate: Date
    @Binding var editorText: String
    
    @State var activeTab = 0
    @State var searchQuery = ""
    
    var body: some View {
        VStack(spacing: 12) {
            CalendarView(selectedDate: $selectedDate, entryExists: { date in
                let comps = Calendar.current.dateComponents([.year, .month, .day], from: date)
                return journal.entry(for: comps) != nil
            })
            
            Picker("", selection: $activeTab) {
                Text("Tags").tag(0)
                Text("Suche").tag(1)
                Text("Templates").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            // Tab contents
            if activeTab == 0 {
                // Tags list
                List(extractedTags, id: \.self) { tag in
                    HStack {
                        Image(systemName: "tag.fill")
                            .foregroundColor(.purple)
                        Text(tag)
                    }
                }
            } else if activeTab == 1 {
                // Search panel
                VStack(spacing: 8) {
                    TextField("Suchen...", text: $searchQuery)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                    
                    List(searchResults(for: searchQuery), id: \.date) { result in
                        Button(action: { selectDate(result.date) }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(result.dateString)
                                    .font(.headline)
                                Text(result.snippet)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            .padding(.vertical, 4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else {
                // Templates list
                List(templatesList, id: \.name) { template in
                    Button(action: { applyTemplate(template.content) }) {
                        Label(template.name, systemImage: "doc.text")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private static let searchDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    private static let tagRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: "(?:^|\\s)#([a-zA-Z][a-zA-Z0-9_]*)\\b", options: [])
    }()

    var extractedTags: [String] {
        var tags: Set<String> = []
        guard let regex = Self.tagRegex else {
            return []
        }
        for month in journal.months.values {
            for day in month.days.values {
                let text = day.text
                let range = NSRange(text.startIndex..<text.endIndex, in: text)
                regex.enumerateMatches(in: text, options: [], range: range) { match, _, _ in
                    if let match = match, match.numberOfRanges > 1 {
                        if let r = Range(match.range(at: 1), in: text) {
                            tags.insert(String(text[r]))
                        }
                    }
                }
            }
        }
        return Array(tags).sorted()
    }
    
    struct SearchResult {
        let date: Date
        let dateString: String
        let snippet: String
    }
    
    func searchResults(for query: String) -> [SearchResult] {
        guard !query.isEmpty else { return [] }
        var results: [SearchResult] = []
        let formatter = Self.searchDateFormatter
        
        for (monthKey, month) in journal.months {
            for (dayKey, day) in month.days {
                if day.text.localizedCaseInsensitiveContains(query) {
                    if let date = formatter.date(from: "\(monthKey)-\(String(format: "%02d", dayKey))") {
                        let snippet = day.text.replacingOccurrences(of: "\n", with: " ")
                        results.append(SearchResult(date: date, dateString: formatter.string(from: date), snippet: snippet))
                    }
                }
            }
        }
        return results.sorted(by: { $0.date > $1.date })
    }
    
    struct TemplateItem {
        let name: String
        let content: String
    }
    
    var templatesList: [TemplateItem] {
        // Default list of built-in templates
        return [
            TemplateItem(name: "Meeting", content: "=== Meeting ===\n**Thema:** \n**Teilnehmer:** \n**Ergebnisse:**\n"),
            TemplateItem(name: "Telefonat", content: "=== Telefonat ===\n- **Teilnehmer:** \n- **Besprochen:** \n- **Aktionen:**\n"),
            TemplateItem(name: "Tagesplan", content: "=== Tagesplan ===\n+ [ ] Task 1\n+ [ ] Task 2\n")
        ]
    }
    
    func selectDate(_ date: Date) {
        selectedDate = date
    }
    
    func applyTemplate(_ content: String) {
        editorText += (editorText.isEmpty ? "" : "\n") + content
    }
}
