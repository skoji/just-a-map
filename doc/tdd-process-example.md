# テスト駆動開発（TDD）の実践例

## 概要

Issue #8（地図中心点の住所表示機能）の実装で実践したTDDプロセスを、具体的なコード例と共に解説します。

## TDDサイクル

```
1. Red   - 失敗するテストを書く
2. Green - テストを通す最小限の実装
3. Refactor - コードを改善（テストは通ったまま）
```

## 実装例1: 追従モード状態管理

### 1. Red - 失敗するテストを書く

```swift
// MapViewModelTests.swift
func testCenterOnUserLocationEnablesFollowingMode() {
    // Given
    let location = CLLocation(latitude: 35.6762, longitude: 139.6503)
    sut.userLocation = location
    sut.isFollowingUser = false
    
    // When
    sut.centerOnUserLocation()
    
    // Then
    XCTAssertTrue(sut.isFollowingUser, "centerOnUserLocationを呼ぶと追従モードが有効になるべき")
}
```

**この時点でのエラー**：
- `centerOnUserLocation`メソッドが追従モードを有効化していない

### 2. Green - テストを通す最小限の実装

```swift
// MapViewModel.swift
func centerOnUserLocation() {
    guard let location = userLocation else { return }
    
    // 追従モードを有効化
    isFollowingUser = true  // この行を追加
    
    withAnimation(.easeInOut(duration: 0.3)) {
        region = MKCoordinateRegion(
            center: location.coordinate,
            span: region.span
        )
    }
}
```

### 3. Refactor - 必要に応じて改善

この例では、実装がシンプルなのでリファクタリングは不要でした。

## 実装例2: デバウンス処理付き住所取得

### 1. Red - 失敗するテストを書く

```swift
func testFetchAddressForMapCenterWithDebounce() async {
    // Given
    let newCenter = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
    sut.isFollowingUser = false
    
    // When - 地図中心を更新
    sut.updateMapCenter(newCenter)
    
    // Then - 即座には住所取得が開始されない
    XCTAssertFalse(sut.isLoadingMapCenterAddress)
    XCTAssertNil(sut.mapCenterAddress)
    
    // デバウンス時間（300ms）待つ
    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
    
    // Then - デバウンス後に住所が取得される
    XCTAssertNotNil(sut.mapCenterAddress)
    XCTAssertFalse(sut.isLoadingMapCenterAddress)
}
```

**この時点でのエラー**：
- `updateMapCenter`メソッドが存在しない
- `isLoadingMapCenterAddress`プロパティが存在しない
- `mapCenterAddress`プロパティが存在しない

### 2. Green - テストを通す実装

まず、必要なプロパティを追加：

```swift
// MapViewModel.swift
@Published var mapCenterCoordinate = CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503)
@Published var mapCenterAddress: FormattedAddress?
@Published var isLoadingMapCenterAddress = false

private var mapCenterGeocodingTask: Task<Void, Never>?
private let mapCenterDebounceDelay: UInt64 = 300_000_000 // 300ms
```

次に、メソッドを実装：

```swift
func updateMapCenter(_ coordinate: CLLocationCoordinate2D) {
    mapCenterCoordinate = coordinate
    
    guard !isFollowingUser else { return }
    
    // 前のタスクをキャンセル
    mapCenterGeocodingTask?.cancel()
    
    // 新しいタスクを開始
    mapCenterGeocodingTask = Task {
        // デバウンス
        try? await Task.sleep(nanoseconds: mapCenterDebounceDelay)
        
        guard !Task.isCancelled else { return }
        
        // 住所を取得
        await fetchAddressForMapCenter()
    }
}

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

### 3. Refactor - タスク管理の改善

```swift
// stopLocationTracking()メソッドに追加
func stopLocationTracking() {
    locationManager.stopLocationUpdates()
    geocodingTask?.cancel()
    mapCenterGeocodingTask?.cancel()  // 追加：地図中心のタスクもキャンセル
}
```

## 実装例3: 連続的な更新のキャンセル

### 1. Red - 失敗するテストを書く

```swift
func testRapidMapCenterUpdatesCancelPreviousFetch() async {
    // Given
    let center1 = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
    let center2 = CLLocationCoordinate2D(latitude: 35.6820, longitude: 139.7680)
    let center3 = CLLocationCoordinate2D(latitude: 35.6830, longitude: 139.7690)
    sut.isFollowingUser = false
    
    // When - 連続して地図中心を更新
    sut.updateMapCenter(center1)
    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
    sut.updateMapCenter(center2)
    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
    sut.updateMapCenter(center3)
    
    // Then - 最後の更新のみが処理される
    try? await Task.sleep(nanoseconds: 400_000_000) // 0.4秒
    XCTAssertEqual(sut.mapCenterCoordinate.latitude, center3.latitude, accuracy: 0.0001)
    XCTAssertEqual(sut.mapCenterCoordinate.longitude, center3.longitude, accuracy: 0.0001)
}
```

このテストは、既に実装したデバウンス処理により自動的にパスしました。これは良い設計の証拠です。

## TDDの利点（実例から）

### 1. 設計の改善
- テストを先に書くことで、APIの使いやすさを考慮
- 例：`updateMapCenter`メソッドの引数が自然に決まった

### 2. リグレッション防止
- 全てのテストが通ることで、既存機能が壊れていないことを確認
- 例：追従モード時の位置更新が正常に動作し続けることを保証

### 3. ドキュメント化
- テストコードが仕様書として機能
- 例：デバウンス時間が300msであることが明確

### 4. リファクタリングの安全性
- テストがあることで、安心してコードを改善可能
- 例：タスク管理の改善時もテストで動作を保証

## モックオブジェクトの活用

```swift
// MockGeocodeService.swift
class MockGeocodeService: GeocodeServiceProtocol {
    var reverseGeocodeResult: Result<Address, Error> = .success(Address(
        name: "東京駅",
        fullAddress: "東京都千代田区丸の内１丁目９−１",
        postalCode: "100-0005",
        locality: "千代田区",
        subAdministrativeArea: nil,
        administrativeArea: "東京都",
        country: "日本"
    ))
    
    func reverseGeocode(location: CLLocation) async throws -> Address {
        switch reverseGeocodeResult {
        case .success(let address):
            return address
        case .failure(let error):
            throw error
        }
    }
}
```

**モックの利点**：
- 外部APIに依存しない高速なテスト
- エラーケースのテストが容易
- 予測可能な結果でテストの安定性向上

## 学んだこと

### 1. 非同期処理のテスト
- `async/await`を使用したテストの書き方
- `Task.sleep`でタイミングを制御

### 2. SwiftUIとの統合
- ViewModelのテストに集中
- UIテストは最小限に（今回は手動テストで補完）

### 3. 段階的な実装
- 小さな単位でRed-Green-Refactorサイクルを回す
- 各段階でコミット

## まとめ

TDDを実践することで：
- バグの少ない、信頼性の高いコードを実装
- 設計が自然に改善される
- 将来の変更に対する安全性が確保される

特に、デバウンス処理のような複雑な非同期処理では、TDDのアプローチが非常に有効であることが実証されました。