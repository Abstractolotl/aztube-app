//
//  Downloader.swift
//  Runner
//
//  Created by Lucas Pape on 16.01.22.
//

import Foundation
import YoutubeDL
import PythonKit
import AVKit
import AVFoundation
import ffmpegkit

struct Download {
    let done: Bool
    let progress: Int
    let downloadId: Int
    let videoId: String
    
    func toMap() -> [String: Any] {
        var map = [String: Any]()
        
        map["done"] = done
        map["progress"] = progress
        map["downloadId"] = downloadId
        map["videoId"] = videoId
        
        return map
    }
}

class ProgressUpdate {
    private let progressUpdate: ((Download) -> Void)
    private let didFinishDownloadingTo: ((URL) -> Void)
    private let downloadId: Int
    private let videoId: String
    
    init(downloadId:Int, videoId:String, progressUpdate: @escaping ((Download) -> Void), didFinishDownloadingTo: @escaping ((URL) -> Void)){
        self.downloadId = downloadId
        self.videoId = videoId
        self.progressUpdate = progressUpdate
        self.didFinishDownloadingTo = didFinishDownloadingTo
    }
}

class Util {
    private static var downloads = [Int: Download]()
    private static var progressUpdaters = [Int: [((Download) -> Void)]]()
    
    public static func downloadVideo(videoId: String, downloadId: Int, quality: String, progressUpdate: @escaping ((Download) -> Void), callback: @escaping ((String?) -> Void)) {
        
        downloadPythonModule { success in
            if(success){
                let formatAndInfo = getInfo(videoId: videoId)
                
                if(formatAndInfo?.0 != nil){
                    let formats = getFormats(formats: formatAndInfo!.0, quality: quality)
                    
                    if(formats != nil){
                        let formats = formats!
                        
                        let duration = formatAndInfo?.1?["duration"]
                        
                        downloadFormat(format: formats[0], downloadId: downloadId, videoId: videoId, progressStart: 0, progressFactor: formats.count > 1 ? 0.1 : 0.5, progressUpdate: progressUpdate) { audioTempUrl in
                            if(audioTempUrl != nil){
                                do {
                                    let audioFilename = String(downloadId) + "-temp.m4a"
                                    let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                                    let audioFilepath = documentDirectory.appendingPathComponent(audioFilename)
                                    
                                    let audioData = try Data(contentsOf: audioTempUrl!)
                                    try audioData.write(to: audioFilepath)
                                    
                                    if(formats.count > 1){
                                        downloadFormat(format: formats[1], downloadId: downloadId, videoId: videoId, progressStart: 10, progressFactor: 0.4, progressUpdate: progressUpdate) { videoTempUrl in
                                            do {
                                                if(videoTempUrl != nil){
                                                    let videoFilename = String(downloadId) + "-temp.mp4"
                                                    let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                                                    let videoFilepath = documentDirectory.appendingPathComponent(videoFilename)
                                                    
                                                    let videoData = try Data(contentsOf: videoTempUrl!)
                                                    try videoData.write(to: videoFilepath)
                                                    
                                                    combineVideoAndAudio(audioUrl: audioFilepath, videoURL: videoFilepath, videoId: videoId, downloadId: downloadId, progressUpdate: progressUpdate, callback: callback)
                                                }else{
                                                    print("Failed to download video")
                                                }
                                            } catch {
                                                print("Failed so save video")
                                            }
                                        }
                                    }else{
                                        saveAudio(url: audioFilepath, downloadId: downloadId, videoId: videoId, progressUpdate: progressUpdate, callback: callback)
                                    }
                                    
                                } catch {
                                    print("Failed to save audio")
                                }
                            }
                        }
                    }else{
                        print("could not find format")
                        callback(nil)
                    }
                }else{
                    print("could not find video")
                    callback(nil)
                }
            }else{
                print("Cannot download video")
                callback(nil)
            }
        }
    }
    
