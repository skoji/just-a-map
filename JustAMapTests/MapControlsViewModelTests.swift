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
}