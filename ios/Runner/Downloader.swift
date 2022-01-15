//
//  Downloader.swift
//  Runner
//
//  Created by Lucas Pape on 16.01.22.
//

import Foundation

struct Download {
    let done: Bool
    let progress: Int
    let downloadId: Int
    let videoId: String
}

class Downloader {
    private static var downloads = [Int: Download]()
    private static var progressUpdaters = [Int: [((Download) -> Void)]]()
    
    public static func downloadVideo(videoId: String, downloadId: Int, quality: String, progressUpdate: ((Download) -> Void)) -> String? {
        return ""
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
        return false
    }
    
    public static func openDownload(uri: String) {
        
    }
    
    public static func downloadExists(uri: String) -> Bool {
        return false
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
