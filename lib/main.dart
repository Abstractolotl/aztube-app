import 'package:aztube/files/filemanager.dart';
import 'package:aztube/files/i_filemanager.dart';
import 'package:aztube/files/settingsmodel.dart';
import 'package:aztube/views/dashboard.dart';
import 'package:aztube/views/linking.dart';
import 'package:aztube/views/loading.dart';
import 'package:fast_qr_reader_view/fast_qr_reader_view.dart';
import 'package:flutter/material.dart';

List<CameraDescription> cameras = [];

Future<void> main() async{
  WidgetsFlutterBinding.ensureInitialized();

  IFileManager fileManager = FileManager();

  List<CameraDescription> cameras = await availableCameras();
  Future<Settings> settings = fileManager.getSettings();

  runApp(AzTube(settings: settings, cameras: cameras));
}

class AzTube extends StatelessWidget {

  const AzTube({Key? key, required this.settings, required this.cameras}) : super(key: key);

  final Future<Settings> settings;
  final List<CameraDescription> cameras;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AzTube',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey
      ),
      home: FutureBuilder(future: settings,
        builder: (context, snapshot) {
          if(snapshot.hasData){
            Settings current = snapshot.data as Settings;
            if(current.deviceHash == '0'){
                return LinkingScreen(cameras: cameras, settings: current);
            }
            return DashboardScreen(title: 'AzTube', settings: current);
          }else if(snapshot.hasError){
            return LinkingScreen(cameras: cameras, settings: Settings());
          }
          return const LoadingScreen();
        })
    );
  }
}