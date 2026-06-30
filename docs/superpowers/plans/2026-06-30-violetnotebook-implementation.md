# VioletNotebook Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a 100% compatible native macOS SwiftUI re-implementation of RedNotebook called VioletNotebook.

**Architecture:** A three-pane macOS application built as a Swift Package Manager executable project. It uses the `Yams` library for parsing/saving `YYYY-MM.txt` files and rendering txt2tags to HTML using `WKWebView`.

**Tech Stack:** Swift 5.9+, SwiftUI, WKWebView, Yams (YAML parser).

## Global Constraints

- Native Swift and SwiftUI for macOS 13+ only.
- Strict 100% compatibility with RedNotebook's file format.
- No modifications or corruption to existing YAML values when loading or saving.
- Premium styling using native macOS fonts (Inter/system), HSL tailored colors (primarily shades of violet), and clean layouts.
- TDD approach: core logic, parsers, and file management must be covered by automated tests.

---

### Task 1: Swift Package Setup & Configuration Model

**Files:**
- Create: `Package.swift`
- Create: `Sources/VioletNotebook/Models/Config.swift`
- Test: `Tests/VioletNotebookTests/ConfigTests.swift`

**Interfaces:**
- Consumes: None
- Produces: `Config` struct mapping `key=value` files to a dictionary representation.

- [ ] **Step 1: Create Package.swift**
  Create `Package.swift` at the root of the workspace. Add Yams as a dependency.
  ```swift
  // swift-tools-version: 5.9
  import PackageDescription

  let package = Package(
      name: "VioletNotebook",
      platforms: [.macOS(.v13)],
      products: [
          .executable(name: "VioletNotebook", targets: ["VioletNotebook"])
      ],
      dependencies: [
          .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.6")
      ],
      targets: [
          .executableTarget(
              name: "VioletNotebook",
              dependencies: ["Yams"],
              path: "Sources/VioletNotebook"
          ),
          .testTarget(
              name: "VioletNotebookTests",
              dependencies: ["VioletNotebook"],
              path: "Tests/VioletNotebookTests"
          )
      ]
  )
  ```

- [ ] **Step 2: Create a failing test for Config loading**
  Create `Tests/VioletNotebookTests/ConfigTests.swift` to verify parsing of a raw configuration file.
  ```swift
  import XCTest
  @testable import VioletNotebook

  final class ConfigTests: XCTestCase {
      func testConfigParsing() throws {
          let rawConfig = """
          # RedNotebook Config
          spellcheck=1
          autoSwitchMode=0
          previewFont=Helvetica, sans-serif
          """
          
          let config = try Config.parse(rawConfig)
          XCTAssertEqual(config["spellcheck"], "1")
          XCTAssertEqual(config["autoSwitchMode"], "0")
          XCTAssertEqual(config["previewFont"], "Helvetica, sans-serif")
      }
      
      func testConfigSerialization() throws {
          var config = Config()
          config["spellcheck"] = "1"
          config["previewFont"] = "Helvetica, sans-serif"
          
          let serialized = config.serialize()
          XCTAssertTrue(serialized.contains("spellcheck=1"))
          XCTAssertTrue(serialized.contains("previewFont=Helvetica, sans-serif"))
      }
  }
  ```

- [ ] **Step 3: Run the test to ensure it fails**
  Run: `swift test --filter ConfigTests`
  Expected: Compile failure (Config not defined).

- [ ] **Step 4: Implement minimal Config model**
  Create `Sources/VioletNotebook/Models/Config.swift`.
  ```swift
  import Foundation

  struct Config {
      var settings: [String: String] = [:]
      
      subscript(key: String) -> String? {
          get { settings[key] }
          set { settings[key] = newValue }
      }
      
      static func parse(_ raw: String) throws -> Config {
          var settings: [String: String] = [:]
          let lines = raw.components(separatedBy: .newlines)
          for line in lines {
              let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
              if trimmed.isEmpty || trimmed.hasPrefix("#") {
                  continue
              }
              let parts = trimmed.split(separator: "=", maxSplits: 1)
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
  ```

