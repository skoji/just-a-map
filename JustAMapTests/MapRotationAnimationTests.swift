import XCTest
import SwiftUI
import MapKit
import CoreLocation
@testable import JustAMap

/// 地図の回転アニメーションに関するテスト
@MainActor
class MapRotationAnimationTests: XCTestCase {
    
    private var mapControlsViewModel: MapControlsViewModel!
    private var mapViewModel: MapViewModel!
    private var mockLocationManager: MockLocationManager!
    
    override func setUp() {
        super.setUp()
        mockLocationManager = MockLocationManager()
        mapControlsViewModel = MapControlsViewModel()
        mapViewModel = MapViewModel(locationManager: mockLocationManager, mapControlsViewModel: mapControlsViewModel)
    }
    
    override func tearDown() {
        mapControlsViewModel = nil
        mapViewModel = nil
        mockLocationManager = nil
        super.tearDown()
    }
    
    // MARK: - North Up / Heading Up 切り替えテスト
    
    func testToggleMapOrientationChangesIsNorthUp() {
        // Given: 初期状態（North Up）
        XCTAssertTrue(mapControlsViewModel.isNorthUp)
        XCTAssertFalse(mapControlsViewModel.isHeadingUp)
        
        // When: 切り替える
        mapControlsViewModel.toggleMapOrientation()
        
        // Then: Heading Upに変わる
        XCTAssertFalse(mapControlsViewModel.isNorthUp)
        XCTAssertTrue(mapControlsViewModel.isHeadingUp)
        
        // When: もう一度切り替える
        mapControlsViewModel.toggleMapOrientation()
        
        // Then: North Upに戻る
        XCTAssertTrue(mapControlsViewModel.isNorthUp)
        XCTAssertFalse(mapControlsViewModel.isHeadingUp)
    }
    
    // MARK: - 回転角度計算テスト
    
    func testCalculateHeadingRotationReturnsCorrectAngle() {
        // Given: 様々な方位角
        let testCases: [(heading: Double, expected: Double)] = [
            (0, 0),         // 北向き
            (90, -90),      // 東向き
            (180, -180),    // 南向き
            (270, -270),    // 西向き
            (45, -45),      // 北東向き
            (360, -360),    // 北向き（360度）
        ]
        
        // When & Then: 各ケースで正しい回転角度が返される
        for testCase in testCases {
            let rotation = mapControlsViewModel.calculateHeadingRotation(testCase.heading)
            XCTAssertEqual(rotation, testCase.expected, accuracy: 0.01,
                          "Heading \(testCase.heading)° should result in rotation \(testCase.expected)°")
        }
    }
    
    // MARK: - MapViewModel連携テスト
    
    func testMapViewModelReturnsCorrectHeadingForOrientation() {
        // Given: テスト用の位置情報
        let testLocation = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671),
            altitude: 0,
            horizontalAccuracy: 5,
            verticalAccuracy: 5,
            course: 45.0, // 北東向き
            speed: 10.0,
            timestamp: Date()
        )
        
        // When: North Upモード
        mapControlsViewModel.isNorthUp = true
        let northUpHeading = mapViewModel.calculateMapHeading(for: testLocation)
        
        // Then: 0度（北向き）が返される
        XCTAssertEqual(northUpHeading, 0, accuracy: 0.01)
        
        // When: Heading Upモード
        mapControlsViewModel.isNorthUp = false
        let headingUpHeading = mapViewModel.calculateMapHeading(for: testLocation)
        
        // Then: コース方向（45度）が返される
        XCTAssertEqual(headingUpHeading, 45.0, accuracy: 0.01)
    }
    
    func testMapViewModelHandlesInvalidCourse() {
        // Given: コース情報が無効な位置情報
        let testLocation = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671),
            altitude: 0,
            horizontalAccuracy: 5,
            verticalAccuracy: 5,
            course: -1.0, // 無効なコース
            speed: 0.0,
            timestamp: Date()
        )
        
        // When: Heading Upモード
        mapControlsViewModel.isNorthUp = false
        let heading = mapViewModel.calculateMapHeading(for: testLocation)
        
        // Then: 0度（デフォルト）が返される
        XCTAssertEqual(heading, 0, accuracy: 0.01)
    }
    
    // MARK: - 切り替え時の即座の回転テスト
    
    func testOrientationToggleShouldTriggerImmediateRotation() {
        // Given: 位置情報とHeading Upモード
        let testLocation = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671),
            altitude: 0,
            horizontalAccuracy: 5,
            verticalAccuracy: 5,
            course: 90.0, // 東向き
            speed: 10.0,
            timestamp: Date()
        )
        mockLocationManager.simulateLocationUpdate(testLocation)
        mapControlsViewModel.isNorthUp = false
        
        // When: North Upに切り替える
        // Note: 実際のMapViewとの連携はUIテストで確認するため、
        // ここではtoggleが正しく動作することのみを確認
        mapControlsViewModel.toggleMapOrientation()
        
        // Then: 正しく切り替わっている
        XCTAssertTrue(mapControlsViewModel.isNorthUp)
        
        // And: 位置情報に基づいて正しいheadingが計算される
        let heading = mapViewModel.calculateMapHeading(for: testLocation)
        XCTAssertEqual(heading, 0, accuracy: 0.01) // North Upなので0度
    }
    
    // MARK: - North Upモードでのユーザー操作制限テスト
    
    func testNorthUpModeShouldDisableUserRotation() {
        // Given: North Upモード
        mapControlsViewModel.isNorthUp = true
        
        // Then: ユーザーによる回転が無効
        XCTAssertFalse(mapViewModel.isUserRotationEnabled)
        
        // When: Heading Upモードに切り替え
        mapControlsViewModel.isNorthUp = false
        
        // Then: ユーザーによる回転が有効
        XCTAssertTrue(mapViewModel.isUserRotationEnabled)
    }
}