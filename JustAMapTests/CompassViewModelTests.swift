import XCTest
@testable import JustAMap

@MainActor
final class CompassViewModelTests: XCTestCase {
    var viewModel: CompassViewModel!
    
    override func setUp() async throws {
        try await super.setUp()
        viewModel = CompassViewModel()
    }
    
    override func tearDown() async throws {
        viewModel = nil
        try await super.tearDown()
    }
    
    func testInitialState() {
        XCTAssertEqual(viewModel.rotation, 0, "Initial rotation should be 0")
        XCTAssertFalse(viewModel.isNorthUp, "Initial state should be Heading Up (isNorthUp = false)")
    }
    
    func testUpdateRotationInHeadingUpMode() {
        viewModel.isNorthUp = false
        viewModel.updateRotation(45)
        
        XCTAssertEqual(viewModel.rotation, 45, accuracy: 0.01, "Rotation should be updated to 45 degrees in Heading Up mode")
    }
    
    func testUpdateRotationInNorthUpMode() {
        viewModel.isNorthUp = true
        viewModel.updateRotation(45)
        
        XCTAssertEqual(viewModel.rotation, 0, accuracy: 0.01, "Rotation should remain 0 in North Up mode")
    }
    
    func testToggleOrientation() {
        let initialState = viewModel.isNorthUp
        viewModel.toggleOrientation()
        
        XCTAssertNotEqual(viewModel.isNorthUp, initialState, "Orientation should toggle")
        
        viewModel.toggleOrientation()
        XCTAssertEqual(viewModel.isNorthUp, initialState, "Orientation should toggle back")
    }
    
    func testOnToggleCallback() {
        var callbackExecuted = false
        var newOrientationState: Bool?
        
        viewModel.onToggle = { isNorthUp in
            callbackExecuted = true
            newOrientationState = isNorthUp
        }
        
        viewModel.toggleOrientation()
        
        XCTAssertTrue(callbackExecuted, "Callback should be executed when toggling")
        XCTAssertEqual(newOrientationState, viewModel.isNorthUp, "Callback should receive the new orientation state")
    }
    
    func testRotationNormalization() {
        viewModel.isNorthUp = false
        
        viewModel.updateRotation(370)
        XCTAssertEqual(viewModel.rotation, 10, accuracy: 0.01, "Rotation should be normalized to 10 degrees")
        
        viewModel.updateRotation(-10)
        XCTAssertEqual(viewModel.rotation, 350, accuracy: 0.01, "Negative rotation should be normalized to 350 degrees")
        
        viewModel.updateRotation(720)
        XCTAssertEqual(viewModel.rotation, 0, accuracy: 0.01, "Multiple full rotations should be normalized to 0 degrees")
    }
    
    func testSyncOrientationToNorthUp() {
        viewModel.rotation = 45.0
        viewModel.isNorthUp = false
        
        viewModel.syncOrientation(isNorthUp: true)
        
        XCTAssertTrue(viewModel.isNorthUp, "Should be in North Up mode")
        XCTAssertEqual(viewModel.rotation, 0, accuracy: 0.01, "Rotation should be reset to 0 when syncing to North Up")
    }
    
    func testSyncOrientationToHeadingUp() {
        viewModel.rotation = 0
        viewModel.isNorthUp = true
        
        viewModel.syncOrientation(isNorthUp: false, currentHeading: 90.0)
        
        XCTAssertFalse(viewModel.isNorthUp, "Should be in Heading Up mode")
        XCTAssertEqual(viewModel.rotation, 90.0, accuracy: 0.01, "Rotation should be updated to current heading when syncing to Heading Up")
    }
    
    func testSyncOrientationToHeadingUpWithDefaultHeading() {
        viewModel.rotation = 45.0
        viewModel.isNorthUp = true
        
        viewModel.syncOrientation(isNorthUp: false)
        
        XCTAssertFalse(viewModel.isNorthUp, "Should be in Heading Up mode")
        XCTAssertEqual(viewModel.rotation, 0, accuracy: 0.01, "Rotation should be 0 when no heading is provided")
    }
}