import Foundation
import CoreLocation

/// 速度表示の単位
enum SpeedUnit: String, CaseIterable {
    case kmh = "kmh"
    case mph = "mph"
    
    /// 単位記号
    var symbol: String {
        switch self {
        case .kmh:
            return "km/h"
        case .mph:
            return "mph"
        }
    }
    
    /// 速度値を指定された単位の文字列として表示
    /// - Parameter speed: 速度値（km/h単位、CLLocationのspeedから取得した値を3.6倍したもの）
    /// - Returns: 表示用文字列（例: "50km/h", "31mph", "---"）
    func displayString(for speed: Double) -> String {
        // 負の値は無効な速度を示す
        guard speed >= 0 else {
            return "---"
        }
        
        switch self {
        case .kmh:
            return "\(Int(speed.rounded()))\(symbol)"
        case .mph:
            let mphValue = Self.convertKmhToMph(kmh: speed)
            return "\(Int(mphValue.rounded()))\(symbol)"
        }
    }
    
    /// km/hをmphに変換
    /// - Parameter kmh: km/h値
    /// - Returns: mph値
    static func convertKmhToMph(kmh: Double) -> Double {
        return kmh * 0.6213711922
    }
    
    /// mphをkm/hに変換
    /// - Parameter mph: mph値
    /// - Returns: km/h値
    static func convertMphToKmh(mph: Double) -> Double {
        return mph * 1.609344
    }
}