- [ ] **Step 5: Verify the test passes**
  Run: `swift test --filter ConfigTests`
  Expected: PASS.

- [ ] **Step 6: Commit**
  Run: `git add Package.swift Sources/VioletNotebook/Models/Config.swift Tests/VioletNotebookTests/ConfigTests.swift && git commit -m "feat: add config parsing and serialization"`

---

### Task 2: YAML Models (Day, Month) and Compatibility

**Files:**
- Create: `Sources/VioletNotebook/Models/Day.swift`
- Create: `Sources/VioletNotebook/Models/Month.swift`
- Test: `Tests/VioletNotebookTests/ModelTests.swift`

**Interfaces:**
- Consumes: Yams library.
- Produces: `Day` and `Month` structs that serialize/deserialize exact RedNotebook YAML contents.

- [ ] **Step 1: Create tests for Day/Month YAML compatibility**
  Create `Tests/VioletNotebookTests/ModelTests.swift` with sample YAML that contains text and dynamic tags.
  ```swift
  import XCTest
  import Yams
  @testable import VioletNotebook

  final class ModelTests: XCTestCase {
      func testMonthParsingWithComplexYAML() throws {
          let yamlData = """
          15:
            text: "Today was a productive day. #project #work"
            Arbeit:
              Task 1: null
              Task 2: null
          18:
            text: "Just chilled."
          """
          
          let decoder = YAMLDecoder()
          let monthContent = try decoder.decode([Int: DayData].self, from: yamlData)
          
          XCTAssertEqual(monthContent[15]?.text, "Today was a productive day. #project #work")
          XCTAssertEqual(monthContent[18]?.text, "Just chilled.")
          XCTAssertEqual(monthContent[15]?.extraCategories?["Arbeit"]?["Task 1"], nil)
          XCTAssertEqual(monthContent[15]?.extraCategories?["Arbeit"]?.keys.sorted(), ["Task 1", "Task 2"])
      }

      func testMonthSerialization() throws {
          var dayData = DayData(text: "Hello #world")
          dayData.extraCategories = ["Coding": ["SwiftUI": nil]]
          let monthData = [1: dayData]
          
          let encoder = YAMLEncoder()
          let yamlString = try encoder.encode(monthData)
          
          // Verify that it contains both text and categories in correct layout
          XCTAssertTrue(yamlString.contains("text: \"Hello #world\"") || yamlString.contains("text: Hello #world"))
          XCTAssertTrue(yamlString.contains("Coding:"))
          XCTAssertTrue(yamlString.contains("SwiftUI: null"))
      }
  }
  ```

- [ ] **Step 2: Run test to verify it fails**
  Run: `swift test --filter ModelTests`
  Expected: FAIL with compilation errors (DayData not defined).

- [ ] **Step 3: Implement Day/Month Models**
  Create `Sources/VioletNotebook/Models/Day.swift` containing `DayData` and dynamic tag parsing.
  ```swift
  import Foundation

  struct DayData: Codable, Equatable {
      var text: String
      var extraCategories: [String: [String: String?]]?
      
      init(text: String, extraCategories: [String: [String: String?]]? = nil) {
          self.text = text
          self.extraCategories = extraCategories
      }
      
      struct DynamicCodingKeys: CodingKey {
          var stringValue: String
          init?(stringValue: String) {
              self.stringValue = stringValue
          }
          var intValue: Int?
          init?(intValue: Int) { return nil }
      }
      
      init(from decoder: Decoder) throws {
          let container = try decoder.container(keyedBy: DynamicCodingKeys.self)
          self.text = try container.decode(String.self, forKey: DynamicCodingKeys(stringValue: "text")!)
          
          var extra: [String: [String: String?]] = [:]
          for key in container.allKeys {
              if key.stringValue != "text" {
                  if let dict = try? container.decode([String: String?].self, forKey: key) {
                      extra[key.stringValue] = dict
                  } else if let isNull = try? container.decodeNil(forKey: key), isNull {
                      extra[key.stringValue] = [:]
                  }
              }
          }
          self.extraCategories = extra.isEmpty ? nil : extra
      }
      
      func encode(to encoder: Encoder) throws {
          var container = encoder.container(keyedBy: DynamicCodingKeys.self)
          try container.encode(text, forKey: DynamicCodingKeys(stringValue: "text")!)
          
          if let extra = extraCategories {
              for (category, subEntries) in extra {
                  try container.encode(subEntries, forKey: DynamicCodingKeys(stringValue: category)!)
              }
          }
      }
  }
  ```
  Create `Sources/VioletNotebook/Models/Month.swift`.
  ```swift
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
  ```

