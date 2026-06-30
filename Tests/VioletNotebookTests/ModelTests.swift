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
        
        if case .object(let arbeitDict) = monthContent[15]?.extraCategories?["Arbeit"] {
            XCTAssertEqual(arbeitDict["Task 1"], .null)
            XCTAssertEqual(arbeitDict["Task 2"], .null)
            XCTAssertEqual(arbeitDict.keys.sorted(), ["Task 1", "Task 2"])
        } else {
            XCTFail("Expected .object for 'Arbeit'")
        }
    }

    func testMonthSerialization() throws {
        var dayData = DayData(text: "Hello #world")
        dayData.extraCategories = ["Coding": .object(["SwiftUI": .null])]
        let monthData = [1: dayData]
        
        let encoder = YAMLEncoder()
        let yamlString = try encoder.encode(monthData)
        
        print("--- GENERATED YAML ---")
        print(yamlString)
        print("----------------------")
        
        // Verify that it contains both text and categories in correct layout
        XCTAssertTrue(yamlString.contains("text: \"Hello #world\"") || yamlString.contains("text: Hello #world") || yamlString.contains("text: 'Hello #world'"))
        XCTAssertTrue(yamlString.contains("Coding:"))
        XCTAssertTrue(yamlString.contains("SwiftUI: null") || yamlString.contains("SwiftUI: .nan") || yamlString.contains("SwiftUI: null"))
    }

    func testMonthFilenameAndIsEmpty() {
        // Test filename generation
        let month = Month(year: 2026, month: 6)
        XCTAssertEqual(month.filename, "2026-06.txt")
        
        let monthTen = Month(year: 2026, month: 10)
        XCTAssertEqual(monthTen.filename, "2026-10.txt")
        
        // Test isEmpty
        var emptyMonth = Month(year: 2026, month: 6)
        XCTAssertTrue(emptyMonth.isEmpty)
        
        emptyMonth.days = [1: DayData(text: "   \n  ")]
        XCTAssertTrue(emptyMonth.isEmpty)
        
        var nonEmptyMonth = Month(year: 2026, month: 6)
        nonEmptyMonth.days = [1: DayData(text: "Hello")]
        XCTAssertFalse(nonEmptyMonth.isEmpty)
    }

    func testMonthWithEmptyTextAndNonEmptyCategoriesIsNotEmpty() {
        var month = Month(year: 2026, month: 6)
        month.days = [1: DayData(text: "", extraCategories: ["Custom": .string("Value")])]
        XCTAssertFalse(month.isEmpty)
    }

    func testMissingOrNullTextKeysDecodeSuccessfully() throws {
        let yamlData = """
        15:
          Arbeit:
            Task 1: null
        18:
          text: null
          Sport: "Running"
        """
        let decoder = YAMLDecoder()
        let monthContent = try decoder.decode([Int: DayData].self, from: yamlData)
        
        XCTAssertEqual(monthContent[15]?.text, "")
        XCTAssertEqual(monthContent[18]?.text, "")
        
        if case .object(let arbeitDict) = monthContent[15]?.extraCategories?["Arbeit"] {
            XCTAssertEqual(arbeitDict["Task 1"], .null)
        } else {
            XCTFail("Expected .object for 'Arbeit'")
        }
        
        XCTAssertEqual(monthContent[18]?.extraCategories?["Sport"], .string("Running"))
    }
}
