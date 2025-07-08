import XCTest
@testable import JustAMapCore

final class IdleTimerManagerTests: XCTestCase {
    var sut: IdleTimerManagerProtocol!
    var mockApplication: MockUIApplication!
    
    override func setUp() {
        super.setUp()
        mockApplication = MockUIApplication()
        sut = IdleTimerManager(application: mockApplication)
    }
    
    override func tearDown() {
        sut = nil
        mockApplication = nil
        super.tearDown()
    }
    
    func testEnableIdleTimerDisabled() {
        // Given
        mockApplication.isIdleTimerDisabled = false
        
        // When
        sut.setIdleTimerDisabled(true)
        
        // Then
        XCTAssertTrue(mockApplication.isIdleTimerDisabled)
    }
    
    func testDisableIdleTimerDisabled() {
        // Given
        mockApplication.isIdleTimerDisabled = true
        
        // When
        sut.setIdleTimerDisabled(false)
        
        // Then
        XCTAssertFalse(mockApplication.isIdleTimerDisabled)
    }
    
    func testIdleTimerStateIsPreserved() {
        // Given
        mockApplication.isIdleTimerDisabled = false
        
        // When
        sut.setIdleTimerDisabled(true)
        sut.setIdleTimerDisabled(true) // 重複呼び出し
        
        // Then
        XCTAssertTrue(mockApplication.isIdleTimerDisabled)
    }
    
    func testHandleAppLifecycle() {
        // Given
        sut.setIdleTimerDisabled(true)
        
        // When - アプリがバックグラウンドに移行
        sut.handleAppDidEnterBackground()
        
        // Then
        XCTAssertFalse(mockApplication.isIdleTimerDisabled)
        
        // When - アプリがフォアグラウンドに復帰
        sut.handleAppWillEnterForeground()
        
        // Then
        XCTAssertTrue(mockApplication.isIdleTimerDisabled)
    }
}

// MARK: - Mock Classes
class MockUIApplication: UIApplicationProtocol {
    var isIdleTimerDisabled: Bool = false
}