# 高度表示機能の実装

## 概要

JustAMapの高度表示機能は、リアルタイムで現在の高度を地図上に表示する機能です。バイク走行中に標高を確認できるよう、視認性と操作性を重視して設計されています。

## 主要機能

- **リアルタイム高度表示**: GPS位置情報から高度を取得し、地図上に表示
- **単位切り替え**: メートル(m)とフィート(ft)の相互変換
- **表示切り替え**: 設定画面から高度表示のON/OFF切り替え
- **エラーハンドリング**: 無効なGPSデータの適切な処理
- **多言語対応**: 日本語・英語の完全対応

## アーキテクチャ

### 全体構成

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   AltitudeView  │    │   MapViewModel  │    │ LocationManager │
│   (UI Layer)    │◄───┤ (Business Logic)│◄───┤  (Data Source)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                        │                        │
         │                        │                        │
         ▼                        ▼                        ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   AltitudeUnit  │    │SettingsViewModel│    │MapSettingsStorage│
│   (Model)       │    │  (Settings)     │    │  (Persistence)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### 責任分離

- **AltitudeUnit**: 単位変換とフォーマット処理
- **AltitudeView**: UI表示とユーザーインターフェース
- **MapViewModel**: 位置情報の管理と状態管理
- **SettingsViewModel**: 設定の管理
- **MapSettingsStorage**: データの永続化

## 主要コンポーネント

### 1. AltitudeUnit（Models/AltitudeUnit.swift）

高度の単位変換を担当するenumです：

```swift
enum AltitudeUnit: String, CaseIterable {
    case meters = "meters"
    case feet = "feet"
    
    var symbol: String {
        switch self {
        case .meters: return "m"
        case .feet: return "ft"
        }
    }
    
    func displayString(for altitude: Double) -> String {
        guard altitude >= 0 else { return "---" }
        
        switch self {
        case .meters:
            return "\(Int(altitude.rounded()))\(symbol)"
        case .feet:
            let feetValue = Self.convertToFeet(meters: altitude)
            return "\(Int(feetValue.rounded()))\(symbol)"
        }
    }
}
```

**設計上の特徴：**
- 変換係数: 1メートル = 3.28084フィート
- 負の値は"---"で表示（無効なGPSデータを示す）
- 表示は整数値に丸め込み（小数点以下は非表示）

### 2. AltitudeView（Views/AltitudeView.swift）

高度表示のUI コンポーネントです：

```swift
struct AltitudeView: View {
    private let altitude: Double?
    private let verticalAccuracy: Double?
    private let unit: AltitudeUnit
    private let isLoading: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "mountain.2.fill")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.secondary)
            
            Text(displayText)
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .foregroundColor(isLoading ? .secondary : .primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(radius: 2)
        )
        .padding(.horizontal, 16)
    }
}
```

**UI設計の特徴：**
- **アイコン**: 山のアイコン（mountain.2.fill）で高度表示を視覚的に示す
- **フォント**: 等幅フォント（monospaced）で数値の読みやすさを向上
- **サイズ**: 16pt（バイク走行中でも読みやすい）
- **レイアウト**: AddressViewと同じ左側パディング構造（52pt）で整列
- **背景**: 白い背景に軽い影で視認性を確保

### 3. MapViewModel統合（Models/MapViewModel.swift）

位置情報の管理と高度データの処理：

```swift
@MainActor
class MapViewModel: ObservableObject {
    @Published var currentAltitude: Double?
    @Published var currentVerticalAccuracy: Double?
    
    /// 高度表示が有効かどうか
    var isAltitudeDisplayEnabled: Bool {
        return settingsStorage.isAltitudeDisplayEnabled
    }
    
    /// 高度の単位
    var altitudeUnit: AltitudeUnit {
        return settingsStorage.altitudeUnit
    }
    
    /// 高度の表示文字列を取得
    func getAltitudeDisplayString(altitude: Double, verticalAccuracy: Double, unit: AltitudeUnit) -> String {
        guard verticalAccuracy >= 0 else {
            return "---" // 無効な精度の場合
        }
        return unit.displayString(for: altitude)
    }
}
```

**LocationManagerDelegate 統合：**

```swift
extension MapViewModel: LocationManagerDelegate {
    nonisolated func locationManager(_ manager: LocationManagerProtocol, didUpdateLocation location: CLLocation) {
        Task { @MainActor in
            self.currentAltitude = location.altitude
            self.currentVerticalAccuracy = location.verticalAccuracy
            // 他の位置情報処理...
        }
    }
}
```

