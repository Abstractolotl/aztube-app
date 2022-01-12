import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class DownloadData{

  String downloadID = '0';
  String videoID = '0';
  String quality = 'audio_only';

  String title = 'Title';
  String author = 'Author';

  String fileName = '';
  bool downloaded = false;
  String savedTo = '';
  int progress = 0;

  DownloadData();

  DownloadData.fromJson(dynamic json)
      : downloadID = json['downloadId'] ?? '0',
        videoID = json['videoId'],
        quality = json['quality'],
        title = json['title'],
        author = json['author'],
        fileName = json['fileName'] ?? json['videoID'],
        downloaded = json['downloaded'] ?? false,
        savedTo = json['savedTo'] ?? '';

  Map<String, dynamic> toJson() => {
    'downloadId': downloadID,
    'videoId': videoID,
    'quality': quality,
    'title': title,
    'author': author,
    'downloaded': downloaded,
    'savedTo': savedTo,
  };

}