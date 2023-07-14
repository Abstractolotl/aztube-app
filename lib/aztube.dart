import 'dart:collection';

import 'package:aztube/aztube_plattform.dart';
import 'package:aztube/data/device_link_info.dart';
import 'package:aztube/data/download_info.dart';
import 'package:flutter/material.dart';

class AzTubeApp with ChangeNotifier {
  final HashMap<String, DeviceLinkInfo> deviceLinks = HashMap();
  final HashMap<String, DownloadInfo> downloads = HashMap();
  late final AzTubePlattform plattform = AzTubePlattform(onProgress: _onProgress);

  void startDownload(DownloadInfo info) async {
    debugPrint("startDownload");
    if (info.progress != 0) {
      debugPrint("Tried starting download that was already started");
      return;
    }

    try {
      String location = await plattform.downloadVideo(info);
      info.downloadLocation = location;
    } catch (error) {
      debugPrint(error.toString());
    }
  }

  bool hasDeviceLinks() {
    return deviceLinks.isNotEmpty;
  }

  void removeDeviceLink(DeviceLinkInfo info) {
    deviceLinks.remove(info.deviceToken);
    notifyListeners();
  }

  void _onProgress(String downloadId, double progress) {
    debugPrint("onProgress");
    var dwn = downloads[downloadId];
    if (dwn == null) {
      debugPrint("No Download for id $downloadId");
      return;
    } // log something

    dwn.progress = progress;
    debugPrint("Updated progess to $progress");
    notifyListeners();
  }

  void addDeviceLinks(DeviceLinkInfo info) {
    deviceLinks[info.deviceToken] = info;
    notifyListeners();
  }
}
