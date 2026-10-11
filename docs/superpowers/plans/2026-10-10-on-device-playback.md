# Plan: On-Device Playback Architecture

**Spec:** `docs/superpowers/specs/2026-10-10-on-device-playback-design.md`

## Goal

Mobile app resolves YouTube audio stream URLs on-device (`youtube_explode_dart`) and
plays them through the existing `just_audio` pipeline; the Render backend shrinks to
metadata only (search/song/playlist/health). Downloads become device-local.

## Architecture

- **New:** `flutter_app/lib/services/stream_resolver.dart` + conditional lookup files
  (`stream_resolver_lookup_io.dart`, `stream_resolver_lookup_stub.dart`)
- **Swapped:** `player_service.play()` and `download_service.downloadSong()` call
  `StreamResolver.resolve()` instead of `ApiService.getAudioUrl()`
- **Deleted (backend):** `/api/stream`, `/api/download`, `/api/save`, `/api/downloads*`,
  `/api/probe`, background download threads, cookie machinery, all yt-dlp usage
- **Deleted (app):** `ApiService.getStreamUrl/getDownloadUrl/getAudioUrl`, server
  download polling in `downloads_screen`

## Working agreement

- Working tree contains the user's own uncommitted edits (AndroidManifest.xml,
  player_screen.dart, song_card.dart) — **do not touch or commit those files**.
  `git add` only the files each task names.
- Order matters: app goes first, backend deletions last — no intermediate state
  ships where the app calls endpoints that no longer exist.
- PowerShell 5.1: no `&&`, use `;`.

---

## Task 1: Dependencies + pending env wiring commit

Steps:
1. `flutter pub add youtube_explode_dart` (adds it to `pubspec.yaml`/`pubspec.lock`).
2. Commit the already-finished Render wiring that is still uncommitted:
   `flutter_app/.env`, `flutter_app/.gitignore` exception, `flutter_app/lib/main.dart`
   (dotenv load), `pubspec.yaml`, `pubspec.lock`.

Files to Modify: `flutter_app/pubspec.yaml`, `flutter_app/pubspec.lock`

Validation:
- `cd flutter_app; git status` → only user's own files remain uncommitted
  (AndroidManifest.xml, player_screen.dart, song_card.dart)

Commit: `feat: add youtube_explode_dart and commit Render env wiring`

---

## Task 2: StreamResolver (TDD)

