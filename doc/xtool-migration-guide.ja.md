# xtool Migration Guide

## 概要

JustAMapプロジェクトは、XcodeプロジェクトからxtoolベースのSwiftPMワークスペースへ移行しました。これにより、Linux、WSL、macOSでのクロスプラットフォーム開発が可能になります。

## 新しいプロジェクト構造

```
just-a-map/
├── Package.swift           # SwiftPMマニフェスト
├── xtool.yml              # xtool設定ファイル
├── Info.plist             # アプリ情報（位置情報権限など）
├── Makefile               # ビルド自動化
├── Resources/             # リソースファイル
│   ├── source/           # ソースアセット
│   │   └── Assets.xcassets
│   ├── built/            # コンパイル済みアセット
│   │   ├── Assets.car
│   │   ├── *.png
│   │   └── VersionInfo.plist  # ビルド時生成（.gitignore）
├── Sources/
│   └── JustAMap/          # メインターゲット
│       ├── JustAMapApp.swift  # @mainエントリポイント
│       ├── ContentView.swift
│       ├── MapView.swift
│       ├── Models/
│       ├── Services/
│       ├── Views/
│       └── Extensions/
├── Tests/
│   └── JustAMapTests/     # テストターゲット
├── scripts/               # ビルドスクリプト
│   ├── compile-assets.sh  # アセットコンパイル
│   ├── fix-assets.sh      # アセット配置
│   ├── generate-version.sh # バージョン情報生成
│   └── sync-version-info.sh # VersionInfo.plist同期
└── xtool/                 # ビルド成果物（.gitignoreに追加）
    └── JustAMap.app/      # 生成されたアプリ
```

## ビルド方法

### 前提条件

1. xtoolのインストール:
```bash
# macOS
brew install xtool

# Linux/WSL
curl -L https://github.com/xtool-org/xtool/releases/latest/download/xtool-linux-x86_64 -o /usr/local/bin/xtool
chmod +x /usr/local/bin/xtool
```

2. Swift 5.9以上のインストール

### ビルドと実行

#### Makefileを使用（推奨）

```bash
# アプリをビルド
make build

# シミュレータで実行
make run

# 実機にインストール
make install DEVICE_ID=<device-udid>

# デバイス一覧を確認
make devices

# テストを実行
make test

# クリーンビルド
make clean

# ヘルプを表示
make help
```

#### 手動でのビルド

xtoolの制限により、アセットのコンパイルには追加手順が必要です：

```bash
# 1. アプリをビルド
xtool dev build

# 2. アセットを修正（アイコン表示のため必須）
./scripts/fix-assets.sh

# 3. 実機にインストール
xtool install -u <device-udid> xtool/JustAMap.app
```

### アセットの更新

xtoolはAssets.xcassetsをコンパイルできないため、macOSでの事前コンパイルが必要です：

```bash
# macOSでアセットをコンパイル
make compile-assets

# または手動で実行
./scripts/compile-assets.sh
```

コンパイル済みアセット（Resources/built/）はGitにコミットされているため、他のプラットフォームでもビルド可能です。

### テスト実行

**Makefileを使用（推奨）**
```bash
make test
```

**その他の方法**

1. Xcodeを使用:
```bash
open Package.swift
# Cmd+U でテスト実行
```

2. xcodebuildを使用:
```bash
xcodebuild test -scheme JustAMap -destination 'platform=iOS Simulator,name=iPhone 16'
```

### その他のコマンド

```bash
# クリーンアップ
rm -rf xtool/ .build/

# デバイスリスト確認
xtool devices

# アプリのインストール（.ipaファイル）
xtool install <path-to-ipa>

# アプリの起動
xtool launch --bundle-id com.example.JustAMap
```

## Xcode での開発

Xcodeを使用する場合は、SwiftPMプロジェクトとして開きます：

```bash
open Package.swift
```

または、Xcodeから「File > Open...」でPackage.swiftを選択します。

## CI/CD設定

GitHub Actionsなどで以下のようなワークフローを使用できます：

```yaml
name: Build and Test

on: [push, pull_request]

jobs:
  build:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest]
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Install Swift
      uses: swift-actions/setup-swift@v1
      with:
        swift-version: "5.9"
    
    - name: Install xtool
      run: |
        if [ "$RUNNER_OS" == "Linux" ]; then
          curl -L https://github.com/xtool-org/xtool/releases/latest/download/xtool-linux-x86_64 -o /usr/local/bin/xtool
        else
          brew install xtool
        fi
        chmod +x /usr/local/bin/xtool
    
    - name: Setup xtool (Linux)
      if: runner.os == 'Linux'
      run: |
        # Note: Requires Xcode.xip to be provided
        # See xtool documentation for setup instructions
    
    - name: Build
      run: xtool dev run --simulator --configuration release
    
    - name: Test (macOS only)
      if: runner.os == 'macOS'
      run: xcodebuild test -scheme JustAMap -destination 'platform=iOS Simulator,name=iPhone 16'
```

## トラブルシューティング

### ビルドエラー

1. **ビルドエラー: "No devices are booted"**
   ```bash
   # シミュレータを起動
   xcrun simctl boot "iPhone 16"
   # 再度実行
   make run
   ```

2. **アプリアイコンが表示されない**
   - `make fix-assets`を実行してアセットを修正
   - Resources/built/にAssets.carが存在することを確認
   - macOSで`make compile-assets`を実行してアセットを再コンパイル

3. **リソースが見つからない場合**
   - Resources/source/Assets.xcassetsにアセットが配置されているか確認
   - Package.swiftでリソースが正しく定義されているか確認

4. **xtool.ymlエラー**
   - ファイル名が`xtool.yml`（`.yaml`ではない）であることを確認
   - 最小構成: `version: 1`、`bundleID: com.example.JustAMap`、`infoPath: Info.plist`

### テストエラー

1. **テストが見つからない場合**
   - テストファイルが`Tests/JustAMapTests/`に配置されているか確認
   - import文が`@testable import JustAMap`になっているか確認

## 移行の利点

1. **クロスプラットフォーム対応**: Linux、WSL、macOSで開発可能
2. **CI/CD簡素化**: Xcodeなしでビルド・テスト可能
3. **依存関係管理**: SwiftPMによる統一的な依存関係管理
4. **開発環境の一貫性**: xtoolによる統一的なビルド設定
5. **バージョン管理**: Gitベースの自動バージョン管理システム（詳細は[version-management-system.ja.md](version-management-system.ja.md)を参照）

## 既知の制限事項

1. **アセットカタログ**: xtoolはAssets.xcassetsをコンパイルできないため、macOSでの事前コンパイルが必要
2. **アプリアイコン**: ビルド後にfix-assetsスクリプトの実行が必要
3. **devモード**: `xtool dev`では自動的なアセット修正は行われない

## 今後の作業

- CI/CD設定の完全な移行
- Linux/WSL環境でのテスト
- パフォーマンス最適化
- xtoolのアセットカタログサポートの改善待ち