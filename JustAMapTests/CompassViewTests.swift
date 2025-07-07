import XCTest
import SwiftUI
@testable import JustAMap

@MainActor
final class CompassViewTests: XCTestCase {
    var viewModel: CompassViewModel!
    
    override func setUp() async throws {
        try await super.setUp()
        viewModel = CompassViewModel()
    }
    
    override func tearDown() async throws {
        viewModel = nil
        try await super.tearDown()
    }
    
    func testCompassViewInitialization() {
        let compassView = CompassView(viewModel: viewModel)
        XCTAssertNotNil(compassView)
        XCTAssertEqual(compassView.viewModel.rotation, 0)
        XCTAssertFalse(compassView.viewModel.isNorthUp)
    }
    
    func testCompassViewWithRotation() {
        viewModel.rotation = 90
        let compassView = CompassView(viewModel: viewModel)
        XCTAssertEqual(compassView.viewModel.rotation, 90)
    }
    
    func testCompassViewToggleCallback() {
        var callbackExecuted = false
        var receivedState: Bool?
        
        viewModel.onToggle = { isNorthUp in
            callbackExecuted = true
            receivedState = isNorthUp
        }
        
        let compassView = CompassView(viewModel: viewModel)
        
        // Simulate toggle
        compassView.viewModel.toggleOrientation()
        
        XCTAssertTrue(callbackExecuted)
        XCTAssertNotNil(receivedState)
        XCTAssertEqual(receivedState, viewModel.isNorthUp)
    }
    
    func testCompassConstants() {
        XCTAssertEqual(CompassView.Constants.size, 60)
        XCTAssertEqual(CompassView.Constants.iconSize, 30)
        XCTAssertEqual(CompassView.Constants.borderWidth, 2)
        XCTAssertEqual(CompassView.Constants.shadowRadius, 4)
    }
}