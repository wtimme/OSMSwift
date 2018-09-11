//
//  APIClientProtocol.swift
//  OSMSwift
//
//  Created by Wolfgang Timme on 9/12/18.
//

import Foundation

import SwiftOverpass

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
