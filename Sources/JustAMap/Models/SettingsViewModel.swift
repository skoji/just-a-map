import Foundation
import SwiftUI

class SettingsViewModel: ObservableObject {
    private var settingsStorage: MapSettingsStorageProtocol
    private var bundle: BundleProtocol
    private var gitVersionProvider: GitVersionInfoProvider
    
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
    
    init(settingsStorage: MapSettingsStorageProtocol = MapSettingsStorage(), bundle: BundleProtocol = Bundle.main, gitVersionProvider: GitVersionInfoProvider? = nil) {
        self.settingsStorage = settingsStorage
        self.bundle = bundle
        self.gitVersionProvider = gitVersionProvider ?? GitVersionInfoProvider()
        self.defaultZoomIndex = settingsStorage.defaultZoomIndex
        self.defaultMapStyle = settingsStorage.defaultMapStyle
        self.defaultIsNorthUp = settingsStorage.defaultIsNorthUp
        self.addressFormat = settingsStorage.addressFormat
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
        // Try Git-based versioning first
        let gitVersion = gitVersionProvider.versionString
        if !gitVersion.isEmpty && gitVersion != "1.0.0+unknown" {
            return gitVersion
        }
        
        // Fall back to bundle version
        guard let version = bundle.object(forInfoDictionaryKey: Self.appVersionKey) as? String else {
            return Self.unknownAppInfoLocalized
        }
        return version
    }
    
    var buildNumber: String {
        // Try Git-based versioning first
        let gitBuildNumber = gitVersionProvider.buildNumber
        if !gitBuildNumber.isEmpty && gitBuildNumber != "1" {
            return gitBuildNumber
        }
        
        // Fall back to bundle build number
        guard let buildNumber = bundle.object(forInfoDictionaryKey: Self.buildNumberKey) as? String else {
            return Self.unknownAppInfoLocalized
        }
        return buildNumber
    }
}