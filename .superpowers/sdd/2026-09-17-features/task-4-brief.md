# Task 4: Most Played Section on HomeScreen

## Task Description

Add a "Most Played" section to the HomeScreen that displays the top 10 songs by play count.

## Files

- Modify: `flutter_app/lib/screens/home_screen.dart`

## Requirements

### 1. Add most played state variable

In `_HomeScreenState`, add:

```dart
List<Song> _mostPlayed = [];
```

### 2. Load most played in initState and _loadRecents

```dart
@override
void initState() {
  super.initState();
  _loadRecents();
}

void _loadRecents() {
  setState(() {
    _recentPlays = StorageService.getRecentPlays();
    _mostPlayed = StorageService.getMostPlayed(limit: 10);
  });
}
```

### 3. Add Most Played section in _buildHomeContent

After the Recently Played `SliverToBoxAdapter`, add another `SliverToBoxAdapter`:

```dart
SliverToBoxAdapter(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Most Played',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (_mostPlayed.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No plays yet.\nStart listening to see your top songs!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _mostPlayed.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: SongCard(
                    song: _mostPlayed[index],
                    isCompact: true,
                    onTap: () {
                      playerService.playList(
                        _mostPlayed,
                        startIndex: index,
                      );
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

## Context

- StorageService now has `getMostPlayed({int limit})` method (Task 1)
- HomeScreen already shows Recently Played in a horizontal scroll
- SongCard widget already supports `isCompact: true` mode
- PlayerService handles queue and playback

## Your Job

1. Read the existing `C:\Users\Administrator\Downloads\nekocMusic\flutter_app\lib\screens\home_screen.dart`
2. Add the most played state and loading logic
3. Add the Most Played section UI
4. Verify the file compiles (run `flutter analyze lib/screens/home_screen.dart`)
5. Commit your work
6. Report back

## Report Format

Write your full report to: C:\Users\Administrator\Downloads\nekocMusic\.superpowers\sdd\2026-09-17-features\task-4-report.md

Then report back with ONLY:
- **Status:** DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
- Commits created (short SHA + subject)
- One-line test summary
- Your concerns, if any
- The report file path
