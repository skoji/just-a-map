# xtool Migration Guide

## 概要

JustAMapプロジェクトは、XcodeプロジェクトからxtoolベースのSwiftPMワークスペースへ移行しました。これにより、Linux、WSL、macOSでのクロスプラットフォーム開発が可能になります。

## 新しいプロジェクト構造

```
just-a-map/
├── Package.swift           # SwiftPMマニフェスト
├── xtool.yaml             # xtool設定ファイル
├── Sources/
│   ├── JustAMapKit/       # ライブラリターゲット
│   │   ├── ContentView.swift
│   │   ├── MapView.swift
│   │   ├── Models/
│   │   ├── Services/
│   │   ├── Views/
│   │   ├── Extensions/
│   │   └── Resources/
│   │       └── Assets.xcassets
│   └── JustAMapApp/       # 実行可能ターゲット
│       └── JustAMapApp.swift
└── Tests/
    └── JustAMapKitTests/  # テストターゲット
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

### ビルドコマンド

```bash
# デバッグビルド
xtool build

# リリースビルド
xtool build --configuration release

# または、設定済みスクリプトを使用
xtool run build
```

### テスト実行

```bash
# 全テストを実行
xtool test

# または、設定済みスクリプトを使用
xtool run test

# 特定のテストだけを実行
xtool test --filter JustAMapKitTests.LocationManagerTests
```

### その他のコマンド

```bash
# クリーン
xtool clean
# または
xtool run clean

# コードフォーマット
xtool run format
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
    
    - name: Build
      run: xtool build --configuration release
    
    - name: Test
      run: xtool test
```

## トラブルシューティング

### ビルドエラー

1. **モジュールが見つからない場合**
   ```bash
   xtool clean
   rm -rf .build
   xtool build
   ```

2. **リソースが見つからない場合**
   - `Sources/JustAMapKit/Resources/`にリソースが正しく配置されているか確認
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