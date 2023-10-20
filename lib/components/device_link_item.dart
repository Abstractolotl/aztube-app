import 'package:aztube/data/device_link_info.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DeviceLinkItem extends StatelessWidget {
  final DeviceLinkInfo info;
  final Function() onDelete;
  final Function() onEdit;

  const DeviceLinkItem({super.key, required this.info, required this.onDelete, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.computer),
      title: Text(info.deviceName),
      subtitle: Text(DateFormat("yyyy-MM-dd H:m").format(info.registerDate)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            color: Colors.red,
            onPressed: onDelete,
          )
        ],
      ),
    );
  }
}
