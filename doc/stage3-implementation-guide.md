# 段階3 実装ガイド - 地図コントロールと表示モード切り替え

## 概要
段階3では、just a mapアプリに直感的な地図操作機能を追加しました。バイクのハンドルマウントでの使用を考慮し、大きなタップターゲットと分かりやすいUIを実装しています。

## 実装した機能

### 1. ズームコントロール
- **ズームイン/アウトボタン**: 虫眼鏡アイコンで表示される60x60ポイントの大きなボタン
- **12段階の離散的ズームレベル**: 建物レベル（200m）から地球レベル（1,000,000m）まで
- **高度ベースの実装**: MapKitの内部変換に影響されない安定した動作
- **ズーム制限インジケーター**: ズームの限界に達した時はボタンがグレーアウト
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
  - ズームレベル（インデックスとして保存）
- **アプリ再起動時の復元**: 前回の設定が自動的に適用される

## 実装の詳細

### MapControlsViewModel
地図コントロールのビジネスロジックを管理する新しいViewModelを作成しました。

```swift
@MainActor
class MapControlsViewModel: ObservableObject {
    @Published var currentMapStyle: MapStyle = .standard
    @Published var isNorthUp: Bool = true
    @Published private(set) var currentZoomIndex: Int = 5
    
    // 高度ベースのズームレベル（12段階）
    private let predefinedAltitudes: [Double] = [
        200,      // 建物レベル
        500,      // 街区レベル
        1000,     // 近隣レベル
        2000,     // 地区レベル
        5000,     // 市区レベル
        10000,    // 市レベル
        20000,    // 都市圏レベル
        50000,    // 県レベル
        100000,   // 地方レベル
        200000,   // 国レベル
        500000,   // 大陸レベル
        1000000,  // 地球レベル
    ]
    
    // ズーム操作
    func zoomIn()
    func zoomOut()
    func setNearestZoomIndex(for altitude: Double)
    
    // プロパティ
    var currentAltitude: Double { get }
    var canZoomIn: Bool { get }
    var canZoomOut: Bool { get }
}
```

### ズーム実装の改善

#### 問題点
以前のspan（緯度経度の範囲）ベースの実装では、MapKitが内部で値を変換するため、期待した値と異なる値が返される問題がありました：

```
期待値: 0.02 -> MapKitからの戻り値: 0.034474...
期待値: 0.05 -> MapKitからの戻り値: 0.08618...
```

#### 解決策
MKMapCameraのaltitude（高度）プロパティを使用することで、より安定したズーム管理を実現：

```swift
// 新しいズーム実装
let camera = MapCamera(
    centerCoordinate: coordinate,
    distance: viewModel.mapControlsViewModel.currentAltitude,
    heading: heading,
    pitch: 0
)
mapPosition = .camera(camera)
```

### MapControlsView
地図コントロールのUIコンポーネントです。

```swift
struct MapControlsView: View {
    @ObservedObject var mapViewModel: MapViewModel
    @ObservedObject var controlsViewModel: MapControlsViewModel
    @Binding var mapPosition: MapCameraPosition
    @Binding var isZoomingByButton: Bool
    let currentMapCamera: MapCamera?
    
    var body: some View {
        VStack(spacing: 16) {
            // ズームコントロール
            VStack(spacing: 8) {
                ControlButton(
                    icon: "plus.magnifyingglass",
                    action: { zoomIn() },
                    isEnabled: controlsViewModel.canZoomIn
                )
                ControlButton(
                    icon: "minus.magnifyingglass",
                    action: { zoomOut() },
                    isEnabled: controlsViewModel.canZoomOut
                )
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
    func saveZoomIndex(_ index: Int)
    func loadZoomIndex() -> Int?
}
```

## iOS開発の学習ポイント

### 1. MapCameraとMapCameraPosition
iOS 17の新しいMapKit APIでは、`MapCamera`と`MapCameraPosition`を使用して地図の位置を管理：

```swift
// MapCameraの作成
let camera = MapCamera(
    centerCoordinate: location.coordinate,
    distance: 10000,  // 高度（メートル）
    heading: 0,       // 方向（度）
    pitch: 0          // 傾き（度）
)

// MapCameraPositionへの適用
@State private var mapPosition: MapCameraPosition = .automatic
mapPosition = .camera(camera)
```

### 2. onMapCameraChangeの活用
地図の変更を監視し、ユーザーの操作を追跡：

```swift
.onMapCameraChange { context in
    // contextから現在のカメラ情報を取得
    let camera = context.camera
    currentMapCamera = camera
    
    // 高度から最も近いズームレベルを設定
    viewModel.mapControlsViewModel.setNearestZoomIndex(for: camera.distance)
}
```

### 3. SwiftUIの状態管理
ボタン操作とピンチ操作を区別するためのフラグ管理：

```swift
@State private var isZoomingByButton = false

// ボタンでのズーム時
isZoomingByButton = true
withAnimation {
    mapPosition = .camera(newCamera)
}
DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
    isZoomingByButton = false
}
```

## テスト駆動開発（TDD）の実践

### 1. MapControlsViewModelTests
ズーム操作、スタイル切り替え、向き切り替えのロジックをテスト：

```swift
func testZoomInLimit() {
    // 最小ズームレベルに設定
    sut.setZoomIndex(0)
    
    // ズームインを試みる
    sut.zoomIn()
    
    // それ以上ズームインできないことを確認
    XCTAssertEqual(sut.currentZoomIndex, 0)
    XCTAssertFalse(sut.canZoomIn)
}

func testSetNearestZoomIndex() {
    // 高度750mは1000m（インデックス2）に最も近い
    sut.setNearestZoomIndex(for: 750)
    XCTAssertEqual(sut.currentZoomIndex, 2)
}
```

### 2. MapSettingsStorageTests
設定の保存と読み込みをモックを使用してテスト：

```swift
func testSaveZoomIndex() {
    sut.saveZoomIndex(7)
    XCTAssertEqual(mockUserDefaults.storage["zoomIndex"] as? Int, 7)
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

## 実装の利点

### 1. 安定したズーム動作
- MapKitの内部変換に依存しない
- 常に予測可能な12段階のズームレベル
- ピンチ操作後もボタンで確実に次のレベルへ移動

### 2. 優れたユーザー体験
- ズーム制限が視覚的に分かる（ボタンのグレーアウト）
- 一貫性のあるズームステップ
- スムーズなアニメーション

### 3. 保守性の向上
- インデックスベースのシンプルな実装
- テストが書きやすく、動作の検証が容易
- 将来の拡張（音声コマンドなど）に対応しやすい設計

## 今後の拡張予定

### Heading Up機能の実装
現在はボタンとフラグのみ実装。今後の実装に必要な要素：
- CLLocationManagerDelegateでheading情報を取得
- MapCameraのheadingプロパティに適用
- 磁北と真北の選択オプション

### 音声コマンド対応
将来的な音声操作のための基盤：
- 各操作メソッドが独立している設計
- 音声認識からの呼び出しが容易
- "ズームイン"、"ズームアウト"などのシンプルなコマンド

## まとめ
段階3では、バイクでの使用を考慮した直感的な地図コントロールを実装しました。特に、高度ベースのズーム実装により、MapKitの内部動作に左右されない安定した操作性を実現しました。大きなタップターゲット、視覚的なフィードバック、設定の永続化により、実用的な地図アプリとしての基本機能が完成しました。

TDDアプローチにより、各機能が確実に動作することを保証しながら、段階的に機能を追加することができました。