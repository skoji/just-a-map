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