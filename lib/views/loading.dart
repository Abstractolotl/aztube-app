import 'package:flutter/material.dart';

class LoadingScreen extends StatefulWidget {

  const LoadingScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => LoadingScreenState();

}

class LoadingScreenState extends State<LoadingScreen> {

  @override
  Widget build(BuildContext context) {

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      )
    );

  }

}
