# Version Management System

## 概要

JustAMapプロジェクトでは、Gitベースの自動バージョン管理システムを採用しています。このシステムは、ビルド時にGitの情報から自動的にバージョン番号を生成し、アプリケーションに埋め込みます。

## システム構成

### 主要コンポーネント

1. **scripts/generate-version.sh**
   - Gitリポジトリから情報を取得
   - バージョン文字列とビルド番号を生成
   - コマンドライン引数で特定の情報を返す

2. **scripts/sync-version-info.sh**
   - ビルド時に実行される
   - `Resources/VersionInfo.plist`を生成
   - Git情報をplist形式に同期

3. **Resources/VersionInfo.plist**
   - ビルド時に生成される
   - Git追跡対象外（.gitignoreに記載）
   - アプリケーションから読み込まれる

4. **SettingsViewModel**
   - VersionInfo.plistからバージョン情報を読み込む
   - 存在しない場合はBundleから取得（フォールバック）

## バージョン番号の構成

### バージョン文字列
```
<major>.<minor>.<patch>+<commit-hash>[.dirty]
```

- **major.minor.patch**: セマンティックバージョニング
- **commit-hash**: 短縮形のGitコミットハッシュ（7文字）
- **.dirty**: 未コミットの変更がある場合に付加

例: `1.0.0+89a1dfd.dirty`

### ビルド番号
- Gitのコミット数を使用
- 自動的にインクリメントされる
- 例: `234`

## ビルドプロセス

1. `make build`または`make test`実行時
2. `sync-version-info.sh`が呼ばれる
3. `generate-version.sh`でGit情報を取得
4. `Resources/VersionInfo.plist`を生成
5. `fix-assets.sh`でアプリバンドルにコピー

## 実装の詳細

### VersionInfo.plistの形式
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0+89a1dfd</string>
    <key>CFBundleVersion</key>
    <string>234</string>
</dict>
</plist>
```

### SettingsViewModelでの読み込み
```swift
// VersionInfo.plistから読み込み
if let versionInfoURL = bundle.url(forResource: "VersionInfo", withExtension: "plist"),
   let data = try? Data(contentsOf: versionInfoURL),
   let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] {
    self.versionInfo = plist
}
```

## 重要な設計判断

### なぜInfo.plistを直接変更しないのか

1. **Git管理の問題**: Info.plistはGit追跡対象のため、ビルドごとに変更されるとリポジトリが汚れる
2. **CI/CDの問題**: 自動ビルドでコミットされていない変更が発生する
3. **開発体験**: 開発中に常にGitステータスがdirtyになる

### ランタイムバージョン情報の利点

1. **クリーンなGitステータス**: ビルド後もリポジトリがクリーン
2. **柔軟性**: ビルド時に動的にバージョン情報を生成
3. **互換性**: 既存のInfo.plist構造を変更不要

## トラブルシューティング

### VersionInfo.plistが見つからない

- 初回ビルド前は存在しない（正常）
- `make build`を実行すると自動生成される
- 手動で作成する必要はない

### バージョン情報が更新されない

1. Gitリポジトリであることを確認
2. `git status`で現在の状態を確認
3. `./scripts/generate-version.sh version-string`で手動確認

### テスト時のバージョン情報

- `MockBundle`を使用してテスト
- `mockResources`プロパティでVersionInfo.plistのURLを設定可能

## 今後の拡張

- リリースタグからの自動バージョン取得
- ビルド環境情報の追加（ブランチ名など）
- バージョン履歴の記録