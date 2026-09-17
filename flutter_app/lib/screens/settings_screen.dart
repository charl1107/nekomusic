import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/player_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playerService = context.watch<PlayerService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionHeader('Appearance'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Use dark theme'),
            value: playerService.isDarkMode,
            onChanged: (_) => playerService.toggleDarkMode(),
          ),
          const Divider(),
          const _SectionHeader('Playback'),
          SwitchListTile(
            title: const Text('Autoplay'),
            subtitle: const Text('Automatically play next song'),
            value: playerService.autoplay,
            onChanged: (value) => playerService.setAutoplay(value),
          ),
          ListTile(
            title: const Text('Audio Quality'),
            subtitle: Text(playerService.audioQuality),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showQualityDialog(context, playerService),
          ),
          const Divider(),
          const _SectionHeader('About'),
          const ListTile(
            title: Text('Version'),
            subtitle: Text('1.0.0'),
          ),
          ListTile(
            title: const Text('NekoMusic'),
            subtitle: const Text('A music player built with Flutter'),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  void _showQualityDialog(BuildContext context, PlayerService playerService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Audio Quality'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['128kbps', '192kbps', '320kbps'].map((quality) {
            return RadioListTile<String>(
              title: Text(quality),
              value: quality,
              groupValue: playerService.audioQuality,
              onChanged: (value) {
                if (value != null) {
                  playerService.setAudioQuality(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
