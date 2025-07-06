# Just a Map - エミュレータでの動作確認手順

## 1. Xcodeでプロジェクトを開く

### 方法A: 新規プロジェクトを作成（推奨）
1. Xcodeを開く
2. "Create New Project" を選択
3. iOS > App を選択して "Next"
4. 以下の設定で作成:
   - Product Name: `JustAMap`
   - Team: あなたのApple Developer Team（なければ個人を選択）
   - Organization Identifier: `com.example`（任意）
   - Interface: `SwiftUI`
   - Language: `Swift`
   - Use Core Data: オフ
   - Include Tests: オン
5. プロジェクトの保存場所をこのディレクトリ（`just-a-map`）に設定

### 方法B: 既存ファイルを使用
1. 作成したプロジェクトに既存のSwiftファイルを追加
2. File > Add Files to "JustAMap"...
3. `JustAMap`フォルダ内の全ファイルを選択（Tests含む）
4. "Copy items if needed" はオフ
5. Target membershipで`JustAMap`にチェック

## 2. Info.plist の設定

プロジェクトナビゲーターで:
1. JustAMap > Info.plist を選択
2. 右クリックして "Open As > Source Code"
3. 以下のキーが含まれていることを確認:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>現在地を地図の中心に表示するために位置情報を使用します</string>
```

## 3. エミュレータの起動と設定

1. Xcodeの上部にあるデバイス選択から任意のiPhoneシミュレータを選択（例: iPhone 15）
2. ▶️ ボタンでビルド&実行
3. アプリが起動したら位置情報の許可ダイアログが表示される
4. "Allow While Using App" を選択

## 4. エミュレータで位置情報をシミュレート

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

- [ ] アプリ起動時に位置情報許可ダイアログが表示される
- [ ] 許可後、現在地が地図の中心に表示される
- [ ] 位置が移動すると地図も追従する
- [ ] 地図を手動でドラッグすると追従が解除される
- [ ] 右下の位置ボタンをタップすると現在地に戻る
- [ ] 位置情報を拒否した場合、エラーバナーが表示される
- [ ] エラーバナーの「設定」ボタンで設定アプリが開く

## 6. デバッグTips

### 位置情報が取得できない場合:
1. エミュレータをリセット: Device > Erase All Content and Settings...
2. Xcodeをクリーンビルド: Product > Clean Build Folder
3. エミュレータの位置情報設定を確認: Settings > Privacy & Security > Location Services

### コンソールログの確認:
Xcodeの下部にあるデバッグエリアでログを確認できます。

## 7. 実機でのテスト（オプション）

実機でテストする場合:
1. iPhone/iPadをMacに接続
2. デバイス選択で接続したデバイスを選択
3. 初回は開発者として信頼する設定が必要:
   - 設定 > 一般 > VPNとデバイス管理 > デベロッパAPP
4. 実際のGPSで動作確認可能