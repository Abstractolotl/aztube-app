import 'package:aztube/data/device_link_info.dart';
import 'package:flutter/material.dart';

class DeviceLinkItem extends StatelessWidget {
  final DeviceLinkInfo info;

  const DeviceLinkItem({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.smartphone),
      title: Text(info.deviceName),
      trailing: IconButton(
        icon: const Icon(Icons.delete),
        color: Colors.red,
        onPressed: () {},
      ),
    );
  }
}