    private static func saveAudio(url: URL, downloadId: Int, videoId: String, progressUpdate: @escaping ((Download) -> Void), callback: @escaping ((String?) -> Void)){
        let filename = String(downloadId) + ".mp3"
        
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filepath = documentDirectory.appendingPathComponent(filename)
        
        let audioAsset = AVAsset(url: url)
        
        FFmpegKit.executeAsync("-y -i " + URLComponents(url: url, resolvingAgainstBaseURL: false)!.path + " " + URLComponents(url: filepath, resolvingAgainstBaseURL: false)!.path, withCompleteCallback: { ffmpegSession in
            do {
                try FileManager.default.removeItem(atPath: URLComponents(string: url.absoluteString)!.path)
            }catch{
                print("Could not delete temp file")
            }
            callback(filename)
        }, withLogCallback: { log in
        }, withStatisticsCallback: { statistics in
            if(statistics != nil){
                let total = Double(CMTimeGetSeconds(audioAsset.duration))
                let doneTime = (Double(statistics!.getTime()))
                
                var progress = (doneTime /  total) * 100
                
                if(progress.isNaN || progress.isInfinite){
                    progress = 0
                }
                
                print(progress)
                print(total)
                print(doneTime)
                
                progressUpdate(Download(done: false, progress: (50 + Int((progress * 0.5))), downloadId: downloadId, videoId: videoId))
            }
        })
    }
    
    private static func combineVideoAndAudio(audioUrl: URL, videoURL: URL, videoId:String, downloadId: Int, progressUpdate: @escaping ((Download) -> Void), callback: @escaping ((String?) -> Void)){
        let filename = String(downloadId) + ".mp4"
        
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filepath = documentDirectory.appendingPathComponent(filename)
        
        let audioAsset = AVAsset(url: audioUrl)
        
        FFmpegKit.executeAsync("-y -i " + URLComponents(url: videoURL, resolvingAgainstBaseURL: false)!.path + " -i " + URLComponents(url: audioUrl, resolvingAgainstBaseURL: false)!.path + " -c:v mpeg4 -c:a aac " + URLComponents(url: filepath, resolvingAgainstBaseURL: false)!.path,  withCompleteCallback: { ffmpegSession in
            do {
                try FileManager.default.removeItem(atPath: URLComponents(string: audioUrl.absoluteString)!.path)
                try FileManager.default.removeItem(atPath: URLComponents(string: videoURL.absoluteString)!.path)
            }catch{
                print("Could not delete temp files")
            }
            
            callback(filename)
        }, withLogCallback: { log in
        }, withStatisticsCallback: { statistics in
            if(statistics != nil){
                let total = Double(CMTimeGetSeconds(audioAsset.duration))
                let doneTime = (Double(statistics!.getTime()))
                
                var progress = (doneTime /  total) * 100
                
                if(progress.isNaN || progress.isInfinite){
                    progress = 0
                }
                
                print(progress)
                
                print(total)
                print(doneTime)
                
                progressUpdate(Download(done: false, progress: (50 + Int((progress * 0.5))), downloadId: downloadId, videoId: videoId))
            }
        })
    }
    
    private static func downloadFormat(format:Format, downloadId: Int, videoId: String, progressStart: Int, progressFactor: Double, progressUpdate: @escaping ((Download) -> Void), callback: @escaping ((URL?) -> Void)) {
        print("Downloading format...")
        
        let mockId = UUID().uuidString
        
        let delegateQueue = OperationQueue()
        
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = format.urlRequest!.allHTTPHeaderFields
        
        let urlSession = URLSession(configuration: config, delegate: nil, delegateQueue: delegateQueue)
        
        let task = urlSession.downloadTask(with: (format.urlRequest?.url!)!) { localURL, urlResponse, error in
            if(error != nil){
                mockProgress[mockId] = 100
                callback(nil)
            }else{
                mockProgress[mockId] = 100
                callback(localURL)
            }
        }
        
        task.resume()
        
        runMockProgress(id: mockId, downloadId: downloadId, videoId: videoId, progressStart: progressStart, progressFactor: progressFactor, progressUpdate: progressUpdate)
    }
    
    private static var mockProgress = [String: Int]()
    
    private static func runMockProgress(id: String, downloadId: Int, videoId: String, progressStart: Int, progressFactor: Double, progressUpdate: @escaping ((Download) -> Void)){
        if(mockProgress[id] == nil){
            mockProgress[id] = 1
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if(mockProgress[id]! < 100){
                mockProgress[id] = mockProgress[id]! + 1
                
                progressUpdate(Download(done: false, progress: (progressStart + Int((Double(mockProgress[id]!) * progressFactor))), downloadId: downloadId, videoId: videoId))
                
                runMockProgress(id:id, downloadId: downloadId, videoId: videoId, progressStart: progressStart, progressFactor: progressFactor, progressUpdate: progressUpdate)
            }
        }
    }
    
