import Foundation
import SwiftUI

@MainActor
class CompassViewModel: ObservableObject {
    @Published var rotation: Double = 0
    @Published var isNorthUp: Bool = true  // デフォルトはNorth Up（MapSettingsStorageと同じ）
    
    /// Closure called when the compass orientation is toggled
    /// - Parameter isNorthUp: The new orientation state (true for North Up, false for Heading Up)
    var onToggle: ((Bool) -> Void)?
    
    func updateRotation(_ degrees: Double) {
        guard !isNorthUp else {
            rotation = 0
            return
        }
        
        // Normalize rotation to 0-360 range
        var normalizedRotation = degrees.truncatingRemainder(dividingBy: 360)
        if normalizedRotation < 0 {
            normalizedRotation += 360
        }
        rotation = normalizedRotation
    }
    
    func toggleOrientation() {
        isNorthUp.toggle()
        onToggle?(isNorthUp)
        
        // Reset rotation to 0 when switching to North Up
        if isNorthUp {
            rotation = 0
        }
    }
    
    /// Sync orientation state from external source (e.g., MapViewModel)
    /// This ensures rotation is reset properly when switching to North Up
    /// - Parameters:
    ///   - isNorthUp: The new orientation state
    ///   - currentHeading: The current map heading (used when switching to Heading Up mode)
    func syncOrientation(isNorthUp: Bool, currentHeading: Double = 0) {
        self.isNorthUp = isNorthUp
        if isNorthUp {
            rotation = 0
        } else {
            // When switching to Heading Up, update rotation to current heading
            updateRotation(currentHeading)
        }
    }
}