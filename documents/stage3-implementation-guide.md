# 段階3 実装ガイド - 地図コントロールと表示モード切り替え

## 概要
段階3では、just a mapアプリに直感的な地図操作機能を追加しました。バイクのハンドルマウントでの使用を考慮し、大きなタップターゲットと分かりやすいUIを実装しています。

## 実装した機能

### 1. ズームコントロール
- **ズームイン/アウトボタン**: 虫眼鏡アイコンで表示される60x60ポイントの大きなボタン
- **ズームレベルの保持**: ピンチ操作やボタン操作でのズーム変更が、地図移動後も保持される
- **ズーム範囲制限**: 最小0.0005度、最大180度の範囲で制限
- **スムーズなアニメーション**: withAnimationによる自然な拡大縮小

### 2. 地図表示モード切り替え
- **3つの表示モード**:
  - 標準（通常の地図）
  - ハイブリッド（航空写真+地図情報）
  - 航空写真のみ
- **ワンタップ切り替え**: 地図アイコンをタップするたびに循環
- **視覚的フィードバック**: 現在のモードに応じてアイコンが変化

### 3. North Up / Heading Up 切り替え準備
- **切り替えボタン**: コンパスアイコンで表示
- **状態管理**: 将来のヘディング情報に対応するための基盤を実装
- **アイコンの変化**: North UpとHeading Upで異なるアイコン表示

### 4. 設定の永続化
- **UserDefaultsによる保存**:
  - 現在の地図スタイル
  - North Up/Heading Upの設定
  - ズームレベル
- **アプリ再起動時の復元**: 前回の設定が自動的に適用される

## 実装の詳細

### MapControlsViewModel
地図コントロールのビジネスロジックを管理する新しいViewModelを作成しました。

```swift
@MainActor
class MapControlsViewModel: ObservableObject {
    @Published var currentMapStyle: MapStyle = .standard
    @Published var isNorthUp: Bool = true
    
    // ズーム計算
    func calculateZoomIn(from currentSpan: MKCoordinateSpan) -> MKCoordinateSpan
    func calculateZoomOut(from currentSpan: MKCoordinateSpan) -> MKCoordinateSpan
    
    // スタイル切り替え
    func toggleMapStyle()
    func toggleMapOrientation()
}
```

### MapControlsView
地図コントロールのUIコンポーネントです。

```swift
struct MapControlsView: View {
    @ObservedObject var mapViewModel: MapViewModel
    @ObservedObject var controlsViewModel: MapControlsViewModel
    @Binding var mapPosition: MapCameraPosition
    
    var body: some View {
        VStack(spacing: 16) {
            // ズームコントロール
            VStack(spacing: 8) {
                ControlButton(icon: "plus.magnifyingglass", action: { zoomIn() })
                ControlButton(icon: "minus.magnifyingglass", action: { zoomOut() })
            }
            
            Divider()
            
            // 地図スタイル切り替え
            ControlButton(icon: mapStyleIcon, action: { controlsViewModel.toggleMapStyle() })
            
            // North Up / Heading Up 切り替え
            ControlButton(icon: orientationIcon, action: { controlsViewModel.toggleMapOrientation() })
        }
    }
}
```

### MapSettingsStorage
設定の永続化を管理するサービスクラスです。

```swift
protocol MapSettingsStorageProtocol {
    func saveMapStyle(_ style: MapStyle)
    func loadMapStyle() -> MapStyle
    func saveMapOrientation(isNorthUp: Bool)
    func loadMapOrientation() -> Bool
    func saveZoomLevel(span: MKCoordinateSpan?)
    func loadZoomLevel() -> MKCoordinateSpan?
}
```

### ズームレベルの追跡と保持
MapViewModelに`currentSpan`プロパティを追加し、以下の場面で更新：
- onMapCameraChangeでユーザーのピンチ操作を追跡
- ズームボタンでの変更を反映
- 現在地に戻る際も現在のズームレベルを維持

## iOS開発の学習ポイント

### 1. @ViewBuilderの活用
SwiftUIの地図スタイル切り替えで、複数の条件分岐を使った実装：

```swift
Group {
    switch viewModel.mapControlsViewModel.currentMapStyle {
    case .standard:
        Map(position: $mapPosition).mapStyle(.standard)
    case .hybrid:
        Map(position: $mapPosition).mapStyle(.hybrid)
    case .imagery:
        Map(position: $mapPosition).mapStyle(.imagery)
    }
}
```

### 2. MapCameraPositionの扱い
iOS 17の新しいMapKit APIでは、`MapCameraPosition`を使用して地図の位置を管理：

```swift
@State private var mapPosition: MapCameraPosition = .region(
    MKCoordinateRegion(center: location, span: span)
)
```

### 3. パターンマッチングの注意点
Swiftのパターンマッチングで、以下のような構文エラーに注意：

```swift
// ❌ エラー
if case .region(let region) = mapPosition { }

// ✅ 正しい
switch mapPosition {
case let .region(region):
    // 処理
default:
    break
}
```

## テスト駆動開発（TDD）の実践

### 1. MapControlsViewModelTests
ズーム計算、スタイル切り替え、向き切り替えのロジックをテスト：

```swift
func testZoomInLimit() {
    let span = MKCoordinateSpan(latitudeDelta: 0.0001, longitudeDelta: 0.0001)
    let newSpan = sut.calculateZoomIn(from: span)
    XCTAssertEqual(newSpan.latitudeDelta, sut.minimumZoomSpan.latitudeDelta)
}
```

### 2. MapSettingsStorageTests
設定の保存と読み込みをモックを使用してテスト：

```swift
func testSaveMapStyle() {
    sut.saveMapStyle(.hybrid)
    XCTAssertEqual(mockUserDefaults.storage["mapStyle"] as? String, "hybrid")
}
```

### 3. @MainActorの考慮
UIに関連するクラスのテストでは、`@MainActor`アノテーションが必要：

```swift
@MainActor
final class MapControlsViewModelTests: XCTestCase {
    // テストコード
}
```

## 今後の拡張予定

### Heading Up機能の実装
現在はボタンとフラグのみ実装。今後の実装に必要な要素：
- CLLocationManagerDelegateでheading情報を取得
- MapCameraPositionにrotation角度を適用
- 磁北と真北の選択オプション

### 音声コマンド対応
将来的な音声操作のための基盤：
- 各操作メソッドが独立している設計
- 音声認識からの呼び出しが容易

## まとめ
段階3では、バイクでの使用を考慮した直感的な地図コントロールを実装しました。大きなタップターゲット、視覚的なフィードバック、設定の永続化により、実用的な地図アプリとしての基本機能が完成しました。

TDDアプローチにより、各機能が確実に動作することを保証しながら、段階的に機能を追加することができました。