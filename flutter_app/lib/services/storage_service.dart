import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/song.dart';
import '../models/playlist.dart';

class StorageService {
  static late Box _settingsBox;
  static late Box _playlistsBox;
  static late Box _recentsBox;

  static Future<void> init() async {
    _settingsBox = await Hive.openBox('settings');
    _playlistsBox = await Hive.openBox('playlists');
    _recentsBox = await Hive.openBox('recents');
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
}
