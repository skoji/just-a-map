import Foundation
@testable import JustAMap

class MockBundle: BundleProtocol {
    var infoDictionary: [String: Any]?
    
    func object(forInfoDictionaryKey key: String) -> Any? {
        return infoDictionary?[key]
    }
}