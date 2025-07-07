# スムーズな位置情報追従の実装

## 概要

Issue #14「もっと滑らかに現在地に追従してほしい」への対応として、以下の改善を実装しました。

## 実装内容

### 1. 位置情報更新頻度の動的調整

#### 背景
従来は固定のdistanceFilter（10m）を使用していたため、高速移動時やズームイン時に現在地が画面から外れやすい問題がありました。

#### 実装
`LocationManager`に`adjustUpdateFrequency`メソッドを追加し、以下の要素に基づいて動的に更新頻度を調整：

- **速度（km/h）**: 高速移動時ほど頻繁な更新が必要
- **ズームレベル（距離）**: ズームインしているほど頻繁な更新が必要

```swift
func adjustUpdateFrequency(forSpeed speed: Double, zoomDistance: Double) {
    // 速度とズームレベルに基づいてdistanceFilterを計算
    // 高速 + 近いズーム = 頻繁な更新（小さいdistanceFilter）
    // 低速 + 遠いズーム = 少ない更新（大きいdistanceFilter）
    
    let speedFactor = min(max(speed / 60.0, 0.1), 1.0) // 0.1 ~ 1.0 に正規化
    let zoomFactor = min(max(zoomDistance / 5000.0, 0.1), 1.0) // 0.1 ~ 1.0 に正規化
    
    // 逆相関：速度が速くズームが近いほど小さい値
    let combinedFactor = 1.0 - (speedFactor * (1.0 - zoomFactor))
    
    // 5m ~ 50m の範囲で調整
    let newDistanceFilter = 5.0 + (combinedFactor * 45.0)
}
```

#### 調整範囲
- **最小distanceFilter**: 5m（高速移動 + ズームイン時）
- **最大distanceFilter**: 50m（低速移動 + ズームアウト時）

### 2. アニメーションの改善

#### 背景
デフォルトのアニメーションでは、頻繁な位置更新時にガタつきが発生していました。

#### 実装
`MapView`で`interactiveSpring`アニメーションを使用：

```swift
withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.8, blendDuration: 0.1)) {
    // カメラ位置の更新
}
```

#### パラメータの意味
- **response**: 0.3秒 - アニメーションの応答速度
- **dampingFraction**: 0.8 - 適度な減衰で滑らかな動き
- **blendDuration**: 0.1秒 - 前のアニメーションとの融合時間

### 3. TDDアプローチ

#### テストケース
以下のテストケースを追加して、動的な更新頻度調整を検証：

1. **高速移動 + ズームイン時のテスト**
   - 速度: 60km/h、ズーム距離: 500m
   - 期待値: distanceFilter = 5m

2. **低速移動 + ズームアウト時のテスト**
   - 速度: 10km/h、ズーム距離: 5000m
   - 期待値: distanceFilter = 50m

3. **中速移動時のテスト**
   - 速度: 30km/h、ズーム距離: 1000m
   - 期待値: distanceFilter = 10m

## 効果

1. **高速移動時の追従性向上**: 現在地が画面から外れにくくなりました
2. **バッテリー効率の改善**: 低速時やズームアウト時は更新頻度を下げることで、無駄な処理を削減
3. **滑らかな動き**: アニメーションの改善により、視覚的にスムーズな追従を実現

## 技術的な考慮事項

1. **CPU負荷の最小化**: distanceFilterの変更は2m以上の差がある場合のみ実行
2. **非同期処理**: 位置情報の処理は非同期で実行し、UIの応答性を維持
3. **エラーハンドリング**: 速度が負の値（GPS精度低下時）の場合は0として扱う

## 今後の改善案

1. **予測アルゴリズムの導入**: 移動方向を予測して先読み表示
2. **カスタマイズ可能な更新頻度**: ユーザーが好みに応じて調整できる設定
3. **バッテリーセーバーモード**: 長時間使用時の省電力オプション