import 'dart:html' as html;
import '../models/song.dart';

typedef ProgressCallback = void Function(double progress);

Future<void> downloadFile(String url, Song song,
    {ProgressCallback? onProgress, dynamic cancelToken}) async {
  final anchor = html.AnchorElement(href: url);
  anchor.download = '${song.title}.mp3';
  anchor.click();
  if (onProgress != null) {
    onProgress(1.0);
  }
}

Future<String> saveToDeviceFile(Song song) async {
  throw Exception('Save to device not supported on web');
}
