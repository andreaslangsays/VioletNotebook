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
}


