//
//  AppDelegate.swift
//  Runner
//
//  Created by Lucas Pape on 15.01.22.
//

import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        let channel = FlutterMethodChannel(name: "de.aztube.aztube_app/youtube",
                                           binaryMessenger: controller.binaryMessenger)
        channel.setMethodCallHandler({
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            switch(call.method){
            case "downloadVideo":
                if let args = call.arguments as? Dictionary<String, Any>,
                   let videoId = args["videoId"] as? String,
                   let quality = args["quality"] as? String,
                   let downloadId = args["downloadId"] as? Int {
                    
                    let uri = Downloader.downloadVideo(videoId: videoId, downloadId: downloadId, quality: quality) { download in
                        channel.invokeMethod("progress", arguments: download)
                    }
                    
                    if(uri != nil){
                        result(uri)
                    }else{
                        result(false)
                    }
                } else {
                    result(FlutterError.init(code: "bad args", message: nil, details: nil))
                }
                
                break;
            case "getThumbnailUrl":
                if let args = call.arguments as? Dictionary<String, Any>,
                   let videoId = args["videoId"] as? String {
                    
                    result(Downloader.getThumbnailUrl(videoId:videoId))
                } else {
                    result(FlutterError.init(code: "bad args", message: nil, details: nil))
                }
                break;
            case "getActiveDownloads":
                result(Downloader.getActiveDownloads())
                break;
            case "openDownload":
                if let args = call.arguments as? Dictionary<String, Any>,
                   let uri = args["uri"] as? String {
                    result(Downloader.openDownload(uri: uri))
                }  else {
                    result(FlutterError.init(code: "bad args", message: nil, details: nil))
                }
                break;
            case "deleteDownload":
                if let args = call.arguments as? Dictionary<String, Any>,
                   let uri = args["uri"] as? String {
                    result(Downloader.deleteDownload(uri: uri))
                }  else {
                    result(FlutterError.init(code: "bad args", message: nil, details: nil))
                }
                break;
            case "downloadExists":
                if let args = call.arguments as? Dictionary<String, Any>,
                   let uri = args["uri"] as? String {
                    result(Downloader.downloadExists(uri: uri))
                }  else {
                    result(FlutterError.init(code: "bad args", message: nil, details: nil))
                }
                break;
            case "registerDownloadProgressUpdate":
                if let args = call.arguments as? Dictionary<String, Any>,
                   let downloadId = args["downloadId"] as? Int {
                    result(Downloader.registerProgressUpdate(downloadId: downloadId){ download in
                        channel.invokeMethod("progress", arguments: download)
                    })
                }  else {
                    result(FlutterError.init(code: "bad args", message: nil, details: nil))
                }
                break;
            default:
                print("fuck you swift no this switch doesnt need to be exshaustive noone gives a fuck")
            }
        })
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
