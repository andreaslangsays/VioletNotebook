import SwiftUI

struct StatsDashboardView: View {
    @ObservedObject var journal: Journal
    
    struct StatSummary {
        let totalEntries: Int
        let totalWords: Int
        let totalCharacters: Int
        let averageLength: Double
        let longestEntryString: String
        let readingTimeString: String
    }
    
    var stats: StatSummary {
        var entryCount = 0
        var wordCount = 0
        var charCount = 0
        var maxWords = -1
        var maxWordsDate = "-"
        
        for month in journal.months.values {
            for (day, dayData) in month.days {
                let textEmpty = dayData.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                let categoriesEmpty = dayData.extraCategories?.isEmpty ?? true
                if !textEmpty || !categoriesEmpty {
                    entryCount += 1
                    let words = dayData.text.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
                    wordCount += words
                    charCount += dayData.text.count
                    
                    if words > maxWords {
                        maxWords = words
                        maxWordsDate = String(format: "%02d.%02d.%04d", day, month.month, month.year)
                    }
                }
            }
        }
        
        let avg = entryCount > 0 ? Double(wordCount) / Double(entryCount) : 0.0
        
        let longestStr: String
        if maxWords >= 0 {
            let unit = maxWords == 1 ? "Wort" : "Wörter"
            longestStr = "\(maxWordsDate) (\(maxWords) \(unit))"
        } else {
            longestStr = "-"
        }
        
        let readTimeStr: String
        if wordCount > 0 {
            let minutes = Double(wordCount) / 200.0
            if minutes < 1.0 {
                readTimeStr = "Weniger als eine Minute"
            } else {
                let mins = max(1, Int(round(minutes)))
                readTimeStr = "\(mins) Min."
            }
        } else {
            readTimeStr = "0 Min."
        }
        
        return StatSummary(
            totalEntries: entryCount,
            totalWords: wordCount,
            totalCharacters: charCount,
            averageLength: avg,
            longestEntryString: longestStr,
            readingTimeString: readTimeStr
        )
    }
    
    var totalEntries: Int { stats.totalEntries }
    var totalWords: Int { stats.totalWords }
    var totalCharacters: Int { stats.totalCharacters }
    var averageLength: Double { stats.averageLength }
    var longestEntryString: String { stats.longestEntryString }
    var readingTimeString: String { stats.readingTimeString }
    
    var body: some View {
        let currentStats = stats
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
                    StatCard(title: "Einträge gesamt", value: "\(currentStats.totalEntries)", icon: "book")
                    StatCard(title: "Wörter gesamt", value: "\(currentStats.totalWords)", icon: "text.alignleft")
                    StatCard(title: "Zeichen gesamt", value: "\(currentStats.totalCharacters)", icon: "character")
                    StatCard(title: "Ø Länge pro Eintrag", value: currentStats.totalEntries > 0 ? String(format: "%.1f", currentStats.averageLength) : "0", icon: "divide")
                    StatCard(title: "Lesezeit", value: currentStats.readingTimeString, icon: "clock")
                    StatCard(title: "Längster Eintrag", value: currentStats.longestEntryString, icon: "crown")
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
