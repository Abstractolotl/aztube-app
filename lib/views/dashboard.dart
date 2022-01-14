import 'dart:async';
import 'dart:convert';

import 'package:aztube/api/apihelper.dart';
import 'package:aztube/api/downloaddata.dart';
import 'package:aztube/elements/aztubebar.dart';
import 'package:aztube/elements/download.dart';
import 'package:aztube/elements/simplebutton.dart';
import 'package:aztube/files/downloadsmodel.dart';
import 'package:aztube/files/filemanager.dart';
import 'package:aztube/files/settingsmodel.dart';
import 'package:aztube/views/linking.dart';
import 'package:aztube/views/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {

  static const timeout = 2;
  static const platform = MethodChannel("de.aztube.aztube_app/youtube");

  Future<dynamic> nativeMethodCallHandler(MethodCall methodCall) async {
    switch (methodCall.method) {
      case "progress":
        var videoId = methodCall.arguments['videoId'];
        var downloadId = methodCall.arguments['downloadId'];
        var progress = methodCall.arguments['progress'];
        DownloadData? download = downloadCache.findBy(videoId, downloadId);
        if (download != null && !download.downloaded) {
          download.progress = progress;
          setState(() {
            timer?.cancel();
            timer = polling();
          });
        }
        break;
    }
  }

  DownloadCache downloadCache = DownloadCache();
  Settings currentSettings = Settings();
  bool loading = true;

  ListView downloads = ListView();
  Timer? timer;

  AppLifecycleState lastState = AppLifecycleState.paused;

  @override
  void initState() {
    platform.setMethodCallHandler(nativeMethodCallHandler);
    super.initState();
    reloadCache();
  }

  @override
  void dispose() {
    timer?.cancel();
    loading = true;
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    reloadCache();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
          appBar: AppBar(
            title: AzTubeBar.title,
          ),
          body: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Center(child: CircularProgressIndicator(color: Colors.green))
              ]));
    }

    if (currentSettings.deviceHash.length < 10) {
      return Scaffold(
        appBar: AppBar(title: AzTubeBar.title, actions: <Widget>[
          IconButton(
              onPressed: () {
                Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                SettingsScreen(settings: currentSettings)))
                    .then(reload);
              },
              icon: const Icon(Icons.settings, color: Colors.white),
              tooltip: 'Open Settings')
        ]),
        body: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Center(
              child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 5.0, horizontal: 5.0),
                  child: Column(
                    children: [
                      SimpleButton(
                        child: const Text('Link Browser'),
                        color: Colors.green,
                        onPressed: () {
                          startLinking();
                        },
                      )
                    ],
                  )))
        ]),
      );
    }

    initDownloads();

    return Scaffold(
      appBar: AppBar(title: AzTubeBar.title, actions: <Widget>[
        IconButton(
            onPressed: () {
              timer?.cancel();
              Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              SettingsScreen(settings: currentSettings)))
                  .then(reload);
            },
            icon: const Icon(Icons.settings, color: Colors.white),
            tooltip: 'Open Settings')
      ]),
      body: downloads,
    );
  }

  void startLinking() {
    Route route = MaterialPageRoute(
        builder: (context) => LinkingScreen(settings: currentSettings));
    Navigator.push(context, route).then(reload);
  }

  FutureOr reload(dynamic value) {
    setState(() {
      loading = true;
    });
    reloadCache();
  }

  void reloadCache() async {
    currentSettings = await FileManager().getSettings();
    downloadCache = await FileManager().getDownloads();
    setState(() {
      loading = false;
      if (currentSettings.deviceHash.length >= 10) {
        timer = polling();
      }
    });
  }

  void initDownloads() {
    var queue = downloadCache.getAll();
    downloads = ListView.builder(
        padding: const EdgeInsets.all(5.0),
        itemCount: queue.length,
        itemBuilder: (context, index) {
          return Download(
              video: queue[index], cache: downloadCache, state: this);
        });

    initRunningDownloads();
  }

  void initRunningDownloads() async {
    List<dynamic> result = await platform.invokeMethod("getActiveDownloads");

    for (var i = 0; i < result.length; i++) {
      Map<String, dynamic> args = {"downloadId": result[i]["downloadId"]};

      await platform.invokeMethod("registerDownloadProgressUpdate", args);
    }
  }

  Timer polling() {
    return Timer.periodic(const Duration(seconds: timeout), (timer) async {
      var response = await APIHelper.fetchDownloads(currentSettings.deviceHash);
      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success']) {
          var downloads = jsonResponse['downloads'];
          for (var download in downloads) {
            DownloadData video = DownloadData.fromJson(download);
            final dynamic thumbnail = await platform
                .invokeMethod("getThumbnailUrl", {"videoId": video.videoId});
            video.thumbnail = thumbnail;
            downloadCache.queue.add(video);
          }
          FileManager().saveDownloads(downloadCache);
          setState(() {});
        } else {
          var error = jsonResponse['error'];
          if (error != 'no entry in database' &&
              error != 'deviceToken not ready yet') {
            timer.cancel();
            currentSettings.deviceHash = '0';
            FileManager().saveSettings(currentSettings);
            setState(() {});
          }
        }
      }
    });
  }
}
