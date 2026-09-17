import 'dart:html' as html;
import '../models/song.dart';

Future<void> downloadFile(String url, Song song) async {
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', '${song.title}.mp3')
    ..style.display = 'none';
  html.document.body!.children.add(anchor);
  anchor.click();
  anchor.remove();
}
