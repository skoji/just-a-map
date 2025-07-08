import SwiftUI

/// 住所を表示するビュー
struct AddressView: View {
    let formattedAddress: FormattedAddress?
    let isLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if isLoading && formattedAddress == nil {
                // 初回ローディング時
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("住所を取得中...")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            } else if let address = formattedAddress {
                // 住所表示
                VStack(alignment: .leading, spacing: 2) {
                    // メインテキスト（場所名または地域名）
                    Text(address.primaryText)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    // サブテキスト（詳細住所）
                    Text(address.secondaryText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    // 郵便番号（あれば）
                    if let postalCode = address.postalCode {
                        Text(postalCode)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
}

// MARK: - Preview
struct AddressView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // ローディング状態
            AddressView(formattedAddress: nil, isLoading: true)
            
            // 住所表示（場所名あり）
            AddressView(
                formattedAddress: FormattedAddress(
                    primaryText: "東京駅",
                    secondaryText: "東京都千代田区丸の内1-9-1",
                    postalCode: "〒100-0005"
                ),
                isLoading: false
            )
            
            // 住所表示（場所名なし）
            AddressView(
                formattedAddress: FormattedAddress(
                    primaryText: "千代田区",
                    secondaryText: "東京都千代田区丸の内1-9-1",
                    postalCode: nil
                ),
                isLoading: false
            )
            
            Spacer()
        }
        .background(Color.gray.opacity(0.1))
    }
}