### 4. 設定画面統合（Views/SettingsView.swift）

設定画面での高度表示設定：

```swift
Section("settings.display_settings".localized) {
    // 高度表示設定
    Toggle("settings.altitude_display".localized, isOn: $viewModel.isAltitudeDisplayEnabled)
    
    // 高度単位設定（高度表示がONの場合のみ表示）
    if viewModel.isAltitudeDisplayEnabled {
        Picker("settings.altitude_unit".localized, selection: $viewModel.altitudeUnit) {
            Text("settings.altitude_unit_meters".localized).tag(AltitudeUnit.meters)
            Text("settings.altitude_unit_feet".localized).tag(AltitudeUnit.feet)
        }
    }
}
```

### 5. データ永続化（Services/MapSettingsStorage.swift）

設定の永続化処理：

```swift
protocol MapSettingsStorageProtocol {
    var isAltitudeDisplayEnabled: Bool { get set }
    var altitudeUnit: AltitudeUnit { get set }
    
    func saveAltitudeDisplayEnabled(_ enabled: Bool)
    func loadAltitudeDisplayEnabled() -> Bool
    func saveAltitudeUnit(_ unit: AltitudeUnit)
    func loadAltitudeUnit() -> AltitudeUnit
}
```

**UserDefaultsキー:**
- `isAltitudeDisplayEnabled`: 高度表示の有効/無効
- `altitudeUnit`: 高度の単位（"meters" / "feet"）

## データフロー

```
CLLocationManager → MapViewModel → AltitudeView
                         ↓
                   MapSettingsStorage
                         ↓
                   UserDefaults
```

1. **位置情報取得**: CLLocationManagerが位置情報を取得
2. **データ処理**: MapViewModelがaltitudeとverticalAccuracyを抽出
3. **設定確認**: MapSettingsStorageから表示設定と単位設定を取得
4. **UI更新**: AltitudeViewが設定に基づいて表示を更新
5. **永続化**: 設定変更時にUserDefaultsに保存

## エラーハンドリング

### 無効なGPSデータの処理

```swift
private var displayText: String {
    if isLoading {
        return "---"
    }
    
    guard let altitude = altitude,
          let accuracy = verticalAccuracy,
          accuracy >= 0 else {
        return "---" // 無効な高度データの場合
    }
    
    return unit.displayString(for: altitude)
}
```

**エラーケース:**
- GPS信号が取得できない場合: "---"表示
- 垂直精度が負の値の場合: "---"表示
- 高度データが存在しない場合: "---"表示

## 多言語対応

### ローカライゼーションキー

**日本語（ja.lproj/Localizable.strings）:**
```
"settings.altitude_display" = "高度表示";
"settings.altitude_unit" = "高度の単位";
"settings.altitude_unit_meters" = "メートル (m)";
"settings.altitude_unit_feet" = "フィート (ft)";
```

**英語（en.lproj/Localizable.strings）:**
```
"settings.altitude_display" = "Show Altitude";
"settings.altitude_unit" = "Altitude Unit";
"settings.altitude_unit_meters" = "Meters (m)";
"settings.altitude_unit_feet" = "Feet (ft)";
```

## テスト戦略

### TDDアプローチ

1. **Red**: 失敗するテストを先に記述
2. **Green**: テストを通す最小実装
3. **Refactor**: リファクタリングによる改善

### テストファイル構成

```
Tests/JustAMapTests/
├── AltitudeUnitTests.swift           # 単位変換テスト
├── AltitudeViewTests.swift           # UI コンポーネントテスト
├── MapViewModelAltitudeTests.swift   # ViewModelテスト
├── AltitudeIntegrationTests.swift    # 統合テスト
├── AltitudeSettingsTests.swift       # 設定テスト
└── AltitudeSettingsViewModelTests.swift # 設定ViewModelテスト
```

### 主要テストケース

#### 1. AltitudeUnitTests.swift（単位変換）

```swift
func testMetersToFeetConversion() {
    // Given
    let metersValue = 100.0
    
    // When
    let feetValue = AltitudeUnit.convertToFeet(meters: metersValue)
    
    // Then
    XCTAssertEqual(feetValue, 328.0, accuracy: 1.0)
}

func testDisplayStringForInvalidAltitude() {
    // Given
    let invalidAltitude = -50.0
    
    // When
    let result = AltitudeUnit.meters.displayString(for: invalidAltitude)
    
    // Then
    XCTAssertEqual(result, "---")
}
```

