//
//  APIClient.swift
//  OSMSwift
//
//  Created by Wolfgang Timme on 6/24/18.
//

import Foundation

import SwiftOverpass

public enum APIClientError: Error {
    case notAuthenticated
}

enum Endpoint: String {
    case getPermissions = "/api/0.6/permissions"
}

public enum Result<Value> {
    case success(Value)
    case error(Error?)
}

public protocol APIClientProtocol {

    /// Flag whether the client is authenticated.
    var isAuthenticated: Bool { get }

    /// Removes the credentials, logging the client out.
    func logout()

    /// Authenticates the client by presenting a view controller with the OAuth flow.
    /// When successful, the client stores the credentials in the Keychain and is authenticated.
    ///
    /// - Parameters:
    ///   - presentingViewController: The view controller from which the OAuth flow should be presented.
    ///   - completion: Closure that is executed once the account was added or an error occurred.
    func addAccountUsingOAuth(from presentingViewController: UIViewController,
                              _ completion: @escaping (Error?) -> Void)
    
    /// Attempts to get details on the authenticated user.
    ///
    /// - Parameter completion: Closure that is executed once the user details were determined or an error occured.
    func authenticatedUser(_ completion: @escaping (User?, Error?) -> Void)

    /// Request the list with permissions from the server.
    ///
    /// - Parameter completion: Closure that is executed once the permissions were determined or an error occured.
    func permissions(_ completion: @escaping ([Permission], Error?) -> Void)

    /// Attempts to download the map data inside the given bounding box.
    ///
    /// - Parameters:
    ///   - boundingBox: The bounding box that confines the map data.
    ///   - completion: Closure that is executed once the map data was downloaded completely or an error occured.
    func mapData(inside boundingBox: BoundingBox, _ completion: @escaping ([OverpassElement], Error?) -> Void)
    
    /// Attempts to retrieve all open changesets for the user with the given ID.
    ///
    /// - Parameters:
    ///   - userId: The ID of the user to get all open changesets from.
    ///   - completion: Closure that is executed once the changesets were retrieved or an error occured.
    func openChangesets(userId: Int, _ completion: @escaping ([Changeset], Error?) -> Void)
    
    /// Attempts to create the given changeset.
    ///
    /// - Parameters:
    ///   - tags: The tags to assign to the changeset.
    ///   - completion: Closure that is executed once the changeset was created and assigned an ID or an error occurred.
    func createChangeset(tags: [Tag], _ completion: @escaping (_ changesetId: Int?, _ error: Error?) -> Void)
    
    /// Attempts to create a new Node in the Changeset with the given ID.
    ///
    /// - Parameters:
    ///   - node: The node to create.
    ///   - changesetId: The changeset the Node creation belongs to.
    ///   - completion: Closure that is executed once the Node was created and assigned an ID or an error occurred.
    func createNode(_ node: OverpassNode,
                    changesetId: Int,
                    _ completion: @escaping (Result<Int>) -> Void)

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

