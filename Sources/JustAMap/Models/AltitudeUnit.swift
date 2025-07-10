import Foundation
import CoreLocation

/// 高度表示の単位
enum AltitudeUnit: String, CaseIterable {
    case meters = "meters"
    case feet = "feet"
    
    /// 単位記号
    var symbol: String {
        switch self {
        case .meters:
            return "m"
        case .feet:
            return "ft"
        }
    }
    
    /// 高度値を指定された単位の文字列として表示
    /// - Parameter altitude: 高度値（メートル単位、CLLocationのaltitudeから取得）
    /// - Returns: 表示用文字列（例: "100m", "328ft", "---"）
    func displayString(for altitude: Double) -> String {
        // CLLocationのverticalAccuracyが負の場合は無効な高度を示す
        // ここでは簡単化して負の値は無効として扱う
        guard altitude >= 0 else {
            return "---"
        }
        
        switch self {
        case .meters:
            return "\(Int(altitude.rounded()))\(symbol)"
        case .feet:
            let feetValue = Self.convertToFeet(meters: altitude)
            return "\(Int(feetValue.rounded()))\(symbol)"
        }
    }
    
    /// メートルをフィートに変換
    /// - Parameter meters: メートル値
    /// - Returns: フィート値
    static func convertToFeet(meters: Double) -> Double {
        return meters * 3.28084
    }
    
    /// フィートをメートルに変換
    /// - Parameter feet: フィート値
    /// - Returns: メートル値
    static func convertToMeters(feet: Double) -> Double {
        return feet / 3.28084
    }
}