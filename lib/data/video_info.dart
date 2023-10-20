enum VideoQuality {
  audio("audio"),
  video_144p("144p"),
  video_240p("240p"),
  video_360p("360p"),
  video_480p("480p"),
  video_720p("720p"),
  video_1080p("1080p");

  const VideoQuality(this.text);
  final String text;
}

class VideoInfo {
  final String videoId;
  final String title;
  final String author;
  final VideoQuality quality;

  VideoInfo(
    this.videoId,
    this.title,
    this.author,
    this.quality,
  );

  factory VideoInfo.fromJson(Map<String, dynamic> json) {
    return VideoInfo(
      json['videoId'] as String,
      json['title'] as String,
      json['author'] as String,
      _getVideoQuality(json['quality'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'videoId': videoId,
      'title': title,
      'author': author,
      'quality': quality.text,
    };
  }

  static VideoQuality _getVideoQuality(String qualityText) {
    switch (qualityText) {
      case 'audio':
        return VideoQuality.audio;
      case '144p':
        return VideoQuality.video_144p;
      case '240p':
        return VideoQuality.video_240p;
      case '360p':
        return VideoQuality.video_360p;
      case '480p':
        return VideoQuality.video_480p;
      case '720p':
        return VideoQuality.video_720p;
      case '1080p':
        return VideoQuality.video_1080p;
      default:
        throw ArgumentError('Invalid VideoQuality: $qualityText');
    }
  }
}
