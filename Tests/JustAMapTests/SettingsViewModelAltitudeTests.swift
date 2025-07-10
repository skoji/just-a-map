import XCTest
@testable import JustAMap

final class SettingsViewModelAltitudeTests: XCTestCase {
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
    
    func testInitialAltitudeDisplayEnabled() {
        XCTAssertEqual(sut.isAltitudeDisplayEnabled, mockSettingsStorage.isAltitudeDisplayEnabled)
        XCTAssertFalse(sut.isAltitudeDisplayEnabled) // デフォルトは無効
    }
    
    func testInitialAltitudeUnit() {
        XCTAssertEqual(sut.altitudeUnit, mockSettingsStorage.altitudeUnit)
        XCTAssertEqual(sut.altitudeUnit, .meters) // デフォルトはメートル
    }
    
    func testUpdateAltitudeDisplayEnabled() {
        // 高度表示を有効にする
        sut.isAltitudeDisplayEnabled = true
        XCTAssertTrue(mockSettingsStorage.isAltitudeDisplayEnabled)
        
        // 高度表示を無効にする
        sut.isAltitudeDisplayEnabled = false
        XCTAssertFalse(mockSettingsStorage.isAltitudeDisplayEnabled)
    }
    
    func testUpdateAltitudeUnit() {
        // フィートに変更
        sut.altitudeUnit = .feet
        XCTAssertEqual(mockSettingsStorage.altitudeUnit, .feet)
        
        // メートルに戻す
        sut.altitudeUnit = .meters
        XCTAssertEqual(mockSettingsStorage.altitudeUnit, .meters)
    }
    
    func testAltitudeSettingsIndependentOfOtherSettings() {
        // 他の設定を変更しても高度設定に影響しないことを確認
        let initialAltitudeEnabled = sut.isAltitudeDisplayEnabled
        let initialAltitudeUnit = sut.altitudeUnit
        
        sut.defaultMapStyle = .hybrid
        sut.defaultIsNorthUp = false
        sut.addressFormat = .detailed
        
        XCTAssertEqual(sut.isAltitudeDisplayEnabled, initialAltitudeEnabled)
        XCTAssertEqual(sut.altitudeUnit, initialAltitudeUnit)
    }
}