# Task 9: Download Button in Player Screen

## Task Description

Add a download button to the player screen with Spotify-style state feedback.

## Files

- Modify: `flutter_app/lib/screens/player_screen.dart`

## Requirements

### 1. Add download button after song title

After the song title `Text` widget, add:

```dart
const SizedBox(height: 8),
Consumer<DownloadService>(
  builder: (context, downloadService, _) {
    final state = downloadService.getState(song.id);
    return IconButton(
      icon: state == DownloadState.downloading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              state == DownloadState.downloaded
                  ? Icons.download_done
                  : Icons.download,
              color: state == DownloadState.downloaded
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
      onPressed: state == DownloadState.downloading
          ? null
          : () {
              if (state == DownloadState.downloaded) {
                downloadService.removeDownload(song.id);
              } else {
                downloadService.downloadSong(song);
              }
            },
    );
  },
),
```

### 2. Add required imports

```dart
import 'package:provider/provider.dart';
import '../services/download_service.dart';
```

## Context

- DownloadService exists with `getState(String songId)`, `downloadSong(Song song)`, `removeDownload(String songId)` methods (Task 3)
- DownloadState enum has: idle, downloading, downloaded
- PlayerScreen currently shows song title, artist, seek bar, and controls
- The button should show: download icon (idle), spinning progress (downloading), checkmark (downloaded)

## Your Job

1. Read the existing `C:\Users\Administrator\Downloads\nekocMusic\flutter_app\lib\screens\player_screen.dart`
2. Implement exactly what the task specifies
3. Verify the file compiles by running: `cd C:\Users\Administrator\Downloads\nekocMusic\flutter_app; flutter analyze lib/screens/player_screen.dart`
4. Commit your work with a descriptive message
5. Self-review your changes
6. Write your report to: C:\Users\Administrator\Downloads\nekocMusic\.superpowers\sdd\2026-09-17-features\task-9-report.md

## Report Format

Write your full report to the path above, then report back with ONLY:
- **Status:** DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
- Commits created (short SHA + subject)
- One-line test summary
- Your concerns, if any
- The report file path
