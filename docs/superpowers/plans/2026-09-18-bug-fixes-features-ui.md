# NekoMusic Bug Fixes, Features & Modern UI Upgrade Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix all bugs, add missing features (shuffle, repeat, favorites, queue, add-to-playlist), and upgrade UI to modern design.

**Architecture:** Fix critical bugs first, then add features to PlayerService/StorageService, then upgrade UI components and theme.

**Tech Stack:** Flutter, Hive, Provider, just_audio, Google Fonts, CachedNetworkImage, shimmer

**Spec:** N/A (design approved in chat)

## Global Constraints

- Flutter SDK >=3.0.0 <4.0.0
- Python Flask backend with YouTube Data API v3
- Hive for local storage
- Provider for state management
- Must work on web and Android

---

## File Structure

| File | Purpose |
|------|---------|
| `flutter_app/lib/services/download_service.dart` | Fix infinite recursion in saveToDevice |
| `flutter_app/lib/services/player_service.dart` | Add shuffle, repeat, favorites |
| `flutter_app/lib/services/storage_service.dart` | Add favorites storage |
| `flutter_app/lib/screens/player_screen.dart` | Add shuffle/repeat UI, queue view |
| `flutter_app/lib/screens/home_screen.dart` | Add favorites section |
| `flutter_app/lib/screens/queue_screen.dart` | **New** - Queue view |
| `flutter_app/lib/theme/app_theme.dart` | Modern UI theme |
| `flutter_app/lib/main.dart` | Update theme, add fonts |
| `flutter_app/lib/widgets/song_card.dart` | Add favorite button |
| `flutter_app/lib/widgets/mini_player.dart` | **New** - Glassmorphism mini player |
| `flutter_app/lib/screens/settings_screen.dart` | Add about dialog |
| `flutter_app/pubspec.yaml` | Add dependencies |

---

## Phase 1: Bug Fixes

### Task 1: Fix saveToDevice Infinite Recursion

**Files:**
- Modify: `flutter_app/lib/services/download_service.dart:44-48`

**Interfaces:**
- Produces: `saveToDevice(Song song)` returns `Future<String?>` (fixed)

- [ ] **Step 1: Fix the recursive call**

```dart
// BEFORE (broken - infinite recursion):
Future<String?> saveToDevice(Song song) async {
  try {
    final path = await saveToDevice(song); // CALLS ITSELF
    return path;
  } catch (e) {
    return null;
  }
}

// AFTER (fixed - calls platform-specific implementation):
Future<String?> saveToDevice(Song song) async {
  try {
    final path = await saveToDeviceFile(song);
    return path;
  } catch (e) {
    return null;
  }
}
```

- [ ] **Step 2: Verify fix**

Run: `cd flutter_app && flutter analyze lib/services/download_service.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add flutter_app/lib/services/download_service.dart
git commit -m "fix: resolve infinite recursion in saveToDevice"
```

---

### Task 2: Fix Empty Platform Stub

**Files:**
- Modify: `flutter_app/lib/services/download_service_helper.dart`

**Interfaces:**
- Produces: `downloadFile()` and `saveToDeviceFile()` with desktop support

- [ ] **Step 1: Add desktop download support**

```dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/song.dart';

typedef ProgressCallback = void Function(double progress);

Future<void> downloadFile(String url, Song song, {ProgressCallback? onProgress}) async {
  final dir = await getApplicationDocumentsDirectory();
  final filePath = '${dir.path}/${song.id}.mp3';
  final file = File(filePath);
  
  // Simple HTTP download for desktop
  final response = await HttpClient().getUrl(Uri.parse(url));
  final httpResponse = await response.close();
  final sink = file.openWrite();
  await httpResponse.pipe(sink);
}

Future<String> saveToDeviceFile(Song song) async {
  final dir = await getDownloadsDirectory();
  final filePath = '${dir?.path ?? ''}/${song.title}.mp3';
  final sourceFile = File('${(await getApplicationDocumentsDirectory()).path}/${song.id}.mp3');
  
  if (await sourceFile.exists()) {
    await sourceFile.copy(filePath);
    return filePath;
  }
  throw Exception('Downloaded file not found');
}
```

