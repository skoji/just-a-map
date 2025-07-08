import Foundation
@testable import JustAMap

class MockIdleTimerManager: IdleTimerManagerProtocol {
    var isIdleTimerDisabled = false
    
    func setIdleTimerDisabled(_ disabled: Bool) {
        isIdleTimerDisabled = disabled
    }
    
    func handleAppDidEnterBackground() {}
    func handleAppWillEnterForeground() {}
}