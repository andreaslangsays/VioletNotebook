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
    
    @MainActor
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
    
    @MainActor
    func testJournalLoadConfig() throws {
        // Create configuration.cfg file
        let configURL = tempDir.appendingPathComponent("configuration.cfg")
        let configContent = """
        # Comments are ignored
        theme=dark
        editor_font=Monaco
        """
        try configContent.write(to: configURL, atomically: true, encoding: .utf8)
        
        let journal = Journal(directory: tempDir)
        try journal.loadAll()
        
        XCTAssertEqual(journal.config["theme"], "dark")
        XCTAssertEqual(journal.config["editor_font"], "Monaco")
    }
    
    @MainActor
    func testJournalSaveEmptyEntryDeletesFile() throws {
        let journal = Journal(directory: tempDir)
        let date = DateComponents(year: 2026, month: 6, day: 30)
        
        // Save an entry
        try journal.saveEntry(text: "Some content", date: date)
        let monthURL = tempDir.appendingPathComponent("2026-06.txt")
        XCTAssertTrue(FileManager.default.fileExists(atPath: monthURL.path))
        
        // Save an empty entry
        try journal.saveEntry(text: "", date: date)
        XCTAssertFalse(FileManager.default.fileExists(atPath: monthURL.path))
        XCTAssertNil(journal.entry(for: date))
        XCTAssertTrue(journal.months.isEmpty)
    }
    
    @MainActor
    func testJournalSaveEmptyEntryWithCategoriesKeepsFile() throws {
        let journal = Journal(directory: tempDir)
        let date = DateComponents(year: 2026, month: 6, day: 30)
        let k = journal.key(year: 2026, month: 6)
        
        // Pre-populate months with a day that has categories
        var dayData = DayData(text: "Initial")
        dayData.extraCategories = ["CustomKey": .string("CustomVal")]
        let month = Month(year: 2026, month: 6, days: [30: dayData])
        journal.months[k] = month
        
        // Save an empty text entry
        try journal.saveEntry(text: "", date: date)
        
        // It should still exist since extraCategories is non-empty
        let entry = journal.entry(for: date)
        XCTAssertNotNil(entry)
        XCTAssertEqual(entry?.text, "")
        XCTAssertEqual(entry?.extraCategories?["CustomKey"], .string("CustomVal"))
        
        let monthURL = tempDir.appendingPathComponent("2026-06.txt")
        XCTAssertTrue(FileManager.default.fileExists(atPath: monthURL.path))
    }
    
    @MainActor
    func testJournalIgnoreNonMonthFiles() throws {
        // Create a non-matching txt file
        let invalidFile = tempDir.appendingPathComponent("2026-06-backup.txt")
        try "dummy content".write(to: invalidFile, atomically: true, encoding: .utf8)
        
        let journal = Journal(directory: tempDir)
        try journal.loadAll()
        
        // 2026-06-backup.txt should be ignored
        XCTAssertNil(journal.months[journal.key(year: 2026, month: 6)])
    }
    
    @MainActor
    func testJournalLoadAllThrowsOnInvalidYAML() throws {
        // Create a matching txt file with invalid YAML
        let invalidYAMLFile = tempDir.appendingPathComponent("2026-08.txt")
        try "invalid: yaml: : content".write(to: invalidYAMLFile, atomically: true, encoding: .utf8)
        
        let journal = Journal(directory: tempDir)
        XCTAssertThrowsError(try journal.loadAll())
    }
    
    @MainActor
    func testSaveEmptyEntryForNewMonthDoesNotThrow() throws {
        let journal = Journal(directory: tempDir)
        let date = DateComponents(year: 2026, month: 9, day: 1)
        
        // Saving empty text entry for a new month should not throw file-not-found
        XCTAssertNoThrow(try journal.saveEntry(text: "", date: date))
        
        // Verify it was not written to disk and no month was added
        let monthURL = tempDir.appendingPathComponent("2026-09.txt")
        XCTAssertFalse(FileManager.default.fileExists(atPath: monthURL.path))
        XCTAssertNil(journal.entry(for: date))
        XCTAssertTrue(journal.months.isEmpty)
    }
    
    @MainActor
    func testJournalLoadAllCaseInsensitiveMonthFiles() throws {
        let lowercaseFile = tempDir.appendingPathComponent("2026-06.txt")
        let uppercaseFile = tempDir.appendingPathComponent("2026-07.TXT")
        
        let content = "30:\n  text: Hello"
        try content.write(to: lowercaseFile, atomically: true, encoding: .utf8)
        try content.write(to: uppercaseFile, atomically: true, encoding: .utf8)
        
        let journal = Journal(directory: tempDir)
        try journal.loadAll()
        
        XCTAssertNotNil(journal.months[journal.key(year: 2026, month: 6)])
        XCTAssertNotNil(journal.months[journal.key(year: 2026, month: 7)])
    }
}