- [ ] **Step 4: Run test to verify it passes**
  Run: `swift test --filter ModelTests`
  Expected: PASS.

- [ ] **Step 5: Commit**
  Run: `git add Sources/VioletNotebook/Models/Day.swift Sources/VioletNotebook/Models/Month.swift Tests/VioletNotebookTests/ModelTests.swift && git commit -m "feat: add Day and Month models with custom YAML coding keys"`

---

### Task 3: Journal Manager with Directory Access

**Files:**
- Create: `Sources/VioletNotebook/Models/Journal.swift`
- Test: `Tests/VioletNotebookTests/JournalTests.swift`

**Interfaces:**
- Consumes: `Month`, `DayData`, `Config`, `Yams`.
- Produces: `Journal` class managing folder loads, saves, and security bookmarks.

- [ ] **Step 1: Write tests for Journal loading & saving**
  Create `Tests/VioletNotebookTests/JournalTests.swift`.
  ```swift
  import XCTest
  @testable import VioletNotebook

  final class JournalTests: XCTestCase {
      var tempDir: URL!
      
      override func setUp() {
          super.setUp()
          tempDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
          try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
      }
      
      override func tearDown() {
          try? FileManager.default.removeItem(at: tempDir)
          super.tearDown()
      }
      
      func testJournalLoadAndSave() throws {
          let journal = Journal(directory: tempDir)
          XCTAssertTrue(journal.months.isEmpty)
          
          // Save a day entry
          try journal.saveEntry(text: "Hello #swift", date: DateComponents(year: 2026, month: 6, day: 30))
          
          // Reload journal from disk
          let journal2 = Journal(directory: tempDir)
          try journal2.loadAll()
          
          let day = journal2.entry(for: DateComponents(year: 2026, month: 6, day: 30))
          XCTAssertEqual(day?.text, "Hello #swift")
      }
  }
  ```

- [ ] **Step 2: Run test to verify it fails**
  Run: `swift test --filter JournalTests`
  Expected: FAIL (Journal not defined).

- [ ] **Step 3: Implement Journal Manager**
  Create `Sources/VioletNotebook/Models/Journal.swift`.
  ```swift
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
              self.config = (try? Config.parse(raw)) ?? Config()
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
          
          if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
              m.days.removeValue(forKey: day)
          } else {
              m.days[day] = d
          }
          
          months[k] = m
          
          // Save month back to file
          let file = directory.appendingPathComponent(m.filename)
          if m.days.isEmpty {
              try? FileManager.default.removeItem(at: file)
          } else {
              let encoder = YAMLEncoder()
              let yamlString = try encoder.encode(m.days)
              try yamlString.write(to: file, atomically: true, encoding: .utf8)
          }
      }
  }
  ```

- [ ] **Step 4: Run test to verify it passes**
  Run: `swift test --filter JournalTests`
  Expected: PASS.

- [ ] **Step 5: Commit**
  Run: `git add Sources/VioletNotebook/Models/Journal.swift Tests/VioletNotebookTests/JournalTests.swift && git commit -m "feat: implement Journal loading/saving"`

---

### Task 4: txt2tags Parser

