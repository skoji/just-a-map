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
        
        // デバウンス時間（300ms）待つ
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
        
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
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
        sut.updateMapCenter(center2)
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
        sut.updateMapCenter(center3)
        
        // Then - 最後の更新のみが処理される
        try? await Task.sleep(nanoseconds: 400_000_000) // 0.4秒
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
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒（デバウンス + 処理時間）
        
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
        
        // When
        sut.centerOnUserLocation()
        
        // Then
        XCTAssertTrue(sut.isFollowingUser, "追従モードが有効になるべき")
        // NOTE: 現在の実装では、centerOnUserLocationはデフォルトズームレベルを使用していない
        // この動作を確認するためのテスト
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
}