import SwiftUI

struct StatsDashboardView: View {
    @ObservedObject var journal: Journal
    
    var entries: [(date: (day: Int, month: Int, year: Int), data: DayData)] {
        var result: [(date: (day: Int, month: Int, year: Int), data: DayData)] = []
        for month in journal.months.values {
            for (day, dayData) in month.days {
                let textEmpty = dayData.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                let categoriesEmpty = dayData.extraCategories?.isEmpty ?? true
                if !textEmpty || !categoriesEmpty {
                    result.append((date: (day: day, month: month.month, year: month.year), data: dayData))
                }
            }
        }
        return result
    }
    
    var totalEntries: Int {
        return entries.count
    }
    
    var totalWords: Int {
        return entries.reduce(0) { sum, entry in
            sum + entry.data.text.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
        }
    }
    
    var totalCharacters: Int {
        return entries.reduce(0) { sum, entry in
            sum + entry.data.text.count
        }
    }
    
    var averageLength: Double {
        let total = totalEntries
        guard total > 0 else { return 0.0 }
        return Double(totalWords) / Double(total)
    }
    
    var longestEntry: (date: String, wordCount: Int)? {
        var longest: (date: String, wordCount: Int)? = nil
        for entry in entries {
            let count = entry.data.text.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
            if let currentLongest = longest {
                if count > currentLongest.wordCount {
                    let dateStr = String(format: "%02d.%02d.%04d", entry.date.day, entry.date.month, entry.date.year)
                    longest = (date: dateStr, wordCount: count)
                }
            } else {
                let dateStr = String(format: "%02d.%02d.%04d", entry.date.day, entry.date.month, entry.date.year)
                longest = (date: dateStr, wordCount: count)
            }
        }
        return longest
    }
    
    var longestEntryString: String {
        if let longest = longestEntry {
            let unit = longest.wordCount == 1 ? "Wort" : "Wörter"
            return "\(longest.date) (\(longest.wordCount) \(unit))"
        } else {
            return "-"
        }
    }
    
    var readingTimeString: String {
        guard totalWords > 0 else { return "0 Min." }
        let minutes = Double(totalWords) / 200.0
        if minutes < 1.0 {
            return "Weniger als eine Minute"
        } else {
            let mins = max(1, Int(round(minutes)))
            return "\(mins) Min."
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Statistiken")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .padding(.bottom, 4)
                
                let columns = [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ]
                
                LazyVGrid(columns: columns, spacing: 12) {
                    StatCard(title: "Einträge gesamt", value: "\(totalEntries)", icon: "book")
                    StatCard(title: "Wörter gesamt", value: "\(totalWords)", icon: "text.alignleft")
                    StatCard(title: "Zeichen gesamt", value: "\(totalCharacters)", icon: "character")
                    StatCard(title: "Ø Länge pro Eintrag", value: totalEntries > 0 ? String(format: "%.1f", averageLength) : "0", icon: "divide")
                    StatCard(title: "Lesezeit", value: readingTimeString, icon: "clock")
                    StatCard(title: "Längster Eintrag", value: longestEntryString, icon: "crown")
                }
            }
            .padding()
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(Color.purple)
                Spacer()
            }
            Spacer(minLength: 0)
            Text(value)
                .font(.system(.title, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.6)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 90, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isHovered ? Color.purple.opacity(0.1) : Color.purple.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isHovered ? Color.purple.opacity(0.3) : Color.purple.opacity(0.12), lineWidth: 1)
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
