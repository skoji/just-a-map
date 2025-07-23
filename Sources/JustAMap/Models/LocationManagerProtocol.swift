import Foundation
import CoreLocation

/// LocationManagerの振る舞いを定義するプロトコル
/// このプロトコルにより、実際のCLLocationManagerとモックを切り替えることができる
protocol LocationManagerProtocol: AnyObject {
    /// デリゲート
    var delegate: LocationManagerDelegate? { get set }
    
    /// 現在の認証ステータス
    var authorizationStatus: CLAuthorizationStatus { get }
    
    /// 位置情報の使用許可をリクエスト
    func requestLocationPermission()
    
    /// 位置情報の更新を開始
    func startLocationUpdates()
    
    /// 位置情報の更新を停止
    func stopLocationUpdates()
    
    /// ズームレベルに基づいて更新頻度を調整
    /// - Parameter zoomLevel: 地図のズームレベル
    func adjustUpdateFrequency(forZoomLevel zoomLevel: Double)
}

/// LocationManagerのイベントを受け取るデリゲート
protocol LocationManagerDelegate: AnyObject {
    /// 位置情報が更新された時
    func locationManager(_ manager: LocationManagerProtocol, didUpdateLocation location: CLLocation)
    
    /// エラーが発生した時
    func locationManager(_ manager: LocationManagerProtocol, didFailWithError error: Error)
    
    /// 認証ステータスが変更された時
    func locationManager(_ manager: LocationManagerProtocol, didChangeAuthorization status: CLAuthorizationStatus)
    
    /// 位置情報の更新が一時停止された時
    func locationManagerDidPauseLocationUpdates(_ manager: LocationManagerProtocol)
    
    /// 位置情報の更新が再開された時
    func locationManagerDidResumeLocationUpdates(_ manager: LocationManagerProtocol)
}

/// 位置情報関連のエラー
enum LocationError: Error, Equatable {
    case authorizationDenied
    case locationServicesDisabled
    case locationUpdateFailed(String)
    
    var localizedDescription: String {
        switch self {
        case .authorizationDenied:
            return "location.error.authorization_denied".localized
        case .locationServicesDisabled:
            return "location.error.services_disabled".localized
        case .locationUpdateFailed(let reason):
            return "location.error.update_failed".localized(with: reason)
        }
    }
}