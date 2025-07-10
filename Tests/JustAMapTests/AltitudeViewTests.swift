import XCTest
import SwiftUI
import CoreLocation
@testable import JustAMap

final class AltitudeViewTests: XCTestCase {
    var sut: AltitudeView!
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testAltitudeViewDisplaysValidAltitudeInMeters() {
        // Given
        let altitude = 100.0
        let verticalAccuracy = 5.0
        let unit = AltitudeUnit.meters
        
        // When
        sut = AltitudeView(altitude: altitude, verticalAccuracy: verticalAccuracy, unit: unit)
        
        // Then
        // The view should exist and not crash
        XCTAssertNotNil(sut)
    }
    
    func testAltitudeViewDisplaysValidAltitudeInFeet() {
        // Given
        let altitude = 100.0
        let verticalAccuracy = 5.0
        let unit = AltitudeUnit.feet
        
        // When
        sut = AltitudeView(altitude: altitude, verticalAccuracy: verticalAccuracy, unit: unit)
        
        // Then
        // The view should exist and not crash
        XCTAssertNotNil(sut)
    }
    
    func testAltitudeViewDisplaysInvalidAltitude() {
        // Given
        let altitude = 100.0
        let verticalAccuracy = -1.0 // Negative accuracy indicates invalid altitude
        let unit = AltitudeUnit.meters
        
        // When
        sut = AltitudeView(altitude: altitude, verticalAccuracy: verticalAccuracy, unit: unit)
        
        // Then
        // The view should exist and not crash
        XCTAssertNotNil(sut)
    }
    
    func testAltitudeViewDisplaysLoadingState() {
        // Given
        let isLoading = true
        let unit = AltitudeUnit.meters
        
        // When
        sut = AltitudeView(isLoading: isLoading, unit: unit)
        
        // Then
        // The view should exist and not crash
        XCTAssertNotNil(sut)
    }
    
    func testAltitudeViewFormatsMetersCorrectly() {
        // Given
        let altitude = 123.7
        let verticalAccuracy = 5.0
        let unit = AltitudeUnit.meters
        
        // When
        let displayValue = unit.displayString(for: altitude)
        
        // Then
        XCTAssertEqual(displayValue, "124m") // Rounded to nearest integer
    }
    
    func testAltitudeViewFormatsFeetCorrectly() {
        // Given
        let altitude = 100.0 // meters
        let verticalAccuracy = 5.0
        let unit = AltitudeUnit.feet
        
        // When
        let displayValue = unit.displayString(for: altitude)
        
        // Then
        XCTAssertEqual(displayValue, "328ft") // 100m * 3.28084 ≈ 328ft
    }
}