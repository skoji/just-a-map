import XCTest
@testable import JustAMap

final class CompassViewModelTests: XCTestCase {
    var viewModel: CompassViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = CompassViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
        super.tearDown()
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
}