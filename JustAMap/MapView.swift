import SwiftUI
import MapKit
import Combine

/// 地図を表示するView
struct MapView: View {
    @StateObject private var viewModel = MapViewModel()
    @State private var mapPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    )
    
    var body: some View {
        ZStack {
            // 地図
            Group {
                switch viewModel.mapControlsViewModel.currentMapStyle {
                case .standard:
                    Map(position: $mapPosition) {
                        UserAnnotation()
                    }
                    .mapStyle(.standard)
                    .mapControls {
                        MapCompass()
                        MapScaleView()
                    }
                case .hybrid:
                    Map(position: $mapPosition) {
                        UserAnnotation()
                    }
                    .mapStyle(.hybrid)
                    .mapControls {
                        MapCompass()
                        MapScaleView()
                    }
                case .imagery:
                    Map(position: $mapPosition) {
                        UserAnnotation()
                    }
                    .mapStyle(.imagery)
                    .mapControls {
                        MapCompass()
                        MapScaleView()
                    }
                }
            }
            .ignoresSafeArea()
            .onMapCameraChange { context in
                // 現在のズームレベルを追跡
                viewModel.currentSpan = context.region.span
                
                // ユーザーが地図を手動で動かした場合、追従モードを解除
                if viewModel.isFollowingUser {
                    if let userLocation = viewModel.userLocation {
                        let mapCenter = CLLocation(
                            latitude: context.region.center.latitude,
                            longitude: context.region.center.longitude
                        )
                        let distance = userLocation.distance(from: mapCenter)
                        if distance > 100 { // 100m以上離れたら追従解除
                            viewModel.isFollowingUser = false
                        }
                    }
                }
            }
            
            // 上部のUI（住所表示とエラー表示）
            VStack {
                // 住所表示
                AddressView(
                    formattedAddress: viewModel.formattedAddress,
                    isLoading: viewModel.isLoadingAddress
                )
                
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
                        mapPosition: $mapPosition
                    )
                    .padding(.leading, 20)
                    
                    Spacer()
                    
                    // 現在地に戻るボタン（右側）
                    Button(action: {
                        viewModel.isFollowingUser = true
                        if let location = viewModel.userLocation {
                            withAnimation {
                                mapPosition = .region(MKCoordinateRegion(
                                    center: location.coordinate,
                                    span: viewModel.currentSpan
                                ))
                            }
                        }
                    }) {
                        Image(systemName: viewModel.isFollowingUser ? "location.fill" : "location")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding(.trailing, 20)
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            viewModel.requestLocationPermission()
        }
        .onDisappear {
            viewModel.stopLocationTracking()
            viewModel.saveSettings()
        }
        .onReceive(viewModel.$userLocation) { newLocation in
            // 追従モードの場合は地図を更新
            if viewModel.isFollowingUser, let location = newLocation {
                withAnimation {
                    mapPosition = .region(MKCoordinateRegion(
                        center: location.coordinate,
                        span: viewModel.currentSpan
                    ))
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            viewModel.handleAppDidEnterBackground()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            viewModel.handleAppWillEnterForeground()
        }
        .onReceive(viewModel.mapControlsViewModel.$currentMapStyle) { _ in
            viewModel.saveSettings()
        }
        .onReceive(viewModel.mapControlsViewModel.$isNorthUp) { _ in
            viewModel.saveSettings()
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
        .padding(.horizontal)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// MARK: - Preview
struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView()
    }
}