# Task 1: Storage - Play Counts & Downloads

## Task Description

Add play count tracking and download storage to StorageService.

## Files

- Modify: `flutter_app/lib/services/storage_service.dart`

## Requirements

### 1. Add play counts box

Add a new Hive box `_playCountsBox` and open it in `init()`.

### 2. Add play count methods

```dart
static int getPlayCount(String songId) =>
    _playCountsBox.get(songId, defaultValue: 0);

static Future<void> incrementPlayCount(String songId) async {
  final count = getPlayCount(songId);
  await _playCountsBox.put(songId, count + 1);
}

static List<Song> getMostPlayed({int limit = 10}) {
  final entries = _playCountsBox.toMap().entries.toList()
    ..sort((a, b) => (b.value as int).compareTo(a.value as int));
  final recentData = _recentsBox.get('recents', defaultValue: '[]');
  final allSongs = (json.decode(recentData as String) as List)
      .map((s) => Song.fromJson(s))
      .toList();
  final songMap = {for (var s in allSongs) s.id: s};
  final result = <Song>[];
  for (var entry in entries.take(limit)) {
    if (songMap.containsKey(entry.key)) {
      result.add(songMap[entry.key]!);
    }
  }
  return result;
}
```

### 3. Add downloads box

Add a new Hive box `_downloadsBox` and open it in `init()`.

### 4. Add download methods

```dart
static List<Song> getDownloads() {
  final data = _downloadsBox.get('downloads', defaultValue: '[]');
  final list = json.decode(data as String) as List;
  return list.map((s) => Song.fromJson(s)).toList();
}

static Future<void> addDownload(Song song) async {
  final downloads = getDownloads();
  if (downloads.any((s) => s.id == song.id)) return;
  downloads.insert(0, song);
  await _downloadsBox.put('downloads',
      json.encode(downloads.map((s) => s.toJson()).toList()));
}

static Future<void> removeDownload(String songId) async {
  final downloads = getDownloads();
  downloads.removeWhere((s) => s.id == songId);
  await _downloadsBox.put('downloads',
      json.encode(downloads.map((s) => s.toJson()).toList()));
}

static bool isDownloaded(String songId) =>
    getDownloads().any((s) => s.id == songId);
```

## Context

- This is the first task in a feature branch adding Most Played, Downloads, and YouTube Import
- The app uses Hive for local storage
- Song model already exists with id, title, artist, album, thumbnail, duration fields
- StorageService already manages settings, playlists, and recents boxes

## Your Job

1. Read the existing `flutter_app/lib/services/storage_service.dart`
2. Add the new boxes and methods as specified
3. Verify the file compiles (run `flutter analyze lib/services/storage_service.dart`)
4. Commit your work
5. Report back

## Report Format

Write your full report to: `C:\Users\Administrator\Downloads\nekocMusic\.superpowers\sdd\2026-09-17-features\task-1-report.md`

Then report back with ONLY:
- **Status:** DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
- Commits created (short SHA + subject)
- One-line test summary
- Your concerns, if any
- The report file path
