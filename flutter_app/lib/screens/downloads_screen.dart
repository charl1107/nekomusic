import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../services/storage_service.dart';
import '../services/player_service.dart';
import '../widgets/song_card.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  List<Song> _downloads = [];

  @override
  void initState() {
    super.initState();
    _loadDownloads();
  }

  void _loadDownloads() {
    setState(() {
      _downloads = StorageService.getDownloads();
    });
  }

  @override
  Widget build(BuildContext context) {
    final playerService = context.watch<PlayerService>();
    _downloads = StorageService.getDownloads();
    return Scaffold(
      appBar: AppBar(title: const Text('Downloads')),
      body: _downloads.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.download_done, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No downloads yet.\nTap the download icon on any song!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _downloads.length,
              itemBuilder: (context, index) {
                final song = _downloads[index];
                return SongCard(
                  song: song,
                  onTap: () {
                    playerService.playList(
                      _downloads,
                      startIndex: index,
                    );
                  },
                );
              },
            ),
    );
  }
}
