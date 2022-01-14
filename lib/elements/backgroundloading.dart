import 'package:aztube/api/downloaddata.dart';
import 'package:aztube/files/downloadsmodel.dart';
import 'package:aztube/files/filemanager.dart';
import 'package:aztube/views/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BackgroundLoading{

  BackgroundLoading();

  void startBackground(DownloadData data, DownloadCache cache, DashboardScreenState dashboard) async{
      if(!data.downloaded && data.progress <= 0){
        const platform = MethodChannel("de.aztube.aztube_app/youtube");
        Map<String, dynamic> args = {
          "videoId": data.videoId,
          "quality": data.quality,
          "downloadId": data.downloadId
        };

        final dynamic result = await platform.invokeMethod("downloadVideo", args);
        try {
          if (!result) {
            ScaffoldMessenger.of(dashboard.context).showSnackBar(
              const SnackBar(
                  content: Text('Download failed'),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating),
            );
          }
        } catch (e) {
          cache.queue.remove(data);

          data.downloaded = true;
          data.savedTo = result;

          cache.downloaded.add(data);
          FileManager().saveDownloads(cache);

          dashboard.setState(() { });
        }
      }
  }
}