import Foundation
import MapKit
import SwiftUI

/// 地図の表示スタイル
enum MapStyle: String, CaseIterable {
    case standard = "標準"
    case hybrid = "航空写真+地図"
    case imagery = "航空写真"
}

/// 地図コントロールのビジネスロジックを管理
@MainActor
class MapControlsViewModel: ObservableObject {
    // MARK: - Zoom Properties
    
    /// 最小ズームスパン（最大ズームイン）
    let minimumZoomSpan = MKCoordinateSpan(latitudeDelta: 0.0005, longitudeDelta: 0.0005)
    
    /// 最大ズームスパン（最大ズームアウト）
    let maximumZoomSpan = MKCoordinateSpan(latitudeDelta: 180.0, longitudeDelta: 180.0)
    
    /// ズーム倍率
    private let zoomFactor: Double = 2.0
    
    // MARK: - Map Style Properties
    
    /// 現在の地図スタイル
    @Published var currentMapStyle: MapStyle = .standard
    
    // MARK: - Map Orientation Properties
    
    /// North Up（北が上）モード
    @Published var isNorthUp: Bool = true
    
    /// Heading Up（進行方向が上）モード
    var isHeadingUp: Bool {
        !isNorthUp
    }
    
    // MARK: - Zoom Methods
    
    /// ズームイン計算
    func calculateZoomIn(from span: MKCoordinateSpan) -> MKCoordinateSpan {
        let newLatDelta = max(span.latitudeDelta / zoomFactor, minimumZoomSpan.latitudeDelta)
        let newLonDelta = max(span.longitudeDelta / zoomFactor, minimumZoomSpan.longitudeDelta)
        
        return MKCoordinateSpan(
            latitudeDelta: newLatDelta,
            longitudeDelta: newLonDelta
        )
    }
    
    /// ズームアウト計算
    func calculateZoomOut(from span: MKCoordinateSpan) -> MKCoordinateSpan {
        let newLatDelta = min(span.latitudeDelta * zoomFactor, maximumZoomSpan.latitudeDelta)
        let newLonDelta = min(span.longitudeDelta * zoomFactor, maximumZoomSpan.longitudeDelta)
        
        return MKCoordinateSpan(
            latitudeDelta: newLatDelta,
            longitudeDelta: newLonDelta
        )
    }
    
    /// スパンからズームレベルを計算（0-20の範囲）
    func calculateZoomLevel(from span: MKCoordinateSpan) -> Double {
        // MapKitのズームレベル計算式（簡易版）
        let maxZoom: Double = 20.0
        let worldLatDelta: Double = 180.0
        
        // log2を使用してズームレベルを計算
        let zoomLevel = log2(worldLatDelta / span.latitudeDelta)
        
        // 0-20の範囲にクランプ
        return max(0, min(maxZoom, zoomLevel))
    }
    
    // MARK: - Map Style Methods
    
    /// 地図スタイルを切り替え
    func toggleMapStyle() {
        let allStyles = MapStyle.allCases
        guard let currentIndex = allStyles.firstIndex(of: currentMapStyle) else { return }
        
        let nextIndex = (currentIndex + 1) % allStyles.count
        currentMapStyle = allStyles[nextIndex]
    }
    
    /// MapStyleに対応するMKMapTypeを返す
    var currentMKMapType: MKMapType {
        switch currentMapStyle {
        case .standard:
            return .standard
        case .hybrid:
            return .hybrid
        case .imagery:
            return .satellite
        }
    }
    
    // MARK: - Map Orientation Methods
    
    /// 地図の向きを切り替え
    func toggleMapOrientation() {
        isNorthUp.toggle()
    }
    
    /// ヘディングから地図の回転角度を計算
    func calculateHeadingRotation(_ heading: Double) -> Double {
        // MapKitは北が0度で時計回りなので、負の値で回転
        return -heading
    }
}