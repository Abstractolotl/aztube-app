import 'package:aztube/files/downloadsmodel.dart';
import 'package:aztube/files/settingsmodel.dart';

abstract class IFileManager {

    Future<Settings> getSettings();

    void saveSettings(Settings settings);

    Future<DownloadCache> getDownloads();

    void saveDownloads(DownloadCache downloads);

}