# media_kit Playback Engine Swap Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace just_audio's ExoPlayer as the network-streaming engine with media_kit (libmpv) so streamed music plays on the user's Android phone, keeping just_audio solely for RAM-only `.ct` encrypted local files, and enabling Windows playback for the first time.

**Architecture:** `PlayerService` keeps its exact public API (UI and the user's uncommitted screen files untouched). Internally it multiplexes two engines: media_kit `Player` for all network streaming and legacy `.mp3` files, and a lazily-created just_audio `AudioPlayer` only for `.ct` decrypt-stream playback. Position/duration funnel through broadcast StreamControllers owned by the service.

**Tech Stack:** Flutter (Dart 3), media_kit ^1.1.11 + media_kit_libs_audio ^1.0.5 (universal Android+Windows libs), just_audio ^0.9.36 (kept, narrowed), youtube_explode_dart ^3.1.0 (unchanged extraction).

**Spec:** `docs/superpowers/specs/2026-10-12-media-kit-player-design.md`

## Global Constraints

- **Never touch the user's uncommitted files:** `flutter_app/android/app/src/main/AndroidManifest.xml`, `flutter_app/lib/screens/player_screen.dart`, `flutter_app/lib/widgets/song_card.dart`. Always `git add` explicit paths, never `git add -A` / `git add .`.
- `PlayerService` public API stays source-compatible: `position`, `duration`, `positionStream`, `durationStream`, `isPlaying`, `seek`, `togglePlay`, `playNext`, `playPrevious`, `stop`, `playList`, `queue`, `currentSong`, `currentIndex`, `shuffleMode`, `repeatMode`, `cycleRepeat`, `toggleShuffle`, `isFavorite`, `toggleFavorite`, settings getters/setters.
- `.ct` encrypted playback keeps its RAM-only property: no plaintext ever written to disk.
- No User-Agent or other headers passed to media_kit stream URLs.
- Error snack strings verbatim: `'Stream extraction failed - YouTube gave no audio for this song'` (resolve null) and `'Playback error: <message>'` (player load failure).
- `flutter analyze` baseline: 9 pre-existing info-level lints in untouched files (search_screen, settings_screen, app_theme) — zero new issues above that.
- PowerShell 5.1 on this machine: no `&&` chaining; run commands separately.

## Review Focus

No pure-Dart seam exists for engine integration (native libmpv/ExoPlayer), so unit tests cannot pin these — the named gates do. Each line maps to the gate step that exercises it.

1. **media_kit native libs fail to load on the user's specific phone** (wrong ABI, missing .so) → music still silent. Gate: Task 2 Step 6, APK install + tap song.
2. **Windows build breaks or crashes at startup** — just_audio/audio_session have no Windows implementation; eager creation would throw. Mitigated by lazy just_audio; Gate: Task 3 Steps 1–3 (build + run on laptop).
3. **Seek bar frozen after swap** — media_kit position stream semantics differ (must emit on seek and while paused-at-position). Gate: Task 3 Step 3, scrub the seek bar mid-song.
4. **Autoplay queue advance broken** — media_kit `stream.completed` missed or double-fires; expected: song ends → next starts once. Gate: Task 3 Step 3, let a short song play to the end.
5. **`.ct` download regression** — lazy just_audio creation path. Gate: Task 3 Step 3, play one downloaded song if any exist on the laptop-synced state; if none exist, report as unverified rather than assuming success.

---

### Task 1: media_kit dependencies, app initialization, resolver revert

**Files:**
- Modify: `flutter_app/pubspec.yaml` (dependencies block, lines 9–26)
- Modify: `flutter_app/lib/main.dart:12-14`
- Revert: `flutter_app/lib/services/stream_resolver_lookup_io.dart` (drops the uncommitted mp4/AAC preference — a just_audio-era workaround; media_kit decodes the default opus/webm stream natively)

**Interfaces:**
- Consumes: nothing (foundation task).
- Produces: `MediaKit.ensureInitialized()` runs at app startup (required before any `Player` construction in Task 2); media_kit packages resolvable; `StreamResolver.resolve` returns the committed `withHighestBitrate()` behavior.

- [ ] **Step 1: Add dependencies**

In `pubspec.yaml` under `dependencies:` (alphabetical neighbors: `just_audio`, `logging`), add:

```yaml
  media_kit: ^1.1.11
  media_kit_libs_audio: ^1.0.5
```

- [ ] **Step 2: Initialize media_kit in main.dart**

Add `import 'package:media_kit/media_kit.dart';` and insert `MediaKit.ensureInitialized();` immediately after `WidgetsFlutterBinding.ensureInitialized();` in `main()` (before `Hive.initFlutter()` — media_kit requires initialization before any player use; everything else stays in place).

- [ ] **Step 3: Revert the resolver workaround**

Run: `git checkout -- flutter_app/lib/services/stream_resolver_lookup_io.dart`

- [ ] **Step 4: Resolve, analyze, test**

Run separately: `flutter pub get` (expect: Got dependencies!), then `flutter analyze` (expect: 9 baseline infos, zero new), then `flutter test` (expect: 9/9 passing).

- [ ] **Step 5: Commit**

```bash
git add flutter_app/pubspec.yaml flutter_app/pubspec.lock flutter_app/lib/main.dart flutter_app/lib/services/stream_resolver_lookup_io.dart
git commit -m "feat: add media_kit engine dependencies and initialization"
```

---

### Task 2: PlayerService engine swap

**Files:**
- Modify: `flutter_app/lib/services/player_service.dart` (playback paths rewritten; settings/favorites/queue-management methods unchanged; also deletes this file's uncommitted workarounds: `_downloadViaDart`, `_probeMediaUrl`, UA header hack, temp-file fallback branch)

**Interfaces:**
- Consumes: media_kit `Player`/`Media` (available since Task 1); `EncryptedAudioSource` + `CipherService.transformChunk` (existing, unchanged); `StreamResolver.resolve(String) -> Future<String?>`; `showGlobalSnack(String)`; `StorageService` methods (unchanged).
- Produces (exact internals later tasks and the gates rely on):
  - `final Player _mk` — media_kit player, eager, streams all network + legacy `.mp3` playback.
  - `AudioPlayer? _justAudio` with getter `AudioPlayer get _local` (`_justAudio ??= AudioPlayer()`) — created only on first `.ct` playback; never on Windows.
  - `bool _usesLocalPlayback` — selects which engine `position`/`duration`/`togglePlay`/`seek`/repeat-one read and route to. Set `true` immediately before `_local.setAudioSource(...)`, `false` immediately before `_mk.open(...)`.
  - `final _positionController = StreamController<Duration>.broadcast()` and `final _durationController = StreamController<Duration?>.broadcast()` — fed by the active engine; exposed as `positionStream`/`durationStream`.
  - Getters: `Duration get position` → local ? `_local.position` : `_mk.state.position`; `Duration get duration` → local ? `_local.duration` : `_mk.state.duration`, coalesced with `?? Duration.zero`.
  - Public API surface otherwise identical to today (per Global Constraints). Deleted: `AudioPlayer get player`, `Stream<PlayerState> get playerStateStream` (grep-verified zero consumers).

- [ ] **Step 1: Rewrite the engine layer of player_service.dart**

Constructor wiring (media_kit side):

```dart
_mk.stream.position.listen(_positionController.add);
_mk.stream.duration.listen(_durationController.add);
_mk.stream.playing.listen((p) { _isPlaying = p; notifyListeners(); });
_mk.stream.completed.listen((c) { if (c && _autoplay) playNext(); });
_mk.stream.error.listen((msg) { debugPrint('[mk] error: $msg'); showGlobalSnack('Playback error: $msg'); final s = currentSong; if (s != null && !_usesLocalPlayback) { _tryPlayLocal(s); } });
_mk.stream.log.listen((l) => debugPrint('[mk] ${l.text}'));
```

Lazy local getter attaches mirrors on first creation (same three behaviors: position, duration, playing+completed via `_local.playerStateStream` with existing `ProcessingState.completed` logic).

`play(Song)` body: queue handling unchanged; local attempt unchanged (`_tryPlayLocal` first, `!kIsWeb`); then `resolve` → null-snack-and-return on failure → else `_usesLocalPlayback = false; await _mk.open(Media(audioUrl), play: true);` → stats + `notifyListeners()`. Catch → `debugPrint` + `'Playback error: $e'` snack + `!kIsWeb` local fallback.

`_tryPlayLocal`: `.ct` branch → `_usesLocalPlayback = true;` + `_local.setAudioSource(EncryptedAudioSource(file, length))` + `_local.play()` (rest as today). Legacy `.mp3` branch moves to media_kit: `_usesLocalPlayback = false; await _mk.open(Media(legacyFile.path), play: true);`.

Routing methods: `togglePlay`/`seek`/repeat-one's `seek(Duration.zero) + play` branch on `_usesLocalPlayback` (`_local.pause()/play()/seek()` vs `_mk.pause()/play()/seek()`). `stop()` halts both engines (`await _mk.stop(); await _justAudio?.stop();`), then `_currentIndex = -1; notifyListeners();` as today. `dispose()` disposes both engines and closes both controllers.

Deletions: `_downloadViaDart`, `_probeMediaUrl`, the `setUrl` UA-header call and the temp-file branch in `play()`. Imports: add `package:media_kit/media_kit.dart`, `dart:async`; remove nothing that `EncryptedAudioSource` still needs.

- [ ] **Step 2: Verify statics and regression net**

Run separately: `flutter analyze` (expect: 9 baseline infos, zero new), `flutter test` (expect: 9/9).

- [ ] **Step 3: Build the Android APK**

Run: `flutter build apk --debug` (expect: `√ Built build\app\outputs\flutter-apk\app-debug.apk`; first build with native libs may take several extra minutes on this machine).

- [ ] **Step 4: Commit**

```bash
git add flutter_app/lib/services/player_service.dart
git commit -m "feat: stream via media_kit engine, keep just_audio for .ct files"
```

- [ ] **Step 5: Deliver APK to the user (device gate — user action)**

Point the user to `flutter_app\build\app\outputs\flutter-apk\app-debug.apk`; ask them to install, search a song, tap it, and report: music, or which popup appears. **Stop and wait for the report** before Task 3 — this gate validates Review Focus #1 and decides whether Task 2 needs a fix round (do not proceed on assumption).

---

### Task 3: Windows desktop build and laptop playback gate

**Files:**
- Modify: only if the build surfaces Windows-specific failures — allowed only in `player_service.dart`/`main.dart`, consistent with the lazy-init design (e.g., guarding any platform-channel call with `Platform.isAndroid || Platform.isIOS`). The user's files stay untouched.

**Interfaces:**
- Consumes: Task 2's lazy `_justAudio` design (the reason Windows startup cannot crash).
- Produces: a working Windows debug build — the project's standard playback test path from now on (no APK installs for future playback checks).

- [ ] **Step 1: Build for Windows**

Run: `flutter build windows --debug` (expect: success). If it fails on a plugin without a Windows implementation, fix per the allowed-files rule above, re-run analyze, commit with message `fix: guard platform channels for Windows desktop`.

- [ ] **Step 2: Run on the laptop**

Run: `flutter run -d windows` (background it; wait for the window).

- [ ] **Step 3: Laptop playback gate (user action — Review Focus #2–#5)**

With the user driving: play a searched song (audio on laptop = engine swap works off-device), scrub the seek bar mid-song (position updates), let a song end (next starts once, autoplay), and if a `.ct` download exists, play it (lazy just_audio path). Report results; any failure = fix round in Task 2's routing/wiring before proceeding.

- [ ] **Step 4: Final verification and wrap-up**

Run separately: `flutter analyze` (9 baseline infos), `flutter test` (9/9). Report the branch's commits to the user and note that push is their call (their uncommitted files remain in the working tree throughout).
