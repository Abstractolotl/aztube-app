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
      icon: const Icon(Icons.settings, color: Theme.of(context).primaryIconTheme.color),
      tooltip: 'Open Settings')
    ];
  }
  
}