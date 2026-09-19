import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../services/player_service.dart';
import '../screens/player_screen.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final playerService = context.watch<PlayerService>();
    final song = playerService.currentSong;

    if (song == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PlayerScreen()),
        );
      },
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: song.thumbnail != null
                      ? CachedNetworkImage(
                          imageUrl: song.thumbnail!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 48,
                            height: 48,
                            color: Colors.grey[300],
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 48,
                            height: 48,
                            color: Theme.of(context).colorScheme.primaryContainer,
                            child: Icon(
                              Icons.music_note,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        )
                      : Container(
                          width: 48,
                          height: 48,
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
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        song.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    playerService.isPlaying ? Icons.pause : Icons.play_arrow,
                  ),
                  onPressed: () => playerService.togglePlay(),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  onPressed: () => playerService.playNext(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
