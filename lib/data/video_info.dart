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
  final String id;
  final String title;
  final String author;
  final VideoQuality quality;

  VideoInfo(
    this.id,
    this.title,
    this.author,
    this.quality,
  );
}
