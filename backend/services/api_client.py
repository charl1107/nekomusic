import os
import tempfile

import requests
import yt_dlp
from config import Config


class YouTubeAPIClient:
    def __init__(self):
        self.api_key = Config.YOUTUBE_API_KEY
        self.base_url = Config.YOUTUBE_API_BASE

        # Optional YouTube cookies (Netscape cookies.txt contents) to bypass
        # bot checks from datacenter IPs. Read from env, written to a temp file.
        self.cookiefile = None
        self.cookie_count = 0
        cookies = os.getenv("YOUTUBE_COOKIES", "").strip()
        if cookies:
            self.cookiefile = os.path.join(tempfile.gettempdir(), "yt_cookies.txt")
            with open(self.cookiefile, "w", encoding="utf-8") as f:
                f.write(cookies if cookies.endswith("\n") else cookies + "\n")
            with open(self.cookiefile, encoding="utf-8") as f:
                # Netscape cookie rows contain >=5 tabs (comments/header don't)
                self.cookie_count = sum(1 for line in f if line.count("\t") >= 5)

    def search(self, query):
        if not self.api_key:
            return self._mock_search(query)
        try:
            response = requests.get(
                f"{self.base_url}/search",
                params={
                    "part": "snippet",
                    "q": query,
                    "type": "video",
                    "videoCategoryId": "10",
                    "maxResults": 20,
                    "key": self.api_key,
                },
                timeout=10,
            )
            response.raise_for_status()
            data = response.json()
            results = []
            for item in data.get("items", []):
                video_id = item.get("id", {}).get("videoId")
                if not video_id:
                    continue
                snippet = item["snippet"]
                results.append({
                    "id": video_id,
                    "title": snippet["title"],
                    "artist": snippet["channelTitle"],
                    "thumbnail": snippet["thumbnails"]["high"]["url"],
                    "duration": None,
                })
            if results:
                video_ids = [r["id"] for r in results]
                durations = self._get_durations(video_ids)
                for r in results:
                    r["duration"] = durations.get(r["id"])
            return {"results": results}
        except requests.RequestException:
            return self._mock_search(query)

    def get_song(self, song_id):
        if not self.api_key:
            return self._mock_song(song_id)
        try:
            response = requests.get(
                f"{self.base_url}/videos",
                params={
                    "part": "snippet,contentDetails",
                    "id": song_id,
                    "key": self.api_key,
                },
                timeout=10,
            )
            response.raise_for_status()
            items = response.json().get("items", [])
            if not items:
                return None
            item = items[0]
            snippet = item["snippet"]
            duration = self._parse_duration(
                item.get("contentDetails", {}).get("duration")
            )
            return {
                "id": song_id,
                "title": snippet["title"],
                "artist": snippet["channelTitle"],
                "album": None,
                "thumbnail": snippet["thumbnails"]["high"]["url"],
                "duration": duration,
            }
        except requests.RequestException:
            return self._mock_song(song_id)

    @staticmethod
    def _best_audio_url(info):
        """Pick a playable URL out of an extract_info result."""
        if info.get("url"):
            return info["url"]
        fmts = [f for f in (info.get("formats") or []) if f.get("url")]
        if not fmts:
            return None

        def score(f):
            audio = f.get("acodec") not in (None, "none")
            nofrag = not f.get("fragments")
            audio_only = f.get("vcodec") in (None, "none")
            return (audio and nofrag and audio_only, audio and nofrag, audio)

        return max(fmts, key=score).get("url")

    def get_audio_url(self, song_id):
        video_url = f"https://www.youtube.com/watch?v={song_id}"
        client_sets = ["android_vr", "android", "ios", "mweb", "tv", "web"]
        self.last_audio_error = None
        self.audio_errors = []
        for client in client_sets:
            base_opts = {
                "quiet": True,
                "no_warnings": True,
                "geo_bypass": True,
                "extractor_args": {"youtube": {"player_client": [client]}},
            }
            if self.cookiefile:
                base_opts["cookiefile"] = self.cookiefile
            # 1) preferred: audio-only format selection; 2) fallback: default
            # selection, then pick the best audio URL manually.
            for fmt in ("bestaudio/best", None):
                opts = dict(base_opts)
                if fmt:
                    opts["format"] = fmt
                try:
                    with yt_dlp.YoutubeDL(opts) as ydl:
                        info = ydl.extract_info(video_url, download=False)
                    url = self._best_audio_url(info)
                    if url:
                        return url
                    fmts = info.get("formats") or []
                    self.audio_errors.append(
                        f"{client} fmt={fmt}: no-url _type={info.get('_type')} "
                        f"entries={len(info.get('entries') or [])} "
                        f"fmts={[(f.get('format_id'), f.get('acodec'), bool(f.get('url'))) for f in fmts][:10]} "
                        f"keys={sorted(info.keys())[:15]}"
                    )
                except Exception as e:
                    self.last_audio_error = f"{client} fmt={fmt}: {e}"
                    self.audio_errors.append(f"{client} fmt={fmt}: {e}")
                    print(f"[yt-dlp] {client} fmt={fmt} failed: {e}", flush=True)
                    continue
        return None

    def get_playlist(self, playlist_id):
        if not self.api_key:
            return self._mock_playlist(playlist_id)
        try:
            results = []
            next_page_token = None
            while True:
                params = {
                    "part": "snippet",
                    "playlistId": playlist_id,
                    "maxResults": 50,
                    "key": self.api_key,
                }
                if next_page_token:
                    params["pageToken"] = next_page_token
                response = requests.get(
                    f"{self.base_url}/playlistItems",
                    params=params,
                    timeout=10,
                )
                response.raise_for_status()
                data = response.json()
                for item in data.get("items", []):
                    snippet = item["snippet"]
                    video_id = snippet.get("resourceId", {}).get("videoId")
                    if video_id:
                        results.append({
                            "id": video_id,
                            "title": snippet["title"],
                            "artist": snippet["channelTitle"],
                            "thumbnail": snippet["thumbnails"]["high"]["url"],
                            "duration": None,
                        })
                next_page_token = data.get("nextPageToken")
                if not next_page_token:
                    break
            if results:
                video_ids = [r["id"] for r in results]
                durations = self._get_durations(video_ids)
                for r in results:
                    r["duration"] = durations.get(r["id"])
            return {"results": results}
        except requests.RequestException:
            return self._mock_playlist(playlist_id)

    def get_audio_stream(self, song_id):
        audio_url = self.get_audio_url(song_id)
        if not audio_url:
            return None
        try:
            headers = {
                "Referer": "https://www.youtube.com/",
                "Origin": "https://www.youtube.com",
            }
            response = requests.get(
                audio_url, headers=headers, timeout=30, stream=True
            )
            response.raise_for_status()
            return response.content
        except requests.RequestException:
            return None

    def _get_durations(self, video_ids):
        if not video_ids:
            return {}
        try:
            response = requests.get(
                f"{self.base_url}/videos",
                params={
                    "part": "contentDetails",
                    "id": ",".join(video_ids),
                    "key": self.api_key,
                },
                timeout=10,
            )
            response.raise_for_status()
            durations = {}
            for item in response.json().get("items", []):
                durations[item["id"]] = self._parse_duration(
                    item.get("contentDetails", {}).get("duration")
                )
            return durations
        except requests.RequestException:
            return {}

    def _parse_duration(self, iso_duration):
        if not iso_duration:
            return None
        import re
        match = re.match(r"PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?", iso_duration)
        if not match:
            return None
        hours = int(match.group(1) or 0)
        minutes = int(match.group(2) or 0)
        seconds = int(match.group(3) or 0)
        total_minutes = hours * 60 + minutes
        return f"{total_minutes}:{seconds:02d}"

    def _mock_search(self, query):
        return {
            "results": [
                {
                    "id": "dQw4w9WgXcQ",
                    "title": f"{query} - Official Audio",
                    "artist": "Artist Name",
                    "thumbnail": "https://picsum.photos/300/300",
                    "duration": "3:45",
                },
                {
                    "id": "9bZkp7q19f0",
                    "title": f"{query} - Live Performance",
                    "artist": "Artist Name",
                    "thumbnail": "https://picsum.photos/300/300",
                    "duration": "5:12",
                },
            ]
        }

    def _mock_song(self, song_id):
        return {
            "id": song_id,
            "title": "Sample Song",
            "artist": "Sample Artist",
            "album": "Sample Album",
            "thumbnail": "https://picsum.photos/300/300",
            "duration": "3:45",
        }

    def _mock_playlist(self, playlist_id):
        return {
            "results": [
                {
                    "id": "mock_1",
                    "title": "Sample Song 1",
                    "artist": "Artist Name",
                    "thumbnail": "https://picsum.photos/300/300",
                    "duration": "3:45",
                }
            ]
        }
