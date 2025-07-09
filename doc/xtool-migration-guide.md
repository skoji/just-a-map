# xtool Migration Guide

## 概要

JustAMapプロジェクトは、XcodeプロジェクトからxtoolベースのSwiftPMワークスペースへ移行しました。これにより、Linux、WSL、macOSでのクロスプラットフォーム開発が可能になります。

## 新しいプロジェクト構造

```
just-a-map/
├── Package.swift           # SwiftPMマニフェスト
├── xtool.yml              # xtool設定ファイル
├── Sources/
│   └── JustAMap/          # メインターゲット
│       ├── JustAMapApp.swift  # @mainエントリポイント
│       ├── ContentView.swift
│       ├── MapView.swift
│       ├── Models/
│       ├── Services/
│       ├── Views/
│       ├── Extensions/
│       └── Resources/
│           └── Assets.xcassets
├── Tests/
│   └── JustAMapTests/     # テストターゲット
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

```bash
# シミュレータでビルドと実行
xtool dev run --simulator

# 実機でビルドと実行（デバイスのUDIDが必要）
xtool dev run --udid <device-udid>

# デバッグ/リリース設定
xtool dev run --simulator --configuration debug    # デフォルト
xtool dev run --simulator --configuration release

# ビルド成果物
# xtool/JustAMap.app/ に生成されます
```

### テスト実行

現在、iOSアプリのテストはSwiftPMでは直接実行できません。以下の方法を使用します：

**方法1: Xcodeを使用（推奨）**
```bash
# Xcodeで開く
open Package.swift
# Cmd+U でテスト実行
```

**方法2: xcodebuildを使用**
```bash
xcodebuild test -scheme JustAMap -destination 'platform=iOS Simulator,name=iPhone 16'
```

**注意**: `swift test`コマンドはmacOS向けビルドを試みるため、iOS専用アプリでは使用できません。

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
   xtool dev run --simulator
   ```

2. **リソースが見つからない場合**
   - `Sources/JustAMap/Resources/`にリソースが正しく配置されているか確認
   - Package.swiftでリソースが`.process("Resources")`として定義されているか確認

3. **xtool.ymlエラー**
   - ファイル名が`xtool.yml`（`.yaml`ではない）であることを確認
   - 最小構成: `version: 1`と`bundleID: com.example.JustAMap`
   - Package.swiftでリソースが正しく定義されているか確認

### テストエラー

1. **テストが見つからない場合**
   - テストファイルが`Tests/JustAMapKitTests/`に配置されているか確認
   - import文が`@testable import JustAMapKit`になっているか確認

## 移行の利点

1. **クロスプラットフォーム対応**: Linux、WSL、macOSで開発可能
2. **CI/CD簡素化**: Xcodeなしでビルド・テスト可能
3. **依存関係管理**: SwiftPMによる統一的な依存関係管理
4. **開発環境の一貫性**: xtoolによる統一的なビルド設定

## 今後の作業

- CI/CD設定の完全な移行
- Linux/WSL環境でのテスト
- パフォーマンス最適化