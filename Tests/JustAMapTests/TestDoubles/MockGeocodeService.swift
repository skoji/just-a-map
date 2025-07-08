import Foundation
import CoreLocation
@testable import JustAMapCore

class MockGeocodeService: GeocodeServiceProtocol {
    var reverseGeocodeResult: Result<Address, Error> = .success(Address(
        name: "東京駅",
        fullAddress: "東京都千代田区丸の内１丁目９−１",
        postalCode: "100-0005",
        locality: "千代田区",
        subAdministrativeArea: nil,
        administrativeArea: "東京都",
        country: "日本"
    ))
    
    func reverseGeocode(location: CLLocation) async throws -> Address {
        switch reverseGeocodeResult {
        case .success(let address):
            return address
        case .failure(let error):
            throw error
        }
    }
}