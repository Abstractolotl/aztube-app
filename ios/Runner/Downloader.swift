//
//  Downloader.swift
//  Runner
//
//  Created by Lucas Pape on 16.01.22.
//

import AVKit
import AVFoundation

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

struct DownloadWithCallback {
    let download: Download
    let quality: String
    let callback: ((String?) -> Void)
}

class Downloader: NSObject, URLSessionDownloadDelegate {
    private var downloads = [Int: Download]()
    private var progressUpdaters = [Int: [((Download) -> Void)]]()
    
    private var downloadTaskMap = [URLSessionDownloadTask: DownloadWithCallback]()
    
    public func downloadVideo(videoId: String, downloadId: Int, quality: String, progressUpdate: @escaping ((Download) -> Void), callback: @escaping ((String?) -> Void)) {
        
        self.registerProgressUpdate(downloadId: downloadId, progressUpdate: progressUpdate)
        
        startDownload(videoId: videoId, quality: quality) {
            callback(nil)
        } callback: { downloadUUID in
            self.startDownloadWatcher(downloadUUID: downloadUUID, downloadId: downloadId, videoId: videoId) { result, duration in
                if(result != nil && duration != nil){
                    self.downloadFile(downloadResult: result!, downloadId: downloadId, videoId: videoId, quality: quality) { filepath in
                        if(filepath != nil){
                            callback(filepath)
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
    
    private func startDownloadWatcher(downloadUUID: String, downloadId:Int, videoId: String, downloadFinished: @escaping ((String?, Int?) -> Void)){
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            getProgress(downloadId: downloadUUID) {
                downloadFinished(nil, nil)
            } callback: { progress in
                self.runProgressUpdaters(download: Download(done: false, progress: Int((Double(progress) * (0.5))), downloadId: downloadId, videoId: videoId))
                
                self.startDownloadWatcher(downloadUUID: downloadUUID, downloadId: downloadId, videoId: videoId, downloadFinished: downloadFinished)
            } finalCallback: { result, duration in
                self.runProgressUpdaters(download: Download(done: false, progress: Int((Double(100) * (0.5))), downloadId: downloadId, videoId: videoId))
                
                downloadFinished(result, duration)
            }
        }
    }
    
    private func downloadFile(downloadResult: String, downloadId: Int, videoId: String, quality:String, downloadFinished: @escaping ((String?) -> Void)){
        print("https://api.lucaspape.de/youtube/static/" + downloadResult)
        
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        
        let downloadTask = session.downloadTask(with: URL(string: "https://api.lucaspape.de/youtube/static/" + downloadResult)!)
        
        downloadTask.resume()
        
        downloadTaskMap[downloadTask] = DownloadWithCallback(download: Download(done: false, progress: 0, downloadId: downloadId, videoId: videoId), quality: quality, callback: downloadFinished)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        let progress:Double = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite) * 100.0
        
        let downloadWithCallback = downloadTaskMap[downloadTask]
        
        let download = Download(done: false, progress: 50 + Int((progress * 0.5)), downloadId: downloadWithCallback!.download.downloadId, videoId: downloadWithCallback!.download.videoId)
        
        runProgressUpdaters(download: download)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let download = downloadTaskMap[downloadTask]
        
        var filename = String(download!.download.downloadId)
        
        if(download!.quality == "audio"){
            filename += ".m4a"
        }else{
            filename += ".mp4"
        }
        
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filepath = documentDirectory.appendingPathComponent(filename)
        
        do {
            let data = try Data(contentsOf: location)
            try data.write(to: filepath)
            
            download!.callback(filename)
        } catch {
            print("Failed to save file")
            
            download!.callback(nil)
        }
    }
    
    
    public func getThumbnailUrl(videoId: String) -> String {
        return "https://img.youtube.com/vi/" + videoId + "/default.jpg"
    }
    
    public func getActiveDownloads() -> [Download] {
        var activeDownloads = [Download]()
        
        for downloadId in downloads.keys {
            let download = downloads[downloadId]!
            
            if(download.done){
                activeDownloads.append(download)
            }
        }
        
        return activeDownloads
    }
    
    public func deleteDownload(uri: String) -> Bool {
        do{
            let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let filename = documentDirectory.appendingPathComponent(uri)
            try FileManager.default.removeItem(atPath: URLComponents(string: filename.absoluteString)!.path)
            return true
        } catch {
            return false
        }
    }
    
    public func openDownload(uri: String, delegate: UIDocumentInteractionControllerDelegate) {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filename = documentDirectory.appendingPathComponent(uri)
        
        let interaction = UIDocumentInteractionController(url: filename)
        interaction.delegate = delegate
        interaction.presentPreview(animated: true)
    }
    
    public func downloadExists(uri: String) -> Bool {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filename = documentDirectory.appendingPathComponent(uri)
        
        return FileManager.default.fileExists(atPath: URLComponents(string: filename.absoluteString)!.path)
    }
    
    public func registerProgressUpdate(downloadId: Int, progressUpdate: @escaping ((Download) -> Void)) {
        var progressUpdaterList = progressUpdaters[downloadId]
        
        if(progressUpdaterList == nil){
            progressUpdaterList = [((Download) -> Void)]()
        }
        
        progressUpdaterList!.append(progressUpdate)
        progressUpdaters[downloadId] = progressUpdaterList
    }
    
    private func runProgressUpdaters(download: Download){
        let progressUpdaterList = progressUpdaters[download.downloadId]
        
        if(progressUpdaterList != nil){
            for progressUpdater in progressUpdaterList! {
                progressUpdater(download)
            }
        }
    }
}
