# Task 2: Player Service - Track Play Counts

## Task Description

Increment play count in PlayerService when a song is played.

## Files

- Modify: `flutter_app/lib/services/player_service.dart`

## Requirements

### 1. Add increment call in play() method

In the `play()` method, after `StorageService.addRecentPlay(song);`, add:

```dart
StorageService.incrementPlayCount(song.id);
```

## Context

- StorageService now has `incrementPlayCount(String songId)` method (added in Task 1)
- PlayerService already calls `StorageService.addRecentPlay(song)` in the `play()` method
- This is a simple one-line addition

## Your Job

1. Read the existing `C:\Users\Administrator\Downloads\nekocMusic\flutter_app\lib\services\player_service.dart`
2. Add the increment call after the recent play call
3. Verify the file compiles (run `flutter analyze lib/services/player_service.dart`)
4. Commit your work
5. Report back

## Report Format

Write your full report to: C:\Users\Administrator\Downloads\nekocMusic\.superpowers\sdd\2026-09-17-features\task-2-report.md

Then report back with ONLY:
- **Status:** DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
- Commits created (short SHA + subject)
- One-line test summary
- Your concerns, if any
- The report file path
