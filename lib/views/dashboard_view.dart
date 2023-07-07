import 'package:aztube/aztube.dart';
import 'package:aztube/data/download_info.dart';
import 'package:aztube/components/download_item.dart';
import 'package:aztube/main.dart';
import 'package:aztube/strings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  void startDeviceLinking() {}

  @override
  Widget build(BuildContext context) {
    //ThemeData theme = Theme.of(context);
    return Consumer<AzTubeApp>(
      builder: (context, app, child) => Scaffold(
        appBar: appBar(context),
        body: downloadList(app.downloads.values),
      ),
    );
  }

  Widget downloadList(Iterable<DownloadInfo> downloads) {
    return ListView.builder(
      itemCount: downloads.length,
      itemBuilder: (context, index) {
        return DownloadItem(
          info: downloads.elementAt(index),
        );
      },
    );
  }

  Widget noDeviceLink(ThemeData theme) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(10.0),
        constraints: const BoxConstraints.expand(width: double.infinity, height: 75),
        child: ElevatedButton(
          onPressed: startDeviceLinking,
          child: const Text('Link Browser'),
        ),
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
}
