# Task 11: Downloads Screen

## Task Description

Create a new screen that shows all downloaded songs.

## Files

- Create: `flutter_app/lib/screens/downloads_screen.dart`

## Requirements

### 1. Create DownloadsScreen

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../services/storage_service.dart';
import '../services/player_service.dart';
import '../services/download_service.dart';
import '../widgets/song_card.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  List<Song> _downloads = [];

  @override
  void initState() {
    super.initState();
    _loadDownloads();
  }

  void _loadDownloads() {
    setState(() {
      _downloads = StorageService.getDownloads();
    });
  }

  @override
  Widget build(BuildContext context) {
    final playerService = context.watch<PlayerService>();
    final downloadService = context.watch<DownloadService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Downloads')),
      body: _downloads.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.download_done, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No downloads yet.\nTap the download icon on any song!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _downloads.length,
              itemBuilder: (context, index) {
                return SongCard(
                  song: _downloads[index],
                  onTap: () {
                    playerService.playList(
                      _downloads,
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

- StorageService has `getDownloads()` method that returns list of downloaded songs (Task 1)
- PlayerService handles queue and playback
- DownloadService manages download state
- SongCard displays song info with tap to play

## Your Job

1. Create the new `C:\Users\Administrator\Downloads\nekocMusic\flutter_app\lib\screens\downloads_screen.dart` file
2. Verify the file compiles by running: `cd C:\Users\Administrator\Downloads\nekocMusic\flutter_app; flutter analyze lib/screens/downloads_screen.dart`
3. Commit your work with a descriptive message
4. Self-review your changes
5. Write your report to: C:\Users\Administrator\Downloads\nekocMusic\.superpowers\sdd\2026-09-17-features\task-11-report.md

## Report Format

Write your full report to the path above, then report back with ONLY:
- **Status:** DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
- Commits created (short SHA + subject)
- One-line test summary
- Your concerns, if any
- The report file path
