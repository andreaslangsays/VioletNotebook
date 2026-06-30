import XCTest
@testable import VioletNotebook

final class ConfigTests: XCTestCase {
    func testConfigParsing() {
        let rawConfig = """
        # RedNotebook Config
        spellcheck=1
        autoSwitchMode=0
        previewFont=Helvetica, sans-serif
        userDir=
        """
        
        let config = Config.parse(rawConfig)
        XCTAssertEqual(config["spellcheck"], "1")
        XCTAssertEqual(config["autoSwitchMode"], "0")
        XCTAssertEqual(config["previewFont"], "Helvetica, sans-serif")
        XCTAssertEqual(config["userDir"], "")
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
