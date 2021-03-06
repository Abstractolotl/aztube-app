class DownloadData {
  int downloadId = 0;
  String videoId = '0';
  String quality = 'audio_only';

  String title = 'Title';
  String author = 'Unknown';

  String fileName = '';
  bool downloaded = false;
  String savedTo = '';
  String thumbnail = '';
  int progress = 0;

  DownloadData();

  DownloadData.fromJson(dynamic json)
      : downloadId = json['downloadId'] ?? 0,
        videoId = json['videoId'],
        quality = json['quality'],
        title = json['title'],
        author = json['author'] ?? 'Unknown',
        fileName = json['fileName'] ?? json['title'],
        downloaded = json['downloaded'] ?? false,
        savedTo = json['savedTo'] ?? '',
        thumbnail = json['thumbnail'] ?? '';

  Map<String, dynamic> toJson() => {
        'downloadId': downloadId,
        'videoId': videoId,
        'quality': quality,
        'title': title,
        'author': author,
        'downloaded': downloaded,
        'savedTo': savedTo,
        'thumbnail': thumbnail,
      };
}
