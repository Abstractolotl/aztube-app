import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class DownloadData{

  String downloadID = '0';
  String videoID = '0';
  String quality = 'audio_only';
  String fileName = '';
  bool downloaded = false;
  String savedTo = '';
  int progress = 0;

  DownloadData();

  DownloadData.fromJson(Map<String, dynamic> json)
      : downloadID = json['downloadId'] ?? '0',
        videoID = json['videoId'],
        quality = json['quality'],
        fileName = json['fileName'] ?? json['videoID'],
        downloaded = json['downloaded'] ?? false,
        savedTo = json['savedTo'] ?? '';

  Map<String, dynamic> toJson() => {
    'downloadId': downloadID,
    'videoId': videoID,
    'quality': quality,
    'downloaded': downloaded,
    'savedTo': savedTo,
  };

  Stream<int> get downloading async*{
    if(progress < 100 && !downloaded){
      yield progress;
    }
  }
}