# Design: Fully Serverless Discovery (drop Render)

**Date:** 2026-10-11
**Status:** Approved (design), supersedes the metadata role of
`2026-10-10-on-device-playback-design.md`
**Scope:** Flutter app only; backend decommissioned

## Problem

The on-device playback restructure left the Render backend holding exactly
two jobs: Data API search (`/api/search`) and playlist import
(`/api/playlist`). Both exist only to keep the YouTube Data API key off
the client. The Render service is also currently suspended, and its sole
remaining purpose does not justify keeping a server alive.

## Decision

Move search and playlist import on-device with `youtube_explode_dart`
(the same library that already resolves playback streams). The app
becomes 100% serverless; the API key retires; the backend and
`render.yaml` are deleted (git history preserves them).

Accepted trade-offs:
- Search relevance is YouTube's mobile search (good, not Data-API-grade).
- Web search returns empty results until the IFrame phase — consistent
  with web being secondary and `youtube_explode_dart` being io-only.

## Components

### 1. New `flutter_app/lib/services/discovery_service.dart`

Static API mirroring the call shape of the deleted `ApiService`:

```
static Future<List<Song>> search(String query)
static Future<List<Song>> importPlaylist(String url) // extracts list= id
```

Conditional-import backend (same pattern as `stream_resolver`):
- `discovery_lookup_io.dart`: owns a short-lived `YoutubeExplode` per
  call (closed in `finally`); `search` -> `yt.search.getVideos(query)`;
  `importPlaylist` -> `yt.playlists.getVideos(id)`; both map
  `Video -> Song`; any failure -> empty list.
- `discovery_lookup_stub.dart`: web stub returning empty lists.
- `youtube_explode_dart` is imported ONLY in the io lookup file.

Mapping: `id = video.id.value`, `title = video.title`,
`artist = video.author`, `thumbnail = video.thumbnails.maxResUrl`,
`duration = formatDuration(video.duration)` (public pure function:
null -> null, 215s -> "3:35", >=1h -> "1:00:00").

### 2. Call-site swaps (2 lines)

- `search_screen.dart`: `ApiService.search(query)` -> `DiscoveryService.search(query)`
- `library_screen.dart`: `ApiService.importYouTubePlaylist(url)` -> `DiscoveryService.importPlaylist(url)`
- Loading/error UI in both screens untouched.

### 3. Deletions

- `flutter_app/lib/services/api_service.dart`
- `flutter_app/.env`, `flutter_dotenv` (pubspec dependency + assets
  entry), `dotenv.load()` + import in `main.dart`,
  the `!flutter_app/.env` line in the root `.gitignore`
- `backend/` (entire directory) and `render.yaml`

## Error handling

Search/playlist failure -> empty list (identical UX contract to the old
ApiService, which swallowed errors and returned []).

## Acceptance criteria

- `flutter analyze` clean (no new issues), `flutter test` green
  (duration-format tests included), `flutter build web --debug` succeeds
- No reference to `ApiService`, `dotenv`, or `nekomusic-5d94` remains in
  `flutter_app/lib`
- Device gate: search returns results and a tapped song plays, with no
  backend in existence

## Out of scope

- Web IFrame playback/search (phase 2, unchanged)
- README doc refresh (tracked as a deferred minor from the prior review)
