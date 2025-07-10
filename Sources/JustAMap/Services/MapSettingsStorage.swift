import Foundation
import MapKit

/// UserDefaultsのプロトコル（テスト用）
protocol UserDefaultsProtocol {
    func object(forKey defaultName: String) -> Any?
    func set(_ value: Any?, forKey defaultName: String)
    func bool(forKey defaultName: String) -> Bool
    func double(forKey defaultName: String) -> Double
    func string(forKey defaultName: String) -> String?
    func integer(forKey defaultName: String) -> Int
}

/// UserDefaultsをプロトコルに準拠
extension UserDefaults: UserDefaultsProtocol {}

/// 地図設定の永続化を管理するプロトコル
protocol MapSettingsStorageProtocol {
    // 現在の設定
    var mapStyle: MapStyle { get set }
    var isNorthUp: Bool { get set }
    var zoomIndex: Int { get set }
    
    // デフォルト設定
    var defaultZoomIndex: Int { get set }
    var defaultMapStyle: MapStyle { get set }
    var defaultIsNorthUp: Bool { get set }
    var addressFormat: AddressFormat { get set }
    
    // 高度表示設定
    var isAltitudeDisplayEnabled: Bool { get set }
    var altitudeUnit: AltitudeUnit { get set }
    
    // 従来のメソッド（互換性のため維持）
    func saveMapStyle(_ style: MapStyle)
    func loadMapStyle() -> MapStyle
    func saveMapOrientation(isNorthUp: Bool)
    func loadMapOrientation() -> Bool
    func saveZoomLevel(span: MKCoordinateSpan)
    func loadZoomLevel() -> MKCoordinateSpan?
    func saveZoomIndex(_ index: Int)
    func loadZoomIndex() -> Int?
    
    // 初回起動チェック
    func isFirstLaunch() -> Bool
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
        static let zoomIndex = "zoomIndex"
        static let defaultZoomIndex = "defaultZoomIndex"
        static let defaultMapStyle = "defaultMapStyle"
        static let defaultIsNorthUp = "defaultIsNorthUp"
        static let addressFormat = "addressFormat"
        static let isAltitudeDisplayEnabled = "isAltitudeDisplayEnabled"
        static let altitudeUnit = "altitudeUnit"
    }
    
    init(userDefaults: UserDefaultsProtocol = UserDefaults.standard) {
        self.userDefaults = userDefaults
    }
    
    // MARK: - Computed Properties for Protocol Conformance
    
    var mapStyle: MapStyle {
        get { loadMapStyle() }
        set { saveMapStyle(newValue) }
    }
    
    var isNorthUp: Bool {
        get { loadMapOrientation() }
        set { saveMapOrientation(isNorthUp: newValue) }
    }
    
    var zoomIndex: Int {
        get { loadZoomIndex() ?? 5 }
        set { saveZoomIndex(newValue) }
    }
    
    var defaultZoomIndex: Int {
        get {
            if userDefaults.object(forKey: Keys.defaultZoomIndex) != nil {
                return userDefaults.integer(forKey: Keys.defaultZoomIndex)
            }
            return 5 // デフォルト値
        }
        set {
            userDefaults.set(newValue, forKey: Keys.defaultZoomIndex)
        }
    }
    
    var defaultMapStyle: MapStyle {
        get {
            guard let rawValue = userDefaults.string(forKey: Keys.defaultMapStyle),
                  let style = MapStyle(rawValue: rawValue) else {
                return .standard // デフォルト
            }
            return style
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: Keys.defaultMapStyle)
        }
    }
    
    var defaultIsNorthUp: Bool {
        get {
            if userDefaults.object(forKey: Keys.defaultIsNorthUp) != nil {
                return userDefaults.bool(forKey: Keys.defaultIsNorthUp)
            }
            return true // デフォルトはNorth Up
        }
        set {
            userDefaults.set(newValue, forKey: Keys.defaultIsNorthUp)
        }
    }
    
    var addressFormat: AddressFormat {
        get {
            guard let rawValue = userDefaults.string(forKey: Keys.addressFormat),
                  let format = AddressFormat(rawValue: rawValue) else {
                return .standard // デフォルト
            }
            return format
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: Keys.addressFormat)
        }
    }
    
    var isAltitudeDisplayEnabled: Bool {
        get {
            if userDefaults.object(forKey: Keys.isAltitudeDisplayEnabled) != nil {
                return userDefaults.bool(forKey: Keys.isAltitudeDisplayEnabled)
            }
            return false // デフォルトは無効
        }
        set {
            userDefaults.set(newValue, forKey: Keys.isAltitudeDisplayEnabled)
        }
    }
    
    var altitudeUnit: AltitudeUnit {
        get {
            guard let rawValue = userDefaults.string(forKey: Keys.altitudeUnit),
                  let unit = AltitudeUnit(rawValue: rawValue) else {
                return .meters // デフォルト
            }
            return unit
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: Keys.altitudeUnit)
        }
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
    
    // MARK: - Zoom Index
    
    func saveZoomIndex(_ index: Int) {
        userDefaults.set(index, forKey: Keys.zoomIndex)
    }
    
    func loadZoomIndex() -> Int? {
        // キーが存在するか確認
        if userDefaults.object(forKey: Keys.zoomIndex) != nil {
            return userDefaults.integer(forKey: Keys.zoomIndex)
        }
        return nil
    }
    
    // MARK: - First Launch Check
    
    func isFirstLaunch() -> Bool {
        // いずれかの現在の設定が保存されていない場合は初回起動と判定
        return userDefaults.object(forKey: Keys.mapStyle) == nil &&
               userDefaults.object(forKey: Keys.isNorthUp) == nil &&
               userDefaults.object(forKey: Keys.zoomIndex) == nil
    }
}