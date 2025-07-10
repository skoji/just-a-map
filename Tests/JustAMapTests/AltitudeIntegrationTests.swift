import XCTest
import CoreLocation
@testable import JustAMap

final class AltitudeIntegrationTests: XCTestCase {
    var mapViewModel: MapViewModel!
    var settingsViewModel: SettingsViewModel!
    var mockLocationManager: MockLocationManager!
    var mockGeocodeService: MockGeocodeService!
    var mockSettingsStorage: MockMapSettingsStorage!
    
    override func setUp() {
        super.setUp()
        mockLocationManager = MockLocationManager()
        mockGeocodeService = MockGeocodeService()
        mockSettingsStorage = MockMapSettingsStorage()
        
        mapViewModel = MapViewModel(
            locationManager: mockLocationManager,
            geocodeService: mockGeocodeService,
            settingsStorage: mockSettingsStorage
        )
        
        settingsViewModel = SettingsViewModel(settingsStorage: mockSettingsStorage)
    }
    
    override func tearDown() {
        mapViewModel = nil
        settingsViewModel = nil
        mockLocationManager = nil
        mockGeocodeService = nil
        mockSettingsStorage = nil
        super.tearDown()
    }
    
    func testAltitudeDisplayIntegrationFlow() {
        // 初期状態：高度表示は無効
        XCTAssertFalse(mapViewModel.isAltitudeDisplayEnabled)
        XCTAssertNil(mapViewModel.displayedAltitude)
        
        // 設定で高度表示を有効にする
        settingsViewModel.isAltitudeDisplayEnabled = true
        XCTAssertTrue(mapViewModel.isAltitudeDisplayEnabled)
        
        // 位置情報を更新（有効な高度付き）
        let testLocation = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
            altitude: 150.5,
            horizontalAccuracy: 10.0,
            verticalAccuracy: 5.0,
            timestamp: Date()
        )
        
        mockLocationManager.simulateLocationUpdate(testLocation)
        
        // 高度が表示されることを確認
        XCTAssertEqual(mapViewModel.currentAltitude, 150.5)
        XCTAssertEqual(mapViewModel.displayedAltitude, 150.5) // デフォルトはメートル
        
        // 単位をフィートに変更
        settingsViewModel.altitudeUnit = .feet
        XCTAssertEqual(mapViewModel.altitudeUnit, .feet)
        
        let expectedFeet = AltitudeUnit.convertToFeet(meters: 150.5)
        XCTAssertEqual(mapViewModel.displayedAltitude, expectedFeet, accuracy: 0.001)
        
        // 無効な垂直精度の位置情報を送信
        let invalidLocation = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
            altitude: 200.0,
            horizontalAccuracy: 10.0,
            verticalAccuracy: -1.0, // 無効
            timestamp: Date()
        )
        
        mockLocationManager.simulateLocationUpdate(invalidLocation)
        
        // 高度は表示されない
        XCTAssertNil(mapViewModel.displayedAltitude)
        
        // 高度表示を無効にする
        settingsViewModel.isAltitudeDisplayEnabled = false
        XCTAssertFalse(mapViewModel.isAltitudeDisplayEnabled)
    }
    
    func testAltitudeFormattingIntegration() {
        // 高度表示を有効にする
        settingsViewModel.isAltitudeDisplayEnabled = true
        
        // メートル単位でのテスト
        settingsViewModel.altitudeUnit = .meters
        
        let testLocation = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
            altitude: 123.7,
            horizontalAccuracy: 10.0,
            verticalAccuracy: 3.0,
            timestamp: Date()
        )
        
        mockLocationManager.simulateLocationUpdate(testLocation)
        
        let formattedAltitude = mapViewModel.altitudeUnit.formatAltitude(mapViewModel.displayedAltitude)
        XCTAssertEqual(formattedAltitude, "124 m")
        
        // フィート単位でのテスト
        settingsViewModel.altitudeUnit = .feet
        
        let formattedAltitudeFeet = mapViewModel.altitudeUnit.formatAltitude(mapViewModel.displayedAltitude)
        let expectedFeet = Int(round(AltitudeUnit.convertToFeet(meters: 123.7)))
        XCTAssertEqual(formattedAltitudeFeet, "\(expectedFeet) ft")
    }
    
    func testAltitudeSettingsPersistence() {
        // 設定を変更
        settingsViewModel.isAltitudeDisplayEnabled = true
        settingsViewModel.altitudeUnit = .feet
        
        // ストレージに保存されていることを確認
        XCTAssertTrue(mockSettingsStorage.isAltitudeDisplayEnabled)
        XCTAssertEqual(mockSettingsStorage.altitudeUnit, .feet)
        
        // 新しいViewModelを作成して設定が保持されていることを確認
        let newMapViewModel = MapViewModel(
            locationManager: mockLocationManager,
            geocodeService: mockGeocodeService,
            settingsStorage: mockSettingsStorage
        )
        
        XCTAssertTrue(newMapViewModel.isAltitudeDisplayEnabled)
        XCTAssertEqual(newMapViewModel.altitudeUnit, .feet)
    }
}