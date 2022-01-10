class Settings {

  String deviceHash = '0';
  String fileLocation = 'Downloads/';
  bool backgroundLoading = false;

  Settings();

  Settings.fromJson(Map<String, dynamic> json)
      : deviceHash = json['device'],
        fileLocation = json['fileLocation'],
        backgroundLoading = json['background'];

  Map<String, dynamic> toJson() => {
    'device': deviceHash,
    'fileLocation': fileLocation,
    'background': backgroundLoading
  };

}