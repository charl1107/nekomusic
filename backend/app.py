from flask import Flask, jsonify, request, send_file, Response
from flask_cors import CORS
from services.api_client import YouTubeAPIClient
import os
import json
import threading
import time

app = Flask(__name__)
CORS(app)

api_client = YouTubeAPIClient()

# Downloads folder and tracking
DOWNLOADS_DIR = os.path.join(os.path.dirname(__file__), 'downloads')
os.makedirs(DOWNLOADS_DIR, exist_ok=True)

# In-memory download tracking
download_status = {}  # {song_id: {"state": "downloading|completed|error", "progress": 0-100, "filename": "..."}}


@app.route("/api/search", methods=["GET"])
def search():
    query = request.args.get("q", "")
    if not query:
        return jsonify({"error": "Query parameter 'q' is required"}), 400
    results = api_client.search(query)
    return jsonify(results)


@app.route("/api/song/<song_id>", methods=["GET"])
def get_song(song_id):
    song = api_client.get_song(song_id)
    if not song:
        return jsonify({"error": "Song not found"}), 404
    return jsonify(song)


@app.route("/api/stream/<song_id>", methods=["GET"])
def stream(song_id):
    audio_url = api_client.get_audio_url(song_id)
    if not audio_url:
        return jsonify({"error": "Audio not available"}), 404
    return jsonify({"url": audio_url})


@app.route("/api/playlist/<playlist_id>", methods=["GET"])
def get_playlist(playlist_id):
    results = api_client.get_playlist(playlist_id)
    return jsonify(results)


@app.route("/api/download/<song_id>", methods=["GET"])
def download(song_id):
    """Stream audio for playback (no download)"""
    audio_url = api_client.get_audio_url(song_id)
    if not audio_url:
        return jsonify({"error": "Audio not available", "detail": api_client.last_audio_error}), 404

    import requests as req
    headers = {
        "Referer": "https://www.youtube.com/",
        "Origin": "https://www.youtube.com",
    }
    upstream = req.get(audio_url, headers=headers, timeout=30, stream=True)
    upstream.raise_for_status()

    content_length = upstream.headers.get("Content-Length")

    def generate():
        for chunk in upstream.iter_content(chunk_size=8192):
            if chunk:
                yield chunk

    resp_headers = {
        "Content-Type": "audio/mpeg",
        "Content-Disposition": f'inline; filename="{song_id}.mp3"',
    }
    if content_length:
        resp_headers["Content-Length"] = content_length

    return Response(generate(), headers=resp_headers)


def download_in_background(song_id, song_title):
    """Download song to server downloads folder in background"""
    try:
        download_status[song_id] = {
            "state": "downloading",
            "progress": 0,
            "filename": f"{song_title}.mp3",
            "song_id": song_id,
        }

        audio_url = api_client.get_audio_url(song_id)
        if not audio_url:
            download_status[song_id]["state"] = "error"
            download_status[song_id]["error"] = "Audio not available"
            return

        import requests as req
        headers = {
            "Referer": "https://www.youtube.com/",
            "Origin": "https://www.youtube.com",
        }
        upstream = req.get(audio_url, headers=headers, timeout=60, stream=True)
        upstream.raise_for_status()

        total_size = int(upstream.headers.get("Content-Length", 0))
        downloaded = 0

        # Sanitize filename
        safe_title = "".join(c if c.isalnum() or c in " -_" else "_" for c in song_title)
        filepath = os.path.join(DOWNLOADS_DIR, f"{safe_title}.mp3")

        with open(filepath, 'wb') as f:
            for chunk in upstream.iter_content(chunk_size=8192):
                if chunk:
                    f.write(chunk)
                    downloaded += len(chunk)
                    if total_size > 0:
                        progress = int((downloaded / total_size) * 100)
                        download_status[song_id]["progress"] = progress

        download_status[song_id]["state"] = "completed"
        download_status[song_id]["progress"] = 100
        download_status[song_id]["filepath"] = filepath

    except Exception as e:
        download_status[song_id]["state"] = "error"
        download_status[song_id]["error"] = str(e)


@app.route("/api/save/<song_id>", methods=["POST"])
def save_download(song_id):
    """Start background download and save to server"""
    data = request.get_json() or {}
    song_title = data.get("title", song_id)

    if song_id in download_status and download_status[song_id]["state"] == "downloading":
        return jsonify({"status": "already_downloading"})

    thread = threading.Thread(target=download_in_background, args=(song_id, song_title))
    thread.daemon = True
    thread.start()

    return jsonify({"status": "started"})


@app.route("/api/downloads", methods=["GET"])
def get_downloads():
    """Get all download statuses"""
    return jsonify(list(download_status.values()))


@app.route("/api/downloads/<song_id>", methods=["GET"])
def get_download_status(song_id):
    """Get status of a specific download"""
    if song_id in download_status:
        return jsonify(download_status[song_id])
    return jsonify({"state": "not_found"}), 404


@app.route("/api/downloads/<song_id>/file", methods=["GET"])
def get_downloaded_file(song_id):
    """Download the saved file from server"""
    if song_id not in download_status or download_status[song_id]["state"] != "completed":
        return jsonify({"error": "Download not completed"}), 404

    filepath = download_status[song_id].get("filepath")
    if not filepath or not os.path.exists(filepath):
        return jsonify({"error": "File not found"}), 404

    return send_file(filepath, as_attachment=True, download_name=download_status[song_id]["filename"])


@app.route("/api/health", methods=["GET"])
def health():
    return jsonify({"status": "ok", "app": "Capu Tune"})


if __name__ == "__main__":
    app.run(debug=True, host='0.0.0.0', port=int(os.environ.get("PORT", 5000)))
