import Foundation

/// String extension for localization support
extension String {
    /// Returns the localized string for the current key
    var localized: String {
        return NSLocalizedString(self, bundle: Bundle.module, comment: "")
    }
    
    /// Returns the localized string with format arguments
    func localized(with arguments: CVarArg...) -> String {
        return String(format: NSLocalizedString(self, bundle: Bundle.module, comment: ""), arguments: arguments)
    }
}