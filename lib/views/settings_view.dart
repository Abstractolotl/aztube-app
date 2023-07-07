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
            ...settingsSegment(theme),
            const Divider(),
            ...deviceLinksSegment(theme, app.deviceLinks.values),
          ],
        ),
      ),
    );
  }

  List<Widget> settingsSegment(TextTheme theme) {
    return [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text("Settings", style: theme.bodyLarge),
      ),
      ListTile(
        title: const Text("Auto Download"),
        subtitle: const Text("Start downloading as soon as possible"),
        trailing: Checkbox(
          onChanged: (value) {},
          value: false,
        ),
      )
    ];
  }

  List<Widget> deviceLinksSegment(TextTheme theme, Iterable<DeviceLinkInfo> links) {
    return [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text("Connected Devices", style: theme.bodyLarge),
      ),
      ListView.builder(
          shrinkWrap: true,
          itemCount: links.length,
          itemBuilder: (context, index) {
            return DeviceLinkItem(info: links.elementAt(index));
          }),
      Container(
        padding: const EdgeInsets.all(8),
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {},
          child: const Text("Link Device"),
        ),
      ),
    ];
  }

  AppBar appBar() {
    return AppBar(
      title: const Text(APP_TITLE),
    );
  }
}
