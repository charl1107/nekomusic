import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/playlist.dart';
import '../services/player_service.dart';
import '../widgets/song_card.dart';

class PlaylistDetailScreen extends StatelessWidget {
  final Playlist playlist;
  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  Widget build(BuildContext context) {
    final playerService = context.watch<PlayerService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(playlist.name),
        actions: [
          if (playlist.songs.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.play_circle_fill),
              onPressed: () {
                playerService.playList(playlist.songs);
              },
            ),
        ],
      ),
      body: playlist.songs.isEmpty
          ? const Center(
              child: Text(
                'No songs in this playlist.\nAdd songs from search.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: playlist.songs.length,
              itemBuilder: (context, index) {
                return SongCard(
                  song: playlist.songs[index],
                  onTap: () {
                    playerService.playList(
                      playlist.songs,
                      startIndex: index,
                    );
                  },
                );
              },
            ),
    );
  }
}
