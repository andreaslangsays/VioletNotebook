import SwiftUI

struct CalendarView: View {
    @Binding var selectedDate: Date
    let entryExists: (Date) -> Bool
    
    @Environment(\.colorScheme) var colorScheme
    @State private var currentMonth: Date = Date()
    
    private let calendar = Calendar.current
    private let daysOfWeek = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]
    
    var body: some View {
        VStack(spacing: 8) {
            // Month controller header
            HStack {
                Button(action: { changeMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text(monthYearString(from: currentMonth))
                    .font(.headline)
                    .foregroundColor(Theme.text(for: colorScheme))
                
                Spacer()
                
                Button(action: { changeMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            
            // Weekday headers
            HStack(spacing: 0) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(Theme.textMuted(for: colorScheme))
                }
            }
            
            // Calendar Grid
            let days = daysInMonth(from: currentMonth)
            let chunks = days.chunked(into: 7)
            
            VStack(spacing: 4) {
                ForEach(0..<chunks.count, id: \.self) { rowIndex in
                    HStack(spacing: 0) {
                        ForEach(0..<chunks[rowIndex].count, id: \.self) { colIndex in
                            let dateOpt = chunks[rowIndex][colIndex]
                            if let date = dateOpt {
                                let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                                let hasEntry = entryExists(date)
                                
                                Button(action: { selectedDate = date }) {
                                    VStack(spacing: 2) {
                                        Text("\(calendar.component(.day, from: date))")
                                            .font(.body)
                                            .foregroundColor(isSelected ? .white : (hasEntry ? Theme.accent(for: colorScheme) : Theme.text(for: colorScheme)))
                                        
                                        Circle()
                                            .fill(isSelected ? .white : Theme.accent(for: colorScheme))
                                            .frame(width: 4, height: 4)
                                            .opacity(hasEntry ? 1.0 : 0.0)
                                    }
                                    .frame(maxWidth: .infinity, minHeight: 32)
                                    .background(isSelected ? Theme.accent(for: colorScheme) : Color.clear)
                                    .cornerRadius(6)
                                }
                                .buttonStyle(.plain)
                            } else {
                                Spacer()
                                    .frame(maxWidth: .infinity, minHeight: 32)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Theme.cardBackground(for: colorScheme))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.border(for: colorScheme), lineWidth: 1)
        )
        .onAppear {
            currentMonth = selectedDate
        }
        .onChange(of: selectedDate) { newDate in
            currentMonth = newDate
        }
    }
    
    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: date)
    }
    
    private func daysInMonth(from date: Date) -> [Date?] {
        guard let monthRange = calendar.range(of: .day, in: .month, for: date),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) else { return [] }
        
        let weekdayOfFirst = calendar.component(.weekday, from: firstOfMonth)
        // Adjust weekday index to start with Monday (1=Mo, 7=So)
        let offset = (weekdayOfFirst + 5) % 7
        
        var days: [Date?] = Array(repeating: nil, count: offset)
        
        for day in 1...monthRange.count {
            if let dayDate = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(dayDate)
            }
        }
        
        while days.count % 7 != 0 {
            days.append(nil)
        }
        
        return days
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
