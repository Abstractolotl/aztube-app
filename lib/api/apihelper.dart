import 'package:http/http.dart' as http;

class APIHelper{

  static const API_URL = "https://aztube.lucaspape.de/api/v1";

  static Future<http.Response> registerDevice(String code){
    var uri = Uri.parse(API_URL + "/register");
    return http.post(uri, body: '{"code": "$code"}');
  }

}