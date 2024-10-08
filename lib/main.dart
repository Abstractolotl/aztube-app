import 'package:aztube/aztube.dart';
import 'package:aztube/data/video_info.dart';
import 'package:aztube/views/dashboard_view.dart';
import 'package:aztube/views/debug_view.dart';
import 'package:aztube/views/device_link_view.dart';
import 'package:aztube/views/settings_view.dart';
import 'package:aztube/views/share_view.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:receive_intent/receive_intent.dart';

void main() {
  runApp(const AzTube());
}

class AzTube extends StatelessWidget {
  const AzTube({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: initAzTube(),
        builder: (BuildContext context, AsyncSnapshot<AzTubeApp> snapshot) {
          if (!snapshot.hasData) {
            return const MaterialApp(home: Text("Loading"));
          }

          if (snapshot.hasError) {
            return const MaterialApp(home: Text("Some friggin Error"));
          }

          return ChangeNotifierProvider<AzTubeApp>(
            create: (context) => snapshot.data!,
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
              initialRoute: ShareView.info == null ? '/' : '/share',
              routes: {
                '/': (context) => const DashboardView(),
                '/debug': (context) => const DebugView(),
                '/settings': (context) => const SettingsView(),
                '/link': (context) => const DeviceLinkView(),
                '/share': (context) => const ShareView(),
              },
            ),
          );
        });
  }

  Future<AzTubeApp> initAzTube() async {
    var app = AzTubeApp();
    await app.init();
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
