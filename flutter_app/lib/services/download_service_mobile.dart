import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/song.dart';

typedef ProgressCallback = void Function(double progress);

Future<void> downloadFile(String url, Song song,
    {ProgressCallback? onProgress}) async {
  if (Platform.isAndroid) {
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      throw Exception('Storage permission denied');
    }
  }

  final dir = await getApplicationDocumentsDirectory();
  final filePath = '${dir.path}/${song.id}.mp3';
  final dio = Dio();
  await dio.download(
    url,
    filePath,
    onReceiveProgress: (received, total) {
      if (total > 0 && onProgress != null) {
        onProgress(received / total);
      }
    },
  );
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
  if (Platform.isAndroid) {
    final status = await Permission.storage.request();
    if (!status.isGranted) throw Exception('Storage permission denied');
  }

  // Source: app's cached download
  final appDir = await getApplicationDocumentsDirectory();
  final sourceFile = File('${appDir.path}/${song.id}.mp3');

  if (!await sourceFile.exists()) {
    throw Exception('File not found in cache');
  }

  // Destination: device Downloads folder
  Directory destDir;
  if (Platform.isAndroid) {
    destDir = Directory('/storage/emulated/0/Download');
    if (!await destDir.exists()) {
      destDir = await getExternalStorageDirectory() ?? appDir;
    }
  } else {
    destDir = await getApplicationDocumentsDirectory();
  }

  final destPath = '${destDir.path}/${song.title}.mp3';
  await sourceFile.copy(destPath);
  return destPath;
}