**Files:**
- Create: `Sources/VioletNotebook/Parser/Txt2TagsParser.swift`
- Test: `Tests/VioletNotebookTests/ParserTests.swift`

**Interfaces:**
- Consumes: raw markdown/txt2tags String.
- Produces: formatted HTML String.

- [ ] **Step 1: Create parser tests**
  Create `Tests/VioletNotebookTests/ParserTests.swift`.
  ```swift
  import XCTest
  @testable import VioletNotebook

  final class ParserTests: XCTestCase {
      func testBasicFormatting() {
          let raw = "This is **bold** and //italic// and __underlined__ and --stricken--."
          let html = Txt2TagsParser.toHTML(raw)
          XCTAssertEqual(html, "<p>This is <b>bold</b> and <i>italic</i> and <u>underlined</u> and <s>stricken</s>.</p>")
      }
      
      func testTitles and Lines() {
          let raw = """
          = Main H1 =
          == Sub H2 ==
          ====================
          """
          let html = Txt2TagsParser.toHTML(raw)
          XCTAssertTrue(html.contains("<h1>Main H1</h1>"))
          XCTAssertTrue(html.contains("<h2>Sub H2</h2>"))
          XCTAssertTrue(html.contains("<hr />"))
      }
      
      func testLinksAndHashtags() {
          let raw = "Check [Google \"\"https://google.com\"\"] and #swift tag."
          let html = Txt2TagsParser.toHTML(raw)
          XCTAssertTrue(html.contains("<a href=\"https://google.com\">Google</a>"))
          XCTAssertTrue(html.contains("<span class=\"hashtag\">#swift</span>"))
      }
  }
  ```

- [ ] **Step 2: Run test to verify it fails**
  Run: `swift test --filter ParserTests`
  Expected: FAIL.

- [ ] **Step 3: Implement Parser**
  Create `Sources/VioletNotebook/Parser/Txt2TagsParser.swift`.
  ```swift
  import Foundation

  struct Txt2TagsParser {
      static func toHTML(_ raw: String) -> String {
          var result = ""
          let lines = raw.components(separatedBy: .newlines)
          var inList = false
          
          for line in lines {
              var trimmed = line.trimmingCharacters(in: .whitespaces)
              
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
  ```

- [ ] **Step 4: Run test to verify it passes**
  Run: `swift test --filter ParserTests`
  Expected: PASS.

- [ ] **Step 5: Commit**
  Run: `git add Sources/VioletNotebook/Parser/Txt2TagsParser.swift Tests/VioletNotebookTests/ParserTests.swift && git commit -m "feat: add txt2tags parser with HTML generation"`

---

### Task 5: Web Preview & Custom Calendar Views

**Files:**
- Create: `Sources/VioletNotebook/Views/PreviewWebView.swift`
- Create: `Sources/VioletNotebook/Views/CalendarView.swift`

**Interfaces:**
- Consumes: HTML strings (PreviewWebView), entry presence data (CalendarView).
- Produces: Native AppKit/WKWebView wrappers and customized calendar UI grid.

