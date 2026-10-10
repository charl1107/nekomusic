# Design: On-Device Playback Architecture

**Date:** 2026-10-10
**Status:** Approved (design), pending spec review
**Scope:** Flutter app (Android/iOS primary, web secondary) + Render backend

## Problem

YouTube blocks its streaming endpoints from datacenter IPs. The Render
backend (yt-dlp + cookies + every tested player client) receives
`Sign in to confirm you're not a bot` or responses with zero audio
formats. This is IP-level and permanent for Render; no server-side
library, cookie, OAuth, or public Invidious/Piped workaround survives on
it (all tested 2026-10-10).

Extraction from residential IPs works reliably (verified repeatedly from
a local machine, same yt-dlp version, same videos).

## Decision

Split responsibilities:

- **Render backend:** metadata only (search, song, playlist, health).
  No YouTube streaming endpoints at all.
- **Flutter mobile app:** resolves audio stream URLs on-device via
  `youtube_explode_dart` and plays them with the existing `just_audio`
  pipeline. The phone's residential IP is the trust root.
- **Web build:** best-effort phase 2 using the YouTube IFrame player
  (browser origins are CORS-blocked from YouTube's API — verified).

This matches how RiMusic, Spotube, InnerTune, and BlackHole operate.

## Components

### 1. Backend (`backend/`)

Keep:

| Route | Purpose |
|---|---|
| `GET /api/search?q=` | Search via YouTube Data API key |
| `GET /api/song/<id>` | Song metadata |
| `GET /api/playlist/<id>` | Playlist metadata |
| `GET /api/health` | Health check (Render health check path) |

Delete:

- `/api/stream`, `/api/download`, `/api/save`, `/api/downloads`,
  `/api/downloads/<id>`, `/api/downloads/<id>/file`
- `/api/probe/<id>` (temporary diagnostic) and all `detail`/`cookie_count`
  diagnostics on error responses
- `download_in_background`, `download_status`, `DOWNLOADS_DIR` and the
  `downloads/` directory
- Cookie loading (`YOUTUBE_COOKIES`) in `services/api_client.py`
- `get_audio_url`, `get_audio_stream` in `services/api_client.py`
- `yt-dlp` in `requirements.txt`
- `YOUTUBE_COOKIES` in `render.yaml`

`render.yaml` keeps `healthCheckPath: /api/health` and
`YOUTUBE_API_KEY` (sync: false).

### 2. Stream resolver (new: `flutter_app/lib/services/stream_resolver.dart`)

Single-purpose unit:

```
resolve(String videoId) -> Future<String?>
```

- Uses `youtube_explode_dart` (`videos.streamsClient.getManifest`)
- Selects `manifest.audioOnly.withHighestBitrate()`
- Returns the direct `googlevideo.com` URL (or null on failure)
- Owns/closes a `YoutubeExplode` instance; no other concerns
- Runs entirely on the device — no server call

### 3. Player integration (`flutter_app/lib/services/player_service.dart`)

- `play()` flow becomes:
  1. Existing local-file-first check (`_tryPlayLocal`) unchanged
  2. `StreamResolver.resolve(song.id)` instead of
     `ApiService.getAudioUrl(song.id)`
  3. `_player.setUrl(url)` + `play()` — unchanged
- Queue, seek, position, autoplay, recents: untouched
- On resolve failure: `play()` returns without starting playback
  (existing behavior when the server returned null) — no retry loop,
  no crash

### 4. Downloads / offline (`download_service.dart`, `downloads_screen.dart`)

- Download = resolve on-device → fetch bytes → save into the existing
  encrypted local storage (from commit `37c3d97`)
- `downloads_screen` reads local storage; server `/api/downloads`
  endpoints no longer exist
- Web download path (`download_service_web.dart`): out of scope until
  phase 2 (server save is gone; web storage deferred)

### 5. Web (phase 2, separate slice)

- Hidden YouTube IFrame player behind the same `player_service`
  interface (play/pause/seek/position events via the IFrame API)
- Not part of the first delivery; mobile is the product

## Data flow (mobile)

```
Search:   App → Render /api/search → YouTube Data API (works today)
Play:     App → StreamResolver (on-device) → Innertube (phone IP) →
          googlevideo URL → just_audio streams directly from Google CDN
Offline:  App → StreamResolver → fetch bytes → encrypted local storage
```

No Render involvement in playback, downloads, or streaming.

## Error handling

- Manifest fetch fails (rare on residential IPs): return null; player
  surfaces "unavailable" and offers skip — no retries loop
- Age-restricted/blocked videos (small minority): logged; cookie
  fallback explicitly deferred (YAGNI until observed in practice)
- Library breakage after YouTube changes: upstream
  `youtube_explode_dart` updates; acceptable risk, residential IP keeps
  working through the vast majority of changes

## Phases

1. **Mobile playback end-to-end** (resolver + player swap) — gate:
   audio plays on a device/emulator
2. **Backend slimming** (deletions above) — parallel, zero app risk
3. **Downloads rework** to device-local storage
4. **Web IFrame** (separate slice, after mobile ships)

## Acceptance criteria

- Search returns results from Render (unchanged behavior)
- On Android/iOS: tap a song → audio plays (server not in the path)
- Offline download plays back from local storage with no network
- Backend has no YouTube streaming code and deploys clean on Render
- `flutter analyze` passes with no new issues

## Out of scope

- ytmusicapi adoption (current Data API search works)
- Proxy/PO-token/OAuth server-side workarounds (abandoned, documented)
- User accounts, playlists server-side, background audio packages
  beyond what exists
