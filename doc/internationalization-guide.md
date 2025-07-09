# 多言語化実装ガイド

## 概要

このガイドでは、just a mapアプリケーションに英語対応を追加した多言語化実装について説明します。

## 実装済み機能

### 1. 基本的な国際化インフラストラクチャ

#### Localizable.stringsファイル
- `Resources/Localization/ja.lproj/Localizable.strings` - 日本語リソース
- `Resources/Localization/en.lproj/Localizable.strings` - 英語リソース

#### String拡張によるローカライゼーションヘルパー
- `Sources/JustAMap/Extensions/String+Localization.swift`
- `"key".localized` - 基本的なローカライゼーション
- `"key".localized(with: args...)` - フォーマット付きローカライゼーション

### 2. 対象テキストの国際化

#### AddressView（住所表示ビュー）
- "住所を取得中..." → "address.loading"
  - 日本語: "住所を取得中..."
  - 英語: "Loading address..."

#### SettingsView（設定画面）
- "設定" → "settings.title"
- "閉じる" → "settings.close"  
- "デフォルト設定" → "settings.default_settings"
- "デフォルトズームレベル" → "settings.default_zoom_level"
- "地図の種類" → "settings.map_type"
- "デフォルトでNorth Up" → "settings.default_north_up"
- "表示設定" → "settings.display_settings"
- "住所表示フォーマット" → "settings.address_format"

#### AddressFormat（住所フォーマット）
- "標準" → "address_format.standard"
- "詳細" → "address_format.detailed"  
- "シンプル" → "address_format.simple"
- フォーマット説明文も完全にローカライズ

#### MapStyle（地図スタイル）
- "標準" → "map_style.standard"
- "航空写真+地図" → "map_style.hybrid" (英語: "Satellite + Map")
- "航空写真" → "map_style.imagery" (英語: "Satellite")

#### LocationError（位置情報エラー）
- 全てのエラーメッセージをローカライズ
- フォーマット付きエラーメッセージにも対応

#### AddressFormatter（住所フォーマッター）
- "現在地" → "address.current_location" (英語: "Current Location")

### 3. 国際化対応住所フォーマット

#### ロケール検出による自動切り替え
```swift
let currentLanguage = Locale.current.language.languageCode?.identifier ?? "en"
```

#### 郵便番号フォーマット
- **日本語環境**: 〒100-0001
- **英語/国際環境**: 100-0001（プレーン形式）

#### 住所コンポーネントの順序
- **日本語**: 都道府県 → 市区町村/郡 → 区市町村
- **英語/国際**: 市区町村 → 州/県 → 国 (カンマ区切り)

### 4. テスト実装

#### LocalizationTests.swift
- String拡張のテスト
- AddressFormatのローカライゼーションテスト
- MapStyleのローカライゼーションテスト
- LocationErrorのローカライゼーションテスト
- AddressFormatterの国際化対応テスト

## 技術的詳細

### Package.swift設定
```swift
.target(
    name: "JustAMap",
    dependencies: [],
    path: "Sources/JustAMap",
    resources: [
        .process("../../Resources/Localization")
    ]
),
```

### 使用方法の例

#### 基本的な文字列のローカライゼーション
```swift
Text("settings.title".localized)
```

#### フォーマット付き文字列のローカライゼーション
```swift
"location.error.update_failed".localized(with: errorMessage)
```

#### 条件付きローカライゼーション（住所フォーマッターで使用）
```swift
let currentLanguage = Locale.current.language.languageCode?.identifier ?? "en"
if currentLanguage == "ja" {
    // 日本語固有の処理
} else {
    // 国際（英語）処理
}
```

## 多言語化の拡張方法

### 新しい言語の追加手順

1. **新しい.lprojディレクトリの作成**
   ```
   Resources/Localization/[language_code].lproj/
   ```

2. **Localizable.stringsファイルの作成**
   既存の英語版をベースに翻訳

3. **Package.swiftの更新**（通常は不要、resourcesが自動検出）

4. **住所フォーマットの調整**
   必要に応じてAddressFormatterでロケール固有の処理を追加

### 新しい文字列の追加手順

1. **全てのLocalizable.stringsファイルに同じキーを追加**
2. **コード内でローカライズされていない文字列を置換**
   ```swift
   "新しいテキスト" → "new.text.key".localized
   ```
3. **テストケースの追加**

## ベストプラクティス

### キーの命名規則
- ドット区切りの階層構造を使用
- 例: `"settings.display_settings"`, `"address_format.standard"`

### コメントの活用
Localizable.stringsファイルでセクションコメントを使用：
```
/* SettingsView */
"settings.title" = "Settings";
```

### フォーマット文字列
- %@, %d などのフォーマット指定子を適切に使用
- 引数の順序が言語によって異なる場合は位置指定子を使用

### 住所フォーマットの国際化
- ロケールによる住所コンポーネントの順序変更
- 区切り文字の変更（日本語：なし、英語：カンマ）
- 郵便番号プレフィックスの調整

## 注意事項

### UI要素のサイズ調整
- 英語は日本語より長くなる傾向があるため、UIレイアウトに十分な余裕を持たせる
- 特にボタンテキストや設定項目名に注意

### 文化的配慮
- 住所フォーマットは文化に依存するため、各国の慣習に合わせる
- 日付、時刻、数値フォーマットも将来的に考慮が必要

### テスト環境
- シミュレータの言語設定を変更してテスト
- 実機での動作確認も重要

## 今後の改善点

1. **複数形対応**: NSStringLocalizedStringWithDefaultValue を使用した複数形対応
2. **右から左への言語対応**: アラビア語、ヘブライ語などのサポート
3. **地域特化**: 同じ言語でも地域による差異への対応
4. **音声読み上げ**: VoiceOverでの多言語対応

---

このガイドに従って、just a mapアプリケーションの多言語化を効率的に管理・拡張できます。