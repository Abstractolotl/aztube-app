// ignore_for_file: constant_identifier_names

import 'dart:convert';

import 'package:aztube/api/api_exceptions.dart';
import 'package:aztube/data/download_info.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const API = "http://noucake.ddns.net:9000";

Future<String> registerDeviceLink(String code, String deviceName) async {
  var payload = '{"code": "$code", "deviceName": "$deviceName"}';
  http.Response resp = await http.post(
    Uri.parse("$API/register"),
    body: payload,
    headers: {"CONTENT-TYPE": "application/json"},
  );
  debugPrint(resp.body);
  var jsonResp = jsonDecode(resp.body);
  if (resp.statusCode != 200 || jsonResp["success"] != true || jsonResp["deviceToken"] == null) {
    throw ApiException("Could not register device: ${jsonResp["error"]}", resp.statusCode);
  }
  return jsonResp["deviceToken"];
}

Future<List<DownloadInfo>> pollDownloads(String deviceToken) async {
  http.Response resp = await http.post(
    Uri.parse("$API/poll/$deviceToken"),
  );

  debugPrint(resp.body);
  var jsonResp = jsonDecode(resp.body);
  if (resp.statusCode != 200 || jsonResp["success"] != true) {
    throw ApiException("Could not poll for Downloads: ${jsonResp["error"]}", resp.statusCode);
  }

  List<DownloadInfo> aa = jsonResp;
  return aa;
}
