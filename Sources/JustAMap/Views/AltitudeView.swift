import SwiftUI

/// 高度を表示するView
struct AltitudeView: View {
    let altitude: Double?
    let unit: AltitudeUnit
    let isLoading: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "mountain.2.fill")
                .font(.caption)
                .foregroundColor(.white)
            
            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else {
                Text(displayText)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.7))
        .cornerRadius(8)
        .shadow(radius: 2)
    }
    
    private var displayText: String {
        unit.formatAltitude(altitude)
    }
}

#Preview {
    VStack(spacing: 16) {
        AltitudeView(altitude: 150.7, unit: .meters, isLoading: false)
        AltitudeView(altitude: 492.0, unit: .feet, isLoading: false)
        AltitudeView(altitude: nil, unit: .meters, isLoading: true)
        AltitudeView(altitude: nil, unit: .meters, isLoading: false)
        AltitudeView(altitude: -50.3, unit: .meters, isLoading: false)
    }
    .padding()
    .background(Color.gray.opacity(0.3))
}