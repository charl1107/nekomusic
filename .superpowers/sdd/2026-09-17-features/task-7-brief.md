# Task 7: Backend YouTube Playlist Endpoint

## Task Description

Add a backend endpoint to fetch YouTube playlist contents using the YouTube Data API v3.

## Files

- Modify: `backend/app.py`
- Modify: `backend/services/api_client.py`

## Requirements

### 1. Add get_playlist to api_client.py

```python
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
```

### 2. Add route to app.py

```python
@app.route("/api/playlist/<playlist_id>", methods=["GET"])
def get_playlist(playlist_id):
    results = api_client.get_playlist(playlist_id)
    return jsonify(results)
```

## Context

- YouTubeAPIClient already has `search`, `get_song`, `get_audio_url` methods
- YouTube Data API v3 playlistItems endpoint returns video items in a playlist
- Pagination is needed to fetch all items (maxResults: 50 per page)
- `_get_durations` method already exists for fetching video durations
- Mock fallback is needed for when API key is missing

## Your Job

1. Read the existing `C:\Users\Administrator\Downloads\nekocMusic\backend\services\api_client.py`
2. Read the existing `C:\Users\Administrator\Downloads\nekocMusic\backend\app.py`
3. Implement exactly what the task specifies
4. Verify the backend runs: `cd C:\Users\Administrator\Downloads\nekocMusic\backend; python -c "from app import app; print('Backend OK')"`
5. Commit your work with a descriptive message
6. Self-review your changes
7. Write your report to: C:\Users\Administrator\Downloads\nekocMusic\.superpowers\sdd\2026-09-17-features\task-7-report.md

## Report Format

Write your full report to the path above, then report back with ONLY:
- **Status:** DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
- Commits created (short SHA + subject)
- One-line test summary
- Your concerns, if any
- The report file path
