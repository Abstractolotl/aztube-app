class VideoData{

  String videoID = '0';
  String quality = 'audio_only';
  bool downloaded = false;
  String savedTo = '';

  VideoData();

  VideoData.fromJson(Map<String, dynamic> json)
      : videoID = json['videoId'],
        quality = json['quality'],
        downloaded = json['downloaded'] ?? false,
        savedTo = json['savedTo'] ?? '';

  Map<String, dynamic> toJson() => {
    'videoId': videoID,
    'quality': quality,
    'downloaded': downloaded,
    'savedTo': savedTo,
  };
}