import 'dart:html' as html;
import 'dart:js' as js;
import '../models/song.dart';

typedef void ProgressCallback(double progress);

Future<void> downloadFile(String url, Song song,
    {ProgressCallback? onProgress}) async {
  // Use XMLHttpRequest for progress tracking, no popup
  final xhr = html.HttpRequest();
  xhr.open('GET', url, async: true);
  xhr.responseType = 'blob';

  xhr.onProgress.listen((e) {
    if (e.lengthComputable && onProgress != null) {
      onProgress(e.loaded / e.total);
    }
  });

  final completer = Completer<void>();
  xhr.onLoad.listen((_) {
    if (xhr.status == 200) {
      // Store blob in memory via JS (no download popup)
      js.context.callMethod('eval', ['''
        (async () => {
          const blob = xhr.response;
          window._nekocMusicBlobs = window._nekocMusicBlobs || {};
          window._nekocMusicBlobs["${song.id}"] = blob;
        })()
      ''']);
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

import 'dart:async';
