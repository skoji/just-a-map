# CLAUDE.md - just a map 開発ガイドライン

## プロジェクト概要

### アプリケーション名
**just a map** - リアルタイムで更新される以外は単なる地図

### 目的
バイク（オートバイ）のハンドルマウントで使用する、シンプルで実用的な地図アプリケーション。ナビゲーション機能は不要で、現在地の確認と基本的な地図操作に特化。

### 主要な課題解決
- 通常の地図アプリはすぐにスリープしてしまう
- 信号待ちでの複雑な操作は危険で困難
- 現在の住所を即座に確認したい
- シンプルで直感的な操作性が必要

### ドキュメント

これまでの実装についての解説文書を[doc](doc)以下に格納している。

## 技術要件

### 使用技術
- **フレームワーク**: SwiftUI
- **地図**: Apple純正のMapKit
- **最小対応iOS**: iOS 17.0以上（最新のMapKit機能を活用）

### 開発方針
** 以下に必ず従ってください **
- **TDD（Test-Driven Development）**: t-wada流のTDDを採用
  - 問題が発生した場合の修正でも必ずTDDを行うこと。
- **設計思想**: John Carmack（シンプルさと効率性）、Robert C. Martin（Clean Architecture）、Rob Pike（簡潔性）の思想を意識
- **ドキュメント**: iOS開発経験のないプログラマーが理解し、自力で開発できるレベルの説明を提供

### 開発プロセス
** 以下に必ず従ってください **
- 上記開発方針を守ること。
- 必ず作業ブランチを切り、PRを作成すること。
- push前にはテストが壊れていないか確実に確認すること。
- 機能追加や、内部で利用する技術の変更があれば、[doc](doc)以下の文書に追加・更新を行うこと。

## 設計原則

### John Carmack的アプローチ
- **実用性重視**: 過度な抽象化を避け、動作する最小限のコードから始める
- **パフォーマンス**: バッテリー消費を最小限に抑える位置情報更新頻度の最適化

### Robert C. Martin的アプローチ
- **依存性の逆転**: LocationManagerプロトコルを定義し、テスト可能性を確保
- **単一責任原則**: 各クラス/構造体は明確な単一の責任を持つ
- **境界の明確化**: ビジネスロジックとUIを分離

### Rob Pike的アプローチ
- **シンプルさ**: 「シンプルであることは複雑であることよりも難しい」
- **明確性**: コードは書かれるよりも読まれることが多い
- **少ないほど豊か**: 機能を追加する前に、本当に必要か検討

## テスト戦略

### TDDサイクル
1. **Red**: 失敗するテストを書く
2. **Green**: テストを通す最小限の実装
3. **Refactor**: コードを改善（テストは通ったまま）

### テスト対象の優先順位
1. ビジネスロジック（位置情報処理、住所変換）
2. 状態管理（地図の設定、表示モード）
3. UI統合テスト（最小限に留める）

### モックとスタブ
- CLLocationManagerのモック化
- CLGeocoderのスタブ化
- UserDefaultsのインメモリ実装

## コード規約

### 命名規則
- **変数/関数**: camelCase
- **型**: PascalCase
- **定数**: 大文字スネークケース（必要に応じて）

### ファイル構成
```
JustAMap/
├── JustAMapApp.swift
├── ContentView.swift
├── MapView.swift
├── Models/
│   ├── LocationManager.swift
│   ├── LocationManagerProtocol.swift
│   ├── AddressFormatter.swift
│   ├── AddressFormat.swift
│   ├── MapViewModel.swift
│   ├── MapControlsViewModel.swift
│   └── SettingsViewModel.swift
├── Services/
│   ├── GeocodeService.swift
│   ├── IdleTimerManager.swift
│   └── MapSettingsStorage.swift
├── Views/
│   ├── AddressView.swift
│   ├── MapControlsView.swift
│   └── SettingsView.swift
├── Extensions/
│   └── (現在は空)
└── Assets.xcassets/
    ├── AppIcon.appiconset/
    └── AccentColor.colorset/

JustAMapTests/
├── JustAMapTests.swift
├── LocationManagerTests.swift
├── AddressFormatterTests.swift
├── IdleTimerManagerTests.swift
├── MapControlsViewModelTests.swift
├── MapSettingsStorageTests.swift
├── SettingsViewModelTests.swift
└── TestDoubles/
    └── MockLocationManager.swift

JustAMapUITests/
├── JustAMapUITests.swift
└── JustAMapUITestsLaunchTests.swift
```

## エラーハンドリング戦略

### 位置情報取得エラー
- **権限拒否時**: 設定画面への誘導メッセージを表示、地図は日本全体を表示
- **位置情報取得失敗**: 最後の既知の位置を使用、エラーアイコンを控えめに表示
- **精度が低い場合**: 精度インジケーターを表示（半透明の円で精度範囲を視覚化）

### ネットワークエラー
- **地図タイル読み込み失敗**: キャッシュされたタイルを使用、オフライン表示を明示
- **ジオコーディング失敗**: 緯度経度を表示、リトライボタンを提供
- **タイムアウト**: 3秒でタイムアウト、自動リトライは最大3回まで

### エラーメッセージの原則
- バイク走行中でも読みやすい大きな文字
- 技術的な詳細は避け、ユーザーが取るべき行動を明示
- 自動的に消えるメッセージは最低5秒表示

## パフォーマンス指標

