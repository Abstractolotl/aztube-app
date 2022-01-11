import 'package:aztube/api/VideoData.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Download extends StatefulWidget {

  const Download({Key? key, required this.name, required this.video}) : super(key: key);

  final VideoData video;
  final String name;

  @override
  State<StatefulWidget> createState() {
    return DownloadState();
  }

}

class DownloadState extends State<Download> {

  bool downloading = false;
  bool finished = false;

  @override
  Widget build(BuildContext context) {
    Widget trailing = IconButton(
      onPressed: () {
        startDownload();
      },
      icon: Icon(finished ? Icons.download_done : Icons.download),
      color: Colors.black,
    );
    if(downloading){
      trailing = const CircularProgressIndicator(color: Colors.black);
    }
    return Column(children: [
      ListTile(
          title: Text(widget.name),
          trailing: trailing ),
      const Divider()
    ]);
  }

  void startDownload(){
    if(!downloading && !finished){
      setState(() {
        downloading = true;
      });
      downloadVideo(widget.video);
    }
  }

  void downloadVideo(VideoData video) async {
    const platform = MethodChannel("de.aztube.aztube_app/youtube");
    Map<String, dynamic> args = {
      "videoId": video.videoID,
      "quality": video.quality
    };

    final String result = await platform.invokeMethod("downloadVideo", args);
    if(result.length > 2){
      setState(() {
        downloading = false;
        finished = true;
      });
    }
  }

}