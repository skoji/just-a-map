import Foundation
import SwiftUI

class SettingsViewModel: ObservableObject {
    private var settingsStorage: MapSettingsStorageProtocol
    private var bundle: BundleProtocol
    private var versionInfo: [String: Any]?
    
    // ズームインデックスの範囲
    static let minZoomIndex = ZoomConstants.minIndex
    static let maxZoomIndex = ZoomConstants.maxIndex
    
    // Bundle info dictionary keys
    private static let appVersionKey = "CFBundleShortVersionString"
    private static let buildNumberKey = "CFBundleVersion"
    private static let unknownAppInfoLocalized = "app_info.unknown".localized
    
    @Published var defaultZoomIndex: Int {
        didSet {
            settingsStorage.defaultZoomIndex = defaultZoomIndex
        }
    }
    
    @Published var defaultMapStyle: MapStyle {
        didSet {
            settingsStorage.defaultMapStyle = defaultMapStyle
        }
    }
    
    @Published var defaultIsNorthUp: Bool {
        didSet {
            settingsStorage.defaultIsNorthUp = defaultIsNorthUp
        }
    }
    
    @Published var addressFormat: AddressFormat {
        didSet {
            settingsStorage.addressFormat = addressFormat
        }
    }
    
    @Published var isAltitudeDisplayEnabled: Bool {
        didSet {
            settingsStorage.isAltitudeDisplayEnabled = isAltitudeDisplayEnabled
        }
    }
    
    @Published var altitudeUnit: AltitudeUnit {
        didSet {
            settingsStorage.altitudeUnit = altitudeUnit
        }
    }
    
    init(settingsStorage: MapSettingsStorageProtocol = MapSettingsStorage(), bundle: BundleProtocol = Bundle.main) {
        self.settingsStorage = settingsStorage
        self.bundle = bundle
        self.defaultZoomIndex = settingsStorage.defaultZoomIndex
        self.defaultMapStyle = settingsStorage.defaultMapStyle
        self.defaultIsNorthUp = settingsStorage.defaultIsNorthUp
        self.addressFormat = settingsStorage.addressFormat
        self.isAltitudeDisplayEnabled = settingsStorage.isAltitudeDisplayEnabled
        self.altitudeUnit = settingsStorage.altitudeUnit
        
        // Load version info from VersionInfo.plist if available
        if let versionInfoURL = bundle.url(forResource: "VersionInfo", withExtension: "plist"),
           let data = try? Data(contentsOf: versionInfoURL),
           let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] {
            self.versionInfo = plist
        }
    }
    
    var zoomLevelDisplayText: String {
        let zoomLevels: [String] = [
            "200m", "500m", "1km", "2km", "5km", "10km",
            "20km", "50km", "100km", "200km", "500km", "1,000km"
        ]
        
        guard defaultZoomIndex >= 0 && defaultZoomIndex < zoomLevels.count else {
            return zoomLevels[5] // デフォルト
        }
        
        return zoomLevels[defaultZoomIndex]
    }
    
    var appVersion: String {
        // First try to get from VersionInfo.plist
        if let versionInfo = versionInfo,
           let version = versionInfo[Self.appVersionKey] as? String {
            return version
        }
        
        // Fallback to bundle info
        guard let version = bundle.object(forInfoDictionaryKey: Self.appVersionKey) as? String else {
            return Self.unknownAppInfoLocalized
        }
        return version
    }
    
    var buildNumber: String {
        // First try to get from VersionInfo.plist
        if let versionInfo = versionInfo,
           let buildNumber = versionInfo[Self.buildNumberKey] as? String {
            return buildNumber
        }
        
        // Fallback to bundle info
        guard let buildNumber = bundle.object(forInfoDictionaryKey: Self.buildNumberKey) as? String else {
            return Self.unknownAppInfoLocalized
        }
        return buildNumber
    }
}