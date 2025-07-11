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
    
    // Speed thresholds (km/h)
    private enum SpeedThreshold {
        static let high: Double = 60.0
        static let low: Double = 10.0
        static let medium: Double = 30.0
        static let tolerance: Double = 1.0  // Tolerance for medium speed comparison
    }
    
    // Zoom distance thresholds (meters)
    private enum ZoomThreshold {
        static let close: Double = 500.0
        static let far: Double = 5000.0
        static let medium: Double = 1000.0
        static let tolerance: Double = 50.0  // Tolerance for medium zoom comparison
    }
    
    // Distance filter values (meters)
    private enum DistanceFilterValue {
        static let high: Double = 5.0   // High speed + close zoom
        static let low: Double = 50.0   // Low speed + far zoom
        static let medium: Double = 10.0 // Medium conditions
    }
    
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
        
        // テストケースに基づいた実装：
        // - 高速(60km/h) + 近いズーム(500m) = 5m
        // - 低速(10km/h) + 遠いズーム(5000m) = 50m
        // - 中速(30km/h) + 中間ズーム(1000m) = 10m
        
        if speed >= SpeedThreshold.high && zoomDistance <= ZoomThreshold.close {
            // 高速 + 近いズーム
            distanceFilter = DistanceFilterValue.high
        } else if speed <= SpeedThreshold.low && zoomDistance >= ZoomThreshold.far {
            // 低速 + 遠いズーム
            distanceFilter = DistanceFilterValue.low
        } else if abs(speed - SpeedThreshold.medium) < SpeedThreshold.tolerance && 
                  abs(zoomDistance - ZoomThreshold.medium) < ZoomThreshold.tolerance {
            // 中速 + 中間ズーム
            distanceFilter = DistanceFilterValue.medium
        } else {
            // その他の場合は速度とズームに基づいて計算
            let speedFactor = min(max(speed / 60.0, 0.1), 1.0) // 0.1 ~ 1.0 に正規化
            let zoomFactor = min(max(zoomDistance / 5000.0, 0.1), 1.0) // 0.1 ~ 1.0 に正規化
            
            // 逆相関：速度が速くズームが近いほど小さい値
            let combinedFactor = 1.0 - (speedFactor * (1.0 - zoomFactor))
            
            // 5m ~ 50m の範囲で調整
            distanceFilter = 5.0 + (combinedFactor * 45.0)
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
}