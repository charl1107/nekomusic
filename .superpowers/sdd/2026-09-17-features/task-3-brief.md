# Task 3: Download Service

## Task Description

Create a new DownloadService that handles downloading songs with Spotify-style state management.

## Files

- Create: `flutter_app/lib/services/download_service.dart`
- Modify: `flutter_app/pubspec.yaml` (add dependencies)
- Modify: `flutter_app/lib/main.dart` (register provider)

## Requirements

### 1. Create DownloadService

```dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/song.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

enum DownloadState { idle, downloading, downloaded }

class DownloadService extends ChangeNotifier {
  final Map<String, DownloadState> _states = {};

  DownloadState getState(String songId) =>
      _states[songId] ?? (StorageService.isDownloaded(songId)
          ? DownloadState.downloaded
          : DownloadState.idle);

  Future<void> downloadSong(Song song) async {
    if (getState(song.id) == DownloadState.downloading) return;

    _states[song.id] = DownloadState.downloading;
    notifyListeners();

    try {
      final audioUrl = await ApiService.getAudioUrl(song.id);
      if (audioUrl == null) {
        _states[song.id] = DownloadState.idle;
        notifyListeners();
        return;
      }

      if (kIsWeb) {
        await _downloadWeb(audioUrl, song);
      } else {
        await _downloadMobile(audioUrl, song);
      }

      await StorageService.addDownload(song);
      _states[song.id] = DownloadState.downloaded;
    } catch (e) {
      _states[song.id] = DownloadState.idle;
    }
    notifyListeners();
  }

  Future<void> _downloadWeb(String url, Song song) async {
    // Uses dart:html - implemented in Task 3b
  }

  Future<void> _downloadMobile(String url, Song song) async {
    // Uses dio + path_provider - implemented in Task 3c
  }

  Future<void> removeDownload(String songId) async {
    await StorageService.removeDownload(songId);
    _states[songId] = DownloadState.idle;
    notifyListeners();
  }
}
```

### 2. Implement web download (Task 3b)

Add import and implementation:

```dart
import 'dart:html' as html;

Future<void> _downloadWeb(String url, Song song) async {
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', '${song.title}.mp3')
    ..style.display = 'none';
  html.document.body!.children.add(anchor);
  anchor.click();
  anchor.remove();
}
```

### 3. Implement mobile download (Task 3c)

Add imports and implementation:

```dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> _downloadMobile(String url, Song song) async {
  if (!kIsWeb && Platform.isAndroid) {
    final status = await Permission.storage.request();
    if (!status.isGranted) return;
  }

  final dir = await getApplicationDocumentsDirectory();
  final filePath = '${dir.path}/${song.id}.mp3';
  final dio = Dio();
  await dio.download(url, filePath);
}
```

### 4. Add dependencies to pubspec.yaml

```yaml
dependencies:
  dio: ^5.4.0
  permission_handler: ^11.0.0
  path_provider: ^2.1.0
```

### 5. Register DownloadService in main.dart

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => PlayerService()),
    ChangeNotifierProvider(create: (_) => DownloadService()),
  ],
  child: const NekoMusicApp(),
)
```

## Context

- StorageService already has `addDownload`, `removeDownload`, `isDownloaded` methods (Task 1)
- ApiService has `getAudioUrl(String id)` method that returns direct audio URL
- The app runs on both web and Android
- For web, use dart:html AnchorElement for direct download
- For Android, use dio + path_provider + permission_handler

## Your Job

1. Create the new download_service.dart file
2. Add the dependencies to pubspec.yaml
3. Register the provider in main.dart
4. Verify the files compile (run `flutter analyze`)
5. Commit your work
6. Report back

## Report Format

Write your full report to: C:\Users\Administrator\Downloads\nekocMusic\.superpowers\sdd\2026-09-17-features\task-3-report.md

Then report back with ONLY:
- **Status:** DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
- Commits created (short SHA + subject)
- One-line test summary
- Your concerns, if any
- The report file path
