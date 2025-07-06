# 地図中心点の住所表示機能の実装

## 概要

Issue #8で実装した、地図スクロール時に中心点の住所を表示する機能について、技術的な詳細を解説します。

## 機能要件

1. **追従モードの管理**
   - 現在位置を自動追従するモードと、地図を自由に操作するモードの切り替え
   - ユーザーが地図を操作したら自動的に追従モード解除

2. **クロスヘア表示**
   - 追従モード解除時に地図中心に十字マークを表示
   - 視認性の高いデザイン（赤色、白背景）

3. **中心点の住所表示**
   - 地図中心の座標を逆ジオコーディング
   - デバウンス処理で過度なAPI呼び出しを防止

## アーキテクチャ

### 状態管理

```swift
// MapViewModel.swift
@Published var isFollowingUser = true  // 追従モード状態
@Published var mapCenterCoordinate = CLLocationCoordinate2D(...)  // 地図中心座標
@Published var mapCenterAddress: FormattedAddress?  // 中心点の住所
@Published var isLoadingMapCenterAddress = false  // ローディング状態
```

### データフロー

```
ユーザー操作
    ↓
MapView.onMapCameraChange
    ↓
viewModel.updateMapCenter()  // デバウンス処理
    ↓
viewModel.fetchAddressForMapCenter()  // 住所取得
    ↓
AddressView  // 表示更新
```

## 実装の詳細

### 1. 追従モード解除の検知

```swift
// MapView.swift
.onMapCameraChange { context in
    // 地図中心座標を更新
    viewModel.updateMapCenter(context.region.center)
    
    // ユーザーが地図を手動で動かした場合、追従モードを解除
    if viewModel.isFollowingUser {
        if let userLocation = viewModel.userLocation {
            let mapCenter = CLLocation(
                latitude: context.region.center.latitude,
                longitude: context.region.center.longitude
            )
            let distance = userLocation.distance(from: mapCenter)
            if distance > 100 { // 100m以上離れたら追従解除
                viewModel.handleUserMapInteraction()
            }
        }
    }
}
```

**ポイント**：
- `onMapCameraChange`で地図の変更を検知
- 現在位置から100m以上離れたら追従モード解除
- ズームボタン操作時は`isZoomingByButton`フラグで除外

### 2. デバウンス処理

```swift
// MapViewModel.swift
private var mapCenterGeocodingTask: Task<Void, Never>?
private let mapCenterDebounceDelay: UInt64 = 300_000_000 // 300ms

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
```

**デバウンスの仕組み**：
1. 地図移動のたびに前のタスクをキャンセル
2. 300ms待機
3. その間に新しい移動がなければ住所取得開始
4. Structured Concurrencyでタスク管理

### 3. クロスヘア表示

```swift
// CrosshairView.swift
struct CrosshairView: View {
    var body: some View {
        ZStack {
            // 背景の円（視認性向上）
            Circle()
                .fill(Color.white.opacity(0.8))
                .frame(width: 40, height: 40)
                .shadow(radius: 2)
            
            // 十字マーク
            ZStack {
                Rectangle()
                    .fill(Color.red)
                    .frame(width: 30, height: 3)
                
                Rectangle()
                    .fill(Color.red)
                    .frame(width: 3, height: 30)
            }
            
            // 中心の点
            Circle()
                .fill(Color.red)
                .frame(width: 6, height: 6)
        }
    }
}
```

**デザインの工夫**：
- 白い半透明の背景で視認性向上
- 赤色で目立つデザイン
- `allowsHitTesting(false)`でタッチイベントを透過

### 4. 住所表示の切り替え

```swift
// MapView.swift
AddressView(
    formattedAddress: viewModel.isFollowingUser 
        ? viewModel.formattedAddress 
        : viewModel.mapCenterAddress,
    isLoading: viewModel.isFollowingUser 
        ? viewModel.isLoadingAddress 
        : viewModel.isLoadingMapCenterAddress
)
```

**条件分岐**：
- 追従モード時：現在位置の住所
- 追従モード解除時：地図中心の住所

### 5. 現在位置ボタンのフィードバック

```swift
// MapView.swift
Button(action: {
    viewModel.centerOnUserLocation()
    // カメラ位置を更新
}) {
    Image(systemName: viewModel.isFollowingUser ? "location.fill" : "location")
        .font(.title2)
        .foregroundColor(.white)
        .frame(width: 60, height: 60)
        .background(viewModel.isFollowingUser ? Color.blue : Color.gray)
        .clipShape(Circle())
        .shadow(radius: 4)
        .overlay(
            // 追従モード解除時にパルスアニメーション
            Circle()
                .stroke(Color.blue, lineWidth: 2)
                .scaleEffect(viewModel.isFollowingUser ? 1 : 1.3)
                .opacity(viewModel.isFollowingUser ? 0 : 0.6)
                .animation(
                    viewModel.isFollowingUser ? .none : 
                    Animation.easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true),
                    value: viewModel.isFollowingUser
                )
        )
}
```

**視覚的フィードバック**：
- アイコン：`location.fill`（追従中）/ `location`（解除時）
- 背景色：青（追従中）/ グレー（解除時）
- パルスアニメーション：解除時のみ表示

## パフォーマンス最適化

### 1. デバウンス処理
- 地図スクロール中の過度なAPI呼び出しを防止
- 300msの遅延で適切なバランスを実現

### 2. タスクキャンセル
- Structured Concurrencyで適切なタスク管理
- 不要になったタスクは即座にキャンセル

### 3. 条件付き処理
- 追従モード時は中心点の住所取得をスキップ
- 必要な時のみ逆ジオコーディングを実行

## テスト戦略

### 1. 単体テスト（MapViewModelTests）
- 追従モード状態管理
- デバウンス処理の動作確認
- 地図中心座標の更新

### 2. 統合テスト（今後の課題）
- MapViewとMapViewModelの連携
- 実際の地図操作による動作確認

## 今後の改善案

1. **オフライン対応**
   - 住所キャッシュの実装
   - オフライン時のフォールバック

2. **パフォーマンス向上**
   - 住所取得結果のキャッシュ
   - より効率的な座標比較アルゴリズム

3. **UI/UXの改善**
   - クロスヘアのカスタマイズ設定
   - 住所表示のアニメーション

## まとめ

この実装では、SwiftUIの`onMapCameraChange`とStructured Concurrencyを活用して、効率的な地図中心点の住所表示を実現しました。デバウンス処理により、パフォーマンスとユーザビリティのバランスを取ることができました。