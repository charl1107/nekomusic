import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/song.dart';

class ApiService {
  static final String baseUrl =
      dotenv.env['API_BASE_URL'] ?? 'https://nekomusic-5d94.onrender.com/api';
  static const Duration _timeout = Duration(seconds: 60);

  static Future<List<Song>> search(String query) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/search?q=${Uri.encodeComponent(query)}'),
          )
          .timeout(_timeout);
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
      final response =
          await http.get(Uri.parse('$baseUrl/song/$id')).timeout(_timeout);
      if (response.statusCode == 200) {
        return Song.fromJson(json.decode(response.body));
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
      final response =
          await http.get(Uri.parse('$baseUrl/playlist/$playlistId')).timeout(_timeout);
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
