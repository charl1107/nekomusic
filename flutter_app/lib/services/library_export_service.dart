import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/song.dart';
import 'storage_service.dart';

class LibraryExportService {
  static Future<bool> exportAndShare(BuildContext context) async {
    final now = DateTime.now().toUtc();
    final filename =
        'nekomusic_library_${now.toIso8601String().replaceAll(':', '-')}.json';
    final playlists = StorageService.getPlaylists();
    final export = {
      'format': 'nekomusic-library',
      'version': 1,
      'exportedAt': now.toIso8601String(),
      'playlists': playlists.map((playlist) => {
        'id': playlist.id,
        'name': playlist.name,
        'description': playlist.description,
        'createdAt': playlist.createdAt.toIso8601String(),
        'tracks': playlist.songs.map(_trackData).toList(),
      }).toList(),
    };
    final bytes = Uint8List.fromList(
      utf8.encode(const JsonEncoder.withIndent('  ').convert(export)),
    );

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.linux) {
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Export NekoMusic library',
        fileName: filename,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: bytes,
      );
      return path != null;
    }

    final renderObject = context.findRenderObject();
    final sharePositionOrigin = renderObject is RenderBox
        ? renderObject.localToGlobal(Offset.zero) & renderObject.size
        : null;
    await Share.shareXFiles(
      [
        XFile.fromData(
          bytes,
          mimeType: 'application/json',
          name: filename,
        ),
      ],
      fileNameOverrides: [filename],
      subject: 'NekoMusic library',
      text: 'NekoMusic playlist and track information',
      sharePositionOrigin: sharePositionOrigin,
    );
    return true;
  }

  static Map<String, dynamic> _trackData(Song song) => {
    'id': song.id,
    'title': song.title,
    'artist': song.artist,
    'album': song.album,
    'duration': song.duration,
    'thumbnail': song.thumbnail,
    if (song.localPath != null) 'fileName': _fileName(song.localPath!),
  };

  static String _fileName(String path) =>
      path.replaceAll('\\', '/').split('/').last;
}
