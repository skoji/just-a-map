import Foundation
import SwiftUI

class SettingsViewModel: ObservableObject {
    private var settingsStorage: MapSettingsStorageProtocol
    
    // ズームインデックスの範囲
    static let minZoomIndex = ZoomConstants.minIndex
    static let maxZoomIndex = ZoomConstants.maxIndex
    
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
    
    init(settingsStorage: MapSettingsStorageProtocol = MapSettingsStorage()) {
        self.settingsStorage = settingsStorage
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
}