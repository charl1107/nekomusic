# Task 12: Update Navigation (5 Tabs)

## Task Description

Update the home screen navigation to include 5 tabs with a Downloads tab.

## Files

- Modify: `flutter_app/lib/screens/home_screen.dart`

## Requirements

### 1. Add import

```dart
import 'downloads_screen.dart';
```

### 2. Update IndexedStack children

```dart
children: [
  _buildHomeContent(playerService),
  const SearchScreen(),
  const LibraryScreen(),
  const DownloadsScreen(),
  const SettingsScreen(),
],
```

### 3. Update NavigationBar destinations

```dart
destinations: const [
  NavigationDestination(
    icon: Icon(Icons.home_outlined),
    selectedIcon: Icon(Icons.home),
    label: 'Home',
  ),
  NavigationDestination(
    icon: Icon(Icons.search),
    selectedIcon: Icon(Icons.search),
    label: 'Search',
  ),
  NavigationDestination(
    icon: Icon(Icons.library_music_outlined),
    selectedIcon: Icon(Icons.library_music),
    label: 'Library',
  ),
  NavigationDestination(
    icon: Icon(Icons.download_outlined),
    selectedIcon: Icon(Icons.download),
    label: 'Downloads',
  ),
  NavigationDestination(
    icon: Icon(Icons.settings_outlined),
    selectedIcon: Icon(Icons.settings),
    label: 'Settings',
  ),
],
```

## Context

- DownloadsScreen exists (Task 11)
- HomeScreen currently has 4 tabs: Home, Search, Library, Settings
- Need to add Downloads as the 4th tab (before Settings)

## Your Job

1. Read the existing `C:\Users\Administrator\Downloads\nekocMusic\flutter_app\lib\screens\home_screen.dart`
2. Implement exactly what the task specifies
3. Verify the file compiles by running: `cd C:\Users\Administrator\Downloads\nekocMusic\flutter_app; flutter analyze lib/screens/home_screen.dart`
4. Commit your work with a descriptive message
5. Self-review your changes
6. Write your report to: C:\Users\Administrator\Downloads\nekocMusic\.superpowers\sdd\2026-09-17-features\task-12-report.md

## Report Format

Write your full report to the path above, then report back with ONLY:
- **Status:** DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
- Commits created (short SHA + subject)
- One-line test summary
- Your concerns, if any
- The report file path
