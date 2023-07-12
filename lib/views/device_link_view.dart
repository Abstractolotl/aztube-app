import 'package:aztube/aztube.dart';
import 'package:aztube/strings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class DeviceLinkView extends StatelessWidget {
  const DeviceLinkView({super.key});

  @override
  Widget build(BuildContext context) {
    //AzTubeApp app = Provider.of(context);
    //var theme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: appBar(),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: QRView(key: GlobalKey(debugLabel: 'QR'), onQRViewCreated: (controller) {}),
      ),
    );
  }

  AppBar appBar() {
    return AppBar(
      title: const Text(APP_TITLE),
    );
  }
}
