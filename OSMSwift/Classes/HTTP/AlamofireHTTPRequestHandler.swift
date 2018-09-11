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
    
    public func request(_ method: String,
                        _ baseURL: URL,
                        _ path: String,
                        _ parameters: [String : Any]?,
                        _ data: Data?,
                        _ completion: @escaping (DataResponse) -> Void) {

        guard let resourceURL = URL(string: path, relativeTo: baseURL) else {
            assertionFailure("Unable to construct the resource URL.")
            return
        }
        
        guard let httpMethod = HTTPMethod(rawValue: method) else {
            assertionFailure("Unrecognized HTTP method '\(method)'")
            return
        }

        switch httpMethod {
        case .put:
            put(resourceURL, data: data, completion)
        default:
            get(resourceURL, completion)
        }
    }
    
    private func get(_ url: URL, _ completion: @escaping (DataResponse) -> Void) {
        Alamofire.request(url).response { response in
            completion(DataResponse(data: response.data,
                                    error: response.error))
        }
    }
    
    private func put(_ url: URL, data: Data?, _ completion: @escaping (DataResponse) -> Void) {
        var xmlRequest = URLRequest(url: url)
        xmlRequest.httpMethod = "PUT"
        xmlRequest.httpBody = data
        xmlRequest.addValue("text/xml", forHTTPHeaderField: "Content-Type")
        
        Alamofire.request(xmlRequest)
            .responseData { (response) in
                completion(DataResponse(data: response.data,
                                        error: response.error))
        }
    }

}
