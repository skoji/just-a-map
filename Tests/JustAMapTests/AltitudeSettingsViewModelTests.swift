import XCTest
import SwiftUI
@testable import JustAMap

final class AltitudeSettingsViewModelTests: XCTestCase {
    var sut: SettingsViewModel!
    var mockSettingsStorage: MockMapSettingsStorage!
    var mockBundle: MockBundle!
    
    override func setUp() {
        super.setUp()
        mockSettingsStorage = MockMapSettingsStorage()
        mockBundle = MockBundle()
        sut = SettingsViewModel(settingsStorage: mockSettingsStorage, bundle: mockBundle)
    }
    
    override func tearDown() {
        sut = nil
        mockSettingsStorage = nil
        mockBundle = nil
        super.tearDown()
    }
    
    func testAltitudeDisplayEnabledInitialValue() {
        // Given & When
        let isEnabled = sut.isAltitudeDisplayEnabled
        
        // Then
        XCTAssertFalse(isEnabled) // デフォルトはOFF
    }
    
    func testAltitudeDisplayEnabledCanBeToggled() {
        // Given
        sut.isAltitudeDisplayEnabled = true
        
        // When
        let isEnabled = sut.isAltitudeDisplayEnabled
        
        // Then
        XCTAssertTrue(isEnabled)
        XCTAssertTrue(mockSettingsStorage.isAltitudeDisplayEnabled)
    }
    
    func testAltitudeUnitInitialValue() {
        // Given & When
        let unit = sut.altitudeUnit
        
        // Then
        XCTAssertEqual(unit, .meters) // デフォルトはメートル
    }
    
    func testAltitudeUnitCanBeChanged() {
        // Given
        sut.altitudeUnit = .feet
        
        // When
        let unit = sut.altitudeUnit
        
        // Then
        XCTAssertEqual(unit, .feet)
        XCTAssertEqual(mockSettingsStorage.altitudeUnit, .feet)
    }
    
    func testAltitudeSettingsArePersisted() {
        // Given
        sut.isAltitudeDisplayEnabled = true
        sut.altitudeUnit = .feet
        
        // When
        let newViewModel = SettingsViewModel(settingsStorage: mockSettingsStorage, bundle: mockBundle)
        
        // Then
        XCTAssertTrue(newViewModel.isAltitudeDisplayEnabled)
        XCTAssertEqual(newViewModel.altitudeUnit, .feet)
    }
}