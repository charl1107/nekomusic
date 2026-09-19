import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/song.dart';
import '../services/api_service.dart';

typedef ProgressCallback = void Function(double progress);

Future<void> downloadFile(String url, Song song,
    {ProgressCallback? onProgress, dynamic cancelToken}) async {
  // On web, use backend save endpoint for background download
  final saveUrl = '${ApiService.baseUrl}/save/${song.id}';

  try {
    final response = await http.post(
      Uri.parse(saveUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'title': song.title}),
    );

    if (response.statusCode == 200) {
      // Poll for progress
      await _pollDownloadProgress(song.id, onProgress);
    } else {
      throw Exception('Failed to start download');
    }
  } catch (e) {
    throw Exception('Download failed: $e');
  }
}

Future<void> _pollDownloadProgress(String songId, ProgressCallback? onProgress) async {
  final statusUrl = '${ApiService.baseUrl}/downloads/$songId';
  int maxAttempts = 300; // 5 minutes max (1 second intervals)

  for (int i = 0; i < maxAttempts; i++) {
    await Future.delayed(const Duration(seconds: 1));

    try {
      final response = await http.get(Uri.parse(statusUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final state = data['state'];
        final progress = data['progress'] ?? 0;

        if (onProgress != null) {
          onProgress(progress / 100.0);
        }

        if (state == 'completed') {
          return;
        } else if (state == 'error') {
          throw Exception(data['error'] ?? 'Download failed');
        }
      }
    } catch (e) {
      if (i == maxAttempts - 1) rethrow;
    }
  }

  throw Exception('Download timed out');
}

Future<String> saveToDeviceFile(Song song) async {
  throw Exception('Save to device not supported on web - file is saved on server');
}

Future<void> deleteFile(String songId) async {
  // On web, file is on server - could add delete endpoint if needed
}
