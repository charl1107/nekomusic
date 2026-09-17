class Song {
  final String id;
  final String title;
  final String artist;
  final String? album;
  final String? thumbnail;
  final String? duration;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    this.thumbnail,
    this.duration,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      artist: json['artist'] ?? '',
      album: json['album'],
      thumbnail: json['thumbnail'],
      duration: json['duration'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'thumbnail': thumbnail,
      'duration': duration,
    };
  }
}
