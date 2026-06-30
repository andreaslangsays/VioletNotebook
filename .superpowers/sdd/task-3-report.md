# Task 3 Report: Journal Manager with Directory Access

## What was Implemented
- Implemented the `Journal` class in `Sources/VioletNotebook/Models/Journal.swift` as an `ObservableObject` managing the loading/saving of month files (`YYYY-MM.txt` pattern) and config files (`configuration.cfg`).
- Exposed the following properties and methods in `Journal`:
  - `directory`: The base directory of the journal.
  - `@Published var months`: A dictionary mapping month keys (format `YYYY-MM`) to loaded `Month` structs.
  - `@Published var config`: A `Config` object for the loaded config settings.
  - `key(year: Int, month: Int)`: Helper method generating month key strings.
  - `entry(for: DateComponents)`: Method retrieving the `DayData` entry for specific dates.
  - `loadAll()`: Method finding and decoding all matching `YYYY-MM.txt` files and the `configuration.cfg` file in the directory.
  - `saveEntry(text: String, date: DateComponents)`: Method updating/saving individual day entries, encoding them into YAML via Yams, and deleting empty files/months appropriately.

## What was Tested and Test Results
Created `Tests/VioletNotebookTests/JournalTests.swift` testing the following:
1. `testJournalLoadAndSave`: Verifies basic loading and saving of day entries.
2. `testJournalLoadConfig`: Verifies config parser integration.
3. `testJournalSaveEmptyEntryDeletesFile`: Verifies that empty entries are cleared out and the corresponding month file is deleted if the month becomes completely empty.
4. `testJournalSaveEmptyEntryWithCategoriesKeepsFile`: Verifies that an entry is NOT deleted if it has extra category metadata, even if the text is empty.
5. `testJournalIgnoreNonMonthFiles`: Verifies that non-matching files are ignored, and invalid YAML files fail gracefully rather than crashing.

### TDD Evidence: RED (Failing Test Output)
```
/Users/andreas/Code/VioletNotebook/Tests/VioletNotebookTests/JournalTests.swift:19:23: error: cannot find 'Journal' in scope
17 |     
18 |     func testJournalLoadAndSave() throws {
19 |         let journal = Journal(directory: tempDir)
   |                       `- error: cannot find 'Journal' in scope
20 |         XCTAssertTrue(journal.months.isEmpty)
21 |         

/Users/andreas/Code/VioletNotebook/Tests/VioletNotebookTests/JournalTests.swift:26:24: error: cannot find 'Journal' in scope
24 |         
25 |         // Reload journal from disk
26 |         let journal2 = Journal(directory: tempDir)
   |                        `- error: cannot find 'Journal' in scope
27 |         try journal2.loadAll()
28 |         
error: fatalError
```

### TDD Evidence: GREEN (Passing Test Output)
```
[14/17] Compiling VioletNotebookTests JournalTests.swift
[15/17] Emitting module VioletNotebookTests
[15/17] Write Objects.LinkFileList
[16/17] Linking VioletNotebookPackageTests
Build complete! (1.84s)
Test Suite 'All tests' started at 2026-06-30 10:05:05.586.
Test Suite 'VioletNotebookPackageTests.xctest' started at 2026-06-30 10:05:05.587.
Test Suite 'ConfigTests' started at 2026-06-30 10:05:05.587.
Test Case '-[VioletNotebookTests.ConfigTests testConfigParsing]' started.
Test Case '-[VioletNotebookTests.ConfigTests testConfigParsing]' passed (0.001 seconds).
Test Case '-[VioletNotebookTests.ConfigTests testConfigSerialization]' started.
Test Case '-[VioletNotebookTests.ConfigTests testConfigSerialization]' passed (0.000 seconds).
Test Suite 'ConfigTests' passed at 2026-06-30 10:05:05.588.
	 Executed 2 tests, with 0 failures (0 unexpected) in 0.001 (0.001) seconds
Test Suite 'JournalTests' started at 2026-06-30 10:05:05.588.
Test Case '-[VioletNotebookTests.JournalTests testJournalIgnoreNonMonthFiles]' started.
Test Case '-[VioletNotebookTests.JournalTests testJournalIgnoreNonMonthFiles]' passed (0.006 seconds).
Test Case '-[VioletNotebookTests.JournalTests testJournalLoadAndSave]' started.
Test Case '-[VioletNotebookTests.JournalTests testJournalLoadAndSave]' passed (0.002 seconds).
Test Case '-[VioletNotebookTests.JournalTests testJournalLoadConfig]' started.
Test Case '-[VioletNotebookTests.JournalTests testJournalLoadConfig]' passed (0.001 seconds).
Test Case '-[VioletNotebookTests.JournalTests testJournalSaveEmptyEntryDeletesFile]' started.
Test Case '-[VioletNotebookTests.JournalTests testJournalSaveEmptyEntryDeletesFile]' passed (0.001 seconds).
Test Case '-[VioletNotebookTests.JournalTests testJournalSaveEmptyEntryWithCategoriesKeepsFile]' started.
Test Case '-[VioletNotebookTests.JournalTests testJournalSaveEmptyEntryWithCategoriesKeepsFile]' passed (0.002 seconds).
Test Suite 'JournalTests' passed at 2026-06-30 10:05:05.600.
	 Executed 5 tests, with 0 failures (0 unexpected) in 0.011 (0.012) seconds
Test Suite 'ModelTests' started at 2026-06-30 10:05:05.600.
Test Case '-[VioletNotebookTests.ModelTests testMissingOrNullTextKeysDecodeSuccessfully]' started.
Test Case '-[VioletNotebookTests.ModelTests testMissingOrNullTextKeysDecodeSuccessfully]' passed (0.001 seconds).
Test Case '-[VioletNotebookTests.ModelTests testMonthFilenameAndIsEmpty]' started.
Test Case '-[VioletNotebookTests.ModelTests testMonthFilenameAndIsEmpty]' passed (0.000 seconds).
Test Case '-[VioletNotebookTests.ModelTests testMonthParsingWithComplexYAML]' started.
Test Case '-[VioletNotebookTests.ModelTests testMonthParsingWithComplexYAML]' passed (0.001 seconds).
Test Case '-[VioletNotebookTests.ModelTests testMonthSerialization]' started.
Test Case '-[VioletNotebookTests.ModelTests testMonthSerialization]' passed (0.000 seconds).
Test Case '-[VioletNotebookTests.ModelTests testMonthWithEmptyTextAndNonEmptyCategoriesIsNotEmpty]' started.
Test Case '-[VioletNotebookTests.ModelTests testMonthWithEmptyTextAndNonEmptyCategoriesIsNotEmpty]' passed (0.000 seconds).
Test Case '-[VioletNotebookTests.ModelTests testNullAndBooleanAndNumberPreservation]' started.
Test Case '-[VioletNotebookTests.ModelTests testNullAndBooleanAndNumberPreservation]' passed (0.001 seconds).
Test Suite 'ModelTests' passed at 2026-06-30 10:05:05.604.
	 Executed 6 tests, with 0 failures (0 unexpected) in 0.003 (0.004) seconds
Test Suite 'VioletNotebookPackageTests.xctest' passed at 2026-06-30 10:05:05.604.
	 Executed 13 tests, with 0 failures (0 unexpected) in 0.015 (0.017) seconds
Test Suite 'All tests' passed at 2026-06-30 10:05:05.604.
	 Executed 13 tests, with 0 failures (0 unexpected) in 0.015 (0.018) seconds
```

