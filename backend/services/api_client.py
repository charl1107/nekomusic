import requests
from config import Config


class YouTubeAPIClient:
    def __init__(self):
        self.base_url = Config.API_BASE_URL
        self.headers = {
            "Authorization": f"Bearer {Config.API_KEY}",
            "Content-Type": "application/json",
        }

    def search(self, query):
        try:
            response = requests.get(
                f"{self.base_url}/search",
                params={"q": query},
                headers=self.headers,
                timeout=10,
            )
            response.raise_for_status()
            return response.json()
        except requests.RequestException:
            return self._mock_search(query)

    def get_song(self, song_id):
        try:
            response = requests.get(
                f"{self.base_url}/song/{song_id}",
                headers=self.headers,
                timeout=10,
            )
            response.raise_for_status()
            return response.json()
        except requests.RequestException:
            return self._mock_song(song_id)

    def get_audio_stream(self, song_id):
        try:
            response = requests.get(
                f"{self.base_url}/stream/{song_id}",
                headers=self.headers,
                timeout=30,
                stream=True,
            )
            response.raise_for_status()
            return response.content
        except requests.RequestException:
            return None

    def _mock_search(self, query):
        return {
            "results": [
                {
                    "id": "mock_1",
                    "title": f"{query} - Official Audio",
                    "artist": "Artist Name",
                    "thumbnail": "https://picsum.photos/300/300",
                    "duration": "3:45",
                },
                {
                    "id": "mock_2",
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
