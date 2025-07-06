import Foundation

/// 表示用にフォーマットされた住所
struct FormattedAddress {
    let primaryText: String      // メインの表示テキスト（名前や地域名）
    let secondaryText: String    // サブの表示テキスト（詳細住所）
    let postalCode: String?      // 郵便番号（表示用フォーマット済み）
}

/// 住所を表示用にフォーマットするクラス
class AddressFormatter {
    
    /// 住所を表示用にフォーマット
    func formatForDisplay(_ address: Address) -> FormattedAddress {
        let primaryText = determinePrimaryText(from: address)
        let secondaryText = address.fullAddress
        let formattedPostalCode = formatPostalCode(address.postalCode)
        
        return FormattedAddress(
            primaryText: primaryText,
            secondaryText: secondaryText,
            postalCode: formattedPostalCode
        )
    }
    
    private func determinePrimaryText(from address: Address) -> String {
        // 優先順位: 1. 場所の名前, 2. 市区町村, 3. デフォルト
        if let name = address.name, !name.isEmpty {
            return name
        }
        
        if let locality = address.locality, !locality.isEmpty {
            return locality
        }
        
        return "現在地"
    }
    
    private func formatPostalCode(_ postalCode: String?) -> String? {
        guard let postalCode = postalCode, !postalCode.isEmpty else {
            return nil
        }
        
        // すでに〒が含まれている場合はそのまま返す
        if postalCode.hasPrefix("〒") {
            return postalCode
        }
        
        return "〒\(postalCode)"
    }
}