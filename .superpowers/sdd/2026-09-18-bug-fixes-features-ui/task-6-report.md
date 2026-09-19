# Task 6: Add Favorite Button to SongCard

## Status: DONE

## Changes Made

**File modified:** `lib/widgets/song_card.dart`

1. Added import for `PlayerService`
2. Added favorite `IconButton` in `_buildFullCard` trailing row (before `more_vert` button) — heart icon toggles between `Icons.favorite` and `Icons.favorite_border`, colored with `colorScheme.primary` when favorited
3. Added "Add to favorites" `ListTile` in `_showOptions` menu (before Share) — toggles favorite and closes bottom sheet

## Verification

- `flutter analyze lib/widgets/song_card.dart` — **No issues found**

## Commits

- `2ba9731` — `feat: add favorite button to song card`

## Concerns

None. The implementation uses the existing `PlayerService.isFavorite()` and `PlayerService.toggleFavorite()` methods which delegate to `StorageService` for persistence.