- [ ] **Step 2: Verify fix**

Run: `cd flutter_app && flutter analyze lib/services/download_service_helper.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add flutter_app/lib/services/download_service_helper.dart
git commit -m "fix: add desktop download support"
```

---

## Phase 2: Features

### Task 3: Add Shuffle & Repeat to PlayerService

**Files:**
- Modify: `flutter_app/lib/services/player_service.dart`

**Interfaces:**
- Produces: `shuffleMode`, `repeatMode`, `toggleShuffle()`, `cycleRepeat()`, `queue` getter

- [ ] **Step 1: Add state fields**

```dart
// Add to PlayerService class:
bool _shuffleMode = false;
RepeatMode _repeatMode = RepeatMode.off;

bool get shuffleMode => _shuffleMode;
RepeatMode get repeatMode => _repeatMode;
List<Song> get queue => List.unmodifiable(_queue);
```

- [ ] **Step 2: Add enums and methods**

```dart
enum RepeatMode { off, all, one }

void toggleShuffle() {
  _shuffleMode = !_shuffleMode;
  if (_shuffleMode) {
    _queue.shuffle();
  }
  notifyListeners();
}

void cycleRepeat() {
  switch (_repeatMode) {
    case RepeatMode.off:
      _repeatMode = RepeatMode.all;
      break;
    case RepeatMode.all:
      _repeatMode = RepeatMode.one;
      break;
    case RepeatMode.one:
      _repeatMode = RepeatMode.off;
      break;
  }
  notifyListeners();
}
```

- [ ] **Step 3: Update playNext() for repeat**

```dart
Future<void> playNext() async {
  if (_queue.isEmpty) return;
  
  if (_repeatMode == RepeatMode.one) {
    // Replay current song
    await _audioPlayer.seek(Duration.zero);
    await _audioPlayer.play();
    return;
  }
  
  _currentIndex++;
  if (_currentIndex >= _queue.length) {
    if (_repeatMode == RepeatMode.all) {
      _currentIndex = 0;
    } else {
      await stop();
      return;
    }
  }
  
  await _playCurrent();
}
```

- [ ] **Step 4: Verify compiles**

Run: `cd flutter_app && flutter analyze lib/services/player_service.dart`
Expected: No errors

- [ ] **Step 5: Commit**

```bash
git add flutter_app/lib/services/player_service.dart
git commit -m "feat: add shuffle and repeat modes"
```

---

### Task 4: Add Favorites to StorageService

**Files:**
- Modify: `flutter_app/lib/services/storage_service.dart`

**Interfaces:**
- Produces: `addFavorite()`, `removeFavorite()`, `isFavorite()`, `getFavorites()`

- [ ] **Step 1: Add favorites box**

```dart
static late Box _favoritesBox;

static Future<void> init() async {
  // ... existing boxes ...
  _favoritesBox = await Hive.openBox('favorites');
}
```

- [ ] **Step 2: Add favorite methods**

```dart
static List<Song> getFavorites() {
  final data = _favoritesBox.get('favorites', defaultValue: '[]');
  final list = json.decode(data as String) as List;
  return list.map((s) => Song.fromJson(s)).toList();
}

static Future<void> addFavorite(Song song) async {
  final favorites = getFavorites();
  if (favorites.any((s) => s.id == song.id)) return;
  favorites.insert(0, song);
  await _favoritesBox.put('favorites',
      json.encode(favorites.map((s) => s.toJson()).toList()));
}

static Future<void> removeFavorite(String songId) async {
  final favorites = getFavorites();
  favorites.removeWhere((s) => s.id == songId);
  await _favoritesBox.put('favorites',
      json.encode(favorites.map((s) => s.toJson()).toList()));
}

static bool isFavorite(String songId) =>
    getFavorites().any((s) => s.id == songId);
```

