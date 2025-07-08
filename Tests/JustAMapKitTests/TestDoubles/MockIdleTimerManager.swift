import Foundation
@testable import JustAMapKit

class MockIdleTimerManager: IdleTimerManagerProtocol {
    var isIdleTimerDisabled = false
    
    func setIdleTimerDisabled(_ disabled: Bool) {
        isIdleTimerDisabled = disabled
    }
    
    func handleAppDidEnterBackground() {}
    func handleAppWillEnterForeground() {}
}