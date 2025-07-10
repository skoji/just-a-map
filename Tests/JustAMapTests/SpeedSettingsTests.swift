import XCTest
@testable import JustAMap

final class SpeedSettingsTests: XCTestCase {
    var sut: MapSettingsStorage!
    var mockUserDefaults: MockUserDefaults!
    
    override func setUp() {
        super.setUp()
        mockUserDefaults = MockUserDefaults()
        sut = MapSettingsStorage(userDefaults: mockUserDefaults)
    }
    
    override func tearDown() {
        sut = nil
        mockUserDefaults = nil
        super.tearDown()
    }
    
    func testSpeedDisplayEnabledDefaultValue() {
        // Given/When
        let isEnabled = sut.isSpeedDisplayEnabled
        
        // Then
        XCTAssertFalse(isEnabled, "Speed display should be disabled by default")
    }
    
    func testSpeedDisplayEnabledSaveAndLoad() {
        // Given
        let expectedValue = true
        
        // When
        sut.isSpeedDisplayEnabled = expectedValue
        
        // Then
        XCTAssertEqual(sut.isSpeedDisplayEnabled, expectedValue)
        XCTAssertTrue(mockUserDefaults.storage["isSpeedDisplayEnabled"] as! Bool)
    }
    
    func testSpeedDisplayEnabledLoadFromStorage() {
        // Given
        mockUserDefaults.storage["isSpeedDisplayEnabled"] = true
        
        // When
        let isEnabled = sut.isSpeedDisplayEnabled
        
        // Then
        XCTAssertTrue(isEnabled)
    }
    
    func testSpeedUnitDefaultValue() {
        // Given/When
        let speedUnit = sut.speedUnit
        
        // Then
        XCTAssertEqual(speedUnit, .kmh, "Default speed unit should be km/h")
    }
    
    func testSpeedUnitSaveAndLoad() {
        // Given
        let expectedUnit = SpeedUnit.mph
        
        // When
        sut.speedUnit = expectedUnit
        
        // Then
        XCTAssertEqual(sut.speedUnit, expectedUnit)
        XCTAssertEqual(mockUserDefaults.storage["speedUnit"] as! String, "mph")
    }
    
    func testSpeedUnitLoadFromStorage() {
        // Given
        mockUserDefaults.storage["speedUnit"] = "mph"
        
        // When
        let speedUnit = sut.speedUnit
        
        // Then
        XCTAssertEqual(speedUnit, .mph)
    }
    
    func testSpeedUnitLoadInvalidFromStorage() {
        // Given
        mockUserDefaults.storage["speedUnit"] = "invalid"
        
        // When
        let speedUnit = sut.speedUnit
        
        // Then
        XCTAssertEqual(speedUnit, .kmh, "Should default to km/h when invalid value in storage")
    }
    
    func testSaveSpeedDisplayEnabled() {
        // Given
        let expectedValue = true
        
        // When
        sut.saveSpeedDisplayEnabled(expectedValue)
        
        // Then
        XCTAssertTrue(sut.loadSpeedDisplayEnabled())
        XCTAssertTrue(mockUserDefaults.storage["isSpeedDisplayEnabled"] as! Bool)
    }
    
    func testLoadSpeedDisplayEnabledWhenNotSet() {
        // Given - no value set
        
        // When
        let isEnabled = sut.loadSpeedDisplayEnabled()
        
        // Then
        XCTAssertFalse(isEnabled, "Should return false when no value is set")
    }
    
    func testSaveSpeedUnit() {
        // Given
        let expectedUnit = SpeedUnit.mph
        
        // When
        sut.saveSpeedUnit(expectedUnit)
        
        // Then
        XCTAssertEqual(sut.loadSpeedUnit(), expectedUnit)
        XCTAssertEqual(mockUserDefaults.storage["speedUnit"] as! String, "mph")
    }
    
    func testLoadSpeedUnitWhenNotSet() {
        // Given - no value set
        
        // When
        let speedUnit = sut.loadSpeedUnit()
        
        // Then
        XCTAssertEqual(speedUnit, .kmh, "Should return km/h when no value is set")
    }
}