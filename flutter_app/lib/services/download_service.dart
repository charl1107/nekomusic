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

  DownloadState getState(String songId) =>
      _states[songId] ??
      (StorageService.isDownloaded(songId)
          ? DownloadState.downloaded
          : DownloadState.idle);

  Future<void> downloadSong(Song song) async {
    if (getState(song.id) == DownloadState.downloading) return;

    _states[song.id] = DownloadState.downloading;
    notifyListeners();

    try {
      final audioUrl = await ApiService.getAudioUrl(song.id);
      if (audioUrl == null) {
        _states[song.id] = DownloadState.idle;
        notifyListeners();
        return;
      }

      await downloadFile(audioUrl, song);

      await StorageService.addDownload(song);
      _states[song.id] = DownloadState.downloaded;
    } catch (e) {
      _states[song.id] = DownloadState.idle;
    }
    notifyListeners();
  }

  Future<void> removeDownload(String songId) async {
    await StorageService.removeDownload(songId);
    _states[songId] = DownloadState.idle;
    notifyListeners();
  }
}
