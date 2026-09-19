import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/song.dart';
import '../models/playlist.dart';

class StorageService {
  static late Box _settingsBox;
  static late Box _playlistsBox;
  static late Box _recentsBox;
  static late Box _playCountsBox;
  static late Box _downloadsBox;
  static late Box _searchesBox;
  static late Box _favoritesBox;

  static Future<void> init() async {
    _settingsBox = await Hive.openBox('settings');
    _playlistsBox = await Hive.openBox('playlists');
    _recentsBox = await Hive.openBox('recents');
    _playCountsBox = await Hive.openBox('playCounts');
    _downloadsBox = await Hive.openBox('downloads');
    _searchesBox = await Hive.openBox('searches');
    _favoritesBox = await Hive.openBox('favorites');
  }

  static bool getDarkMode() => _settingsBox.get('darkMode', defaultValue: false);
  static void setDarkMode(bool value) => _settingsBox.put('darkMode', value);

  static bool getAutoplay() => _settingsBox.get('autoplay', defaultValue: true);
  static void setAutoplay(bool value) => _settingsBox.put('autoplay', value);

  static String getAudioQuality() =>
      _settingsBox.get('audioQuality', defaultValue: '320kbps');
  static void setAudioQuality(String value) =>
      _settingsBox.put('audioQuality', value);

  static List<Playlist> getPlaylists() {
    final data = _playlistsBox.get('playlists', defaultValue: '[]');
    final list = json.decode(data as String) as List;
    return list.map((p) => Playlist.fromJson(p)).toList();
  }

  static Future<void> savePlaylists(List<Playlist> playlists) async {
    final data = playlists.map((p) => p.toJson()).toList();
    await _playlistsBox.put('playlists', json.encode(data));
  }

  static Future<void> addPlaylist(Playlist playlist) async {
    final playlists = getPlaylists();
    playlists.add(playlist);
    await savePlaylists(playlists);
  }

  static Future<void> deletePlaylist(String id) async {
    final playlists = getPlaylists();
    playlists.removeWhere((p) => p.id == id);
    await savePlaylists(playlists);
  }

  static List<Song> getRecentPlays() {
    final data = _recentsBox.get('recents', defaultValue: '[]');
    final list = json.decode(data as String) as List;
    return list.map((s) => Song.fromJson(s)).toList();
  }

  static Future<void> addRecentPlay(Song song) async {
    final recents = getRecentPlays();
    recents.removeWhere((s) => s.id == song.id);
    recents.insert(0, song);
    if (recents.length > 50) recents.removeLast();
    final data = recents.map((s) => s.toJson()).toList();
    await _recentsBox.put('recents', json.encode(data));
  }

  static int getPlayCount(String songId) =>
      _playCountsBox.get(songId, defaultValue: 0);

  static Future<void> incrementPlayCount(String songId) async {
    final count = getPlayCount(songId);
    await _playCountsBox.put(songId, count + 1);
  }

  static List<Song> getMostPlayed({int limit = 10}) {
    final recentData = _recentsBox.get('recents', defaultValue: '[]');
    final allSongs = (json.decode(recentData as String) as List)
        .map((s) => Song.fromJson(s))
        .toList();
    final songMap = {for (var s in allSongs) s.id: s};

    // Get songs with play counts, sorted by count
    final entries = _playCountsBox.toMap().entries.toList()
      ..sort((a, b) => (b.value as int).compareTo(a.value as int));

    final result = <Song>[];
    final addedIds = <String>{};

    // Add songs with play counts first
    for (var entry in entries) {
      if (result.length >= limit) break;
      if (songMap.containsKey(entry.key)) {
        result.add(songMap[entry.key]!);
        addedIds.add(entry.key);
      }
    }

    // Fill remaining with recent songs not yet added
    for (var song in allSongs) {
      if (result.length >= limit) break;
      if (!addedIds.contains(song.id)) {
        result.add(song);
        addedIds.add(song.id);
      }
    }

    return result;
  }

  static List<Song> getDownloads() {
    final data = _downloadsBox.get('downloads', defaultValue: '[]');
    final list = json.decode(data as String) as List;
    return list.map((s) => Song.fromJson(s)).toList();
  }

  static Future<void> addDownload(Song song) async {
    final downloads = getDownloads();
    if (downloads.any((s) => s.id == song.id)) return;
    downloads.insert(0, song);
    await _downloadsBox.put('downloads',
        json.encode(downloads.map((s) => s.toJson()).toList()));
  }

  static Future<void> removeDownload(String songId) async {
    final downloads = getDownloads();
    downloads.removeWhere((s) => s.id == songId);
    await _downloadsBox.put('downloads',
        json.encode(downloads.map((s) => s.toJson()).toList()));
  }

  static bool isDownloaded(String songId) =>
      getDownloads().any((s) => s.id == songId);

  static List<String> getRecentSearches() {
    final data = _searchesBox.get('searches', defaultValue: '[]');
    return List<String>.from(json.decode(data as String));
  }

  static Future<void> addRecentSearch(String query) async {
    if (query.trim().isEmpty) return;
    final searches = getRecentSearches();
    searches.remove(query);
    searches.insert(0, query);
    if (searches.length > 20) searches.removeLast();
    await _searchesBox.put('searches', json.encode(searches));
  }

  static Future<void> removeRecentSearch(String query) async {
    final searches = getRecentSearches();
    searches.remove(query);
    await _searchesBox.put('searches', json.encode(searches));
  }

  static Future<void> clearRecentSearches() async {
    await _searchesBox.put('searches', json.encode([]));
  }

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
}
