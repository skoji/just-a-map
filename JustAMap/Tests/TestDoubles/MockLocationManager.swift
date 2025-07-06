import Foundation
import CoreLocation
@testable import JustAMap

/// テスト用のLocationManagerモック
class MockLocationManager: LocationManagerProtocol {
    weak var delegate: LocationManagerDelegate?
    
    private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    private(set) var didRequestAuthorization = false
    private(set) var isUpdatingLocation = false
    
    func requestLocationPermission() {
        didRequestAuthorization = true
    }
    
    func startLocationUpdates() {
        isUpdatingLocation = true
    }
    
    func stopLocationUpdates() {
        isUpdatingLocation = false
    }
    
    // MARK: - Test Helpers
    
    /// テスト用: 位置情報の更新をシミュレート
    func simulateLocationUpdate(_ location: CLLocation) {
        delegate?.locationManager(self, didUpdateLocation: location)
    }
    
    /// テスト用: エラーをシミュレート
    func simulateError(_ error: Error) {
        delegate?.locationManager(self, didFailWithError: error)
    }
    
    /// テスト用: 認証ステータスの変更をシミュレート
    func simulateAuthorizationChange(_ status: CLAuthorizationStatus) {
        authorizationStatus = status
        delegate?.locationManager(self, didChangeAuthorization: status)
    }
}