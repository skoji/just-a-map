import Foundation

/// 表示用にフォーマットされた住所
struct FormattedAddress {
    let primaryText: String      // メインの表示テキスト（名前や地域名）
    let secondaryText: String    // サブの表示テキスト（詳細住所）
    let postalCode: String?      // 郵便番号（表示用フォーマット済み）
}

/// 住所を表示用にフォーマットするクラス
class AddressFormatter {
    private let settingsStorage: MapSettingsStorageProtocol
    
    init(settingsStorage: MapSettingsStorageProtocol = MapSettingsStorage()) {
        self.settingsStorage = settingsStorage
    }
    
    /// 住所を表示用にフォーマット
    func formatForDisplay(_ address: Address) -> FormattedAddress {
        let format = settingsStorage.addressFormat
        
        switch format {
        case .standard:
            let primaryText = determinePrimaryText(from: address)
            let secondaryText = buildFullAddressFromComponents(from: address)
            let formattedPostalCode = formatPostalCode(address.postalCode)
            
            return FormattedAddress(
                primaryText: primaryText,
                secondaryText: secondaryText,
                postalCode: formattedPostalCode
            )
            
        case .detailed:
            // 詳細フォーマット：常に完全な住所を表示
            let primaryText = buildFullAddressFromComponents(from: address)
            let secondaryText = buildDetailedSecondaryText(from: address)
            let formattedPostalCode = formatPostalCode(address.postalCode)
            
            return FormattedAddress(
                primaryText: primaryText,
                secondaryText: secondaryText,
                postalCode: formattedPostalCode
            )
            
        case .simple:
            // シンプルフォーマット：市区町村のみ
            let primaryText = address.locality ?? "現在地"
            let secondaryText = ""
            
            return FormattedAddress(
                primaryText: primaryText,
                secondaryText: secondaryText,
                postalCode: nil
            )
        }
    }
    
    private func determinePrimaryText(from address: Address) -> String {
        // 優先順位: 1. 場所の名前, 2. 都道府県+市区町村/郡など, 3. デフォルト
        if let name = address.name, !name.isEmpty {
            return name
        }
        
        var components: [String] = []
        
        // 都道府県を追加
        if let administrativeArea = address.administrativeArea, !administrativeArea.isEmpty {
            components.append(administrativeArea)
        }
        
        // 市区町村/郡を追加（subAdministrativeAreaがあればそれを、なければlocalityを使用）
        if let subAdministrativeArea = address.subAdministrativeArea, !subAdministrativeArea.isEmpty {
            components.append(subAdministrativeArea)
        } else if let locality = address.locality, !locality.isEmpty {
            components.append(locality)
        }
        
        if !components.isEmpty {
            return components.joined(separator: " ")
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
    
    private func buildDetailedSecondaryText(from address: Address) -> String {
        var components: [String] = []
        
        // 場所名
        if let name = address.name, !name.isEmpty {
            components.append(name)
        }
        
        // 市区町村
        if let locality = address.locality, !locality.isEmpty {
            components.append(locality)
        }
        
        // 郡・地区
        if let subAdministrativeArea = address.subAdministrativeArea, !subAdministrativeArea.isEmpty {
            components.append(subAdministrativeArea)
        }
        
        // 都道府県
        if let administrativeArea = address.administrativeArea, !administrativeArea.isEmpty {
            components.append(administrativeArea)
        }
        
        // 国
        if let country = address.country, !country.isEmpty {
            components.append(country)
        }
        
        return components.joined(separator: " / ")
    }
    
    private func buildFullAddressFromComponents(from address: Address) -> String {
        var components: [String] = []
        
        // 都道府県
        if let administrativeArea = address.administrativeArea, !administrativeArea.isEmpty {
            components.append(administrativeArea)
        }
        
        // 市区町村/郡
        if let subAdministrativeArea = address.subAdministrativeArea, !subAdministrativeArea.isEmpty {
            components.append(subAdministrativeArea)
        }
        
        // 区市町村
        if let locality = address.locality, !locality.isEmpty {
            components.append(locality)
        }
        
        // fullAddressが存在し、コンポーネントで構築した住所より詳細な情報を含む場合
        if let fullAddress = address.fullAddress, !fullAddress.isEmpty {
            // コンポーネントで構築した住所
            let builtAddress = components.joined(separator: "")
            
            // fullAddressがbuiltAddressで始まる場合、残りの部分（番地など）を取得
            if fullAddress.hasPrefix(builtAddress) {
                let remainingPart = String(fullAddress.dropFirst(builtAddress.count))
                let trimmed = remainingPart.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    components.append(trimmed)
                }
            } else {
                // fullAddressの構造が予期したものと異なる場合は、fullAddressをそのまま使用
                return fullAddress
            }
        }
        
        // コンポーネントが空の場合はfullAddressをそのまま返す
        if components.isEmpty {
            return address.fullAddress ?? ""
        }
        
        return components.joined(separator: "")
    }
}