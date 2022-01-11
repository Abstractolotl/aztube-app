import 'dart:convert';
import 'dart:io';

import 'package:aztube/files/i_filemanager.dart';
import 'package:aztube/files/settingsmodel.dart';
import 'package:path_provider/path_provider.dart';

class FileManager extends IFileManager{

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/settings.json');
  }

  @override
  Future<Settings> getSettings() async{
    final file = await _localFile;
    if(file.existsSync()) {
      return Settings.fromJson(jsonDecode(file.readAsStringSync()));
    }
    return Settings();
  }

  @override
  void save(Settings settings) async {
    final file = await _localFile;
    file.writeAsStringSync(jsonEncode(settings.toJson()));
  }

}