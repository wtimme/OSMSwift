//
//  HTTPRequestHandlerMock.swift
//  OSMSwift_Tests
//
//  Created by Wolfgang Timme on 6/26/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

@testable import OSMSwift

class HTTPRequestHandlerMock {
    /// The parameters with which `request(_:_:_:_:_:)` was called.
    var method: String?
    var baseURL: URL?
    var path: String?
    var parameters: [String: Any]?
    var data: Data?

    /// Use this variable to mock the response from the server.
    var dataResponse = DataResponse(data: nil, error: nil)
}

extension HTTPRequestHandlerMock: HTTPRequestHandling {
    
    func request(_ method: String,
                 _ baseURL: URL,
                 _ path: String,
                 _ parameters: [String : Any]?,
                 _ data: Data?,
                 _ completion: @escaping (DataResponse) -> Void) {
        self.method = method
        self.baseURL = baseURL
        self.path = path
        self.parameters = parameters
        self.data = data

        completion(dataResponse)
    }

}
