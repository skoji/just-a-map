import Foundation

/// String extension for localization support
extension String {
    /// Returns the localized string for the current key
    var localized: String {
        return NSLocalizedString(self, bundle: Bundle.module, comment: "")
    }
    
    /// Returns the localized string with format arguments
    func localized(with arguments: CVarArg...) -> String {
        let formatString = self.localized
        return String(format: formatString, arguments: arguments)
    }
}