- [ ] **Step 3: Verify compiles**

Run: `cd flutter_app && flutter analyze lib/services/storage_service.dart`
Expected: No errors

- [ ] **Step 4: Commit**

```bash
git add flutter_app/lib/services/storage_service.dart
git commit -m "feat: add favorites storage"
```

---

### Task 5: Add Favorites to PlayerService

**Files:**
- Modify: `flutter_app/lib/services/player_service.dart`

**Interfaces:**
- Produces: `toggleFavorite()`, `isFavorite()`

- [ ] **Step 1: Add favorite methods**

```dart
bool isFavorite(String songId) => StorageService.isFavorite(songId);

void toggleFavorite(Song song) {
  if (isFavorite(song.id)) {
    StorageService.removeFavorite(song.id);
  } else {
    StorageService.addFavorite(song);
  }
  notifyListeners();
}
```

- [ ] **Step 2: Verify compiles**

Run: `cd flutter_app && flutter analyze lib/services/player_service.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add flutter_app/lib/services/player_service.dart
git commit -m "feat: add favorite toggle to player service"
```

---

### Task 6: Add Favorite Button to SongCard

**Files:**
- Modify: `flutter_app/lib/widgets/song_card.dart`

**Interfaces:**
- Consumes: `PlayerService.toggleFavorite()`, `PlayerService.isFavorite()`

- [ ] **Step 1: Add favorite icon button**

```dart
// In _buildFullCard, add to trailing Row:
if (playerService.isFavorite(song.id))
  Icon(Icons.favorite, color: Theme.of(context).colorScheme.primary, size: 20)
```

- [ ] **Step 2: Add to options menu**

```dart
// Add to _showOptions before Share:
ListTile(
  leading: Icon(
    context.read<PlayerService>().isFavorite(song.id)
        ? Icons.favorite
        : Icons.favorite_border,
  ),
  title: const Text('Add to favorites'),
  onTap: () {
    context.read<PlayerService>().toggleFavorite(song);
    Navigator.pop(context);
  },
),
```

- [ ] **Step 3: Verify compiles**

Run: `cd flutter_app && flutter analyze lib/widgets/song_card.dart`
Expected: No errors

- [ ] **Step 4: Commit**

```bash
git add flutter_app/lib/widgets/song_card.dart
git commit -m "feat: add favorite button to song card"
```

---

### Task 7: Create Queue Screen

**Files:**
- Create: `flutter_app/lib/screens/queue_screen.dart`

**Interfaces:**
- Consumes: `PlayerService.queue`, `PlayerService.playList()`

- [ ] **Step 1: Create queue_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/player_service.dart';
import '../models/song.dart';
import '../widgets/song_card.dart';

