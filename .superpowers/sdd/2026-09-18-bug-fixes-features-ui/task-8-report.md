# Task 8: Wire Queue Button in PlayerScreen

**Status:** DONE

## Changes Made

Modified `lib/screens/player_screen.dart`:
1. Added import for `queue_screen.dart`
2. Added `IconButton` with `Icons.queue_music` to AppBar actions before `more_vert`
3. Button navigates to `QueueScreen` via `Navigator.push`

## Verification

- `flutter analyze lib/screens/player_screen.dart` — **No issues found**
- No behavioral changes to existing code; additive only
