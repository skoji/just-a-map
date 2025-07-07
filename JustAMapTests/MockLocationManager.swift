import Foundation
import CoreLocation
@testable import JustAMap

/// テスト用のLocationManagerモック
class MockLocationManager: LocationManagerProtocol {
    weak var delegate: LocationManagerDelegate?
    
    private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    private(set) var didRequestAuthorization = false
    private(set) var isUpdatingLocation = false
    private(set) var distanceFilter: Double = 10.0
    
    /// テスト用: 現在位置を設定できるプロパティ
    var currentLocation: CLLocation?
    
    func requestLocationPermission() {
        didRequestAuthorization = true
    }
    
    func startLocationUpdates() {
        isUpdatingLocation = true
    }
    
    func stopLocationUpdates() {
        isUpdatingLocation = false
    }
    
    func adjustUpdateFrequency(forSpeed speed: Double, zoomDistance: Double) {
        // 速度とズームレベルに基づいてdistanceFilterを計算
        // 高速 + 近いズーム = 頻繁な更新（小さいdistanceFilter）
        // 低速 + 遠いズーム = 少ない更新（大きいdistanceFilter）
        
        let speedFactor = min(max(speed / 60.0, 0.1), 1.0) // 0.1 ~ 1.0 に正規化
        let zoomFactor = min(max(zoomDistance / 5000.0, 0.1), 1.0) // 0.1 ~ 1.0 に正規化
        
        // 逆相関：速度が速くズームが近いほど小さい値
        let combinedFactor = 1.0 - (speedFactor * (1.0 - zoomFactor))
        
        // 5m ~ 50m の範囲で調整
        distanceFilter = 5.0 + (combinedFactor * 45.0)
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