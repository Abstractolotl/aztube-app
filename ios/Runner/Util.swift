//
//  Downloader.swift
//  Runner
//
//  Created by Lucas Pape on 16.01.22.
//

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



class Downloader {
    private static var downloads = [Int: Download]()
    private static var progressUpdaters = [Int: [((Download) -> Void)]]()
    
    public static func downloadVideo(videoId: String, downloadId: Int, quality: String, progressUpdate: @escaping ((Download) -> Void), callback: @escaping ((String?) -> Void)) {
        
        registerProgressUpdate(downloadId: downloadId, progressUpdate: progressUpdate)
        
        startDownload(videoId: videoId, quality: quality.replacingOccurrences(of: "p", with: "")) {
            callback(nil)
        } callback: { downloadUUID in
            startDownloadWatcher(downloadUUID: downloadUUID, downloadId: downloadId, videoId: videoId) { result, duration in
                if(result != nil && duration != nil){
                    downloadFile(downloadResult: result!, downloadId: downloadId, videoId: videoId) { filepath in
                        if(filepath != nil){
                            convert(url: filepath!, duration: duration!, downloadId: downloadId, quality: quality, videoId: videoId) { convertedPath in
                                callback(convertedPath)
                            }
                        }else{
                            callback(nil)
                        }
                    }
                }else{
                    print("api failed to download")
                    
                    callback(nil)
                }
            }
        }
    }
    
    private static func startDownloadWatcher(downloadUUID: String, downloadId:Int, videoId: String, downloadFinished: @escaping ((String?, Int?) -> Void)){
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            getProgress(downloadId: downloadUUID) {
                downloadFinished(nil, nil)
            } callback: { progress in
                runProgressUpdaters(download: Download(done: false, progress: Int((Double(progress) * (0.2))), downloadId: downloadId, videoId: videoId))
                
                startDownloadWatcher(downloadUUID: downloadUUID, downloadId: downloadId, videoId: videoId, downloadFinished: downloadFinished)
            } finalCallback: { result, duration in
                runProgressUpdaters(download: Download(done: false, progress: Int((Double(100) * (0.2))), downloadId: downloadId, videoId: videoId))
                
                downloadFinished(result, duration)
            }
        }
    }
    
    private static func downloadFile(downloadResult: String, downloadId: Int, videoId: String, downloadFinished: @escaping ((URL?) -> Void)){
        print("https://api.lucaspape.de/youtube/static/" + downloadResult)
        
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration)
        
        var observation: NSKeyValueObservation? = nil
        
        let downloadTask = session.downloadTask(with: URL(string: "https://api.lucaspape.de/youtube/static/" + downloadResult)!) { localURL, urlResponse, error in
            observation?.invalidate()
            
            let filename = String(downloadId) + "_orig"
            let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let filepath = documentDirectory.appendingPathComponent(filename)
            
            do {
                if(localURL != nil){
                    let data = try Data(contentsOf: localURL!)
                    try data.write(to: filepath)
                    
                    downloadFinished(filepath)
                }else{
                    print("Could not find download")
                    
                    downloadFinished(nil)
                }
            } catch {
                print("Failed to save file")
                
                downloadFinished(nil)
            }
        }
        
        observation = downloadTask.progress.observe(\.fractionCompleted) { progress, _ in
           runProgressUpdaters(download: Download(done: false, progress: (20 + Int((Double(progress.fractionCompleted) * 0.3))), downloadId: downloadId, videoId: videoId))
        }
        
        downloadTask.resume()
    }
    
    private static func convert(url: URL, duration: Int, downloadId: Int, quality: String, videoId: String, convertFinished: @escaping ((String?) -> Void)){
        var filename = String(downloadId)
        
        var ffmpegCommand = ""
        
        if(quality == "audio"){
            filename += ".m4a"
            
            let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let filepath = documentDirectory.appendingPathComponent(filename)
            
            ffmpegCommand = "-y -i " + URLComponents(url: url, resolvingAgainstBaseURL: false)!.path + " -c:a aac " + URLComponents(url: filepath, resolvingAgainstBaseURL: false)!.path
        }else{
            filename += ".mp4"
            
            let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let filepath = documentDirectory.appendingPathComponent(filename)
            
            ffmpegCommand = "-y -i " + URLComponents(url: url, resolvingAgainstBaseURL: false)!.path + " -c:v mpeg4 -c:a aac " + URLComponents(url: filepath, resolvingAgainstBaseURL: false)!.path
        }
        
        FFmpegKit.executeAsync(ffmpegCommand, withCompleteCallback: { ffmpegSession in
            do {
                try FileManager.default.removeItem(atPath: URLComponents(string: url.absoluteString)!.path)
            }catch{
                print("Could not delete temp files")
            }
            
            convertFinished(filename)
        }, withLogCallback: { log in
            
        }, withStatisticsCallback: { statistics in
            if(statistics != nil){
                let total = Double(duration*1000)
                let doneTime = (Double(statistics!.getTime()))
               
                var progress = (doneTime / total) * 100
                
                if(progress.isNaN || progress.isInfinite){
                    progress = 0
                }
                
                runProgressUpdaters(download: Download(done: false, progress: (50 + Int((progress * 0.5))), downloadId: downloadId, videoId: videoId))
            }
        })
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
    
    private static func runProgressUpdaters(download: Download){
        let progressUpdaterList = progressUpdaters[download.downloadId]
        
        if(progressUpdaterList != nil){
            for progressUpdater in progressUpdaterList! {
                progressUpdater(download)
            }
        }
    }
}
