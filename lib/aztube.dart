import 'dart:collection';
import 'dart:convert';

import 'package:aztube/aztube_plattform.dart';
import 'package:aztube/data/device_link_info.dart';
import 'package:aztube/data/download_info.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AzTubeApp with ChangeNotifier {
  static String PREF_DEVICE_LINKS = "DEVICE_LINKS";
  static String PREF_DOWNLOADS = "DOWNLOADS";

  final HashMap<String, DeviceLinkInfo> deviceLinks = HashMap();
  final HashMap<String, DownloadInfo> downloads = HashMap();

  late final AzTubePlattform plattform = AzTubePlattform(onProgress: _onProgress);

  String loadingError = "NOT LOADED";

  AzTubeApp() {}

  void startDownload(DownloadInfo info) async {
    debugPrint("startDownload");
    if (info.progress != 0) {
      debugPrint("Tried starting download that was already started");
      return;
    }

    try {
      String location = await plattform.downloadVideo(info);
      info.downloadLocation = location;
      _save();
    } catch (error) {
      debugPrint(error.toString());
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
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(PREF_DEVICE_LINKS) || !prefs.containsKey(PREF_DOWNLOADS)) {
      loadingError = "No data in SharedPref";
      return;
    }

    try {
      Map<String, dynamic> loadedLinksRaw = jsonDecode(prefs.getString(PREF_DEVICE_LINKS)!);
      Map<String, DeviceLinkInfo> loadedLinks = loadedLinksRaw.map(
        (key, value) => MapEntry(key, DeviceLinkInfo.fromJson(value)),
      );

      Map<String, dynamic> loadedDownloadsRaw = jsonDecode(prefs.getString(PREF_DOWNLOADS)!);
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

    prefs.setString(PREF_DEVICE_LINKS, jsonEncode(deviceLinks));
    prefs.setString(PREF_DOWNLOADS, jsonEncode(downloads));
  }

  void clearAllData() async {
    final prefs = await SharedPreferences.getInstance();

    prefs.clear();
  }
}
