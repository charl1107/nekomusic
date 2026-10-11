# Plan: Fully Serverless Discovery

**Spec:** `docs/superpowers/specs/2026-10-11-serverless-search-design.md`

## Goal

Search and playlist import move on-device via `youtube_explode_dart`;
the app loses every server dependency; backend and `render.yaml` are
deleted.

## Architecture

- **New:** `discovery_service.dart` + conditional lookups
  (`discovery_lookup_io.dart`, `discovery_lookup_stub.dart`) — exact
  mirror of the existing `stream_resolver` conditional-import pattern
- **Swapped:** 2 call sites (`search_screen.dart:72`,
  `library_screen.dart:118`)
- **Deleted:** `api_service.dart`, `.env`, `flutter_dotenv` wiring,
  `backend/`, `render.yaml`

## Working agreement

- Same as the prior plan: user's uncommitted files
  (AndroidManifest.xml, player_screen.dart, song_card.dart, old
  untracked plan doc) are never staged; `git add` only named files.
- PowerShell 5.1: no `&&`, use `;`.
- `youtube_explode_dart` may be imported ONLY in
  `discovery_lookup_io.dart` (web-build safety; enforced by Task 3's
  `flutter build web --debug` gate).

---

## Task 1: Discovery service (TDD)

Steps:
1. Create `flutter_app/test/discovery_service_test.dart` FIRST:
   - `formatDuration(null)` -> null
   - `formatDuration(Duration(seconds: 215))` -> `'3:35'`
   - `formatDuration(Duration(seconds: 59))` -> `'0:59'`
   - `formatDuration(Duration(hours: 1, minutes: 2, seconds: 3))` -> `'1:02:03'`
   Red: the io lookup file doesn't exist yet.
2. Implement:
   - `discovery_lookup_io.dart`: public `String? formatDuration(Duration?)`
     (minutes zero-padded to at least 2 chars only in the m:ss form per
     the cases above — i.e. `m:ss` with seconds zero-padded; h form is
     `h:mm:ss`), private `Song songFromVideo(Video v)` mapping
     `v.id.value / v.title / v.author / v.thumbnails.maxResUrl /
     formatDuration(v.duration)`, and
     `Future<List<Song>> searchRemote(String query)` /
     `Future<List<Song>> importPlaylistRemote(String url)` each
     constructing a short-lived `YoutubeExplode` (closed in `finally`),
     calling `yt.search.getVideos(query)` / `yt.playlists.getVideos(id)`
     (id extracted from `list=` query param — port the logic from the
     deleted `ApiService._extractPlaylistId`; invalid url -> `[]`),
     mapping via `songFromVideo`; ANY failure -> `[]`.
   - `discovery_lookup_stub.dart`: same two functions returning `[]`.
   - `discovery_service.dart`: static `DiscoveryService.search` /
     `DiscoveryService.importPlaylist` delegating through
     `import 'discovery_lookup_stub.dart' if (dart.library.io) 'discovery_lookup_io.dart' as lookup;`.
   - Attempt one mapping test constructing a `Video` directly if the
     package's `Video` constructor allows it cleanly; if it fights you,
     skip it and note why in the report (device gate covers mapping).
3. `cd flutter_app; flutter test` green; `flutter analyze` clean.

Files to Create: the 3 lib files + 1 test file
Commit: `feat: on-device discovery service (search + playlists)`

---

## Task 2: Call-site swap + client wiring deletions

Steps:
1. `search_screen.dart` (~line 72): `ApiService.search(query)` ->
   `DiscoveryService.search(query)`; fix imports.
2. `library_screen.dart` (~line 118):
   `ApiService.importYouTubePlaylist(result)` ->
   `DiscoveryService.importPlaylist(result)`; fix imports.
3. Delete `flutter_app/lib/services/api_service.dart`.
4. Delete `flutter_app/.env`.
5. `pubspec.yaml`: remove the `flutter_dotenv` dependency and the
   `.env` assets entry.
6. `main.dart`: remove the dotenv import and `await dotenv.load()`.
7. Root `.gitignore`: remove the `!flutter_app/.env` negation line.
8. Verify: repo-wide grep in `flutter_app/` for `ApiService|dotenv|API_BASE_URL|nekomusic-5d94` -> zero hits; `flutter analyze` clean; `flutter test` green.

Files to Modify: search_screen.dart, library_screen.dart, pubspec.yaml, main.dart, .gitignore; Delete: api_service.dart, .env
Commit: `feat: app goes fully serverless, remove API client and dotenv`

---

## Task 3: Backend removal + full gates

Steps:
1. `git rm -r backend render.yaml` (git history preserves both).
2. Repo-wide grep for `backend/|render.yaml|onrender.com` outside docs
   -> report any code hits (docs are out of scope; README refresh is a
   known deferred minor).
3. Gates: `cd flutter_app; flutter analyze` (no new issues),
   `flutter test` (all green), `flutter build web --debug` (succeeds —
   proves discovery's conditional import didn't leak io into web).

Files to Delete: backend/, render.yaml
Commit: `chore: remove backend and render.yaml (fully serverless)`

---

## Task 4: Acceptance + ship

Controller-run after final review (same split as the prior plan):
1. Push to main.
2. **Device gate (user):** search a term -> results appear -> tap a
   song -> audio plays, with no backend existing.
3. Render dashboard service deletion is the user's call, now
   unreferenced by anything.
