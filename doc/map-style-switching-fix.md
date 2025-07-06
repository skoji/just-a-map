# 地図スタイル切り替え時のズームレベルリセット問題の修正

## 問題の概要

実機で地図スタイル（標準/ハイブリッド/航空写真）を切り替えた際に、以下の問題が発生していました：

1. **スタイル切り替えが即座に反映されない**：スタイルボタンをタップしても見た目が変わらず、その後ズームやスクロール操作を行うと反映される
2. **ズームレベルがリセットされる**：スタイル切り替え後、日本全体が表示される最大ズームレベルに戻ってしまう

## 原因分析

### 初期実装の問題点

```swift
// 地図
Group {
    switch viewModel.mapControlsViewModel.currentMapStyle {
    case .standard:
        Map(position: $mapPosition) {
            UserAnnotation()
        }
        .mapStyle(.standard)
    case .hybrid:
        Map(position: $mapPosition) {
            UserAnnotation()
        }
        .mapStyle(.hybrid)
    case .imagery:
        Map(position: $mapPosition) {
            UserAnnotation()
        }
        .mapStyle(.imagery)
    }
}
```

この実装では、スタイルごとに別々の`Map`インスタンスを作成していました。そのため：

1. スタイル切り替え時に新しい`Map`インスタンスが作成される
2. `onMapCameraChange`イベントが予期せず発火し、ズームレベルが変更される
3. カメラ位置（ズームレベルと中心座標）が失われる

## 解決アプローチの変遷

### 1. 複雑なアプローチ（失敗）

最初は以下のような複雑な解決策を試みました：

- スタイル変更中フラグ（`isChangingMapStyle`）の導入
- カメラ位置の保存と復元
- 微小なカメラ位置変更による強制的な再描画
- `.id()`モディファイアによるビューの再作成

これらのアプローチは過度に複雑で、新たな問題（予期しないズームアウト）を引き起こしました。

### 2. シンプルなアプローチ（成功）

最終的に、SwiftUIの基本的な状態管理を活用したシンプルな解決策に到達しました。

## 最終的な解決策

### 実装コード

```swift
struct MapView: View {
    // ... 他のプロパティ ...
    
    // マップスタイル表示用の@State変数
    @State private var mapStyleForDisplay: JustAMap.MapStyle = .standard
    
    // MapKit.MapStyleに変換する計算プロパティ
    private var mapStyleValue: MapKit.MapStyle {
        switch mapStyleForDisplay {
        case .standard:
            return .standard
        case .hybrid:
            return .hybrid
        case .imagery:
            return .imagery
        }
    }
    
    var body: some View {
        ZStack {
            // 単一のMapインスタンスを使用
            Map(position: $mapPosition) {
                UserAnnotation()
            }
            .mapStyle(mapStyleValue)  // 動的にスタイルを適用
            .mapControls {
                MapCompass()
                MapScaleView()
            }
            // ... 他のモディファイア ...
        }
        .onReceive(viewModel.mapControlsViewModel.$currentMapStyle) { newStyle in
            viewModel.saveSettings()
            // State変数を更新してSwiftUIの再描画を促す
            mapStyleForDisplay = newStyle
        }
    }
}
```

### 解決のポイント

1. **単一のMapインスタンス**：`switch`文による複数インスタンスではなく、単一の`Map`を使用
2. **@State変数の活用**：`mapStyleForDisplay`を介することで、SwiftUIの再描画メカニズムを適切に動作させる
3. **シンプルな実装**：カメラ位置の保存・復元などの複雑な処理は不要

## なぜこの解決策が機能するか

### SwiftUIの再描画メカニズム

1. `@State`変数が変更されると、SwiftUIはビューを再描画する
2. 単一の`Map`インスタンスを使用しているため、カメラ位置は自動的に保持される
3. `mapStyle`プロパティの変更により、地図の見た目だけが更新される

### 型の衝突の解決

アプリ内で定義した`MapStyle`列挙型と`MapKit.MapStyle`の名前衝突を避けるため：

- 完全修飾名（`JustAMap.MapStyle`）を使用
- 計算プロパティで`MapKit.MapStyle`に変換

## 学んだ教訓

1. **シンプルさの重要性**：地図スタイルの切り替えは基本的な操作であり、複雑な対処は不要
2. **SwiftUIの基本に立ち返る**：`@State`と計算プロパティという基本的な機能で解決可能
3. **単一インスタンスの利点**：状態の保持が自動的に行われ、追加の管理コードが不要

## テストの追加

`MapStyleSwitchingTests`を追加し、TDDアプローチで開発しました：

```swift
@MainActor
class MapStyleSwitchingTests: XCTestCase {
    // MainActorアノテーションが必要（ViewModelがMainActor isolated）
    
    func testMapStyleChangePreservesZoomLevel() {
        // ズームレベルが保持されることを確認
    }
}
```

## 今後の改善点

現在の実装はシンプルで効果的ですが、将来的に以下の改善を検討できます：

1. アニメーション付きのスタイル切り替え
2. スタイル切り替え時の視覚的フィードバック
3. より高度なカメラ制御（必要に応じて）

## 参考資料

- [SwiftUI Map Documentation](https://developer.apple.com/documentation/mapkit/map)
- [Managing State in SwiftUI](https://developer.apple.com/documentation/swiftui/state-and-data-flow)