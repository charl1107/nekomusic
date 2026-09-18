# Task 5: Playlist Detail Screen

## Task Description

Create a new screen that shows the songs in a playlist, allowing users to play them.

## Files

- Create: `flutter_app/lib/screens/playlist_detail_screen.dart`

## Requirements

### 1. Create PlaylistDetailScreen

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/playlist.dart';
import '../services/player_service.dart';
import '../services/download_service.dart';
import '../widgets/song_card.dart';

class PlaylistDetailScreen extends StatelessWidget {
  final Playlist playlist;
  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  Widget build(BuildContext context) {
    final playerService = context.watch<PlayerService>();
    final downloadService = context.watch<DownloadService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(playlist.name),
        actions: [
          if (playlist.songs.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.play_circle_fill),
              onPressed: () {
                playerService.playList(playlist.songs);
              },
            ),
        ],
      ),
      body: playlist.songs.isEmpty
          ? const Center(
              child: Text(
                'No songs in this playlist.\nAdd songs from search.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: playlist.songs.length,
              itemBuilder: (context, index) {
                return SongCard(
                  song: playlist.songs[index],
                  onTap: () {
                    playerService.playList(
                      playlist.songs,
                      startIndex: index,
                    );
                  },
                );
              },
            ),
    );
  }
}
```

## Context

- Playlist model has: id, name, description, songs, createdAt
- PlayerService handles queue and playback
- DownloadService handles download state (will be used in Task 10)
- SongCard widget displays song info with tap to play

## Your Job

1. Create the new `C:\Users\Administrator\Downloads\nekocMusic\flutter_app\lib\screens\playlist_detail_screen.dart` file
2. Verify the file compiles by running: `cd C:\Users\Administrator\Downloads\nekocMusic\flutter_app; flutter analyze lib/screens/playlist_detail_screen.dart`
3. Commit your work with a descriptive message
4. Self-review your changes
5. Write your report to: C:\Users\Administrator\Downloads\nekocMusic\.superpowers\sdd\2026-09-17-features\task-5-report.md

## Report Format

Write your full report to the path above, then report back with ONLY:
- **Status:** DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
- Commits created (short SHA + subject)
- One-line test summary
- Your concerns, if any
- The report file path
