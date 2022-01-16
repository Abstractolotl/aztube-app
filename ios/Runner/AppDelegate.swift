//
//  AppDelegate.swift
//  Runner
//
//  Created by Lucas Pape on 15.01.22.
//

import UIKit
import Flutter
import YoutubeDL
import PythonSupport

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate, UIDocumentInteractionControllerDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        PythonSupport.initialize()
        
        _ = Downloader.shared
        
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
                    
                    Util.downloadVideo(videoId: videoId, downloadId: downloadId, quality: quality, progressUpdate: { download in
                        channel.invokeMethod("progress", arguments: download)
                    }) { uri in
                        if(uri != nil){
                            result(uri)
                        }else{
                            result(false)
                        }
                    }
                } else {
                    result(FlutterError.init(code: "bad args", message: nil, details: nil))
                }
                
                break
            case "getThumbnailUrl":
                if let args = call.arguments as? Dictionary<String, Any>,
                   let videoId = args["videoId"] as? String {
                    
                    result(Util.getThumbnailUrl(videoId:videoId))
                } else {
                    result(FlutterError.init(code: "bad args", message: nil, details: nil))
                }
                break
            case "getActiveDownloads":
                result(Util.getActiveDownloads())
                break
            case "openDownload":
                if let args = call.arguments as? Dictionary<String, Any>,
                   let uri = args["uri"] as? String {
                    Util.openDownload(uri: uri, delegate: self)
                    result(true)
                }  else {
                    result(FlutterError.init(code: "bad args", message: nil, details: nil))
                }
                break
            case "deleteDownload":
                if let args = call.arguments as? Dictionary<String, Any>,
                   let uri = args["uri"] as? String {
                    result(Util.deleteDownload(uri: uri))
                }  else {
                    result(FlutterError.init(code: "bad args", message: nil, details: nil))
                }
                break
            case "downloadExists":
                if let args = call.arguments as? Dictionary<String, Any>,
                   let uri = args["uri"] as? String {
                    result(Util.downloadExists(uri: uri))
                }  else {
                    result(FlutterError.init(code: "bad args", message: nil, details: nil))
                }
                break
            case "registerDownloadProgressUpdate":
                if let args = call.arguments as? Dictionary<String, Any>,
                   let downloadId = args["downloadId"] as? Int {
                    result(Util.registerProgressUpdate(downloadId: downloadId){ download in
                        channel.invokeMethod("progress", arguments: download)
                    })
                }  else {
                    result(FlutterError.init(code: "bad args", message: nil, details: nil))
                }
                break
            default:
                break
            }
        })
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self.window!.rootViewController!
    }
}