- [ ] **Step 1: Implement PreviewWebView wrapper**
  Create `Sources/VioletNotebook/Views/PreviewWebView.swift` with HTML stylesheet and violet accents.
  ```swift
  import SwiftUI
  import WebKit

  struct PreviewWebView: NSViewRepresentable {
      let htmlContent: String
      let onDayLinkClick: (String) -> Void
      
      func makeNSView(context: Context) -> WKWebView {
          let webView = WKWebView()
          webView.navigationDelegate = context.coordinator
          return webView
      }
      
      func updateNSView(_ nsView: WKWebView, context: Context) {
          let styledHtml = """
          <html>
          <head>
          <style>
          body {
              font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
              font-size: 14px;
              line-height: 1.6;
              padding: 16px;
              background-color: transparent;
              color: #333333;
          }
          @media (prefers-color-scheme: dark) {
              body { color: #f5f5f5; }
          }
          h1, h2, h3 { color: #5a2d82; }
          @media (prefers-color-scheme: dark) {
              h1, h2, h3 { color: #b18ce4; }
          }
          a { color: #7f34c2; text-decoration: none; }
          a:hover { text-decoration: underline; }
          .hashtag {
              color: #a855f7;
              font-weight: 500;
          }
          hr { border: 0; border-top: 1px solid #e2e8f0; margin: 16px 0; }
          @media (prefers-color-scheme: dark) {
              hr { border-top: 1px solid #475569; }
          }
          </style>
          </head>
          <body>
          \(htmlContent)
          </body>
          </html>
          """
          nsView.loadHTMLString(styledHtml, baseURL: nil)
      }
      
      func makeCoordinator() -> Coordinator {
          Coordinator(self)
      }
      
      class Coordinator: NSObject, WKNavigationDelegate {
          var parent: PreviewWebView
          
          init(_ parent: PreviewWebView) {
              self.parent = parent
          }
          
          func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
              if let url = navigationAction.request.url {
                  if url.scheme == "violet" && url.host == "day" {
                      let dateStr = url.lastPathComponent
                      parent.onDayLinkClick(dateStr)
                      decisionHandler(.cancel)
                      return
                  } else if url.scheme != "about" {
                      NSWorkspace.shared.open(url)
                      decisionHandler(.cancel)
                      return
                  }
              }
              decisionHandler(.allow)
          }
      }
  }
  ```

- [ ] **Step 2: Implement CalendarView**
  Create `Sources/VioletNotebook/Views/CalendarView.swift` to build a custom calendar grid highlighting days with entries.
  ```swift
  import SwiftUI

  struct CalendarView: View {
      @Binding var selectedDate: Date
      let entryExists: (Date) -> Bool
      
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
                      .foregroundColor(.primary)
                  
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
                          .foregroundColor(.secondary)
                  }
              }
              
              // Calendar Grid
              let days = daysInMonth(from: currentMonth)
              let chunks = days.chunked(into: 7)
              
              VStack(spacing: 4) {
                  ForEach(0..<chunks.count, id: \.self) { rowIndex in
                      HStack(spacing: 0) {
                          ForEach(chunks[rowIndex], id: \.self) { dateOpt in
                              if let date = dateOpt {
                                  let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                                  let hasEntry = entryExists(date)
                                  
                                  Button(action: { selectedDate = date }) {
                                      VStack(spacing: 2) {
                                          Text("\(calendar.component(.day, from: date))")
                                              .font(.body)
                                              .foregroundColor(isSelected ? .white : .primary)
                                          
                                          Circle()
                                              .fill(isSelected ? .white : Color.purple)
                                              .frame(width: 4, height: 4)
                                              .opacity(hasEntry ? 1.0 : 0.0)
                                      }
                                      .frame(maxWidth: .infinity, minHeight: 32)
                                      .background(isSelected ? Color.purple : Color.clear)
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
          .background(Color(NSColor.controlBackgroundColor))
          .cornerRadius(12)
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
  ```

- [ ] **Step 3: Commit**
  Run: `git add Sources/VioletNotebook/Views/PreviewWebView.swift Sources/VioletNotebook/Views/CalendarView.swift && git commit -m "feat: add PreviewWebView wrapper and custom CalendarView grid"`

---

### Task 6: Sidebar & Detailed Editor Layout

**Files:**
- Create: `Sources/VioletNotebook/Views/SidebarView.swift`
- Create: `Sources/VioletNotebook/Views/EditorView.swift`

**Interfaces:**
- Consumes: `Journal`, selected date bindings, insertion bindings.
- Produces: Sidebar list for Tags/Templates/Search and Editor rich view.

