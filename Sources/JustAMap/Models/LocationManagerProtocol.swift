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
    
    /// 速度とズームレベルに基づいて更新頻度を調整
    /// - Parameters:
    ///   - speed: 現在の速度（km/h）
    ///   - zoomDistance: 地図のズーム距離（メートル）
    func adjustUpdateFrequency(forSpeed speed: Double, zoomDistance: Double)
}

/// LocationManagerのイベントを受け取るデリゲート
protocol LocationManagerDelegate: AnyObject {
    /// 位置情報が更新された時
    func locationManager(_ manager: LocationManagerProtocol, didUpdateLocation location: CLLocation)
    
    /// エラーが発生した時
    func locationManager(_ manager: LocationManagerProtocol, didFailWithError error: Error)
    
    /// 認証ステータスが変更された時
    func locationManager(_ manager: LocationManagerProtocol, didChangeAuthorization status: CLAuthorizationStatus)
}

/// 位置情報関連のエラー
enum LocationError: Error, Equatable {
    case authorizationDenied
    case locationServicesDisabled
    case locationUpdateFailed(String)
    
    var localizedDescription: String {
        switch self {
        case .authorizationDenied:
            return "位置情報の使用が許可されていません"
        case .locationServicesDisabled:
            return "位置情報サービスが無効になっています"
        case .locationUpdateFailed(let reason):
            return "位置情報の取得に失敗しました: \(reason)"
        }
    }
}