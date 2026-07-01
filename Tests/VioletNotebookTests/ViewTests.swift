import XCTest
import SwiftUI
@testable import VioletNotebook

@MainActor
final class ViewTests: XCTestCase {
    func testPreviewWebViewInitialization() {
        var clickedDay: String? = nil
        let webView = PreviewWebView(htmlContent: "<p>Hello</p>") { day in
            clickedDay = day
        }
        XCTAssertEqual(webView.htmlContent, "<p>Hello</p>")
        
        let coordinator = webView.makeCoordinator()
        XCTAssertNotNil(coordinator)
        
        // Suppress warning
        XCTAssertNil(clickedDay)
    }
    
    func testCalendarViewInitialization() {
        let date = Date()
        let selectedDate = Binding.constant(date)
        let view = CalendarView(selectedDate: selectedDate) { _ in false }
        XCTAssertNotNil(view)
    }
    
    func testEditorView() {
        var editorText = "Hello world of SwiftUI"
        let binding = Binding(get: { editorText }, set: { editorText = $0 })
        let view = EditorView(text: binding)
        XCTAssertNotNil(view)
        
        // Test word count logic
        XCTAssertEqual(view.wordCount, 4)
        
        // Test text insertion methods
        view.insertMarkup("**", "**")
        XCTAssertEqual(editorText, "Hello world of SwiftUI**text**")
        
        view.insertLine()
        XCTAssertEqual(editorText, "Hello world of SwiftUI**text**\n====================\n")
    }
    
    func testSidebarView() {
        // Setup journal and bindings
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        let journal = Journal(directory: tempDir)
        
        // Add some mock data to journal
        let dayData1 = DayData(text: "Had a meeting with #team about #swift development today. #work")
        let dayData2 = DayData(text: "Working on #swift UI layouts. #ui")
        
        // Set month
        let month = Month(year: 2026, month: 6, days: [
            15: dayData1,
            16: dayData2
        ])
        journal.months["2026-06"] = month
        
        var selectedDate = Date()
        let selectedDateBinding = Binding(get: { selectedDate }, set: { selectedDate = $0 })
        
        var editorText = ""
        let editorTextBinding = Binding(get: { editorText }, set: { editorText = $0 })
        
        let sidebar = SidebarView(journal: journal, selectedDate: selectedDateBinding, editorText: editorTextBinding)
        
        // Test tags extraction logic
        let tags = sidebar.extractedTags
        XCTAssertEqual(tags, ["swift", "team", "ui", "work"])
        
        // Test search logic
        let results = sidebar.searchResults(for: "meeting")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.snippet, "Had a meeting with #team about #swift development today. #work")
        
        // Test select date from search
        if let targetDate = results.first?.date {
            sidebar.selectDate(targetDate)
            let calendar = Calendar.current
            XCTAssertEqual(calendar.component(.day, from: selectedDate), 15)
            XCTAssertEqual(calendar.component(.month, from: selectedDate), 6)
            XCTAssertEqual(calendar.component(.year, from: selectedDate), 2026)
        }
        
        // Test templates list
        let templates = sidebar.templatesList
        XCTAssertFalse(templates.isEmpty)
        XCTAssertEqual(templates.first?.name, "Meeting")
        
        // Test template application
        sidebar.applyTemplate("Hello Template")
        XCTAssertEqual(editorText, "Hello Template")
        
        sidebar.applyTemplate("Line 2")
        XCTAssertEqual(editorText, "Hello Template\nLine 2")
        
