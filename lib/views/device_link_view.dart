import 'dart:io';

import 'package:aztube/api/aztube_api.dart';
import 'package:aztube/aztube.dart';
import 'package:aztube/data/device_link_info.dart';
import 'package:aztube/strings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:uuid/uuid.dart';

class DeviceLinkView extends StatefulWidget {
  const DeviceLinkView({super.key});

  @override
  State<DeviceLinkView> createState() => _DeviceLinkViewState();
}

class _DeviceLinkViewState extends State<DeviceLinkView> {
  QRViewController? controller;
  AzTubeApp? app;
  ScaffoldMessengerState? messenger;
  NavigatorState? nav;

  void initController(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((event) {
      if (event.code == null) return;
      controller.stopCamera();
      onQRScanned(event.code!);
    });
  }

  void onQRScanned(String code) async {
    if (!Uuid.isValidUUID(fromString: code)) {
      messenger?.showSnackBar(const SnackBar(content: Text("Malformed QR Code")));

      return;
    }
    try {
      String deviceToken = await registerDeviceLink(code, "My Device");
      app?.addDeviceLinks(DeviceLinkInfo(deviceToken, "My Computer", DateTime.now()));
      nav?.pop();
    } catch (e) {
      messenger?.showSnackBar(SnackBar(content: Text(e.toString())));
    }
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
    messenger = ScaffoldMessenger.of(context);

    return Scaffold(
      appBar: appBar(),
      body: Column(
        children: [
          camPanel(),
          bottomPanel(),
        ],
      ),
    );
  }

  Widget camPanel() {
    return GestureDetector(
      onTap: () {
        controller?.resumeCamera();
        controller?.toggleFlash();
      },
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(children: [
          QRView(
            key: GlobalKey(debugLabel: 'QR'),
            onQRViewCreated: initController,
          ),
          Image.asset("assets/device_link_qr_overlay.png"),
        ]),
      ),
    );
  }

  Widget bottomPanel() {
    return const Flexible(
      flex: 1,
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text("Open the AzTube Browser Extension\n and press \"Link new Device\"", textAlign: TextAlign.center),
            Spacer(),
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
    );
  }

  AppBar appBar() {
    return AppBar(
      title: const Text(APP_TITLE),
    );
  }
}
