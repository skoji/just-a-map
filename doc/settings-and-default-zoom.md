# 設定画面とデフォルトズームレベル機能

## 概要
just a mapアプリに設定画面を追加し、デフォルトズームレベルや地図の表示設定をカスタマイズできるようになりました。特に、現在位置ボタンを押した時に適用されるデフォルトズームレベルの機能は、バイクでの使用時に便利な機能です。

## 実装した機能

### 1. 設定画面（SettingsView）
- **アクセス方法**: 地図画面右上の歯車アイコンをタップ
- **表示形式**: モーダルシート形式で表示
- **閉じる方法**: 右上の「閉じる」ボタンまたは下にスワイプ

### 2. デフォルト設定
設定画面では以下のデフォルト値を設定できます：

#### デフォルトズームレベル
- **12段階のズームレベル**: 200m〜1,000kmまで
- **視覚的な操作**: ＋/−ボタンで段階的に調整
- **リアルタイム表示**: 現在選択中のズームレベルが中央に表示される
- **適用タイミング**: 現在位置ボタンを押した時に適用

#### デフォルト地図の種類
- 標準
- ハイブリッド
- 航空写真

#### デフォルト地図の向き
- North Up（北が上）
- Heading Up（進行方向が上）※回転機能は今後実装予定

### 3. 表示設定

#### 住所表示フォーマット
- **標準**: バランスの取れた表示（例：東京都港区六本木6-10-1）
- **詳細**: 郵便番号を含む詳細表示（例：〒106-6108 東京都港区六本木6-10-1）
- **シンプル**: 最小限の情報（例：六本木6-10-1）

## 技術的な実装詳細

### 1. SwiftUI FormとButtonの問題と解決
#### 問題
SwiftUIのForm内でButtonに`.buttonStyle(.plain)`を適用すると、ボタンがタップに反応しない問題が発生しました。

#### 解決策
```swift
Button {
    viewModel.defaultZoomIndex -= 1
} label: {
    Image(systemName: "minus.circle.fill")
        .font(.title2)
        .foregroundColor(viewModel.defaultZoomIndex > minIndex ? .blue : .gray)
}
.disabled(viewModel.defaultZoomIndex <= minIndex)
.buttonStyle(.borderless) // .plainではなく.borderlessを使用
```

### 2. デフォルトズームレベルの適用

#### MapViewModelの実装
```swift
func centerOnUserLocation() {
    guard let location = userLocation else { return }
    
    // 追従モードを有効化
    isFollowingUser = true
    
    // デフォルトズームレベルを適用
    let defaultZoomIndex = settingsStorage.defaultZoomIndex
    mapControlsViewModel.setZoomIndex(defaultZoomIndex)
    
    withAnimation(.easeInOut(duration: 0.3)) {
        region = MKCoordinateRegion(
            center: location.coordinate,
            span: region.span
        )
    }
}
```

### 3. 追従モード維持の問題と解決

#### 問題
現在位置ボタンを押してデフォルトズームレベルが適用される際、一時的に地図の中心がずれることで追従モードが解除され、十字線が表示される問題がありました。

#### 解決策
`isZoomingByButton`フラグを使用して、ズーム操作中は距離チェックをスキップ：

```swift
// MapView.swift
Button(action: {
    // ズーム中フラグを立てて、onMapCameraChangeでの追従解除を防ぐ
    isZoomingByButton = true
    viewModel.centerOnUserLocation()
    
    if let location = viewModel.userLocation {
        withAnimation {
            let camera = MapCamera(
                centerCoordinate: location.coordinate,
                distance: viewModel.mapControlsViewModel.currentAltitude,
                heading: viewModel.mapControlsViewModel.isNorthUp ? 0 : location.course,
                pitch: 0
            )
            mapPosition = .camera(camera)
        }
    }
    
    // アニメーション完了後にフラグをリセット
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        isZoomingByButton = false
    }
}) {
    // ボタンのUI
}
```

