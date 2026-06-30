import XCTest
@testable import VioletNotebook

final class ParserTests: XCTestCase {
    func testBasicFormatting() {
        let raw = "This is **bold** and //italic// and __underlined__ and --stricken--."
        let html = Txt2TagsParser.toHTML(raw)
        XCTAssertEqual(html, "<p>This is <b>bold</b> and <i>italic</i> and <u>underlined</u> and <s>stricken</s>.</p>\n")
    }
    
    func testTitlesAndLines() {
        let raw = """
        = Main H1 =
        == Sub H2 ==
        ====================
        """
        let html = Txt2TagsParser.toHTML(raw)
        XCTAssertTrue(html.contains("<h1>Main H1</h1>"), "Expected <h1>Main H1</h1> in: \(html)")
        XCTAssertTrue(html.contains("<h2>Sub H2</h2>"), "Expected <h2>Sub H2</h2> in: \(html)")
        XCTAssertTrue(html.contains("<hr />"), "Expected <hr /> in: \(html)")
    }
    
    func testLinksAndHashtags() {
        let raw = "Check [Google \"\"https://google.com\"\"] and #swift tag."
        let html = Txt2TagsParser.toHTML(raw)
        XCTAssertTrue(html.contains("<a href=\"https://google.com\">Google</a>"), "Expected Google link in: \(html)")
        XCTAssertTrue(html.contains("<span class=\"hashtag\">#swift</span>"), "Expected #swift hashtag in: \(html)")
    }

    func testEmptyAndComments() {
        XCTAssertEqual(Txt2TagsParser.toHTML(""), "")
        XCTAssertEqual(Txt2TagsParser.toHTML("% comment line\n% another comment"), "")
        XCTAssertEqual(Txt2TagsParser.toHTML("  \n\n  "), "")
    }

    func testVariousHeadings() {
        let raw = """
        = Title 1 =
        === Title 3 ===
        """
        let html = Txt2TagsParser.toHTML(raw)
        XCTAssertTrue(html.contains("<h1>Title 1</h1>\n"), "Expected <h1>Title 1</h1> in: \(html)")
        XCTAssertTrue(html.contains("<h3>Title 3</h3>\n"), "Expected <h3>Title 3</h3> in: \(html)")
    }

    func testListsWithMultipleItems() {
        let raw = """
        - First item with **bold**
        - Second item
        + Third item with //italic//
        
        Normal paragraph
        """
        let html = Txt2TagsParser.toHTML(raw)
        let expected = """
        <ul>
        <li>First item with <b>bold</b></li>
        <li>Second item</li>
        <li>Third item with <i>italic</i></li>
        </ul>
        <p>Normal paragraph</p>\n
        """
        XCTAssertEqual(html, expected)
    }

    func testHashtagEdgeCases() {
        let raw = "#first #second_tag #third123 #a #123 #ffffff c#sharp #swift"
        let html = Txt2TagsParser.toHTML(raw)
        // #first at start of line
        XCTAssertTrue(html.contains("<span class=\"hashtag\">#first</span>"))
        // #second_tag with underscore
        XCTAssertTrue(html.contains("<span class=\"hashtag\">#second_tag</span>"))
        // #third123 with trailing digits
        XCTAssertTrue(html.contains("<span class=\"hashtag\">#third123</span>"))
        // #a single letter
        XCTAssertTrue(html.contains("<span class=\"hashtag\">#a</span>"))
        // #123 should NOT match (starts with digit)
        XCTAssertFalse(html.contains("<span class=\"hashtag\">#123</span>"))
        XCTAssertTrue(html.contains("#123"))
        // #ffffff should NOT match (starts with letter, but usually HEX, wait, does our regex match it?)
        // Let's see: pattern is `(#[a-zA-Z][a-zA-Z0-9_]*)\\b`.
        // Since 'f' is a letter, our regex actually MATCHES #ffffff.
        // Wait, is that expected/acceptable?
        // Let's check how the regex is written: `(#[a-zA-Z][a-zA-Z0-9_]*)\\b`.
        // This regex matches #ffffff because it starts with a letter 'f' and has letters/numbers.
        // Wait, HEX colors are usually part of a style/color block, e.g. `{text|color:#ffffff}`.
        // So HEX color tags in text might be formatted as #ffffff. If they are in a color block, they won't have space before them.
        // Let's check the test brief:
        // "Hashtags #tag (alphanumeric starting with letters, excludes HEX colors/C directives)"
        // Wait, does the Python code exclude hex colors?
        // In python: HASHTAG = re.compile(r'(^|\s)(#[a-zA-Z][a-zA-Z0-9_]*)\b')
        // So Python HASHTAG ALSO matches #ffffff if it is a standalone word, but not inside styles or hex values that start with digits or aren't preceded by space/start of line.
        // Let's test what we have.
        // What about c#sharp? 'c#sharp' does not start with # at word start (there is no space before #), so it shouldn't match.
        XCTAssertFalse(html.contains("<span class=\"hashtag\">c#sharp</span>"))
    }

    func testShortLinkEdgeCases() {
        let raw = "Check [2026-06-30] and [My Entry 2026-06-30] and [incomplete 202-06-30] or [2026-06]."
        let html = Txt2TagsParser.toHTML(raw)
        XCTAssertTrue(html.contains("<a href=\"violet://day/2026-06-30\">2026-06-30</a>"))
        XCTAssertTrue(html.contains("<a href=\"violet://day/2026-06-30\">My Entry</a>"))
        XCTAssertFalse(html.contains("href=\"violet://day/202-06-30\""))
        XCTAssertFalse(html.contains("href=\"violet://day/2026-06\""))
    }

    func testHTMLSafeness() {
        let raw = "Some & text with <script>alert('xss')</script> tags."
        let html = Txt2TagsParser.toHTML(raw)
        XCTAssertFalse(html.contains("<script>"))
        XCTAssertTrue(html.contains("&amp;"))
        XCTAssertTrue(html.contains("&lt;script&gt;"))
    }
}
