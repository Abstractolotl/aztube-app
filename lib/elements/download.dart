import 'package:flutter/material.dart';

class Download extends StatefulWidget {

  const Download({Key? key, required this.name}) : super(key: key);

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
    if(finished){
      icon = const Icon(Icons.delete_forever);
    }else if(downloading){
      icon = const Icon(Icons.downloading);
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
    if(downloading){
      setState(() {
        finished = true;
      });
    }else{
      setState(() {
        downloading = true;
      });
    }
  }

}