import SwiftUI
import MapKit

/// 地図を表示するView
struct MapView: View {
    @StateObject private var viewModel = MapViewModel()
    
    var body: some View {
        ZStack {
            // 地図
            Map(
                coordinateRegion: $viewModel.region,
                showsUserLocation: true,
                userTrackingMode: .constant(viewModel.isFollowingUser ? .follow : .none)
            )
            .ignoresSafeArea()
            
            // エラー表示
            if let error = viewModel.locationError {
                VStack {
                    ErrorBanner(error: error)
                    Spacer()
                }
                .padding(.top, 50)
            }
            
            // コントロールボタン
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    
                    // 現在地に戻るボタン
                    Button(action: {
                        viewModel.isFollowingUser = true
                        viewModel.centerOnUserLocation()
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
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            viewModel.requestLocationPermission()
            viewModel.startLocationTracking()
        }
        .onDisappear {
            viewModel.stopLocationTracking()
        }
        .onChange(of: viewModel.region) { _ in
            // ユーザーが地図を手動で動かした場合、追従モードを解除
            if viewModel.isFollowingUser {
                // 現在地から離れた場合のみ追従を解除
                if let userLocation = viewModel.userLocation {
                    let mapCenter = CLLocation(
                        latitude: viewModel.region.center.latitude,
                        longitude: viewModel.region.center.longitude
                    )
                    let distance = userLocation.distance(from: mapCenter)
                    if distance > 100 { // 100m以上離れたら追従解除
                        viewModel.isFollowingUser = false
                    }
                }
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