import 'dart:collection';
import 'dart:convert';

import 'package:aztube/aztube_plattform.dart';
import 'package:aztube/data/device_link_info.dart';
import 'package:aztube/data/download_info.dart';
import 'package:aztube/data/share_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:receive_intent/receive_intent.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AzTubeApp with ChangeNotifier {
  static String prefDeviceLink = "DEVICE_LINKS";
  static String prefDownloads = "DOWNLOADS";

  final HashMap<String, DeviceLinkInfo> deviceLinks = HashMap();
  final HashMap<String, DownloadInfo> downloads = HashMap();
  late final ShareIntent? shareIntent;

  late final AzTubePlattform plattform = AzTubePlattform(onProgress: _onProgress);

  String loadingError = "NOT LOADED";

  AzTubeApp();

  Future<void> startDownload(DownloadInfo info) async {
    debugPrint("startDownload");
    if (info.progress > 0) {
      debugPrint("Tried starting download that was already started");
      return;
    }

    try {
      String location = await plattform.downloadVideo(info);
      info.downloadLocation = location;
      _save();
    } catch (error) {
      debugPrint(error.toString());
      if (error is PlatformException) {
        throw Exception(error.message);
      }
      rethrow;
    }
  }

  bool hasDeviceLinks() {
    return deviceLinks.isNotEmpty;
  }

  void removeDeviceLink(DeviceLinkInfo info) {
    deviceLinks.remove(info.deviceToken);
    _save();
    notifyListeners();
  }

  void renameDeviceLink(DeviceLinkInfo info, String name) {
    deviceLinks[info.deviceToken] = DeviceLinkInfo(info.deviceToken, name, info.registerDate);
    _save();
    notifyListeners();
  }

  void addDeviceLinks(DeviceLinkInfo info) {
    deviceLinks[info.deviceToken] = info;
    _save();
    notifyListeners();
  }

  void addDownloads(List<DownloadInfo> infos) {
    for (var info in infos) {
      downloads[info.id] = info;
    }
    _save();
    notifyListeners();
  }

  void addDownload(DownloadInfo info) {
    downloads[info.id] = info;
    _save();
    notifyListeners();
  }

  void removeDownload(DownloadInfo info) {
    downloads.remove(info.id);
    _save();
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

    if (progress >= 100) {
      _save();
    }
    notifyListeners();
  }

  Future<void> init() async {
    var intent = await ReceiveIntent.getInitialIntent();
    if (intent != null && intent.action == "android.intent.action.SEND") {
      var title = intent.extra!["android.intent.extra.SUBJECT"];
      var url = Uri.parse(intent.extra!["android.intent.extra.TEXT"]);
      var id = url.queryParameters["v"];

      if (id == null) {
        shareIntent = null;
      } else {
        shareIntent = ShareIntent(title: title, text: id);
      }
    } else {
      shareIntent = null;
    }

    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(prefDeviceLink) || !prefs.containsKey(prefDownloads)) {
      loadingError = "No data in SharedPref";
      return;
    }

    try {
      Map<String, dynamic> loadedLinksRaw = jsonDecode(prefs.getString(prefDeviceLink)!);
      Map<String, DeviceLinkInfo> loadedLinks = loadedLinksRaw.map(
        (key, value) => MapEntry(key, DeviceLinkInfo.fromJson(value)),
      );

      Map<String, dynamic> loadedDownloadsRaw = jsonDecode(prefs.getString(prefDownloads)!);
      Map<String, DownloadInfo> loadedDownloads = loadedDownloadsRaw.map(
        (key, value) => MapEntry(key, DownloadInfo.fromJson(value)),
      );

      for (var element in loadedDownloads.values) {
        if (element.progress < 100) element.progress = 0;
      }

      deviceLinks.addEntries(loadedLinks.entries);
      downloads.addEntries(loadedDownloads.entries);
    } catch (e) {
      loadingError = "Error while parsing $e";
      return;
    }

    loadingError = "Success";
  }

  void _save() async {
    final prefs = await SharedPreferences.getInstance();

    prefs.setString(prefDeviceLink, jsonEncode(deviceLinks));
    prefs.setString(prefDownloads, jsonEncode(downloads));
  }

  void clearAllData() async {
    final prefs = await SharedPreferences.getInstance();

    prefs.clear();
  }
}
