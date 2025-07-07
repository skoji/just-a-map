import SwiftUI
import MapKit

/// 地図コントロールボタンのビュー
struct MapControlsView: View {
    @ObservedObject var mapViewModel: MapViewModel
    @ObservedObject var controlsViewModel: MapControlsViewModel
    @Binding var mapPosition: MapCameraPosition
    @Binding var isZoomingByButton: Bool
    let currentMapCamera: MapCamera?
    
    var body: some View {
        VStack(spacing: 16) {
            // ズームコントロール
            VStack(spacing: 8) {
                // ズームイン
                ControlButton(
                    icon: "plus.magnifyingglass",
                    action: {
                        zoomIn()
                    },
                    isEnabled: controlsViewModel.canZoomIn
                )
                
                // ズームアウト
                ControlButton(
                    icon: "minus.magnifyingglass",
                    action: {
                        zoomOut()
                    },
                    isEnabled: controlsViewModel.canZoomOut
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
    
    private func zoomIn() {
        print("ズームイン: レベル\(controlsViewModel.currentZoomIndex) -> \(controlsViewModel.currentZoomIndex - 1)")
        
        controlsViewModel.zoomIn()
        updateMapCamera()
    }
    
    private func zoomOut() {
        print("ズームアウト: レベル\(controlsViewModel.currentZoomIndex) -> \(controlsViewModel.currentZoomIndex + 1)")
        
        controlsViewModel.zoomOut()
        updateMapCamera()
    }
    
    private func updateMapCamera() {
        isZoomingByButton = true
        
        // 現在のカメラ位置、または最新の位置情報を使用
        let centerCoordinate: CLLocationCoordinate2D
        let heading: Double
        
        if let camera = currentMapCamera {
            centerCoordinate = camera.centerCoordinate
            heading = camera.heading
        } else if let userLocation = mapViewModel.userLocation {
            centerCoordinate = userLocation.coordinate
            heading = controlsViewModel.isNorthUp ? 0 : userLocation.course
        } else {
            // デフォルト位置（東京駅）
            centerCoordinate = CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503)
            heading = 0
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            let newCamera = MapCamera(
                centerCoordinate: centerCoordinate,
                distance: controlsViewModel.currentAltitude,
                heading: heading,
                pitch: 0
            )
            mapPosition = .camera(newCamera)
        }
        
        // アニメーション完了後にフラグをリセット
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isZoomingByButton = false
        }
    }
}

/// コントロールボタンのスタイル
struct ControlButton: View {
    let icon: String
    let action: () -> Void
    var isEnabled: Bool = true
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isEnabled ? .primary : .gray)
                .frame(width: 60, height: 60)
                .background(Color(UIColor.systemBackground))
                .clipShape(Circle())
                .shadow(radius: 2)
        }
        .disabled(!isEnabled)
    }
}

// MARK: - Preview
struct MapControlsView_Previews: PreviewProvider {
    static var previews: some View {
        MapControlsView(
            mapViewModel: MapViewModel(),
            controlsViewModel: MapControlsViewModel(),
            mapPosition: .constant(.automatic),
            isZoomingByButton: .constant(false),
            currentMapCamera: nil
        )
        .padding()
        .background(Color.gray.opacity(0.2))
    }
}