import 'package:aztube/api/apihelper.dart';
import 'package:aztube/elements/simplebutton.dart';
import 'package:aztube/files/filemanager.dart';
import 'package:aztube/files/settingsmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:matomo_tracker/matomo_tracker.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key, required this.settings}) : super(key: key);

  final Settings settings;

  @override
  State<StatefulWidget> createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> with TraceableClientMixin {
  static const platform = MethodChannel("de.aztube.aztube_app/youtube");
  Key key = UniqueKey();

  @override
  String get traceName => 'Created HomePage';

  @override
  String get traceTitle => 'Settings';

  Color getColor(Set<MaterialState> states) {
    const Set<MaterialState> interactiveStates = <MaterialState>{
      MaterialState.pressed,
      MaterialState.hovered,
      MaterialState.focused,
    };
    return Colors.indigo;
  }

  @override
  Widget build(BuildContext context) {
    Color contrastColor = Theme.of(context).primaryIconTheme.color;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Container(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
        child: ListView(children: [
          ListTile(
              title: const Text('Notifications'),
              trailing: Checkbox(
                checkColor: Colors.white,
                fillColor: MaterialStateProperty.resolveWith(getColor),
                value: widget.settings.notifications,
                onChanged: (value) {
                  widget.settings.notifications = value!;
                  FileManager().saveSettings(widget.settings);
                  setState(() {});
                },
              )),
          const Divider(),
          ListTile(
              title: const Text('Download in backround'),
              trailing: Checkbox(
                checkColor: Colors.white,
                fillColor: MaterialStateProperty.resolveWith(getColor),
                value: widget.settings.backgroundLoading,
                onChanged: (value) {
                  widget.settings.backgroundLoading = value!;
                  FileManager().saveSettings(widget.settings);
                  setState(() {});
                },
              )),
          const Divider(),
          ListTile(
              title: const Text('Anonymous tracking'),
              trailing: Checkbox(
                checkColor: Colors.white,
                fillColor: MaterialStateProperty.resolveWith(getColor),
                value: widget.settings.anonymousTracking,
                onChanged: (value) {
                  widget.settings.anonymousTracking = value!;
                  MatomoTracker.instance.setOptOut(optout: !widget.settings.anonymousTracking);
                  FileManager().saveSettings(widget.settings);
                  setState(() {});
                },
              )),
          const Divider(),
          Container(
            padding:
                const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
            child: SimpleButton(
              child: const Text('Unlink', style: const TextStyle(color: contrastColor)),
              color: (widget.settings.deviceHash.length >= 10)
                  ? Colors.red
                  : Colors.blueGrey,
              disabled: ! (widget.settings.deviceHash.length >= 10),
              onPressed: () {
                if (widget.settings.deviceHash.length >= 10) {
                  APIHelper.unregisterDevice(widget.settings.deviceHash);
                  widget.settings.deviceHash = '0';
                  FileManager().saveSettings(widget.settings);
                  Navigator.pop(context);
                }
              },
            ),
          ),
        ]),
      ),
    );
  }
}
