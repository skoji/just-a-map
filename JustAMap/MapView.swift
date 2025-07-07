import SwiftUI
import MapKit
import Combine

/// 地図を表示するView
struct MapView: View {
    @StateObject private var viewModel = MapViewModel()
    @StateObject private var compassViewModel = CompassViewModel()
    @State private var mapPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    )
    @State private var currentMapCamera: MapCamera?
    @State private var isZoomingByButton = false
    @State private var isShowingSettings = false
    @State private var mapStyleForDisplay: JustAMap.MapStyle?
    
    // アニメーションパラメータ定数
    private enum AnimationConstants {
        static let mapRotationResponse: Double = 0.3
        static let mapRotationDamping: Double = 0.8
        static let mapRotationBlendDuration: Double = 0.1
    }
    
    // MARK: - Helper Methods
    
    /// Update compass rotation based on camera heading
    private func updateCompassRotation(heading: Double) {
        compassViewModel.updateRotation(heading)
    }
    
    private var currentMapKitStyle: MapKit.MapStyle {
        switch mapStyleForDisplay ?? viewModel.mapControlsViewModel.currentMapStyle {
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
            Map(position: $mapPosition, interactionModes: viewModel.mapControlsViewModel.isNorthUp ? [.pan, .zoom] : .all) {
                UserAnnotation()
            }
            .mapStyle(currentMapKitStyle)
            .mapControls {
                MapScaleView()
            }
            .ignoresSafeArea()
            .onMapCameraChange { context in
                // ボタンによるズーム中は無視
                guard !isZoomingByButton else { return }
                
                // カメラ情報を更新
                let camera = context.camera
                currentMapCamera = camera
                // 高度から最も近いズームインデックスを設定
                viewModel.mapControlsViewModel.setNearestZoomIndex(for: camera.distance)
                
                // 地図中心座標を更新
                viewModel.updateMapCenter(context.region.center)
                
                // コンパスの回転を更新
                updateCompassRotation(heading: camera.heading)
                
                // ユーザーが地図を手動で動かした場合、追従モードを解除
                // ただし、ズームボタン操作中は無視
                if viewModel.isFollowingUser && !isZoomingByButton {
                    if let userLocation = viewModel.userLocation {
                        let mapCenter = CLLocation(
                            latitude: context.region.center.latitude,
                            longitude: context.region.center.longitude
                        )
                        let distance = userLocation.distance(from: mapCenter)
                        if distance > 100 { // 100m以上離れたら追従解除
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
                    
                    // 右側のコントロール
                    VStack(spacing: 16) {
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
                        
                        // コンパスビュー
                        CompassView(viewModel: compassViewModel)
                    }
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
                        // ズーム中フラグを立てて、onMapCameraChangeでの追従解除を防ぐ
                        isZoomingByButton = true
                        viewModel.centerOnUserLocation()
                        if let location = viewModel.userLocation {
                            withAnimation(.interactiveSpring(response: AnimationConstants.mapRotationResponse, dampingFraction: AnimationConstants.mapRotationDamping, blendDuration: AnimationConstants.mapRotationBlendDuration)) {
                                // centerOnUserLocationでデフォルトズームが適用されるので、
                                // ここでもcurrentAltitudeを使用（既に更新されている）
                                let camera = MapCamera(
                                    centerCoordinate: location.coordinate,
                                    distance: viewModel.mapControlsViewModel.currentAltitude,
                                    heading: viewModel.mapControlsViewModel.isNorthUp ? 0 : location.course,
                                    pitch: 0
                                )
                                mapPosition = .camera(camera)
                            }
                        }
                        // アニメーション完了後にフラグをリセット
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            isZoomingByButton = false
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
            // 初期スタイルを設定（まだ設定されていない場合のみ）
            if mapStyleForDisplay == nil {
                mapStyleForDisplay = viewModel.mapControlsViewModel.currentMapStyle
            }
            
            // コンパスの初期設定
            let initialHeading = currentMapCamera?.heading ?? 0
            compassViewModel.syncOrientation(isNorthUp: viewModel.mapControlsViewModel.isNorthUp, 
                                            currentHeading: initialHeading)
            compassViewModel.onToggle = { isNorthUp in
                viewModel.mapControlsViewModel.isNorthUp = isNorthUp
            }
        }
        .onDisappear {
            viewModel.stopLocationTracking()
            viewModel.saveSettings()
        }
        .onReceive(viewModel.$userLocation) { newLocation in
            // 追従モードの場合は地図を更新
            if viewModel.isFollowingUser, let location = newLocation {
                // より滑らかなアニメーションを実現
                withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.8, blendDuration: 0.1)) {
                    let mapHeading = viewModel.mapControlsViewModel.isNorthUp ? 0 : location.course
                    let camera = MapCamera(
                        centerCoordinate: location.coordinate,
                        distance: viewModel.mapControlsViewModel.currentAltitude,
                        heading: mapHeading,
                        pitch: 0
                    )
                    mapPosition = .camera(camera)
                    // コンパスの回転を更新
                    updateCompassRotation(heading: mapHeading)
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
            viewModel.saveSettings()
            // State変数を更新してSwiftUIの再描画を促す
            mapStyleForDisplay = newStyle
        }
        .onReceive(viewModel.mapControlsViewModel.$isNorthUp) { isNorthUp in
            viewModel.saveSettings()
            // コンパスの状態を同期（回転のリセットまたは現在のヘディングへの更新）
            let currentHeading = currentMapCamera?.heading ?? viewModel.userLocation?.course ?? 0
            compassViewModel.syncOrientation(isNorthUp: isNorthUp, currentHeading: currentHeading)
            // 地図の向きが切り替わったら即座にアニメーション付きで回転
            if let location = viewModel.userLocation ?? currentMapCamera.map({ camera in
                CLLocation(latitude: camera.centerCoordinate.latitude, longitude: camera.centerCoordinate.longitude)
            }) {
                withAnimation(.interactiveSpring(response: AnimationConstants.mapRotationResponse, dampingFraction: AnimationConstants.mapRotationDamping, blendDuration: AnimationConstants.mapRotationBlendDuration)) {
                    let calculatedHeading = viewModel.calculateMapHeading(for: location)
                    
                    let camera = MapCamera(
                        centerCoordinate: location.coordinate,
                        distance: currentMapCamera?.distance ?? viewModel.mapControlsViewModel.currentAltitude,
                        heading: calculatedHeading,
                        pitch: 0
                    )
                    mapPosition = .camera(camera)
                }
                
                // テスト用のコールバックを呼び出し
                viewModel.onOrientationToggle?()
            }
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