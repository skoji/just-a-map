# Just a Map

**just a map** - リアルタイムで更新される以外は単なる地図

バイク（オートバイ）のハンドルマウントで使用することを想定した、シンプルで実用的な地図アプリケーション。

## 主な機能

### 段階1（実装済み）
- ✅ 現在位置を中心とした地図表示
- ✅ 位置情報の自動追従（10m以上移動時）
- ✅ 手動で地図を動かすと追従モード解除
- ✅ 現在地に戻るボタン（60x60ptでグローブ対応）
- ✅ 位置情報権限の適切な処理
- ✅ エラー表示と設定画面への誘導

### 段階2（実装済み）
- ✅ 現在位置の住所表示（逆ジオコーディング）
- ✅ 日本の住所フォーマットに対応（都道府県→市区町村→番地）
- ✅ 場所名の優先表示（東京駅など）
- ✅ 郵便番号の表示
- ✅ スリープ防止機能（画面が自動で消えない）
- ✅ バックグラウンド/フォアグラウンド遷移の適切な処理

### 段階3（実装済み）
- ✅ ズームコントロール（12段階の離散的ズームレベル）
  - 建物レベル（200m）から地球レベル（1,000,000m）まで
  - 高度ベースの安定した実装（MapKitの内部変換に影響されない）
  - ズーム制限時のボタングレーアウト表示
- ✅ 地図表示モードの切り替え（標準/ハイブリッド/航空写真）
- ✅ North Up / Heading Up の切り替えボタン（実際の回転は今後実装）
- ✅ 設定の永続化（UserDefaults）
  - ズームレベル（インデックスとして保存）
  - 地図スタイル
  - 地図の向き設定

### その他実装済み機能

- ✅ North Up / Heading Upの切り替え・回転
- ✅ コンパス


## 技術仕様

- **iOS**: 17.0以上
- **フレームワーク**: SwiftUI, MapKit, CoreLocation
- **位置情報精度**: 最高精度（kCLLocationAccuracyBest）
- **更新頻度**: 速度とズームに応じて変化
- **住所取得**: CLGeocoder（逆ジオコーディング）
- **スリープ防止**: UIApplication.shared.isIdleTimerDisabled
- **ズーム実装**: MKMapCamera.distance（高度）ベース

## 開発環境

- Xcode 16.0以上（オプション）
- Swift 5.9以上
- macOS 14.0以上 / Linux / WSL
- iOS Simulator（iOS 18.5推奨）
- xtool（クロスプラットフォームビルドツール）

## セットアップ

### 1. プロジェクトを開く
```bash
git clone <repository-url>
cd just-a-map
```

### 2. ビルドと実行

#### xtoolを使用する場合（推奨）
```bash
# xtoolのインストール
brew install xtool  # macOS
# Linux/WSLの場合は https://github.com/xtool-org/xtool を参照

# Makefileを使用したビルドと実行
make build           # アプリをビルド
make run             # シミュレータで実行
make install DEVICE_ID=<device-id>  # 実機にインストール

# デバイスIDの確認
make devices         # 接続されているデバイス一覧を表示

# その他の便利なコマンド
make test           # テストを実行
make clean          # ビルド成果物をクリーン
make help           # 利用可能なコマンド一覧を表示
```

**注意**: xtoolはAssets.xcassetsをコンパイルできないため、アセットの処理には特別な手順が必要です。Makefileがこれを自動的に処理します。

#### アセットの更新について
アイコンやその他のアセットを変更した場合：
1. macOSで `make compile-assets` を実行してアセットをコンパイル
2. コンパイル済みアセットはGitにコミットされているため、他のプラットフォームでもビルド可能

#### Xcodeを使用する場合
```bash
# SwiftPMプロジェクトとして開く
open Package.swift
```

詳細は[xtool移行ガイド](doc/xtool-migration-guide.ja.md)を参照してください。

### 3. 位置情報の権限設定
アプリ起動時に位置情報の許可ダイアログが表示されるので、「Allow While Using App」を選択

## エミュレータで位置情報をシミュレート

### 位置情報の設定方法:
1. エミュレータのメニューバーから: Features > Location
2. 以下のオプションから選択:
   - **Apple**: Apple本社（カリフォルニア）
   - **City Bicycle Ride**: 自転車での移動をシミュレート
   - **City Run**: ランニングでの移動をシミュレート
   - **Freeway Drive**: 高速道路での移動をシミュレート
   - **Custom Location...**: 任意の緯度経度を入力

