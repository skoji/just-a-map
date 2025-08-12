# Internationalization Implementation Guide

## Overview

This guide explains the internationalization implementation that added English support to the just a map application.

## Implemented Features

### 1. Basic Internationalization Infrastructure

#### Localizable.strings Files
- `Resources/Localization/ja.lproj/Localizable.strings` - Japanese resources
- `Resources/Localization/en.lproj/Localizable.strings` - English resources

#### Localization Helper with String Extension
- `Sources/JustAMap/Extensions/String+Localization.swift`
- `"key".localized` - Basic localization
- `"key".localized(with: args...)` - Localization with formatting

### 2. Internationalization of Target Text

#### AddressView (Address Display View)
- "住所を取得中..." → "address.loading"
  - Japanese: "住所を取得中..."
  - English: "Loading address..."

#### SettingsView (Settings Screen)
- "設定" → "settings.title"
- "閉じる" → "settings.close"
- "デフォルト設定" → "settings.default_settings"
- "デフォルトズームレベル" → "settings.default_zoom_level"
- "地図の種類" → "settings.map_type"
- "デフォルトでNorth Up" → "settings.default_north_up"
- "表示設定" → "settings.display_settings"
- "住所表示フォーマット" → "settings.address_format"

#### AddressFormat (Address Format)
- "標準" → "address_format.standard"
- "詳細" → "address_format.detailed"
- "シンプル" → "address_format.simple"
- Format descriptions are also fully localized

#### MapStyle (Map Style)
- "標準" → "map_style.standard"
- "航空写真+地図" → "map_style.hybrid" (English: "Satellite + Map")
- "航空写真" → "map_style.imagery" (English: "Satellite")

#### LocationError (Location Information Errors)
- All error messages are localized
- Support for formatted error messages as well

#### AddressFormatter (Address Formatter)
- "現在地" → "address.current_location" (English: "Current Location")

### 3. Internationalized Address Format

#### Automatic Switching Based on Locale Detection
```swift
let currentLanguage = Locale.current.language.languageCode?.identifier ?? "en"
```

#### Postal Code Format
- **Japanese environment**: 〒100-0001
- **English/International environment**: 100-0001 (plain format)

#### Address Component Order
- **Japanese**: Prefecture → City/Ward/Town/Village/District → Ward/City/Town/Village
- **English/International**: City/Town/Village → State/Prefecture → Country (comma-separated)

### 4. Test Implementation

#### LocalizationTests.swift
- String extension tests
- AddressFormat localization tests
- MapStyle localization tests
- LocationError localization tests
- AddressFormatter internationalization support tests

## Technical Details

### Package.swift Configuration
```swift
.target(
    name: "JustAMap",
    dependencies: [],
    path: "Sources/JustAMap",
    resources: [
        .process("../../Resources/Localization")
    ]
),
```

### Usage Examples

#### Basic String Localization
```swift
Text("settings.title".localized)
```

#### Formatted String Localization
```swift
"location.error.update_failed".localized(with: errorMessage)
```

#### Conditional Localization (Used in Address Formatter)
```swift
let currentLanguage = Locale.current.language.languageCode?.identifier ?? "en"
if currentLanguage == "ja" {
    // Japanese-specific processing
} else {
    // International (English) processing
}
```

## Extending Internationalization

### Steps to Add New Languages

1. **Create New .lproj Directory**
   ```
   Resources/Localization/[language_code].lproj/
   ```

2. **Create Localizable.strings File**
   Translate based on existing English version

3. **Update Package.swift** (usually unnecessary, resources are auto-detected)

4. **Adjust Address Format**
   Add locale-specific processing in AddressFormatter if needed

### Steps to Add New Strings

1. **Add the same key to all Localizable.strings files**
2. **Replace non-localized strings in code**
   ```swift
   "New text" → "new.text.key".localized
   ```
3. **Add test cases**

## Best Practices

### Key Naming Convention
- Use dot-separated hierarchical structure
- Example: `"settings.display_settings"`, `"address_format.standard"`

### Using Comments
Use section comments in Localizable.strings files:
```
/* SettingsView */
"settings.title" = "Settings";
```

### Format Strings
- Use format specifiers like %@, %d appropriately
- Use positional specifiers when argument order differs by language

### Address Format Internationalization
- Change order of address components by locale
- Change separators (Japanese: none, English: comma)
- Adjust postal code prefixes

## Notes

### UI Element Size Adjustment
- English tends to be longer than Japanese, so provide sufficient margin in UI layouts
- Pay special attention to button text and setting item names

### Cultural Considerations
- Address formats depend on culture, so adapt to customs of each country
- Date, time, and number formats also need future consideration

### Test Environment
- Test by changing simulator language settings
- Real device testing is also important

## iOS App Language Settings

### CFBundleLocalizations Configuration

With the following settings in Info.plist, the "Preferred Language" option appears in iOS "Settings" → "Apps" → "JustAMap":

```xml
<key>CFBundleLocalizations</key>
<array>
    <string>ja</string>
    <string>en</string>
</array>
<key>CFBundleDevelopmentRegion</key>
<string>en</string>
```

### Permission Description Internationalization with InfoPlist.strings

Location access permission descriptions are also internationalized:

- `Resources/Localization/en.lproj/InfoPlist.strings`
- `Resources/Localization/ja.lproj/InfoPlist.strings`

```
/* Location Permission Descriptions */
"NSLocationWhenInUseUsageDescription" = "We use location to display your current position on the map and show your address.";
```

### User Experience

1. **System Language Following**: By default, follows iOS system language settings
2. **App-specific Settings**: Language can be changed for the app alone in "Settings" → "Apps" → "JustAMap" → "Preferred Language"
3. **Immediate Reflection**: Language changes are reflected the next time the app is launched

## Future Improvements

1. **Plural Support**: Support for plurals using NSStringLocalizedStringWithDefaultValue
2. **Right-to-Left Language Support**: Support for Arabic, Hebrew, etc.
3. **Regional Specialization**: Support for regional differences even within the same language
4. **Voice Narration**: Multilingual support for VoiceOver

---

Following this guide, you can efficiently manage and extend the internationalization of the just a map application.