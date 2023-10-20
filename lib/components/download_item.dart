import 'package:aztube/aztube.dart';
import 'package:aztube/data/download_info.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DownloadItem extends StatelessWidget {
  final DownloadInfo info;
  final Function() onOpen;

  const DownloadItem({
    super.key,
    required this.info,
    required this.onOpen,
  });

  void startDownload(BuildContext context) {
    AzTubeApp app = Provider.of(context, listen: false);
    app.startDownload(info);
  }

  @override
  Widget build(BuildContext context) {
    TextTheme theme = Theme.of(context).textTheme;
    return InkWell(
      onLongPress: onOpen,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.black12)),
        ),
        child: Row(
          children: [
            lead(),
            const SizedBox(width: 10),
            Flexible(
              fit: FlexFit.tight,
              child: content(theme),
            ),
            trail(context),
          ],
        ),
      ),
    );
  }

  Widget lead() {
    return SizedBox(
      width: 75,
      child: CachedNetworkImage(
          imageUrl: 'https://img.youtube.com/vi/${info.video.videoId}/default.jpg',
          errorWidget: (context, url, error) {
            return const Icon(Icons.image_not_supported);
          },
          progressIndicatorBuilder: (context, url, progress) {
            return Center(child: CircularProgressIndicator(value: progress.progress));
          }),
    );
  }

  Widget content(TextTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(info.video.title, style: theme.titleMedium),
        const SizedBox(height: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              info.video.author,
              style: theme.labelMedium,
            ),
            Text(info.video.quality.text, style: theme.labelMedium),
          ],
        )
      ],
    );
  }

  Widget trail(BuildContext context) {
    if (info.isDownloaded()) {
      return const Icon(Icons.download_done);
    }

    if (info.isDownloading()) {
      return CircularProgressIndicator(value: info.progress / 100.0);
    }

    if (info.isError()) {
      return const Icon(
        Icons.error,
        color: Colors.red,
      );
    }

    return IconButton(
      onPressed: () => startDownload(context),
      icon: const Icon(Icons.download),
    );
  }
}
