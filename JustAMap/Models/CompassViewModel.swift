import Foundation
import SwiftUI

@MainActor
class CompassViewModel: ObservableObject {
    @Published var rotation: Double = 0
    @Published var isNorthUp: Bool = false
    
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
    func syncOrientation(isNorthUp: Bool) {
        self.isNorthUp = isNorthUp
        if isNorthUp {
            rotation = 0
        }
    }
}