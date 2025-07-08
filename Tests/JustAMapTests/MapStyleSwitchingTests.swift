import XCTest
@testable import JustAMap

/// 地図スタイル切り替え時の挙動をテストするクラス
@MainActor
class MapStyleSwitchingTests: XCTestCase {
    var mapControlsViewModel: MapControlsViewModel!
    
    override func setUp() async throws {
        try await super.setUp()
        mapControlsViewModel = MapControlsViewModel()
    }
    
    override func tearDown() async throws {
        mapControlsViewModel = nil
        try await super.tearDown()
    }
    
    /// 地図スタイル切り替え時にズームレベルが保持されることをテスト
    func testMapStyleChangePreservesZoomLevel() {
        // Given: 特定のズームレベルを設定
        let initialZoomIndex = 5
        mapControlsViewModel.setZoomIndex(initialZoomIndex)
        let initialAltitude = mapControlsViewModel.currentAltitude
        
        // When: 地図スタイルを変更
        let originalStyle = mapControlsViewModel.currentMapStyle
        mapControlsViewModel.toggleMapStyle()
        
        // Then: ズームレベルが保持されている
        XCTAssertEqual(mapControlsViewModel.currentZoomIndex, initialZoomIndex)
        XCTAssertEqual(mapControlsViewModel.currentAltitude, initialAltitude)
        XCTAssertNotEqual(mapControlsViewModel.currentMapStyle, originalStyle)
    }
}