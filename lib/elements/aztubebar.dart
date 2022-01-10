import 'package:flutter/material.dart';

class AzTubeBar{

  static const Text title = Text('AzTube');

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