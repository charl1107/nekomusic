# Task 6: Wire Library Screen Tap & Import

## Task Description

Wire up the library screen to navigate to playlist detail view when a playlist is tapped, and add YouTube import functionality.

## Files

- Modify: `flutter_app/lib/screens/library_screen.dart`

## Requirements

### 1. Import PlaylistDetailScreen

```dart
import 'playlist_detail_screen.dart';
```

### 2. Wire onTap to navigate

Change `onTap: () {}` to:

```dart
onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PlaylistDetailScreen(playlist: playlist),
    ),
  );
},
```

### 3. Add YouTube import button to AppBar actions

```dart
actions: [
  IconButton(
    icon: const Icon(Icons.link),
    onPressed: _importFromYouTube,
  ),
],
```

### 4. Implement _importFromYouTube

```dart
Future<void> _importFromYouTube() async {
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Import from YouTube'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Paste YouTube playlist URL',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: const Text('Import'),
        ),
      ],
    ),
  );

  if (result != null && result.isNotEmpty) {
    final songs = await ApiService.importYouTubePlaylist(result);
    if (songs.isNotEmpty && context.mounted) {
      final nameController = TextEditingController(text: 'Imported Playlist');
      final name = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Playlist Name'),
          content: TextField(controller: nameController),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, nameController.text),
              child: const Text('Create'),
            ),
          ],
        ),
      );

      if (name != null && name.isNotEmpty) {
        final playlist = Playlist(
          id: const Uuid().v4(),
          name: name,
          songs: songs,
        );
        await StorageService.addPlaylist(playlist);
        _loadPlaylists();
      }
    }
  }
}
```

### 5. Add required imports

```dart
import 'package:uuid/uuid.dart';
import '../services/api_service.dart';
import '../models/song.dart';
```

## Context

- PlaylistDetailScreen exists (Task 5)
- LibraryScreen already has playlist list with onTap: () {} placeholder
- ApiService will have `importYouTubePlaylist(String url)` method (Task 8)
- StorageService has `addPlaylist(Playlist playlist)` method
- UUID package is already in pubspec.yaml

## Your Job

1. Read the existing `C:\Users\Administrator\Downloads\nekocMusic\flutter_app\lib\screens\library_screen.dart`
2. Implement exactly what the task specifies
3. Verify the file compiles by running: `cd C:\Users\Administrator\Downloads\nekocMusic\flutter_app; flutter analyze lib/screens/library_screen.dart`
4. Commit your work with a descriptive message
5. Self-review your changes
6. Write your report to: C:\Users\Administrator\Downloads\nekocMusic\.superpowers\sdd\2026-09-17-features\task-6-report.md

## Report Format

Write your full report to the path above, then report back with ONLY:
- **Status:** DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
- Commits created (short SHA + subject)
- One-line test summary
- Your concerns, if any
- The report file path