class QueueScreen extends StatelessWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playerService = context.watch<PlayerService>();
    final queue = playerService.queue;
    final currentSong = playerService.currentSong;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Queue'),
        actions: [
          if (queue.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: () {
                playerService.stop();
              },
            ),
        ],
      ),
      body: queue.isEmpty
          ? const Center(
              child: Text(
                'No songs in queue.\nPlay something to start!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: queue.length,
              onReorder: (oldIndex, newIndex) {
                // Handle reorder
              },
              itemBuilder: (context, index) {
                final song = queue[index];
                final isPlaying = song.id == currentSong?.id;
                return SongCard(
                  key: ValueKey(song.id),
                  song: song,
                  onTap: () {
                    playerService.playList(queue, startIndex: index);
                  },
                );
              },
            ),
    );
  }
}
```

- [ ] **Step 2: Verify compiles**

Run: `cd flutter_app && flutter analyze lib/screens/queue_screen.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add flutter_app/lib/screens/queue_screen.dart
git commit -m "feat: create queue screen"
```

---

### Task 8: Wire Queue Button in PlayerScreen

**Files:**
- Modify: `flutter_app/lib/screens/player_screen.dart`

**Interfaces:**
- Consumes: `QueueScreen`

- [ ] **Step 1: Add queue button**

```dart
// Add to actions before more_vert:
IconButton(
  icon: const Icon(Icons.queue_music),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QueueScreen()),
    );
  },
),
```

- [ ] **Step 2: Verify compiles**

Run: `cd flutter_app && flutter analyze lib/screens/player_screen.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add flutter_app/lib/screens/player_screen.dart
git commit -m "feat: add queue button to player screen"
```

---

### Task 9: Add Shuffle/Repeat UI to PlayerScreen

**Files:**
- Modify: `flutter_app/lib/screens/player_screen.dart`

**Interfaces:**
- Consumes: `PlayerService.shuffleMode`, `PlayerService.repeatMode`

- [ ] **Step 1: Update shuffle button**

```dart
IconButton(
  icon: Icon(
    Icons.shuffle,
    color: playerService.shuffleMode
        ? Theme.of(context).colorScheme.primary
        : null,
  ),
  onPressed: () => playerService.toggleShuffle(),
),
```

- [ ] **Step 2: Update repeat button**

```dart
IconButton(
  icon: Icon(
    playerService.repeatMode == RepeatMode.one
        ? Icons.repeat_one
        : Icons.repeat,
    color: playerService.repeatMode != RepeatMode.off
        ? Theme.of(context).colorScheme.primary
        : null,
  ),
  onPressed: () => playerService.cycleRepeat(),
),
```

- [ ] **Step 3: Add favorite button**

```dart
// Add after share in _showOptions:
ListTile(
  leading: Icon(
    playerService.isFavorite(song.id) ? Icons.favorite : Icons.favorite_border,
    color: playerService.isFavorite(song.id) ? Colors.red : null,
  ),
  title: Text(
    playerService.isFavorite(song.id) ? 'Remove from favorites' : 'Add to favorites',
  ),
  onTap: () {
    playerService.toggleFavorite(song);
    Navigator.pop(context);
  },
),
```

- [ ] **Step 4: Verify compiles**

Run: `cd flutter_app && flutter analyze lib/screens/player_screen.dart`
Expected: No errors

- [ ] **Step 5: Commit**

```bash
git add flutter_app/lib/screens/player_screen.dart
git commit -m "feat: add shuffle/repeat/favorite UI to player"
```

---

### Task 10: Add Favorites Section to HomeScreen

**Files:**
- Modify: `flutter_app/lib/screens/home_screen.dart`

**Interfaces:**
- Consumes: `StorageService.getFavorites()`

- [ ] **Step 1: Add favorites loading**

```dart
List<Song> _favorites = [];

void _loadRecents() {
  setState(() {
    _recentPlays = StorageService.getRecentPlays();
    _mostPlayed = StorageService.getMostPlayed(limit: 10);
    _favorites = StorageService.getFavorites();
  });
}
```

- [ ] **Step 2: Add Favorites section**

```dart
// Add after Most Played section:
if (_favorites.isNotEmpty)
  SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Favorites',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _favorites.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: SongCard(
                    song: _favorites[index],
                    isCompact: true,
                    onTap: () {
                      playerService.playList(_favorites, startIndex: index);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  ),