### 4. 設定の永続化

#### SettingsViewModelの実装
```swift
class SettingsViewModel: ObservableObject {
    private var settingsStorage: MapSettingsStorageProtocol
    
    @Published var defaultZoomIndex: Int {
        didSet {
            settingsStorage.defaultZoomIndex = defaultZoomIndex
        }
    }
    
    @Published var defaultMapStyle: MapStyle {
        didSet {
            settingsStorage.defaultMapStyle = defaultMapStyle
        }
    }
    
    @Published var defaultIsNorthUp: Bool {
        didSet {
            settingsStorage.defaultIsNorthUp = defaultIsNorthUp
        }
    }
    
    @Published var addressFormat: AddressFormat {
        didSet {
            settingsStorage.addressFormat = addressFormat
        }
    }
}
```

## テスト駆動開発（TDD）のプロセス

### 1. 設定画面のボタン動作テスト
```swift
func testZoomLevelDisplayTextUpdatesWhenDefaultZoomIndexChanges() {
    // Given
    sut.defaultZoomIndex = 2
    XCTAssertEqual(sut.zoomLevelDisplayText, "1km")
    
    // When - ズームインボタンを押した時の動作を再現
    sut.defaultZoomIndex = 3
    
    // Then
    XCTAssertEqual(sut.zoomLevelDisplayText, "2km")
}
```

### 2. デフォルトズームレベル適用のテスト
```swift
func testCenterOnUserLocationUsesDefaultZoomLevel() {
    // Given
    let testLocation = CLLocation(latitude: 35.6762, longitude: 139.6503)
    sut.userLocation = testLocation
    mockSettingsStorage.defaultZoomIndex = 2 // 1km
    sut.mapControlsViewModel.setZoomIndex(8) // 現在は100km
    
    // When
    sut.centerOnUserLocation()
    
    // Then
    XCTAssertTrue(sut.isFollowingUser)
    XCTAssertEqual(sut.mapControlsViewModel.currentZoomIndex, 2)
}
```

### 3. 追従モード維持のテスト
```swift
func testFollowingModeRemainsEnabledAfterCenterOnUserLocation() {
    // Given
    let testLocation = CLLocation(latitude: 35.6762, longitude: 139.6503)
    sut.userLocation = testLocation
    sut.isFollowingUser = false
    
    // When
    sut.centerOnUserLocation()
    
    // Then
    XCTAssertTrue(sut.isFollowingUser)
    
    // 地図操作をシミュレート（100m未満の移動）
    let nearbyCoordinate = CLLocationCoordinate2D(
        latitude: 35.6763,
        longitude: 139.6503
    )
    sut.updateMapCenter(nearbyCoordinate)
    
    // 100m未満の移動では追従モードは維持されるべき
    XCTAssertTrue(sut.isFollowingUser)
}
```

## トラブルシューティング

### 設定画面のボタンが反応しない
- **原因**: Form内でのButtonStyle設定の問題
- **解決**: `.buttonStyle(.borderless)`を使用

### デフォルトズームが適用されない
- **確認事項**: 
  - settingsStorageが正しく初期化されているか
  - defaultZoomIndexが保存されているか
  - centerOnUserLocationが呼ばれているか

### 追従モードが解除される
- **原因**: onMapCameraChangeでの距離チェック
- **解決**: isZoomingByButtonフラグの使用

## 今後の改善案

1. **設定のエクスポート/インポート**: 複数デバイス間での設定共有
2. **プリセット機能**: よく使う設定の組み合わせを保存
3. **ジェスチャーカスタマイズ**: ダブルタップやロングプレスの動作設定
4. **テーマ設定**: ダークモード/ライトモードの固定設定

## 更新履歴

- 2025-07-07: 初版作成（Issue #12対応）
  - 設定画面のボタン修正
  - デフォルトズームレベル機能の実装
  - 追従モード維持の改善