- [ ] **Step 1: Implement EditorView**
  Create `Sources/VioletNotebook/Views/EditorView.swift` with standard keyboard additions and a status bar helper.
  ```swift
  import SwiftUI

  struct EditorView: View {
      @Binding var text: String
      
      var body: some View {
          VStack(spacing: 0) {
              // Edit Toolbar
              HStack(spacing: 8) {
                  Button(action: { insertMarkup("**", "**") }) {
                      Image(systemName: "bold")
                  }
                  .help("Fett (**)")
                  
                  Button(action: { insertMarkup("//", "//") }) {
                      Image(systemName: "italic")
                  }
                  .help("Kursiv (//)")
                  
                  Button(action: { insertMarkup("__", "__") }) {
                      Image(systemName: "underline")
                  }
                  .help("Unterstrichen (__)")
                  
                  Button(action: { insertMarkup("--", "--") }) {
                      Image(systemName: "strikethrough")
                  }
                  .help("Durchgestrichen (--)")
                  
                  Divider().frame(height: 16)
                  
                  Button(action: { insertLine() }) {
                      Image(systemName: "minus")
                  }
                  .help("Linie einfügen")
                  
                  Spacer()
              }
              .padding(8)
              .background(Color(NSColor.windowBackgroundColor))
              
              // Text Area
              TextEditor(text: $text)
                  .font(.system(.body, design: .monospaced))
                  .padding(4)
              
              // Status Bar
              HStack {
                  Text("Worte: \(wordCount) | Zeichen: \(text.count)")
                      .font(.caption)
                      .foregroundColor(.secondary)
                  Spacer()
              }
              .padding(.horizontal, 12)
              .padding(.vertical, 4)
              .background(Color(NSColor.windowBackgroundColor))
          }
      }
      
      private var wordCount: Int {
          text.split(separator: { $0.isWhitespace || $0.isNewline }).count
      }
      
      private func insertMarkup(_ prefix: String, _ suffix: String) {
          // Simplistic fallback editor insertion
          text += prefix + "text" + suffix
      }
      
      private func insertLine() {
          text += "\n====================\n"
      }
  }
  ```

- [ ] **Step 2: Implement SidebarView**
  Create `Sources/VioletNotebook/Views/SidebarView.swift` with list filters.
  ```swift
  import SwiftUI

  struct SidebarView: View {
      @ObservedObject var journal: Journal
      @Binding var selectedDate: Date
      @Binding var editorText: String
      
      @State private var activeTab = 0
      @State private var searchQuery = ""
      
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
                  VStack {
                      TextField("Suchen...", text: $searchQuery)
                          .textFieldStyle(.roundedBorder)
                          .padding(.horizontal)
                      
                      List(searchResults, id: \.date) { result in
                          Button(action: { selectDate(result.date) }) {
                              VStack(alignment: .leading) {
                                  Text(result.dateString)
                                      .font(.headline)
                                  Text(result.snippet)
                                      .font(.caption)
                                      .foregroundColor(.secondary)
                                      .lineLimit(1)
                              }
                          }
                          .buttonStyle(.plain)
                      }
                  }
              } else {
                  // Templates list
                  List(templatesList, id: \.name) { template in
                      Button(action: { applyTemplate(template.content) }) {
                          Label(template.name, systemImage: "doc.text")
                      }
                      .buttonStyle(.plain)
                  }
              }
          }
      }
      
      private var extractedTags: [String] {
          var tags: Set<String> = []
          for month in journal.months.values {
              for day in month.days.values {
                  // Scan for #tags
                  let words = day.text.components(separatedBy: .whitespacesAndNewlines)
                  for word in words {
                      if word.hasPrefix("#") && word.count > 1 {
                          tags.insert(String(word.dropFirst()))
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
      
      private var searchResults: [SearchResult] {
          guard !searchQuery.isEmpty else { return [] }
          var results: [SearchResult] = []
          let formatter = DateFormatter()
          formatter.dateFormat = "yyyy-MM-dd"
          
          for (monthKey, month) in journal.months {
              for (dayKey, day) in month.days {
                  if day.text.localizedCaseInsensitiveContains(searchQuery) {
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
      
      private var templatesList: [TemplateItem] {
          // Default list of built-in templates
          return [
              TemplateItem(name: "Meeting", content: "=== Meeting ===\n**Thema:** \n**Teilnehmer:** \n**Ergebnisse:**\n"),
              TemplateItem(name: "Telefonat", content: "=== Telefonat ===\n- **Teilnehmer:** \n- **Besprochen:** \n- **Aktionen:**\n"),
              TemplateItem(name: "Tagesplan", content: "=== Tagesplan ===\n+ [ ] Task 1\n+ [ ] Task 2\n")
          ]
      }
      
      private func selectDate(_ date: Date) {
          selectedDate = date
      }
      
      private func applyTemplate(_ content: String) {
          editorText += "\n" + content
      }
  }
  ```