        // Cleanup temp dir
        try? FileManager.default.removeItem(at: tempDir)
    }
    
    func testMainViewInitialization() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        let journal = Journal(directory: tempDir)
        let mainView = MainView(journal: journal)
        XCTAssertNotNil(mainView)
    }

    func testTagCloudFrequenciesAndFontSizes() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        let journal = Journal(directory: tempDir)
        let dayData1 = DayData(text: "Had a meeting with #team about #swift development today. #work #swift")
        let dayData2 = DayData(text: "Working on #swift UI layouts. #ui #work")
        
        let month = Month(year: 2026, month: 6, days: [
            15: dayData1,
            16: dayData2
        ])
        journal.months["2026-06"] = month
        
        var selectedDate = Date()
        let selectedDateBinding = Binding(get: { selectedDate }, set: { selectedDate = $0 })
        
        var editorText = ""
        let editorTextBinding = Binding(get: { editorText }, set: { editorText = $0 })
        
        let sidebar = SidebarView(journal: journal, selectedDate: selectedDateBinding, editorText: editorTextBinding)
        
        let freqs = sidebar.tagFrequencies
        XCTAssertEqual(freqs["swift"], 3)
        XCTAssertEqual(freqs["work"], 2)
        XCTAssertEqual(freqs["team"], 1)
        XCTAssertEqual(freqs["ui"], 1)
        
        // 2. Verify font sizes linear scaling (minSize = 11, maxSize = 24)
        XCTAssertEqual(sidebar.fontSize(for: "swift", minSize: 11, maxSize: 24), 24)
        XCTAssertEqual(sidebar.fontSize(for: "work", minSize: 11, maxSize: 24), 17.5)
        XCTAssertEqual(sidebar.fontSize(for: "team", minSize: 11, maxSize: 24), 11)
        XCTAssertEqual(sidebar.fontSize(for: "ui", minSize: 11, maxSize: 24), 11)
        
        // 3. Verify scale calculation doesn't divide by zero if all tags have the same frequency.
        let dayData3 = DayData(text: "#swift #work #team")
        journal.months["2026-06"] = Month(year: 2026, month: 6, days: [15: dayData3])
        let newFreqs = sidebar.tagFrequencies
        XCTAssertEqual(newFreqs["swift"], 1)
        XCTAssertEqual(newFreqs["work"], 1)
        XCTAssertEqual(newFreqs["team"], 1)
        XCTAssertEqual(sidebar.fontSize(for: "swift", minSize: 11, maxSize: 24), 17.5)
        
        // 4. Verify recalculation works cleanly when adding/removing entries.
        let dayData4 = DayData(text: "#swift")
        var currentMonth = journal.months["2026-06"]!
        currentMonth.days[16] = dayData4
        journal.months["2026-06"] = currentMonth
        
        let updatedFreqs = sidebar.tagFrequencies
        XCTAssertEqual(updatedFreqs["swift"], 2)
        XCTAssertEqual(updatedFreqs["work"], 1)
        XCTAssertEqual(updatedFreqs["team"], 1)
        
        XCTAssertEqual(sidebar.fontSize(for: "swift", minSize: 11, maxSize: 24), 24)
        XCTAssertEqual(sidebar.fontSize(for: "work", minSize: 11, maxSize: 24), 11)
        
        try? FileManager.default.removeItem(at: tempDir)
    }
    
    func testStatsDashboardCalculations() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        let journal = Journal(directory: tempDir)
        let statsView = StatsDashboardView(journal: journal)
        
        // 1. Verify empty journal handling
        XCTAssertEqual(statsView.totalEntries, 0)
        XCTAssertEqual(statsView.totalWords, 0)
        XCTAssertEqual(statsView.totalCharacters, 0)
        XCTAssertEqual(statsView.averageLength, 0.0)
        XCTAssertEqual(statsView.longestEntryString, "-")
        XCTAssertEqual(statsView.readingTimeString, "0 Min.")
        
        // 2. Add some entries
        let dayData1 = DayData(text: "Hello world of SwiftUI") // 4 words, 22 chars
        let dayData2 = DayData(text: "Learning Swift is awesome and fun.") // 6 words, 34 chars
        
        let month = Month(year: 2026, month: 6, days: [
            15: dayData1,
            16: dayData2
        ])
        journal.months["2026-06"] = month
        
        // Verify stats with 2 entries
        XCTAssertEqual(statsView.totalEntries, 2)
        XCTAssertEqual(statsView.totalWords, 10)
        XCTAssertEqual(statsView.totalCharacters, 56)
        XCTAssertEqual(statsView.averageLength, 5.0)
        XCTAssertEqual(statsView.longestEntryString, "16.06.2026 (6 Wörter)")
        XCTAssertEqual(statsView.readingTimeString, "Weniger als eine Minute")
        
        // 3. Add a longer entry to test reading time and longest entry update
        // We will create a string with 250 words
        let longText = Array(repeating: "word", count: 250).joined(separator: " ")
        let dayData3 = DayData(text: longText)
        
        var updatedMonth = journal.months["2026-06"]!
        updatedMonth.days[17] = dayData3
        journal.months["2026-06"] = updatedMonth
        
        // Total entries: 3
        // Total words: 10 + 250 = 260
        // Average length: 260 / 3 = 86.666...
        // Longest entry: 17.06.2026 (250 Wörter)
        // Reading time: 260 / 200 = 1.3 minutes -> rounded to 1 Min.
        XCTAssertEqual(statsView.totalEntries, 3)
        XCTAssertEqual(statsView.totalWords, 260)
        XCTAssertEqual(statsView.averageLength, 260.0 / 3.0, accuracy: 0.01)
        XCTAssertEqual(statsView.longestEntryString, "17.06.2026 (250 Wörter)")
        XCTAssertEqual(statsView.readingTimeString, "1 Min.")
        
        // 4. Add another long entry to test 450 words -> 460 total words -> 460 / 200 = 2.3 minutes -> rounded to 2 Min.
        let veryLongText = Array(repeating: "word", count: 450).joined(separator: " ")
        let dayData4 = DayData(text: veryLongText)
        
        updatedMonth.days[18] = dayData4
        journal.months["2026-06"] = updatedMonth
        
        XCTAssertEqual(statsView.totalEntries, 4)
        XCTAssertEqual(statsView.totalWords, 710) // 10 + 250 + 450 = 710
        XCTAssertEqual(statsView.longestEntryString, "18.06.2026 (450 Wörter)")
        XCTAssertEqual(statsView.readingTimeString, "4 Min.") // 710 / 200 = 3.55 -> rounded to 4 Min.
    }
    
    func testExportCompilerTextAndHTML() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let journal = Journal(directory: tempDir)
        let cal = Calendar(identifier: .gregorian)
        
        let d14 = cal.date(from: DateComponents(year: 2026, month: 6, day: 14))!
        let d15 = cal.date(from: DateComponents(year: 2026, month: 6, day: 15))!
        let d16 = cal.date(from: DateComponents(year: 2026, month: 6, day: 16))!
        
        let month = Month(year: 2026, month: 6, days: [
            14: DayData(text: "Day 14 text"),
            15: DayData(text: "Day 15 text"),
            16: DayData(text: "Day 16 text")
        ])
        journal.months["2026-06"] = month
        
        let textOnly15 = ExportCompiler.compileText(from: d15, to: d15, in: journal)
        XCTAssertTrue(textOnly15.contains("=== Montag, 15.06.2026 ==="))
        XCTAssertTrue(textOnly15.contains("Day 15 text"))
        XCTAssertFalse(textOnly15.contains("Day 14 text"))
        XCTAssertFalse(textOnly15.contains("Day 16 text"))
        
        let textAll = ExportCompiler.compileText(from: d14, to: d16, in: journal)
        XCTAssertTrue(textAll.contains("=== Sonntag, 14.06.2026 ==="))
        XCTAssertTrue(textAll.contains("=== Montag, 15.06.2026 ==="))
        XCTAssertTrue(textAll.contains("=== Dienstag, 16.06.2026 ==="))
        
        let htmlContent = ExportCompiler.compileHTML(from: d15, to: d15, in: journal)
        XCTAssertTrue(htmlContent.contains("<!DOCTYPE html>"))
        XCTAssertTrue(htmlContent.contains("Montag, 15.06.2026"))
        XCTAssertTrue(htmlContent.contains("<p>Day 15 text</p>"))
    }
    
    func testExportViewInitialization() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let journal = Journal(directory: tempDir)
        var isPresented = true
        let binding = Binding(get: { isPresented }, set: { isPresented = $0 })
        let view = ExportView(journal: journal, isPresented: binding)
        XCTAssertNotNil(view)
    }
}



