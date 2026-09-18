import '../models/song.dart';

typedef ProgressCallback = void Function(double progress);

Future<void> downloadFile(String url, Song song,
    {ProgressCallback? onProgress}) async {}

Future<String> saveToDeviceFile(Song song) async => '';
