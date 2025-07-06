import XCTest
import MapKit
@testable import JustAMap

final class SettingsViewModelTests: XCTestCase {
    var sut: SettingsViewModel!
    var mockSettingsStorage: MockMapSettingsStorage!
    
    override func setUp() {
        super.setUp()
        mockSettingsStorage = MockMapSettingsStorage()
        sut = SettingsViewModel(settingsStorage: mockSettingsStorage)
    }
    
    override func tearDown() {
        sut = nil
        mockSettingsStorage = nil
        super.tearDown()
    }
    
    func testInitialValues() {
        XCTAssertEqual(sut.defaultZoomIndex, mockSettingsStorage.defaultZoomIndex)
        XCTAssertEqual(sut.defaultMapStyle, mockSettingsStorage.defaultMapStyle)
        XCTAssertEqual(sut.defaultIsNorthUp, mockSettingsStorage.defaultIsNorthUp)
        XCTAssertEqual(sut.addressFormat, mockSettingsStorage.addressFormat)
    }
    
    func testUpdateDefaultZoomIndex() {
        let newZoomIndex = 5
        sut.defaultZoomIndex = newZoomIndex
        
        XCTAssertEqual(mockSettingsStorage.defaultZoomIndex, newZoomIndex)
    }
    
    func testUpdateDefaultMapStyle() {
        let newMapStyle = MapStyle.hybrid
        sut.defaultMapStyle = newMapStyle
        
        XCTAssertEqual(mockSettingsStorage.defaultMapStyle, newMapStyle)
    }
    
    func testUpdateDefaultIsNorthUp() {
        let newIsNorthUp = false
        sut.defaultIsNorthUp = newIsNorthUp
        
        XCTAssertEqual(mockSettingsStorage.defaultIsNorthUp, newIsNorthUp)
    }
    
    func testUpdateAddressFormat() {
        let newFormat = AddressFormat.detailed
        sut.addressFormat = newFormat
        
        XCTAssertEqual(mockSettingsStorage.addressFormat, newFormat)
    }
    
    func testZoomLevelDisplayText() {
        sut.defaultZoomIndex = 0
        XCTAssertEqual(sut.zoomLevelDisplayText, "200m")
        
        sut.defaultZoomIndex = 6
        XCTAssertEqual(sut.zoomLevelDisplayText, "20km")
        
        sut.defaultZoomIndex = 11
        XCTAssertEqual(sut.zoomLevelDisplayText, "1,000km")
    }
}

class MockMapSettingsStorage: MapSettingsStorageProtocol {
    var mapStyle: MapStyle = .standard
    var isNorthUp: Bool = true
    var zoomIndex: Int = 5
    var defaultZoomIndex: Int = 5
    var defaultMapStyle: MapStyle = .standard
    var defaultIsNorthUp: Bool = true
    var addressFormat: AddressFormat = .standard
    var mockIsFirstLaunch: Bool = false
    
    func saveMapStyle(_ style: MapStyle) {
        mapStyle = style
    }
    
    func loadMapStyle() -> MapStyle {
        return mapStyle
    }
    
    func saveMapOrientation(isNorthUp: Bool) {
        self.isNorthUp = isNorthUp
    }
    
    func loadMapOrientation() -> Bool {
        return isNorthUp
    }
    
    func saveZoomLevel(span: MKCoordinateSpan) {
        // Not needed for these tests
    }
    
    func loadZoomLevel() -> MKCoordinateSpan? {
        return nil
    }
    
    func saveZoomIndex(_ index: Int) {
        zoomIndex = index
    }
    
    func loadZoomIndex() -> Int? {
        return zoomIndex
    }
    
    func isFirstLaunch() -> Bool {
        return mockIsFirstLaunch
    }
}