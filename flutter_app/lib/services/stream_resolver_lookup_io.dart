import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// Resolves [videoId] to the highest-bitrate audio-only stream URL using
/// youtube_explode_dart.
///
/// Returns null when the manifest contains no audio-only streams. Extraction
/// errors propagate to the caller (`StreamResolver.resolve` in
/// `stream_resolver.dart` converts them to null).
Future<String?> defaultLookup(String videoId) async {
  final yt = YoutubeExplode();
  try {
    final manifest = await yt.videos.streamsClient.getManifest(videoId);
    if (manifest.audioOnly.isEmpty) {
      return null;
    }
    return manifest.audioOnly.withHighestBitrate().url.toString();
  } finally {
    yt.close();
  }
}
