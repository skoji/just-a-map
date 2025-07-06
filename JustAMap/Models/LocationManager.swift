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
        let locationError: LocationError
        
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                locationError = .authorizationDenied
            case .locationUnknown:
                locationError = .locationUpdateFailed("位置情報を取得できません")
            default:
                locationError = .locationUpdateFailed(clError.localizedDescription)
            }
        } else {
            locationError = .locationUpdateFailed(error.localizedDescription)
        }
        
        delegate?.locationManager(self, didFailWithError: locationError)
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        delegate?.locationManager(self, didChangeAuthorization: manager.authorizationStatus)
        
        // 許可が得られたら自動的に位置情報更新を開始
        if manager.authorizationStatus == .authorizedWhenInUse || 
           manager.authorizationStatus == .authorizedAlways {
            startLocationUpdates()
        }
    }
}