```

- [ ] **Step 3: Verify compiles**

Run: `cd flutter_app && flutter analyze lib/screens/home_screen.dart`
Expected: No errors

- [ ] **Step 4: Commit**

```bash
git add flutter_app/lib/screens/home_screen.dart
git commit -m "feat: add favorites section to home screen"
```

---

### Task 11: Add About Dialog to Settings

**Files:**
- Modify: `flutter_app/lib/screens/settings_screen.dart`

**Interfaces:**
- Produces: About dialog with app info

- [ ] **Step 1: Add about dialog**

```dart
// Change the empty onTap:
onTap: () {
  showAboutDialog(
    context: context,
    applicationName: 'NekoMusic',
    applicationVersion: '1.0.0',
    applicationIcon: const Icon(Icons.music_note, size: 48),
    children: [
      const Text('A beautiful music player built with Flutter.'),
    ],
  );
},
```

- [ ] **Step 2: Verify compiles**

Run: `cd flutter_app && flutter analyze lib/screens/settings_screen.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add flutter_app/lib/screens/settings_screen.dart
git commit -m "feat: add about dialog to settings"
```

---

## Phase 3: Modern UI Upgrade

### Task 12: Update Dependencies

**Files:**
- Modify: `flutter_app/pubspec.yaml`

**Interfaces:**
- Produces: google_fonts, cached_network_image, shimmer packages

- [ ] **Step 1: Add dependencies**

```yaml
dependencies:
  google_fonts: ^6.1.0
  cached_network_image: ^3.3.1
  shimmer: ^3.0.0
```

- [ ] **Step 2: Install dependencies**

Run: `cd flutter_app && flutter pub get`
Expected: Success

- [ ] **Step 3: Commit**

```bash
git add flutter_app/pubspec.yaml
git commit -m "feat: add modern UI dependencies"
```

---

### Task 13: Update Theme with Modern Colors

**Files:**
- Modify: `flutter_app/lib/theme/app_theme.dart`

**Interfaces:**
- Produces: Modern Material 3 theme with custom colors

- [ ] **Step 1: Update theme**

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorSchemeSeed: const Color(0xFF6750A4),
    textTheme: GoogleFonts.interTextTheme(),
    cardTheme: const CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 1,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorSchemeSeed: const Color(0xFF6750A4),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    cardTheme: const CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 1,
    ),
  );
}
```

- [ ] **Step 2: Verify compiles**

Run: `cd flutter_app && flutter analyze lib/theme/app_theme.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add flutter_app/lib/theme/app_theme.dart
git commit -m "feat: update theme with modern Material 3 design"
```

---

### Task 14: Create Glassmorphism Mini Player

**Files:**
- Create: `flutter_app/lib/widgets/mini_player.dart`

**Interfaces:**
- Consumes: `PlayerService`, `DownloadService`

