# Task 10: Wire Download in Song Card — Report

## Status: DONE

## Changes Made

- **`flutter_app/lib/widgets/song_card.dart`** — 2 edits:
  1. Added `package:provider` and `download_service.dart` imports.
  2. Replaced the static "Download" `ListTile` with a `Consumer<DownloadService>` that:
     - Shows `CircularProgressIndicator` when `DownloadState.downloading`
     - Shows `Icons.download_done` when `DownloadState.downloaded`
     - Shows `Icons.download` when `DownloadState.idle`
     - On tap: calls `removeDownload` if already downloaded, otherwise calls `downloadSong`, then closes the sheet.

## Verification

- `flutter analyze lib/widgets/song_card.dart` — **No issues found**

## Commits

- `03b0f33` — `feat: wire download action in song card bottom sheet`

## Concerns

None. Implementation matches the task spec exactly and compiles cleanly.
