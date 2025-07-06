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
    @Published var currentSpan = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01) // 廃止予定
    
    @Published var userLocation: CLLocation?
    @Published var isLocationAuthorized = false
    @Published var locationError: LocationError?
    @Published var isFollowingUser = true
    @Published var formattedAddress: FormattedAddress?
    @Published var isLoadingAddress = false
    
    private let locationManager: LocationManagerProtocol
    private let geocodeService: GeocodeServiceProtocol
    private let addressFormatter: AddressFormatter
    private let idleTimerManager: IdleTimerManagerProtocol
    let mapControlsViewModel: MapControlsViewModel
    private let settingsStorage: MapSettingsStorageProtocol
    
    private var geocodingTask: Task<Void, Never>?
    private var lastGeocodedLocation: CLLocation?
    private let geocodingMinimumDistance: CLLocationDistance = 50.0 // 50m以上移動したら住所を更新
    
    init(locationManager: LocationManagerProtocol = LocationManager(),
         geocodeService: GeocodeServiceProtocol = GeocodeService(),
         addressFormatter: AddressFormatter = AddressFormatter(),
         idleTimerManager: IdleTimerManagerProtocol = IdleTimerManager(),
         mapControlsViewModel: MapControlsViewModel? = nil,
         settingsStorage: MapSettingsStorageProtocol = MapSettingsStorage()) {
        self.locationManager = locationManager
        self.geocodeService = geocodeService
        self.addressFormatter = addressFormatter
        self.idleTimerManager = idleTimerManager
        self.mapControlsViewModel = mapControlsViewModel ?? MapControlsViewModel()
        self.settingsStorage = settingsStorage
        self.locationManager.delegate = self
        
        // スリープ防止を有効化
        self.idleTimerManager.setIdleTimerDisabled(true)
        
        // 保存された設定を読み込む
        loadSettings()
    }
    
    private func loadSettings() {
        // 現在の設定を読み込む（なければデフォルト設定を使用）
        let currentMapStyle = settingsStorage.mapStyle
        let currentIsNorthUp = settingsStorage.isNorthUp
        let currentZoomIndex = settingsStorage.zoomIndex
        
        // 保存された現在の設定がない場合は、デフォルト設定を使用
        if settingsStorage.loadMapStyle() == .standard && 
           settingsStorage.loadMapOrientation() == true && 
           settingsStorage.loadZoomIndex() == nil {
            // 初回起動時：デフォルト設定を現在の設定として保存
            mapControlsViewModel.currentMapStyle = settingsStorage.defaultMapStyle
            mapControlsViewModel.isNorthUp = settingsStorage.defaultIsNorthUp
            mapControlsViewModel.setZoomIndex(settingsStorage.defaultZoomIndex)
            
            // 現在の設定として保存
            saveSettings()
        } else {
            // 保存された設定を読み込む
            mapControlsViewModel.currentMapStyle = currentMapStyle
            mapControlsViewModel.isNorthUp = currentIsNorthUp
            mapControlsViewModel.setZoomIndex(currentZoomIndex)
        }
    }
    
    func saveSettings() {
        settingsStorage.saveMapStyle(mapControlsViewModel.currentMapStyle)
        settingsStorage.saveMapOrientation(isNorthUp: mapControlsViewModel.isNorthUp)
        settingsStorage.saveZoomIndex(mapControlsViewModel.currentZoomIndex)
    }
    
    func requestLocationPermission() {
        locationManager.requestLocationPermission()
    }
    
    func startLocationTracking() {
        locationManager.startLocationUpdates()
    }
    
    func stopLocationTracking() {
        locationManager.stopLocationUpdates()
        geocodingTask?.cancel()
    }
    
    /// アプリがバックグラウンドに入った時
    func handleAppDidEnterBackground() {
        idleTimerManager.handleAppDidEnterBackground()
    }
    
    /// アプリがフォアグラウンドに戻った時
    func handleAppWillEnterForeground() {
        idleTimerManager.handleAppWillEnterForeground()
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
        
        // スムーズなアニメーションで地図を更新（現在のズームレベルを保持）
        withAnimation(.easeInOut(duration: 0.5)) {
            region = MKCoordinateRegion(
                center: location.coordinate,
                span: currentSpan
            )
        }
    }
    
    private func fetchAddress(for location: CLLocation) {
        // 前回のジオコーディング位置から十分離れているかチェック
        if let lastLocation = lastGeocodedLocation {
            let distance = location.distance(from: lastLocation)
            if distance < geocodingMinimumDistance {
                return // まだ住所を更新する必要がない
            }
        }
        
        // 前のタスクをキャンセル
        geocodingTask?.cancel()
        
        // 新しいタスクを開始
        geocodingTask = Task {
            isLoadingAddress = true
            
            // 少し遅延を入れて連続リクエストを防ぐ
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
            
            guard !Task.isCancelled else { return }
            
            do {
                let address = try await geocodeService.reverseGeocode(location: location)
                
                // タスクがキャンセルされていないか確認
                guard !Task.isCancelled else { return }
                
                self.formattedAddress = addressFormatter.formatForDisplay(address)
                self.isLoadingAddress = false
                self.lastGeocodedLocation = location // 成功時のみ更新
            } catch {
                // タスクがキャンセルされていないか確認
                guard !Task.isCancelled else { return }
                
                print("Geocoding error: \(error)")
                self.isLoadingAddress = false
                // エラーの場合は住所を空にしない（前の住所を保持）
            }
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
            // 住所を取得
            self.fetchAddress(for: location)
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