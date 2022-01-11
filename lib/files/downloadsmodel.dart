import 'package:aztube/api/videodata.dart';

class DownloadCache{

  List<VideoData> queue = [];
  List<VideoData> downloaded = [];

  DownloadCache();

  List<VideoData> getAll(){
    List<VideoData> all = [];

    all.addAll(queue);
    all.addAll(downloaded);

    return all;
  }

  DownloadCache.fromJson(Map<String, dynamic> json)
      : queue = json['queue'],
        downloaded = json['downloaded'];

  Map<String, dynamic> toJson() => {
    'queue': queue,
    'downloaded': downloaded
  };

}