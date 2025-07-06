import SwiftUI
import MapKit

/// 地図コントロールボタンのビュー
struct MapControlsView: View {
    @ObservedObject var mapViewModel: MapViewModel
    @ObservedObject var controlsViewModel: MapControlsViewModel
    @Binding var mapPosition: MapCameraPosition
    
    var body: some View {
        VStack(spacing: 16) {
            // ズームコントロール
            VStack(spacing: 8) {
                // ズームイン
                ControlButton(
                    icon: "plus.magnifyingglass",
                    action: {
                        zoomIn()
                    }
                )
                
                // ズームアウト
                ControlButton(
                    icon: "minus.magnifyingglass",
                    action: {
                        zoomOut()
                    }
                )
            }
            
            Divider()
                .frame(width: 40)
                .background(Color.gray.opacity(0.5))
            
            // 地図スタイル切り替え
            ControlButton(
                icon: mapStyleIcon,
                action: {
                    controlsViewModel.toggleMapStyle()
                }
            )
            
            // North Up / Heading Up 切り替え
            ControlButton(
                icon: controlsViewModel.isNorthUp ? "location.north.fill" : "location.north.line.fill",
                action: {
                    controlsViewModel.toggleMapOrientation()
                }
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    // MARK: - Computed Properties
    
    private var mapStyleIcon: String {
        switch controlsViewModel.currentMapStyle {
        case .standard:
            return "map"
        case .hybrid:
            return "map.fill"
        case .imagery:
            return "globe.americas.fill"
        }
    }
    
    // MARK: - Methods
    
    @MainActor
    private func zoomIn() {
        // MapCameraPositionから直接regionを取得する別の方法
        Task { @MainActor in
            // 現在のカメラ位置を取得してズームイン
            if let currentRegion = getCurrentRegion() {
                let newSpan = controlsViewModel.calculateZoomIn(from: currentRegion.span)
                withAnimation {
                    mapPosition = .region(MKCoordinateRegion(
                        center: currentRegion.center,
                        span: newSpan
                    ))
                    mapViewModel.currentSpan = newSpan
                }
            }
        }
    }
    
    @MainActor
    private func zoomOut() {
        // MapCameraPositionから直接regionを取得する別の方法
        Task { @MainActor in
            // 現在のカメラ位置を取得してズームアウト
            if let currentRegion = getCurrentRegion() {
                let newSpan = controlsViewModel.calculateZoomOut(from: currentRegion.span)
                withAnimation {
                    mapPosition = .region(MKCoordinateRegion(
                        center: currentRegion.center,
                        span: newSpan
                    ))
                    mapViewModel.currentSpan = newSpan
                }
            }
        }
    }
    
    private func getCurrentRegion() -> MKCoordinateRegion? {
        // MapViewModelから現在の地域を取得
        return mapViewModel.region
    }
}

/// コントロールボタンのスタイル
struct ControlButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.primary)
                .frame(width: 60, height: 60)
                .background(Color(UIColor.systemBackground))
                .clipShape(Circle())
                .shadow(radius: 2)
        }
    }
}

// MARK: - Preview
struct MapControlsView_Previews: PreviewProvider {
    static var previews: some View {
        MapControlsView(
            mapViewModel: MapViewModel(),
            controlsViewModel: MapControlsViewModel(),
            mapPosition: .constant(.region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )))
        )
        .padding()
        .background(Color.gray.opacity(0.2))
    }
}