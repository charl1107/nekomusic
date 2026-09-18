import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/song.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:5000/api';

  static Future<List<Song>> search(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/search?q=${Uri.encodeComponent(query)}'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['results'] as List)
            .map((json) => Song.fromJson(json))
            .toList();
      }
    } catch (e) {
      // ignore
    }
    return [];
  }

  static Future<Song?> getSong(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/song/$id'));
      if (response.statusCode == 200) {
        return Song.fromJson(json.decode(response.body));
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  static String getStreamUrl(String id) => '$baseUrl/stream/$id';
  static String getDownloadUrl(String id) => '$baseUrl/download/$id';

  static Future<String?> getAudioUrl(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/stream/$id'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['url'];
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  static Future<List<Song>> importYouTubePlaylist(String url) async {
    final playlistId = _extractPlaylistId(url);
    if (playlistId == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/playlist/$playlistId'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['results'] as List)
            .map((json) => Song.fromJson(json))
            .toList();
      }
    } catch (e) {
      // ignore
    }
    return [];
  }

  static String? _extractPlaylistId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    return uri.queryParameters['list'];
  }
}
