#if canImport(UIKit)
import UIKit
#endif
import SwiftUI

/// UIApplicationのプロトコル（テスト用）
protocol UIApplicationProtocol {
    var isIdleTimerDisabled: Bool { get set }
}

/// UIApplicationをプロトコルに準拠させる
#if canImport(UIKit)
extension UIApplication: UIApplicationProtocol {}
#endif

/// スリープ防止機能を管理するプロトコル
protocol IdleTimerManagerProtocol {
    func setIdleTimerDisabled(_ disabled: Bool)
    func handleAppDidEnterBackground()
    func handleAppWillEnterForeground()
}

/// スリープ防止機能の実装
class IdleTimerManager: IdleTimerManagerProtocol {
    private var application: UIApplicationProtocol
    private var shouldKeepScreenOn = false
    
    #if canImport(UIKit)
    init(application: UIApplicationProtocol = UIApplication.shared) {
        self.application = application
    }
    #else
    init(application: UIApplicationProtocol) {
        self.application = application
    }
    #endif
    
    /// スリープ防止の有効/無効を設定
    func setIdleTimerDisabled(_ disabled: Bool) {
        shouldKeepScreenOn = disabled
        updateIdleTimerState()
    }
    
    /// アプリがバックグラウンドに入った時の処理
    func handleAppDidEnterBackground() {
        // バックグラウンドでは必ずスリープ防止を解除
        application.isIdleTimerDisabled = false
    }
    
    /// アプリがフォアグラウンドに戻った時の処理
    func handleAppWillEnterForeground() {
        // 前の状態を復元
        updateIdleTimerState()
    }
    
    private func updateIdleTimerState() {
        application.isIdleTimerDisabled = shouldKeepScreenOn
    }
}