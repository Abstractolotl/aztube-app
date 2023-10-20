// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:aztube/data/video_info.dart';

class DownloadInfo {
  final VideoInfo video;
  final String id;
  double progress;
  String? downloadLocation;

  DownloadInfo({
    required this.video,
    required this.id,
    this.progress = 0,
    this.downloadLocation,
  });

  bool isDownloaded() {
    return progress >= 100;
  }

  bool isDownloading() {
    return progress > 0 && progress < 100;
  }

  bool isError() {
    return progress < 0;
  }

  factory DownloadInfo.fromJson(Map<String, dynamic> json) {
    return DownloadInfo(
      video: VideoInfo.fromJson(json['video']),
      id: json['id'] as String,
      progress: json['progress'] as double,
      downloadLocation: json['downloadLocation'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'video': video.toJson(),
      'id': id,
      'progress': progress,
      'downloadLocation': downloadLocation,
    };
  }
}
