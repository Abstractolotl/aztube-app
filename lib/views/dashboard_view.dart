import 'dart:math';

import 'package:aztube/api/aztube_api.dart';
import 'package:aztube/aztube.dart';
import 'package:aztube/data/download_info.dart';
import 'package:aztube/components/download_item.dart';
import 'package:aztube/strings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
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
        //remove device
        messenger.showSnackBar(SnackBar(content: Text("Could not Poll for Device Link ${deviceLink.deviceName} $e")));
      }
    }
  }

  Widget dashboardBody(BuildContext context, AzTubeApp app, ScaffoldMessengerState messenger) {
    if (!app.hasDeviceLinks()) {
      return noDeviceLink(context);
    }

    return downloadList(app, messenger);
  }

  Widget downloadList(AzTubeApp app, ScaffoldMessengerState messenger) {
    return RefreshIndicator(
      onRefresh: () => onRefresh(app, messenger),
      child: ListView.builder(
        itemCount: app.downloads.values.length,
        itemBuilder: (context, index) {
          DownloadInfo info = app.downloads.values.elementAt(index);
          return DownloadItem(
            info: info,
            onOpen: (() => openDownloadItemMenu(context, info)),
          );
        },
      ),
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

  void openDownloadItemMenu(BuildContext context, DownloadInfo info) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text("Delete Item"),
              content: const Text("Downloaded data remains on your device."),
              actions: [
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
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Cancel"),
                )
              ],
            ));
  }
}
