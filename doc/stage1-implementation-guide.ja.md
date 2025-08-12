# 段階1実装ガイド：基本的な地図表示

このドキュメントでは、iOS開発に馴染みのないプログラマー向けに、段階1で実装した内容を詳しく解説します。

## 目次

1. [プロジェクト構造](#プロジェクト構造)
2. [主要コンポーネントの解説](#主要コンポーネントの解説)
3. [位置情報の取得フロー](#位置情報の取得フロー)
4. [SwiftUIとMapKitの連携](#swiftuiとmapkitの連携)
5. [エラーハンドリング](#エラーハンドリング)
6. [テスト戦略](#テスト戦略)

## プロジェクト構造

```
JustAMap/
├── JustAMapApp.swift      # アプリのエントリーポイント
├── ContentView.swift      # メインのビュー（MapViewを表示）
├── MapView.swift          # 地図表示のUI
├── Models/
│   ├── LocationManagerProtocol.swift  # 位置情報管理の抽象化
│   ├── LocationManager.swift          # 実際の位置情報管理
│   └── MapViewModel.swift             # ビジネスロジック
└── Assets.xcassets/       # アイコンや色などのリソース
```

## 主要コンポーネントの解説

### 1. JustAMapApp.swift - アプリのエントリーポイント

```swift
@main
struct JustAMapApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

**解説：**
- `@main`：このstructがアプリケーションのエントリーポイントであることを示す
- `App`プロトコル：SwiftUIアプリケーションの基本構造を定義
- `WindowGroup`：アプリのウィンドウを管理（iOSでは通常1つ）

### 2. LocationManagerProtocol.swift - 抽象化層

```swift
protocol LocationManagerProtocol: AnyObject {
    var delegate: LocationManagerDelegate? { get set }
    var authorizationStatus: CLAuthorizationStatus { get }
    
    func requestLocationPermission()
    func startLocationUpdates()
    func stopLocationUpdates()
}
```

**なぜプロトコルを使うのか？**
- **テスタビリティ**: 実際のGPSがなくてもテストできる
- **依存性の逆転**: 上位レイヤーが下位レイヤーの具体的な実装に依存しない
- **モック化**: テスト時に偽の位置情報を簡単に注入できる

### 3. LocationManager.swift - 実装

```swift
class LocationManager: NSObject, LocationManagerProtocol {
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10.0  // 10m移動したら更新
        locationManager.activityType = .automotiveNavigation
    }
}
```

**重要な設定：**
- `desiredAccuracy`：GPS精度（最高精度を指定）
- `distanceFilter`：更新頻度（10m移動ごと）
- `activityType`：使用シナリオ（車両ナビゲーション用に最適化）

### 4. MapViewModel.swift - ビジネスロジック

```swift
@MainActor
class MapViewModel: ObservableObject {
    @Published var region = MKCoordinateRegion(...)
    @Published var userLocation: CLLocation?
    @Published var isLocationAuthorized = false
    @Published var locationError: LocationError?
    @Published var isFollowingUser = true
}
```

**SwiftUIの重要概念：**
- `@MainActor`：UIの更新は必ずメインスレッドで行う
- `@Published`：値が変更されたらUIを自動更新
- `ObservableObject`：SwiftUIがこのオブジェクトを監視可能に

## 位置情報の取得フロー

```
1. アプリ起動
   ↓
2. MapView.onAppear()でrequestLocationPermission()を呼ぶ
   ↓
3. システムが権限ダイアログを表示
   ↓
4. ユーザーが許可
   ↓
5. locationManagerDidChangeAuthorization()が呼ばれる
   ↓
6. startLocationUpdates()で位置情報取得開始
   ↓
7. locationManager(_:didUpdateLocations:)で位置を受信
   ↓
8. MapViewModelが地図を更新
```

## SwiftUIとMapKitの連携

### iOS 17の新しいMap API

```swift
Map(position: $mapPosition) {
    UserAnnotation()  // 現在位置のマーカー
}
.mapControls {
    MapCompass()      // 方位磁針
    MapScaleView()    // 縮尺表示
}
```

**旧APIとの違い：**
- 旧：`Map(coordinateRegion: $region)`
- 新：`Map(position: .constant(.region(region)))`
- より宣言的で、MapKitの他の機能と統合しやすい

### 地図の追従モード

```swift
.onMapCameraChange { context in
    if viewModel.isFollowingUser {
        // ユーザーが地図を動かしたら追従を解除
        if distance > 100 { // 100m以上離れたら
            viewModel.isFollowingUser = false
        }
    }
}
```

## エラーハンドリング

### 位置情報エラーの種類

1. **権限拒否** (`CLAuthorizationStatus.denied`)
   - ユーザーが位置情報の使用を拒否
   - 設定アプリへの誘導が必要

2. **一時的なエラー** (`kCLErrorDomain Code=0`)
   - シミュレータでよく発生
   - 無視して問題ない

3. **位置情報サービス無効**
   - デバイス全体で位置情報がオフ
   - システム設定の変更が必要

### エラー表示UI

```swift
struct ErrorBanner: View {
    let error: LocationError
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(error.localizedDescription)
            
            if error == .authorizationDenied {
                Button("設定") {
                    // 設定アプリを開く
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                }
            }
        }
    }
}
```

## テスト戦略

### プロトコルを使ったモック

```swift
class MockLocationManager: LocationManagerProtocol {
    func simulateLocationUpdate(_ location: CLLocation) {
        delegate?.locationManager(self, didUpdateLocation: location)
    }
}
```

**テストの例：**
```swift
func testLocationUpdate() {
    // Given
    let mockManager = MockLocationManager()
    let viewModel = MapViewModel(locationManager: mockManager)
    
    // When
    mockManager.simulateLocationUpdate(CLLocation(...))
    
    // Then
    XCTAssertNotNil(viewModel.userLocation)
}
```

## iOS特有の注意点

### 1. Info.plistの設定
位置情報を使用するには、必ず使用理由を明記する必要があります：
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>現在地を地図の中心に表示するために位置情報を使用します</string>
```

### 2. メインスレッドとバックグラウンドスレッド
- UI更新は必ずメインスレッド（`@MainActor`）
- 位置情報の取得はバックグラウンドスレッド
- `Task { @MainActor in ... }`で切り替え

### 3. メモリ管理
- `weak var delegate`：循環参照を防ぐ
- `@StateObject`：ビューが再描画されても同じインスタンスを保持
- `@ObservedObject`：親から渡されたオブジェクトを監視

## まとめ

段階1では、以下の基本機能を実装しました：

1. **位置情報の取得と権限管理**
2. **地図の表示と現在位置への追従**
3. **エラーハンドリングとユーザーフィードバック**
4. **テスト可能な設計**

これらの実装により、バイクのハンドルマウントで使用できる基本的な地図アプリケーションの土台が完成しました。