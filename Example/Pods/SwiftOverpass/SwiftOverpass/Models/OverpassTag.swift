//
//  OverpassTag.swift
//  SwiftOverpass
//
//  Created by Sho Kamei on 2017/12/03.
//  Copyright © 2017年 Sho Kamei. All rights reserved.
//

import Foundation

/// Represents a tag for the query.
public struct OverpassTag {
    // MARK: - Properties
    
    /// The key of the tag.
    public let key: String
    /// The value of the tag.
    public let value: String?
    /// `true` if the tag represents negation. `false` otherwise.
    public let isNegation: Bool
    /// `true` if the tag represents regex. `false` otherwise
    public let isRegex: Bool
    
    // MARK: - Initializers
    
    /**
     Creates a `OverpassTag`
     */
    public init(key: String, value: String?, isNegation: Bool = false, isRegex: Bool = false) {
        self.key = key
        self.value = value
        self.isNegation = isNegation
        self.isRegex = isRegex
    }
}
