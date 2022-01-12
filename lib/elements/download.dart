import 'dart:developer';

import 'package:aztube/api/downloaddata.dart';
import 'package:aztube/files/downloadsmodel.dart';
import 'package:aztube/files/filemanager.dart';
import 'package:aztube/views/dashboard.dart';
import 'package:aztube/views/downloadoption.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Download extends StatefulWidget {

  const Download({Key? key, required this.video, required this.cache, required this.state}) : super(key: key);

  final DashboardScreenState state;
  final DownloadCache cache;
  final DownloadData video;

  @override
  State<StatefulWidget> createState() {
    return DownloadState();
  }

}

class DownloadState extends State<Download> {

  bool downloading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Widget trailing = IconButton(
      enableFeedback: !(!widget.video.downloaded && !downloading),
      onPressed: () {
        if(!widget.video.downloaded && !downloading){
          startDownload();
        }
      },
      icon: Icon(widget.video.downloaded  ? Icons.download_done : Icons.download),
      color: Colors.black,
    );
    if(downloading){
      trailing = const CircularProgressIndicator(color: Colors.black);
    }
    return Column(children: [
      ListTile(
          title: Text(widget.video.title),
          trailing: trailing,
          onLongPress: openInformationView,
      ),
      const Divider()
    ]);
  }

  void openInformationView(){
    Route route = MaterialPageRoute(
        builder: (context) => DownloadScreen(video: widget.video, cache: widget.cache));
    Navigator.push(context, route).then(widget.state.reload);
  }

  void startDownload(){
    if(!downloading && !widget.video.downloaded){
      setState(() {
        downloading = true;
      });
      downloadVideo(widget.video);
    }
  }

  void downloadVideo(DownloadData video) async {
    const platform = MethodChannel("de.aztube.aztube_app/youtube");
    Map<String, dynamic> args = {
      "videoId": video.videoID,
      "quality": video.quality,
      "downloadId": video.downloadID
    };

    final bool result = await platform.invokeMethod("downloadVideo", args);
    if(!result){
      setState(() {
        downloading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download failed'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating),
      );
    }else{
      widget.cache.queue.remove(widget.video);
      widget.video.downloaded = true;
      widget.cache.downloaded.add(widget.video);
      FileManager().saveDownloads(widget.cache);
      setState(() {
        downloading = false;
      });
    }
  }

}