import XCTest
import MapKit
@testable import JustAMapKit

final class MapSettingsStorageTests: XCTestCase {
    var sut: MapSettingsStorageProtocol!
    var mockUserDefaults: MockUserDefaults!
    
    override func setUp() {
        super.setUp()
        mockUserDefaults = MockUserDefaults()
        sut = MapSettingsStorage(userDefaults: mockUserDefaults)
    }
    
    override func tearDown() {
        sut = nil
        mockUserDefaults = nil
        super.tearDown()
    }
    
    func testSaveMapStyle() {
        // Given
        let style = MapStyle.hybrid
        
        // When
        sut.saveMapStyle(style)
        
        // Then
        XCTAssertEqual(mockUserDefaults.storage["mapStyle"] as? String, style.rawValue)
    }
    
    func testLoadMapStyle() {
        // Given
        mockUserDefaults.storage["mapStyle"] = MapStyle.imagery.rawValue
        
        // When
        let style = sut.loadMapStyle()
        
        // Then
        XCTAssertEqual(style, .imagery)
    }
    
    func testLoadMapStyleDefault() {
        // Given - UserDefaultsに何も保存されていない
        
        // When
        let style = sut.loadMapStyle()
        
        // Then
        XCTAssertEqual(style, .standard)
    }
    
    func testSaveMapOrientation() {
        // Given
        let isNorthUp = false
        
        // When
        sut.saveMapOrientation(isNorthUp: isNorthUp)
        
        // Then
        XCTAssertEqual(mockUserDefaults.storage["isNorthUp"] as? Bool, false)
    }
    
    func testLoadMapOrientation() {
        // Given
        mockUserDefaults.storage["isNorthUp"] = false
        
        // When
        let isNorthUp = sut.loadMapOrientation()
        
        // Then
        XCTAssertFalse(isNorthUp)
    }
    
    func testLoadMapOrientationDefault() {
        // Given - UserDefaultsに何も保存されていない
        
        // When
        let isNorthUp = sut.loadMapOrientation()
        
        // Then
        XCTAssertTrue(isNorthUp) // デフォルトはNorth Up
    }
    
    func testSaveZoomLevel() {
        // Given
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        
        // When
        sut.saveZoomLevel(span: span)
        
        // Then
        XCTAssertEqual(mockUserDefaults.storage["zoomLatDelta"] as? Double, 0.05)
        XCTAssertEqual(mockUserDefaults.storage["zoomLonDelta"] as? Double, 0.05)
    }
    
    func testLoadZoomLevel() {
        // Given
        mockUserDefaults.storage["zoomLatDelta"] = 0.1
        mockUserDefaults.storage["zoomLonDelta"] = 0.1
        
        // When
        let span = sut.loadZoomLevel()
        
        // Then
        XCTAssertEqual(span?.latitudeDelta, 0.1)
        XCTAssertEqual(span?.longitudeDelta, 0.1)
    }
    
    func testLoadZoomLevelDefault() {
        // Given - UserDefaultsに何も保存されていない
        
        // When
        let span = sut.loadZoomLevel()
        
        // Then
        XCTAssertNil(span)
    }
    
    func testSaveZoomIndex() {
        // Given
        let index = 7
        
        // When
        sut.saveZoomIndex(index)
        
        // Then
        XCTAssertEqual(mockUserDefaults.storage["zoomIndex"] as? Int, 7)
    }
    
    func testLoadZoomIndex() {
        // Given
        mockUserDefaults.storage["zoomIndex"] = 3
        
        // When
        let index = sut.loadZoomIndex()
        
        // Then
        XCTAssertEqual(index, 3)
    }
    
    func testLoadZoomIndexDefault() {
        // Given - UserDefaultsに何も保存されていない
        
        // When
        let index = sut.loadZoomIndex()
        
        // Then
        XCTAssertNil(index)
    }
    
    // MARK: - New Settings Tests
    
    func testDefaultZoomIndex() {
        // Given
        let newValue = 8
        
        // When
        sut.defaultZoomIndex = newValue
        
        // Then
        XCTAssertEqual(mockUserDefaults.storage["defaultZoomIndex"] as? Int, newValue)
        XCTAssertEqual(sut.defaultZoomIndex, newValue)
    }
    
