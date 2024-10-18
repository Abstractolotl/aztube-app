import 'package:firebase_analytics/firebase_analytics.dart';

enum QrType {
  success,
  invalidQr,
  serviceError,
}

enum DeviceName {
  success,
  unknown,
}

class AzTubeAnalytics {
  static void logQRScanned(QrType type, DeviceName deviceName) {
    FirebaseAnalytics.instance.logEvent(name: "qr_scanned", parameters: {
      "type": type,
      "device_name": deviceName,
    });
  }
}
