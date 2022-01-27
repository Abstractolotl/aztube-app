//
//  Requests.swift
//  Runner
//
//  Created by Lucas Pape on 27.01.22.
//

import UIKit
private func loadData(fromURLString urlString: String,
                      completion: @escaping (Result<Data, Error>) -> Void) {
    
    let urlString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
    
    if let url = URL(string: urlString) {
        let urlSession = URLSession.shared
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let task = urlSession.dataTask(with: request){ (data, response, error) in
            if let error = error {
                completion(.failure(error))
            }
            
            if let data = data {
                completion(.success(data))
            }
        }
        
        task.resume()
    }else{
        completion(.failure(ParseError.urlParseError("Something went wrong decoding URL")))
    }
}

func startDownload(videoId: String, quality:String, onError: @escaping (() -> Void), callback: @escaping ((String) -> Void)){
    let requestUrl = "https://api.lucaspape.de/youtube/download?videoId=" + videoId + "&quality=" + quality
    
    loadData(fromURLString: requestUrl, completion: { (result) in
        switch result {
        case .success(let data):
            do {
                let jsonDecoder = JSONDecoder()
                
                struct Response: Decodable {
                    let downloadId: String
                }
                
                let decodedResponse = try jsonDecoder.decode(Response.self, from: data)
                
                DispatchQueue.main.async {
                    callback(decodedResponse.downloadId)
                }
                
            } catch {
                DispatchQueue.main.async {
                    onError()
                }
            }
        case .failure(_):
            DispatchQueue.main.async {
                onError()
            }
        }
    })
}


func getProgress(downloadId: String, onError: @escaping (() -> Void), callback: @escaping ((Int) -> Void), finalCallback : @escaping ((String, Int) -> Void)){
    let requestUrl = "https://api.lucaspape.de/youtube/progress?downloadId=" + downloadId
    
    loadData(fromURLString: requestUrl, completion: { (result) in
        switch result {
        case .success(let data):
            do {
                let jsonDecoder = JSONDecoder()
                
                struct Response: Decodable {
                    let finished: Bool
                    let progress: Double
                }
                
                struct ResponseWithResult: Decodable {
                    let finished: Bool
                    let progress: Double
                    let result: String
                    let duration: Int
                }
                
                let decodedResponse = try jsonDecoder.decode(Response.self, from: data)
                
                if(decodedResponse.finished){
                    let decodedWithResult = try jsonDecoder.decode(ResponseWithResult.self, from: data)
                    
                    finalCallback(decodedWithResult.result, decodedWithResult.duration)
                }else{
                    DispatchQueue.main.async {
                        callback(Int(decodedResponse.progress))
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    print(error)
                    onError()
                }
            }
        case .failure(_):
            DispatchQueue.main.async {
                onError()
            }
        }
    })
}
