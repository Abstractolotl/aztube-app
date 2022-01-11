import 'package:aztube/elements/aztubebar.dart';
import 'package:aztube/elements/simplebutton.dart';
import 'package:aztube/files/settingsmodel.dart';
import 'package:aztube/views/linking.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class DashboardScreen extends StatefulWidget {

  const DashboardScreen({Key? key, required this.settings}) : super(key: key);

  final Settings settings;

  @override
  State<StatefulWidget> createState() => DashboardScreenState();

}

class DashboardScreenState extends State<DashboardScreen> {

  bool startlink = false;

  @override
  Widget build(BuildContext context) {
    if(startlink){
      return LinkingScreen(settings: widget.settings);
    }

    if(widget.settings.deviceHash.length < 10){
      return Scaffold(
        appBar: AppBar(title: AzTubeBar.title, actions: AzTubeBar.buildActions(context, widget.settings)),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          Center(
           child: Container(
               padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 5.0),
               child: SimpleButton(
                 child: const Text('Link Browser'),
                 color: Colors.green,
                 onPressed: () {
                   Navigator.push(context, MaterialPageRoute(builder: (context) => LinkingScreen(settings: widget.settings)));
                 },
               )
           )
          )
        ]),
      );
    }

    return Scaffold(
      appBar: AppBar(title: AzTubeBar.title, actions: AzTubeBar.buildActions(context, widget.settings)),
    );

  }

}
