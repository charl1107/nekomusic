# Task 12: Update Navigation (5 Tabs) — Report

## Status: DONE

## Changes Made

Modified `flutter_app/lib/screens/home_screen.dart` with three edits:

1. **Added import** for `downloads_screen.dart` (line 9)
2. **Added `const DownloadsScreen()`** to `IndexedStack` children as the 4th item (line 49), between Library and Settings
3. **Added `NavigationDestination`** for Downloads tab with `Icons.download_outlined` / `Icons.download` and label `'Downloads'` (lines 79-83), between Library and Settings

## Verification

- `flutter analyze lib/screens/home_screen.dart` passed with only 1 pre-existing deprecation warning (`withOpacity` → `withValues()`) — no new issues introduced.

## Commit

- `e48b201` — `feat(navigation): add Downloads tab as 4th navigation destination`

## Concerns

None. The change is minimal and matches the task spec exactly. The `IndexedStack` and `NavigationBar` are kept in sync with 5 items each. The existing `onDestinationSelected` logic (index 0 reloads recents) remains correct.
