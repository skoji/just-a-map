import XCTest
@testable import JustAMap

final class AltitudeUnitTests: XCTestCase {
    func testAltitudeUnitRawValues() {
        XCTAssertEqual(AltitudeUnit.meters.rawValue, "meters")
        XCTAssertEqual(AltitudeUnit.feet.rawValue, "feet")
    }
    
    func testAltitudeUnitFromRawValue() {
        XCTAssertEqual(AltitudeUnit(rawValue: "meters"), .meters)
        XCTAssertEqual(AltitudeUnit(rawValue: "feet"), .feet)
        XCTAssertNil(AltitudeUnit(rawValue: "invalid"))
    }
    
    func testAltitudeUnitDisplaySymbol() {
        XCTAssertEqual(AltitudeUnit.meters.displaySymbol, "m")
        XCTAssertEqual(AltitudeUnit.feet.displaySymbol, "ft")
    }
    
    func testAltitudeUnitDisplayName() {
        XCTAssertEqual(AltitudeUnit.meters.displayName, "altitude_unit.meters".localized)
        XCTAssertEqual(AltitudeUnit.feet.displayName, "altitude_unit.feet".localized)
    }
    
    func testAllCasesContainsBothUnits() {
        XCTAssertEqual(AltitudeUnit.allCases.count, 2)
        XCTAssertTrue(AltitudeUnit.allCases.contains(.meters))
        XCTAssertTrue(AltitudeUnit.allCases.contains(.feet))
    }
    
    func testConvertMetersToFeet() {
        let meters = 100.0
        let expectedFeet = meters * 3.28084
        XCTAssertEqual(AltitudeUnit.convertToFeet(meters: meters), expectedFeet, accuracy: 0.001)
    }
    
    func testConvertFeetToMeters() {
        let feet = 328.084
        let expectedMeters = feet / 3.28084
        XCTAssertEqual(AltitudeUnit.convertToMeters(feet: feet), expectedMeters, accuracy: 0.001)
    }
    
    func testFormatAltitudeMeters() {
        XCTAssertEqual(AltitudeUnit.meters.formatAltitude(100.5), "101 m")
        XCTAssertEqual(AltitudeUnit.meters.formatAltitude(-50.7), "-51 m")
        XCTAssertEqual(AltitudeUnit.meters.formatAltitude(0), "0 m")
    }
    
    func testFormatAltitudeFeet() {
        XCTAssertEqual(AltitudeUnit.feet.formatAltitude(328.084), "328 ft")
        XCTAssertEqual(AltitudeUnit.feet.formatAltitude(-164.042), "-164 ft")
        XCTAssertEqual(AltitudeUnit.feet.formatAltitude(0), "0 ft")
    }
    
    func testFormatAltitudeWithInvalidValue() {
        // Test with negative vertical accuracy (invalid altitude)
        XCTAssertEqual(AltitudeUnit.meters.formatAltitude(nil), "---")
        XCTAssertEqual(AltitudeUnit.feet.formatAltitude(nil), "---")
    }
}