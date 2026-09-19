import 'dart:html' as html;
import '../models/song.dart';

typedef ProgressCallback = void Function(double progress);

Future<void> downloadFile(String url, Song song,
    {ProgressCallback? onProgress}) async {
  // On web, trigger browser download directly
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', '${song.title}.mp3')
    ..style.display = 'none';
  html.document.body!.children.add(anchor);
  anchor.click();
  anchor.remove();

  // Report as complete
  if (onProgress != null) {
    onProgress(1.0);
  }
}

Future<String> saveToDeviceFile(Song song) async {
  // On web, trigger browser download
  final url = 'http://localhost:5000/api/download/${song.id}';
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', '${song.title}.mp3')
    ..style.display = 'none';
  html.document.body!.children.add(anchor);
  anchor.click();
  anchor.remove();
  return 'Downloaded via browser';
}
