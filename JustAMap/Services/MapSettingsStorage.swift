import Foundation
import MapKit

/// UserDefaultsのプロトコル（テスト用）
protocol UserDefaultsProtocol {
    func object(forKey defaultName: String) -> Any?
    func set(_ value: Any?, forKey defaultName: String)
    func bool(forKey defaultName: String) -> Bool
    func double(forKey defaultName: String) -> Double
    func string(forKey defaultName: String) -> String?
}

/// UserDefaultsをプロトコルに準拠
extension UserDefaults: UserDefaultsProtocol {}

/// 地図設定の永続化を管理するプロトコル
protocol MapSettingsStorageProtocol {
    func saveMapStyle(_ style: MapStyle)
    func loadMapStyle() -> MapStyle
    func saveMapOrientation(isNorthUp: Bool)
    func loadMapOrientation() -> Bool
    func saveZoomLevel(span: MKCoordinateSpan)
    func loadZoomLevel() -> MKCoordinateSpan?
}

/// 地図設定の永続化サービス
class MapSettingsStorage: MapSettingsStorageProtocol {
    private let userDefaults: UserDefaultsProtocol
    
    // UserDefaults keys
    private enum Keys {
        static let mapStyle = "mapStyle"
        static let isNorthUp = "isNorthUp"
        static let zoomLatDelta = "zoomLatDelta"
        static let zoomLonDelta = "zoomLonDelta"
    }
    
    init(userDefaults: UserDefaultsProtocol = UserDefaults.standard) {
        self.userDefaults = userDefaults
    }
    
    // MARK: - Map Style
    
    func saveMapStyle(_ style: MapStyle) {
        userDefaults.set(style.rawValue, forKey: Keys.mapStyle)
    }
    
    func loadMapStyle() -> MapStyle {
        guard let rawValue = userDefaults.string(forKey: Keys.mapStyle),
              let style = MapStyle(rawValue: rawValue) else {
            return .standard // デフォルト
        }
        return style
    }
    
    // MARK: - Map Orientation
    
    func saveMapOrientation(isNorthUp: Bool) {
        userDefaults.set(isNorthUp, forKey: Keys.isNorthUp)
    }
    
    func loadMapOrientation() -> Bool {
        // デフォルトがtrueなので、キーが存在しない場合もtrueを返す
        if userDefaults.object(forKey: Keys.isNorthUp) != nil {
            return userDefaults.bool(forKey: Keys.isNorthUp)
        }
        return true // デフォルトはNorth Up
    }
    
    // MARK: - Zoom Level
    
    func saveZoomLevel(span: MKCoordinateSpan) {
        userDefaults.set(span.latitudeDelta, forKey: Keys.zoomLatDelta)
        userDefaults.set(span.longitudeDelta, forKey: Keys.zoomLonDelta)
    }
    
    func loadZoomLevel() -> MKCoordinateSpan? {
        let latDelta = userDefaults.double(forKey: Keys.zoomLatDelta)
        let lonDelta = userDefaults.double(forKey: Keys.zoomLonDelta)
        
        // 0の場合は保存されていないと判断
        if latDelta == 0 || lonDelta == 0 {
            return nil
        }
        
        return MKCoordinateSpan(
            latitudeDelta: latDelta,
            longitudeDelta: lonDelta
        )
    }
}