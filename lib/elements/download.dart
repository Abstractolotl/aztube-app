import 'package:aztube/api/downloaddata.dart';
import 'package:aztube/files/downloadsmodel.dart';
import 'package:aztube/files/filemanager.dart';
import 'package:aztube/views/dashboard.dart';
import 'package:aztube/views/downloadoption.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Download extends StatefulWidget {
  const Download(
      {Key? key, required this.video, required this.cache, required this.state})
      : super(key: key);

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
    if (widget.video.progress > 0 && !widget.video.downloaded) {
      downloading = true;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Widget trailing = IconButton(
      enableFeedback: !(!widget.video.downloaded && !downloading),
      onPressed: () {
        if (!widget.video.downloaded && !downloading) {
          startDownload();
        }
      },
<<<<<<< Updated upstream
      icon: Icon(widget.video.downloaded  ? Icons.download_done : Icons.download),
      color: widget.video.downloaded ? Colors.green : Colors.black,
    );
    if(downloading){
      trailing = CircularProgressIndicator(color: Colors.green, value: widget.video.progress/100,);
    }
    var type = widget.video.quality == 'audio' ? ' [Audio]' : ' [Video]';
    return Column(children: [
      ListTile(
          title: Text(widget.video.title + type),
          trailing: trailing,
          onLongPress: openInformationView,
=======
      icon:
          Icon(widget.video.downloaded ? Icons.download_done : Icons.download),
      color: widget.video.downloaded ? Colors.green : Colors.black,
    );
    if (downloading) {
      //https://i.imgur.com/Z51QssF.png
      trailing = CircularProgressIndicator(
        color: Colors.green,
        value: widget.video.progress / 100,
      );
    }
    return Column(children: [
      ListTile(
        contentPadding: const EdgeInsets.all(0),
        visualDensity: VisualDensity(horizontal: 0, vertical: 0),
        dense: true,
        horizontalTitleGap: 5,
        leading: Image.network(
            "https://i.ytimg.com/vi/xyVfLxV08I0/maxresdefault.jpg"),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              children: [
                Text(
                  widget.video.title + "sehr sehr langer langer titel itel",
                  style: TextStyle(fontSize: 17),
                  overflow: TextOverflow.ellipsis,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.video.author,
                      style: TextStyle(
                          fontSize: 10.0,
                          color: Colors.black.withOpacity(0.25)),
                    ),
                    Text(
                      widget.video.downloadId.toString() +
                          " - " +
                          widget.video.videoId +
                          " - " +
                          widget.video.quality,
                      style: TextStyle(
                          fontSize: 10.0,
                          color: Colors.black.withOpacity(0.25)),
                    ),
                  ],
                )
              ],
            ),
          ],
        ),
        trailing: trailing,
        onLongPress: openInformationView,
>>>>>>> Stashed changes
      ),
      const Divider()
    ]);
  }

  void openInformationView() {
    Route route = MaterialPageRoute(
        builder: (context) =>
            DownloadScreen(video: widget.video, cache: widget.cache));
    Navigator.push(context, route).then(widget.state.reload);
  }

  void startDownload() {
    if (!downloading && !widget.video.downloaded) {
      setState(() {
        downloading = true;
      });
      downloadVideo(widget.video);
    }
  }

  void downloadVideo(DownloadData video) async {
    const platform = MethodChannel("de.aztube.aztube_app/youtube");
    Map<String, dynamic> args = {
      "videoId": video.videoId,
      "quality": video.quality,
      "downloadId": video.downloadId
    };

    final dynamic result = await platform.invokeMethod("downloadVideo", args);
    try {
      if (!result) {
        setState(() {
          downloading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Download failed'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      widget.cache.queue.remove(widget.video);

      widget.video.downloaded = true;
      widget.video.savedTo = result;

      widget.cache.downloaded.add(widget.video);
      FileManager().saveDownloads(widget.cache);
      setState(() {
        downloading = false;
      });
    }
  }
}
