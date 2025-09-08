---
title: Speed does not become 0 when stopped with speed display ON
labels: bug, speed, ios, corelocation
status: open
---

## Summary

When speed display is ON, after coming to a stop the speed sometimes does not drop to 0 and the previous non-zero value remains displayed.

## Expected Behavior

- When stopped, speed should display as 0.
- Even if CoreLocation reports an invalid speed (`speed = -1`), the app should treat it as 0 when stopped.

## Actual Behavior

- After stopping, the previously displayed speed persists for a while.
- Because `CLLocationManager.pausesLocationUpdatesAutomatically = false` when speed display is ON, `locationManagerDidPauseLocationUpdates` is not called and there is no chance to reset to 0.

## Root Cause Hypothesis

- In `MapViewModel.locationManager(_:didUpdateLocation:)`, when `location.speed < 0` (invalid), the code keeps the previous valid value instead of updating.
- With speed display ON, automatic pausing is disabled, so there is no event to force-reset speed to 0 while stationary.

## Fix Plan (TDD)

1. Add a failing test (Red)
   - Given speed display ON
   - After receiving a valid speed (e.g., 10 m/s), when receiving an invalid speed (-1), speed becomes 0.
2. Implement (Green)
   - When `location.speed < 0` and speed display is ON, set `currentSpeed = 0`.
   - Preserve existing behavior for speed display OFF: ignore invalid speed and keep the last valid value.
3. Refactor as needed.

## Impact

- Only the speed update logic in `MapViewModel`.
- Existing tests assume speed display OFF; unaffected. New tests will cover the ON case.

## Checklist

- [ ] With speed display ON, speed becomes 0 when stopped
- [ ] With speed display OFF, invalid speed is still ignored
- [ ] Unit display (km/h, mph) remains unchanged

## Notes

- CoreLocation `CLLocation.speed` is in m/s and returns `-1` when invalid

---

Implementation branch: `fix/speed-zero-when-stopped`
PR: not yet created

