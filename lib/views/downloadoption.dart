import 'package:aztube/api/downloaddata.dart';
import 'package:aztube/elements/simplebutton.dart';
import 'package:aztube/files/downloadsmodel.dart';
import 'package:aztube/files/filemanager.dart';
import 'package:flutter/material.dart';

class DownloadScreen extends StatefulWidget {

  const DownloadScreen({Key? key, required this.video, required this.cache}) : super(key: key);

  final DownloadCache cache;
  final DownloadData video;

  @override
  State<StatefulWidget> createState() => DownloadScreenState();

}

class DownloadScreenState extends State<DownloadScreen> {

  @override
  Widget build(BuildContext context) {

    return Scaffold(
        appBar: AppBar(title: Text(widget.video.title)),
        body: ListView(
          children: [
            ListTile(
              title: Text('Author: ${widget.video.author}'),
            ),
            const Divider(),
            ListTile(
              title: Text(widget.video.downloaded ? 'Location: ${widget.video.savedTo}' : 'Location: -'),
              trailing: IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () {  },
              ),
            ),
            const Divider(),
            Row(
              children: [
                SimpleButton(
                  color: Colors.orange,
                  child: const Text('Remove'),
                  onPressed: (){
                    removeFromList();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${widget.video.title} removed'),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating),
                    );
                    Navigator.pop(context);
                  },
                ),
                SimpleButton(
                  disabled: !widget.video.downloaded,
                  color: widget.video.downloaded ? Colors.orange : Colors.grey,
                  child: const Text('Delete'),
                  onPressed: (){
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${widget.video.title} deleted'),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating),
                    );
                  },
                ),
              ],
            )
          ],
        )
    );
  }

  void removeFromList(){
    if(widget.cache.downloaded.contains(widget.video)){
      widget.cache.downloaded.remove(widget.video);
    }
    if(widget.cache.queue.contains(widget.video)){
      widget.cache.queue.remove(widget.video);
    }
    FileManager().saveDownloads(widget.cache);
  }

}
