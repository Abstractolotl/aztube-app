import 'dart:io';
import 'dart:ui';

import 'package:aztube/aztube.dart';
import 'package:aztube/firebase_options.dart';
import 'package:aztube/views/dashboard_view.dart';
import 'package:aztube/views/debug_view.dart';
import 'package:aztube/views/device_link_view.dart';
import 'package:aztube/views/settings_view.dart';
import 'package:aztube/views/share_view.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid) {
    await MediaStore.ensureInitialized();
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  if ((await MediaStore().getPlatformSDKInt()) >= 33) {
    Permission.audio.request();
  }

  await FirebaseMessaging.instance.requestPermission(provisional: true, alert: true);
  var token = await FirebaseMessaging.instance.getToken();

  var app = AzTubeApp(token ?? "");
  await app.init();

  runApp(AzTube(app: app));
}

class AzTube extends StatelessWidget {
  final AzTubeApp app;

  const AzTube({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AzTubeApp>(
      create: (context) => app,
      child: MaterialApp(
        title: 'AzTube',
        theme: ThemeData(
          textTheme: GoogleFonts.comfortaaTextTheme(const TextTheme(
            titleSmall: TextStyle(fontWeight: FontWeight.bold),
            titleMedium: TextStyle(fontWeight: FontWeight.bold),
            titleLarge: TextStyle(fontWeight: FontWeight.bold),
            labelSmall: TextStyle(color: Colors.black45),
            labelMedium: TextStyle(color: Colors.black45),
            labelLarge: TextStyle(color: Colors.black45),
          )),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const DashboardView(),
          '/debug': (context) => const DebugView(),
          '/settings': (context) => const SettingsView(),
          '/link': (context) => const DeviceLinkView(),
          '/share': (context) => const ShareView(),
        },
      ),
    );
  }
}
