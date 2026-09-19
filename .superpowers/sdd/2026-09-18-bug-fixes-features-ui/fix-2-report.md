# Fix 2: Web Download Broken - Mark as Browser-Only

**Status:** DONE

## Changes

### lib/services/download_service_web.dart

Replaced XHR-based `downloadFile` (which discarded response data) with direct browser download via `AnchorElement`. Removed unused `dart:async` import.

- Old: XHR fetch with progress listener, no response handling, no actual file save
- New: Creates anchor element, triggers browser download, reports 1.0 progress

### lib/services/download_service.dart

Added clarifying comments about platform-specific download behavior:
- Web: triggers browser download (no local cache)
- Mobile/Desktop: downloads to app documents directory

## Verification

`flutter analyze` - 0 errors, 16 pre-existing warnings/infos (none in modified files)

## Concerns

None. The existing `saveToDeviceFile` method already had the correct browser download pattern; `downloadFile` now matches it.
