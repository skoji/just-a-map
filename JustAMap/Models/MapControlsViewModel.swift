import Foundation
import MapKit
import SwiftUI

/// 地図の表示スタイル
enum MapStyle: String, CaseIterable {
    case standard = "標準"
    case hybrid = "航空写真+地図"
    case imagery = "航空写真"
    
    var displayName: String {
        return self.rawValue
    }
}

/// ズームレベルの定数
enum ZoomConstants {
    static let minIndex = 0
    // 将来的にpredefinedAltitudesの数が変わっても対応できるように
    // 本来は配列のサイズから動的に計算したいが、staticプロパティの制約により固定値
    static let maxIndex = 11  // predefinedAltitudes.count - 1
}

/// 地図コントロールのビジネスロジックを管理
@MainActor
class MapControlsViewModel: ObservableObject {
    // MARK: - Zoom Properties
    
    /// 予め定義されたズームレベル（高度値）
    /// 高度が低いほどズームイン、高いほどズームアウト
    private let predefinedAltitudes: [Double] = [
        200,      // 最大ズームイン - 建物レベル
        500,      // 街区レベル
        1000,     // 近隣レベル
        2000,     // 地区レベル
        5000,     // 市区レベル
        10000,    // 市レベル
        20000,    // 都市圏レベル
        50000,    // 県レベル
        100000,   // 地方レベル
        200000,   // 国レベル
        500000,   // 大陸レベル
        1000000,  // 最大ズームアウト - 地球レベル
    ]
    
    
    /// 現在のズームレベルインデックス
    @Published private(set) var currentZoomIndex: Int = 5 // デフォルトは市レベル
    
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
    
    /// 現在の高度を取得
    var currentAltitude: Double {
        predefinedAltitudes[currentZoomIndex]
    }
    
    /// ズームイン
    func zoomIn() {
        if currentZoomIndex > ZoomConstants.minIndex {
            currentZoomIndex -= 1
        }
    }
    
    /// ズームアウト
    func zoomOut() {
        if currentZoomIndex < ZoomConstants.maxIndex {
            currentZoomIndex += 1
        }
    }
    
    /// 高度から最も近いズームインデックスを設定
    func setNearestZoomIndex(for altitude: Double) {
        var closestIndex = 0
        var minDifference = abs(altitude - predefinedAltitudes[0])
        
        for i in 1..<predefinedAltitudes.count {
            let difference = abs(altitude - predefinedAltitudes[i])
            if difference < minDifference {
                minDifference = difference
                closestIndex = i
            }
        }
        
        currentZoomIndex = closestIndex
    }
    
    /// ズームレベルを設定（0-11の範囲）
    func setZoomIndex(_ index: Int) {
        currentZoomIndex = max(0, min(predefinedAltitudes.count - 1, index))
    }
    
    /// ズームインが可能かどうか
    var canZoomIn: Bool {
        currentZoomIndex > 0
    }
    
    /// ズームアウトが可能かどうか
    var canZoomOut: Bool {
        currentZoomIndex < predefinedAltitudes.count - 1
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