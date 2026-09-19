# Fix 3: Delete Files on removeDownload

## Status: DONE

## Summary

`removeDownload()` previously only removed metadata from Hive, leaving actual `.mp3` files on disk. Files accumulated indefinitely.

## Changes

| File | Change |
|------|--------|
| `lib/services/download_service_mobile.dart` | Added `deleteFile(String songId)` — deletes `<songId>.mp3` from app documents directory |
| `lib/services/download_service_helper.dart` | Added `deleteFile(String songId)` — same implementation for desktop/helper path |
| `lib/services/download_service.dart` | Updated `removeDownload()` to call `deleteFile(songId)` before removing metadata |

## Verification

`flutter analyze` — 0 new errors, 0 new warnings. All 16 issues are pre-existing.

## Test Summary

No unit tests modified. Manual verification: removing a download now deletes both metadata and file from disk.

## Concerns

None — deletion errors are silently caught per spec, matching the pattern used by other file operations in this codebase.
