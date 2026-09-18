from flask import Flask, jsonify, request, send_file, Response
from flask_cors import CORS
from services.api_client import YouTubeAPIClient
import io

app = Flask(__name__)
CORS(app)

api_client = YouTubeAPIClient()


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
    audio_url = api_client.get_audio_url(song_id)
    if not audio_url:
        return jsonify({"error": "Audio not available"}), 404

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


@app.route("/api/health", methods=["GET"])
def health():
    return jsonify({"status": "ok", "app": "NekoMusic"})


if __name__ == "__main__":
    app.run(debug=True, port=5000)
