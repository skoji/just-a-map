# トラブルシューティングガイド

段階1の実装で実際に遭遇した問題と、その解決方法をまとめます。

## 目次

1. [ビルドエラー](#ビルドエラー)
2. [実行時エラー](#実行時エラー)
3. [位置情報関連](#位置情報関連)
4. [UI関連](#ui関連)
5. [テスト関連](#テスト関連)

## ビルドエラー

### 1. Info.plistの重複エラー

**エラーメッセージ：**
```
Multiple commands produce '.../JustAMap.app/Info.plist'
```

**原因：**
- カスタムInfo.plistファイルと自動生成の設定が競合

**解決方法：**
1. カスタムInfo.plistを削除
2. Build Settingsで`GENERATE_INFOPLIST_FILE = YES`を確認
3. Info.plistの設定は`INFOPLIST_KEY_*`で指定

```
// Build Settingsに追加
INFOPLIST_KEY_NSLocationWhenInUseUsageDescription = "現在地を地図の中心に表示するために位置情報を使用します"
```

### 2. MapKit APIの非推奨警告

**警告メッセージ：**
```
'init(coordinateRegion:interactionModes:showsUserLocation:userTrackingMode:)' was deprecated in iOS 17.0
```

**原因：**
- iOS 17で新しいMap APIが導入された

**解決方法：**

旧API：
```swift
Map(coordinateRegion: $viewModel.region,
    showsUserLocation: true,
    userTrackingMode: .constant(.follow))
```

新API：
```swift
Map(position: $mapPosition) {
    UserAnnotation()
}
.mapControls {
    MapCompass()
    MapScaleView()
}
```

### 3. MKCoordinateRegionがEquatableに準拠していない

**エラーメッセージ：**
```
Instance method 'onChange(of:perform:)' requires that 'MKCoordinateRegion' conform to 'Equatable'
```

**解決方法：**
`onChange`の代わりに`onReceive`を使用：

```swift
// エラーになる
.onChange(of: viewModel.region) { _ in }

// 正しい方法
.onReceive(viewModel.$region) { newRegion in }

// または新APIの場合
.onMapCameraChange { context in }
```

## 実行時エラー

### 1. CLLocationManager did fail with error: Error Domain=kCLErrorDomain Code=1

**エラーの意味：**
- Code=1: 位置情報サービスへのアクセスが拒否されている

**確認事項：**
1. Info.plistに権限説明が設定されているか
2. シミュレータの Settings > Privacy > Location Services がオンか
3. アプリに位置情報の権限が付与されているか

**解決方法：**
1. アプリを削除して再インストール
2. シミュレータをリセット：Device > Erase All Content and Settings

### 2. CLLocationManager did fail with error: Error Domain=kCLErrorDomain Code=0

**エラーの意味：**
- Code=0 (locationUnknown): 一時的に位置情報が取得できない

**特徴：**
- シミュレータで頻繁に発生
- 実機ではほとんど発生しない
- 位置情報は正常に更新される

**解決方法：**
このエラーを無視する処理を追加：

```swift
func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    if let clError = error as? CLError {
        switch clError.code {
        case .locationUnknown:
            // Code 0: 一時的なエラーなので無視
            print("Temporary location error - ignoring")
            return
        case .denied:
            // 権限拒否は適切に処理
            delegate?.locationManager(self, didFailWithError: LocationError.authorizationDenied)
        default:
            // その他のエラー
            delegate?.locationManager(self, didFailWithError: LocationError.locationUpdateFailed(clError.localizedDescription))
        }
    }
}
```

## 位置情報関連

### 1. 位置情報が更新されない

**原因：**
- シミュレータで位置情報が設定されていない
- 権限が付与されていない

**解決方法：**
1. シミュレータメニュー：Features > Location > Apple
2. または Custom Location で緯度経度を指定

### 2. エラーメッセージが消えない

**問題：**
「位置情報の取得に失敗しました」が表示され続ける

**原因：**
- 位置情報が正常に取得できてもエラーがクリアされない

**解決方法：**
位置情報取得成功時にエラーをクリア：

```swift
nonisolated func locationManager(_ manager: LocationManagerProtocol, didUpdateLocation location: CLLocation) {
    Task { @MainActor in
        self.userLocation = location
        // エラーをクリア（権限拒否以外）
        if self.locationError != nil && self.locationError != .authorizationDenied {
            self.locationError = nil
        }
    }
}
```

## UI関連

### 1. 地図が現在地に追従しない

**原因：**
- 新しいMapKit APIでの実装が必要

**解決方法：**
```swift
// 位置情報が更新されたら地図を更新
.onReceive(viewModel.$userLocation) { newLocation in
    if viewModel.isFollowingUser, let location = newLocation {
        withAnimation {
            mapPosition = .region(MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        }
    }
}
```

### 2. ボタンが小さすぎる

**問題：**
バイクのグローブを着用した状態でタップしづらい

**解決方法：**
最小60x60ポイントのタップターゲット：

```swift
Button(action: { }) {
    Image(systemName: "location.fill")
        .font(.title2)
        .frame(width: 60, height: 60)  // 最小サイズ
        .background(Color.blue)
        .clipShape(Circle())
}
```

## テスト関連

### 1. テストがコンパイルエラー

**エラー：**
```
Cannot convert value of type 'CLLocationDegrees?' to expected argument type 'CLLocationDegrees'
```

**原因：**
オプショナル型の扱いが不適切

**解決方法：**
```swift
// エラーになる
XCTAssertEqual(mockDelegate.lastReceivedLocation?.coordinate.latitude, expected, accuracy: 0.0001)

// 正しい方法
XCTAssertNotNil(mockDelegate.lastReceivedLocation)
XCTAssertEqual(mockDelegate.lastReceivedLocation!.coordinate.latitude, expected, accuracy: 0.0001)
```

### 2. テスト実行時のデバイス指定エラー

**エラー：**
```
Unable to find a device matching the provided destination specifier
```

**解決方法：**
利用可能なデバイスを確認：
```bash
xcodebuild -showdestinations -scheme JustAMapTests
```

正しいデバイスを指定：
```bash
xcodebuild test -scheme JustAMapTests -destination 'platform=iOS Simulator,name=iPhone 16'
```

## デバッグのコツ

### 1. エラーの詳細を出力

```swift
print("Location error: \(clError.code.rawValue) - \(clError.localizedDescription)")
```

### 2. 状態の確認

```swift
print("Authorization status: \(locationManager.authorizationStatus.rawValue)")
print("Is updating location: \(isUpdatingLocation)")
print("User location: \(userLocation?.coordinate ?? CLLocationCoordinate2D())")
```

### 3. シミュレータのログ確認

Xcodeの下部のデバッグエリアで、アプリのログとシステムログを確認できます。

## まとめ

多くの問題は以下が原因です：

1. **権限設定の不備**
2. **新旧APIの混在**
3. **シミュレータ特有の挙動**
4. **非同期処理の扱い**

これらを理解することで、トラブルシューティングが効率的に行えます。