### バッテリー消費
- **目標**: 1時間の連続使用で15%以下のバッテリー消費
- **位置情報更新頻度**:
  - 高速移動時（60km/h以上）: 1秒ごと
  - 中速移動時（20-60km/h）: 2秒ごと
  - 低速/停止時（20km/h未満）: 5秒ごと
- **地図更新**: 有意な移動（10m以上）があった場合のみ

### メモリ使用量
- **上限**: 200MB（地図タイルキャッシュ含む）
- **キャッシュ戦略**: LRUで最大100MBまで地図タイルをキャッシュ
- **メモリ警告時**: 古いタイルから削除、最小50MBは維持

### 起動時間
- **コールドスタート**: 3秒以内に地図表示
- **権限確認**: 非ブロッキングで実行
- **前回の位置**: UserDefaultsに保存し、即座に表示

## UI/UXガイドライン

### タッチターゲット
- **最小サイズ**: 60x60ポイント（グローブ着用を考慮）
- **間隔**: ボタン間は最低20ポイント
- **配置**: 画面端から最低40ポイント内側（握り込み防止）

### 視認性
- **コントラスト比**: 最低7:1（WCAG AAA準拠）
- **文字サイズ**:
  - 住所表示: 24ポイント以上
  - ボタンラベル: 20ポイント以上
- **色使い**: 色のみに依存しない（形状やアイコンも併用）

### 日光下での使用
- **明るさ自動調整**: 環境光センサーと連動
- **高コントラストモード**: 直射日光下では自動的に切り替え
- **反射防止**: 重要な情報は画面中央に配置

### 振動対策
- **デバウンス**: タップは100ms以上の長押しで確定
- **スワイプ無効化**: 意図しない操作を防ぐため、重要な操作はボタンのみ
- **確認不要**: 全ての操作は即座に実行（取り消し可能な操作に限定）

## デバッグとログ戦略

### ログレベル
```swift
enum LogLevel {
    case verbose  // 開発時のみ：全ての位置情報更新
    case debug    // デバッグビルド：主要なイベント
    case info     // リリースビルド：起動、権限変更
    case error    // 常時：エラーのみ
}
```

### クラッシュレポート
- **Crashlytics統合**: 基本的なクラッシュ情報のみ送信
- **個人情報除外**: 位置情報、住所は送信しない
- **オプトイン**: 初回起動時に許可を求める

### テスト用モック位置情報
```swift
// Debug builds only
let testScenarios = [
    "東京駅周辺走行",
    "山間部（GPS精度低下）",
    "トンネル通過（GPS喪失）",
    "高速道路走行"
]
```

## セキュリティとプライバシー

### 位置情報の取扱い
- **保存期間**: 現在位置のみ、履歴は保存しない
- **送信**: 外部サーバーへの送信は一切行わない
- **権限**: 「使用中のみ」で十分（常時追跡は不要）

### データ永続化
- **保存対象**:
  - UI設定（ズームインデックス、地図スタイル、地図の向き）
  - デフォルト設定（デフォルトズームレベル、デフォルト地図スタイル、デフォルト地図の向き）
  - 住所表示フォーマット設定
- **保存しない**:
  - 位置情報（緯度経度）
  - 移動履歴
  - 検索履歴（検索機能自体がない）
  - 住所情報

### サードパーティ
- **使用ライブラリ**: Apple純正フレームワークのみ
- **広告/トラッキング**: 一切使用しない
- **アナリティクス**: 実装していない

## 将来の拡張予定

> **メンテナンス指示**: 各機能が実装されIssueがCloseされた際は、該当項目を「実装済み機能」セクションに移動し、実装日とPR番号を記録してください。

### North Up / Heading Up
- North Up / Heading Up 切り替え時の回転 ([Issue #1](https://github.com/skoji/just-a-map/issues/1))

### 多言語化
- 日本語に加えて、英語 ([Issue #2](https://github.com/skoji/just-a-map/issues/2))

### 音声操作
- 「ズームイン/アウト」
- 「ノースアップ/ヘディングアップ」
- 「標準地図/航空写真」
- ([Issue #4](https://github.com/skoji/just-a-map/issues/4))

### その他
- Apple Watchとの連携 ([Issue #5](https://github.com/skoji/just-a-map/issues/5))
- CarPlay対応 ([Issue #6](https://github.com/skoji/just-a-map/issues/6))

## 実装済み機能

> **記録形式**: 機能名 (実装日: YYYY-MM-DD, PR: #番号)

### 設定画面
- デフォルトズームレベル、地図の種類、地図の向きの設定
- 住所表示フォーマット選択（標準、詳細、シンプル）
- 設定の永続化とアプリ起動時の適用
- (実装日: 2025-01-06, PR: #7, [Issue #3](https://github.com/skoji/just-a-map/issues/3))

### 地図スクロール時の中心点表示と住所表示
- 追従モード状態管理（isFollowing）
- 地図操作による追従モード解除
- 地図中心にクロスヘア（十字マーク）表示
- デバウンス処理付き中心点住所取得（300ms）
- 現在位置/地図中心の住所表示切り替え
- 現在位置ボタンの視覚的フィードバック（パルスアニメーション）
- (実装日: 2025-01-06, PR: #未定, [Issue #8](https://github.com/skoji/just-a-map/issues/8))

## 参考リソース
- [Apple MapKit Documentation](https://developer.apple.com/documentation/mapkit/)
- [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)
- [t-wadaのTDD解説](https://gihyo.jp/dev/serial/01/tdd)
- [iOS Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)

---

このドキュメントは生きたドキュメントとして、開発の進行に応じて更新されることを前提としています。
