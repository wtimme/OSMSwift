//
//  Changeset.swift
//  OSMSwift
//
//  Created by Wolfgang Timme on 9/7/18.
//  Copyright © 2018 Wolfgang Timme. All rights reserved.
//

import Foundation

public struct Changeset {
    public struct Comment {
        public let userId: Int
        public let username: String
        public let dateAsString: String
        public let content: String
        
        public init(userId: Int, username: String, dateAsString: String, content: String) {
            self.userId = userId
            self.username = username
            self.dateAsString = dateAsString
            self.content = content
        }
    }
    
    public let id: Int
    public let userId: Int
    public let username: String
    public let boundingBox: BoundingBox
    public let tags: [Tag]
    public let createdDateTimestamp: String
    public let numberOfComments: Int
    public let comments: [Comment]
    public let closedDateTimestamp: String?
    
    public init(id: Int,
                userId: Int,
                username: String,
                boundingBox: BoundingBox,
                tags: [Tag],
                createdDateTimestamp: String,
                numberOfComments: Int,
                comments: [Comment],
                closedDateTimestamp: String?) {
        self.id = id
        self.userId = userId
        self.username = username
        self.boundingBox = boundingBox
        self.tags = tags
        self.createdDateTimestamp = createdDateTimestamp
        self.numberOfComments = numberOfComments
        self.comments = comments
        self.closedDateTimestamp = closedDateTimestamp
    }
}
