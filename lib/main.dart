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

  ThemeData _darkTheme(){
    return ThemeData(
        brightness: Brightness.dark,

        fontFamily: 'OpenSans',

        textTheme: const TextTheme(
          headline1: TextStyle(fontSize: 17, color: Colors.white),
          bodyText1: TextStyle(fontSize: 10.0, color: Colors.white54),
        )
    );
  }

  ThemeData _lightTheme(){
    return ThemeData(
        primarySwatch: Colors.blueGrey,
        brightness: Brightness.light,

        fontFamily: 'OpenSans',

        textTheme: const TextTheme(
          headline1: TextStyle(fontSize: 17, color: Colors.black),
          bodyText1: TextStyle(fontSize: 10.0, color: Colors.black38),
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AzTube',
      theme: _lightTheme(),
      darkTheme: _darkTheme(),
      home: FutureBuilder(future: settings,
        builder: (context, snapshot) {
          if(snapshot.hasData){
            return const DashboardScreen();
          }else if(snapshot.hasError){
            return const DashboardScreen();
          }
          return const LoadingScreen();
        })
    );
  }
}