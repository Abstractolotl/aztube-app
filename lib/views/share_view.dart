import 'package:aztube/aztube.dart';
import 'package:aztube/data/download_info.dart';
import 'package:aztube/data/share_intent.dart';
import 'package:aztube/data/video_info.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ShareView extends StatefulWidget {
  const ShareView({super.key});

  @override
  State<ShareView> createState() => _ShareViewState();
}

class _ShareViewState extends State<ShareView> {
  final TextEditingController titleController = TextEditingController();

  final TextEditingController authorController = TextEditingController();

  String? selectedQuality;

  @override
  Widget build(BuildContext context) {
    return Consumer<AzTubeApp>(builder: (context, app, child) {
      titleController.text = app.shareIntent?.title ?? '';
      return Scaffold(
          appBar: AppBar(
            title: const Text('Share View'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: card(app!),
          ));
    });
  }

  List<Widget> inputs(ShareIntent shareIntent) {
    return <Widget>[
      TextFormField(
        controller: titleController,
        decoration: const InputDecoration(
          labelText: 'Title',
        ),
      ),
      TextField(
        controller: authorController,
        decoration: const InputDecoration(
          labelText: 'Author',
        ),
      ),
      DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          labelText: 'Quality',
        ),
        value: 'Audio', // Preselect the first item
        items: <String>['Audio'].map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            selectedQuality = newValue;
          });
        },
      ),
    ];
  }

  void onDownload(AzTubeApp app) {
    VideoQuality quality = VideoQuality.audio;

    app.addDownload(DownloadInfo(
        video: VideoInfo(app.shareIntent!.text, titleController.text, authorController.text, quality),
        id: DateTime.now().millisecondsSinceEpoch.toString()));
    Navigator.of(context).pushReplacementNamed('/');
  }

  Widget card(AzTubeApp app) {
    return Card(
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.only(top: 16.0, bottom: 16.0, left: 8, right: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              height: 150.0,
              child: Image.network(
                'https://img.youtube.com/vi/${app.shareIntent!.text}/hqdefault.jpg',
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  ...inputs(app.shareIntent!),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50.0,
                    child: ElevatedButton(
                      onPressed: (() => onDownload(app)),
                      child: const Text('Download'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
