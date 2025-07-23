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
    
    func adjustUpdateFrequency(forZoomLevel zoomLevel: Double) {
        // ズームレベルに基づいてdistanceFilterを計算
        // ズームインしているほど細かく更新（小さいdistanceFilter）
        
        if zoomLevel >= 16 {
            // 非常に詳細なズーム
            distanceFilter = 5.0
        } else if zoomLevel >= 14 {
            // 詳細なズーム
            distanceFilter = 10.0
        } else if zoomLevel >= 12 {
            // 標準的なズーム
            distanceFilter = 20.0
        } else {
            // 広域ズーム
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
}