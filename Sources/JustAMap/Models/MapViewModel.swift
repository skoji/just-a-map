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
    @Published var mapCenterCoordinate = CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503)
    @Published var mapCenterAddress: FormattedAddress?
    @Published var isLoadingMapCenterAddress = false
    
    private let locationManager: LocationManagerProtocol
    private let geocodeService: GeocodeServiceProtocol
    private let addressFormatter: AddressFormatter
    private let idleTimerManager: IdleTimerManagerProtocol?
    let mapControlsViewModel: MapControlsViewModel
    private let settingsStorage: MapSettingsStorageProtocol
    
    private var geocodingTask: Task<Void, Never>?
    private var lastGeocodedLocation: CLLocation?
    private let geocodingMinimumDistance: CLLocationDistance = 50.0 // 50m以上移動したら住所を更新
    
    private var mapCenterGeocodingTask: Task<Void, Never>?
    private let mapCenterDebounceDelay: UInt64 = 300_000_000 // 300ms
    
    // 地図の向き切り替え時のコールバック（テスト用）
    var onOrientationToggle: (() -> Void)?
    
    init(locationManager: LocationManagerProtocol = LocationManager(),
         geocodeService: GeocodeServiceProtocol = GeocodeService(),
         addressFormatter: AddressFormatter? = nil,
         idleTimerManager: IdleTimerManagerProtocol? = nil,
         mapControlsViewModel: MapControlsViewModel? = nil,
         settingsStorage: MapSettingsStorageProtocol = MapSettingsStorage()) {
        self.locationManager = locationManager
        self.geocodeService = geocodeService
        self.settingsStorage = settingsStorage
        // AddressFormatterはsettingsStorageを使用するため、ここで作成
        self.addressFormatter = addressFormatter ?? AddressFormatter(settingsStorage: settingsStorage)
        self.idleTimerManager = idleTimerManager ?? IdleTimerManager()
        self.mapControlsViewModel = mapControlsViewModel ?? MapControlsViewModel()
        self.locationManager.delegate = self
        
        // スリープ防止を有効化
        self.idleTimerManager?.setIdleTimerDisabled(true)
        
        // 保存された設定を読み込む
        loadSettings()
    }
    
    private func loadSettings() {
        if settingsStorage.isFirstLaunch() {
            // 初回起動時：デフォルト設定を現在の設定として使用・保存
            mapControlsViewModel.currentMapStyle = settingsStorage.defaultMapStyle
            mapControlsViewModel.isNorthUp = settingsStorage.defaultIsNorthUp
            mapControlsViewModel.setZoomIndex(settingsStorage.defaultZoomIndex)
            
            // 現在の設定として保存
            saveSettings()
        } else {
            // 保存された設定を読み込む
            mapControlsViewModel.currentMapStyle = settingsStorage.mapStyle
            mapControlsViewModel.isNorthUp = settingsStorage.isNorthUp
            mapControlsViewModel.setZoomIndex(settingsStorage.zoomIndex)
        }
    }
    
    func saveSettings() {
        settingsStorage.saveMapStyle(mapControlsViewModel.currentMapStyle)
        settingsStorage.saveMapOrientation(isNorthUp: mapControlsViewModel.isNorthUp)
        settingsStorage.saveZoomIndex(mapControlsViewModel.currentZoomIndex)
    }
    
    /// 設定変更時に呼び出される（住所の再フォーマットが必要な場合）
    func refreshAddressFormat() {
        // 現在の位置情報で住所を再取得
        if let location = userLocation {
            // 最後のジオコーディング位置をリセットして強制的に再取得
            lastGeocodedLocation = nil
            fetchAddress(for: location)
        }
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
        mapCenterGeocodingTask?.cancel()
    }
    
    /// アプリがバックグラウンドに入った時
    func handleAppDidEnterBackground() {
        idleTimerManager?.handleAppDidEnterBackground()
    }
    
    /// アプリがフォアグラウンドに戻った時
    func handleAppWillEnterForeground() {
        idleTimerManager?.handleAppWillEnterForeground()
    }
    
    func centerOnUserLocation() {
        guard let location = userLocation else { return }
        
        // 追従モードを有効化
        isFollowingUser = true
        
        // デフォルトズームレベルを適用
        let defaultZoomIndex = settingsStorage.defaultZoomIndex
        mapControlsViewModel.setZoomIndex(defaultZoomIndex)
        
        withAnimation(.easeInOut(duration: 0.3)) {
            region = MKCoordinateRegion(
                center: location.coordinate,
                span: region.span
            )
        }
    }
    
    /// ユーザーが地図を操作したときに呼ばれる
    func handleUserMapInteraction() {
        isFollowingUser = false
    }
    
    /// 地図の中心座標を更新（デバウンス処理付き）
    func updateMapCenter(_ coordinate: CLLocationCoordinate2D) {
        mapCenterCoordinate = coordinate
        
        // 追従モードでない場合のみ、地図中心の住所を取得
        guard !isFollowingUser else { return }
        
        // 前のタスクをキャンセル
        mapCenterGeocodingTask?.cancel()
        
        // 新しいタスクを開始
        mapCenterGeocodingTask = Task {
            // デバウンス
            try? await Task.sleep(nanoseconds: mapCenterDebounceDelay)
            
            guard !Task.isCancelled else { return }
            
            // 住所を取得
            await fetchAddressForMapCenter()
        }
    }
    
    private func fetchAddressForMapCenter() async {
        isLoadingMapCenterAddress = true
        
        let location = CLLocation(
            latitude: mapCenterCoordinate.latitude,
            longitude: mapCenterCoordinate.longitude
        )
        
        do {
            let address = try await geocodeService.reverseGeocode(location: location)
            
            guard !Task.isCancelled else { return }
            
            self.mapCenterAddress = addressFormatter.formatForDisplay(address)
            self.isLoadingMapCenterAddress = false
        } catch {
            guard !Task.isCancelled else { return }
            
            print("Map center geocoding error: \(error)")
            self.isLoadingMapCenterAddress = false
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
            
            // 速度とズームレベルに基づいて更新頻度を調整
            let speed = max(0, location.speed * 3.6) // m/s to km/h, 負の値は0に
            let zoomDistance = self.mapControlsViewModel.currentAltitude
            manager.adjustUpdateFrequency(forSpeed: speed, zoomDistance: zoomDistance)
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
    
    // MARK: - Map Rotation Support
    
    /// 位置情報に基づいて地図の方向を計算
    func calculateMapHeading(for location: CLLocation) -> Double {
        if mapControlsViewModel.isNorthUp {
            return 0 // North Up: 常に北が上
        } else {
            // Heading Up: コース情報が有効な場合は使用、無効な場合は0
            return location.course >= 0 ? location.course : 0
        }
    }
    
    /// ユーザーによる地図の回転が許可されているか
    var isUserRotationEnabled: Bool {
        // North Upモードでは回転を禁止
        return !mapControlsViewModel.isNorthUp
    }
}