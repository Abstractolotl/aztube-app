import 'dart:convert';
import 'dart:io';

import 'package:aztube/files/downloadsmodel.dart';
import 'package:aztube/files/i_filemanager.dart';
import 'package:aztube/files/settingsmodel.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class FileManager extends IFileManager{

  static const platform = MethodChannel("de.aztube.aztube_app/youtube");

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _settingsFile async {
    final path = await _localPath;
    return File('$path/settings.json');
  }

  Future<File> get _downloadsFile async {
    final path = await _localPath;
    return File('$path/downloads.json');
  }

  @override
  Future<Settings> getSettings() async{
    final file = await _settingsFile;
    if(file.existsSync()) {
      return Settings.fromJson(jsonDecode(file.readAsStringSync()));
    }
    return Settings();
  }

  @override
  void saveSettings(Settings settings) async {
    final file = await _settingsFile;
    file.writeAsStringSync(jsonEncode(settings.toJson()));
    platform.invokeMethod('settingsChanged');
  }


  @override
  Future<DownloadCache> getDownloads() async{
    final file = await _downloadsFile;
    if(file.existsSync()) {
      return DownloadCache.fromJson(jsonDecode(file.readAsStringSync()));
    }
    return DownloadCache();
  }

  @override
  void saveDownloads(DownloadCache downloads) async {
    final file = await _downloadsFile;
    file.writeAsStringSync(jsonEncode(downloads.toJson()));
    platform.invokeMethod('downloadsChanged');
  }
}