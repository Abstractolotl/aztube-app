import 'package:aztube/aztube.dart';
import 'package:aztube/data/device_link_info.dart';
import 'package:aztube/data/download_info.dart';
import 'package:aztube/data/video_info.dart';
import 'package:aztube/views/dashboard_view.dart';
import 'package:aztube/views/device_link_view.dart';
import 'package:aztube/views/settings_view.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const AzTube());
}

class AzTube extends StatelessWidget {
  const AzTube({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AzTubeApp>(
      create: (_) => someTestData(),
      child: MaterialApp(
        title: 'Flutter Demo',
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
        routes: {
          '/': (context) => const DashboardView(),
          '/settings': (context) => const SettingsView(),
          '/link': (context) => const DeviceLinkView(),
        },
      ),
    );
  }

  AzTubeApp someTestData() {
    var app = AzTubeApp();
    // app.deviceLinks["some-token"] = (DeviceLinkInfo("some-token", "The Device"));
    // app.downloads["dwn-id"] = (DownloadInfo(
    //     video: VideoInfo(
    //       "uA832zpafis",
    //       "Let Me Let You Go",
    //       "ONE OK ROCK",
    //       VideoQuality.audio,
    //     ),
    //     id: "dwn-id"));
    return app;
  }
}
