import 'dart:async';
import 'dart:io';

import 'package:aztube/analytics.dart';
import 'package:aztube/api/aztube_api.dart';
import 'package:aztube/aztube.dart';
import 'package:aztube/data/device_link_info.dart';
import 'package:aztube/strings.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class DeviceLinkView extends StatefulWidget {
  const DeviceLinkView({super.key});

  @override
  State<DeviceLinkView> createState() => _DeviceLinkViewState();
}

class _DeviceLinkViewState extends State<DeviceLinkView> with WidgetsBindingObserver {
  final MobileScannerController controller = MobileScannerController();

  StreamSubscription<BarcodeCapture>? subscription;
  bool loading = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    subscription = controller.barcodes.listen(handleBarcodeScan);
    controller.start();
  }

  @override
  void dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    subscription?.cancel();
    subscription = null;
    super.dispose();
    await controller.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!controller.value.hasCameraPermission) {
      return;
    }

    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return;

      case AppLifecycleState.resumed:
        subscription = controller.barcodes.listen(handleBarcodeScan);

        controller.start();
      case AppLifecycleState.inactive:
        subscription?.cancel();
        subscription = null;
        controller.stop();
    }
  }

  void handleBarcodeScan(BarcodeCapture barcodes) async {
    var code = barcodes.barcodes.firstOrNull;
    if (code == null || code.displayValue == null) {
      return;
    }

    subscription?.cancel();
    subscription = null;

    await handleBarcode(code);

    subscription = controller.barcodes.listen(handleBarcodeScan);
  }

  Future<void> handleBarcode(Barcode code) async {
    var scannedString = code.displayValue!;

    if (!Uuid.isValidUUID(fromString: scannedString)) {
      AzTubeAnalytics.logQRScanned(QrType.invalidQr, DeviceName.unknown);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Malformed QR Code")));
      return;
    }

    setState(() {
      loading = true;
    });

    AzTubeApp app = Provider.of(context, listen: false);
    String deviceName;
    DeviceName device;
    if (Platform.isAndroid) {
      var info = await DeviceInfoPlugin().androidInfo;
      deviceName = info.model;
      device = DeviceName.success;
    } else {
      deviceName = "Mysterious Device ôo";
      device = DeviceName.unknown;
    }

    try {
      String deviceToken = await registerDeviceLink(scannedString, deviceName, app.firebaseToken);
      AzTubeAnalytics.logQRScanned(QrType.success, device);
      app.addDeviceLinks(DeviceLinkInfo(deviceToken, "My Computer", DateTime.now()));
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      AzTubeAnalytics.logQRScanned(QrType.serviceError, device);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
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
      onTap: () => {controller.toggleTorch()},
      onDoubleTap: () => {controller.switchCamera()},
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(children: [
          MobileScanner(controller: controller),
          Image.asset("assets/device_link_qr_overlay.png"),
          if (loading) const Center(child: CircularProgressIndicator())
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
