import SwiftUI
import MapKit
import Combine

/// 地図を表示するView
struct MapView: View {
    // MARK: - Constants
    private enum Constants {
        static let styleChangeDelay: TimeInterval = 0.1
        static let animationDuration: TimeInterval = 0.3
        static let flagResetDelay: TimeInterval = 0.5
        static let followingDistanceThreshold: CLLocationDistance = 100.0
    }
    
    // MARK: - State
    @StateObject private var viewModel = MapViewModel()
    @State private var mapPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    )
    @State private var currentMapCamera: MapCamera?
    @State private var isZoomingByButton = false
    @State private var isShowingSettings = false
    @State private var isChangingMapStyle = false
    
    private var currentMapStyle: MapKit.MapStyle {
        switch viewModel.mapControlsViewModel.currentMapStyle {
        case .standard:
            return .standard
        case .hybrid:
            return .hybrid
        case .imagery:
            return .imagery
        }
    }
    
    var body: some View {
        ZStack {
            // 地図
            Map(position: $mapPosition) {
                UserAnnotation()
            }
            .mapStyle(currentMapStyle)
            .mapControls {
                MapCompass()
                MapScaleView()
            }
            .ignoresSafeArea()
            .onMapCameraChange { context in
                // ボタンによるズーム中またはスタイル変更中は無視
                guard !isZoomingByButton && !isChangingMapStyle else { return }
                
                // カメラ情報を更新
                let camera = context.camera
                currentMapCamera = camera
                // 高度から最も近いズームインデックスを設定
                viewModel.mapControlsViewModel.setNearestZoomIndex(for: camera.distance)
                
                // 地図中心座標を更新
                viewModel.updateMapCenter(context.region.center)
                
                // ユーザーが地図を手動で動かした場合、追従モードを解除
                if viewModel.isFollowingUser {
                    if let userLocation = viewModel.userLocation {
                        let mapCenter = CLLocation(
                            latitude: context.region.center.latitude,
                            longitude: context.region.center.longitude
                        )
                        let distance = userLocation.distance(from: mapCenter)
                        if distance > Constants.followingDistanceThreshold {
                            viewModel.handleUserMapInteraction()
                        }
                    }
                }
            }
            
            // クロスヘア（追従モード解除時のみ表示）
            if !viewModel.isFollowingUser {
                CrosshairView()
                    .allowsHitTesting(false) // タッチイベントを透過
            }
            
            // 上部のUI（住所表示とエラー表示）
            VStack {
                // 住所表示と設定ボタン
                HStack(alignment: .top) {
                    AddressView(
                        formattedAddress: viewModel.isFollowingUser ? viewModel.formattedAddress : viewModel.mapCenterAddress,
                        isLoading: viewModel.isFollowingUser ? viewModel.isLoadingAddress : viewModel.isLoadingMapCenterAddress
                    )
                    
                    Spacer()
                    
                    // 設定ボタン
                    Button(action: {
                        isShowingSettings = true
                    }) {
                        Image(systemName: "gear")
                            .font(.title2)
                            .foregroundColor(.blue)
                            .frame(width: 44, height: 44)
                            .background(Color(.systemBackground))
                            .clipShape(Circle())
                            .shadow(radius: 2)
                    }
                    .accessibilityLabel("設定")
                    .padding(.trailing, 20)
                    .padding(.top, 10)
                }
                
                // エラー表示
                if let error = viewModel.locationError {
                    ErrorBanner(error: error)
                        .padding(.horizontal)
                        .padding(.top, 8)
                }
                
                Spacer()
            }
            
            // コントロールボタン
            VStack {
                Spacer()
                HStack {
                    // 地図コントロール（左側）
                    MapControlsView(
                        mapViewModel: viewModel,
                        controlsViewModel: viewModel.mapControlsViewModel,
                        mapPosition: $mapPosition,
                        isZoomingByButton: $isZoomingByButton,
                        currentMapCamera: currentMapCamera
                    )
                    .padding(.leading, 20)
                    
                    Spacer()
                    
                    // 現在地に戻るボタン（右側）
                    Button(action: {
                        viewModel.centerOnUserLocation()
                        if let location = viewModel.userLocation {
                            withAnimation {
                                let camera = MapCamera(
                                    centerCoordinate: location.coordinate,
                                    distance: viewModel.mapControlsViewModel.currentAltitude,
                                    heading: viewModel.mapControlsViewModel.isNorthUp ? 0 : location.course,
                                    pitch: 0
                                )
                                mapPosition = .camera(camera)
                            }
                        }
                    }) {
                        Image(systemName: viewModel.isFollowingUser ? "location.fill" : "location")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(viewModel.isFollowingUser ? Color.blue : Color.gray)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                            .overlay(
                                // 追従モード解除時にパルスアニメーション
                                Circle()
                                    .stroke(Color.blue, lineWidth: 2)
                                    .scaleEffect(viewModel.isFollowingUser ? 1 : 1.3)
                                    .opacity(viewModel.isFollowingUser ? 0 : 0.6)
                                    .animation(
                                        viewModel.isFollowingUser ? .none : Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                                        value: viewModel.isFollowingUser
                                    )
                            )
                    }
                    .padding(.trailing, 20)
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            viewModel.requestLocationPermission()
            // 初期カメラ位置を設定
            let initialCamera = MapCamera(
                centerCoordinate: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
                distance: viewModel.mapControlsViewModel.currentAltitude
            )
            mapPosition = .camera(initialCamera)
        }
        .onDisappear {
            viewModel.stopLocationTracking()
            viewModel.saveSettings()
        }
        .onReceive(viewModel.$userLocation) { newLocation in
            // 追従モードの場合は地図を更新
            if viewModel.isFollowingUser, let location = newLocation {
                withAnimation {
                    let camera = MapCamera(
                        centerCoordinate: location.coordinate,
                        distance: viewModel.mapControlsViewModel.currentAltitude,
                        heading: viewModel.mapControlsViewModel.isNorthUp ? 0 : location.course,
                        pitch: 0
                    )
                    mapPosition = .camera(camera)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            viewModel.handleAppDidEnterBackground()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            viewModel.handleAppWillEnterForeground()
        }
        .onReceive(viewModel.mapControlsViewModel.$currentMapStyle) { newStyle in
            // スタイル変更開始
            isChangingMapStyle = true
            viewModel.saveSettings()
            
            // カメラ位置を保持して再設定
            if let camera = currentMapCamera {
                DispatchQueue.main.asyncAfter(deadline: .now() + Constants.styleChangeDelay) {
                    withAnimation(.easeInOut(duration: Constants.animationDuration)) {
                        mapPosition = .camera(camera)
                    }
                    // スタイル変更完了
                    DispatchQueue.main.asyncAfter(deadline: .now() + Constants.flagResetDelay) {
                        isChangingMapStyle = false
                    }
                }
            } else {
                // カメラ情報がない場合は即座にフラグをリセット
                DispatchQueue.main.asyncAfter(deadline: .now() + Constants.flagResetDelay) {
                    isChangingMapStyle = false
                }
            }
        }
        .onReceive(viewModel.mapControlsViewModel.$isNorthUp) { _ in
            viewModel.saveSettings()
        }
        .onReceive(viewModel.mapControlsViewModel.$currentZoomIndex) { _ in
            viewModel.saveSettings()
        }
        .sheet(isPresented: $isShowingSettings) {
            SettingsView()
                .onDisappear {
                    // 設定画面が閉じられたときに住所フォーマットを更新
                    viewModel.refreshAddressFormat()
                }
        }
    }
}

/// エラーバナー
struct ErrorBanner: View {
    let error: LocationError
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.white)
            
            Text(error.localizedDescription)
                .foregroundColor(.white)
                .font(.headline)
            
            Spacer()
            
            if error == .authorizationDenied {
                Button("設定") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.2))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.red)
        .cornerRadius(12)
        .shadow(radius: 3)
    }
}

// MARK: - Preview
struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView()
    }
}