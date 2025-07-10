import XCTest
@testable import JustAMap

final class MapSettingsStorageAltitudeTests: XCTestCase {
    var sut: MapSettingsStorage!
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
    
    func testAltitudeDisplayEnabledDefaultValue() {
        // 初期値はfalse（高度表示はデフォルトでOFF）
        XCTAssertFalse(sut.isAltitudeDisplayEnabled)
    }
    
    func testSaveAndLoadAltitudeDisplayEnabled() {
        // 高度表示を有効にする
        sut.isAltitudeDisplayEnabled = true
        XCTAssertTrue(sut.isAltitudeDisplayEnabled)
        XCTAssertTrue(mockUserDefaults.bool(forKey: "isAltitudeDisplayEnabled"))
        
        // 高度表示を無効にする
        sut.isAltitudeDisplayEnabled = false
        XCTAssertFalse(sut.isAltitudeDisplayEnabled)
        XCTAssertFalse(mockUserDefaults.bool(forKey: "isAltitudeDisplayEnabled"))
    }
    
    func testAltitudeUnitDefaultValue() {
        // 初期値はメートル
        XCTAssertEqual(sut.altitudeUnit, .meters)
    }
    
    func testSaveAndLoadAltitudeUnit() {
        // フィートに変更
        sut.altitudeUnit = .feet
        XCTAssertEqual(sut.altitudeUnit, .feet)
        XCTAssertEqual(mockUserDefaults.string(forKey: "altitudeUnit"), "feet")
        
        // メートルに戻す
        sut.altitudeUnit = .meters
        XCTAssertEqual(sut.altitudeUnit, .meters)
        XCTAssertEqual(mockUserDefaults.string(forKey: "altitudeUnit"), "meters")
    }
    
    func testLoadAltitudeUnitWithInvalidRawValue() {
        // 無効な値が保存されている場合はデフォルト値を返す
        mockUserDefaults.set("invalid_unit", forKey: "altitudeUnit")
        XCTAssertEqual(sut.altitudeUnit, .meters)
    }
    
    func testLoadAltitudeDisplayEnabledFromExistingData() {
        // 既存のデータが存在する場合
        mockUserDefaults.set(true, forKey: "isAltitudeDisplayEnabled")
        
        // 新しいインスタンスを作成して確認
        let newSut = MapSettingsStorage(userDefaults: mockUserDefaults)
        XCTAssertTrue(newSut.isAltitudeDisplayEnabled)
    }
    
    func testLoadAltitudeUnitFromExistingData() {
        // 既存のデータが存在する場合
        mockUserDefaults.set("feet", forKey: "altitudeUnit")
        
        // 新しいインスタンスを作成して確認
        let newSut = MapSettingsStorage(userDefaults: mockUserDefaults)
        XCTAssertEqual(newSut.altitudeUnit, .feet)
    }
}

// MARK: - Mock UserDefaults for Testing
class MockUserDefaults: UserDefaultsProtocol {
    private var storage: [String: Any] = [:]
    
    func object(forKey defaultName: String) -> Any? {
        return storage[defaultName]
    }
    
    func set(_ value: Any?, forKey defaultName: String) {
        storage[defaultName] = value
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