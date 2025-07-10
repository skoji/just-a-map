import XCTest
import CoreLocation
import SwiftUI
@testable import JustAMap

@MainActor
final class AltitudeIntegrationTests: XCTestCase {
    var mapViewModel: MapViewModel!
    var settingsViewModel: SettingsViewModel!
    var mockLocationManager: MockLocationManager!
    var mockGeocodeService: MockGeocodeService!
    var mockSettingsStorage: MockMapSettingsStorage!
    
    override func setUp() async throws {
        mockLocationManager = MockLocationManager()
        mockGeocodeService = MockGeocodeService()
        mockSettingsStorage = MockMapSettingsStorage()
        
        mapViewModel = MapViewModel(
            locationManager: mockLocationManager,
            geocodeService: mockGeocodeService,
            settingsStorage: mockSettingsStorage
        )
        
        settingsViewModel = SettingsViewModel(
            settingsStorage: mockSettingsStorage,
            bundle: MockBundle()
        )
    }
    
    override func tearDown() async throws {
        mapViewModel = nil
        settingsViewModel = nil
        mockLocationManager = nil
        mockGeocodeService = nil
        mockSettingsStorage = nil
    }
    
    func testAltitudeSettingsIntegration() {
        // Given
        XCTAssertFalse(mapViewModel.isAltitudeDisplayEnabled) // 初期状態はOFF
        XCTAssertEqual(mapViewModel.altitudeUnit, .meters) // 初期状態はメートル
        
        // When - 設定画面で高度表示をONにしてフィートに変更
        settingsViewModel.isAltitudeDisplayEnabled = true
        settingsViewModel.altitudeUnit = .feet
        
        // Then - MapViewModelからも変更が見える
        XCTAssertTrue(mapViewModel.isAltitudeDisplayEnabled)
        XCTAssertEqual(mapViewModel.altitudeUnit, .feet)
        
        // And - 設定が永続化されている
        XCTAssertTrue(mockSettingsStorage.isAltitudeDisplayEnabled)
        XCTAssertEqual(mockSettingsStorage.altitudeUnit, .feet)
    }
    
    func testAltitudeDataFlowFromGPSToDisplay() {
        // Given
        settingsViewModel.isAltitudeDisplayEnabled = true
        settingsViewModel.altitudeUnit = .meters
        
        let location = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
            altitude: 100.0,
            horizontalAccuracy: 5.0,
            verticalAccuracy: 3.0,
            timestamp: Date()
        )
        
        // When - GPS位置情報が更新される
        mockLocationManager.simulateLocationUpdate(location)
        
        // Then - MapViewModelで高度データが取得される
        XCTAssertEqual(mapViewModel.currentAltitude, 100.0)
        XCTAssertEqual(mapViewModel.currentVerticalAccuracy, 3.0)
        
        // And - 表示用文字列が正しく生成される
        let displayString = mapViewModel.getAltitudeDisplayString(
            altitude: 100.0,
            verticalAccuracy: 3.0,
            unit: .meters
        )
        XCTAssertEqual(displayString, "100m")
    }
    
    func testAltitudeViewCreationWithIntegratedData() {
        // Given
        settingsViewModel.isAltitudeDisplayEnabled = true
        settingsViewModel.altitudeUnit = .feet
        
        let location = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
            altitude: 100.0, // 100m
            horizontalAccuracy: 5.0,
            verticalAccuracy: 5.0,
            timestamp: Date()
        )
        
        // When
        mockLocationManager.simulateLocationUpdate(location)
        
        // Then - AltitudeViewが正しいデータで作成される
        let altitudeView = AltitudeView(
            altitude: mapViewModel.currentAltitude,
            verticalAccuracy: mapViewModel.currentVerticalAccuracy,
            unit: mapViewModel.altitudeUnit
        )
        
        XCTAssertNotNil(altitudeView)
        // 100m = 328ft（整数に丸める）
        XCTAssertEqual(mapViewModel.altitudeUnit.displayString(for: 100.0), "328ft")
    }
    
    func testAltitudeDisabledState() {
        // Given
        settingsViewModel.isAltitudeDisplayEnabled = false
        
        let location = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
            altitude: 100.0,
            horizontalAccuracy: 5.0,
            verticalAccuracy: 5.0,
            timestamp: Date()
        )
        
        // When
        mockLocationManager.simulateLocationUpdate(location)
        
        // Then - 高度データは取得されるが、表示は無効
        XCTAssertEqual(mapViewModel.currentAltitude, 100.0) // データは保存される
        XCTAssertFalse(mapViewModel.isAltitudeDisplayEnabled) // 表示は無効
    }
    
    func testInvalidAltitudeHandling() {
        // Given
        settingsViewModel.isAltitudeDisplayEnabled = true
        
        let location = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
            altitude: 100.0,
            horizontalAccuracy: 5.0,
            verticalAccuracy: -1.0, // 無効な精度
            timestamp: Date()
        )
        
        // When
        mockLocationManager.simulateLocationUpdate(location)
        
        // Then
        let displayString = mapViewModel.getAltitudeDisplayString(
            altitude: mapViewModel.currentAltitude ?? 0,
            verticalAccuracy: mapViewModel.currentVerticalAccuracy ?? 0,
            unit: mapViewModel.altitudeUnit
        )
        
        XCTAssertEqual(displayString, "---") // 無効な精度の場合は"---"
    }
}