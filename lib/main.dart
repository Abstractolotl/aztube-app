import 'package:aztube/files/filemanager.dart';
import 'package:aztube/files/i_filemanager.dart';
import 'package:aztube/files/settingsmodel.dart';
import 'package:aztube/views/dashboard.dart';
import 'package:aztube/views/linking.dart';
import 'package:aztube/views/loading.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

List<CameraDescription> cameras = [];

Future<void> main() async{
  WidgetsFlutterBinding.ensureInitialized();

  IFileManager fileManager = FileManager();

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
            return const DashboardScreen();
          }else if(snapshot.hasError){
            return const DashboardScreen();
          }
          return const LoadingScreen();
        })
    );
  }
}