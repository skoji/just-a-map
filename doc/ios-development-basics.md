# iOS開発の基本概念

iOS開発に初めて触れるプログラマー向けに、基本的な概念と用語を解説します。

## 目次

1. [SwiftUIとは](#swiftuiとは)
2. [プロパティラッパー](#プロパティラッパー)
3. [ビューのライフサイクル](#ビューのライフサイクル)
4. [非同期処理](#非同期処理)
5. [権限システム](#権限システム)
6. [Xcodeの基本](#xcodeの基本)

## SwiftUIとは

SwiftUIは、Appleが2019年に発表した宣言的UIフレームワークです。

### 宣言的UIの例

```swift
// 命令的（UIKit）
let label = UILabel()
label.text = "Hello"
label.textColor = .red
view.addSubview(label)

// 宣言的（SwiftUI）
Text("Hello")
    .foregroundColor(.red)
```

**特徴：**
- 「どう作るか」ではなく「何を表示するか」を記述
- 状態が変わると自動的にUIが更新される
- プレビュー機能でリアルタイムに確認可能

## プロパティラッパー

SwiftUIでよく使われる特殊な属性です。

### @State
ビュー内部の状態を管理します。
```swift
struct CounterView: View {
    @State private var count = 0  // 値が変わるとビューが再描画
    
    var body: some View {
        Button("Count: \(count)") {
            count += 1  // 自動的にUIが更新される
        }
    }
}
```

### @StateObject
ビューが所有するオブジェクトを管理します。
```swift
struct MapView: View {
    @StateObject private var viewModel = MapViewModel()  // ビューが再描画されても同じインスタンス
}
```

### @Published
ObservableObject内で、変更を通知するプロパティです。
```swift
class MapViewModel: ObservableObject {
    @Published var location: CLLocation?  // 変更されると購読者に通知
}
```

### @ObservedObject
他から渡されたオブジェクトを監視します。
```swift
struct DetailView: View {
    @ObservedObject var viewModel: MapViewModel  // 親から受け取る
}
```

### @EnvironmentObject
アプリ全体で共有されるオブジェクトです。
```swift
@EnvironmentObject var settings: UserSettings  // どこからでもアクセス可能
```

## ビューのライフサイクル

SwiftUIビューの主要なイベント：

```swift
struct MapView: View {
    var body: some View {
        Map()
            .onAppear {
                // ビューが表示される時
                print("ビューが表示されました")
            }
            .onDisappear {
                // ビューが非表示になる時
                print("ビューが非表示になりました")
            }
            .onChange(of: someValue) { newValue in
                // 特定の値が変更された時
                print("値が変更されました: \(newValue)")
            }
    }
}
```

## 非同期処理

### async/await（Swift 5.5以降）

```swift
// 従来のコールバック方式
CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
    if let placemark = placemarks?.first {
        // 処理
    }
}

// async/await方式
func getAddress(for location: CLLocation) async throws -> String {
    let placemarks = try await CLGeocoder().reverseGeocodeLocation(location)
    return placemarks.first?.name ?? "不明"
}
```

### Task

非同期処理を開始します：
```swift
Task {
    let address = try await getAddress(for: location)
    print(address)
}
```

### @MainActor

UI更新は必ずメインスレッドで行う必要があります：
```swift
@MainActor
class MapViewModel: ObservableObject {
    // このクラス内の全てのプロパティ・メソッドはメインスレッドで実行
}

// または
Task { @MainActor in
    // この中のコードはメインスレッドで実行
    self.userLocation = newLocation
}
```

## 権限システム

iOSは以下のようなユーザーデータへのアクセスに権限が必要です：

- 位置情報
- カメラ
- マイク
- 連絡先
- 写真

### 権限リクエストの流れ

1. **Info.plistに使用理由を記載**
   ```xml
   <key>NSLocationWhenInUseUsageDescription</key>
   <string>地図に現在地を表示するため</string>
   ```

2. **権限をリクエスト**
   ```swift
   locationManager.requestWhenInUseAuthorization()
   ```

3. **権限状態を確認**
   ```swift
   switch locationManager.authorizationStatus {
   case .notDetermined:  // まだ聞いていない
   case .denied:         // 拒否された
   case .authorizedWhenInUse:  // 使用中のみ許可
   }
   ```

## Xcodeの基本

### プロジェクト構造

```
MyApp.xcodeproj/          # プロジェクトファイル
├── MyApp/                # ソースコード
│   ├── Assets.xcassets/  # 画像やアイコン
│   ├── Info.plist        # アプリ設定
│   └── *.swift           # Swiftファイル
├── MyAppTests/           # ユニットテスト
└── MyAppUITests/         # UIテスト
```

### よく使うショートカット

- **⌘+R**: ビルド&実行
- **⌘+B**: ビルドのみ
- **⌘+U**: テスト実行
- **⌘+Shift+K**: クリーンビルド
- **⌘+.**: 実行停止
- **⌘+Shift+O**: ファイルを開く

### シミュレータの操作

- **⌘+D**: ホーム画面
- **⌘+Shift+H**: ホームボタン
- **⌘+→/←**: 画面回転
- **Features > Location**: 位置情報シミュレート

### デバッグ

```swift
// プリントデバッグ
print("現在地: \(location)")

// ブレークポイント
// 行番号をクリックして青い矢印を設置

// デバッグコンソール
// Xcodeの下部に表示される
```

## メモリ管理

SwiftはARC（Automatic Reference Counting）でメモリを管理します。

### 循環参照を防ぐ

```swift
// 悪い例：循環参照
class LocationManager {
    var delegate: LocationManagerDelegate?  // 強参照
}

// 良い例：弱参照
class LocationManager {
    weak var delegate: LocationManagerDelegate?  // 弱参照
}
```

### クロージャでの注意

```swift
// 悪い例：selfを強参照
locationManager.updateHandler = { location in
    self.updateLocation(location)  // selfを捕獲
}

// 良い例：weakで捕獲
locationManager.updateHandler = { [weak self] location in
    self?.updateLocation(location)  // 弱参照
}
```

## まとめ

iOS開発の特徴：

1. **宣言的UI**：状態を宣言すれば、UIは自動更新
2. **厳格な権限管理**：ユーザーのプライバシーを重視
3. **非同期処理**：UIの応答性を保つため重要
4. **メモリ管理**：ARCで自動化されているが、循環参照に注意

これらの概念を理解することで、iOS開発の基礎が身につきます。