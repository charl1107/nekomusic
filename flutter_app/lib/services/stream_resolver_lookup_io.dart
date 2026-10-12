import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// Extracts an audio stream URL for [videoId]; null when none exist.
typedef AudioExtract = Future<String?> Function(String videoId);

/// Returns true when [url] answers a ranged request (i.e. is playable).
typedef UrlProbe = Future<bool> Function(String url);

/// Resolves [videoId] to the highest-bitrate audio-only stream URL using
/// youtube_explode_dart, verifying the URL before returning it.
///
/// YouTube intermittently hands out stream URLs that answer 403 at the CDN,
/// so each extracted URL is probed with a small ranged request and extraction
/// is retried (with backoff) while the URL is dead.
///
/// Returns null when the manifest contains no audio-only streams, when
/// extraction fails, or when no live URL is obtained within [maxAttempts]
/// (extraction errors propagate to the caller — `StreamResolver.resolve` in
/// `stream_resolver.dart` converts them to null).
Future<String?> defaultLookup(String videoId) => resolveWithRetry(
      _extractAudioUrl,
      probeUrl,
      videoId,
    );

Future<String?> _extractAudioUrl(String videoId) async {
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

/// Extracts and probes up to [maxAttempts] times, returning the first URL
/// that [probe] confirms live.
@visibleForTesting
Future<String?> resolveWithRetry(
  AudioExtract extract,
  UrlProbe probe,
  String videoId, {
  int maxAttempts = 3,
}) async {
  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    String? url;
    try {
      url = await extract(videoId);
    } catch (_) {
      // Extraction failures are reported by StreamResolver.resolve.
      return null;
    }
    if (url == null) {
      return null;
    }
    if (await probe(url)) {
      return url;
    }
    if (attempt < maxAttempts - 1) {
      await Future<void>.delayed(Duration(milliseconds: 250 * (attempt + 1)));
    }
  }
  return null;
}

/// Cheap liveness check: issues an open-ended ranged request for [url] and
/// stops after the first 64 bytes.
///
/// The range must be open-ended (`bytes=0-`): the CDN answers 206 to small
/// *bounded* ranges even for URLs it would refuse to actually stream, so a
/// bounded probe cannot detect the 403 state.
Future<bool> probeUrl(String url) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  try {
    final req = await client.getUrl(Uri.parse(url));
    req.headers.set('range', 'bytes=0-');
    final resp = await req.close().timeout(const Duration(seconds: 15));
    if (resp.statusCode != 200 && resp.statusCode != 206) {
      return false;
    }
    var bytes = 0;
    await for (final chunk in resp) {
      bytes += chunk.length;
      if (bytes >= 64) {
        break;
      }
    }
    return true;
  } catch (_) {
    return false;
  } finally {
    client.close(force: true);
  }
}
