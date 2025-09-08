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

    func testSpeedBecomesZeroAfterConsecutiveInvalidsWhenStopped() async {
        // Given - Valid speed, then stop and receive consecutive invalids
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

        // When - stop at same coordinate and feed consecutive invalid speeds
        let t1 = movingLocation.timestamp.addingTimeInterval(0.5)
        let invalid1 = CLLocation(
            coordinate: movingLocation.coordinate,
            altitude: 0,
            horizontalAccuracy: 5.0,
            verticalAccuracy: 5.0,
            course: -1,
            speed: -1.0,
            timestamp: t1
        )
        sut.locationManager(mockLocationManager, didUpdateLocation: invalid1)

        let t2 = t1.addingTimeInterval(0.5)
        let invalid2 = CLLocation(
            coordinate: movingLocation.coordinate,
            altitude: 0,
            horizontalAccuracy: 5.0,
            verticalAccuracy: 5.0,
            course: -1,
            speed: -1.0,
            timestamp: t2
        )
        sut.locationManager(mockLocationManager, didUpdateLocation: invalid2)

        let t3 = t2.addingTimeInterval(0.5)
        let invalid3 = CLLocation(
            coordinate: movingLocation.coordinate,
            altitude: 0,
            horizontalAccuracy: 5.0,
            verticalAccuracy: 5.0,
            course: -1,
            speed: -1.0,
            timestamp: t3
        )
        sut.locationManager(mockLocationManager, didUpdateLocation: invalid3)

        // Then - speed becomes 0 after enough invalids while not moving
        let expectation = expectation(description: "invalid speeds lead to zero when stopped")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { expectation.fulfill() }
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(sut.currentSpeed, 0.0)
    }
    
    func testInvalidSpeedDoesNotDropToZeroWhileMoving() async {
        // Given - moving with valid speed
        let start = Date()
        let loc1 = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
            altitude: 0,
            horizontalAccuracy: 5.0,
            verticalAccuracy: 5.0,
            course: 0,
            speed: 15.0,
            timestamp: start
        )
        sut.locationManager(mockLocationManager, didUpdateLocation: loc1)
        let e1 = expectation(description: "set speed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { e1.fulfill() }
        await fulfillment(of: [e1], timeout: 1.0)
        XCTAssertEqual(sut.currentSpeed, 15.0)

        // When - next update is invalid but position advanced (approx speed > threshold)
        let advanced = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 35.6765, longitude: 139.6508),
            altitude: 0,
            horizontalAccuracy: 5.0,
            verticalAccuracy: 5.0,
            course: -1,
            speed: -1.0,
            timestamp: start.addingTimeInterval(0.5)
        )
        sut.locationManager(mockLocationManager, didUpdateLocation: advanced)

        // Then - should keep previous non-zero speed (no blip to zero)
        let e2 = expectation(description: "no zero blip")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { e2.fulfill() }
        await fulfillment(of: [e2], timeout: 1.0)
        XCTAssertEqual(sut.currentSpeed, 15.0)
    }
}
