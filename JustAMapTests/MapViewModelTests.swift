import XCTest
import CoreLocation
@testable import JustAMap

@MainActor
final class MapViewModelTests: XCTestCase {
    
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
    
    // MARK: - 追従モード状態管理のテスト
    
    func testIsFollowingUserInitialState() {
        // 初期状態では追従モードが有効
        XCTAssertTrue(sut.isFollowingUser, "初期状態では追従モードが有効であるべき")
    }
    
    func testDisableFollowingMode() {
        // Given
        XCTAssertTrue(sut.isFollowingUser)
        
        // When
        sut.isFollowingUser = false
        
        // Then
        XCTAssertFalse(sut.isFollowingUser, "追従モードが無効化されるべき")
    }
    
    func testEnableFollowingMode() {
        // Given
        sut.isFollowingUser = false
        XCTAssertFalse(sut.isFollowingUser)
        
        // When
        sut.isFollowingUser = true
        
        // Then
        XCTAssertTrue(sut.isFollowingUser, "追従モードが有効化されるべき")
    }
    
    func testCenterOnUserLocationEnablesFollowingMode() {
        // Given
        let location = CLLocation(latitude: 35.6762, longitude: 139.6503)
        sut.userLocation = location
        sut.isFollowingUser = false
        
        // When
        sut.centerOnUserLocation()
        
        // Then
        XCTAssertTrue(sut.isFollowingUser, "centerOnUserLocationを呼ぶと追従モードが有効になるべき")
    }
    
    func testLocationUpdateWhenFollowingDisabled() {
        // Given
        sut.isFollowingUser = false
        let initialCenter = sut.region.center
        let newLocation = CLLocation(latitude: 40.7128, longitude: -74.0060) // New York
        
        // When
        sut.locationManager(mockLocationManager, didUpdateLocation: newLocation)
        
        // 非同期処理を待つ
        let expectation = expectation(description: "Location update")
        Task {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Then
        XCTAssertEqual(sut.region.center.latitude, initialCenter.latitude, accuracy: 0.0001,
                      "追従モードが無効の場合、地図の中心は更新されないべき")
        XCTAssertEqual(sut.region.center.longitude, initialCenter.longitude, accuracy: 0.0001,
                      "追従モードが無効の場合、地図の中心は更新されないべき")
    }
    
    func testLocationUpdateWhenFollowingEnabled() {
        // Given
        sut.isFollowingUser = true
        let newLocation = CLLocation(latitude: 40.7128, longitude: -74.0060) // New York
        
        // When
        sut.locationManager(mockLocationManager, didUpdateLocation: newLocation)
        
        // 非同期処理を待つ
        let expectation = expectation(description: "Location update")
        Task {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Then
        XCTAssertEqual(sut.region.center.latitude, newLocation.coordinate.latitude, accuracy: 0.0001,
                      "追従モードが有効の場合、地図の中心が更新されるべき")
        XCTAssertEqual(sut.region.center.longitude, newLocation.coordinate.longitude, accuracy: 0.0001,
                      "追従モードが有効の場合、地図の中心が更新されるべき")
    }
    
    // MARK: - 地図操作による追従モード解除のテスト
    
    func testDisableFollowingModeWhenUserPansMap() {
        // Given
        sut.isFollowingUser = true
        XCTAssertTrue(sut.isFollowingUser)
        
        // When - ユーザーが地図を操作したことをシミュレート
        sut.handleUserMapInteraction()
        
        // Then
        XCTAssertFalse(sut.isFollowingUser, "ユーザーが地図を操作したら追従モードが解除されるべき")
    }
    
    func testMapCenterPositionTracking() {
        // Given
        let initialCenter = CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503)
        sut.mapCenterCoordinate = initialCenter
        
        // When
        let newCenter = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
        sut.mapCenterCoordinate = newCenter
        
        // Then
        XCTAssertEqual(sut.mapCenterCoordinate.latitude, newCenter.latitude, accuracy: 0.0001)
        XCTAssertEqual(sut.mapCenterCoordinate.longitude, newCenter.longitude, accuracy: 0.0001)
    }
}