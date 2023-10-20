class DeviceLinkInfo {
  final String deviceToken;
  final String deviceName;
  final DateTime registerDate;

  DeviceLinkInfo(this.deviceToken, this.deviceName, this.registerDate);

  factory DeviceLinkInfo.fromJson(Map<String, dynamic> json) {
    return DeviceLinkInfo(
      json['deviceToken'] as String,
      json['deviceName'] as String,
      DateTime.parse(json['registerDate'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceToken': deviceToken,
      'deviceName': deviceName,
      'registerDate': registerDate.toIso8601String(),
    };
  }
}