### おすすめテストシナリオ:
1. まず "Apple" を選択して基本動作を確認
2. "City Bicycle Ride" でバイク走行に近い動きをテスト
3. Custom Location で日本の位置を設定:
   - 東京駅: 緯度 35.6762, 経度 139.6503
   - 大阪駅: 緯度 34.7024, 経度 135.4959

## 5. 動作確認項目

### 基本機能
- [ ] アプリ起動時に位置情報許可ダイアログが表示される
- [ ] 許可後、現在地が地図の中心に表示される
- [ ] 位置が移動すると地図も追従する
- [ ] 地図を手動でドラッグすると追従が解除される
- [ ] 右下の位置ボタンをタップすると現在地に戻る
- [ ] 位置情報を拒否した場合、エラーバナーが表示される
- [ ] エラーバナーの「設定」ボタンで設定アプリが開く

### 住所表示とスリープ防止
- [ ] 現在地の住所が上部に表示される
- [ ] 移動すると住所が更新される
- [ ] アプリ使用中は画面がスリープしない
- [ ] バックグラウンドに移行するとスリープ防止が解除される

### 地図コントロール
- [ ] ズームイン/アウトボタンで12段階のズームレベルを切り替えられる
- [ ] ズーム限界に達するとボタンがグレーアウトする
- [ ] ピンチ操作後もボタンで確実に次のレベルに移動する
- [ ] 地図スタイルボタンで標準/ハイブリッド/航空写真を切り替えられる
- [ ] North Up/Heading Upボタンが表示される（タップで状態が切り替わる）
- [ ] アプリ再起動時に前回の設定が復元される

## 6. デバッグTips

### 位置情報が取得できない場合:
1. エミュレータをリセット: Device > Erase All Content and Settings...
2. Xcodeをクリーンビルド: Product > Clean Build Folder
3. エミュレータの位置情報設定を確認: Settings > Privacy & Security > Location Services

### コンソールログの確認:
Xcodeの下部にあるデバッグエリアでログを確認できます。ズーム操作時は現在のレベルがコンソールに出力されます。

## テスト

### ユニットテストの実行

#### Makefileを使用する場合（推奨）
```bash
make test
```

#### Xcodeを使用する場合
```bash
open Package.swift
# Xcode内で ⌘+U
```

#### xcodebuildを使用する場合
```bash
xcodebuild test -scheme JustAMap -destination 'platform=iOS Simulator,name=iPhone 16'
```

### 現在のテストカバレッジ
- LocationManagerのプロトコル準拠
- 位置情報の権限処理
- 位置情報更新のデリゲート通知
- エラーハンドリング
- 住所フォーマットの変換（AddressFormatterTests）
- スリープ防止機能（IdleTimerManagerTests）
- 高度ベースズーム機能とマップスタイル切り替え（MapControlsViewModelTests）
  - 12段階のズームレベル管理
  - ズーム制限のテスト
  - 高度からズームインデックスへの変換
- 設定の永続化（MapSettingsStorageTests）
  - ズームインデックスの保存/読み込み

## トラブルシューティング

### 位置情報が取得できない場合
1. シミュレータの位置情報設定を確認: Features > Location
2. Settings > Privacy & Security > Location Services がオンになっているか確認
3. アプリを削除して再インストール

### "kCLErrorDomain Code=0" エラーが表示される場合
これはシミュレータ特有の一時的なエラーで、アプリの動作には影響しません。実機では発生しません。

## ライセンス

このプロジェクトはMITライセンスの下で公開されています。詳細は[LICENSE](LICENSE)ファイルを参照してください。

## 貢献

プルリクエストを歓迎します。大きな変更を行う場合は、まずissueを開いて変更内容について議論してください。

## ドキュメント

より詳細な技術ドキュメントは[doc](doc)ディレクトリを参照してください。
- [段階1実装ガイド](doc/stage1-implementation-guide.ja.md)
- [段階2実装ガイド](doc/stage2-implementation-guide.ja.md)
- [段階3実装ガイド](doc/stage3-implementation-guide.ja.md)
- [iOS開発の基本概念](doc/ios-development-basics.ja.md)
- [トラブルシューティングガイド](doc/troubleshooting-guide.ja.md)
