//
//  User.swift
//  OSMSwift
//
//  Created by Wolfgang Timme on 9/9/18.
//

import Foundation

public struct User {
    public let id: Int
    public let displayName: String
    
    public init(id: Int, displayName: String) {
        self.id = id
        self.displayName = displayName
    }
}
