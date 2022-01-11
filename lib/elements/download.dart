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
    Icon icon = const Icon(Icons.download);
    if(downloading){
      icon = const Icon(Icons.downloading);
    }
    if(finished && downloading){
      return Column();
    }
    return Column(children: [
      ListTile(
          title: Text(widget.name),
          trailing: IconButton(
            onPressed: () {
              startDownload();
            },
            icon: icon,
            color: Colors.black,
          )),
      const Divider()
    ]);
  }

  void startDownload(){
    if(!downloading){
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
        finished = true;
      });
    }
  }

}