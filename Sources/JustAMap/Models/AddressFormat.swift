import Foundation

enum AddressFormat: String, CaseIterable {
    case standard = "standard"
    case detailed = "detailed"
    case simple = "simple"
    
    var displayName: String {
        switch self {
        case .standard:
            return "address_format.standard".localized
        case .detailed:
            return "address_format.detailed".localized
        case .simple:
            return "address_format.simple".localized
        }
    }
    
    var description: String {
        switch self {
        case .standard:
            return "address_format.standard_description".localized
        case .detailed:
            return "address_format.detailed_description".localized
        case .simple:
            return "address_format.simple_description".localized
        }
    }
}