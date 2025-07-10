import XCTest
@testable import JustAMap

final class AltitudeSettingsTests: XCTestCase {
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
    
    func testAltitudeDisplayDefault() {
        // Given & When
        let isDisplayed = sut.isAltitudeDisplayEnabled
        
        // Then
        XCTAssertFalse(isDisplayed) // デフォルトはOFF
    }
    
    func testAltitudeDisplayCanBeEnabled() {
        // Given
        sut.isAltitudeDisplayEnabled = true
        
        // When
        let isDisplayed = sut.isAltitudeDisplayEnabled
        
        // Then
        XCTAssertTrue(isDisplayed)
    }
    
    func testAltitudeDisplayCanBeDisabled() {
        // Given
        sut.isAltitudeDisplayEnabled = true
        
        // When
        sut.isAltitudeDisplayEnabled = false
        
        // Then
        XCTAssertFalse(sut.isAltitudeDisplayEnabled)
    }
    
    func testAltitudeUnitDefault() {
        // Given & When
        let unit = sut.altitudeUnit
        
        // Then
        XCTAssertEqual(unit, .meters) // デフォルトはメートル
    }
    
    func testAltitudeUnitCanBeChangedToFeet() {
        // Given
        sut.altitudeUnit = .feet
        
        // When
        let unit = sut.altitudeUnit
        
        // Then
        XCTAssertEqual(unit, .feet)
    }
    
    func testAltitudeUnitCanBeChangedBackToMeters() {
        // Given
        sut.altitudeUnit = .feet
        
        // When
        sut.altitudeUnit = .meters
        
        // Then
        XCTAssertEqual(sut.altitudeUnit, .meters)
    }
    
    func testAltitudeSettingsPersistence() {
        // Given
        sut.isAltitudeDisplayEnabled = true
        sut.altitudeUnit = .feet
        
        // When
        let newStorage = MapSettingsStorage(userDefaults: mockUserDefaults)
        
        // Then
        XCTAssertTrue(newStorage.isAltitudeDisplayEnabled)
        XCTAssertEqual(newStorage.altitudeUnit, .feet)
    }
    
    func testSaveAndLoadAltitudeDisplayEnabled() {
        // Given
        let enabled = true
        
        // When
        sut.saveAltitudeDisplayEnabled(enabled)
        let loaded = sut.loadAltitudeDisplayEnabled()
        
        // Then
        XCTAssertEqual(loaded, enabled)
    }
    
    func testSaveAndLoadAltitudeUnit() {
        // Given
        let unit = AltitudeUnit.feet
        
        // When
        sut.saveAltitudeUnit(unit)
        let loaded = sut.loadAltitudeUnit()
        
        // Then
        XCTAssertEqual(loaded, unit)
    }
    
    func testLoadAltitudeDisplayEnabledReturnsDefaultWhenNotSet() {
        // Given
        // UserDefaultsに何も保存されていない状態
        
        // When
        let enabled = sut.loadAltitudeDisplayEnabled()
        
        // Then
        XCTAssertFalse(enabled) // デフォルトはfalse
    }
    
    func testLoadAltitudeUnitReturnsDefaultWhenNotSet() {
        // Given
        // UserDefaultsに何も保存されていない状態
        
        // When
        let unit = sut.loadAltitudeUnit()
        
        // Then
        XCTAssertEqual(unit, .meters) // デフォルトはメートル
    }
}