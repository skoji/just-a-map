import SwiftUI

struct CompassView: View {
    @ObservedObject var viewModel: CompassViewModel
    
    struct Constants {
        static let size: CGFloat = 44
        static let needleLength: CGFloat = 10  // さらに短く
        static let needleWidth: CGFloat = 3
        static let borderWidth: CGFloat = 1.5
        static let shadowRadius: CGFloat = 3
        static let tickLength: CGFloat = 2  // より内側に
        static let tickWidth: CGFloat = 1
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
                    .stroke(Color(.systemGray3), lineWidth: Constants.borderWidth)
                    .frame(width: Constants.size, height: Constants.size)
                
                // Compass dial with ticks
                ForEach(0..<12) { index in
                    Rectangle()
                        .fill(Color(.systemGray2))
                        .frame(width: Constants.tickWidth, height: index % 3 == 0 ? Constants.tickLength * 1.5 : Constants.tickLength)
                        .offset(y: -Constants.size / 2 + Constants.tickLength + 3)  // さらに内側に
                        .rotationEffect(.degrees(Double(index) * 30))
                }
                
                // Compass needle container with fixed frame
                ZStack {
                    // Compass needle (Google Maps style)
                    GeometryReader { geometry in
                        let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                        
                        // North needle (red)
                        Path { path in
                            path.move(to: CGPoint(x: center.x, y: center.y - Constants.needleLength))
                            path.addLine(to: CGPoint(x: center.x - Constants.needleWidth / 2, y: center.y))
                            path.addLine(to: CGPoint(x: center.x + Constants.needleWidth / 2, y: center.y))
                            path.closeSubpath()
                        }
                        .fill(Color.red)
                        
                        // South needle (white with gray border)
                        Path { path in
                            path.move(to: CGPoint(x: center.x, y: center.y + Constants.needleLength))
                            path.addLine(to: CGPoint(x: center.x - Constants.needleWidth / 2, y: center.y))
                            path.addLine(to: CGPoint(x: center.x + Constants.needleWidth / 2, y: center.y))
                            path.closeSubpath()
                        }
                        .fill(Color.white)
                        .overlay(
                            Path { path in
                                path.move(to: CGPoint(x: center.x, y: center.y + Constants.needleLength))
                                path.addLine(to: CGPoint(x: center.x - Constants.needleWidth / 2, y: center.y))
                                path.addLine(to: CGPoint(x: center.x + Constants.needleWidth / 2, y: center.y))
                                path.closeSubpath()
                            }
                            .stroke(Color(.systemGray3), lineWidth: 0.5)
                        )
                        
                        // Center dot
                        Circle()
                            .fill(Color(.systemGray))
                            .frame(width: 4, height: 4)
                            .position(center)
                    }
                    .frame(width: Constants.size, height: Constants.size)
                }
                .frame(width: Constants.size, height: Constants.size)
                .rotationEffect(.degrees(-viewModel.rotation))
                .animation(.easeInOut(duration: 0.3), value: viewModel.rotation)
                
                // North Up indicator (blue tint when active)
                if viewModel.isNorthUp {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: Constants.size - 4, height: Constants.size - 4)
                }
            }
            .frame(width: Constants.size, height: Constants.size)
            .shadow(color: Color.black.opacity(0.15), radius: Constants.shadowRadius, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("Compass. Tap to toggle map orientation")
    }
}