//
//  Tag.swift
//  OSMSwift
//
//  Created by Wolfgang Timme on 9/9/18.
//

import Foundation

public struct Tag {
    public let key: String
    public let value: String
    
    public init(key: String, value: String) {
        self.key = key
        self.value = value
    }
}
