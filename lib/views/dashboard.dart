import 'dart:async';
import 'dart:developer';

import 'package:aztube/api/videodata.dart';
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

  static const platform = MethodChannel("de.aztube.aztube_app/youtube");

  DownloadCache downloadCache = DownloadCache();
  Settings currentSettings = Settings();
  bool loading = true;

  ListView downloads = ListView();

  @override
  void initState() {
    super.initState();
    reloadCache();
  }

  @override
  void reassemble() {
    super.reassemble();
  }

  @override
  Widget build(BuildContext context) {
    if(loading){
      return Scaffold(
          appBar: AppBar(title: AzTubeBar.title,),
          body:  Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Center(
                    child: CircularProgressIndicator(color: Colors.green)
                )
              ]
          )
      );
    }

    if(currentSettings.deviceHash.length < 10){
      return Scaffold(
        appBar: AppBar(
            title: AzTubeBar.title,
            actions: <Widget>[
              IconButton(onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => SettingsScreen(settings: currentSettings))
                ).then(reload);
              },
              icon: const Icon(Icons.settings, color: Colors.white),
              tooltip: 'Open Settings')
            ]
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          Center(
           child: Container(
               padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 5.0),
               child: SimpleButton(
                 child: const Text('Link Browser'),
                 color: Colors.green,
                 onPressed: () {
                   Navigator.push(context,
                       MaterialPageRoute(builder: (context) => LinkingScreen(settings: currentSettings))).then(reload);
                 },
               )
           )
          )
        ]),
      );
    }

    initDownloads();

    return Scaffold(
      appBar: AppBar(
          title: AzTubeBar.title,
          actions: <Widget>[
            IconButton(onPressed: () {
              Navigator.push(context,
              MaterialPageRoute(builder: (context) => SettingsScreen(settings: currentSettings))
              ).then(reload);
              },
                  icon: const Icon(Icons.settings, color: Colors.white),
                  tooltip: 'Open Settings')
              ]
      ),
      body: downloads,
    );

  }

  void startLinking(){
    Route route = MaterialPageRoute(builder: (context) => LinkingScreen(settings: currentSettings));
    Navigator.push(context, route).then(reload);
  }
  
  FutureOr reload(dynamic value){
    setState(() {
      loading = true;
    });
    reloadCache();
  }

  void reloadCache() async{
    currentSettings = await FileManager().getSettings();
    downloadCache = await FileManager().getDownloads();
    setState(() {
      loading = false;
    });
  }


  void initDownloads(){
    VideoData testVideo = VideoData();
    testVideo.videoID = "dQw4w9WgXcQ";
    testVideo.quality = "720p";
    var queue = downloadCache.getAll();
    downloads = ListView.builder(
      padding: const EdgeInsets.all(5.0),
      itemCount: queue.length,
      itemBuilder: (context, index){
        return Download(name: 'Test', video: queue[index], cache: downloadCache);
    });
  }

}
