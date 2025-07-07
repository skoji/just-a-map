import Foundation
import CoreLocation

/// ジオコーディング関連のエラー
enum GeocodeError: Error, Equatable {
    case geocodingFailed
    case noResults
    case invalidLocation
    
    var localizedDescription: String {
        switch self {
        case .geocodingFailed:
            return "住所の取得に失敗しました"
        case .noResults:
            return "住所が見つかりませんでした"
        case .invalidLocation:
            return "無効な位置情報です"
        }
    }
}

/// 住所情報を表す構造体
struct Address: Equatable {
    let name: String?
    let fullAddress: String?
    let postalCode: String?
    let locality: String?         // 市区町村
    let subAdministrativeArea: String? // 郡・地区
    let administrativeArea: String? // 都道府県
    let country: String?
}

/// ジオコーディングサービスのプロトコル
protocol GeocodeServiceProtocol {
    func reverseGeocode(location: CLLocation) async throws -> Address
}

/// CLGeocoderのプロトコル（テスト用）
protocol GeocoderProtocol {
    func reverseGeocodeLocation(_ location: CLLocation) async throws -> [CLPlacemark]
}

/// CLGeocoderをGeocoderProtocolに準拠させる
extension CLGeocoder: GeocoderProtocol {}

/// 逆ジオコーディングサービスの実装
class GeocodeService: GeocodeServiceProtocol {
    private let geocoder: GeocoderProtocol
    
    init(geocoder: GeocoderProtocol = CLGeocoder()) {
        self.geocoder = geocoder
    }
    
    func reverseGeocode(location: CLLocation) async throws -> Address {
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            
            guard let placemark = placemarks.first else {
                throw GeocodeError.noResults
            }
            
            // 住所を構築
            let fullAddress = buildFullAddress(from: placemark)
            
            // デバッグ用
            print("Debug - GeocodeService placemark:")
            print("  name: \(placemark.name ?? "nil")")
            print("  administrativeArea: \(placemark.administrativeArea ?? "nil")")
            print("  subAdministrativeArea: \(placemark.subAdministrativeArea ?? "nil")")
            print("  locality: \(placemark.locality ?? "nil")")
            
            return Address(
                name: placemark.name,
                fullAddress: fullAddress,
                postalCode: placemark.postalCode,
                locality: placemark.locality,
                subAdministrativeArea: placemark.subAdministrativeArea,
                administrativeArea: placemark.administrativeArea,
                country: placemark.country
            )
        } catch {
            if error is GeocodeError {
                throw error
            }
            throw GeocodeError.geocodingFailed
        }
    }
    
    private func buildFullAddress(from placemark: CLPlacemark) -> String {
        var components: [String] = []
        
        // 日本の住所フォーマット: 都道府県 > 郡・市 > 区市町村 > 番地
        if let administrativeArea = placemark.administrativeArea {
            components.append(administrativeArea)
        }
        if let subAdministrativeArea = placemark.subAdministrativeArea {
            components.append(subAdministrativeArea)
        }
        if let locality = placemark.locality {
            components.append(locality)
        }
        if let thoroughfare = placemark.thoroughfare {
            components.append(thoroughfare)
        }
        if let subThoroughfare = placemark.subThoroughfare {
            components.append(subThoroughfare)
        }
        
        return components.joined()
    }
}