#### 2. AltitudeViewTests.swift（UI テスト）

```swift
func testAltitudeViewDisplaysCorrectText() {
    // Given
    let altitude = 123.0
    let verticalAccuracy = 5.0
    let unit = AltitudeUnit.meters
    
    // When
    let view = AltitudeView(
        altitude: altitude,
        verticalAccuracy: verticalAccuracy,
        unit: unit
    )
    
    // Then
    // SwiftUI Testing frameworkを使用してテスト
}
```

#### 3. MapViewModelAltitudeTests.swift（統合テスト）

```swift
@MainActor
class MapViewModelAltitudeTests: XCTestCase {
    func testLocationUpdateSetsAltitudeData() async throws {
        // Given
        let mockLocationManager = MockLocationManager()
        let mapViewModel = MapViewModel(locationManager: mockLocationManager)
        let location = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 35.0, longitude: 139.0),
            altitude: 100.0,
            horizontalAccuracy: 10.0,
            verticalAccuracy: 5.0,
            timestamp: Date()
        )
        
        // When
        mockLocationManager.simulateLocationUpdate(location)
        await Task.yield() // 非同期処理の完了を待つ
        
        // Then
        XCTAssertEqual(mapViewModel.currentAltitude, 100.0)
        XCTAssertEqual(mapViewModel.currentVerticalAccuracy, 5.0)
    }
}
```

### モックオブジェクト

#### MockLocationManager

```swift
class MockLocationManager: LocationManagerProtocol {
    weak var delegate: LocationManagerDelegate?
    
    func simulateLocationUpdate(_ location: CLLocation) {
        delegate?.locationManager(self, didUpdateLocation: location)
    }
}
```

#### MockUserDefaults

```swift
class MockUserDefaults: UserDefaultsProtocol {
    private var storage: [String: Any] = [:]
    
    func set(_ value: Any?, forKey defaultName: String) {
        if let value = value {
            storage[defaultName] = value
        } else {
            storage.removeValue(forKey: defaultName)
        }
    }
    
    func object(forKey defaultName: String) -> Any? {
        return storage[defaultName]
    }
}
```

## UI/UX考慮事項

### バイク走行中の使用を想定した設計

1. **視認性**
   - 16ptのフォントサイズ（小さすぎず大きすぎず）
   - 等幅フォント（数値の読みやすさ）
   - 高コントラスト（黒文字/白背景）

2. **レイアウト**
   - AddressViewとの整列（52pt左パディング）
   - 十分な余白（タッチしやすさ）
   - 山のアイコンで直感的な識別

3. **エラー状態の表示**
   - "---"表示で無効状態を明確に表現
   - ローディング状態との区別

### アクセシビリティ対応

- VoiceOver対応（アイコン + テキストの組み合わせ）
- 色のみに依存しない情報表示
- 十分なコントラスト比の確保

## パフォーマンス考慮

### メモリ効率
- 軽量なenum（AltitudeUnit）
- 必要最小限のPublished プロパティ
- 適切なSwiftUIライフサイクル管理

### 処理効率
- 整数への丸め処理による計算負荷軽減
- 条件分岐による不要な計算の回避
- 非同期処理でのメインスレッドブロック回避

## 今後の拡張可能性

### 追加できる機能
1. **高度精度インジケーター**: 垂直精度に基づく信頼度表示
2. **高度履歴**: 移動中の高度変化をグラフで表示
3. **高度アラート**: 特定の高度に達した際の通知
4. **単位の自動切り替え**: 地域設定に基づく単位の自動選択

### 拡張時の考慮事項
- 既存の設定システムとの統合
- TDDによる継続的な品質保証
- 多言語対応の拡張
- パフォーマンスへの影響評価

## まとめ

高度表示機能は、以下の設計原則に基づいて実装されています：

1. **単一責任の原則**: 各コンポーネントが明確な責任を持つ
2. **依存性の逆転**: プロトコルによる疎結合設計
3. **テスト駆動開発**: 品質保証とリファクタリング安全性
4. **ユーザー体験重視**: バイク走行中の使用を想定した設計
5. **国際化対応**: 多言語環境での使用を考慮

この実装により、堅牢で保守性の高い高度表示機能が提供され、ユーザーは安全かつ快適にバイク走行中の高度情報を確認できます。