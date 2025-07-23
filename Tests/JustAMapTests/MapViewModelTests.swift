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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
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
    
    // MARK: - デバウンス処理付き住所取得のテスト
    
    func testFetchAddressForMapCenterWithDebounce() async {
        // Given
        let newCenter = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
        sut.isFollowingUser = false
        
        // When - 地図中心を更新
        sut.updateMapCenter(newCenter)
        
        // Then - 即座には住所取得が開始されない
        XCTAssertFalse(sut.isLoadingMapCenterAddress)
        XCTAssertNil(sut.mapCenterAddress)
        
        // デバウンス時間（300ms）+ 処理時間を考慮してより長く待つ
        let expectation = expectation(description: "Debounce completion")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 1.0)
        
        // Then - デバウンス後に住所が取得される
        XCTAssertNotNil(sut.mapCenterAddress)
        XCTAssertFalse(sut.isLoadingMapCenterAddress) // 取得完了後はfalseになる
    }
    
    func testRapidMapCenterUpdatesCancelPreviousFetch() async {
        // Given
        let center1 = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
        let center2 = CLLocationCoordinate2D(latitude: 35.6820, longitude: 139.7680)
        let center3 = CLLocationCoordinate2D(latitude: 35.6830, longitude: 139.7690)
        sut.isFollowingUser = false
        
        // When - 連続して地図中心を更新
        sut.updateMapCenter(center1)
        let expectation1 = expectation(description: "First update")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation1.fulfill()
        }
        await fulfillment(of: [expectation1], timeout: 1.0)
        
        sut.updateMapCenter(center2)
        let secondUpdateExpectation = expectation(description: "Second update")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            secondUpdateExpectation.fulfill()
        }
        await fulfillment(of: [secondUpdateExpectation], timeout: 1.0)
        
        sut.updateMapCenter(center3)
        
        // Then - 最後の更新のみが処理される
        let finalUpdateExpectation = expectation(description: "Final update processing")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            finalUpdateExpectation.fulfill()
        }
        await fulfillment(of: [finalUpdateExpectation], timeout: 1.0)
        XCTAssertEqual(sut.mapCenterCoordinate.latitude, center3.latitude, accuracy: 0.0001)
        XCTAssertEqual(sut.mapCenterCoordinate.longitude, center3.longitude, accuracy: 0.0001)
    }
    
    func testMapCenterAddressDisplay() async {
        // Given
        let mapCenter = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
        sut.isFollowingUser = false
        let expectedAddress = Address(
            name: "六本木ヒルズ",
            fullAddress: "東京都港区六本木６丁目１０−１",
            postalCode: "106-6108",
            locality: "港区",
            subAdministrativeArea: nil,
            administrativeArea: "東京都",
            country: "日本"
        )
        mockGeocodeService.reverseGeocodeResult = .success(expectedAddress)
        
        // When
        sut.updateMapCenter(mapCenter)
        let expectation = expectation(description: "Map center address update")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 1.0)
        
        // Then
        XCTAssertNotNil(sut.mapCenterAddress)
        XCTAssertEqual(sut.mapCenterAddress?.primaryText, "六本木ヒルズ")
    }
    
    // MARK: - デフォルトズームレベルのテスト
    
    func testCenterOnUserLocationUsesDefaultZoomLevel() {
        // Given
        let testLocation = CLLocation(latitude: 35.6762, longitude: 139.6503)
        mockLocationManager.currentLocation = testLocation
        sut.userLocation = testLocation
        
        // デフォルトズームレベルを設定
        let defaultZoomIndex = 2 // 1km
        mockSettingsStorage.defaultZoomIndex = defaultZoomIndex
        
        // 現在のズームレベルを別の値に設定
        sut.mapControlsViewModel.setZoomIndex(8) // 100km
        XCTAssertEqual(sut.mapControlsViewModel.currentZoomIndex, 8)
        
        // When
        sut.centerOnUserLocation()
        
        // Then
        XCTAssertTrue(sut.isFollowingUser, "追従モードが有効になるべき")
        XCTAssertEqual(sut.mapControlsViewModel.currentZoomIndex, defaultZoomIndex, "デフォルトズームレベルが適用されるべき")
    }
    
    func testFollowingModeRemainsEnabledAfterCenterOnUserLocation() {
        // Given
        let testLocation = CLLocation(latitude: 35.6762, longitude: 139.6503)
        mockLocationManager.currentLocation = testLocation
        sut.userLocation = testLocation
        sut.isFollowingUser = false // 追従モードを無効にしておく
        
        // When
        sut.centerOnUserLocation()
        
        // Then
        XCTAssertTrue(sut.isFollowingUser, "centerOnUserLocation後は追従モードが有効になるべき")
        
        // 地図操作をシミュレート（100m未満の移動）
        let nearbyCoordinate = CLLocationCoordinate2D(
            latitude: 35.6763, // わずかに北へ
            longitude: 139.6503
        )
        sut.updateMapCenter(nearbyCoordinate)
        
        // 100m未満の移動では追従モードは維持されるべき
        XCTAssertTrue(sut.isFollowingUser, "100m未満の移動では追従モードが維持されるべき")
    }
    
    func testDefaultZoomLevelIsLoadedFromSettings() {
        // Given
        let expectedDefaultZoomIndex = 8 // 100km
        mockSettingsStorage.defaultZoomIndex = expectedDefaultZoomIndex
        mockSettingsStorage.zoomIndex = 5 // 現在のズーム
        
        // When - 新しいViewModelを作成（設定を読み込む）
        let newViewModel = MapViewModel(
            locationManager: mockLocationManager,
            geocodeService: mockGeocodeService,
            idleTimerManager: mockIdleTimerManager,
            settingsStorage: mockSettingsStorage
        )
        
        // Then
        // デフォルトズームインデックスは設定に保存されている
        XCTAssertEqual(mockSettingsStorage.defaultZoomIndex, expectedDefaultZoomIndex)
        // 現在のズームインデックスは保存された値を使用
        XCTAssertEqual(newViewModel.mapControlsViewModel.currentZoomIndex, 5)
    }
    
    // MARK: - 速度表示のテスト
    
    func testSpeedResetsToZeroWhenLocationUpdatesPause() async {
        // Given
        let movingLocation = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
            altitude: 0,
            horizontalAccuracy: 5.0,
            verticalAccuracy: 5.0,
            course: 0,
            speed: 10.0, // 10 m/s = 36 km/h
            timestamp: Date()
        )
        
        // When - 位置情報を更新して速度を設定
        sut.locationManager(mockLocationManager, didUpdateLocation: movingLocation)
        
        // Wait for async operation to complete
        let expectation = expectation(description: "Speed update")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 1.0)
        
        // Then - 速度が設定されていることを確認
        XCTAssertEqual(sut.currentSpeed, 10.0, "速度が設定されるべき")
        
        // When - 位置情報更新が一時停止
        sut.locationManagerDidPauseLocationUpdates(mockLocationManager)
        
        // Wait for async operation to complete
        let pauseExpectation = self.expectation(description: "Pause processing")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            pauseExpectation.fulfill()
        }
        await fulfillment(of: [pauseExpectation], timeout: 1.0)
        
        // Then - 速度が0にリセットされるべき
        XCTAssertEqual(sut.currentSpeed, 0.0, "位置情報更新が一時停止した場合、速度は0にリセットされるべき")
    }
    
    func testInvalidSpeedValueIsIgnored() async {
        // Given - 有効な速度で移動中
        let movingLocation = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
            altitude: 0,
            horizontalAccuracy: 5.0,
            verticalAccuracy: 5.0,
            course: 0,
            speed: 10.0, // 10 m/s = 36 km/h
            timestamp: Date()
        )
        
        sut.locationManager(mockLocationManager, didUpdateLocation: movingLocation)
        let expectation = expectation(description: "Speed update")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(sut.currentSpeed, 10.0, "速度が設定されるべき")
        
        // When - 無効な速度値（-1）を受信
        let invalidSpeedLocation = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 35.6763, longitude: 139.6504),
            altitude: 0,
            horizontalAccuracy: 5.0,
            verticalAccuracy: 5.0,
            course: 0,
            speed: -1.0, // 無効な速度
            timestamp: Date()
        )
        
        sut.locationManager(mockLocationManager, didUpdateLocation: invalidSpeedLocation)
        let invalidSpeedExpectation = self.expectation(description: "Invalid speed processing")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            invalidSpeedExpectation.fulfill()
        }
        await fulfillment(of: [invalidSpeedExpectation], timeout: 1.0)
        
        // Then - 速度は前の有効な値を保持するべき
        XCTAssertEqual(sut.currentSpeed, 10.0, "無効な速度値は無視され、前の有効な値が保持されるべき")
    }
    
    func testSpeedResumesWhenLocationUpdatesResume() async {
        // Given - 位置情報更新が一時停止中で速度が0
        sut.locationManagerDidPauseLocationUpdates(mockLocationManager)
        
        // Wait for async operation to complete
        let expectation = expectation(description: "Pause processing")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 1.0)
        
        XCTAssertEqual(sut.currentSpeed, 0.0, "一時停止中は速度が0であるべき")
        
        // When - 位置情報更新が再開し、新しい位置情報を受信
        sut.locationManagerDidResumeLocationUpdates(mockLocationManager)
        
        let movingLocation = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
            altitude: 0,
            horizontalAccuracy: 5.0,
            verticalAccuracy: 5.0,
            course: 0,
            speed: 15.0, // 15 m/s = 54 km/h
            timestamp: Date()
        )
        
        sut.locationManager(mockLocationManager, didUpdateLocation: movingLocation)
        
        // Wait for async operation to complete
        let resumeExpectation = self.expectation(description: "Speed resume processing")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            resumeExpectation.fulfill()
        }
        await fulfillment(of: [resumeExpectation], timeout: 1.0)
        
        // Then - 速度が更新されるべき
        XCTAssertEqual(sut.currentSpeed, 15.0, "位置情報更新が再開した場合、速度が更新されるべき")
    }
    
}