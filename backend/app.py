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
    audio_stream = api_client.get_audio_stream(song_id)
    if not audio_stream:
        return jsonify({"error": "Audio not available"}), 404
    return Response(
        audio_stream,
        mimetype="audio/mpeg",
        headers={"Content-Disposition": f"inline; filename={song_id}.mp3"},
    )


@app.route("/api/download/<song_id>", methods=["GET"])
def download(song_id):
    audio_data = api_client.get_audio_stream(song_id)
    if not audio_data:
        return jsonify({"error": "Audio not available"}), 404
    return send_file(
        io.BytesIO(audio_data),
        mimetype="audio/mpeg",
        as_attachment=True,
        download_name=f"{song_id}.mp3",
    )


@app.route("/api/health", methods=["GET"])
def health():
    return jsonify({"status": "ok", "app": "NekoMusic"})


if __name__ == "__main__":
    app.run(debug=True, port=5000)
