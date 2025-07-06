import SwiftUI

/// 地図中心を示すクロスヘア（十字マーク）
struct CrosshairView: View {
    var body: some View {
        ZStack {
            // 十字マーク（外側の白い線で視認性向上）
            ZStack {
                // 横線（白い縁取り）
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 32, height: 5)
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                
                // 横線（赤い中心線）
                Rectangle()
                    .fill(Color.red)
                    .frame(width: 30, height: 3)
                
                // 縦線（白い縁取り）
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 5, height: 32)
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                
                // 縦線（赤い中心線）
                Rectangle()
                    .fill(Color.red)
                    .frame(width: 3, height: 30)
            }
            
            // 中心の点（白い縁取り付き）
            Circle()
                .fill(Color.white)
                .frame(width: 8, height: 8)
                .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
            
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