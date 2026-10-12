// Unit tests for StreamResolver.
//
// The resolver delegates to an injectable AudioUrlLookup so these tests use a
// fake lookup instead of hitting YouTube.

import 'package:flutter_test/flutter_test.dart';
import 'package:nekomusic/services/stream_resolver.dart';
import 'package:nekomusic/services/stream_resolver_lookup_io.dart';

void main() {
  group('StreamResolver', () {
    test('returns the URL produced by the lookup', () async {
      final resolver = StreamResolver(
        lookup: (String videoId) async => 'https://example.com/audio.mp4?iq=1',
      );

      final result = await resolver.resolve('dQw4w9WgXcQ');

      expect(result, 'https://example.com/audio.mp4?iq=1');
    });

    test('returns null when the lookup throws', () async {
      final resolver = StreamResolver(
        lookup: (String videoId) async => throw Exception('network down'),
      );

      final result = await resolver.resolve('dQw4w9WgXcQ');

      expect(result, isNull);
    });

    test('returns null when the lookup returns null', () async {
      final resolver = StreamResolver(
        lookup: (String videoId) async => null,
      );

      final result = await resolver.resolve('dQw4w9WgXcQ');

      expect(result, isNull);
    });
  });

  group('resolveWithRetry', () {
    // YouTube intermittently returns stream URLs that answer 403 at the CDN.
    // The lookup must verify each URL and re-extract when it is dead.
    test('returns the URL when the first probe succeeds', () async {
      var extractions = 0;

      final result = await resolveWithRetry(
        (String videoId) async {
          extractions++;
          return 'https://example.com/audio-1';
        },
        (String url) async => true,
        'dQw4w9WgXcQ',
      );

      expect(result, 'https://example.com/audio-1');
      expect(extractions, 1);
    });

    test('re-extracts when the probed URL is dead', () async {
      var extractions = 0;

      final result = await resolveWithRetry(
        (String videoId) async {
          extractions++;
          return 'https://example.com/audio-$extractions';
        },
        (String url) async => !url.endsWith('-1'),
        'dQw4w9WgXcQ',
      );

      expect(result, 'https://example.com/audio-2');
      expect(extractions, 2);
    });

    test('returns null when every probed URL is dead', () async {
      final result = await resolveWithRetry(
        (String videoId) async => 'https://example.com/audio-dead',
        (String url) async => false,
        'dQw4w9WgXcQ',
        maxAttempts: 3,
      );

      expect(result, isNull);
    });

    test('does not probe when extraction yields no streams', () async {
      var probes = 0;

      final result = await resolveWithRetry(
        (String videoId) async => null,
        (String url) async {
          probes++;
          return true;
        },
        'dQw4w9WgXcQ',
      );

      expect(result, isNull);
      expect(probes, 0);
    });

    test('stops retrying when extraction itself throws', () async {
      var attempts = 0;

      final result = await resolveWithRetry(
        (String videoId) async {
          attempts++;
          throw Exception('network down');
        },
        (String url) async => true,
        'dQw4w9WgXcQ',
      );

      expect(result, isNull);
      expect(attempts, 1);
    });
  });
}
