import 'dart:io';

import 'package:aztube/aztube.dart';
import 'package:aztube/data/device_link_info.dart';
import 'package:aztube/strings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class DeviceLinkView extends StatefulWidget {
  const DeviceLinkView({super.key});

  @override
  State<DeviceLinkView> createState() => _DeviceLinkViewState();
}

class _DeviceLinkViewState extends State<DeviceLinkView> {
  QRViewController? controller;
  AzTubeApp? app;
  NavigatorState? nav;

  void initController(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((event) {
      debugPrint("Got QR: ${event.code}");
      controller.stopCamera();

      if (event.code == null) return;
      onQRScanned(event.code!);
    });
  }

  void onQRScanned(String code) {
    debugPrint("Did some scanning");
    //check is qr format valid: is UUID?
    //contact AzTube api, poll code or whatever
    //add Device Link to shiit
    app?.deviceLinks[code] = DeviceLinkInfo(code, "Some Device");
    app?.notifyListeners();
    debugPrint("Can Pop? ${nav?.canPop()}");
    nav?.pop();
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    } else if (Platform.isIOS) {
      controller!.resumeCamera();
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    app = Provider.of(context);
    nav = Navigator.of(context);
    return Scaffold(
      appBar: appBar(),
      body: Padding(
        padding: const EdgeInsets.all(00.0),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(children: [
                QRView(
                  key: GlobalKey(debugLabel: 'QR'),
                  onQRViewCreated: initController,
                ),
                Image.asset("assets/device_link_qr_overlay.png"),
              ]),
            ),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text("Open the AzTube Browser extension and press \"Link new Device\"", textAlign: TextAlign.center),
                  Text.rich(TextSpan(
                    text: "Need help? Go to ",
                    children: [
                      TextSpan(
                          text: "aztube.com/help",
                          style: TextStyle(
                            decoration: TextDecoration.underline,
                          )),
                    ],
                  ))
                ],
              ),
            ),
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
