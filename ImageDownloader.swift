//
//  ImageDownloader.swift
//  Test
//
//  Created by SOUVIK PATLA on 12/07/24.
//

import Foundation
import UIKit

typealias ImageClosure = (_ result: Result<UIImage>, _ url: String) -> Void

class ImageDownloadManager: NSObject {
    
    static let shared = ImageDownloadManager()
    
    private var operationQueue = OperationQueue()
    private var dictionaryBlocks = [UIImageView: (String, ImageClosure, ImageDownloadOperation)]()
    
    private override init() {
        operationQueue.maxConcurrentOperationCount = 100
    }
    
    func addOperation(url: String, imageView: UIImageView, completion: @escaping ImageClosure) {
        
        if let image = DataCache.shared.getImageFromCache(key: url)  {
            
            completion(.Success(image), url)
            if let tupple = self.dictionaryBlocks.removeValue(forKey: imageView){
                tupple.2.cancel()
            }
            
        } else {
            
            if !checkOperationExists(with: url,completion: completion) {
            
                if let tupple = self.dictionaryBlocks.removeValue(forKey: imageView){
                    tupple.2.cancel()
                }
                
                let newOperation = ImageDownloadOperation(url: url) { (image,downloadedImageURL) in
                
                    if let tupple = self.dictionaryBlocks[imageView] {
                    
                        if tupple.0 == downloadedImageURL {
                        
                            if let image = image {
                            
                                DataCache.shared.saveImageToCache(key: downloadedImageURL, image: image)
                                tupple.1(.Success(image), downloadedImageURL)
                                
                                if let tupple = self.dictionaryBlocks.removeValue(forKey: imageView){
                                    tupple.2.cancel()
                                }
                                
                            } else {
                                tupple.1(.Failure("Not fetched"), downloadedImageURL)
                            }
                            
                            _ = self.dictionaryBlocks.removeValue(forKey: imageView)
                        }
                    }
                }
                
                dictionaryBlocks[imageView] = (url, completion, newOperation)
                operationQueue.addOperation(newOperation)
            }
        }
    }
    
    func checkOperationExists(with url: String, completion: @escaping ImageClosure) -> Bool {
        
        if let arrayOperation = operationQueue.operations as? [ImageDownloadOperation] {
            let opeartions = arrayOperation.filter{$0.url == url}
            return opeartions.count > 0 ? true : false
        }
        
        return false
    }
}
typealias ImageCompletion = (_ image : UIImage?, _ url : String) -> Void

class ImageDownloadOperation: Operation {
    
    let url: String?
    var customCompletionBlock: ImageCompletion?
    
    init(url: String, completionBlock: @escaping ImageCompletion) {
        self.url = url
        self.customCompletionBlock = completionBlock
    }
    
    override func main() {
        
        if self.isCancelled { return }
        
        if let url = self.url {
        
            if self.isCancelled { return }
            
            ApiManager.shared.downloadImage(url) { (result) in
            
                DispatchQueue.main.async {
                    switch result {
                    case .Success(let image):
                        if self.isCancelled { return }
                        if let completion = self.customCompletionBlock{
                            completion(image, url)
                        }
                    default:
                        if self.isCancelled { return }
                        break
                    }
                }
            }
        }
    }
}
class DataCache: NSObject {

    static let shared = DataCache()
    
    private(set) var cache: NSCache<AnyObject, AnyObject> = NSCache()
    
    func getImageFromCache(key: String) -> UIImage? {
        if (self.cache.object(forKey: key as AnyObject) != nil) {
            return self.cache.object(forKey: key as AnyObject) as? UIImage
        } else {
            return nil
        }
    }
    
    func saveImageToCache(key: String, image: UIImage) {
        self.cache.setObject(image, forKey: key as AnyObject)
    }
    
}
