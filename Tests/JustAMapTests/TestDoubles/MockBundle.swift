import Foundation
@testable import JustAMap

class MockBundle: BundleProtocol {
    var infoDictionary: [String: Any]?
    var mockResources: [String: URL] = [:]
    
    func object(forInfoDictionaryKey key: String) -> Any? {
        return infoDictionary?[key]
    }
    
    func url(forResource name: String?, withExtension ext: String?) -> URL? {
        guard let name = name else { return nil }
        let key = ext != nil ? "\(name).\(ext!)" : name
        return mockResources[key]
    }
}