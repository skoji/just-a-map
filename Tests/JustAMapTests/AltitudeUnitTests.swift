import XCTest
@testable import JustAMap

final class AltitudeUnitTests: XCTestCase {
    
    func testMetersToFeetConversion() {
        // Given
        let metersValue = 100.0
        
        // When
        let feetValue = AltitudeUnit.convertToFeet(meters: metersValue)
        
        // Then
        let expectedFeet = 328.0 // 100m * 3.28084 ≈ 328ft (rounded to integer)
        XCTAssertEqual(feetValue, expectedFeet, accuracy: 1.0)
    }
    
    func testFeetToMetersConversion() {
        // Given
        let feetValue = 328.0
        
        // When
        let metersValue = AltitudeUnit.convertToMeters(feet: feetValue)
        
        // Then
        let expectedMeters = 100.0 // 328ft / 3.28084 ≈ 100m (rounded to integer)
        XCTAssertEqual(metersValue, expectedMeters, accuracy: 1.0)
    }
    
    func testZeroValueConversion() {
        // Given
        let zeroValue = 0.0
        
        // When & Then
        XCTAssertEqual(AltitudeUnit.convertToFeet(meters: zeroValue), 0.0)
        XCTAssertEqual(AltitudeUnit.convertToMeters(feet: zeroValue), 0.0)
    }
    
    func testNegativeValueConversion() {
        // Given
        let negativeMeters = -50.0
        
        // When
        let negativeFeet = AltitudeUnit.convertToFeet(meters: negativeMeters)
        
        // Then
        XCTAssertTrue(negativeFeet < 0)
        XCTAssertEqual(negativeFeet, -164.0, accuracy: 1.0) // -50m * 3.28084 ≈ -164ft
    }
    
    func testMetersDisplayString() {
        // Given
        let altitude = 100.5
        
        // When
        let displayString = AltitudeUnit.meters.displayString(for: altitude)
        
        // Then
        XCTAssertEqual(displayString, "101m") // Rounded to integer
    }
    
    func testFeetDisplayString() {
        // Given
        let altitude = 100.0
        
        // When
        let displayString = AltitudeUnit.feet.displayString(for: altitude)
        
        // Then
        XCTAssertEqual(displayString, "328ft") // 100m converted to feet and rounded
    }
    
    func testDisplayStringForInvalidAltitude() {
        // Given
        let invalidAltitude = -1.0 // Negative vertical accuracy indicates invalid altitude
        
        // When & Then
        XCTAssertEqual(AltitudeUnit.meters.displayString(for: invalidAltitude), "---")
        XCTAssertEqual(AltitudeUnit.feet.displayString(for: invalidAltitude), "---")
    }
    
    func testUnitSymbols() {
        // Given & When & Then
        XCTAssertEqual(AltitudeUnit.meters.symbol, "m")
        XCTAssertEqual(AltitudeUnit.feet.symbol, "ft")
    }
    
    func testAllCases() {
        // Given & When
        let allCases = AltitudeUnit.allCases
        
        // Then
        XCTAssertEqual(allCases.count, 2)
        XCTAssertTrue(allCases.contains(.meters))
        XCTAssertTrue(allCases.contains(.feet))
    }
}