import Foundation

/// 高度表示の単位
enum AltitudeUnit: String, CaseIterable {
    case meters = "meters"
    case feet = "feet"
    
    /// 表示用のシンボル
    var displaySymbol: String {
        switch self {
        case .meters:
            return "m"
        case .feet:
            return "ft"
        }
    }
    
    /// 表示用の名前（ローカライズ対応）
    var displayName: String {
        switch self {
        case .meters:
            return "altitude_unit.meters".localized
        case .feet:
            return "altitude_unit.feet".localized
        }
    }
    
    /// メートルをフィートに変換
    static func convertToFeet(meters: Double) -> Double {
        return meters * 3.28084
    }
    
    /// フィートをメートルに変換
    static func convertToMeters(feet: Double) -> Double {
        return feet / 3.28084
    }
    
    /// 高度をフォーマットして表示
    /// - Parameter altitude: 高度（メートルまたはフィート）。nilの場合は"---"を返す
    /// - Returns: フォーマット済み文字列
    func formatAltitude(_ altitude: Double?) -> String {
        guard let altitude = altitude else {
            return "---"
        }
        
        // 整数で表示（小数点以下は四捨五入）
        let roundedAltitude = Int(round(altitude))
        return "\(roundedAltitude) \(displaySymbol)"
    }
}