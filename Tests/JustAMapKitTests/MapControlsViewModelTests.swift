import XCTest
import MapKit
@testable import JustAMapKit

@MainActor
final class MapControlsViewModelTests: XCTestCase {
    var sut: MapControlsViewModel!
    
    override func setUp() {
        super.setUp()
        sut = MapControlsViewModel()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Zoom Tests (新しい実装)
    
    func testDefaultZoomIndex() {
        // Then - デフォルトは市レベル（インデックス5）
        XCTAssertEqual(sut.currentZoomIndex, 5)
        XCTAssertEqual(sut.currentAltitude, 10000)
    }
    
    func testZoomIn() {
        // Given
        let initialIndex = sut.currentZoomIndex
        let initialAltitude = sut.currentAltitude
        
        // When
        sut.zoomIn()
        
        // Then
        XCTAssertEqual(sut.currentZoomIndex, initialIndex - 1)
        XCTAssertLessThan(sut.currentAltitude, initialAltitude)
    }
    
    func testZoomOut() {
        // Given
        let initialIndex = sut.currentZoomIndex
        let initialAltitude = sut.currentAltitude
        
        // When
        sut.zoomOut()
        
        // Then
        XCTAssertEqual(sut.currentZoomIndex, initialIndex + 1)
        XCTAssertGreaterThan(sut.currentAltitude, initialAltitude)
    }
    
    func testZoomInLimit() {
        // Given - 最小ズームインデックス（0）に設定
        sut.setZoomIndex(0)
        
        // When
        sut.zoomIn()
        
        // Then - それ以上ズームインしない
        XCTAssertEqual(sut.currentZoomIndex, 0)
        XCTAssertFalse(sut.canZoomIn)
        XCTAssertTrue(sut.canZoomOut)
    }
    
    func testZoomOutLimit() {
        // Given - 最大ズームインデックス（11）に設定
        sut.setZoomIndex(11)
        
        // When
        sut.zoomOut()
        
        // Then - それ以上ズームアウトしない
        XCTAssertEqual(sut.currentZoomIndex, 11)
        XCTAssertTrue(sut.canZoomIn)
        XCTAssertFalse(sut.canZoomOut)
    }
    
    func testSetNearestZoomIndex() {
        // 現在の実装が同じ差の場合にどちらを選ぶか確認
        // 750は500とも100とも250の差がある
        sut.setNearestZoomIndex(for: 750)
        let index750 = sut.currentZoomIndex
        print("高度750のインデックス: \(index750)")
        
        // 中間点をテスト
        sut.setNearestZoomIndex(for: 350)  // 200と500の中間
        let index350 = sut.currentZoomIndex
        print("高度350のインデックス: \(index350)")
        
        // 明らかに近いケースをテスト
        sut.setNearestZoomIndex(for: 100)
        XCTAssertEqual(sut.currentZoomIndex, 0, "高度100は200に最も近い")
        
        sut.setNearestZoomIndex(for: 400)
        XCTAssertEqual(sut.currentZoomIndex, 1, "高度400は500に最も近い")
        
        sut.setNearestZoomIndex(for: 1200000)
        XCTAssertEqual(sut.currentZoomIndex, 11, "高度1200000は1000000に最も近い")
    }
    
    func testZoomStability() {
        // Given - 特定のズームレベルを設定
        sut.setZoomIndex(3)
        let expectedAltitude = sut.currentAltitude
        
        // When - 同じインデックスを再設定
        sut.setZoomIndex(3)
        
        // Then - 高度は変わらない
        XCTAssertEqual(sut.currentAltitude, expectedAltitude)
    }
    
    func testZoomInOutReversibility() {
        // Given
        let initialIndex = sut.currentZoomIndex
        
        // When
        sut.zoomIn()
        sut.zoomOut()
        
        // Then
        XCTAssertEqual(sut.currentZoomIndex, initialIndex)
    }
    
    func testMultipleZoomSteps() {
        // Given
        sut.setZoomIndex(5)
        
        // When - 3回ズームイン
        sut.zoomIn()
        sut.zoomIn()
        sut.zoomIn()
        
        // Then
        XCTAssertEqual(sut.currentZoomIndex, 2)
        
        // When - 2回ズームアウト
        sut.zoomOut()
        sut.zoomOut()
        
        // Then
        XCTAssertEqual(sut.currentZoomIndex, 4)
    }
    
    // MARK: - Map Style Tests
    
    func testDefaultMapStyle() {
        XCTAssertEqual(sut.currentMapStyle, .standard)
    }
    
    func testMapStyleToggle() {
        // When
        sut.toggleMapStyle()
        
        // Then
        XCTAssertEqual(sut.currentMapStyle, .hybrid)
        
        // When
        sut.toggleMapStyle()
        
        // Then
        XCTAssertEqual(sut.currentMapStyle, .imagery)
        
        // When
        sut.toggleMapStyle()
        
        // Then - 最初に戻る
        XCTAssertEqual(sut.currentMapStyle, .standard)
    }
    
    func testMapStyleCycle() {
        // Given
        let expectedCycle: [MapStyle] = [.standard, .hybrid, .imagery]
        var actualCycle: [MapStyle] = []
        
        // When - 完全なサイクルを実行
        for _ in 0..<3 {
            actualCycle.append(sut.currentMapStyle)
            sut.toggleMapStyle()
        }
        
        // Then
        XCTAssertEqual(actualCycle, expectedCycle)
    }
    
    func testMapStyleProperties() {
        // Test standard
        sut.currentMapStyle = .standard
        XCTAssertEqual(sut.currentMKMapType, .standard)
        
        // Test hybrid
        sut.currentMapStyle = .hybrid
        XCTAssertEqual(sut.currentMKMapType, .hybrid)
        
        // Test imagery
        sut.currentMapStyle = .imagery
        XCTAssertEqual(sut.currentMKMapType, .satellite)
    }
    
    // MARK: - Map Orientation Tests
    
    func testDefaultMapOrientation() {
        XCTAssertTrue(sut.isNorthUp)
        XCTAssertFalse(sut.isHeadingUp)
    }
    
    func testToggleMapOrientation() {
        // When
        sut.toggleMapOrientation()
        
        // Then
        XCTAssertFalse(sut.isNorthUp)
        XCTAssertTrue(sut.isHeadingUp)
    }
    
    func testMapOrientationToggleBackAndForth() {
        // When
        sut.toggleMapOrientation()
        sut.toggleMapOrientation()
        
        // Then - 元に戻る
        XCTAssertTrue(sut.isNorthUp)
        XCTAssertFalse(sut.isHeadingUp)
    }
    
    func testCalculateHeadingRotation() {
        // Given
        let heading: Double = 45.0
        
        // When
        let rotation = sut.calculateHeadingRotation(heading)
        
        // Then
        XCTAssertEqual(rotation, -45.0)
    }
}