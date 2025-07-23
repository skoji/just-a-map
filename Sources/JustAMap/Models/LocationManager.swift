import Foundation
import CoreLocation

/// 実際のCLLocationManagerをラップし、LocationManagerProtocolに準拠
class LocationManager: NSObject, LocationManagerProtocol {
    weak var delegate: LocationManagerDelegate?
    
    private let locationManager = CLLocationManager()
    
    var authorizationStatus: CLAuthorizationStatus {
        locationManager.authorizationStatus
    }
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10.0 // 10メートル移動したら更新
        locationManager.allowsBackgroundLocationUpdates = false
        locationManager.pausesLocationUpdatesAutomatically = true
        locationManager.activityType = .automotiveNavigation // バイク走行を想定
    }
    
    func requestLocationPermission() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            delegate?.locationManager(self, didFailWithError: LocationError.authorizationDenied)
        case .authorizedWhenInUse, .authorizedAlways:
            // 既に許可されている
            delegate?.locationManager(self, didChangeAuthorization: locationManager.authorizationStatus)
        @unknown default:
            break
        }
    }
    
    func startLocationUpdates() {
        guard CLLocationManager.locationServicesEnabled() else {
            delegate?.locationManager(self, didFailWithError: LocationError.locationServicesDisabled)
            return
        }
        
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading() // Heading Up表示用
        case .notDetermined:
            requestLocationPermission()
        case .denied, .restricted:
            delegate?.locationManager(self, didFailWithError: LocationError.authorizationDenied)
        @unknown default:
            break
        }
    }
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }
    
    func adjustUpdateFrequency(forAltitude altitude: Double) {
        // カメラの高度に基づいてdistanceFilterを計算
        // 高度が低いほど（ズームインしているほど）細かく更新（小さいdistanceFilter）
        
        let newDistanceFilter: CLLocationDistance
        if altitude <= 500 {
            // 非常に詳細なズーム（街区レベル以下）
            newDistanceFilter = 5.0
        } else if altitude <= 2000 {
            // 詳細なズーム（地区レベル以下）
            newDistanceFilter = 10.0
        } else if altitude <= 10000 {
            // 標準的なズーム（市レベル以下）
            newDistanceFilter = 20.0
        } else {
            // 広域ズーム（市レベルより広域）
            newDistanceFilter = 50.0
        }
        
        // 変化が大きい場合のみ更新（頻繁な更新を避ける）
        if abs(locationManager.distanceFilter - newDistanceFilter) > 2.0 {
            locationManager.distanceFilter = newDistanceFilter
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // 精度が極端に悪い場合は無視
        if location.horizontalAccuracy < 0 || location.horizontalAccuracy > 100 {
            return
        }
        
        delegate?.locationManager(self, didUpdateLocation: location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let clError = error as? CLError {
            print("Location error: \(clError.code.rawValue) - \(clError.localizedDescription)")
            
            switch clError.code {
            case .denied:
                delegate?.locationManager(self, didFailWithError: LocationError.authorizationDenied)
            case .locationUnknown:
                // Code 0: 一時的なエラーなので無視（シミュレータでよく発生）
                print("Temporary location error - ignoring")
                return
            default:
                delegate?.locationManager(self, didFailWithError: LocationError.locationUpdateFailed(clError.localizedDescription))
            }
        } else {
            delegate?.locationManager(self, didFailWithError: LocationError.locationUpdateFailed(error.localizedDescription))
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        delegate?.locationManager(self, didChangeAuthorization: manager.authorizationStatus)
        
        // 許可が得られたら自動的に位置情報更新を開始
        if manager.authorizationStatus == .authorizedWhenInUse || 
           manager.authorizationStatus == .authorizedAlways {
            startLocationUpdates()
        }
    }
    
    func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
        delegate?.locationManagerDidPauseLocationUpdates(self)
    }
    
    func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
        delegate?.locationManagerDidResumeLocationUpdates(self)
    }
}