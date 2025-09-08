---
title: 速度表示ON時に停止しても速度が0にならない
labels: bug, speed, ios, corelocation
status: open
---

## 概要

速度表示をONにした状態で走行を停止しても、速度が0にならず直前の速度が表示され続けることがある。

## 期待される挙動

- 停止時は速度が0として表示される。
- CoreLocationが無効値（`speed = -1`）を返す場合でも、停止状態を適切に検出して0を表示する。

## 実際の挙動

- 停止後もしばらく速度が前回の値のまま表示される。
- 特に「速度表示ON」により `CLLocationManager.pausesLocationUpdatesAutomatically = false` のため、
  `locationManagerDidPauseLocationUpdates` が呼ばれず、0リセットの契機が発生しない。

## 原因の推定

- `MapViewModel.locationManager(_:didUpdateLocation:)` で `location.speed < 0`（無効値）の場合、
  速度を更新せず「直前の有効値を保持」する実装となっている。
- 速度表示ON時は位置更新の自動一時停止を無効化しているため、停止時に0へリセットする経路が存在しない。

## 修正方針（TDD）

1. 再現テストを追加（Red）
   - 前提: 速度表示ON
   - 有効な速度（例: 10 m/s）を受信後、無効速度（-1）を受信したら速度が0になることを検証
2. 実装（Green）
   - `location.speed < 0` かつ「速度表示ON」のときは `currentSpeed = 0` を設定
   - 既存の「速度表示OFFでは無効値は無視して前回値保持」の挙動は維持
3. リファクタリング（必要に応じて）

## 影響範囲

- `MapViewModel` の速度更新ロジックのみ（UIや他機能への副作用はなし）
- 既存テストは「速度表示OFF」を前提としているため非影響。新規テストでON時の挙動を追加。

## 確認項目

- [ ] 速度表示ON時、停止で0表示になる
- [ ] 速度表示OFF時、無効速度は引き続き無視される
- [ ] 速度単位（km/h, mph）の表示は既存実装通り

## 参考

- CoreLocationの `CLLocation.speed` は m/s で、無効時は `-1` を返す

---

実装ブランチ: `fix/speed-zero-when-stopped`
PR: 未作成