- [ ] **Step 3: Commit**
  Run: `git add Sources/VioletNotebook/Views/SidebarView.swift Sources/VioletNotebook/Views/EditorView.swift && git commit -m "feat: implement SidebarView widgets and EditorView content"`

---

### Task 7: Main App Assembly & View Layout Integration

**Files:**
- Create: `Sources/VioletNotebook/Views/MainView.swift`
- Create: `Sources/VioletNotebook/VioletNotebookApp.swift`

**Interfaces:**
- Consumes: All views and models.
- Produces: Executable SwiftUI GUI App entrypoint.

- [ ] **Step 1: Implement MainView**
  Create `Sources/VioletNotebook/Views/MainView.swift` coordinating folder load, navigation toggles, and sync.
  ```swift
  import SwiftUI

  struct MainView: View {
      @StateObject var journal: Journal
      @State private var selectedDate = Date()
      @State private var isEditMode = true
      @State private var editorText = ""
      @State private var showFolderPicker = false
      
      var body: some View {
          NavigationSplitView {
              SidebarView(journal: journal, selectedDate: $selectedDate, editorText: $editorText)
                  .frame(minWidth: 260, maxWidth: 320)
          } detail: {
              VStack(spacing: 0) {
                  // Detail Top Header
                  HStack {
                      Button(action: { moveDay(by: -1) }) {
                          Image(systemName: "chevron.left")
                      }
                      Button(action: { selectedDate = Date() }) {
                          Text("Heute")
                      }
                      Button(action: { moveDay(by: 1) }) {
                          Image(systemName: "chevron.right")
                      }
                      
                      Spacer()
                      
                      Text(formattedDate(selectedDate))
                          .font(.title3)
                          .fontWeight(.semibold)
                      
                      Spacer()
                      
                      Picker("", selection: $isEditMode) {
                          Text("Edit").tag(true)
                          Text("Vorschau").tag(false)
                      }
                      .pickerStyle(.segmented)
                      .frame(width: 140)
                  }
                  .padding()
                  .background(Color(NSColor.windowBackgroundColor))
                  
                  Divider()
                  
                  if isEditMode {
                      EditorView(text: $editorText)
                          .onChange(of: editorText) { newText in
                              saveCurrentDay(text: newText)
                          }
                  } else {
                      PreviewWebView(htmlContent: Txt2TagsParser.toHTML(editorText), onDayLinkClick: { dateStr in
                          let formatter = DateFormatter()
                          formatter.dateFormat = "yyyy-MM-dd"
                          if let date = formatter.date(from: dateStr) {
                              selectedDate = date
                          }
                      })
                  }
              }
              .background(Color(NSColor.controlBackgroundColor))
          }
          .toolbar {
              ToolbarItem(placement: .primaryAction) {
                  Button(action: { showFolderPicker = true }) {
                      Label("Tagebuch öffnen", systemImage: "folder.badge.plus")
                  }
              }
          }
          .sheet(isPresented: $showFolderPicker) {
              VStack(spacing: 20) {
                  Text("Tagebuch-Ordner auswählen")
                      .font(.headline)
                  Text("Wähle das Verzeichnis aus, in dem deine RedNotebook-Einträge liegen.")
                      .font(.subheadline)
                      .foregroundColor(.secondary)
                      .multilineTextAlignment(.center)
                      .padding(.horizontal)
                  
                  Button("Ordner wählen...") {
                      selectFolder()
                  }
                  .buttonStyle(.borderedProminent)
                  .controlSize(.large)
              }
              .padding()
              .frame(width: 350, height: 200)
          }
          .onAppear {
              loadSavedFolder()
          }
          .onChange(of: selectedDate) { newDate in
              loadCurrentDay(date: newDate)
          }
      }
      
      private func moveDay(by offset: Int) {
          if let newDate = Calendar.current.date(byAdding: .day, value: offset, to: selectedDate) {
              selectedDate = newDate
          }
      }
      
      private func formattedDate(_ date: Date) -> String {
          let formatter = DateFormatter()
          formatter.dateStyle = .full
          return formatter.string(from: date)
      }
      
      private func loadCurrentDay(date: Date) {
          let comps = Calendar.current.dateComponents([.year, .month, .day], from: date)
          editorText = journal.entry(for: comps)?.text ?? ""
      }
      
      private func saveCurrentDay(text: String) {
          let comps = Calendar.current.dateComponents([.year, .month, .day], from: selectedDate)
          try? journal.saveEntry(text: text, date: comps)
      }
      
      private func selectFolder() {
          let panel = NSOpenPanel()
          panel.allowsMultipleSelection = false
          panel.canChooseDirectories = true
          panel.canChooseFiles = false
          
          if panel.runModal() == .OK, let url = panel.url {
              // Resolve bookmark
              if let bookmark = try? url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil) {
                  UserDefaults.standard.set(bookmark, forKey: "journalFolderBookmark")
              }
              UserDefaults.standard.set(url.path, forKey: "journalFolderPath")
              
              // Load
              showFolderPicker = false
              journal.months.removeAll()
              let newJournal = Journal(directory: url)
              try? newJournal.loadAll()
              journal.months = newJournal.months
              journal.config = newJournal.config
              loadCurrentDay(date: selectedDate)
          }
      }
      
      private func loadSavedFolder() {
          if let bookmarkData = UserDefaults.standard.data(forKey: "journalFolderBookmark") {
              var isStale = false
              if let url = try? URL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale) {
                  _ = url.startAccessingSecurityScopedResource()
                  try? journal.loadAll()
                  loadCurrentDay(date: selectedDate)
                  return
              }
          }
          
          // No bookmark saved, prompt picker
          showFolderPicker = true
      }
  }
  ```

