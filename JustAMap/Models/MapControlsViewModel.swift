import Foundation
import MapKit
import SwiftUI

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
}