//
//  APIClient.swift
//  OSMSwift
//
//  Created by Wolfgang Timme on 6/24/18.
//

import Foundation

public enum APIClientError: Error {
    case notAuthenticated
}

enum Endpoint: String {
    case getPermissions = "/api/0.6/permissions"
}

public enum Permission: String {
    public typealias RawValue = String
    
    case allow_read_prefs // Read user preferences
    case allow_write_prefs // Modify user preferences
    case allow_write_diary // Create diary entries, comments and make friends
    case allow_write_api // Modify the map
    case allow_read_gpx // Read private GPS traces
    case allow_write_gpx // Upload GPS traces
    case allow_write_notes // Modify notes
}

public protocol APIClientProtocol {
    
    var isAuthenticated: Bool { get }
    
    func addAccountUsingOAuth(from presentingViewController: UIViewController,
                              _ completion: @escaping (Error?) -> Void)
    
    /// Request the list with permissions from the server.
    ///
    /// - Parameter completion: Closure that is executed once the permissions were determined or an error occured.
    func permissions(_ completion: @escaping ([Permission], Error?) -> Void)
    
}

public class APIClient: APIClientProtocol {
    
    public struct OAuthConfiguration {
        /// Setup a URL scheme in your app's Info.plist.
        let callbackURLScheme: String
        
        let consumerKey: String
        let consumerSecret: String
        
        /// After OAuth completed, this will redirect users back to the app using this URL.
        var callbackURLString: String {
            return "\(callbackURLScheme)://oauth-callback/osm"
        }
    }
    
    // MARK: Private
    
    private let baseURL: URL
    private let keychainHandler: KeychainHandling
    private let oauthHandler: OAuthHandling
    private let httpRequestHandler: HTTPRequestHandling
    
    // MARK: Public
    
    public init(baseURL: URL,
                keychainHandler: KeychainHandling,
                oauthHandler: OAuthHandling,
                httpRequestHandler: HTTPRequestHandling) {
        self.baseURL = baseURL
        self.keychainHandler = keychainHandler
        self.oauthHandler = oauthHandler
        self.httpRequestHandler = httpRequestHandler
    }
    
    // MARK: APIClientProtocol
    
    public var isAuthenticated: Bool {
        return nil != keychainHandler.oauthCredentials
    }
    
    public func addAccountUsingOAuth(from presentingViewController: UIViewController,
                                     _ completion: @escaping (Error?) -> Void) {
        oauthHandler.startOAuthFlow(from: presentingViewController) { [weak self] (credentials, error) in
            guard error == nil else {
                completion(error)
                return
            }
            
            guard let credentials = credentials else {
                assertionFailure("There should be either credentials or an error.")
                return
            }
            
            self?.keychainHandler.setCredentials(credentials) 
            
            completion(nil)
        }
    }
    
    public func permissions(_ completion: @escaping ([Permission], Error?) -> Void) {
        guard isAuthenticated else {
            completion([], APIClientError.notAuthenticated)
            return
        }
        
        httpRequestHandler.request(baseURL, path: "/api/0.6/permissions") { (response) in
            guard response.error == nil else {
                completion([], response.error)
                return
            }
        }
    }
    
}
