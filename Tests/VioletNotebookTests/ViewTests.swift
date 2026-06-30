import XCTest
import SwiftUI
@testable import VioletNotebook

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
}
