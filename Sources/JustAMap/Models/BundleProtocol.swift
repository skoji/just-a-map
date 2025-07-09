import Foundation

protocol BundleProtocol {
    func object(forInfoDictionaryKey key: String) -> Any?
    func url(forResource name: String?, withExtension ext: String?) -> URL?
}

extension Bundle: BundleProtocol {}