import 'dart:html' as html;
import 'dart:js' as js;
import '../models/song.dart';

Future<void> downloadFile(String url, Song song) async {
  final filename = '${song.title}.mp3';

  // Use JS fetch to download as blob, then trigger save dialog
  await js.context.callMethod('eval', ['''
    (async () => {
      const response = await fetch("$url");
      const blob = await response.blob();
      const blobUrl = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = blobUrl;
      a.download = "$filename";
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(blobUrl);
    })()
  ''']);
}
