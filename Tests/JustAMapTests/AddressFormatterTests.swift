import XCTest
@testable import JustAMapCore

final class AddressFormatterTests: XCTestCase {
    var sut: AddressFormatter!
    var mockSettingsStorage: MockMapSettingsStorage!
    
    override func setUp() {
        super.setUp()
        mockSettingsStorage = MockMapSettingsStorage()
        mockSettingsStorage.addressFormat = .standard // テストはstandardフォーマットを期待
        sut = AddressFormatter(settingsStorage: mockSettingsStorage)
    }
    
    override func tearDown() {
        sut = nil
        mockSettingsStorage = nil
        super.tearDown()
    }
    
    func testFormatFullAddress() {
        // Given
        let address = Address(
            name: "東京駅",
            fullAddress: "東京都千代田区丸の内1-9-1",
            postalCode: "100-0005",
            locality: "千代田区",
            subAdministrativeArea: nil,
            administrativeArea: "東京都",
            country: "日本"
        )
        
        // When
        let formatted = sut.formatForDisplay(address)
        
        // Then
        XCTAssertEqual(formatted.primaryText, "東京駅")
        XCTAssertEqual(formatted.secondaryText, "東京都千代田区丸の内1-9-1")
        XCTAssertEqual(formatted.postalCode, "〒100-0005")
    }
    
    func testFormatAddressWithoutName() {
        // Given
        let address = Address(
            name: nil,
            fullAddress: "東京都千代田区丸の内1-9-1",
            postalCode: "100-0005",
            locality: "千代田区",
            subAdministrativeArea: nil,
            administrativeArea: "東京都",
            country: "日本"
        )
        
        // When
        let formatted = sut.formatForDisplay(address)
        
        // Then
        XCTAssertEqual(formatted.primaryText, "東京都 千代田区")
        XCTAssertEqual(formatted.secondaryText, "東京都千代田区丸の内1-9-1")
    }
    
    func testFormatAddressWithoutPostalCode() {
        // Given
        let address = Address(
            name: "東京駅",
            fullAddress: "東京都千代田区丸の内1-9-1",
            postalCode: nil,
            locality: "千代田区",
            subAdministrativeArea: nil,
            administrativeArea: "東京都",
            country: "日本"
        )
        
        // When
        let formatted = sut.formatForDisplay(address)
        
        // Then
        XCTAssertNil(formatted.postalCode)
    }
    
    func testFormatMinimalAddress() {
        // Given
        let address = Address(
            name: nil,
            fullAddress: "不明な場所",
            postalCode: nil,
            locality: nil,
            subAdministrativeArea: nil,
            administrativeArea: nil,
            country: nil
        )
        
        // When
        let formatted = sut.formatForDisplay(address)
        
        // Then
        XCTAssertEqual(formatted.primaryText, "現在地")
        XCTAssertEqual(formatted.secondaryText, "不明な場所")
        XCTAssertNil(formatted.postalCode)
    }
    
    func testStandardFormatWithoutNameShowsAdministrativeAreaAndSubAdministrativeArea() {
        // Given
        let address = Address(
            name: nil,
            fullAddress: "神奈川県横浜市西区みなとみらい2-3-1",
            postalCode: "220-0012",
            locality: "西区",
            subAdministrativeArea: "横浜市",
            administrativeArea: "神奈川県",
            country: "日本"
        )
        
        // When
        let formatted = sut.formatForDisplay(address)
        
        // Then
        XCTAssertEqual(formatted.primaryText, "神奈川県 横浜市")
        XCTAssertEqual(formatted.secondaryText, "神奈川県横浜市西区みなとみらい2-3-1")
    }
    
    func testStandardFormatWithoutNameAndSubAdministrativeAreaShowsAdministrativeAreaAndLocality() {
        // Given
        let address = Address(
            name: nil,
            fullAddress: "東京都千代田区丸の内1-9-1",
            postalCode: "100-0005",
            locality: "千代田区",
            subAdministrativeArea: nil,
            administrativeArea: "東京都",
            country: "日本"
        )
        
        // When
        let formatted = sut.formatForDisplay(address)
        
        // Then
        XCTAssertEqual(formatted.primaryText, "東京都 千代田区")
        XCTAssertEqual(formatted.secondaryText, "東京都千代田区丸の内1-9-1")
    }
    
    func testStandardFormatWithNameShowsName() {
        // Given
        let address = Address(
            name: "横浜ランドマークタワー",
            fullAddress: "神奈川県横浜市西区みなとみらい2-2-1",
            postalCode: "220-8138",
            locality: "西区",
            subAdministrativeArea: "横浜市",
            administrativeArea: "神奈川県",
            country: "日本"
        )
        
        // When
        let formatted = sut.formatForDisplay(address)
        
        // Then
        XCTAssertEqual(formatted.primaryText, "横浜ランドマークタワー")
        XCTAssertEqual(formatted.secondaryText, "神奈川県横浜市西区みなとみらい2-2-1")
    }
}