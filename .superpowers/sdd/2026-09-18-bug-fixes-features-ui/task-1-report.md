# Task 1: Fix saveToDevice Infinite Recursion

**Status:** DONE

## Commit
- `ef7a7e5` - fix: resolve infinite recursion in saveToDevice

## Summary
The `saveToDevice` method in `DownloadService` was calling itself recursively (`saveToDevice(song)`) instead of calling the platform-specific top-level `saveToDevice` function. This caused a StackOverflowError when users tried to save a downloaded song to their device.

## Root Cause
The class method `saveToDevice` shadowed the top-level `saveToDevice` function imported from the platform-specific files (`download_service_helper.dart`, `download_service_mobile.dart`, `download_service_web.dart`). In Dart, when a method and a top-level function share the same name, the method takes precedence within the class scope.

## Fix Applied
Renamed the top-level function in all three platform-specific files from `saveToDevice` to `saveToDeviceFile`:
- `lib/services/download_service_helper.dart` (stub/default)
- `lib/services/download_service_mobile.dart` (Android/iOS implementation)
- `lib/services/download_service_web.dart` (web implementation)

Updated `lib/services/download_service.dart` to call `saveToDeviceFile(song)` instead of `saveToDevice(song)`.

## Verification
- `flutter analyze lib/services/download_service.dart` - No issues found
- Full project analysis shows only pre-existing warnings/infos unrelated to this fix

## Concerns
None. The fix is minimal and targeted. The pre-existing issues in the project (deprecated APIs, unused elements) are unrelated to this change.
