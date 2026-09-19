import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../models/song.dart';
import '../services/storage_service.dart';
import '../services/player_service.dart';
import '../services/api_service.dart';
import '../widgets/song_card.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  List<Song> _downloads = [];
  List<Map<String, dynamic>> _activeDownloads = [];
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadDownloads();
    _loadActiveDownloads();
    // Poll for active downloads every 2 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _loadActiveDownloads();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _loadDownloads() {
    setState(() {
      _downloads = StorageService.getDownloads();
    });
  }

  Future<void> _loadActiveDownloads() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/downloads'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final active = data
            .where((d) => d['state'] == 'downloading')
            .toList();
        if (mounted) {
          setState(() {
            _activeDownloads = List<Map<String, dynamic>>.from(active);
          });
        }
      }
    } catch (e) {
      // Ignore errors - will retry on next tick
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerService = context.watch<PlayerService>();
    _downloads = StorageService.getDownloads();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloads'),
        actions: [
          if (_activeDownloads.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${_activeDownloads.length} downloading',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Active downloads section
          if (_activeDownloads.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              child: Row(
                children: [
                  const Icon(Icons.cloud_download, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Downloading ${_activeDownloads.length} song(s) to server...',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _activeDownloads.length,
              itemBuilder: (context, index) {
                final download = _activeDownloads[index];
                final progress = (download['progress'] ?? 0) / 100.0;
                return ListTile(
                  leading: SizedBox(
                    width: 40,
                    height: 40,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          strokeWidth: 3,
                          value: progress,
                        ),
                        Center(
                          child: Text(
                            '${(progress * 100).toInt()}%',
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
                  title: Text(
                    download['filename'] ?? 'Unknown',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: const Text('Saving to server...'),
                );
              },
            ),
            const Divider(),
          ],
          // Completed downloads
          Expanded(
            child: _downloads.isEmpty && _activeDownloads.isEmpty
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
                : _downloads.isEmpty
                    ? const Center(
                        child: Text(
                          'Waiting for downloads to complete...',
                          style: TextStyle(color: Colors.grey),
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
          ),
        ],
      ),
    );
  }
}
