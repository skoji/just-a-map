import Foundation

/// String extension for localization support
extension String {
    /// Returns the localized string for the current key
    var localized: String {
        // Try Bundle.module first (for Swift Package), then fall back to Bundle.main (for iOS app)
        let moduleString = NSLocalizedString(self, bundle: .module, comment: "")
        if moduleString != self {
            return moduleString
        }
        
        return NSLocalizedString(self, bundle: .main, comment: "")
    }
    
    /// Returns the localized string with format arguments
    func localized(with arguments: CVarArg...) -> String {
        let formatString = self.localized
        return String(format: formatString, arguments: arguments)
    }
}