import SwiftUI

/// 地図中心を示すクロスヘア（十字マーク）
struct CrosshairView: View {
    var body: some View {
        ZStack {
            // 背景の円（視認性向上のため）
            Circle()
                .fill(Color.white.opacity(0.8))
                .frame(width: 40, height: 40)
                .shadow(radius: 2)
            
            // 十字マーク
            ZStack {
                // 横線
                Rectangle()
                    .fill(Color.red)
                    .frame(width: 30, height: 3)
                
                // 縦線
                Rectangle()
                    .fill(Color.red)
                    .frame(width: 3, height: 30)
            }
            
            // 中心の点
            Circle()
                .fill(Color.red)
                .frame(width: 6, height: 6)
        }
    }
}

// MARK: - Preview
struct CrosshairView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray.opacity(0.3)
            CrosshairView()
        }
        .ignoresSafeArea()
    }
}