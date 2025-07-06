import Foundation

enum AddressFormat: String, CaseIterable {
    case standard = "standard"
    case detailed = "detailed"
    case simple = "simple"
    
    var displayName: String {
        switch self {
        case .standard:
            return "標準"
        case .detailed:
            return "詳細"
        case .simple:
            return "シンプル"
        }
    }
    
    var description: String {
        switch self {
        case .standard:
            return "場所名または市区町村を表示"
        case .detailed:
            return "完全な住所を常に表示"
        case .simple:
            return "市区町村のみを表示"
        }
    }
}