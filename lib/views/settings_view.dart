import 'package:aztube/aztube.dart';
import 'package:aztube/components/device_link_item.dart';
import 'package:aztube/data/device_link_info.dart';
import 'package:aztube/strings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    AzTubeApp app = Provider.of(context);
    var theme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: appBar(),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...settingsSegment(theme, app),
            const Divider(),
            ...deviceLinksSegment(context, theme, app),
          ],
        ),
      ),
    );
  }

  List<Widget> settingsSegment(TextTheme theme, AzTubeApp app) {
    return [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text("Settings ${app.loadingError}", style: theme.bodyLarge),
      ),
      ListTile(
        title: const Text("Auto Download"),
        subtitle: const Text("Start downloading as soon as possible"),
        trailing: Checkbox(
          onChanged: (value) {},
          value: false,
        ),
      ),
      Center(
        child: ElevatedButton(
            onPressed: () {
              app.clearAllData();
            },
            child: const Text("Clear All Data")),
      )
    ];
  }

  List<Widget> deviceLinksSegment(BuildContext context, TextTheme theme, AzTubeApp app) {
    var it = app.deviceLinks.values.iterator;
    return [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text("Connected Devices", style: theme.bodyLarge),
      ),
      ListView.builder(
          shrinkWrap: true,
          itemCount: app.deviceLinks.length,
          itemBuilder: (context, index) {
            it.moveNext();
            return DeviceLinkItem(
              info: it.current,
              onDelete: () {
                unlinkDevice(context, it.current);
              },
              onEdit: () {
                editLink(context, it.current);
              },
            );
          }),
      Container(
        padding: const EdgeInsets.all(8),
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).pushNamed('/link'),
          child: const Text("Link Device"),
        ),
      ),
    ];
  }

  void editLink(BuildContext context, DeviceLinkInfo info) {
    final TextEditingController _textFieldController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Rename Connected Device"),
        content: TextField(
          onChanged: (value) {},
          controller: _textFieldController,
          decoration: InputDecoration(hintText: info.deviceName),
        ),
        actions: [
          TextButton(
              onPressed: () {
                AzTubeApp app = Provider.of(context, listen: false);
                app.renameDeviceLink(info, _textFieldController.text);

                Navigator.pop(context);
              },
              child: const Text("Rename")),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.red),
              )),
        ],
      ),
    );
  }

  void unlinkDevice(BuildContext context, DeviceLinkInfo info) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Unlink Device"),
        content: Text("Do you really want to unlink ${info.deviceName}?"),
        actions: [
          TextButton(
              onPressed: () {
                AzTubeApp app = Provider.of(context, listen: false);
                app.removeDeviceLink(info);
                Navigator.pop(context);
              },
              child: const Text("Unlink Device")),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.red),
              )),
        ],
      ),
    );
  }

  AppBar appBar() {
    return AppBar(
      title: const Text(APP_TITLE),
    );
  }
}
