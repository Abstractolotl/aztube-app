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

  void restartApp() {
    setState(() {
      key = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(children: [
        Container(child: TextButton(onPressed: (){
          widget.settings.deviceHash = '0';
          FileManager().save(widget.settings);
          restartApp();
        },child: const Text('Unlink')),padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 15.0))
      ]),
    );

  }

}
