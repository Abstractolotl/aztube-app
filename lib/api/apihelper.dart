import 'dart:io';

import 'package:http/http.dart' as http;

class APIHelper{

  static const API_URL = "http://de2.lucaspape.de:4020";

  static Future<http.Response> registerDevice(String code){
    var uri = Uri.parse(API_URL + "/register");
    return http.post(uri, body: '{"code": "$code"}', headers: {
      HttpHeaders.contentTypeHeader: "application/json"
    });
  }

  static void unregisterDevice(String deviceToken){
    var uri = Uri.parse(API_URL + "/unregister");
    http.post(uri, body: '{"deviceToken": "$deviceToken"}', headers: {
      HttpHeaders.contentTypeHeader: "application/json"
    });
  }

}