import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:aztube/api/apihelper.dart';
import 'package:aztube/elements/aztubebar.dart';
import 'package:aztube/files/filemanager.dart';
import 'package:aztube/files/i_filemanager.dart';
import 'package:aztube/files/settingsmodel.dart';
import 'package:flutter/material.dart';

import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:matomo_tracker/matomo_tracker.dart';


class LinkingScreen extends StatefulWidget {

  const LinkingScreen({Key? key, required this.settings}) : super(key: key);

  final Settings settings;

  @override
  State<StatefulWidget> createState() => LinkingScreenState();

}

class LinkingScreenState extends State<LinkingScreen> with TraceableClientMixin {

  bool registering = false;
  IFileManager fileManager = FileManager();

  Barcode? result;

  @override
  String get traceName => 'Started Linking';

  @override
  String get traceTitle => 'Link Browser';


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
                ),
                Center(
                  child: const Text('Transfering Data')
                )
              ]
          )
      );
    }
    if((result?.rawValue ?? '0').length >= 10) {
      var browserCode = (result?.rawValue ?? '0');
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
      body: MobileScanner(
          allowDuplicates: false,
          onDetect: (barcode, args) {
            if (barcode.rawValue != null) {
              setState(() {
                result = barcode;
              });
            }
          }),
    );
  }

  void registerDevice(String browserCode) async{
    var deviceName = await getDeviceName();
    var response = await APIHelper.registerDevice(browserCode, deviceName);
    if(response.statusCode == 200){
      if(jsonDecode(response.body)['success']){
          MatomoTracker.instance.trackEvent(
            eventName: 'deviceLinked',
            action: 'scan',
            eventCategory: 'Linking',
          );
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
