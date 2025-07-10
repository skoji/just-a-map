import SwiftUI
import CoreLocation

/// 速度表示コンポーネント
struct SpeedView: View {
    private let speed: Double?
    private let unit: SpeedUnit
    private let isLoading: Bool
    
    init(speed: Double? = nil, unit: SpeedUnit, isLoading: Bool = false) {
        self.speed = speed
        self.unit = unit
        self.isLoading = isLoading
    }
    
    private var displayText: String {
        if isLoading {
            return "---"
        }
        
        guard let speed = speed, speed >= 0 else {
            return "---" // 無効な速度データの場合
        }
        
        // CLLocationのspeedはm/s単位なので、km/hに変換
        let kmhSpeed = speed * 3.6
        return unit.displayString(for: kmhSpeed)
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "speedometer")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.secondary)
            
            if isLoading {
                Text("---")
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
            } else {
                Text(displayText)
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundColor(.primary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(radius: 2)
        )
        .padding(.horizontal, 16)
    }
}

#Preview {
    VStack(spacing: 20) {
        SpeedView(speed: 13.89, unit: .kmh) // 50 km/h
        SpeedView(speed: 13.89, unit: .mph) // 50 km/h = 31 mph
        SpeedView(speed: -1.0, unit: .kmh) // invalid speed
        SpeedView(unit: .kmh, isLoading: true)
        SpeedView(speed: 0.0, unit: .kmh) // stopped
    }
    .padding()
}