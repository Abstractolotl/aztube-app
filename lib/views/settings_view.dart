import 'package:aztube/api/aztube_api.dart';
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
            ...settingsSegment(context, theme, app),
            const Divider(),
            ...deviceLinksSegment(context, theme, app),
          ],
        ),
      ),
    );
  }

  List<Widget> settingsSegment(BuildContext context, TextTheme theme, AzTubeApp app) {
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
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity,
        height: 50.0,
        child: ElevatedButton(
            onPressed: () {
              app.clearAllData();
            },
            child: const Text("Clear All Data")),
      ),
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity,
        height: 50.0,
        child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushNamed('/debug');
            },
            child: const Text("Debug View")),
      )
    ];
  }

  List<Widget> deviceLinksSegment(BuildContext context, TextTheme theme, AzTubeApp app) {
    var widgets = [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text("Connected Devices", style: theme.bodyLarge),
      )
    ];

    var it = app.deviceLinks.values.iterator;
    return [
      ...widgets,
      if (app.deviceLinks.isEmpty)
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text("No devices connected", style: TextStyle(color: Colors.grey)),
        ),
      ListView.builder(
          shrinkWrap: true,
          itemCount: app.deviceLinks.length,
          itemBuilder: (context, index) {
            it.moveNext();
            var current = it.current;
            return DeviceLinkItem(
              info: current,
              onDelete: () {
                unlinkDevice(context, current);
              },
              onEdit: () {
                editLink(context, current);
              },
            );
          }),
      SizedBox(
        width: double.infinity,
        height: 50.0,
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).pushNamed('/link'),
          child: const Text("Link Device"),
        ),
      ),
    ];
  }

  void editLink(BuildContext context, DeviceLinkInfo info) {
    final TextEditingController textFieldController = TextEditingController(text: info.deviceName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Rename Connected Device"),
        content: TextField(
          onChanged: (value) {},
          controller: textFieldController,
          decoration: InputDecoration(hintText: info.deviceName),
        ),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                "Cancel",
              )),
          TextButton(
              onPressed: () {
                AzTubeApp app = Provider.of(context, listen: false);
                app.renameDeviceLink(info, textFieldController.text);

                Navigator.pop(context);
              },
              child: const Text("Rename")),
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
                Navigator.pop(context);
              },
              child: const Text("Cancel")),
          TextButton(
              onPressed: () async {
                AzTubeApp app = Provider.of(context, listen: false);
                try {
                  await unregister(info.deviceToken);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Could not unlink device: $e")));
                  }
                }
                app.removeDeviceLink(info);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text(
                "Unlink Device",
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
