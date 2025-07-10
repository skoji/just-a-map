import SwiftUI
import CoreLocation

/// 高度表示コンポーネント
struct AltitudeView: View {
    private let altitude: Double?
    private let verticalAccuracy: Double?
    private let unit: AltitudeUnit
    private let isLoading: Bool
    
    init(altitude: Double? = nil, verticalAccuracy: Double? = nil, unit: AltitudeUnit, isLoading: Bool = false) {
        self.altitude = altitude
        self.verticalAccuracy = verticalAccuracy
        self.unit = unit
        self.isLoading = isLoading
    }
    
    private var displayText: String {
        if isLoading {
            return "---"
        }
        
        guard let altitude = altitude,
              let accuracy = verticalAccuracy,
              accuracy >= 0 else {
            return "---" // 無効な高度データの場合
        }
        
        return unit.displayString(for: altitude)
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "mountain.2.fill")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if isLoading {
                Text("---")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
            } else {
                Text(displayText)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.primary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 1)
    }
}

#Preview {
    VStack(spacing: 20) {
        AltitudeView(altitude: 123.0, verticalAccuracy: 5.0, unit: .meters)
        AltitudeView(altitude: 123.0, verticalAccuracy: 5.0, unit: .feet)
        AltitudeView(altitude: 123.0, verticalAccuracy: -1.0, unit: .meters)
        AltitudeView(unit: .meters, isLoading: true)
    }
    .padding()
}