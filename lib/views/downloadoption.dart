import 'package:aztube/api/downloaddata.dart';
import 'package:aztube/elements/simplebutton.dart';
import 'package:aztube/elements/simplecircularbutton.dart';
import 'package:aztube/files/downloadsmodel.dart';
import 'package:aztube/files/filemanager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class DownloadScreen extends StatefulWidget {

  const DownloadScreen({Key? key, required this.video, required this.cache}) : super(key: key);

  final DownloadCache cache;
  final DownloadData video;

  @override
  State<StatefulWidget> createState() => DownloadScreenState();

}

class DownloadScreenState extends State<DownloadScreen> {

  bool loading = false;

  @override
  void initState() {
    if(widget.video.downloaded){
      loading = true;
      checkExists();
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if(loading){
      return Scaffold(
          appBar: AppBar(
            title: const Text('Options'),
          ),
          body: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Center(child: CircularProgressIndicator(color: Colors.green))
              ]));
    }
    return Scaffold(
        appBar: AppBar(title: const Text('Options')),
        body: ListView(
          children: [
            ListTile(
              title: Text('Author: ${widget.video.title}'),
            ),
            const Divider(),
            ListTile(
              title: Text('Author: ${widget.video.author}'),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: SimpleCircularButton(
                    iconData: Icons.delete,
                    fillColor: Colors.red,
                    iconColor: Colors.white,
                    onPressed: (){
                      displayDialog('Delete from List', 'The download is removed from the list but remains available on the device.', () {
                        Navigator.pop(context, 'OK');
                        removeFromList();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${widget.video.title} removed'),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating),
                        );
                        Navigator.pop(context);
                      });
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: SimpleCircularButton(
                    iconData: Icons.play_arrow,
                    fillColor: widget.video.downloaded ? Colors.green : Colors.grey,
                    iconColor: Colors.white,
                    onPressed: (){
                      if(!widget.video.downloaded) return;
                      play();
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: SimpleCircularButton(
                    iconData: Icons.delete_forever,
                    fillColor: widget.video.downloaded ? Colors.red : Colors.grey,
                    iconColor: Colors.white,
                    onPressed: (){
                      if(!widget.video.downloaded) return;
                      displayDialog('Delete completely', 'The download will be completely removed from your device.', () {
                        Navigator.pop(context, 'OK');
                        deleteCompletely();
                      });
                    },
                  ),
                ),
              ],
            )
          ],
        )
    );
  }

  void checkExists() async{
    const platform = MethodChannel("de.aztube.aztube_app/youtube");
    Map<String, dynamic> args = {
      "uri": widget.video.savedTo
    };
    bool result = await platform.invokeMethod("downloadExists", args);
    if(result){
      setState(() {
        loading = false;
      });
    }else{
      widget.video.downloaded = false;
      if(widget.cache.downloaded.contains(widget.video)){
        widget.cache.downloaded.remove(widget.video);
      }
      if(!widget.cache.queue.contains(widget.video)){
        widget.cache.queue.add(widget.video);
      }
      FileManager().saveDownloads(widget.cache);
      setState(() {
        loading = false;
      });
    }
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

  void deleteCompletely() async{
    const platform = MethodChannel("de.aztube.aztube_app/youtube");
    Map<String, dynamic> args = {
      "uri": widget.video.savedTo
    };
    bool result = await platform.invokeMethod("deleteDownload", args);
    if(result){
      removeFromList();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.video.title} deleted'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating),
      );
      Navigator.pop(context);
    }else{
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deletion failed'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating),
      );
    }
  }

  void play() async{
    const platform = MethodChannel("de.aztube.aztube_app/youtube");
    Map<String, dynamic> args = {
      "uri": widget.video.savedTo
    };
    platform.invokeMethod("openDownload", args);
  }

  Future<void> displayDialog(String title, String message, dynamic onApprove){
    return showDialog<void>(context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(
              child: ListBody(
                children: [
                  Text(message),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, 'Cancel'),
                  child: const Text('Cancel')),
              TextButton(onPressed: onApprove as void Function()?,
                child: const Text('Accept'))
            ],
          );
        });
  }

}
