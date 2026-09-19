# Fix 7: Add Download Cancellation

**Status:** DONE

## Summary

Added download cancellation support to the Flutter music app. Users can now cancel in-progress downloads from multiple locations in the UI.

## Changes Made

### `lib/services/download_service.dart`
- Added `import 'package:dio/dio.dart'` for `CancelToken` and `DioException`
- Added `_cancelTokens` map (`Map<String, CancelToken>`) to track active cancel tokens
- Added `isDownloading(String songId)` helper method
- Modified `downloadSong()` to create a `CancelToken`, pass it to `downloadFile()`, and handle `DioException` cancellation
- Added `cancelDownload(String songId)` method that cancels the token, clears state, and notifies listeners
- Moved `notifyListeners()` after error state assignment in catch block

### `lib/services/download_service_mobile.dart`
- Added `CancelToken? cancelToken` named parameter to `downloadFile()`
- Passed `cancelToken` to `dio.download()`
- Fixed null comparison warning (`total > 0` instead of `total != null && total > 0`)

### `lib/services/download_service_helper.dart`
- Added `dynamic cancelToken` parameter to `downloadFile()` for cross-platform compatibility (ignored, since this uses `HttpClient`)
- Fixed null comparison warning

### `lib/services/download_service_web.dart`
- Added `dynamic cancelToken` parameter to `downloadFile()` for cross-platform compatibility (ignored)

### `lib/screens/player_screen.dart`
- Updated download button: tapping during download now calls `cancelDownload()` instead of being disabled
- Added "Cancel download" option in the `_showOptions` bottom sheet when download is in progress

### `lib/screens/downloads_screen.dart`
- Removed unused `_showOptions` method and unused `download_service.dart` import (cleanup)

### `lib/widgets/song_card.dart`
- Added "Cancel download" option in `_showOptions` bottom sheet when download is in progress
- Download/Cancel logic refactored with `if/else` to show either cancel or download option

## Verification

```
flutter analyze
```
Result: No errors, no warnings. Only pre-existing info-level items in unrelated files (search_screen, settings_screen, app_theme).

## Design Decisions

1. **CancelToken lifecycle**: Created in `downloadSong()`, stored in `_cancelTokens` map, removed in `finally` block
2. **Cross-platform**: `CancelToken` parameter added to all platform-specific `downloadFile` implementations with `dynamic` type for non-Dio platforms
3. **UI integration**: Cancel option appears contextually (only when download is in-progress), using orange color to distinguish from destructive actions
4. **DioException handling**: Separated `DioException` catch (for cancel vs other errors) from generic `catch` block
