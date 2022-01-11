import 'package:aztube/elements/aztubebar.dart';
import 'package:aztube/files/filemanager.dart';
import 'package:aztube/files/i_filemanager.dart';
import 'package:aztube/files/settingsmodel.dart';
import 'package:aztube/views/dashboard.dart';
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
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(value.toString())));
      if(value.toString().length > 10) {
        widget.settings.deviceHash = value.toString();
        FileManager().save(widget.settings);
        setState(() {});
        Navigator.push(context, MaterialPageRoute(builder: (context) => DashboardScreen(title: 'AzTube', settings: widget.settings)));
        return;
      }
      print(value.toString() + " rescan");
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
    return Scaffold(
      appBar: AppBar(title: AzTubeBar.title,),
      body: getBody(),
    );

  }

  Widget getBody(){
    if (!controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Stack(children: <Widget>[
      Container(
          child: Padding(
              padding: const EdgeInsets.all(0.0),
              child: Center(
                child:AspectRatio(aspectRatio: controller.value.aspectRatio,
                    child: QRReaderPreview(controller)),
              )
          )
      ),
      Center(
        child: Stack(
          children: [
            SizedBox(
              height: 300,
              width: 300,
              child: Container(
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.red, width: 2.0)
                ),
              ),
            )
          ],
        ),
      )
    ]);
  }
}
