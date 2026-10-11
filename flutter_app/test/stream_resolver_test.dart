// Unit tests for StreamResolver.
//
// The resolver delegates to an injectable AudioUrlLookup so these tests use a
// fake lookup instead of hitting YouTube.

import 'package:flutter_test/flutter_test.dart';
import 'package:nekomusic/services/stream_resolver.dart';

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
}
