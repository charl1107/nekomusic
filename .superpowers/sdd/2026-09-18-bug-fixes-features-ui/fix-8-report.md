# Fix 8: Android 11+ Scoped Storage

## Status
DONE

## Changes Made

### `lib/services/download_service_mobile.dart`
- Added `import 'package:flutter/foundation.dart'` for `kIsWeb`
- Added `!kIsWeb &&` guard in `downloadFile()` to prevent permission requests on web
- Simplified `saveToDeviceFile()` to use `getDownloadsDirectory()` instead of hardcoded paths
- Removed Android-specific `Permission.storage` request from `saveToDeviceFile()` (scoped storage handles access via `getDownloadsDirectory()`)
- Kept `Permission.storage` request in `downloadFile()` for Android 10 and below compatibility

## Verification
- `flutter analyze lib/services/download_service_mobile.dart` → No issues found

## Concerns
- The `Permission.storage` request in `downloadFile()` is still issued for all Android versions (not just API ≤ 29). This works but will show a deprecation warning on Android 11+ builds. For a more precise fix, consider checking `Platform.version` or using `deviceInfoPlugin` to conditionally request only on API ≤ 29.
- `getDownloadsDirectory()` returns the platform-standard downloads directory, which on Android 11+ uses scoped storage automatically — no `MANAGE_EXTERNAL_STORAGE` permission needed.