    private static func getInfo(videoId: String) -> ([Format], Info?)? {
        do {
            let youtubeDL = try YoutubeDL(options: ["nocheckcertificate": true, "format": "all"])
            return try youtubeDL.extractInfo(url: URL(string: "https://www.youtube.com/watch?v=" + videoId)!)
        } catch {
            return nil
        }
    }
    
    private static func getFormats(formats: [Format], quality: String) -> [Format]? {
        var formatList:[Format]? = [Format]()
        
        var audioFormat:Format? = nil
        var videoFormat:Format? = nil
        
        for format in formats {
            if(format.isAudioOnly){
                if(audioFormat != nil){
                    if(((format.filesize != nil) ? format.filesize! : 0) > ((audioFormat!.filesize != nil) ? audioFormat!.filesize! : 0)){
                        audioFormat = format
                    }
                }else{
                    audioFormat = format
                }
            }else if(format.height != nil && String(format.height!) + "p" == quality){
                if(videoFormat != nil){
                    if(((format.filesize != nil) ? format.filesize! : 0) > ((videoFormat!.filesize != nil) ? videoFormat!.filesize! : 0)){
                        videoFormat = format
                    }
                }else{
                    videoFormat = format
                }
            }
        }
        
        if(quality == "audio"){
            formatList?.append(audioFormat!)
        }else if(videoFormat != nil && !videoFormat!.isVideoOnly){
            formatList?.append(videoFormat!)
        }else if(videoFormat != nil && audioFormat != nil && videoFormat!.isVideoOnly){
            formatList?.append(audioFormat!)
            formatList?.append(videoFormat!)
        }else{
            formatList = nil
            
            print("Could not find audio or video format")
        }
        
        return formatList
    }
    
    private static func downloadPythonModule(callback: @escaping ((Bool) -> Void)){
        if(YoutubeDL.shouldDownloadPythonModule){
            print("Downloading python module")
            
            YoutubeDL.downloadPythonModule { error in
                if(error != nil){
                    print("Error downloading python module")
                    callback(false)
                }else{
                    print("Downloaded python mpdule")
                    callback(true)
                }
            }
        }else{
            callback(true)
        }
    }
    
    public static func getThumbnailUrl(videoId: String) -> String {
        return "https://img.youtube.com/vi/" + videoId + "/default.jpg"
    }
    
    public static func getActiveDownloads() -> [Download] {
        var activeDownloads = [Download]()
        
        for downloadId in downloads.keys {
            let download = downloads[downloadId]!
            
            if(download.done){
                activeDownloads.append(download)
            }
        }
        
        return activeDownloads
    }
    
    public static func deleteDownload(uri: String) -> Bool {
        do{
            let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let filename = documentDirectory.appendingPathComponent(uri)
            try FileManager.default.removeItem(atPath: URLComponents(string: filename.absoluteString)!.path)
            return true
        } catch {
            return false
        }
    }
    
    public static func openDownload(uri: String, delegate: UIDocumentInteractionControllerDelegate) {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filename = documentDirectory.appendingPathComponent(uri)
        
        let interaction = UIDocumentInteractionController(url: filename)
        interaction.delegate = delegate
        interaction.presentPreview(animated: true)
    }
    
    public static func downloadExists(uri: String) -> Bool {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filename = documentDirectory.appendingPathComponent(uri)
        
        return FileManager.default.fileExists(atPath: URLComponents(string: filename.absoluteString)!.path)
    }
    
    public static func registerProgressUpdate(downloadId: Int, progressUpdate: @escaping ((Download) -> Void)) {
        var progressUpdaterList = progressUpdaters[downloadId]
        
        if(progressUpdaterList == nil){
            progressUpdaterList = [((Download) -> Void)]()
        }
        
        progressUpdaterList!.append(progressUpdate)
        progressUpdaters[downloadId] = progressUpdaterList
    }
}
