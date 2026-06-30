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
        XCTAssertTrue(yamlString.contains("SwiftUI: null"))
    }

    func testNullAndBooleanAndNumberPreservation() throws {
        let yamlData = """
        1:
          text: "Test day"
          myBoolTrue: true
          myBoolFalse: false
          myInt: 42
          myDouble: 3.14
          myNull: null
          myNested:
            zebra: "last"
            apple: "first"
        """
        
        let decoder = YAMLDecoder()
        let monthContent = try decoder.decode([Int: DayData].self, from: yamlData)
        
        guard let day = monthContent[1] else {
            XCTFail("Expected day 1 to be decoded")
            return
        }
        
        XCTAssertEqual(day.text, "Test day")
        guard let extra = day.extraCategories else {
            XCTFail("Expected extraCategories to be non-nil")
            return
        }
        
        XCTAssertEqual(extra["myBoolTrue"], .bool(true))
        XCTAssertEqual(extra["myBoolFalse"], .bool(false))
        XCTAssertEqual(extra["myInt"], .integer(42))
        XCTAssertEqual(extra["myDouble"], .number(3.14))
        XCTAssertEqual(extra["myNull"], .null)
        
        if case .object(let nested) = extra["myNested"] {
            XCTAssertEqual(nested["apple"], .string("first"))
            XCTAssertEqual(nested["zebra"], .string("last"))
        } else {
            XCTFail("Expected .object for myNested")
        }
        
        // Let's encode it back to YAML
        let encoder = YAMLEncoder()
        let serialized = try encoder.encode(monthContent)
        
        print("--- SERIALIZED FOR PRESERVATION ---")
        print(serialized)
        print("------------------------------------")
        
        // Verify key ordering and type preservation
        let reDecoded = try decoder.decode([Int: DayData].self, from: serialized)
        guard let reDay = reDecoded[1], let reExtra = reDay.extraCategories else {
            XCTFail("Expected re-decoded data to be complete")
            return
        }
        
        XCTAssertEqual(reExtra["myBoolTrue"], .bool(true))
        XCTAssertEqual(reExtra["myBoolFalse"], .bool(false))
        XCTAssertEqual(reExtra["myInt"], .integer(42))
        XCTAssertEqual(reExtra["myDouble"], .number(3.14))
        XCTAssertEqual(reExtra["myNull"], .null)
        XCTAssertEqual(reExtra["myNested"], extra["myNested"])
        
        // Also verify the exact string layout of the serialized output to ensure key sorting is correct.
        guard let appleRange = serialized.range(of: "apple:"),
              let zebraRange = serialized.range(of: "zebra:") else {
            XCTFail("Expected 'apple:' and 'zebra:' in serialized output")
            return
        }
        XCTAssertLessThan(appleRange.lowerBound, zebraRange.lowerBound)
        
        guard let boolFalseRange = serialized.range(of: "myBoolFalse:"),
              let boolTrueRange = serialized.range(of: "myBoolTrue:"),
              let doubleRange = serialized.range(of: "myDouble:"),
              let intRange = serialized.range(of: "myInt:"),
              let nestedRange = serialized.range(of: "myNested:"),
              let nullRange = serialized.range(of: "myNull:") else {
            XCTFail("Expected all category keys in serialized output")
            return
        }
        XCTAssertLessThan(boolFalseRange.lowerBound, boolTrueRange.lowerBound)
        XCTAssertLessThan(boolTrueRange.lowerBound, doubleRange.lowerBound)
        XCTAssertLessThan(doubleRange.lowerBound, intRange.lowerBound)
        XCTAssertLessThan(intRange.lowerBound, nestedRange.lowerBound)
        XCTAssertLessThan(nestedRange.lowerBound, nullRange.lowerBound)
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
