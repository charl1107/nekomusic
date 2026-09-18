# Task 8: Frontend YouTube Playlist Import

## Task Description

Add the frontend method to call the backend YouTube playlist endpoint and import songs.

## Files

- Modify: `flutter_app/lib/services/api_service.dart`

## Requirements

### 1. Add importYouTubePlaylist method

```dart
static Future<List<Song>> importYouTubePlaylist(String url) async {
  final playlistId = _extractPlaylistId(url);
  if (playlistId == null) return [];

  try {
    final response = await http.get(
      Uri.parse('$baseUrl/playlist/$playlistId'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['results'] as List)
          .map((json) => Song.fromJson(json))
          .toList();
    }
  } catch (e) {
    // ignore
  }
  return [];
}

static String? _extractPlaylistId(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return null;
  return uri.queryParameters['list'];
}
```

## Context

- Backend now has `GET /api/playlist/<playlist_id>` endpoint (Task 7)
- ApiService already has `search`, `getSong`, `getAudioUrl`, `getStreamUrl`, `getDownloadUrl` methods
- YouTube playlist URLs look like: `https://www.youtube.com/playlist?list=PLxxxxxx`
- The `list` query parameter contains the playlist ID
- LibraryScreen already has `_importFromYouTube` method that calls `ApiService.importYouTubePlaylist` (Task 6)

## Your Job

1. Read the existing `C:\Users\Administrator\Downloads\nekocMusic\flutter_app\lib\services\api_service.dart`
2. Implement exactly what the task specifies
3. Verify the file compiles by running: `cd C:\Users\Administrator\Downloads\nekocMusic\flutter_app; flutter analyze lib/services/api_service.dart`
4. Commit your work with a descriptive message
5. Self-review your changes
6. Write your report to: C:\Users\Administrator\Downloads\nekocMusic\.superpowers\sdd\2026-09-17-features\task-8-report.md

## Report Format

Write your full report to the path above, then report back with ONLY:
- **Status:** DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
- Commits created (short SHA + subject)
- One-line test summary
- Your concerns, if any
- The report file path
