import XCTest
@testable import JustAMap

/// 多言語化機能のテスト
final class LocalizationTests: XCTestCase {
    
    func testStringLocalizationExtension() {
        // 英語のキーが存在することを確認
        let englishText = "settings.title".localized
        XCTAssertFalse(englishText.isEmpty, "Localized string should not be empty")
        
        // フォーマット付きのローカライゼーションをテスト
        let errorMessage = "location.error.update_failed".localized(with: "Test error")
        XCTAssertTrue(errorMessage.contains("Test error"), "Error message should contain the formatted argument")
    }
    
    func testAddressFormatLocalization() {
        // 各住所フォーマットの表示名がローカライズされていることを確認
        let standard = AddressFormat.standard
        let detailed = AddressFormat.detailed
        let simple = AddressFormat.simple
        
        XCTAssertFalse(standard.displayName.isEmpty, "Standard format display name should not be empty")
        XCTAssertFalse(detailed.displayName.isEmpty, "Detailed format display name should not be empty")
        XCTAssertFalse(simple.displayName.isEmpty, "Simple format display name should not be empty")
        
        XCTAssertFalse(standard.description.isEmpty, "Standard format description should not be empty")
        XCTAssertFalse(detailed.description.isEmpty, "Detailed format description should not be empty")
        XCTAssertFalse(simple.description.isEmpty, "Simple format description should not be empty")
    }
    
    func testMapStyleLocalization() {
        // 各地図スタイルの表示名がローカライズされていることを確認
        let standard = MapStyle.standard
        let hybrid = MapStyle.hybrid
        let imagery = MapStyle.imagery
        
        XCTAssertFalse(standard.displayName.isEmpty, "Standard map style display name should not be empty")
        XCTAssertFalse(hybrid.displayName.isEmpty, "Hybrid map style display name should not be empty")
        XCTAssertFalse(imagery.displayName.isEmpty, "Imagery map style display name should not be empty")
    }
    
    func testLocationErrorLocalization() {
        // 位置情報エラーメッセージがローカライズされていることを確認
        let authError = LocationError.authorizationDenied
        let servicesError = LocationError.locationServicesDisabled
        let updateError = LocationError.locationUpdateFailed("Network error")
        
        XCTAssertFalse(authError.localizedDescription.isEmpty, "Authorization error description should not be empty")
        XCTAssertFalse(servicesError.localizedDescription.isEmpty, "Services error description should not be empty")
        XCTAssertFalse(updateError.localizedDescription.isEmpty, "Update error description should not be empty")
        XCTAssertTrue(updateError.localizedDescription.contains("Network error"), "Update error should contain the reason")
    }
    
    func testAddressFormatterWithLocalization() {
        let storage = MockMapSettingsStorage()
        let formatter = AddressFormatter(settingsStorage: storage)
        
        let address = Address(
            name: nil,
            fullAddress: nil,
            postalCode: nil,
            locality: nil,
            subAdministrativeArea: nil,
            administrativeArea: nil,
            country: nil
        )
        
        let formatted = formatter.formatForDisplay(address)
        
        // 空の住所の場合、"現在地"/"Current Location"のローカライズされた文字列が使用されることを確認
        let expectedCurrentLocation = "address.current_location".localized
        XCTAssertEqual(formatted.primaryText, expectedCurrentLocation, "Empty address should show localized current location")
    }
}