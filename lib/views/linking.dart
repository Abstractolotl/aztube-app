import 'package:aztube_app/elements/aztubebar.dart';
import 'package:aztube_app/files/filemanager.dart';
import 'package:aztube_app/files/i_filemanager.dart';
import 'package:aztube_app/files/settingsmodel.dart';
import 'package:aztube_app/views/dashboard.dart';
import 'package:fast_qr_reader_view/fast_qr_reader_view.dart';
import 'package:flutter/material.dart';

class LinkingScreen extends StatefulWidget {

  const LinkingScreen({Key? key, required this.cameras, required this.settings}) : super(key: key);

  final Settings settings;
  final List<CameraDescription> cameras;

  @override
  State<StatefulWidget> createState() => LinkingScreenState();

}

class LinkingScreenState extends State<LinkingScreen> {

  late QRReaderController controller;
  IFileManager fileManager = FileManager();

  @override
  void initState() {
    super.initState();
    controller = QRReaderController(widget.cameras[0], ResolutionPreset.medium, [CodeFormat.qr], (dynamic value){
      if(value.length > 10) {
        widget.settings.deviceHash = value;
        FileManager().save(widget.settings);
        setState(() {
          Navigator.push(context, MaterialPageRoute(builder: (context) => DashboardScreen(title: 'AzTube', settings: widget.settings)));
        });
      }
      Future.delayed(const Duration(seconds: 3), controller.startScanning);
    });
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
      controller.startScanning();
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget body = AspectRatio(
        aspectRatio:
        controller.value.aspectRatio,
        child: QRReaderPreview(controller));
    if (!controller.value.isInitialized) {
      body = const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      appBar: AppBar(title: AzTubeBar.title,),
      body: body,
    );

  }

}
