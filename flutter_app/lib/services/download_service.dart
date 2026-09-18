import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/song.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'download_service_helper.dart'
    if (dart.library.html) 'download_service_web.dart'
    if (dart.library.io) 'download_service_mobile.dart';

enum DownloadState { idle, downloading, downloaded }

class DownloadService extends ChangeNotifier {
  final Map<String, DownloadState> _states = {};
  final Map<String, double> _progress = {};

  DownloadState getState(String songId) =>
      _states[songId] ??
      (StorageService.isDownloaded(songId)
          ? DownloadState.downloaded
          : DownloadState.idle);

  double getProgress(String songId) => _progress[songId] ?? 0.0;

  Future<void> downloadSong(Song song) async {
    if (getState(song.id) == DownloadState.downloading) return;

    _states[song.id] = DownloadState.downloading;
    _progress[song.id] = 0.0;
    notifyListeners();

    try {
      final downloadUrl = ApiService.getDownloadUrl(song.id);
      await downloadFile(
        downloadUrl,
        song,
        onProgress: (p) {
          _progress[song.id] = p;
          notifyListeners();
        },
      );

      await StorageService.addDownload(song);
      _states[song.id] = DownloadState.downloaded;
      _progress[song.id] = 1.0;
    } catch (e) {
      _states[song.id] = DownloadState.idle;
      _progress[song.id] = 0.0;
    }
    notifyListeners();
  }

  Future<void> removeDownload(String songId) async {
    await StorageService.removeDownload(songId);
    _states[songId] = DownloadState.idle;
    _progress[songId] = 0.0;
    notifyListeners();
  }
}
