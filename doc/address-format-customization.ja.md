# 住所表示フォーマットのカスタマイズ

## 概要

JustAMapでは、住所表示を3つのフォーマット（標準、詳細、シンプル）から選択できます。2025年1月7日の更新で、標準フォーマットの動作を改善し、より見やすい表示を実現しました。

## 住所表示フォーマット

### 標準フォーマット (Standard)
施設名がある場合は施設名を、ない場合は「都道府県 市区町村」を表示します。

**表示例：**
- 施設の場合: `東京駅`
- 通常の住所: `東京都 千代田区`
- 郡がある場合: `神奈川県 横浜市`

### 詳細フォーマット (Detailed)
完全な住所情報を表示し、さらに詳細情報を2行目に表示します。

**表示例：**
```
東京都千代田区丸の内1-9-1
東京駅 / 千代田区 / 東京都 / 日本
```

### シンプルフォーマット (Simple)
市区町村のみを表示する最小限のフォーマットです。

**表示例：**
- `千代田区`

## 技術的な実装詳細

### 施設名の判定ロジック

`GeocodeService`では、以下のロジックで施設名を判定しています：

1. **areasOfInterest**のチェック
   - CLPlacemarkの`areasOfInterest`プロパティを確認
   - 地理的大区分（本州、四国、九州、北海道、沖縄）は除外

2. **住所パターンの検出**
   - name属性に以下のパターンが含まれる場合は住所として扱う：
     - 丁目
     - 番地
     - 番
     - 号
     - ハイフン（-）

```swift
let facilityName: String? = {
    if let areas = placemark.areasOfInterest, !areas.isEmpty {
        let area = areas.first!
        // 地理的な大区分は施設名として扱わない
        let geographicTerms = ["本州", "四国", "九州", "北海道", "沖縄"]
        if geographicTerms.contains(area) {
            return nil
        }
        return area
    } else if let name = placemark.name {
        // 番地や丁目を含む場合は施設名ではなく住所として扱う
        let addressPatterns = ["丁目", "番地", "番", "号", "-"]
        let isAddress = addressPatterns.contains { name.contains($0) }
        return isAddress ? nil : name
    }
    return nil
}()
```

### 住所の構築

`AddressFormatter`の`buildFullAddressFromComponents`メソッドでは、個別のコンポーネントから完全な住所を構築します：

1. 都道府県（administrativeArea）
2. 市区町村/郡（subAdministrativeArea）
3. 区市町村（locality）
4. 残りの住所部分（番地など）

この実装により、`fullAddress`プロパティにsubAdministrativeAreaが含まれていない場合でも、正しく住所を構築できます。

## Address構造体

```swift
struct Address: Equatable {
    let name: String?              // 施設名（番地情報は含まない）
    let fullAddress: String?       // 完全な住所
    let postalCode: String?        // 郵便番号
    let locality: String?          // 市区町村
    let subAdministrativeArea: String? // 郡・地区
    let administrativeArea: String? // 都道府県
    let country: String?           // 国
}
```

## 注意事項

### CLPlacemarkの特性

- `areasOfInterest`には予期しない値（例：「本州」）が含まれることがある
- `name`プロパティには施設名だけでなく、詳細な住所が入ることがある
- `subAdministrativeArea`は東京23区などでは通常nilになる

### テストの考慮事項

住所フォーマットのテストでは、以下のケースを考慮する必要があります：

1. 施設名がある場合とない場合
2. subAdministrativeAreaがある場合とない場合
3. 最小限の情報しかない場合
4. 地理的大区分が含まれる場合

## 関連ファイル

- `/JustAMap/Models/AddressFormatter.swift` - 住所フォーマット処理
- `/JustAMap/Services/GeocodeService.swift` - ジオコーディングと施設名判定
- `/JustAMapTests/AddressFormatterTests.swift` - テストケース

## 参考情報

- [Apple CLPlacemark Documentation](https://developer.apple.com/documentation/corelocation/clplacemark)
- [Apple CLGeocoder Documentation](https://developer.apple.com/documentation/corelocation/clgeocoder)