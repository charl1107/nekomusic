import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/playlist.dart';
import '../services/discovery_service.dart';
import '../services/storage_service.dart';
import 'playlist_detail_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<Playlist> _playlists = [];

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  void _loadPlaylists() {
    setState(() {
      _playlists = StorageService.getPlaylists();
    });
  }

  Future<void> _createPlaylist() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Playlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Playlist name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final playlist = Playlist(
        id: const Uuid().v4(),
        name: result,
      );
      await StorageService.addPlaylist(playlist);
      _loadPlaylists();
    }
  }

  Future<void> _deletePlaylist(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Playlist'),
        content: const Text('Are you sure you want to delete this playlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await StorageService.deletePlaylist(id);
      _loadPlaylists();
    }
  }

  Future<void> _importFromYouTube() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import from YouTube'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Paste YouTube playlist URL',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (result == null || result.trim().isEmpty) return;

    final songs = await DiscoveryService.importPlaylist(result.trim());
    if (!mounted) return;

    if (songs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No songs imported. Check the URL and try again.')),
      );
      return;
    }

    final existingPlaylists = StorageService.getPlaylists();
    final destination = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import playlist'),
        content: Text('Found ${songs.length} songs. Where should they go?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'new'),
            child: const Text('Create new'),
          ),
          if (existingPlaylists.isNotEmpty)
            TextButton(
              onPressed: () => Navigator.pop(context, 'existing'),
              child: const Text('Add to existing'),
            ),
        ],
      ),
    );

    if (!mounted || destination == null) return;

    if (destination == 'existing') {
      final selectedPlaylistId = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Choose a playlist'),
          content: SizedBox(
            width: double.maxFinite,
            height: 320,
            child: ListView.builder(
              itemCount: existingPlaylists.length,
              itemBuilder: (context, index) {
                final playlist = existingPlaylists[index];
                return ListTile(
                  title: Text(playlist.name),
                  subtitle: Text('${playlist.songs.length} songs'),
                  onTap: () => Navigator.pop(context, playlist.id),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );

      if (!mounted || selectedPlaylistId == null) return;

      final playlists = StorageService.getPlaylists();
      final playlistIndex =
          playlists.indexWhere((playlist) => playlist.id == selectedPlaylistId);
      if (playlistIndex == -1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('That playlist is no longer available.')),
        );
        return;
      }

      final playlist = playlists[playlistIndex];
      final songIds = playlist.songs.map((song) => song.id).toSet();
      final newSongs = songs.where((song) => songIds.add(song.id)).toList();
      if (newSongs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All imported songs are already in that playlist.')),
        );
        return;
      }

      playlists[playlistIndex] =
          playlist.copyWith(songs: [...playlist.songs, ...newSongs]);
      await StorageService.savePlaylists(playlists);
      if (!mounted) return;

      _loadPlaylists();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${newSongs.length} songs to "${playlist.name}".'),
        ),
      );
      return;
    }

    final nameController = TextEditingController(text: 'Imported Playlist');
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Playlist Name'),
        content: TextField(controller: nameController),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, nameController.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (name == null || name.trim().isEmpty) return;

    final playlist = Playlist(
      id: const Uuid().v4(),
      name: name.trim(),
      songs: songs,
    );
    await StorageService.addPlaylist(playlist);
    if (!mounted) return;
    _loadPlaylists();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.link),
            onPressed: _importFromYouTube,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createPlaylist,
        child: const Icon(Icons.add),
      ),
      body: _playlists.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.library_music, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No playlists yet.\nCreate one to get started!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _playlists.length,
              itemBuilder: (context, index) {
                final playlist = _playlists[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.queue_music,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    title: Text(playlist.name),
                    subtitle: Text('${playlist.songs.length} songs'),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'delete') {
                          _deletePlaylist(playlist.id);
                        }
                      },
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlaylistDetailScreen(playlist: playlist),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
