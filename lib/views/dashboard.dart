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
import 'package:uuid/uuid.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {

  static const platform = MethodChannel("de.aztube.aztube_app/youtube");

  Future<dynamic> nativeMethodCallHandler(MethodCall methodCall) async {
    switch(methodCall.method){
      case "progress":
        break;
    }
  }

  DownloadCache downloadCache = DownloadCache();
  Settings currentSettings = Settings();
  bool loading = true;

  ListView downloads = ListView();
  Timer? timer;

  @override
  void initState() {
    platform.setMethodCallHandler(nativeMethodCallHandler);
    super.initState();
    reloadCache();
  }

  @override
  void reassemble() {
    super.reassemble();
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
                      ),
                      Container(
                        height: 10.0,
                      ),
                      SimpleButton(
                        child: const Text('Show Notification'),
                        color: Colors.green,
                        onPressed: () {
                          platform.invokeMethod(
                              "showNotification", {"numPendingDownloads": 13});
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
      if(currentSettings.deviceHash.length >= 10){
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
          return Download(video: queue[index], cache: downloadCache);
        });
  }

  Timer polling(){
    return Timer.periodic(const Duration(seconds: 5),
            (timer) async{
                var response = await APIHelper.fetchDownloads(currentSettings.deviceHash);

                if(response.statusCode == 200){
                  var jsonResponse = jsonDecode(response.body);
                  if(jsonResponse['success']){
                    var downloads = jsonResponse['downloads'];
                    for (var download in downloads){
                      DownloadData video = DownloadData.fromJson(download);
                      downloadCache.queue.add(video);
                    }
                    FileManager().saveDownloads(downloadCache);
                    setState(() {
                    });
                  }
                }
            });
  }
}
