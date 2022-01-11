import 'package:aztube/files/settingsmodel.dart';
import 'package:aztube/views/settings.dart';
import 'package:flutter/material.dart';

class AzTubeBar{

  static const Text title = Text('AzTube');

  static List<Widget> buildActions(BuildContext context, Settings settings){
    return <Widget>[
      IconButton(onPressed: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => SettingsScreen(settings: settings)));
      },
      icon: const Icon(Icons.settings, color: Colors.white),
      tooltip: 'Open Settings')
    ];
  }

  static const List<Widget> settings = <Widget>[
    IconButton(onPressed: null,
        icon: Icon(Icons.settings, color: Colors.white),
        tooltip: 'Open Settings')
  ];

  static const List<Widget> home = <Widget>[
    IconButton(onPressed: null,
        icon: Icon(Icons.home, color: Colors.white),
        tooltip: 'Dashboard')
  ];
  
}