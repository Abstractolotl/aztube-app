import 'package:aztube/api/downloaddata.dart';
import 'package:aztube/files/downloadsmodel.dart';
import 'package:aztube/files/filemanager.dart';
import 'package:aztube/views/dashboard.dart';
import 'package:aztube/views/downloadoption.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:matomo_tracker/matomo_tracker.dart';

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
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.video.progress > 0 && !widget.video.downloaded) {
        downloading = true;
    }
    Widget trailing = IconButton(
      enableFeedback: !(!widget.video.downloaded && !downloading),
      onPressed: () {
        if (!widget.video.downloaded && !downloading) {
          startDownload();
        }
      },
      icon: Icon(widget.video.downloaded ? Icons.download_done : Icons.download),
      color: widget.video.downloaded ? Colors.green : Theme.of(context).textTheme.headline1?.color,
    );
    if (downloading && !widget.video.downloaded) {
      trailing = CircularProgressIndicator(
        color: Colors.green,
        value: widget.video.progress / 100,
      );
    }
    var typeInfo = 'Audio';
    if(widget.video.quality != 'audio'){
      typeInfo = 'Video - ${widget.video.quality}';
    }
    return Column(children: [
      ListTile(
        contentPadding: const EdgeInsets.all(0),
        visualDensity: const VisualDensity(horizontal: 0, vertical: 0),
        dense: true,
        horizontalTitleGap: 5,
        leading: Image.network(
          "https://img.youtube.com/vi/${widget.video.videoId}/default.jpg",
          width: 75,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              children: [
                Text(
                  widget.video.title,
                  style: const TextStyle(fontSize: 17),
                  overflow: TextOverflow.ellipsis,
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(
                      minWidth: MediaQuery.of(context).size.width),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.video.author,
                        style: Theme.of(context).textTheme.bodyText1,
                      ),
                      Text(
                        typeInfo,
                        style: Theme.of(context).textTheme.bodyText1,
                      ),
                    ],
                  ),
                )
              ],
            ),
          ],
        ),
        trailing: trailing,
        onTap: play,
        onLongPress: openInformationView,
      ),
      const Divider()
    ]);
  }

  void play() async{
    if(widget.video.downloaded){
      const platform = MethodChannel("de.aztube.aztube_app/youtube");
      Map<String, dynamic> args = {
        "uri": widget.video.savedTo
      };
      bool result = await platform.invokeMethod("downloadExists", args);
      if(result){
        platform.invokeMethod("openDownload", args);
      }else{
        widget.video.downloaded = false;
        widget.video.downloaded = false;
        if(widget.cache.downloaded.contains(widget.video)){
          widget.cache.downloaded.remove(widget.video);
        }
        if(!widget.cache.queue.contains(widget.video)){
          widget.cache.queue.add(widget.video);
        }
        FileManager().saveDownloads(widget.cache);
        setState(() {});
      }
    }
  }

  void openInformationView() {
    if(!downloading){
      Route route = MaterialPageRoute(
          builder: (context) =>
              DownloadScreen(video: widget.video, cache: widget.cache));
      Navigator.push(context, route).then(widget.state.reload);
    }
  }

  void startDownload() {
    if (!downloading && !widget.video.downloaded) {
      MatomoTracker.instance.trackEvent(
        name: 'startDownload',
        action: 'download',
        eventValue: 'foreground',
      );
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
      "downloadId": video.downloadId,
      "title": video.title,
      "author": video.author
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