## Files Changed
- `Sources/VioletNotebook/Models/Journal.swift` (New file)
- `Tests/VioletNotebookTests/JournalTests.swift` (New file)
- `.superpowers/sdd/progress.md` (Updated)

## Self-Review Findings
- **Completeness**: All required elements of the `Journal` class were successfully implemented.
- **Access Control**: Access levels were correctly mapped to internal target configuration (since the target is executable/application, public vs internal compiles properly, and using `@testable import` in tests works seamlessly).
- **Correctness of Deletions**: Edge cases like saving empty text while maintaining categories/tags were correctly verified so metadata is not lost.

## Issues or Concerns
None. The code compiles without warnings, fits into the existing code patterns perfectly, and integrates with the Custom YAML formats verified in Task 2.

## Fix Report: Review Findings Resolved

### 1. Data Loss on Invalid YAML Prevention
- Modified `loadAll()` in `Journal.swift` to use standard `try` instead of `try?` during the decoding step:
  ```swift
  let days = try decoder.decode([Int: DayData].self, from: rawYAML)
  ```
- This ensures that syntax errors or corruption in month files are not silently ignored (which would previously cause them to be overwritten with an empty dictionary). The errors now propagate upwards.

### 2. File Deletion Error Propagation
- Replaced `try? FileManager.default.removeItem(at: file)` with `try FileManager.default.removeItem(at: file)` in `saveEntry()` to ensure any deletion failures (due to permissions, locks, etc.) are surfaced rather than failing silently.

### 3. SwiftUI @Published Thread Safety
- Annotated the `Journal` class with `@MainActor` to guarantee all operations modifying the `@Published` properties `months` and `config` run safely on the Main Actor thread.
- Updated all test cases in `JournalTests.swift` with `@MainActor` attribute to compile and execute in the Main Actor context safely.

### 4. Security Bookmark Resolving Helper
- Added a public static helper method `resolveBookmark(data:)` in `Journal` to support resolving security-scoped bookmark data for sandboxed folder access.

### 5. Verified and Tested
- Added a new test `testJournalLoadAllThrowsOnInvalidYAML` to verify that `loadAll()` correctly throws when encountering invalid YAML content.
- Verified that all 14 tests pass successfully.

## Fix Report (Round 2): Review Findings Resolved

### 1. File Deletion Failure on Non-Existent Files in saveEntry
- Modified `saveEntry(text:date:)` to check if the file exists on disk (`FileManager.default.fileExists(atPath: file.path)`) before calling `removeItem(at:)`. This prevents a Cocoa Error 4 ("The file doesn't exist") when clearing a day's text in a new, unwritten month.
- Verified by adding the test case `testSaveEmptyEntryForNewMonthDoesNotThrow` in `JournalTests.swift`.

### 2. Security-Scoped Resource Handle Leak
- Added a `deinit` block to the `Journal` class to stop accessing security-scoped resources:
  ```swift
  deinit {
      directory.stopAccessingSecurityScopedResource()
  }
  ```

### 3. Robust Directory Checking in loadAll
- Updated the path check in `loadAll()` to verify both the existence and the fact that the path is a directory:
  ```swift
  var isDir: ObjCBool = false
  guard fm.fileExists(atPath: directory.path, isDirectory: &isDir), isDir.boolValue else { return }
  ```

### 4. Case-Insensitive Month File Regex
- Configured the regular expression for finding month files to be case-insensitive, allowing matching of files with uppercase extension `.TXT`:
  ```swift
  let regex = try NSRegularExpression(pattern: "^(\\d{4})-(\\d{2})\\.txt$", options: .caseInsensitive)
  ```
- Verified by adding the test case `testJournalLoadAllCaseInsensitiveMonthFiles` in `JournalTests.swift`.

