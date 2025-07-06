import XCTest
import CoreLocation
@testable import JustAMap

final class GeocodeServiceTests: XCTestCase {
    var sut: GeocodeServiceProtocol!
    var mockGeocoder: MockGeocoder!
    
    override func setUp() {
        super.setUp()
        mockGeocoder = MockGeocoder()
        sut = GeocodeService(geocoder: mockGeocoder)
    }
    
    override func tearDown() {
        sut = nil
        mockGeocoder = nil
        super.tearDown()
    }
    
    func testReverseGeocodeSuccess() async throws {
        // Given
        let location = CLLocation(latitude: 35.6762, longitude: 139.6503) // 東京駅
        let expectedPlacemark = MockPlacemark(
            name: "東京駅",
            thoroughfare: "丸の内",
            subThoroughfare: "1-9-1",
            locality: "千代田区",
            administrativeArea: "東京都",
            postalCode: "100-0005",
            country: "日本"
        )
        mockGeocoder.placemarkToReturn = expectedPlacemark
        
        // When
        let address = try await sut.reverseGeocode(location: location)
        
        // Then
        XCTAssertEqual(address.name, "東京駅")
        XCTAssertEqual(address.fullAddress, "東京都千代田区丸の内1-9-1")
        XCTAssertEqual(address.postalCode, "100-0005")
    }
    
    func testReverseGeocodeFailure() async {
        // Given
        let location = CLLocation(latitude: 0, longitude: 0)
        mockGeocoder.errorToThrow = GeocodeError.geocodingFailed
        
        // When/Then
        do {
            _ = try await sut.reverseGeocode(location: location)
            XCTFail("Should throw error")
        } catch {
            XCTAssertEqual(error as? GeocodeError, GeocodeError.geocodingFailed)
        }
    }
    
    func testReverseGeocodeNoResults() async {
        // Given
        let location = CLLocation(latitude: 0, longitude: 0)
        mockGeocoder.placemarkToReturn = nil
        
        // When/Then
        do {
            _ = try await sut.reverseGeocode(location: location)
            XCTFail("Should throw error")
        } catch {
            XCTAssertEqual(error as? GeocodeError, GeocodeError.noResults)
        }
    }
}

// MARK: - Mock Classes
class MockGeocoder: GeocoderProtocol {
    var placemarkToReturn: CLPlacemark?
    var errorToThrow: Error?
    
    func reverseGeocodeLocation(_ location: CLLocation) async throws -> [CLPlacemark] {
        if let error = errorToThrow {
            throw error
        }
        if let placemark = placemarkToReturn {
            return [placemark]
        }
        return []
    }
}

class MockPlacemark: CLPlacemark {
    private let _name: String?
    private let _thoroughfare: String?
    private let _subThoroughfare: String?
    private let _locality: String?
    private let _administrativeArea: String?
    private let _postalCode: String?
    private let _country: String?
    
    init(name: String? = nil,
         thoroughfare: String? = nil,
         subThoroughfare: String? = nil,
         locality: String? = nil,
         administrativeArea: String? = nil,
         postalCode: String? = nil,
         country: String? = nil) {
        self._name = name
        self._thoroughfare = thoroughfare
        self._subThoroughfare = subThoroughfare
        self._locality = locality
        self._administrativeArea = administrativeArea
        self._postalCode = postalCode
        self._country = country
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var name: String? { _name }
    override var thoroughfare: String? { _thoroughfare }
    override var subThoroughfare: String? { _subThoroughfare }
    override var locality: String? { _locality }
    override var administrativeArea: String? { _administrativeArea }
    override var postalCode: String? { _postalCode }
    override var country: String? { _country }
}