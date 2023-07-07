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
}
