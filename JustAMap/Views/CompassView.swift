import SwiftUI

struct CompassView: View {
    @ObservedObject var viewModel: CompassViewModel
    
    struct Constants {
        static let size: CGFloat = 60
        static let iconSize: CGFloat = 30
        static let borderWidth: CGFloat = 2
        static let shadowRadius: CGFloat = 4
    }
    
    var body: some View {
        Button(action: {
            viewModel.toggleOrientation()
        }) {
            ZStack {
                // Background circle
                Circle()
                    .fill(Color(.systemBackground))
                    .frame(width: Constants.size, height: Constants.size)
                
                // Border
                Circle()
                    .stroke(viewModel.isNorthUp ? Color.blue : Color(.systemGray3), lineWidth: Constants.borderWidth)
                    .frame(width: Constants.size, height: Constants.size)
                
                // Compass icon
                Image(systemName: "location.north.fill")
                    .font(.system(size: Constants.iconSize))
                    .foregroundColor(viewModel.isNorthUp ? .blue : .primary)
                    .rotationEffect(.degrees(-viewModel.rotation))
                    .animation(.easeInOut(duration: 0.3), value: viewModel.rotation)
                
                // North indicator (small "N" at the top when in Heading Up mode)
                if !viewModel.isNorthUp {
                    Text("N")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.red)
                        .offset(y: -Constants.size / 2 + 8)
                        .rotationEffect(.degrees(-viewModel.rotation))
                        .animation(.easeInOut(duration: 0.3), value: viewModel.rotation)
                }
            }
            .frame(width: Constants.size, height: Constants.size)
            .shadow(color: Color.black.opacity(0.2), radius: Constants.shadowRadius, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("Compass. Tap to toggle map orientation")
    }
}