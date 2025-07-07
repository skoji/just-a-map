import XCTest
@testable import JustAMap

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
        XCTAssertEqual(formatted.primaryText, "千代田区")
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
}