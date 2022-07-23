import 'package:aztube/files/filemanager.dart';
import 'package:aztube/files/i_filemanager.dart';
import 'package:aztube/files/settingsmodel.dart';
import 'package:aztube/views/dashboard.dart';
import 'package:aztube/views/loading.dart';
import 'package:flutter/material.dart';
import 'package:matomo_tracker/matomo_tracker.dart';

Future<void> main() async{
  WidgetsFlutterBinding.ensureInitialized();

  IFileManager fileManager = FileManager();

  Future<Settings> settings = fileManager.getSettings();

  await MatomoTracker.instance.initialize(
    siteId: 5,
    url: 'https://analytics.ancozockt.de/matomo.php',
  );

  runApp(AzTube(settings: settings));
}

class AzTube extends StatelessWidget {

  const AzTube({Key? key, required this.settings}) : super(key: key);

  final Future<Settings> settings;

  ThemeData _darkTheme(){
    return ThemeData(
        useMaterial3: true,

        brightness: Brightness.dark,
        primaryColor: Colors.lightBlue[600],
        fontFamily: 'OpenSans',

        textTheme: const TextTheme(
          headline1: TextStyle(fontSize: 17, color: Colors.white),
          bodyText1: TextStyle(fontSize: 10.0, color: Colors.white54)
        ),

        buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary)
    );
  }

  ThemeData _lightTheme(){
    return ThemeData(
        useMaterial3: true,

        brightness: Brightness.light,
        primaryColor: Colors.lightBlue[600],
        fontFamily: 'OpenSans',

        textTheme: const TextTheme(
          headline1: TextStyle(fontSize: 17, color: Colors.black),
          bodyText1: TextStyle(fontSize: 10.0, color: Colors.black38)
        ),

        buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary)
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