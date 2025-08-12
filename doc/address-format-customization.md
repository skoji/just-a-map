# Address Display Format Customization

## Overview

JustAMap allows users to choose from three address display formats (Standard, Detailed, Simple). With the update on January 7, 2025, we improved the behavior of the Standard format to achieve a more readable display.

## Address Display Formats

### Standard Format
Displays the facility name if available, otherwise displays "Prefecture + City/Ward/Town/Village".

**Display Examples:**
- For facilities: `Tokyo Station`
- For regular addresses: `Tokyo + Chiyoda City`
- When districts exist: `Kanagawa Prefecture + Yokohama City`

### Detailed Format
Displays complete address information and additional details on the second line.

**Display Example:**
```
1-9-1 Marunouchi, Chiyoda City, Tokyo
Tokyo Station / Chiyoda City / Tokyo / Japan
```

### Simple Format
A minimal format that displays only the city/ward/town/village.

**Display Example:**
- `Chiyoda City`

## Technical Implementation Details

### Facility Name Determination Logic

In `GeocodeService`, facility names are determined using the following logic:

1. **Check areasOfInterest**
   - Check the `areasOfInterest` property of CLPlacemark
   - Exclude geographic major divisions (Honshu, Shikoku, Kyushu, Hokkaido, Okinawa)

2. **Address Pattern Detection**
   - If the name attribute contains the following patterns, treat it as an address:
     - Chome (丁目)
     - Banchi (番地)
     - Ban (番)
     - Go (号)
     - Hyphen (-)

```swift
let facilityName: String? = {
    if let areas = placemark.areasOfInterest, !areas.isEmpty {
        let area = areas.first!
        // Don't treat geographic major divisions as facility names
        let geographicTerms = ["Honshu", "Shikoku", "Kyushu", "Hokkaido", "Okinawa"]
        if geographicTerms.contains(area) {
            return nil
        }
        return area
    } else if let name = placemark.name {
        // Treat names containing lot numbers or chome as addresses, not facility names
        let addressPatterns = ["Chome", "Banchi", "Ban", "Go", "-"]
        let isAddress = addressPatterns.contains { name.contains($0) }
        return isAddress ? nil : name
    }
    return nil
}()
```

### Address Construction

The `buildFullAddressFromComponents` method in `AddressFormatter` constructs a complete address from individual components:

1. Prefecture (administrativeArea)
2. City/Ward/Town/Village/District (subAdministrativeArea)
3. Ward/City/Town/Village (locality)
4. Remaining address parts (lot numbers, etc.)

This implementation allows proper address construction even when `subAdministrativeArea` is not included in the `fullAddress` property.

## Address Structure

```swift
struct Address: Equatable {
    let name: String?              // Facility name (excludes lot number information)
    let fullAddress: String?       // Complete address
    let postalCode: String?        // Postal code
    let locality: String?          // City/Ward/Town/Village
    let subAdministrativeArea: String? // District/Region
    let administrativeArea: String? // Prefecture
    let country: String?           // Country
}
```

## Notes

### CLPlacemark Characteristics

- `areasOfInterest` may contain unexpected values (e.g., "Honshu")
- The `name` property may contain not only facility names but also detailed addresses
- `subAdministrativeArea` is usually nil for Tokyo's 23 special wards

### Testing Considerations

When testing address formats, the following cases need to be considered:

1. Cases with and without facility names
2. Cases with and without subAdministrativeArea
3. Cases with minimal information only
4. Cases where geographic major divisions are included

## Related Files

- `/JustAMap/Models/AddressFormatter.swift` - Address format processing
- `/JustAMap/Services/GeocodeService.swift` - Geocoding and facility name determination
- `/JustAMapTests/AddressFormatterTests.swift` - Test cases

## Reference Information

- [Apple CLPlacemark Documentation](https://developer.apple.com/documentation/corelocation/clplacemark)
- [Apple CLGeocoder Documentation](https://developer.apple.com/documentation/corelocation/clgeocoder)