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
    //ThemeData theme = Theme.of(context);
    return Consumer<AzTubeApp>(
      builder: (context, app, child) => Scaffold(
        appBar: appBar(context),
        body: dashboardBody(context, app),
      ),
    );
  }

  Future<void> onRefresh() async {}

  Widget dashboardBody(BuildContext context, AzTubeApp app) {
    if (!app.hasDeviceLinks()) {
      return noDeviceLink(context);
    }

    return downloadList(app.downloads.values);
  }

  Widget downloadList(Iterable<DownloadInfo> downloads) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        itemCount: downloads.length,
        itemBuilder: (context, index) {
          return DownloadItem(
            info: downloads.elementAt(index),
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
}
