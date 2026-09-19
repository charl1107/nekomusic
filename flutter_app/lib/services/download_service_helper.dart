import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/song.dart';

typedef ProgressCallback = void Function(double progress);

Future<void> downloadFile(String url, Song song, {ProgressCallback? onProgress}) async {
  final dir = await getApplicationDocumentsDirectory();
  final filePath = '${dir.path}/${song.id}.mp3';
  final file = File(filePath);

  // Simple HTTP download for desktop
  final request = await HttpClient().getUrl(Uri.parse(url));
  final response = await request.close();
  final sink = file.openWrite();
  await response.pipe(sink);

  // Report progress (simplified - just call with 1.0 when done)
  if (onProgress != null) {
    onProgress(1.0);
  }
}

Future<void> deleteFile(String songId) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$songId.mp3');
    if (await file.exists()) {
      await file.delete();
    }
  } catch (e) {
    // Ignore deletion errors
  }
}

Future<String> saveToDeviceFile(Song song) async {
  final dir = await getDownloadsDirectory();
  final filePath = '${dir?.path ?? ''}/${song.title}.mp3';
  final sourceFile = File('${(await getApplicationDocumentsDirectory()).path}/${song.id}.mp3');

  if (await sourceFile.exists()) {
    await sourceFile.copy(filePath);
    return filePath;
  }
  throw Exception('Downloaded file not found');
}
