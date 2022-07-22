class Settings {

  String deviceHash = '0';
  String fileLocation = '';
  bool notifications = true;
  bool backgroundLoading = false;
  bool anounymousTracking = true;

  Settings();

  Settings.fromJson(Map<String, dynamic> json)
      : deviceHash = json['device'],
        fileLocation = json['fileLocation'],
        backgroundLoading = json['background'] ?? false,
        notifications = json['notifications'] ?? true,
        anounymousTracking = json['tracking'] ?? true;

  Map<String, dynamic> toJson() => {
    'device': deviceHash,
    'fileLocation': fileLocation,
    'background': backgroundLoading,
    'notifications': notifications,
    'anounymousTracking': anounymousTracking
  };

}