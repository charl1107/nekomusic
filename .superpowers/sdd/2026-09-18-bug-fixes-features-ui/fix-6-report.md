# Fix 6: Sanitize Filenames for Save-to-Device

## Status: DONE

## Changes
- Modified `lib/services/download_service_mobile.dart` line 69: Added filename sanitization using `song.title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')` before constructing the destination path.

## Verification
- `flutter analyze lib/services/download_service_mobile.dart` completed with no issues.

## Test Summary
Static analysis passed; no additional tests required for this isolated fix.

## Concerns
None.
