import 'package:aztube_app/files/settingsmodel.dart';

abstract class IFileManager {

    Future<Settings> getSettings();

    void save(Settings settings);

}