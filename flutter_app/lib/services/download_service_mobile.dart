import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/song.dart';

Future<void> downloadFile(String url, Song song) async {
  if (Platform.isAndroid) {
    final status = await Permission.storage.request();
    if (!status.isGranted) return;
  }

  final dir = await getApplicationDocumentsDirectory();
  final filePath = '${dir.path}/${song.id}.mp3';
  final dio = Dio();
  await dio.download(url, filePath);
}
