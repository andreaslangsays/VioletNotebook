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
                let freqs = tagFrequencies
                let sortedTags = Array(freqs.keys).sorted()
                
                if sortedTags.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "tag.slash")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("Keine Schlagworte gefunden")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        FlowLayout(spacing: 8, lineSpacing: 10) {
                            ForEach(sortedTags, id: \.self) { tag in
                                TagCloudButton(tag: tag, size: fontSize(for: tag, frequencies: freqs)) {
                                    searchQuery = "#\(tag)"
                                    activeTab = 1
                                }
                            }
                        }
                        .padding()
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

    var tagFrequencies: [String: Int] {
        var frequencies: [String: Int] = [:]
        guard let regex = Self.tagRegex else {
            return [:]
        }
        for month in journal.months.values {
            for day in month.days.values {
                let text = day.text
                let range = NSRange(text.startIndex..<text.endIndex, in: text)
                regex.enumerateMatches(in: text, options: [], range: range) { match, _, _ in
                    if let match = match, match.numberOfRanges > 1 {
                        if let r = Range(match.range(at: 1), in: text) {
                            let tag = String(text[r])
                            frequencies[tag, default: 0] += 1
                        }
                    }
                }
            }
        }
        return frequencies
    }

    var extractedTags: [String] {
        return Array(tagFrequencies.keys).sorted()
    }
    
    func fontSize(for tag: String, minSize: CGFloat = 11, maxSize: CGFloat = 24) -> CGFloat {
        return fontSize(for: tag, frequencies: tagFrequencies, minSize: minSize, maxSize: maxSize)
    }
    
    private func fontSize(for tag: String, frequencies: [String: Int], minSize: CGFloat = 11, maxSize: CGFloat = 24) -> CGFloat {
        guard let f = frequencies[tag] else { return minSize }
        let allFreqs = frequencies.values
        guard let minF = allFreqs.min(), let maxF = allFreqs.max() else { return minSize }
        if maxF == minF {
            return (minSize + maxSize) / 2
        } else {
            let ratio = CGFloat(f - minF) / CGFloat(maxF - minF)
            return minSize + ratio * (maxSize - minSize)
        }
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

struct TagCloudButton: View {
    let tag: String
    let size: CGFloat
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Text("#\(tag)")
                .font(.system(size: size, weight: .medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isHovered ? Color.purple.opacity(0.2) : Color.purple.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isHovered ? Color.purple.opacity(0.4) : Color.purple.opacity(0.15), lineWidth: 1)
                )
                .foregroundColor(.purple)
                .scaleEffect(isHovered ? 1.05 : 1.0)
                .animation(.easeOut(duration: 0.2), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