- [ ] **Step 2: Create Main Entrypoint**
  Create `Sources/VioletNotebook/VioletNotebookApp.swift`.
  ```swift
  import SwiftUI

  @main
  struct VioletNotebookApp: App {
      // Temporary stub path during initial startup
      @StateObject private var journal = Journal(directory: URL(fileURLWithPath: NSHomeDirectory()))
      
      var body: some Scene {
          WindowGroup {
              MainView(journal: journal)
                  .frame(minWidth: 900, minHeight: 600)
          }
          .commands {
              SidebarCommands()
          }
      }
  }
  ```

- [ ] **Step 3: Run full compiler check & tests**
  Run: `swift test`
  Expected: All tests pass.

- [ ] **Step 4: Commit**
  Run: `git add Sources/VioletNotebook/Views/MainView.swift Sources/VioletNotebook/VioletNotebookApp.swift && git commit -m "feat: complete application assembly and setup app entrypoint"`

---

## Verification Plan

### Automated Tests
- Test configuration parsing and writing: `swift test --filter ConfigTests`
- Test YAML loading, mapping and saving matching RedNotebook format: `swift test --filter ModelTests`
- Test txt2tags translation outputs: `swift test --filter ParserTests`
- Test full model and system lifecycle: `swift test`

### Manual Verification
- Launch the application: `swift run VioletNotebook`
- Verify folder selection prompts successfully on startup.
- Choose a directory, verify it creates YAML log files on edits.
- Add formatted elements (`**bold**`, lists) and check Web Preview.
- Select a template and verify text inserts correctly in the editor area.
