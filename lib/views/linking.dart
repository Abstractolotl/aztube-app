import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:aztube/api/apihelper.dart';
import 'package:aztube/elements/aztubebar.dart';
import 'package:aztube/files/filemanager.dart';
import 'package:aztube/files/i_filemanager.dart';
import 'package:aztube/files/settingsmodel.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:device_info_plus/device_info_plus.dart';


class LinkingScreen extends StatefulWidget {

  const LinkingScreen({Key? key, required this.settings}) : super(key: key);

  final Settings settings;

  @override
  State<StatefulWidget> createState() => LinkingScreenState();

}

class LinkingScreenState extends State<LinkingScreen> {

  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  bool registering = false;
  Barcode? result;
  QRViewController? controller;
  IFileManager fileManager = FileManager();

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if(registering){
      return Scaffold(
          appBar: AppBar(title: AzTubeBar.title,),
          body:  Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Center(
                    child: CircularProgressIndicator(color: Colors.green)
                )
              ]
          )
      );
    }
    if((result?.code.toString() ?? '0' ).length >= 10) {
      var browserCode = result?.code.toString() ?? '0';
      registerDevice(browserCode);
      registering = true;
      return Scaffold(
          appBar: AppBar(title: AzTubeBar.title,),
          body:  Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Center(
                    child: CircularProgressIndicator(color: Colors.green)
                )
              ]
          )
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Link Browser')),
      body: _buildQrView(context),
    );
  }

  void registerDevice(String browserCode) async{
    var deviceName = await getDeviceName();
    var response = await APIHelper.registerDevice(browserCode, deviceName);
    if(response.statusCode == 200){
      if(jsonDecode(response.body)['success']){
          var deviceToken = jsonDecode(response.body)['deviceToken'];
          if(deviceToken != null){
            widget.settings.deviceHash = deviceToken;
            FileManager().saveSettings(widget.settings);
            Navigator.pop(context);
            return;
          }else{
            redirectWithError();
          }
      }else{
        redirectWithError();
      }
    }else{
      redirectWithError();
    }
  }

  void redirectWithError(){
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invalid Code'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating),
    );
  }

  Widget _buildQrView(BuildContext context) {
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
        MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: Colors.red,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      if(!registering){
        setState(() {
          result = scanData;
        });
      }
    });
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    dev.log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('no Permission')),
      );
    }
  }

  Future<String> getDeviceName() async{
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if(Platform.isAndroid){
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return androidInfo.model ?? 'Android';
    }
    if(Platform.isIOS){
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return iosInfo.utsname.machine ?? 'IOS';
    }
    WebBrowserInfo webBrowserInfo = await deviceInfo.webBrowserInfo;
    return webBrowserInfo.userAgent ?? 'Browser';
  }

}
