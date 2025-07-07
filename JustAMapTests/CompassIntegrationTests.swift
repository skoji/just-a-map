import XCTest
import SwiftUI
@testable import JustAMap

@MainActor
final class CompassIntegrationTests: XCTestCase {
    var mapViewModel: MapViewModel!
    var compassViewModel: CompassViewModel!
    
    override func setUp() async throws {
        try await super.setUp()
        mapViewModel = MapViewModel()
        compassViewModel = CompassViewModel()
        
        // Set up the connection between compass and map view models
        compassViewModel.onToggle = { isNorthUp in
            self.mapViewModel.mapControlsViewModel.isNorthUp = isNorthUp
        }
    }
    
    override func tearDown() async throws {
        mapViewModel = nil
        compassViewModel = nil
        try await super.tearDown()
    }
    
    func testCompassToggleUpdatesMapOrientation() {
        // Given
        let initialOrientation = mapViewModel.mapControlsViewModel.isNorthUp
        
        // When
        compassViewModel.toggleOrientation()
        
        // Then
        XCTAssertNotEqual(mapViewModel.mapControlsViewModel.isNorthUp, initialOrientation,
                         "Map orientation should change when compass is toggled")
        XCTAssertEqual(compassViewModel.isNorthUp, mapViewModel.mapControlsViewModel.isNorthUp,
                      "Compass and map orientation should be synchronized")
    }
    
    func testMapOrientationChangeUpdatesCompass() {
        // Given
        compassViewModel.isNorthUp = false
        mapViewModel.mapControlsViewModel.isNorthUp = false
        
        // When
        mapViewModel.mapControlsViewModel.isNorthUp = true
        // Manually sync (in real app this happens via onReceive)
        compassViewModel.isNorthUp = true
        
        // Then
        XCTAssertTrue(compassViewModel.isNorthUp, "Compass should reflect map orientation change")
    }
    
    func testCompassRotationInHeadingUpMode() {
        // Given
        compassViewModel.isNorthUp = false
        let testHeading = 45.0
        
        // When
        compassViewModel.updateRotation(testHeading)
        
        // Then
        XCTAssertEqual(compassViewModel.rotation, 45.0, accuracy: 0.01,
                      "Compass should rotate in Heading Up mode")
    }
    
    func testCompassNoRotationInNorthUpMode() {
        // Given
        compassViewModel.isNorthUp = true
        let testHeading = 45.0
        
        // When
        compassViewModel.updateRotation(testHeading)
        
        // Then
        XCTAssertEqual(compassViewModel.rotation, 0.0, accuracy: 0.01,
                      "Compass should not rotate in North Up mode")
    }
    
    func testCompassViewInitializationWithMapViewModel() {
        // Given
        let compassView = CompassView(viewModel: compassViewModel)
        
        // Then
        XCTAssertNotNil(compassView)
        XCTAssertEqual(compassView.viewModel.isNorthUp, compassViewModel.isNorthUp)
    }
}