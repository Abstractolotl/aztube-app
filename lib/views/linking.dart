import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:aztube/api/apihelper.dart';
import 'package:aztube/elements/aztubebar.dart';
import 'package:aztube/files/filemanager.dart';
import 'package:aztube/files/i_filemanager.dart';
import 'package:aztube/files/settingsmodel.dart';
import 'package:aztube/views/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class LinkingScreen extends StatefulWidget {

  const LinkingScreen({Key? key, required this.settings}) : super(key: key);

  final Settings settings;

  @override
  State<StatefulWidget> createState() => LinkingScreenState();

}

class LinkingScreenState extends State<LinkingScreen> {

  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  bool dashboard = false;
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
    if(dashboard){
      return DashboardScreen(settings: widget.settings);
    }
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
      appBar: AppBar(title: AzTubeBar.title,),
      body: _buildQrView(context),
    );
  }

  void registerDevice(String browserCode) async{
    var response = await APIHelper.registerDevice(browserCode);
    if(response.statusCode == 200){
      if(jsonDecode(response.body)['success']){
          var deviceUUID = jsonDecode(response.body)['uuid'];
          widget.settings.deviceHash = deviceUUID;
          FileManager().save(widget.settings);
          Navigator.pop(context);
      }else{
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid Code'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating),
        );
      }
    }else{
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid Code'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating),
      );
    }
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
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('no Permission')),
      );
    }
  }

}
