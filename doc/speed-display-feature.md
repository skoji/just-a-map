# Speed Display Feature - 技術文書

## 概要

バイク走行中に現在の速度をリアルタイムで表示する機能を実装しました。GPS速度情報を使用し、km/hまたはmphの単位で表示できます。

## 実装日
2025-07-10

## 関連Issue
[Issue #57](https://github.com/skoji/just-a-map/issues/57) - Add speed display feature

## 実装内容

### 1. SpeedUnit Enum
速度表示の単位を管理する列挙型を作成。

**ファイル**: `Sources/JustAMap/Models/SpeedUnit.swift`

```swift
enum SpeedUnit: String, CaseIterable {
    case kmh = "kmh"
    case mph = "mph"
    
    var symbol: String
    func displayString(for speed: Double) -> String
    static func convertKmhToMph(kmh: Double) -> Double
    static func convertMphToKmh(mph: Double) -> Double
}
```

**機能**:
- km/h ↔ mph 変換
- 速度表示文字列の生成
- 無効な速度値（負数）の処理

### 2. Settings Storage 拡張
速度表示設定の永続化機能を追加。

**ファイル**: `Sources/JustAMap/Services/MapSettingsStorage.swift`

**追加プロパティ**:
- `isSpeedDisplayEnabled: Bool` - 速度表示のON/OFF
- `speedUnit: SpeedUnit` - 速度の単位（デフォルト: km/h）

**追加メソッド**:
- `saveSpeedDisplayEnabled(_:)` / `loadSpeedDisplayEnabled()`
- `saveSpeedUnit(_:)` / `loadSpeedUnit()`

### 3. SettingsViewModel 拡張
設定画面での速度表示制御を追加。

**ファイル**: `Sources/JustAMap/Models/SettingsViewModel.swift`

**追加プロパティ**:
```swift
@Published var isSpeedDisplayEnabled: Bool
@Published var speedUnit: SpeedUnit
```

### 4. SpeedView UI コンポーネント
速度表示用のSwiftUIコンポーネントを作成。

**ファイル**: `Sources/JustAMap/Views/SpeedView.swift`

**特徴**:
- AltitudeViewと同様のUIデザイン
- スピードメーターアイコン使用
- モノスペース フォントで読みやすさを確保
- ローディング状態と無効値の適切な処理

### 5. MapViewModel 拡張
GPS速度情報の追跡機能を追加。

**ファイル**: `Sources/JustAMap/Models/MapViewModel.swift`

**追加機能**:
- `currentSpeed: Double?` - 現在の速度（m/s単位）
- `isSpeedDisplayEnabled` - 速度表示設定の取得
- `speedUnit` - 速度単位設定の取得
- CLLocationDelegate での速度情報更新

### 6. UI統合
地図画面と設定画面への速度表示機能統合。

**MapView**: 
- 住所・高度表示の下に速度表示を追加
- 設定に応じた表示/非表示制御

**SettingsView**:
- 速度表示ON/OFFトグル
- 速度単位選択ピッカー（表示ON時のみ）

### 7. 国際化対応
英語・日本語の多言語化対応。

**追加文字列**:
- `settings.speed_display` - 速度表示
- `settings.speed_unit` - 速度の単位  
- `settings.speed_unit_kmh` - キロメートル毎時 (km/h)
- `settings.speed_unit_mph` - マイル毎時 (mph)

## テスト実装

### TDD アプローチ
プロジェクトのTDD方針に従い、実装前にテストを作成。

### テストファイル
1. **SpeedUnitTests.swift** - SpeedUnit enumの単体テスト
2. **SpeedSettingsTests.swift** - 設定の永続化テスト
3. **SpeedViewTests.swift** - UI コンポーネントテスト
4. **SettingsViewModelTests.swift** - 設定ViewModelテスト（拡張）

### テスト対象
- 単位変換の正確性
- 設定の永続化
- 無効値の適切な処理
- UI状態の管理

## エラーハンドリング

### 無効な速度値
- 負の速度値: "---" 表示
- GPS取得不可: "---" 表示

### 設定のデフォルト値
- 速度表示: OFF（デフォルト）
- 速度単位: km/h（デフォルト）

## UI/UX 考慮事項

### バイク走行中の視認性
- 大きめの文字サイズ（16pt、モノスペース）
- 高コントラストの配色
- シンプルで直感的なアイコン（スピードメーター）

### タッチターゲット
- 設定画面のトグル・ピッカーは60x60pt以上を確保
- グローブ着用時でも操作可能

## パフォーマンス考慮

### バッテリー消費
- 既存のGPS更新頻度制御をそのまま利用
- 追加のバッテリー消費は最小限

### メモリ使用量
- SpeedViewは軽量なコンポーネント
- 設定値はUserDefaultsで管理

## 実装パターン

### Clean Architecture
- ビジネスロジック（SpeedUnit）とUI（SpeedView）の分離
- プロトコルベースの設計（MapSettingsStorageProtocol）

### SwiftUI ベストプラクティス
- @Published プロパティでのリアクティブ更新
- Preview対応
- アクセシビリティ考慮

## 今後の拡張予定

### 音声読み上げ
将来的に音声操作機能と連携し、速度の音声読み上げが可能。

### Apple Watch 連携
Apple Watch での速度表示（将来のIssue #5と連携）。

### 速度警告
制限速度超過時の警告機能（要検討）。

## 関連ファイル

### 新規作成
- `Sources/JustAMap/Models/SpeedUnit.swift`
- `Sources/JustAMap/Views/SpeedView.swift`  
- `Tests/JustAMapTests/SpeedUnitTests.swift`
- `Tests/JustAMapTests/SpeedSettingsTests.swift`
- `Tests/JustAMapTests/SpeedViewTests.swift`

### 変更
- `Sources/JustAMap/Services/MapSettingsStorage.swift`
- `Sources/JustAMap/Models/SettingsViewModel.swift`
- `Sources/JustAMap/Models/MapViewModel.swift`
- `Sources/JustAMap/MapView.swift`
- `Sources/JustAMap/Views/SettingsView.swift`
- `Sources/JustAMap/en.lproj/Localizable.strings`
- `Sources/JustAMap/ja.lproj/Localizable.strings`
- `Tests/JustAMapTests/SettingsViewModelTests.swift`
- `Tests/JustAMapTests/TestDoubles/MockMapSettingsStorage.swift`

## 技術的詳細

### 速度取得方法
CLLocationのspeedプロパティ（m/s単位）を使用し、表示時にkm/hに変換。

### 単位変換式
- km/h = m/s × 3.6
- mph = km/h × 0.621371

### 表示精度
整数値で表示（小数点以下は四捨五入）。

## 設計判断の根拠

### デフォルト設定
- **速度表示OFF**: プライバシー配慮、バッテリー節約
- **km/h単位**: 日本での一般的な使用

### UIパターン
- **AltitudeView踏襲**: 一貫性のあるUI
- **条件付き表示**: 必要時のみ表示でUIの簡潔性を保持

### エラー表示
- **"---" 表示**: 他の無効値表示と統一

## 不具合修正履歴

### Issue #71: 停止時に速度が0にならない問題
**修正日**: 2025-07-11
**PR**: #72

**問題**:
- デバイスが停止してもCoreLocationの`pausesLocationUpdatesAutomatically = true`により位置情報更新が停止
- 最後の速度値がそのまま表示され続ける

**解決策**:
- 3秒間のタイマーを実装し、位置情報更新が止まったら速度を0にリセット
- タイマーは位置情報更新のたびにリセットされる

### Issue #72: 走行中に速度が0になる問題
**修正日**: 2025-07-13

**問題**:
- GPS精度が悪い時、`CLLocation.speed`が-1（無効値）を返す
- Issue #71の修正で無条件に`currentSpeed = location.speed`としていたため、無効値も設定されていた
- SpeedViewで-1は"---"として表示され、実質的に0扱いになる

**解決策**:
- `location.speed >= 0`の場合のみ速度を更新
- 無効な速度値（-1）の場合は前回の有効な値を保持
- 有効な速度値を受信した場合のみタイマーをリセット

**実装詳細**:
```swift
// 速度が有効な場合のみ更新（無効値-1の場合は前の値を保持）
if location.speed >= 0 {
    self.currentSpeed = location.speed
    // 有効な速度値を受信した場合のみタイマーをリセット
    self.resetSpeedTimer()
}
```

これにより、GPS精度が一時的に悪化しても、前の有効な速度値が表示され続けるようになりました。

### Issue #73: 走行中にランダムに速度が0になる問題
**修正日**: 2025-07-13
**PR**: #74

**問題**:
- Issue #71でタイマーベースの速度リセットを実装したが、走行中でも速度が0にリセットされることがある
- 根本原因：iOSの `pausesLocationUpdatesAutomatically = true` 設定により、システムが位置情報更新を一時停止することがある

**解決策**:
- Apple の純正 Location API を使用した実装に変更
- `locationManagerDidPauseLocationUpdates` デリゲートメソッドで停止を検知
- `locationManagerDidResumeLocationUpdates` デリゲートメソッドで再開を検知
- タイマーベースの実装を完全に削除

**実装詳細**:

1. **LocationManagerProtocol に pause/resume デリゲートを追加**:
```swift
protocol LocationManagerDelegate: AnyObject {
    // 既存のデリゲート...
    
    /// 位置情報の更新が一時停止された時
    func locationManagerDidPauseLocationUpdates(_ manager: LocationManagerProtocol)
    
    /// 位置情報の更新が再開された時
    func locationManagerDidResumeLocationUpdates(_ manager: LocationManagerProtocol)
}
```

2. **MapViewModel でのタイマー削除と pause/resume 処理**:
```swift
// タイマー関連のコードを削除
// private var speedResetTask: Task<Void, Never>?
// private let speedResetDelay: UInt64 = 10_000_000_000

// pause/resume の状態管理
private var isLocationPaused = false

func locationManagerDidPauseLocationUpdates(_ manager: LocationManagerProtocol) {
    Task { @MainActor in
        self.isLocationPaused = true
        // 位置情報更新が一時停止したら即座に速度を0にリセット
        self.currentSpeed = 0.0
    }
}

func locationManagerDidResumeLocationUpdates(_ manager: LocationManagerProtocol) {
    Task { @MainActor in
        self.isLocationPaused = false
        // 位置情報更新が再開されたので、次の更新を待つ
    }
}
```

**利点**:
- Apple の公式 API を使用することで、より正確な停止検知が可能
- タイマーベースの実装よりもシンプルで信頼性が高い
- バッテリー効率も向上（不要なタイマー処理がない）
- iOS の位置情報システムと完全に同期した動作

**テスト**:
- MockLocationManager に `simulateLocationUpdatesPaused()` と `simulateLocationUpdatesResumed()` を追加
- MapViewModelTests で pause/resume 時の速度リセット動作をテスト
- タイマーベースのテストは削除