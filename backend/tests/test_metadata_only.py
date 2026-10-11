"""Metadata-only contract tests for the on-device playback migration (TDD red).

These tests encode the *shape* of the Flask API after streaming/YouTube-download
endpoints are removed. They are deliberately written BEFORE the deletion work:

* The seven route-removal tests FAIL right now (the routes still exist) and
  must pass once task 6 deletes them.
* The kept-route, health, and search-shape tests PASS now and must keep
  passing afterwards.

Deletion assertions are hermetic: they inspect ``app.url_map`` instead of
issuing HTTP requests, so no test ever reaches YouTube/yt-dlp.
"""

import unittest

from app import app

RULES = {r.rule for r in app.url_map.iter_rules()}


class KeptRouteTests(unittest.TestCase):
    """Routes that must remain registered after the migration."""

    def test_search_route_present(self):
        self.assertIn("/api/search", RULES)

    def test_song_route_present(self):
        self.assertIn("/api/song/<song_id>", RULES)

    def test_playlist_route_present(self):
        self.assertIn("/api/playlist/<playlist_id>", RULES)

    def test_health_route_present(self):
        self.assertIn("/api/health", RULES)


class RemovedRouteTests(unittest.TestCase):
    """Routes that must be unregistered after the migration.

    Each test FAILS in the red state (the route is still present) and passes
    once task 6 deletes the corresponding endpoint.
    """

    def test_stream_route_removed(self):
        self.assertNotIn(
            "/api/stream/<song_id>",
            RULES,
            "route '/api/stream/<song_id>' still present; it must be removed",
        )

    def test_download_route_removed(self):
        self.assertNotIn(
            "/api/download/<song_id>",
            RULES,
            "route '/api/download/<song_id>' still present; it must be removed",
        )

    def test_save_route_removed(self):
        self.assertNotIn(
            "/api/save/<song_id>",
            RULES,
            "route '/api/save/<song_id>' still present; it must be removed",
        )

    def test_downloads_route_removed(self):
        self.assertNotIn(
            "/api/downloads",
            RULES,
            "route '/api/downloads' still present; it must be removed",
        )

    def test_download_status_route_removed(self):
        self.assertNotIn(
            "/api/downloads/<song_id>",
            RULES,
            "route '/api/downloads/<song_id>' still present; it must be removed",
        )

    def test_downloaded_file_route_removed(self):
        self.assertNotIn(
            "/api/downloads/<song_id>/file",
            RULES,
            "route '/api/downloads/<song_id>/file' still present; it must be removed",
        )

    def test_probe_route_removed(self):
        self.assertNotIn(
            "/api/probe/<song_id>",
            RULES,
            "route '/api/probe/<song_id>' still present; it must be removed",
        )


class RouteShapeTests(unittest.TestCase):
    """HTTP-level checks that are local-only (no network, no yt-dlp)."""

    def setUp(self):
        self.client = app.test_client()

    def test_health_returns_200(self):
        resp = self.client.get("/api/health")
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp.get_json().get("status"), "ok")

    def test_search_without_query_is_not_404(self):
        # Missing 'q' must yield a client error (400), NOT 404 -- proving the
        # route still exists while rejecting the bad request before any
        # network call is made.
        resp = self.client.get("/api/search")
        self.assertNotEqual(resp.status_code, 404)


if __name__ == "__main__":
    unittest.main()
