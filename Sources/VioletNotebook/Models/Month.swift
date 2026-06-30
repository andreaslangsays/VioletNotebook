import Foundation

struct Month {
    let year: Int
    let month: Int
    var days: [Int: DayData] = [:]
    
    var isEmpty: Bool {
        days.values.allSatisfy { $0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
    
    var filename: String {
        String(format: "%04d-%02d.txt", year, month)
    }
}
