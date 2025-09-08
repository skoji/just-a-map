import XCTest
import CoreLocation
@testable import JustAMap

@MainActor
final class SpeedStopBehaviorTests: XCTestCase {
    var sut: MapViewModel!
    var mockLocationManager: MockLocationManager!
    var mockGeocodeService: MockGeocodeService!
    var mockIdleTimerManager: MockIdleTimerManager!
    var mockSettingsStorage: MockMapSettingsStorage!

    override func setUp() async throws {
        mockLocationManager = MockLocationManager()
        mockGeocodeService = MockGeocodeService()
        mockIdleTimerManager = MockIdleTimerManager()
        mockSettingsStorage = MockMapSettingsStorage()
        // 速度表示をONにして起動
        mockSettingsStorage.isSpeedDisplayEnabled = true

        sut = MapViewModel(
            locationManager: mockLocationManager,
            geocodeService: mockGeocodeService,
            idleTimerManager: mockIdleTimerManager,
            settingsStorage: mockSettingsStorage
        )
    }

    override func tearDown() async throws {
        sut = nil
        mockLocationManager = nil
        mockGeocodeService = nil
        mockIdleTimerManager = nil
        mockSettingsStorage = nil
    }

    func testSpeedBecomesZeroWhenInvalidSpeedWhileDisplayEnabled() async {
        // Given - 移動中の有効な速度が設定されている
        let movingLocation = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
            altitude: 0,
            horizontalAccuracy: 5.0,
            verticalAccuracy: 5.0,
            course: 0,
            speed: 10.0, // 10 m/s
            timestamp: Date()
        )
        sut.locationManager(mockLocationManager, didUpdateLocation: movingLocation)
        let setExpectation = expectation(description: "initial speed set")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { setExpectation.fulfill() }
        await fulfillment(of: [setExpectation], timeout: 1.0)
        XCTAssertEqual(sut.currentSpeed, 10.0)

        // When - 無効な速度（停止時に発生しうる）を受信
        let invalidSpeedLocation = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
            altitude: 0,
            horizontalAccuracy: 5.0,
            verticalAccuracy: 5.0,
            course: -1,
            speed: -1.0, // invalid
            timestamp: Date()
        )
        sut.locationManager(mockLocationManager, didUpdateLocation: invalidSpeedLocation)

        // Then - 速度が0にリセットされる（速度表示ON時の期待挙動）
        let expectation = expectation(description: "invalid speed handled as zero")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { expectation.fulfill() }
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(sut.currentSpeed, 0.0, "Invalid speed should be treated as 0 when speed display is enabled")
    }
}

