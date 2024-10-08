// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/services.dart';

import 'package:aztube/data/download_info.dart';
import 'package:flutter/material.dart';

typedef OnProgressListener = Function(String downloadId, double progress);

class AzTubePlattform {
  final MethodChannel _platform = const MethodChannel("de.abstractolotl.aztube/youtube");
  OnProgressListener? onProgress;

  AzTubePlattform({
    this.onProgress,
  }) {
    _platform.setMethodCallHandler(plattformCallHandler);
  }

  Future<String> downloadVideo(DownloadInfo info) async {
    Map<String, dynamic> args = {
      "videoId": info.video.videoId,
      "downloadId": info.id,
      "quality": info.video.quality.text,
      "title": info.video.title,
      "author": info.video.author
    };

    return await _platform.invokeMethod("downloadVideo", args);
  }

  Future<dynamic> plattformCallHandler(MethodCall call) async {
    debugPrint("Got call for ${call.method}");
    switch (call.method) {
      case "progress":
        var downloadId = call.arguments['downloadId'];
        var progress = call.arguments['progress'];
        onProgress?.call(downloadId, progress);
        break;
      default:
        debugPrint("Unknown method ${call.method}");
        break;
    }
  }
}
