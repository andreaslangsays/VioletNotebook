import Foundation
import Yams

class Journal: ObservableObject {
    let directory: URL
    @Published var months: [String: Month] = [:]
    @Published var config: Config = Config()
    
    init(directory: URL) {
        self.directory = directory
    }
    
    func key(year: Int, month: Int) -> String {
        return String(format: "%04d-%02d", year, month)
    }
    
    func entry(for date: DateComponents) -> DayData? {
        guard let year = date.year, let month = date.month, let day = date.day else { return nil }
        let k = key(year: year, month: month)
        return months[k]?.days[day]
    }
    
    func loadAll() throws {
        let fm = FileManager.default
        guard fm.fileExists(atPath: directory.path) else { return }
        
        // Load config
        let configFile = directory.appendingPathComponent("configuration.cfg")
        if fm.fileExists(atPath: configFile.path),
           let raw = try? String(contentsOf: configFile, encoding: .utf8) {
            self.config = Config.parse(raw)
        }
        
        // Find month files (format: YYYY-MM.txt)
        let contents = try fm.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        let regex = try NSRegularExpression(pattern: "^(\\d{4})-(\\d{2})\\.txt$")
        
        var loadedMonths: [String: Month] = [:]
        for file in contents {
            let name = file.lastPathComponent
            let range = NSRange(name.startIndex..<name.endIndex, in: name)
            if let match = regex.firstMatch(in: name, range: range) {
                let yearStr = (name as NSString).substring(with: match.range(at: 1))
                let monthStr = (name as NSString).substring(with: match.range(at: 2))
                if let year = Int(yearStr), let month = Int(monthStr) {
                    let k = self.key(year: year, month: month)
                    let rawYAML = try String(contentsOf: file, encoding: .utf8)
                    let decoder = YAMLDecoder()
                    let days = (try? decoder.decode([Int: DayData].self, from: rawYAML)) ?? [:]
                    loadedMonths[k] = Month(year: year, month: month, days: days)
                }
            }
        }
        self.months = loadedMonths
    }
    
    func saveEntry(text: String, date: DateComponents) throws {
        guard let year = date.year, let month = date.month, let day = date.day else { return }
        let k = key(year: year, month: month)
        
        var m = months[k] ?? Month(year: year, month: month)
        var d = m.days[day] ?? DayData(text: "")
        d.text = text
        
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && (d.extraCategories?.isEmpty ?? true) {
            m.days.removeValue(forKey: day)
        } else {
            m.days[day] = d
        }
        
        months[k] = m
        
        // Save month back to file
        let file = directory.appendingPathComponent(m.filename)
        if m.isEmpty {
            try? FileManager.default.removeItem(at: file)
            months.removeValue(forKey: k)
        } else {
            let encoder = YAMLEncoder()
            let yamlString = try encoder.encode(m.days)
            try yamlString.write(to: file, atomically: true, encoding: .utf8)
        }
    }
}
