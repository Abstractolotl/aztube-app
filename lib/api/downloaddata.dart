import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class DownloadData{

  int downloadId = 0;
  String videoId = '0';
  String quality = 'audio_only';

  String title = 'Title';
  String author = 'Author';

  String fileName = '';
  bool downloaded = false;
  String savedTo = '';
  int progress = 0;

  DownloadData();

  DownloadData.fromJson(dynamic json)
      : downloadId = json['downloadId'] ?? 0,
        videoId = json['videoId'],
        quality = json['quality'],
        title = json['title'],
        author = json['author'],
        fileName = json['fileName'] ?? json['videoId'],
        downloaded = json['downloaded'] ?? false,
        savedTo = json['savedTo'] ?? '';

  Map<String, dynamic> toJson() => {
    'downloadId': downloadId,
    'videoId': videoId,
    'quality': quality,
    'title': title,
    'author': author,
    'downloaded': downloaded,
    'savedTo': savedTo,
  };

}