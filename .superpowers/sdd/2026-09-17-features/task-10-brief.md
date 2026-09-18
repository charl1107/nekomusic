# Task 10: Wire Download in Song Card

## Task Description

Wire up the download option in the song card bottom sheet to actually download songs.

## Files

- Modify: `flutter_app/lib/widgets/song_card.dart`

## Requirements

### 1. Add imports

```dart
import 'package:provider/provider.dart';
import '../services/download_service.dart';
```

### 2. Wire download option in _showOptions

Change the "Download" `ListTile` to:

```dart
ListTile(
  leading: Consumer<DownloadService>(
    builder: (context, downloadService, _) {
      final state = downloadService.getState(song.id);
      if (state == DownloadState.downloading) {
        return const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      }
      return Icon(
        state == DownloadState.downloaded
            ? Icons.download_done
            : Icons.download,
      );
    },
  ),
  title: const Text('Download'),
  onTap: () {
    final downloadService = context.read<DownloadService>();
    final state = downloadService.getState(song.id);
    if (state == DownloadState.downloaded) {
      downloadService.removeDownload(song.id);
    } else {
      downloadService.downloadSong(song);
    }
    Navigator.pop(context);
  },
),
```

## Context

- SongCard has a `_showOptions` method that shows a bottom sheet with "Add to playlist", "Download", "Share" options
- Currently the "Download" option just closes the sheet (`Navigator.pop(context)`)
- DownloadService exists with `getState`, `downloadSong`, `removeDownload` methods (Task 3)
- DownloadState enum has: idle, downloading, downloaded
- The button should show: download icon (idle), spinning progress (downloading), checkmark (downloaded)

## Your Job

1. Read the existing `C:\Users\Administrator\Downloads\nekocMusic\flutter_app\lib\widgets\song_card.dart`
2. Implement exactly what the task specifies
3. Verify the file compiles by running: `cd C:\Users\Administrator\Downloads\nekocMusic\flutter_app; flutter analyze lib/widgets/song_card.dart`
4. Commit your work with a descriptive message
5. Self-review your changes
6. Write your report to: C:\Users\Administrator\Downloads\nekocMusic\.superpowers\sdd\2026-09-17-features\task-10-report.md

## Report Format

Write your full report to the path above, then report back with ONLY:
- **Status:** DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
- Commits created (short SHA + subject)
- One-line test summary
- Your concerns, if any
- The report file path
