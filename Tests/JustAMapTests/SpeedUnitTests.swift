import XCTest
@testable import JustAMap

final class SpeedUnitTests: XCTestCase {
    
    func testSpeedUnitSymbols() {
        // Given/When/Then
        XCTAssertEqual(SpeedUnit.kmh.symbol, "km/h")
        XCTAssertEqual(SpeedUnit.mph.symbol, "mph")
    }
    
    func testKmhDisplayString() {
        // Given
        let unit = SpeedUnit.kmh
        
        // When/Then
        XCTAssertEqual(unit.displayString(for: 50.0), "50km/h")
        XCTAssertEqual(unit.displayString(for: 50.7), "51km/h") // rounds to nearest integer
        XCTAssertEqual(unit.displayString(for: 0.0), "0km/h")
        XCTAssertEqual(unit.displayString(for: 120.5), "121km/h")
    }
    
    func testMphDisplayString() {
        // Given
        let unit = SpeedUnit.mph
        
        // When/Then
        XCTAssertEqual(unit.displayString(for: 50.0), "31mph") // 50 km/h ≈ 31 mph
        XCTAssertEqual(unit.displayString(for: 100.0), "62mph") // 100 km/h ≈ 62 mph
        XCTAssertEqual(unit.displayString(for: 0.0), "0mph")
        XCTAssertEqual(unit.displayString(for: 160.9), "100mph") // 160.9 km/h ≈ 100 mph
    }
    
    func testInvalidSpeedDisplayString() {
        // Given/When/Then
        XCTAssertEqual(SpeedUnit.kmh.displayString(for: -1.0), "---")
        XCTAssertEqual(SpeedUnit.mph.displayString(for: -10.0), "---")
    }
    
    func testConvertKmhToMph() {
        // Given/When/Then
        XCTAssertEqual(SpeedUnit.convertKmhToMph(kmh: 0.0), 0.0, accuracy: 0.01)
        XCTAssertEqual(SpeedUnit.convertKmhToMph(kmh: 100.0), 62.137, accuracy: 0.01)
        XCTAssertEqual(SpeedUnit.convertKmhToMph(kmh: 50.0), 31.069, accuracy: 0.01)
        XCTAssertEqual(SpeedUnit.convertKmhToMph(kmh: 160.9), 100.0, accuracy: 0.01)
    }
    
    func testConvertMphToKmh() {
        // Given/When/Then
        XCTAssertEqual(SpeedUnit.convertMphToKmh(mph: 0.0), 0.0, accuracy: 0.01)
        XCTAssertEqual(SpeedUnit.convertMphToKmh(mph: 62.137), 100.0, accuracy: 0.01)
        XCTAssertEqual(SpeedUnit.convertMphToKmh(mph: 31.069), 50.0, accuracy: 0.01)
        XCTAssertEqual(SpeedUnit.convertMphToKmh(mph: 100.0), 160.9, accuracy: 0.01)
    }
    
    func testCaseIterable() {
        // Given/When
        let allUnits = SpeedUnit.allCases
        
        // Then
        XCTAssertEqual(allUnits.count, 2)
        XCTAssertTrue(allUnits.contains(.kmh))
        XCTAssertTrue(allUnits.contains(.mph))
    }
    
    func testRawValue() {
        // Given/When/Then
        XCTAssertEqual(SpeedUnit.kmh.rawValue, "kmh")
        XCTAssertEqual(SpeedUnit.mph.rawValue, "mph")
        
        // Test round-trip conversion
        XCTAssertEqual(SpeedUnit(rawValue: "kmh"), .kmh)
        XCTAssertEqual(SpeedUnit(rawValue: "mph"), .mph)
        XCTAssertNil(SpeedUnit(rawValue: "invalid"))
    }
}