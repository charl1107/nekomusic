import 'dart:async';
import 'dart:html' as html;
import '../models/song.dart';

typedef ProgressCallback = void Function(double progress);

Future<void> downloadFile(String url, Song song,
    {ProgressCallback? onProgress}) async {
  final xhr = html.HttpRequest();
  xhr.open('GET', url, async: true);
  xhr.responseType = 'blob';

  xhr.onProgress.listen((e) {
    if (e.lengthComputable && e.total != null && e.total! > 0 && onProgress != null) {
      onProgress(e.loaded! / e.total!);
    }
  });

  final completer = Completer<void>();
  xhr.onLoad.listen((_) {
    if (xhr.status == 200) {
      completer.complete();
    } else {
      completer.completeError(Exception('Download failed: ${xhr.status}'));
    }
  });

  xhr.onError.listen((_) {
    completer.completeError(Exception('Download failed'));
  });

  xhr.send();
  return completer.future;
}

Future<String> saveToDevice(Song song) async {
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