- [ ] **Step 1: Create mini_player.dart**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../services/player_service.dart';
import '../screens/player_screen.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final playerService = context.watch<PlayerService>();
    final song = playerService.currentSong;

    if (song == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PlayerScreen()),
        );
      },
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: song.thumbnail != null
                      ? Image.network(
                          song.thumbnail!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context).colorScheme.secondary,
                              ],
                            ),
                          ),
                          child: const Icon(Icons.music_note, color: Colors.white),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        song.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    playerService.isPlaying ? Icons.pause : Icons.play_arrow,
                  ),
                  onPressed: () => playerService.togglePlay(),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  onPressed: () => playerService.playNext(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify compiles**

Run: `cd flutter_app && flutter analyze lib/widgets/mini_player.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add flutter_app/lib/widgets/mini_player.dart
git commit -m "feat: create glassmorphism mini player"
```

---

### Task 15: Update HomeScreen with Mini Player

**Files:**
- Modify: `flutter_app/lib/screens/home_screen.dart`

**Interfaces:**
- Consumes: `MiniPlayer`

- [ ] **Step 1: Replace mini player**

Replace the existing mini player Container with:

```dart
const MiniPlayer(),
```

- [ ] **Step 2: Verify compiles**

Run: `cd flutter_app && flutter analyze lib/screens/home_screen.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add flutter_app/lib/screens/home_screen.dart
git commit -m "feat: integrate glassmorphism mini player"
```

---

### Task 16: Use CachedNetworkImage

**Files:**
- Modify: `flutter_app/lib/widgets/song_card.dart`
- Modify: `flutter_app/lib/screens/player_screen.dart`
- Modify: `flutter_app/lib/widgets/mini_player.dart`

**Interfaces:**
- Produces: CachedNetworkImage with shimmer loading

- [ ] **Step 1: Update song_card.dart**

```dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

// Replace Image.network with:
song.thumbnail != null
    ? CachedNetworkImage(
        imageUrl: song.thumbnail!,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        placeholder: (context, url) => Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(color: Colors.grey[300]),
        ),
        errorWidget: (context, url, error) => Container(
          width: 56,
          height: 56,
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.music_note,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      )
    : Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
        ),
        child: Icon(
          Icons.music_note,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
```

- [ ] **Step 2: Update player_screen.dart**

```dart
// Replace Image.network with:
song.thumbnail != null
    ? CachedNetworkImage(
        imageUrl: song.thumbnail!,
        width: 280,
        height: 280,
        fit: BoxFit.cover,
        placeholder: (context, url) => Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            width: 280,
            height: 280,
            color: Colors.grey[300],
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: 280,
          height: 280,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
            ),
          ),
          child: const Icon(Icons.music_note, size: 80, color: Colors.white),
        ),
      )
    : Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
        ),
        child: const Icon(Icons.music_note, size: 80, color: Colors.white),
      ),
```

- [ ] **Step 3: Update mini_player.dart**

```dart
// Replace Image.network with:
song.thumbnail != null
    ? CachedNetworkImage(
        imageUrl: song.thumbnail!,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: 48,
          height: 48,
          color: Colors.grey[300],
        ),
        errorWidget: (context, url, error) => Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
            ),
          ),
          child: const Icon(Icons.music_note, color: Colors.white),
        ),
      )
    : Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
        ),
        child: const Icon(Icons.music_note, color: Colors.white),
      ),
```

- [ ] **Step 4: Verify compiles**

Run: `cd flutter_app && flutter analyze`
Expected: No errors

- [ ] **Step 5: Commit**

```bash
git add flutter_app/lib/widgets/song_card.dart flutter_app/lib/screens/player_screen.dart flutter_app/lib/widgets/mini_player.dart
git commit -m "feat: use CachedNetworkImage with shimmer loading"
```

---

### Task 17: Add Page Transitions

**Files:**
- Modify: `flutter_app/lib/main.dart`

**Interfaces:**
- Produces: Custom page transitions

- [ ] **Step 1: Add page transitions**

```dart
// In MaterialApp, add:
theme: AppTheme.lightTheme,
darkTheme: AppTheme.darkTheme,
themeMode: playerService.isDarkMode ? ThemeMode.dark : ThemeMode.light,
pageTransitionsTheme: const PageTransitionsTheme(
  builders: {
    TargetPlatform.android: CupertinoPageTransitionsBuilder(),
    TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
    TargetPlatform.web: CupertinoPageTransitionsBuilder(),
  },
),
```

- [ ] **Step 2: Verify compiles**

Run: `cd flutter_app && flutter analyze lib/main.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add flutter_app/lib/main.dart
git commit -m "feat: add smooth page transitions"
```

---

## Phase 4: Final Verification

### Task 18: Final Testing

- [ ] **Step 1: Run full flutter analyze**

Run: `cd flutter_app && flutter analyze`
Expected: No errors

- [ ] **Step 2: Test all features**

1. Search for a song → play it
2. Tap shuffle → verify queue shuffles
3. Tap repeat → cycles through off/all/one
4. Tap favorite → verify heart icon
5. Go to Home → verify favorites section
6. Tap queue button → verify queue screen
7. Play song → tap download → verify progress
8. Go to Downloads → verify song appears
9. Tap 3-dot menu → verify all options work

- [ ] **Step 3: Commit final**

```bash
git add -A
git commit -m "feat: complete bug fixes, features, and modern UI upgrade"
```

---

**End of Plan**
