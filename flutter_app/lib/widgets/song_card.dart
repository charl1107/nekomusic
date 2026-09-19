import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../services/download_service.dart';
import '../services/player_service.dart';

class SongCard extends StatelessWidget {
  final Song song;
  final VoidCallback? onTap;
  final bool isCompact;

  const SongCard({
    super.key,
    required this.song,
    this.onTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return _buildCompactCard(context);
    }
    return _buildFullCard(context);
  }

  Widget _buildCompactCard(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: song.thumbnail != null
                  ? Image.network(
                      song.thumbnail!,
                      width: 140,
                      height: 140,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.secondary,
                          ],
                        ),
                      ),
                      child: const Icon(Icons.music_note, color: Colors.white),
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              song.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              song.artist,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: song.thumbnail != null
              ? Image.network(
                  song.thumbnail!,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                )
              : Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                  ),
                  child: Icon(
                    Icons.music_note,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
        ),
        title: Text(
          song.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          song.artist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (song.duration != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  song.duration!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            IconButton(
              icon: Icon(
                context.read<PlayerService>().isFavorite(song.id)
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: context.read<PlayerService>().isFavorite(song.id)
                    ? Theme.of(context).colorScheme.primary
                    : null,
                size: 20,
              ),
              onPressed: () {
                context.read<PlayerService>().toggleFavorite(song);
              },
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showOptions(context),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  void _showOptions(BuildContext context) {
    final isDownloaded = context.read<DownloadService>().getState(song.id) == DownloadState.downloaded;

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
              leading: Consumer<DownloadService>(
                builder: (context, downloadService, _) {
                  final state = downloadService.getState(song.id);
                  final progress = downloadService.getProgress(song.id);
                  if (state == DownloadState.downloading) {
                    return SizedBox(
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
                    );
                  }
                  return Icon(
                    state == DownloadState.downloaded
                        ? Icons.download_done
                        : Icons.download,
                  );
                },
              ),
              title: const Text('Download'),
              onTap: () {
                final downloadService = context.read<DownloadService>();
                final state = downloadService.getState(song.id);
                if (state == DownloadState.downloaded) {
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
                  final downloadService = context.read<DownloadService>();
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
              leading: Icon(
                context.read<PlayerService>().isFavorite(song.id)
                    ? Icons.favorite
                    : Icons.favorite_border,
              ),
              title: const Text('Add to favorites'),
              onTap: () {
                context.read<PlayerService>().toggleFavorite(song);
                Navigator.pop(context);
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
}
