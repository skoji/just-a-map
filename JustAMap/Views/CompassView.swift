import SwiftUI

struct CompassView: View {
    @ObservedObject var viewModel: CompassViewModel
    
    struct Constants {
        static let size: CGFloat = 44
        static let needleLength: CGFloat = 14  // 長くして見やすく
        static let needleWidth: CGFloat = 5   // 太くして見やすく
        static let borderWidth: CGFloat = 1.5
        static let shadowRadius: CGFloat = 3
        static let tickLength: CGFloat = 2
        static let tickWidth: CGFloat = 1
        static let tickCount: Int = 12  // 目盛りの数（30度ごと）
    }
    
    var body: some View {
        Button(action: {
            viewModel.toggleOrientation()
        }) {
            ZStack {
                // Background circle
                Circle()
                    .fill(Color.white)  // 常に白背景で視認性向上
                    .frame(width: Constants.size, height: Constants.size)
                
                // Border
                Circle()
                    .stroke(Color(.systemGray2), lineWidth: Constants.borderWidth)  // より濃い境界線
                    .frame(width: Constants.size, height: Constants.size)
                
                // Compass dial with ticks
                ForEach(0..<Constants.tickCount) { index in
                    Rectangle()
                        .fill(Color(.systemGray))  // より濃い目盛り
                        .frame(width: Constants.tickWidth, height: index % 3 == 0 ? Constants.tickLength * 1.5 : Constants.tickLength)
                        .offset(y: -Constants.size / 2 + Constants.tickLength + 3)
                        .rotationEffect(.degrees(Double(index) * (360.0 / Double(Constants.tickCount))))
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
                        .fill(Color(red: 0.9, green: 0.1, blue: 0.1))  // より鮮やかな赤
                        
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
                            .stroke(Color(.systemGray), lineWidth: 1)  // より太い境界線
                        )
                        
                        // Center dot
                        Circle()
                            .fill(Color.black)  // 黒で目立たせる
                            .frame(width: 6, height: 6)  // 大きくする
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
        .accessibilityValue(viewModel.isNorthUp ? "North Up mode" : "Heading Up mode")
    }
}