Steps:
1. Create `flutter_app/test/stream_resolver_test.dart` FIRST — 3 cases using a fake
   `AudioUrlLookup`:
   - fake returns a URL → `resolve` returns that URL
   - fake throws → `resolve` returns `null`
   - fake returns `null` → `resolve` returns `null`
   Run `cd flutter_app; flutter test test/stream_resolver_test.dart` → fails
   (stream_resolver.dart doesn't exist yet).
2. Implement the resolver:
   - `stream_resolver.dart`:
     ```dart
     typedef AudioUrlLookup = Future<String?> Function(String videoId);

     class StreamResolver {
       StreamResolver({AudioUrlLookup? lookup})
           : _lookup = lookup ?? lookup_io.defaultLookup;
       final AudioUrlLookup _lookup;
       Future<String?> resolve(String videoId) async {
         try { return await _lookup(videoId); } catch (_) { return null; }
       }
     }
     ```
     with `import 'stream_resolver_lookup_stub.dart'
     if (dart.library.io) 'stream_resolver_lookup_io.dart' as lookup_io;`
   - `stream_resolver_lookup_io.dart`: real impl — `YoutubeExplode()` →
     `videos.streamsClient.getManifest(id)` → if `manifest.audioOnly` is empty return
     null, else `manifest.audioOnly.withHighestBitrate().url.toString()` →
     `finally { yt.close(); }`
   - `stream_resolver_lookup_stub.dart`: web stub returning `null`
     (youtube_explode_dart is not web-safe; conditional import keeps web compiling).
3. Re-run the test → 3 passing.

Files to Create: `flutter_app/lib/services/stream_resolver.dart`,
`flutter_app/lib/services/stream_resolver_lookup_io.dart`,
`flutter_app/lib/services/stream_resolver_lookup_stub.dart`,
`flutter_app/test/stream_resolver_test.dart`

Validation: `cd flutter_app; flutter test test/stream_resolver_test.dart` → All tests passed

Commit: `feat: on-device stream resolver with unit tests`

---

## Task 3: Player swap

Steps:
1. In `player_service.dart`:
   - Add field `final StreamResolver _resolver;` and constructor param
     `PlayerService({StreamResolver? resolver}) : _resolver = resolver ?? StreamResolver()`
     (existing call sites use `PlayerService()` — unchanged).
   - In `play()` (line ~78): replace `await ApiService.getAudioUrl(song.id)` with
     `await _resolver.resolve(song.id)`. Keep the null → silent return and the
     catch → `_tryPlayLocal` fallback exactly as-is.
   - Remove `import 'api_service.dart'` if no other `ApiService` reference remains
     in the file (check before removing).
   - Web: no branch needed — the stub lookup returns null, so web `play()` returns
     silently until the IFrame phase. Add a one-line comment saying so.

Files to Modify: `flutter_app/lib/services/player_service.dart`

Validation:
- `cd flutter_app; flutter analyze` → no new issues
- `flutter test` → all pass

Commit: `feat: resolve audio streams on-device in player`

---

## Task 4: Downloads rework (device-local)

Steps:
1. `download_service.dart`:
   - Add `final StreamResolver _resolver = StreamResolver();`
   - Mobile branch (line ~48): replace `ApiService.getAudioUrl(song.id)` with
     `_resolver.resolve(song.id)` (null handling unchanged).
   - Web branch (line ~46): replace `ApiService.getDownloadUrl(...)` with setting
     `_errorMessage = 'Downloads are not supported on web yet'`, reset state to
     idle, `notifyListeners(); return;` (mirror the existing null-URL path).
   - Drop the now-unused `api_service` import if nothing else uses it.
2. `download_service_web.dart` (read it fully first): replace `downloadFile` body
   with `throw Exception('Downloads are not supported on web yet')`; delete
   `_pollDownloadProgress` and all `ApiService` references; keep exported signatures
   (`downloadFile`, `ProgressCallback`, `saveToDeviceFile`, `deleteFile`) intact so
   the conditional import still compiles.
3. `downloads_screen.dart` (read fully first):
   - Delete `_loadActiveDownloads` + the 2-second `Timer` that polls
     `${ApiService.baseUrl}/downloads` and the `initState`/`dispose` wiring for them.
   - Build the active-downloads list from `DownloadService` (a `ChangeNotifier`
     already in the provider tree): `isDownloading(id)` / `getProgress(id)`.
   - Keep `_loadDownloads` (local `StorageService`) untouched. Remove `http` and
     `api_service` imports if unused.
4. `api_service.dart`: delete `getStreamUrl`, `getDownloadUrl`, `getAudioUrl`
   (lines 43–58).

Files to Modify: `flutter_app/lib/services/download_service.dart`,
`flutter_app/lib/services/download_service_web.dart`,
`flutter_app/lib/screens/downloads_screen.dart`,
`flutter_app/lib/services/api_service.dart`

Validation:
- `cd flutter_app; flutter analyze` → no new issues
- `flutter test` → all pass

Commit: `feat: device-local downloads, drop server download endpoints from app`

---

## Task 5: Backend tests first (TDD)

Steps:
1. Create `backend/tests/__init__.py` (empty) and `backend/tests/test_metadata_only.py`
   using stdlib `unittest` + `app.test_client()`:
   - `GET /api/health` → 200
   - `GET /api/stream/abc` → 404
   - `GET /api/download/abc` → 404
   - `POST /api/save/abc` → 404
   - `GET /api/downloads` → 404
   - `GET /api/probe/abc` → 404
   - `GET /api/search` (no query param) → non-404 (proves route still exists;
     app returns 400 for missing `q` without hitting the network)
   - `GET /api/song/abc` → skip network-dependent assertions; assert route is not
     404 by checking `/api/song/` handling only if it doesn't hit the network —
     if `get_song` always calls the YouTube API, drop this case and note it.
2. Run: `cd backend; python -m unittest discover -s tests -v` → the 404 assertions
   FAIL (endpoints still exist), health/search pass. That's the red state.

Files to Create: `backend/tests/__init__.py`, `backend/tests/test_metadata_only.py`

Validation: red run shows exactly the expected failing cases.

Commit: `test: backend metadata-only contract (red)`

---

## Task 6: Backend deletions

Steps:
1. `backend/app.py`:
   - Delete routes: `stream`, `download`, `save_download`, `get_downloads`,
     `get_download_status`, `get_downloaded_file`, `probe`.
   - Delete `download_in_background`, `DOWNLOADS_DIR`/downloads folder logic,
     `download_status` dict, and the background-thread machinery.
   - Strip debug `detail`/`cookie_count`/`cookies` fields from error responses.
   - Remove now-unused imports (`send_file`, `Response`, `threading`, `time`, `json`
     — verify each before removing; keep `os` if still used).
2. `backend/services/api_client.py`:
   - Delete `get_audio_url`, `get_audio_stream`, `_best_audio_url`, the player-client
     loop, cookie loading (`YOUTUBE_COOKIES`), and all instrumentation added today.
   - Remove `yt_dlp` import(s). Keep `search`, `get_song`, `get_playlist`.
3. `backend/requirements.txt`: remove `yt-dlp`.
4. `render.yaml`: remove the `YOUTUBE_COOKIES` env var (keep `YOUTUBE_API_KEY`,
   health check, gunicorn).
5. Run `cd backend; python -m unittest discover -s tests -v` → all green.

Files to Modify: `backend/app.py`, `backend/services/api_client.py`,
`backend/requirements.txt`, `render.yaml`

Validation:
- `python -m unittest discover -s tests -v` → OK
- `python -c "import app"` → no error

Commit: `refactor: strip backend to metadata-only (drop yt-dlp and streaming)`

---

## Task 7: Acceptance + ship

Steps:
1. `cd flutter_app; flutter analyze` → no new issues; `flutter test` → pass.
2. `flutter build web --debug` → succeeds (proves the resolver's conditional import
   didn't leak `dart:io` into web). If it fails on `player_service.dart`'s existing
   unconditional `import 'dart:io'`, that is a pre-existing issue — report it, do
   not expand scope.
3. **Device gate (user performs):** install on phone/emulator → search → tap a song
   → audio plays. No console snippets — the test is real playback.
4. Push; Render auto-deploys (~60–140s). Then exactly **two** single requests
   (no polling loops):
   - `GET /api/health` → 200
   - `GET /api/stream/<any-id>` → 404 (endpoint gone)
5. Commit any remaining task files; leave the user's own edits untouched.

Validation: see steps above — device playback is THE acceptance criterion.

Commit: `chore: verify acceptance, ship on-device playback`
