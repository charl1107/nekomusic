# Fix 5: Desktop Progress Incremental

**Date:** 2026-09-19
**File:** `lib/services/download_service_helper.dart`

## Problem
Desktop downloads showed no incremental progress — the UI circle jumped from 0% directly to 100%.

## Root Cause
`downloadFile()` used `response.pipe(sink)` which transfers the entire response body in one shot, giving no opportunity to report intermediate progress.

## Fix
Replaced `response.pipe(sink)` with chunk-based streaming using `await for (final chunk in response)`. When `contentLength` is known (> 0), each chunk is written and progress is reported as `receivedBytes / totalBytes`. When unknown, falls back to `pipe` and reports 1.0 on completion.

Also improved `saveToDeviceFile()`:
- Added `try/catch` with descriptive error wrapping
- Null check on downloads directory
- Sanitized filename to strip illegal characters (`<>:"/\|?*`)

## Verification
```
flutter analyze lib/services/download_service_helper.dart
Analyzing download_service_helper.dart...
No issues found!
```

## Status: DONE
