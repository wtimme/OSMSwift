//
//  AlamofireHTTPRequestHandler.swift
//  OSMSwift
//
//  Created by Wolfgang Timme on 6/26/18.
//

import Foundation

import Alamofire

public class AlamofireHTTPRequestHandler: NSObject, HTTPRequestHandling {
    
    // MARK: HTTPRequestHandling
    
    public func request(_ baseURL: URL,
                 _ path: String,
                 _ parameters: [String : Any]?,
                 _ completion: @escaping (DataResponse) -> Void) {
        Alamofire.request(baseURL).response { response in
            completion(DataResponse(data: response.data,
                                    error: response.error))
        }
    }
    
}
