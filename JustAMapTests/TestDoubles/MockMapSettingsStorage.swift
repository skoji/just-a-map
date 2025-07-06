import Foundation
import MapKit
@testable import JustAMap

class MockMapSettingsStorage: MapSettingsStorageProtocol {
    var mapStyle: MapStyle = .standard
    var isNorthUp: Bool = true
    var zoomIndex: Int = 5
    var defaultMapStyle: MapStyle = .standard
    var defaultIsNorthUp: Bool = true
    var defaultZoomIndex: Int = 5
    var addressFormat: AddressFormat = .standard
    
    private var firstLaunch = true
    
    func isFirstLaunch() -> Bool {
        let isFirst = firstLaunch
        firstLaunch = false
        return isFirst
    }
    
    func saveMapStyle(_ style: MapStyle) {
        mapStyle = style
    }
    
    func saveMapOrientation(isNorthUp: Bool) {
        self.isNorthUp = isNorthUp
    }
    
    func saveZoomIndex(_ index: Int) {
        zoomIndex = index
    }
    
    func saveDefaultMapStyle(_ style: MapStyle) {
        defaultMapStyle = style
    }
    
    func saveDefaultMapOrientation(isNorthUp: Bool) {
        defaultIsNorthUp = isNorthUp
    }
    
    func saveDefaultZoomIndex(_ index: Int) {
        defaultZoomIndex = index
    }
    
    func saveAddressFormat(_ format: AddressFormat) {
        addressFormat = format
    }
    
    // 従来のメソッド（互換性のため実装）
    func loadMapStyle() -> MapStyle {
        return mapStyle
    }
    
    func loadMapOrientation() -> Bool {
        return isNorthUp
    }
    
    func saveZoomLevel(span: MKCoordinateSpan) {
        // Not needed for these tests
    }
    
    func loadZoomLevel() -> MKCoordinateSpan? {
        return nil
    }
    
    func loadZoomIndex() -> Int? {
        return zoomIndex
    }
}