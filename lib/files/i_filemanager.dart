import 'package:aztube/files/settingsmodel.dart';

abstract class IFileManager {

    Future<Settings> getSettings();

    void save(Settings settings);

}