import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/download_service.dart';
import '../services/player_service.dart';
import 'queue_screen.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playerService = context.watch<PlayerService>();
    final song = playerService.currentSong;

    if (song == null) {
      return const Scaffold(
        body: Center(child: Text('No song playing')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.queue_music),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QueueScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showOptions(context, song),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: song.thumbnail != null
                    ? Image.network(
                        song.thumbnail!,
                        width: 280,
                        height: 280,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.secondary,
                            ],
                          ),
                        ),
                        child: const Icon(
                          Icons.music_note,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
              ),
              const SizedBox(height: 24),
              Text(
                song.title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Consumer<DownloadService>(
                builder: (context, downloadService, _) {
                  final state = downloadService.getState(song.id);
                  final progress = downloadService.getProgress(song.id);
                  return IconButton(
                    icon: state == DownloadState.downloading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CircularProgressIndicator(
                                  strokeWidth: 2,
                                  value: progress,
                                  backgroundColor: Colors.grey[300],
                                ),
                                Center(
                                  child: Text(
                                    '${(progress * 100).toInt()}%',
                                    style: const TextStyle(fontSize: 8),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Icon(
                            state == DownloadState.downloaded
                                ? Icons.download_done
                                : Icons.download,
                            color: state == DownloadState.downloaded
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                    onPressed: state == DownloadState.downloading
                        ? null
                        : () {
                            if (state == DownloadState.downloaded) {
                              downloadService.removeDownload(song.id);
                            } else {
                              downloadService.downloadSong(song);
                            }
                          },
                  );
                },
              ),
              Text(
                song.artist,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              StreamBuilder<Duration>(
                stream: playerService.positionStream,
                builder: (context, snapshot) {
                  final position = snapshot.data ?? Duration.zero;
                  final duration = playerService.duration;
                  return Column(
                    children: [
                      Slider(
                        value: position.inSeconds.toDouble(),
                        max: duration.inSeconds.toDouble().clamp(1, double.infinity),
                        onChanged: (value) {
                          playerService.seek(Duration(seconds: value.toInt()));
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_formatDuration(position)),
                            Text(_formatDuration(duration)),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shuffle),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_previous, size: 36),
                    onPressed: () => playerService.playPrevious(),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        playerService.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 36,
                      ),
                      onPressed: () => playerService.togglePlay(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next, size: 36),
                    onPressed: () => playerService.playNext(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.repeat),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showOptions(BuildContext context, song) {
    final downloadService = context.read<DownloadService>();
    final state = downloadService.getState(song.id);
    final isDownloaded = state == DownloadState.downloaded;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.playlist_add),
              title: const Text('Add to playlist'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(isDownloaded ? Icons.download_done : Icons.download),
              title: Text(isDownloaded ? 'Remove download' : 'Download'),
              onTap: () {
                if (isDownloaded) {
                  downloadService.removeDownload(song.id);
                } else {
                  downloadService.downloadSong(song);
                }
                Navigator.pop(context);
              },
            ),
            if (isDownloaded)
              ListTile(
                leading: const Icon(Icons.phone_android),
                title: const Text('Save to device'),
                onTap: () async {
                  Navigator.pop(context);
                  final path = await downloadService.saveToDevice(song);
                  if (context.mounted) {
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
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
