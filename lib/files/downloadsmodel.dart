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

  static DownloadCache fromJson(Map<String, dynamic> json){
      DownloadCache cache = DownloadCache();
      cache.queue = convertBack(json['queue']);
      cache.downloaded = convertBack(json['downloaded']);
      return cache;
  }

  Map<String, dynamic> toJson() => {
    'queue': convertTo(queue),
    'downloaded': convertTo(downloaded)
  };

  List<dynamic> convertTo(List<VideoData> list){
    List<dynamic> response = [];
    for (var element in list) {
      response.add(element.toJson());
    }
    return response;
  }

  static List<VideoData> convertBack(List<dynamic> list){
    List<VideoData> response = [];
    for (var element in list) {
      response.add(VideoData.fromJson(element));
    }
    return response;
  }

}