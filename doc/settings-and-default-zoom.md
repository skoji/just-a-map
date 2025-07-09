# 設定画面とデフォルトズームレベル機能

## 概要

JustAMapの設定画面では、ユーザーが以下の項目をカスタマイズできます：
- デフォルトズームレベル
- デフォルト地図スタイル（標準/衛星写真/ハイブリッド）
- デフォルト地図の向き（北固定/進行方向）
- 住所表示フォーマット（標準/詳細/シンプル）
- アプリバージョン情報の表示

## 実装の詳細

### SettingsViewModel

設定画面のビジネスロジックを管理するViewModelです：

```swift
class SettingsViewModel: ObservableObject {
    private var settingsStorage: MapSettingsStorageProtocol
    private var bundle: BundleProtocol
    private var versionInfo: [String: Any]?
    
    @Published var defaultZoomIndex: Int
    @Published var defaultMapStyle: MapStyle
    @Published var defaultIsNorthUp: Bool
    @Published var addressFormat: AddressFormat
}
```

### バージョン情報の取得

PR #50で実装されたバージョン管理システムを使用：

1. **VersionInfo.plistから取得**（優先）
   - ビルド時に生成される
   - Git情報から自動生成されたバージョン番号を含む

2. **Bundle.mainから取得**（フォールバック）
   - VersionInfo.plistが存在しない場合に使用
   - 開発中やテスト時に有効

### 設定の永続化

`MapSettingsStorage`を使用してUserDefaultsに保存：

```swift
protocol MapSettingsStorageProtocol {
    var defaultZoomIndex: Int { get set }
    var defaultMapStyle: MapStyle { get set }
    var defaultIsNorthUp: Bool { get set }
    var addressFormat: AddressFormat { get set }
}
```

## TDDアプローチ

### テストファースト開発

1. **SettingsViewModelTests**
   - バージョン情報の取得ロジック
   - 設定値の読み書き
   - MockBundleを使用したテスト

2. **統合テスト**
   - 設定画面の表示
   - 設定変更の反映
   - アプリ再起動時の設定保持

### モックオブジェクト

```swift
class MockBundle: BundleProtocol {
    var infoDictionary: [String: Any]?
    var mockResources: [String: URL] = [:]
    
    func url(forResource name: String?, withExtension ext: String?) -> URL? {
        // VersionInfo.plistのモック
    }
}
```

## UI実装

### SwiftUI Form

設定画面はSwiftUIのFormを使用：

```swift
Form {
    Section("map_settings") {
        // ズームレベル設定
        // 地図スタイル設定
        // 地図の向き設定
    }
    
    Section("address_settings") {
        // 住所フォーマット設定
    }
    
    Section("app_info") {
        // バージョン情報表示
    }
}
```

## 国際化対応

全ての設定項目は多言語対応：
- 日本語（ja）
- 英語（en）

Localizable.stringsファイルで管理。

## 今後の拡張

- 設定のエクスポート/インポート
- iCloud同期
- 詳細なカスタマイズオプション