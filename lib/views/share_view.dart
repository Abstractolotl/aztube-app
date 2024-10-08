import 'package:aztube/aztube.dart';
import 'package:aztube/data/download_info.dart';
import 'package:aztube/data/video_info.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ShareView extends StatefulWidget {
  static DownloadInfo? info;

  const ShareView({super.key});

  @override
  State<ShareView> createState() => _ShareViewState();
}

class _ShareViewState extends State<ShareView> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController authorController = TextEditingController();

  String? selectedQuality;

  @override
  void initState() {
    super.initState();

    if (ShareView.info == null) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AzTubeApp>(builder: (context, app, child) {
      titleController.text = ShareView.info!.video.title;
      authorController.text = ShareView.info!.video.author;
      selectedQuality = ShareView.info!.video.quality.name;

      return Scaffold(
          appBar: AppBar(
            title: const Text('Share View'),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: card(app!),
            ),
          ));
    });
  }

  List<Widget> inputs() {
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
        value: selectedQuality, // Preselect the first item
        items: VideoQuality.values.map((VideoQuality value) {
          return DropdownMenuItem<String>(
            value: value.name,
            child: Text(value.name),
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

    var info = DownloadInfo(
        video: VideoInfo(ShareView.info!.video.videoId, titleController.text, authorController.text, quality),
        id: ShareView.info!.id);

    app.addDownload(info);
    ShareView.info = null;
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
                'https://img.youtube.com/vi/${ShareView.info!.video.videoId}/hqdefault.jpg',
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  ...inputs(),
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
