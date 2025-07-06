# Swift Structured Concurrencyの活用

## 概要

just a mapプロジェクトでSwift Structured Concurrencyを活用した非同期処理の実装例を解説します。

## Structured Concurrencyとは

Swift 5.5で導入された構造化された並行処理の仕組みで、以下の特徴があります：

- **構造化**: タスクの親子関係が明確
- **自動キャンセル**: 親タスクがキャンセルされると子タスクも自動的にキャンセル
- **型安全**: コンパイル時にデータ競合を検出

## 実装例

### 1. 基本的な非同期処理

```swift
// GeocodeService.swift
func reverseGeocode(location: CLLocation) async throws -> Address {
    do {
        let placemarks = try await geocoder.reverseGeocodeLocation(location)
        
        guard let placemark = placemarks.first else {
            throw GeocodeError.noResults
        }
        
        // 住所を構築
        let fullAddress = buildFullAddress(from: placemark)
        
        return Address(
            name: placemark.name,
            fullAddress: fullAddress,
            // ...
        )
    } catch {
        if error is GeocodeError {
            throw error
        }
        throw GeocodeError.geocodingFailed
    }
}
```

**ポイント**：
- `async/await`で非同期処理を同期的に記述
- エラーハンドリングが自然な形で実装可能

### 2. タスクのキャンセル処理

```swift
// MapViewModel.swift
private var mapCenterGeocodingTask: Task<Void, Never>?

func updateMapCenter(_ coordinate: CLLocationCoordinate2D) {
    mapCenterCoordinate = coordinate
    
    guard !isFollowingUser else { return }
    
    // 前のタスクをキャンセル
    mapCenterGeocodingTask?.cancel()
    
    // 新しいタスクを開始
    mapCenterGeocodingTask = Task {
        // デバウンス
        try? await Task.sleep(nanoseconds: mapCenterDebounceDelay)
        
        // キャンセルチェック
        guard !Task.isCancelled else { return }
        
        // 住所を取得
        await fetchAddressForMapCenter()
    }
}
```

**キャンセル処理のポイント**：
1. タスクの参照を保持
2. 新しいタスクを開始する前に前のタスクをキャンセル
3. 処理の要所で`Task.isCancelled`をチェック

### 3. @MainActorの活用

```swift
@MainActor
class MapViewModel: ObservableObject {
    @Published var region = MKCoordinateRegion(...)
    @Published var userLocation: CLLocation?
    // ...
}

// LocationManagerDelegate
extension MapViewModel: LocationManagerDelegate {
    nonisolated func locationManager(_ manager: LocationManagerProtocol, didUpdateLocation location: CLLocation) {
        Task { @MainActor in
            self.userLocation = location
            self.updateRegionIfFollowing(location: location)
            // ...
        }
    }
}
```

**@MainActorの利点**：
- UIの更新が自動的にメインスレッドで実行
- データ競合を防ぐ
- `nonisolated`でデリゲートメソッドを分離

### 4. デバウンス処理の実装

```swift
private let mapCenterDebounceDelay: UInt64 = 300_000_000 // 300ms

mapCenterGeocodingTask = Task {
    // デバウンス
    try? await Task.sleep(nanoseconds: mapCenterDebounceDelay)
    
    guard !Task.isCancelled else { return }
    
    // 実際の処理
    await fetchAddressForMapCenter()
}
```

**デバウンスの仕組み**：
1. `Task.sleep`で遅延を実現
2. その間に新しいリクエストが来たらキャンセル
3. 最後のリクエストのみが実行される

### 5. 複数の非同期処理の管理

```swift
// MapViewModel.swift
private var geocodingTask: Task<Void, Never>?        // 現在位置の住所取得
private var mapCenterGeocodingTask: Task<Void, Never>?  // 地図中心の住所取得

func stopLocationTracking() {
    locationManager.stopLocationUpdates()
    geocodingTask?.cancel()
    mapCenterGeocodingTask?.cancel()
}
```

