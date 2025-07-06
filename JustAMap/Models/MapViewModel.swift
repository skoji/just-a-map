import Foundation
import CoreLocation
import MapKit
import SwiftUI

/// 地図表示のビジネスロジックを管理するViewModel
@MainActor
class MapViewModel: ObservableObject {
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503), // 東京駅をデフォルト
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    @Published var userLocation: CLLocation?
    @Published var isLocationAuthorized = false
    @Published var locationError: LocationError?
    @Published var isFollowingUser = true
    
    private let locationManager: LocationManagerProtocol
    
    init(locationManager: LocationManagerProtocol = LocationManager()) {
        self.locationManager = locationManager
        self.locationManager.delegate = self
    }
    
    func requestLocationPermission() {
        locationManager.requestLocationPermission()
    }
    
    func startLocationTracking() {
        locationManager.startLocationUpdates()
    }
    
    func stopLocationTracking() {
        locationManager.stopLocationUpdates()
    }
    
    func centerOnUserLocation() {
        guard let location = userLocation else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            region = MKCoordinateRegion(
                center: location.coordinate,
                span: region.span
            )
        }
    }
    
    private func updateRegionIfFollowing(location: CLLocation) {
        guard isFollowingUser else { return }
        
        // スムーズなアニメーションで地図を更新
        withAnimation(.easeInOut(duration: 0.5)) {
            region = MKCoordinateRegion(
                center: location.coordinate,
                span: region.span
            )
        }
    }
}

// MARK: - LocationManagerDelegate
extension MapViewModel: LocationManagerDelegate {
    nonisolated func locationManager(_ manager: LocationManagerProtocol, didUpdateLocation location: CLLocation) {
        Task { @MainActor in
            self.userLocation = location
            self.updateRegionIfFollowing(location: location)
            // 位置情報が正常に取得できたらエラーをクリア
            if self.locationError != nil && self.locationError != .authorizationDenied {
                self.locationError = nil
            }
        }
    }
    
    nonisolated func locationManager(_ manager: LocationManagerProtocol, didFailWithError error: Error) {
        Task { @MainActor in
            if let locationError = error as? LocationError {
                self.locationError = locationError
            }
        }
    }
    
    nonisolated func locationManager(_ manager: LocationManagerProtocol, didChangeAuthorization status: CLAuthorizationStatus) {
        Task { @MainActor in
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                self.isLocationAuthorized = true
                self.locationError = nil
            case .denied, .restricted:
                self.isLocationAuthorized = false
                self.locationError = .authorizationDenied
            case .notDetermined:
                self.isLocationAuthorized = false
            @unknown default:
                break
            }
        }
    }
}