import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:just_waveform/just_waveform.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:receive_intent/receive_intent.dart';

import 'package:aztube/api/aztube_api.dart';
import 'package:aztube/aztube.dart';
import 'package:aztube/components/download_item.dart';
import 'package:aztube/data/download_info.dart';
import 'package:aztube/data/video_info.dart';
import 'package:aztube/strings.dart';
import 'package:aztube/views/debug_view.dart';
import 'package:aztube/views/share_view.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> with WidgetsBindingObserver {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  final List<StreamSubscription> _sub = List.empty(growable: true);

  @override
  void initState() {
    super.initState();

    _sub.add(FirebaseMessaging.onMessage.listen((event) {
      _refreshIndicatorKey.currentState?.show();
    }));

    SchedulerBinding.instance.addPostFrameCallback((_) {
      _refreshIndicatorKey.currentState?.show();
    });

    _sub.add(ReceiveIntent.receivedIntentStream.listen((intent) {
      if (intent != null && intent.action == "android.intent.action.SEND") {
        var title = intent.extra!["android.intent.extra.SUBJECT"];
        var url = Uri.parse(intent.extra!["android.intent.extra.TEXT"]);
        var id = url.queryParameters["v"];

        if (id != null) {
          ShareView.info = DownloadInfo(
              video: VideoInfo(id, title, "", VideoQuality.audio),
              id: DateTime.now().millisecondsSinceEpoch.toString());
          Navigator.of(context).pushNamed("/share");
        } else {
          debugPrint("Could not find video id in $url");
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Could not find video id in $url")));
        }
      }
    }));
  }

  @override
  void dispose() {
    for (var element in _sub) {
      element.cancel();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint("Resumed");
      _refreshIndicatorKey.currentState?.show();
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addObserver(this);
    var messenger = ScaffoldMessenger.of(context);
    return Consumer<AzTubeApp>(
      builder: (context, app, child) => Scaffold(
        appBar: appBar(context),
        body: dashboardBody(context, app, messenger),
      ),
    );
  }

  Future<void> onRefresh(AzTubeApp app, ScaffoldMessengerState messenger) async {
    for (var deviceLink in app.deviceLinks.values) {
      try {
        var downloadsVideoInfos = await pollDownloads(deviceLink.deviceToken);

        var downloads = downloadsVideoInfos.map((e) {
          var downloadId = "${Random().nextInt(0x000000FFFFFF)}";
          return DownloadInfo(video: e, id: downloadId);
        }).toList();

        app.addDownloads(downloads);
      } catch (e) {
        messenger.showSnackBar(SnackBar(content: Text("Could not Poll for Device Link ${deviceLink.deviceName} $e")));
      }
    }
  }

  Widget dashboardBody(BuildContext context, AzTubeApp app, ScaffoldMessengerState messenger) {
    if (!app.hasDeviceLinks() && app.downloads.isEmpty) {
      return noDeviceLink(context);
    }

    return RefreshIndicator(
      key: _refreshIndicatorKey,
      onRefresh: () => onRefresh(app, messenger),
      child: downloadList(context, app, messenger),
    );
  }

  Widget downloadList(BuildContext context, AzTubeApp app, ScaffoldMessengerState messenger) {
    var downlodas = app.downloads.values;

    if (downlodas.isEmpty) {
      return ListView.builder(
        itemCount: 1,
        itemBuilder: ((context, index) => noDownloads()),
      );
    }

    Widget noDeviceBanner = MaterialBanner(
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        padding: const EdgeInsets.all(20),
        content: const Text("No Device Linked! \nTry linking a device to start downloads from your Browser."),
        actions: <Widget>[
          TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/link');
              },
              child: const Text("Link Device"))
        ]);

    return Column(
      children: [
        if (app.deviceLinks.isEmpty) noDeviceBanner,
        Expanded(
          child: ListView.builder(
              itemCount: app.downloads.values.length,
              itemBuilder: (context, index) {
                DownloadInfo info = app.downloads.values.elementAt(index);
                return DownloadItem(
                  info: info,
                  onOpen: (() => openDownloadItemMenu(context, info)),
                );
              }),
        ),
      ],
    );
  }

  Widget noDeviceLink(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("There is currently no Device Link"),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 25),
            child: Icon(
              Icons.no_cell,
              size: 100,
              color: Colors.black54,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pushNamed('/link'),
                child: const Text('Link Browser'),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 25),
            child: Text("Please refer to this page for support."),
          )
        ],
      ),
    );
  }

  Widget loading(ThemeData theme) {
    return Center(
      child: CircularProgressIndicator(color: theme.primaryColor),
    );
  }

  Widget noDownloads() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 25),
            child: Icon(
              Icons.download,
              size: 100,
              color: Colors.black54,
            ),
          ),
          Text("No Downloads"),
        ],
      ),
    );
  }

  AppBar appBar(BuildContext context) {
    return AppBar(
      title: const Text(APP_TITLE),
      actions: [
        IconButton(
          onPressed: () => Navigator.of(context).pushNamed('/settings'),
          icon: const Icon(Icons.settings),
        )
      ],
    );
  }

  final mediaStorePlugin = MediaStore();
  void openDownloadItemMenu(BuildContext context, DownloadInfo info) {
    Future<Waveform> waveformFuture = () async {
      final completer = Completer<Waveform>();

      String downloadPath = (await mediaStorePlugin.getFilePathFromUri(uriString: info.downloadLocation!))!;
      File audioFile = File(downloadPath);
      File waveFile = File(p.join((await getTemporaryDirectory()).path, "waveform.wave"));
      if (waveFile.existsSync()) {
        completer.complete(await JustWaveform.parse(waveFile));
      } else {
        JustWaveform.extract(audioInFile: audioFile, waveOutFile: waveFile).listen((event) {
          if (event.progress >= 1.0) {
            completer.complete(event.waveform);
          }
        }, onError: (error) {
          completer.completeError(error);
        });
      }
      return await completer.future;
    }();

    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text("Delete Item"),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    const Text("Downloaded data remains on your device."),
                    Text(info.downloadLocation ?? ""),
                    FutureBuilder(
                        future: waveformFuture,
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            debugPrint("YEAH");
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: snapshot.data!.duration.inSeconds * 5,
                                height: 100,
                                child: AudioWaveformWidget(
                                    waveform: snapshot.data!, start: Duration.zero, duration: snapshot.data!.duration),
                              ),
                            );
                          }
                          debugPrint("RIP: " + snapshot.error.toString());
                          return const CircularProgressIndicator();
                        }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Cancel"),
                ),
                if (info.progress <= 0)
                  TextButton(
                    onPressed: () {
                      ShareView.info = info;
                      Navigator.of(context).pushNamed("/share");
                    },
                    child: const Text("Edit"),
                  ),
                TextButton(
                  onPressed: () {
                    AzTubeApp app = Provider.of(context, listen: false);
                    app.removeDownload(info);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Delete",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ));
  }
}

class AudioWaveformWidget extends StatefulWidget {
  final Color waveColor;
  final double scale;
  final double strokeWidth;
  final double pixelsPerStep;
  final Waveform waveform;
  final Duration start;
  final Duration duration;

  const AudioWaveformWidget({
    Key? key,
    required this.waveform,
    required this.start,
    required this.duration,
    this.waveColor = Colors.blue,
    this.scale = 1.0,
    this.strokeWidth = 5.0,
    this.pixelsPerStep = 8.0,
  }) : super(key: key);

  @override
  _AudioWaveformState createState() => _AudioWaveformState();
}

class _AudioWaveformState extends State<AudioWaveformWidget> {
  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: CustomPaint(
        painter: AudioWaveformPainter(
          waveColor: widget.waveColor,
          waveform: widget.waveform,
          start: widget.start,
          duration: widget.duration,
          scale: widget.scale,
          strokeWidth: widget.strokeWidth,
          pixelsPerStep: widget.pixelsPerStep,
        ),
      ),
    );
  }
}
