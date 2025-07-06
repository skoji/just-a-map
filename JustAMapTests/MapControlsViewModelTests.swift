import XCTest
import MapKit
@testable import JustAMap

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
    
    // MARK: - Zoom Tests
    
    func testZoomIn() {
        // Given
        let initialSpan = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        
        // When
        let newSpan = sut.calculateZoomIn(from: initialSpan)
        
        // Then
        XCTAssertLessThan(newSpan.latitudeDelta, initialSpan.latitudeDelta)
        XCTAssertLessThan(newSpan.longitudeDelta, initialSpan.longitudeDelta)
        XCTAssertEqual(newSpan.latitudeDelta, initialSpan.latitudeDelta * 0.5, accuracy: 0.0001)
    }
    
    func testZoomOut() {
        // Given
        let initialSpan = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        
        // When
        let newSpan = sut.calculateZoomOut(from: initialSpan)
        
        // Then
        XCTAssertGreaterThan(newSpan.latitudeDelta, initialSpan.latitudeDelta)
        XCTAssertGreaterThan(newSpan.longitudeDelta, initialSpan.longitudeDelta)
        XCTAssertEqual(newSpan.latitudeDelta, initialSpan.latitudeDelta * 2.0, accuracy: 0.0001)
    }
    
    func testZoomInLimit() {
        // Given - 最小ズーム値に近い値
        let initialSpan = MKCoordinateSpan(latitudeDelta: 0.0001, longitudeDelta: 0.0001)
        
        // When
        let newSpan = sut.calculateZoomIn(from: initialSpan)
        
        // Then - それ以上ズームインしない
        XCTAssertEqual(newSpan.latitudeDelta, sut.minimumZoomSpan.latitudeDelta, accuracy: 0.00001)
    }
    
    func testZoomOutLimit() {
        // Given - 最大ズーム値に近い値
        let initialSpan = MKCoordinateSpan(latitudeDelta: 100.0, longitudeDelta: 100.0)
        
        // When
        let newSpan = sut.calculateZoomOut(from: initialSpan)
        
        // Then - それ以上ズームアウトしない
        XCTAssertEqual(newSpan.latitudeDelta, sut.maximumZoomSpan.latitudeDelta, accuracy: 0.1)
    }
    
    func testZoomLevelCalculation() {
        // Given
        let span1 = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let span2 = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        
        // When
        let level1 = sut.calculateZoomLevel(from: span1)
        let level2 = sut.calculateZoomLevel(from: span2)
        
        // Then
        XCTAssertGreaterThan(level1, level2) // より小さいspanはより高いズームレベル
        XCTAssertGreaterThan(level1, 0)
        XCTAssertLessThanOrEqual(level1, 20)
    }
    
    // MARK: - Map Style Tests
    
    func testDefaultMapStyle() {
        // Then
        XCTAssertEqual(sut.currentMapStyle, .standard)
    }
    
    func testMapStyleToggle() {
        // Given
        let initialStyle = sut.currentMapStyle
        
        // When
        sut.toggleMapStyle()
        
        // Then
        XCTAssertNotEqual(sut.currentMapStyle, initialStyle)
        XCTAssertEqual(sut.currentMapStyle, .hybrid)
    }
    
    func testMapStyleCycle() {
        // Given
        let styles: [MapStyle] = [.standard, .hybrid, .imagery]
        
        // When & Then
        for expectedStyle in styles {
            XCTAssertEqual(sut.currentMapStyle, expectedStyle)
            sut.toggleMapStyle()
        }
        
        // 一周して元に戻る
        XCTAssertEqual(sut.currentMapStyle, .standard)
    }
    
    func testMapStyleToMapType() {
        // Given & When & Then
        XCTAssertEqual(sut.mapTypeForStyle(.standard), .standard)
        XCTAssertEqual(sut.mapTypeForStyle(.hybrid), .hybrid)
        XCTAssertEqual(sut.mapTypeForStyle(.imagery), .satellite)
    }
    
    // MARK: - Map Orientation Tests
    
    func testDefaultMapOrientation() {
        // Then
        XCTAssertTrue(sut.isNorthUp)
        XCTAssertFalse(sut.isHeadingUp)
    }
    
    func testToggleMapOrientation() {
        // Given
        let initialNorthUp = sut.isNorthUp
        
        // When
        sut.toggleMapOrientation()
        
        // Then
        XCTAssertEqual(sut.isNorthUp, !initialNorthUp)
        XCTAssertEqual(sut.isHeadingUp, initialNorthUp)
    }
    
    func testMapOrientationToggleBackAndForth() {
        // When & Then
        sut.toggleMapOrientation()
        XCTAssertFalse(sut.isNorthUp)
        XCTAssertTrue(sut.isHeadingUp)
        
        sut.toggleMapOrientation()
        XCTAssertTrue(sut.isNorthUp)
        XCTAssertFalse(sut.isHeadingUp)
    }
    
    func testCalculateHeadingRotation() {
        // Given
        let heading1: Double = 90  // 東向き
        let heading2: Double = 180 // 南向き
        let heading3: Double = 270 // 西向き
        let heading4: Double = 0   // 北向き
        
        // When & Then
        XCTAssertEqual(sut.calculateHeadingRotation(heading1), -90, accuracy: 0.1)
        XCTAssertEqual(sut.calculateHeadingRotation(heading2), -180, accuracy: 0.1)
        XCTAssertEqual(sut.calculateHeadingRotation(heading3), -270, accuracy: 0.1)
        XCTAssertEqual(sut.calculateHeadingRotation(heading4), 0, accuracy: 0.1)
    }
}