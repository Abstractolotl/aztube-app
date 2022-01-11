import 'package:aztube/api/apihelper.dart';
import 'package:aztube/elements/simplebutton.dart';
import 'package:aztube/files/filemanager.dart';
import 'package:aztube/files/settingsmodel.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {

  const SettingsScreen({Key? key, required this.settings}) : super(key: key);

  final Settings settings;

  @override
  State<StatefulWidget> createState() => SettingsScreenState();

}

class SettingsScreenState extends State<SettingsScreen> {

  Key key = UniqueKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Container(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
        child: ListView(children: [
          SimpleButton(
            child: const Text('Unlink'),
            color: (widget.settings.deviceHash.length >= 10) ? Colors.red : Colors.grey,
            onPressed: () {
              if(widget.settings.deviceHash.length >= 10){
                APIHelper.unregisterDevice(widget.settings.deviceHash);
                widget.settings.deviceHash = '0';
                FileManager().save(widget.settings);
                Navigator.pop(context);
              }
            },
          )
        ]),
      )
    );

  }

}
