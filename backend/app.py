from flask import Flask, jsonify, request
from flask_cors import CORS
from services.api_client import YouTubeAPIClient
import os

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


@app.route("/api/playlist/<playlist_id>", methods=["GET"])
def get_playlist(playlist_id):
    results = api_client.get_playlist(playlist_id)
    return jsonify(results)


@app.route("/api/health", methods=["GET"])
def health():
    return jsonify({"status": "ok", "app": "Capu Tune"})


if __name__ == "__main__":
    app.run(debug=True, host='0.0.0.0', port=int(os.environ.get("PORT", 5000)))
