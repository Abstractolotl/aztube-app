import 'package:aztube/aztube.dart';
import 'package:aztube/api/aztube_api.dart';
import 'package:aztube/strings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DebugView extends StatelessWidget {
  const DebugView({super.key});

  @override
  Widget build(BuildContext context) {
    AzTubeApp app = Provider.of(context);
    var theme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: appBar(),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: () {
                debugPrint("Go!");
                try {
                  registerDeviceLink("123", "My Device").catchError((e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                  });
                } catch (e) {}
              },
              child: const Text("Send generate!"),
            )
          ],
        ),
      ),
    );
  }

  AppBar appBar() {
    return AppBar(
      title: const Text(APP_TITLE),
    );
  }
}
