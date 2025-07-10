import XCTest
import SwiftUI
@testable import JustAMap

final class AltitudeViewTests: XCTestCase {
    func testAltitudeViewModelDisplayText() {
        // Test formatted altitude display
        XCTAssertEqual(AltitudeUnit.meters.formatAltitude(150.7), "151 m")
        XCTAssertEqual(AltitudeUnit.feet.formatAltitude(492.0), "492 ft")
        XCTAssertEqual(AltitudeUnit.meters.formatAltitude(-50.3), "-51 m")
        XCTAssertEqual(AltitudeUnit.meters.formatAltitude(nil), "---")
    }
    
    func testAltitudeConversionForDisplay() {
        let metersAltitude = 150.0
        let feetAltitude = AltitudeUnit.convertToFeet(meters: metersAltitude)
        
        XCTAssertEqual(AltitudeUnit.meters.formatAltitude(metersAltitude), "150 m")
        XCTAssertEqual(AltitudeUnit.feet.formatAltitude(feetAltitude), "492 ft")
    }
}