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
    private(set) var pausesLocationUpdatesAutomatically: Bool = true
    
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
    
    func adjustUpdateFrequency(forAltitude altitude: Double) {
        // カメラの高度に基づいてdistanceFilterを計算
        // 高度が低いほど（ズームインしているほど）細かく更新（小さいdistanceFilter）
        
        if altitude <= 500 {
            // 非常に詳細なズーム（街区レベル以下）
            distanceFilter = 5.0
        } else if altitude <= 2000 {
            // 詳細なズーム（地区レベル以下）
            distanceFilter = 10.0
        } else if altitude <= 10000 {
            // 標準的なズーム（市レベル以下）
            distanceFilter = 20.0
        } else {
            // 広域ズーム（市レベルより広域）
            distanceFilter = 50.0
        }
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
    
    /// テスト用: 位置情報更新の一時停止をシミュレート
    func simulateLocationUpdatesPaused() {
        delegate?.locationManagerDidPauseLocationUpdates(self)
    }
    
    /// テスト用: 位置情報更新の再開をシミュレート
    func simulateLocationUpdatesResumed() {
        delegate?.locationManagerDidResumeLocationUpdates(self)
    }
    
    /// テスト用: 常に一時停止を有効化
    func updatePausesLocationUpdatesAutomatically(for settings: MapSettingsStorageProtocol) {
        pausesLocationUpdatesAutomatically = true
    }
}
