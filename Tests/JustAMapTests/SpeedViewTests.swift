import XCTest
import SwiftUI
@testable import JustAMap

final class SpeedViewTests: XCTestCase {
    
    func testSpeedViewInitialization() {
        // Given/When
        let speedView = SpeedView(speed: 13.89, unit: .kmh, isLoading: false)
        
        // Then
        XCTAssertNotNil(speedView)
    }
    
    func testSpeedViewWithValidSpeed() {
        // Given
        let speedInMeterPerSecond = 13.89 // 50 km/h
        let speedView = SpeedView(speed: speedInMeterPerSecond, unit: .kmh, isLoading: false)
        
        // When
        let mirror = Mirror(reflecting: speedView)
        let speedValue = mirror.children.first(where: { $0.label == "speed" })?.value as? Double
        let unitValue = mirror.children.first(where: { $0.label == "unit" })?.value as? SpeedUnit
        
        // Then
        XCTAssertEqual(speedValue, speedInMeterPerSecond)
        XCTAssertEqual(unitValue, .kmh)
    }
    
    func testSpeedViewWithInvalidSpeed() {
        // Given
        let invalidSpeed = -1.0
        let speedView = SpeedView(speed: invalidSpeed, unit: .kmh, isLoading: false)
        
        // When
        let mirror = Mirror(reflecting: speedView)
        let speedValue = mirror.children.first(where: { $0.label == "speed" })?.value as? Double
        
        // Then
        XCTAssertEqual(speedValue, invalidSpeed)
    }
    
    func testSpeedViewWithMphUnit() {
        // Given
        let speedInMeterPerSecond = 13.89 // 50 km/h ≈ 31 mph
        let speedView = SpeedView(speed: speedInMeterPerSecond, unit: .mph, isLoading: false)
        
        // When
        let mirror = Mirror(reflecting: speedView)
        let unitValue = mirror.children.first(where: { $0.label == "unit" })?.value as? SpeedUnit
        
        // Then
        XCTAssertEqual(unitValue, .mph)
    }
    
    func testSpeedViewLoadingState() {
        // Given
        let speedView = SpeedView(speed: nil, unit: .kmh, isLoading: true)
        
        // When
        let mirror = Mirror(reflecting: speedView)
        let isLoadingValue = mirror.children.first(where: { $0.label == "isLoading" })?.value as? Bool
        
        // Then
        XCTAssertTrue(isLoadingValue ?? false)
    }
    
    func testSpeedViewNilSpeed() {
        // Given
        let speedView = SpeedView(speed: nil, unit: .kmh, isLoading: false)
        
        // When
        let mirror = Mirror(reflecting: speedView)
        let speedValue = mirror.children.first(where: { $0.label == "speed" })?.value
        
        // Then
        XCTAssertNil(speedValue as? Double)
    }
}