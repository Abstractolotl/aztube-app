import 'package:aztube_app/elements/aztubebar.dart';
import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {

  const DashboardScreen({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<StatefulWidget> createState() => DashboardScreenState();

}

class DashboardScreenState extends State<DashboardScreen> {

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: AzTubeBar.title, actions: AzTubeBar.settings),
    );

  }

}
