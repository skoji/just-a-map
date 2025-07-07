# 地図の回転アニメーション実装

## 概要

JustAMapアプリケーションでは、North Up（北が上）とHeading Up（進行方向が上）の2つの地図表示モードをサポートしています。このドキュメントでは、モード切り替え時の滑らかな回転アニメーションの実装について説明します。

## 実装内容

### 1. 即座の回転アニメーション

従来の実装では、North Up/Heading Upの切り替えボタンを押しても、次の位置情報更新まで地図が回転しませんでした。新しい実装では、切り替えボタンを押すと即座に滑らかなアニメーションで地図が回転します。

#### MapView.swift での実装

```swift
.onReceive(viewModel.mapControlsViewModel.$isNorthUp) { isNorthUp in
    viewModel.saveSettings()
    // 地図の向きが切り替わったら即座にアニメーション付きで回転
    if let location = viewModel.userLocation ?? currentMapCamera.map({ camera in
        CLLocation(latitude: camera.centerCoordinate.latitude, longitude: camera.centerCoordinate.longitude)
    }) {
        withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.8, blendDuration: 0.1)) {
            let heading: Double
            if isNorthUp {
                heading = 0 // North Up
            } else if let userLocation = viewModel.userLocation, userLocation.course >= 0 {
                heading = userLocation.course // Heading Up with valid course
            } else {
                heading = 0 // デフォルト
            }
            
            let camera = MapCamera(
                centerCoordinate: location.coordinate,
                distance: currentMapCamera?.distance ?? viewModel.mapControlsViewModel.currentAltitude,
                heading: heading,
                pitch: 0
            )
            mapPosition = .camera(camera)
        }
    }
}
```

この実装により、モード切り替え時に以下の動作を実現：
- **North Upモード**: heading を 0 に設定（北が上）
- **Heading Upモード**: GPS のコース情報を使用（進行方向が上）
- **滑らかなアニメーション**: `interactiveSpring` を使用した自然な回転

### 2. North Upモードでのユーザー操作による回転の禁止

North Upモードでは、地図は常に北が上を向くべきであり、ユーザーが手動で回転させることを防ぐ必要があります。

#### MapView.swift での実装

```swift
Map(position: $mapPosition, interactionModes: viewModel.mapControlsViewModel.isNorthUp ? [.pan, .zoom] : .all) {
    UserAnnotation()
}
```

`interactionModes` パラメータを使用して、North Upモード時は回転を除いたインタラクション（パンとズームのみ）を許可しています。

### 3. 位置情報に基づく地図の方向計算

MapViewModelに、現在のモードと位置情報に基づいて適切な地図の方向を計算するメソッドを追加しました。

#### MapViewModel.swift での実装

```swift
/// 位置情報に基づいて地図の方向を計算
func calculateMapHeading(for location: CLLocation) -> Double {
    if mapControlsViewModel.isNorthUp {
        return 0 // North Up: 常に北が上
    } else {
        // Heading Up: コース情報が有効な場合は使用、無効な場合は0
        return location.course >= 0 ? location.course : 0
    }
}
```

### 4. アニメーションの詳細

使用しているアニメーションパラメータ：
- **タイプ**: `interactiveSpring` - ユーザーインタラクションに適した自然なバネアニメーション
- **response**: 0.3秒 - 素早い反応時間
- **dampingFraction**: 0.8 - 高いダンピングで滑らかな減速
- **blendDuration**: 0.1秒 - 短いブレンド時間で即座の反応

## テスト

実装に対して以下のテストケースを作成：

1. **トグルテスト**: North Up/Heading Upの切り替えが正しく動作することを確認
2. **回転角度計算テスト**: 各方位に対して正しい回転角度が計算されることを確認
3. **無効なコース処理テスト**: GPSコースが無効な場合のフォールバック動作を確認
4. **ユーザー操作制限テスト**: North Upモードで回転が無効になることを確認

## パフォーマンスへの影響

- **バッテリー消費**: 既存の位置情報更新頻度を変更していないため、追加の消費なし
- **CPU使用率**: アニメーションはSwiftUIの最適化されたレンダリングを使用
- **メモリ使用量**: 追加のメモリ使用なし

## 今後の改善案

1. **コンパス表示**: 現在の方位を視覚的に示すコンパスオーバーレイの追加
2. **回転ジェスチャー**: Heading Upモード時の2本指回転ジェスチャーのサポート
3. **方位の平滑化**: GPSコースの揺れを軽減するための移動平均フィルタ

## 関連ファイル

- `/JustAMap/MapView.swift` - 地図表示とアニメーション処理
- `/JustAMap/Models/MapViewModel.swift` - 地図の方向計算ロジック
- `/JustAMap/Models/MapControlsViewModel.swift` - 地図コントロールの状態管理
- `/JustAMapTests/MapRotationAnimationTests.swift` - 回転機能のテスト

## Issue

- [#1 機能追加: North Up / Heading Up 切り替え時の地図回転アニメーション](https://github.com/skoji/just-a-map/issues/1)