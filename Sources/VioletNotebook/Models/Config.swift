import Foundation

struct Config {
    var settings: [String: String] = [:]
    
    subscript(key: String) -> String? {
        get { settings[key] }
        set { settings[key] = newValue }
    }
    
    static func parse(_ raw: String) -> Config {
        var settings: [String: String] = [:]
        let lines = raw.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty || trimmed.hasPrefix("#") {
                continue
            }
            let parts = trimmed.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            if parts.count == 2 {
                let key = String(parts[0]).trimmingCharacters(in: .whitespaces)
                let value = String(parts[1]).trimmingCharacters(in: .whitespaces)
                settings[key] = value
            }
        }
        return Config(settings: settings)
    }
    
    func serialize() -> String {
        var lines = ["# VioletNotebook Configuration"]
        for (key, value) in settings.sorted(by: { $0.key < $1.key }) {
            lines.append("\(key)=\(value)")
        }
        return lines.joined(separator: "\n") + "\n"
    }
}
