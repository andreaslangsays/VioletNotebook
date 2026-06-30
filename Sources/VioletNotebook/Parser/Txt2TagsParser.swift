import Foundation

public struct Txt2TagsParser {
    public static func toHTML(_ raw: String) -> String {
        var result = ""
        let lines = raw.components(separatedBy: .newlines)
        var inList = false
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Skip comments
            if trimmed.hasPrefix("%") { continue }
            
            if trimmed.isEmpty {
                if inList {
                    result += "</ul>\n"
                    inList = false
                }
                continue
            }
            
            // Horizontal Line
            if trimmed.starts(with: "=====") {
                if inList {
                    result += "</ul>\n"
                    inList = false
                }
                result += "<hr />\n"
                continue
            }
            
            // Titles
            if trimmed.hasPrefix("=") && trimmed.hasSuffix("=") {
                if inList {
                    result += "</ul>\n"
                    inList = false
                }
                let level = trimmed.prefix(while: { $0 == "=" }).count
                let titleText = trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "=")).trimmingCharacters(in: .whitespaces)
                result += "<h\(level)>\(titleText)</h\(level)>\n"
                continue
            }
            
            // Lists
            if trimmed.hasPrefix("- ") || trimmed.hasPrefix("+ ") {
                if !inList {
                    result += "<ul>\n"
                    inList = true
                }
                let itemText = String(trimmed.dropFirst(2))
                result += "<li>\(parseInline(itemText))</li>\n"
                continue
            }
            
            // Normal Paragraph
            if inList {
                result += "</ul>\n"
                inList = false
            }
            result += "<p>\(parseInline(trimmed))</p>\n"
        }
        
        if inList {
            result += "</ul>\n"
        }
        
        return result
    }
    
    private static func parseInline(_ text: String) -> String {
        var s = text
        
        // XML escaping for safety
        s = s.replacingOccurrences(of: "&", with: "&amp;")
        s = s.replacingOccurrences(of: "<", with: "&lt;")
        s = s.replacingOccurrences(of: ">", with: "&gt;")
        
        // Bold **text**
        s = parseRegex(s, pattern: "\\*\\*(.*?)\\*\\*", template: "<b>$1</b>")
        // Italic //text//
        s = parseRegex(s, pattern: "//(.*?)//", template: "<i>$1</i>")
        // Underline __text__
        s = parseRegex(s, pattern: "__(.*?)__", template: "<u>$1</u>")
        // Strikethrough --text--
        s = parseRegex(s, pattern: "--(.*?)--", template: "<s>$1</s>")
        
        // Links: [Text ""URL""]
        s = parseRegex(s, pattern: "\\[([^\\]]+?)\\s*\"\"([^\"]+?)\"\"\\]", template: "<a href=\"$2\">$1</a>")
        // Short links/Dates: [2026-06-30]
        s = parseRegex(s, pattern: "\\[(\\d{4}-\\d{2}-\\d{2})\\]", template: "<a href=\"violet://day/$1\">$1</a>")
        // [Text 2026-06-30]
        s = parseRegex(s, pattern: "\\[([^\\]]+?)\\s*(\\d{4}-\\d{2}-\\d{2})\\]", template: "<a href=\"violet://day/$2\">$1</a>")
        
        // Hashtags #tag (alphanumeric starting with letters, excludes HEX colors/C directives)
        s = parseRegex(s, pattern: "(^|\\s)(#[a-zA-Z][a-zA-Z0-9_]*)\\b", template: "$1<span class=\"hashtag\">$2</span>")
        
        return s
    }
    
    private static func parseRegex(_ text: String, pattern: String, template: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return text }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: template)
    }
}
