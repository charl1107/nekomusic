# Design: media_kit playback engine swap

Date: 2026-10-12
Status: approved (design gate), pending implementation plan

## Problem

On the user's Android phone, streamed playback fails with `playback error: (0)
source error` while the same googlevideo URL serves bytes fine to plain Dart
HTTP on the same device. Evidence chain:

- Stream extraction (`youtube_explode_dart`) succeeds on-device.
- A Dart `HttpClient` Range GET to the resolved URL returns `206` with 64
  bytes, with and without a browser User-Agent (`no-UA:206/64b
  chrome-UA:206/64b`), so the CDN serves the phone and neither headers nor IP
  binding are at fault.
- `just_audio`'s ExoPlayer fails to load the same URL (`source error`) even
  with a Chrome User-Agent header and an AAC/mp4 stream preference.
- A full Dart-download-to-temp-file fallback also failed on-device, so
  proxying bytes into ExoPlayer is not a reliable path either.

Conclusion: the failure is isolated to just_audio/ExoPlayer's media-loading
stack on this device; the exact internal mechanism is unknown (no adb access).
Spotube (team-spotube/spotube) proves the alternative: it plays these same
YouTube stream URLs for its ~50k users using `media_kit` (libmpv: its own
libcurl HTTP stack and FFmpeg decoding), completely bypassing ExoPlayer.

## Goal & success criteria

Music streams reliably on the user's Android phone, and playback is also
testable on the user's Windows laptop (no just_audio Windows implementation
exists, so today the desktop build cannot play at all).

Success = the user hears audio from (a) a phone APK install and (b) a Windows
run on the laptop, for arbitrary searched songs.

## Constraints

- `PlayerService` public API used by the UI must keep working unchanged so the
  user's uncommitted screen files (`player_screen.dart`, `song_card.dart`)
  continue to compile: `position`, `duration`, `positionStream`,
  `durationStream`, `isPlaying`, `seek`, `togglePlay`, `playNext`,
  `playPrevious`, `stop`, `playList`, queue/shuffle/repeat/settings/favorites.
- The `.ct` encrypted-download feature keeps its documented RAM-only property:
  no plaintext is ever written to disk.
- Laptop is weak (Celeron N4500, 8 GB): keep the dependency and code footprint
  minimal; no emulator.
- Web stays non-functional for playback (stubbed resolver) until a future
  IFrame phase.

## Approach

Hybrid engines behind the unchanged facade:

- **media_kit `Player`** owns all network streaming — the broken path today.
- **just_audio `AudioPlayer`** shrinks to exactly one job: playing `.ct`
  encrypted local files through the existing `EncryptedAudioSource`
  (`StreamAudioSource` + `CipherService.transformChunk`, RAM-only decrypt).
  It is created lazily on first local playback, so it never initializes on
  Windows (where it would throw at startup).
- Legacy plaintext `.mp3` local files also move to media_kit (`Media(filePath)`
  — libmpv plays files natively), leaving just_audio solely responsible for
  the `.ct` decrypt-stream.

Alternatives considered and rejected:

- *media_kit everywhere* (delete just_audio): requires a loopback HTTP server
  or plaintext temp files for `.ct` playback — new risky code or a broken
  security property, for a feature that works today.
- *Dart-proxy StreamAudioSource into ExoPlayer* (no new engine): the Dart
  full-download fallback already failed on-device, and it would keep ExoPlayer
  as the decoder, which may fail beyond its HTTP layer.

## Components

### pubspec.yaml

Add `media_kit: ^1.1.11` and `media_kit_libs_audio: ^1.0.5` (universal native
libs: Android + Windows). Spotube git-pins media_kit for a playlist `.move()`
bug; this app opens a single `Media` per song, so pub versions suffice.
Keep `logging` (resolver error surfacing uses it).

### main.dart

`MediaKit.ensureInitialized()` before `runApp`. Existing `Logger.root` →
global-snackbar routing stays.

### player_service.dart

- Fields: `_mk` (media_kit `Player`, eager), `_audioPlayer` (just_audio,
  lazy via getter), `_usesLocalPlayback` flag selecting which engine the
  position/duration/playing getters read from.
- Unified broadcast `StreamController<Duration>` (position) and
  `StreamController<Duration?>` (duration), fed by whichever engine is
  active. `positionStream`/`durationStream` expose these; `position`/
  `duration`/`isPlaying` read the active engine's state.
- Engine wiring: media_kit `stream.position`, `stream.duration`,
  `stream.playing` (→ `_isPlaying` + `notifyListeners`), `stream.completed`
  (→ `playNext()` when `_autoplay`), `stream.error` (→ snackbar + local-file
  fallback), `stream.log` (→ debugPrint). just_audio's
  `playerStateStream`/`positionStream` mirrored into the same controllers
  when the lazy instance is created.
- `play(song)`: unchanged queue handling; local `.ct` attempt first
  (just_audio, lazy); else resolve URL → `_mk.open(Media(url), play: true)`.
  No User-Agent headers passed to media_kit — the probe proved the CDN serves
  these URLs header-agnostically and Spotube ships without them.
- `seek`/`togglePlay`/`stop` route to the active engine; `stop()` halts both
  engines (cheap insurance).
- Legacy `.mp3` local path uses media_kit `Media(filePath)`.

### Deletions

All just_audio streaming workarounds go with the engine that needed them:

- `_downloadViaDart` fallback and the download-to-temp branch in `play()`
- `_probeMediaUrl` diagnostic probe
- the Chrome User-Agent header hack on `setUrl`
- the mp4/AAC stream preference in `stream_resolver_lookup_io.dart` — revert
  that file to its committed state (the preference was an uncommitted
  just_audio-era workaround; media_kit decodes the default opus/webm stream
  natively)
- `AudioPlayer get player` and `Stream<PlayerState> get playerStateStream`
  (grep-verified: no consumers anywhere, including uncommitted files)

### Error contract (unchanged UX)

- resolve → null: "Stream extraction failed - YouTube gave no audio for this
  song"
- player load error (media_kit `stream.error`): "Playback error: <message>"
  snackbar, then fall back to local-file playback if present.

## Testing & gates

- `flutter analyze`: clean (9 pre-existing baseline infos untouched).
- `flutter test`: 9/9.
- `flutter build apk --debug`: succeeds.
- `flutter build windows --debug`: succeeds (first time this build is
  exercised).
- User device gate: install APK on phone → music plays for a searched song.
- User laptop gate: `flutter run -d windows` → music plays on the laptop.
  This path becomes the standard playback check for future rounds, ending the
  APK-only test loop.

## Out of scope / follow-ups

- Audio-focus and interruption handling on media_kit (Spotube wires
  audio_session for this). Separate small phase if phone interruptions
  misbehave.
- Removing just_audio entirely by serving `.ct` decrypt-streams to libmpv via
  a loopback HTTP server.
- Web playback (IFrame phase, already deferred).
