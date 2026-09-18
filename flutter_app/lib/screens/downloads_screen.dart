import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../services/storage_service.dart';
import '../services/player_service.dart';
import '../services/download_service.dart';
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

  void _showOptions(Song song) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_arrow),
              title: const Text('Play'),
              onTap: () {
                Navigator.pop(context);
                final playerService = context.read<PlayerService>();
                playerService.playList(_downloads, startIndex: _downloads.indexOf(song));
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone_android),
              title: const Text('Save to device'),
              onTap: () async {
                Navigator.pop(context);
                final downloadService = context.read<DownloadService>();
                final path = await downloadService.saveToDevice(song);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(path != null ? 'Saved to Downloads' : 'Failed to save'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Remove', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                final downloadService = context.read<DownloadService>();
                await downloadService.removeDownload(song.id);
                _loadDownloads();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerService = context.watch<PlayerService>();
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
