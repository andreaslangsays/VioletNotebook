import Foundation

public struct Month {
    public let year: Int
    public let month: Int
    public var days: [Int: DayData]
    
    public init(year: Int, month: Int, days: [Int: DayData] = [:]) {
        self.year = year
        self.month = month
        self.days = days
    }
    
    public var isEmpty: Bool {
        days.values.allSatisfy { day in
            day.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            (day.extraCategories?.isEmpty ?? true)
        }
    }
    
    public var filename: String {
        String(format: "%04d-%02d.txt", year, month)
    }
}
