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
    
    /// 予め定義されたズームレベル（latitudeDelta値）
    private let predefinedZoomLevels: [Double] = [
        0.0005,  // 最大ズームイン
        0.001,
        0.002,
        0.005,
        0.01,
        0.02,
        0.05,
        0.1,
        0.2,
        0.5,
        1.0,
        2.0,
        5.0,
        10.0,
        20.0,
        50.0,
        100.0,
        180.0    // 最大ズームアウト
    ]
    
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
    
    /// 現在のスパンに最も近いズームレベルのインデックスを取得
    private func findClosestZoomLevelIndex(for span: MKCoordinateSpan) -> Int {
        let currentDelta = span.latitudeDelta
        
        // 最も近いレベルを見つける
        var closestIndex = 0
        var minDifference = abs(currentDelta - predefinedZoomLevels[0])
        
        for i in 1..<predefinedZoomLevels.count {
            let difference = abs(currentDelta - predefinedZoomLevels[i])
            if difference < minDifference {
                minDifference = difference
                closestIndex = i
            }
        }
        
        return closestIndex
    }
    
    /// ズームイン計算
    func calculateZoomIn(from span: MKCoordinateSpan) -> MKCoordinateSpan {
        let currentDelta = span.latitudeDelta
        
        // 現在の値以下の最大のレベルを見つける（現在のズームレベル）
        var currentLevelIndex = predefinedZoomLevels.count - 1
        for i in 0..<predefinedZoomLevels.count {
            if predefinedZoomLevels[i] >= currentDelta - 0.0001 {
                currentLevelIndex = i
                break
            }
        }
        
        // より小さいレベルへ移動（ズームイン）
        let targetIndex = max(0, currentLevelIndex - 1)
        
        // 現在のレベルと同じ場合はそのまま
        if targetIndex == currentLevelIndex && abs(currentDelta - predefinedZoomLevels[currentLevelIndex]) < 0.0001 {
            return MKCoordinateSpan(
                latitudeDelta: predefinedZoomLevels[currentLevelIndex],
                longitudeDelta: predefinedZoomLevels[currentLevelIndex]
            )
        }
        
        return MKCoordinateSpan(
            latitudeDelta: predefinedZoomLevels[targetIndex],
            longitudeDelta: predefinedZoomLevels[targetIndex]
        )
    }
    
    /// ズームアウト計算
    func calculateZoomOut(from span: MKCoordinateSpan) -> MKCoordinateSpan {
        let currentDelta = span.latitudeDelta
        
        // 現在の値より大きい最初のレベルを見つける
        for level in predefinedZoomLevels {
            if level > currentDelta + 0.0001 { // 許容誤差を考慮
                return MKCoordinateSpan(
                    latitudeDelta: level,
                    longitudeDelta: level
                )
            }
        }
        
        // すでに最大レベルの場合
        let lastIndex = predefinedZoomLevels.count - 1
        return MKCoordinateSpan(
            latitudeDelta: predefinedZoomLevels[lastIndex],
            longitudeDelta: predefinedZoomLevels[lastIndex]
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