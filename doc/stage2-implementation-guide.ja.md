# 段階2実装ガイド：住所表示とスリープ防止

このドキュメントでは、段階2で実装した住所表示とスリープ防止機能について解説します。

## 目次

1. [実装概要](#実装概要)
2. [TDDによる開発プロセス](#tddによる開発プロセス)
3. [逆ジオコーディングサービス](#逆ジオコーディングサービス)
4. [住所フォーマッター](#住所フォーマッター)
5. [スリープ防止機能](#スリープ防止機能)
6. [UI統合](#ui統合)
7. [学んだこと](#学んだこと)

## 実装概要

段階2では以下の機能を実装しました：

1. **住所表示機能**
   - 現在位置から住所を取得（逆ジオコーディング）
   - 日本の住所フォーマットに対応
   - 場所名（東京駅など）を優先表示

2. **スリープ防止機能**
   - バイク走行中に画面が消えない
   - アプリのライフサイクルに応じた制御

## TDDによる開発プロセス

### 1. GeocodeServiceの開発

**Red（失敗するテストを書く）:**
```swift
func testReverseGeocodeSuccess() async throws {
    // Given
    let location = CLLocation(latitude: 35.6762, longitude: 139.6503)
    let expectedPlacemark = MockPlacemark(name: "東京駅", ...)
    mockGeocoder.placemarkToReturn = expectedPlacemark
    
    // When
    let address = try await sut.reverseGeocode(location: location)
    
    // Then
    XCTAssertEqual(address.name, "東京駅")
}
```

**Green（テストを通す最小限の実装）:**
```swift
func reverseGeocode(location: CLLocation) async throws -> Address {
    let placemarks = try await geocoder.reverseGeocodeLocation(location)
    guard let placemark = placemarks.first else {
        throw GeocodeError.noResults
    }
    return Address(name: placemark.name, ...)
}
```

## 逆ジオコーディングサービス

### プロトコルによる抽象化

```swift
protocol GeocoderProtocol {
    func reverseGeocodeLocation(_ location: CLLocation) async throws -> [CLPlacemark]
}

extension CLGeocoder: GeocoderProtocol {}
```

**なぜプロトコルを使うのか？**
- CLGeocoderをモック化してテスト可能に
- ネットワーク接続なしでテスト実行
- エラーケースも簡単にテスト

### async/awaitの活用

```swift
func reverseGeocode(location: CLLocation) async throws -> Address {
    do {
        let placemarks = try await geocoder.reverseGeocodeLocation(location)
        // ...
    } catch {
        throw GeocodeError.geocodingFailed
    }
}
```

**従来のコールバック方式との違い：**
- コードが読みやすい（同期的な見た目）
- エラーハンドリングが統一的
- キャンセル処理が簡単

## 住所フォーマッター

### 日本の住所表示への対応

```swift
private func buildFullAddress(from placemark: CLPlacemark) -> String {
    var components: [String] = []
    
    // 日本の住所フォーマット: 都道府県 > 市区町村 > 番地
    if let administrativeArea = placemark.administrativeArea {
        components.append(administrativeArea)
    }
    if let locality = placemark.locality {
        components.append(locality)
    }
    // ...
    
    return components.joined()
}
```

### 表示の優先順位

```swift
private func determinePrimaryText(from address: Address) -> String {
    // 優先順位: 1. 場所の名前, 2. 市区町村, 3. デフォルト
    if let name = address.name, !name.isEmpty {
        return name  // "東京駅"
    }
    if let locality = address.locality, !locality.isEmpty {
        return locality  // "千代田区"
    }
    return "現在地"
}
```

## スリープ防止機能

### UIApplicationのラップ

```swift
protocol UIApplicationProtocol {
    var isIdleTimerDisabled: Bool { get set }
}

extension UIApplication: UIApplicationProtocol {}
```

**テスタビリティの向上：**
- UIApplicationをモック化可能
- 実際のアプリケーション状態に依存しない

### ライフサイクル管理

```swift
func handleAppDidEnterBackground() {
    // バックグラウンドでは必ずスリープ防止を解除
    application.isIdleTimerDisabled = false
}

func handleAppWillEnterForeground() {
    // 前の状態を復元
    application.isIdleTimerDisabled = shouldKeepScreenOn
}
```

**重要なポイント：**
- バックグラウンドでスリープ防止を維持するとバッテリーを無駄に消費
- フォアグラウンド復帰時に状態を復元

## UI統合

### AddressView

```swift
struct AddressView: View {
    let formattedAddress: FormattedAddress?
    let isLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if isLoading && formattedAddress == nil {
                // 初回ローディング
                HStack {
                    ProgressView()
                    Text("住所を取得中...")
                }
            } else if let address = formattedAddress {
                // 住所表示
                Text(address.primaryText)
                    .font(.headline)
                Text(address.secondaryText)
                    .font(.subheadline)
            }
        }
    }
}
```

### MapViewModelの統合

```swift
private func fetchAddress(for location: CLLocation) {
    geocodingTask?.cancel()  // 前のタスクをキャンセル
    
    geocodingTask = Task {
        do {
            let address = try await geocodeService.reverseGeocode(location: location)
            guard !Task.isCancelled else { return }
            self.formattedAddress = addressFormatter.formatForDisplay(address)
        } catch {
            // エラーでも前の住所を保持
        }
    }
}
```

**非同期処理の考慮点：**
- 連続した位置更新で前のリクエストをキャンセル
- タスクキャンセル時は UI を更新しない
- エラー時は前の住所を保持（UX向上）

### NotificationCenterの活用

```swift
.onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
    viewModel.handleAppDidEnterBackground()
}
```

**SwiftUIでのライフサイクル管理：**
- ScenePhaseも使えるが、NotificationCenterの方が確実
- 複数のビューで同じイベントを購読可能

## 学んだこと

### 1. TDDの効果
- モック化により外部依存なしでテスト可能
- リファクタリング時の安心感
- インターフェース設計が明確に

### 2. async/awaitのメリット
- 非同期処理が読みやすい
- エラーハンドリングが統一的
- Taskによるキャンセル処理

### 3. プロトコル指向の設計
- 依存性の注入が容易
- テスタビリティの向上
- 実装の詳細を隠蔽

### 4. UXの配慮
- ローディング表示で待機時間を明確に
- エラー時も前の情報を保持
- バッテリー消費への配慮

## まとめ

段階2では、TDDを徹底して以下を実装しました：

1. **逆ジオコーディングサービス**
   - プロトコルによる抽象化
   - async/awaitによる非同期処理

2. **住所フォーマッター**
   - 日本の住所形式に対応
   - 見やすい表示の工夫

3. **スリープ防止機能**
   - ライフサイクルに応じた制御
   - バッテリー消費への配慮

4. **UI統合**
   - 非同期処理の適切な管理
   - ユーザー体験の向上

これらの実装により、バイク走行中でも使いやすい地図アプリケーションがさらに改善されました。