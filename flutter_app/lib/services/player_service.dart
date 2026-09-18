import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';
import 'api_service.dart';
import 'storage_service.dart';

enum RepeatMode { off, all, one }

class PlayerService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  List<Song> _queue = [];
  int _currentIndex = -1;
  bool _isDarkMode = false;
  bool _autoplay = true;
  String _audioQuality = '320kbps';
  bool _isPlaying = false;
  bool _shuffleMode = false;
  RepeatMode _repeatMode = RepeatMode.off;

  AudioPlayer get player => _player;
  List<Song> get queue => List.unmodifiable(_queue);
  int get currentIndex => _currentIndex;
  bool get isDarkMode => _isDarkMode;
  bool get autoplay => _autoplay;
  String get audioQuality => _audioQuality;
  bool get isPlaying => _isPlaying;
  bool get shuffleMode => _shuffleMode;
  RepeatMode get repeatMode => _repeatMode;
  Song? get currentSong =>
      _currentIndex >= 0 && _currentIndex < _queue.length
          ? _queue[_currentIndex]
          : null;

  Duration get position => _player.position;
  Duration get duration => _player.duration ?? Duration.zero;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  PlayerService() {
    _loadSettings();
    _player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      if (state.processingState == ProcessingState.completed && _autoplay) {
        playNext();
      }
      notifyListeners();
    });
  }

  Future<void> _loadSettings() async {
    _isDarkMode = StorageService.getDarkMode();
    _autoplay = StorageService.getAutoplay();
    _audioQuality = StorageService.getAudioQuality();
    notifyListeners();
  }

  Future<void> play(Song song) async {
    final index = _queue.indexWhere((s) => s.id == song.id);
    if (index == -1) {
      _queue.add(song);
      _currentIndex = _queue.length - 1;
    } else {
      _currentIndex = index;
    }

    final audioUrl = await ApiService.getAudioUrl(song.id);
    if (audioUrl == null) return;
    await _player.setUrl(audioUrl);
    await _player.play();
    StorageService.addRecentPlay(song);
    StorageService.incrementPlayCount(song.id);
    notifyListeners();
  }

  Future<void> playList(List<Song> songs, {int startIndex = 0}) async {
    _queue = List.from(songs);
    _currentIndex = startIndex;
    if (_queue.isNotEmpty) {
      await play(_queue[_currentIndex]);
    }
  }

  Future<void> playNext() async {
    if (_queue.isEmpty) return;

    if (_repeatMode == RepeatMode.one) {
      await _player.seek(Duration.zero);
      await _player.play();
      return;
    }

    _currentIndex++;
    if (_currentIndex >= _queue.length) {
      if (_repeatMode == RepeatMode.all) {
        _currentIndex = 0;
      } else {
        await stop();
        return;
      }
    }

    await play(_queue[_currentIndex]);
  }

  Future<void> playPrevious() async {
    if (_currentIndex > 0) {
      _currentIndex--;
      await play(_queue[_currentIndex]);
    }
  }

  Future<void> togglePlay() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> stop() async {
    await _player.stop();
    _currentIndex = -1;
    notifyListeners();
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    StorageService.setDarkMode(_isDarkMode);
    notifyListeners();
  }

  void setAutoplay(bool value) {
    _autoplay = value;
    StorageService.setAutoplay(value);
    notifyListeners();
  }

  void setAudioQuality(String quality) {
    _audioQuality = quality;
    StorageService.setAudioQuality(quality);
    notifyListeners();
  }

  void toggleShuffle() {
    _shuffleMode = !_shuffleMode;
    if (_shuffleMode) {
      _queue.shuffle();
    }
    notifyListeners();
  }

  void cycleRepeat() {
    switch (_repeatMode) {
      case RepeatMode.off:
        _repeatMode = RepeatMode.all;
        break;
      case RepeatMode.all:
        _repeatMode = RepeatMode.one;
        break;
      case RepeatMode.one:
        _repeatMode = RepeatMode.off;
        break;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