    func testDefaultZoomIndexDefaultValue() {
        // Given - UserDefaultsに何も保存されていない
        
        // When
        let value = sut.defaultZoomIndex
        
        // Then
        XCTAssertEqual(value, 5) // デフォルト値
    }
    
    func testDefaultMapStyle() {
        // Given
        let newValue = MapStyle.hybrid
        
        // When
        sut.defaultMapStyle = newValue
        
        // Then
        XCTAssertEqual(mockUserDefaults.storage["defaultMapStyle"] as? String, newValue.rawValue)
        XCTAssertEqual(sut.defaultMapStyle, newValue)
    }
    
    func testDefaultMapStyleDefaultValue() {
        // Given - UserDefaultsに何も保存されていない
        
        // When
        let value = sut.defaultMapStyle
        
        // Then
        XCTAssertEqual(value, .standard) // デフォルト値
    }
    
    func testDefaultIsNorthUp() {
        // Given
        let newValue = false
        
        // When
        sut.defaultIsNorthUp = newValue
        
        // Then
        XCTAssertEqual(mockUserDefaults.storage["defaultIsNorthUp"] as? Bool, newValue)
        XCTAssertEqual(sut.defaultIsNorthUp, newValue)
    }
    
    func testDefaultIsNorthUpDefaultValue() {
        // Given - UserDefaultsに何も保存されていない
        
        // When
        let value = sut.defaultIsNorthUp
        
        // Then
        XCTAssertTrue(value) // デフォルトはNorth Up
    }
    
    func testAddressFormat() {
        // Given
        let newValue = AddressFormat.detailed
        
        // When
        sut.addressFormat = newValue
        
        // Then
        XCTAssertEqual(mockUserDefaults.storage["addressFormat"] as? String, newValue.rawValue)
        XCTAssertEqual(sut.addressFormat, newValue)
    }
    
    func testAddressFormatDefaultValue() {
        // Given - UserDefaultsに何も保存されていない
        
        // When
        let value = sut.addressFormat
        
        // Then
        XCTAssertEqual(value, .standard) // デフォルト値
    }
    
    // MARK: - First Launch Tests
    
    func testIsFirstLaunchReturnsTrueWhenNoSettingsSaved() {
        // Given - UserDefaultsに何も保存されていない
        
        // When
        let isFirstLaunch = sut.isFirstLaunch()
        
        // Then
        XCTAssertTrue(isFirstLaunch)
    }
    
    func testIsFirstLaunchReturnsFalseWhenAnySettingSaved() {
        // Given - いずれかの設定が保存されている
        mockUserDefaults.storage["mapStyle"] = MapStyle.standard.rawValue
        
        // When
        let isFirstLaunch = sut.isFirstLaunch()
        
        // Then
        XCTAssertFalse(isFirstLaunch)
    }
    
    func testIsFirstLaunchReturnsFalseWhenAllSettingsSaved() {
        // Given - すべての設定が保存されている
        mockUserDefaults.storage["mapStyle"] = MapStyle.hybrid.rawValue
        mockUserDefaults.storage["isNorthUp"] = false
        mockUserDefaults.storage["zoomIndex"] = 7
        
        // When
        let isFirstLaunch = sut.isFirstLaunch()
        
        // Then
        XCTAssertFalse(isFirstLaunch)
    }
}

// MARK: - Mock UserDefaults
class MockUserDefaults: UserDefaultsProtocol {
    var storage: [String: Any] = [:]
    
    func object(forKey defaultName: String) -> Any? {
        return storage[defaultName]
    }
    
    func set(_ value: Any?, forKey defaultName: String) {
        if let value = value {
            storage[defaultName] = value
        } else {
            storage.removeValue(forKey: defaultName)
        }
    }
    
    func bool(forKey defaultName: String) -> Bool {
        return storage[defaultName] as? Bool ?? false
    }
    
    func double(forKey defaultName: String) -> Double {
        return storage[defaultName] as? Double ?? 0.0
    }
    
    func string(forKey defaultName: String) -> String? {
        return storage[defaultName] as? String
    }
    
    func integer(forKey defaultName: String) -> Int {
        return storage[defaultName] as? Int ?? 0
    }
}