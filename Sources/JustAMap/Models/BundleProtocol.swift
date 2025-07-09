import Foundation

protocol BundleProtocol {
    func object(forInfoDictionaryKey key: String) -> Any?
}

extension Bundle: BundleProtocol {}