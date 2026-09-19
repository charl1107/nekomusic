# Fix 1: Permission Denied Silent Fail on Mobile

**Date:** 2026-09-18
**File:** `lib/services/download_service_mobile.dart`
**Line:** 13

## Change

Replaced silent early return with exception throw when storage permission is denied on Android.

**Before:**
```dart
if (!status.isGranted) return;
```

**After:**
```dart
if (!status.isGranted) {
  throw Exception('Storage permission denied');
}
```

## Rationale

The `downloadFile` method silently returned on permission denial, leaving the download state stuck at "downloading" or appearing complete without actual file write. `saveToDeviceFile` already had this exception pattern; `downloadFile` was inconsistent. Throwing propagates the error to `DownloadService` for proper state handling.

## Verification

- `flutter analyze lib/services/download_service_mobile.dart` — **No issues found**
- `saveToDeviceFile` (line 33) already uses the same pattern, confirming consistency

## Status: DONE