        if let credentials = keychainHandler.oauthCredentials {
            oauthHandler.setupClientCredentials(credentials)
        }
    }
    
    public convenience init(baseURL: URL, oauthConsumerKey: String, oauthConsumerSecret: String) {
        let keychainHandler = KeychainAccessKeychainHandler(apiBaseURL: baseURL)
        let oauthHandler = OAuthSwiftOAuthHandler(baseURL: baseURL,
                                                  consumerKey: oauthConsumerKey,
                                                  consumerSecret: oauthConsumerSecret)
        let httpRequestHandler = AlamofireHTTPRequestHandler()
        
        self.init(baseURL: baseURL,
                  keychainHandler: keychainHandler,
                  oauthHandler: oauthHandler,
                  httpRequestHandler: httpRequestHandler)
    }

    // MARK: APIClientProtocol

    public var isAuthenticated: Bool {
        return nil != keychainHandler.oauthCredentials
    }

    public func logout() {
        keychainHandler.setCredentials(nil)
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
    
    public func authenticatedUser(_ completion: @escaping (User?, Error?) -> Void) {
        let path = "/api/0.6/user/details"
        
        httpRequestHandler.request(baseURL, path: path) { (response) in
            guard let data = response.data, response.error == nil else {
                completion(nil, response.error)
                return
            }
            
            completion(User(data: data), nil)
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

            guard let responseData = response.data else {
                completion([], nil)
                return
            }

            completion(Permission.parseListOfPermissions(from: responseData),
                       nil)
        }
    }

    public func mapData(inside boundingBox: BoundingBox, _ completion: @escaping ([OverpassElement], Error?) -> Void) {
        let path = "/api/0.6/map?bbox=\(boundingBox.queryString)"

        httpRequestHandler.request(baseURL, path: path) { (response) in
            guard response.error == nil else {
                completion([], response.error)
                return
            }

            guard let responseData = response.data else {
                completion([], nil)
                return
            }

            completion([], nil)
        }
    }
    
    public func openChangesets(userId: Int, _ completion: @escaping ([Changeset], Error?) -> Void) {
        let path = "/api/0.6/changesets?open=true&user=\(userId)"
        
        httpRequestHandler.request(baseURL, path: path) { (response) in
            guard let data = response.data, response.error == nil else {
                completion([], response.error)
                return
            }
            
            completion(Changeset.changesets(from: data), nil)
        }
    }
    
    public func createChangeset(tags: [Tag], _ completion: @escaping (Int?, Error?) -> Void) {
        let path = "/api/0.6/changeset/create"
        
        let xmlString = xmlStringForCreatingAChangeset(with: tags)
        guard let data = xmlString.data(using: .utf8) else {
            assertionFailure("Failed to create data for creating the changeset")
            return
        }
        
        httpRequestHandler.request(baseURL, path: path, method: "PUT", data: data) { (response) in
            guard nil == response.error else {
                completion(nil, response.error)
                return
            }
            
            // When a changeset was successfully created, the server responds with the ID of the changeset.
            // Attempt to parse it.
            guard
                let responseData = response.data,
                let responseAsString = String(data: responseData, encoding: .utf8),
                let changesetId = Int(responseAsString)
            else {
                completion(nil, nil)
                return
            }
            
            completion(changesetId, nil)
        }
    }
    
    public func createNode(_ node: OverpassNode,
                           changesetId: Int,
                           _ completion: @escaping (Result<Int>) -> Void) {
        let path = "/api/0.6/node/create"
        
        let xmlString = xmlStringForAddingNode(node, changesetId: changesetId)
        guard let data = xmlString.data(using: .utf8) else {
            assertionFailure("Failed to create data for creating the changeset")
            return
        }
        
        httpRequestHandler.request(baseURL, path: path, method: "PUT", data: data) { (response) in
            guard nil == response.error else {
                completion(.error(response.error))
                return
            }
            
            // When an entity was successfully created, the server responds with the ID the entity was assigned.
            guard
                let responseData = response.data,
                let responseString = String(data: responseData, encoding: .utf8),
                let responseAsInteger = Int(responseString)
            else {
                completion(.error(nil))
                return
            }
            
            completion(Result.success(responseAsInteger))
        }
    }
    
    // MARK: Private methods
    
    func xmlStringForCreatingAChangeset(with tags: [Tag]) -> String {
        var xmlString = "<osm><changeset>"
        
        tags.forEach {
            xmlString += "<tag k=\"\($0.key)\" v=\"\($0.value)\"/>"
        }
        
        xmlString += "</changeset></osm>"
        
        return xmlString
    }
    
    func xmlStringForAddingNode(_ node: OverpassNode, changesetId: Int) -> String {
        var xmlString = "<osm><node changeset=\"\(changesetId)\" lat=\"\(node.latitude)\" lon=\"\(node.longitude)\">"
        
        node.tags.forEach {
            xmlString += "<tag k=\"\($0.key)\" v=\"\($0.value)\"/>"
        }
        
        xmlString += "</node></osm>"
        
        return xmlString
    }

}
