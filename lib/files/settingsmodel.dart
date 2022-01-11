class Settings {

  String deviceHash = '0';
  String fileLocation = 'Downloads/';
  bool backgroundLoading = false;
  bool notifications = false;

  Settings();

  Settings.fromJson(Map<String, dynamic> json)
      : deviceHash = json['device'],
        fileLocation = json['fileLocation'],
        backgroundLoading = json['background'] ?? false,
        notifications = json['notifications'] ?? false;

  Map<String, dynamic> toJson() => {
    'device': deviceHash,
    'fileLocation': fileLocation,
    'background': backgroundLoading,
    'notifications': notifications,
  };

}