**複数タスクの管理**：
- 異なる目的のタスクを別々に管理
- 必要に応じて個別にキャンセル可能
- アプリのライフサイクルに合わせて一括キャンセル

## ベストプラクティス

### 1. エラーハンドリング

```swift
private func fetchAddressForMapCenter() async {
    isLoadingMapCenterAddress = true
    
    let location = CLLocation(
        latitude: mapCenterCoordinate.latitude,
        longitude: mapCenterCoordinate.longitude
    )
    
    do {
        let address = try await geocodeService.reverseGeocode(location: location)
        
        guard !Task.isCancelled else { return }
        
        self.mapCenterAddress = addressFormatter.formatForDisplay(address)
        self.isLoadingMapCenterAddress = false
    } catch {
        guard !Task.isCancelled else { return }
        
        print("Map center geocoding error: \(error)")
        self.isLoadingMapCenterAddress = false
    }
}
```

**ポイント**：
- エラー時もローディング状態をリセット
- キャンセルされた場合はUIを更新しない

### 2. テストでの非同期処理

```swift
func testFetchAddressForMapCenterWithDebounce() async {
    // Given
    let newCenter = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
    sut.isFollowingUser = false
    
    // When
    sut.updateMapCenter(newCenter)
    
    // Then - 即座には住所取得が開始されない
    XCTAssertFalse(sut.isLoadingMapCenterAddress)
    
    // デバウンス時間待つ
    try? await Task.sleep(nanoseconds: 500_000_000)
    
    // Then - デバウンス後に住所が取得される
    XCTAssertNotNil(sut.mapCenterAddress)
}
```

**テストのポイント**：
- `async`テスト関数で非同期処理をテスト
- `Task.sleep`でタイミングを制御
- 実際の処理時間を考慮した待機時間

### 3. メモリ管理

```swift
// 弱参照を使用しない例（Taskは構造体なのでキャプチャリストは不要）
mapCenterGeocodingTask = Task {
    try? await Task.sleep(nanoseconds: mapCenterDebounceDelay)
    
    guard !Task.isCancelled else { return }
    
    // selfの強参照は問題ない（Taskがキャンセルされれば解放される）
    await fetchAddressForMapCenter()
}
```

## パフォーマンスへの影響

### 1. レスポンシブなUI
- 非同期処理により、UIがブロックされない
- デバウンスで無駄な処理を削減

### 2. 効率的なリソース利用
- 不要になったタスクは即座にキャンセル
- システムリソースの無駄遣いを防ぐ

### 3. バッテリー消費の最適化
- 過度なAPI呼び出しを防止
- 必要最小限の処理のみ実行

## トラブルシューティング

### 1. タスクがキャンセルされない

```swift
// 悪い例
Task {
    while true {
        // Task.isCancelledをチェックしない無限ループ
        await someWork()
    }
}

// 良い例
Task {
    while !Task.isCancelled {
        await someWork()
    }
}
```

### 2. メインスレッドでの重い処理

```swift
// 悪い例
@MainActor
func processHeavyData() async {
    // 重い処理をメインスレッドで実行
    let result = heavyComputation()
}

// 良い例
func processHeavyData() async {
    // バックグラウンドで実行
    let result = await Task.detached {
        return heavyComputation()
    }.value
    
    // 結果のみメインスレッドで更新
    await MainActor.run {
        self.result = result
    }
}
```

## まとめ

Structured Concurrencyを活用することで：

1. **安全な非同期処理**: データ競合やデッドロックを防ぐ
2. **読みやすいコード**: 非同期処理が同期的に記述できる
3. **効率的なリソース管理**: 自動的なキャンセル処理
4. **優れたパフォーマンス**: レスポンシブなUIとバッテリー効率

just a mapプロジェクトでは、これらの特徴を活かして、ユーザーに快適な地図体験を提供しています。