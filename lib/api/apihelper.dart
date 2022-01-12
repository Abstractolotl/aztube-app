import 'dart:io';

import 'package:http/http.dart' as http;

class APIHelper{

  static const api_url = "http://de2.lucaspape.de:4020";

  static Future<http.Response> registerDevice(String code, String deviceName){
    var uri = Uri.parse(api_url + "/register");
    return http.post(uri, body: '{"code": "$code", "deviceName": "$deviceName"}', headers: {
      HttpHeaders.contentTypeHeader: "application/json"
    });
  }

  static Future<http.Response> fetchDownloads(String deviceToken){
    var uri = Uri.parse(api_url + "/poll/$deviceToken");
    return http.get(uri, headers: {
      HttpHeaders.contentTypeHeader: "application/json"
    });
  }

  static void unregisterDevice(String deviceToken){
    var uri = Uri.parse(api_url + "/unregister");
    http.post(uri, body: '{"deviceToken": "$deviceToken"}', headers: {
      HttpHeaders.contentTypeHeader: "application/json"
    });
  }

}