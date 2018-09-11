//
//  Changeset+XML.swift
//  OSMSwift
//
//  Created by Wolfgang Timme on 9/9/18.
//

import Foundation

import AEXML

extension Changeset {
    
    static func changesets(from data: Data) -> [Changeset] {
        do {
            let xmlDocument = try AEXMLDocument(xml: data)
            
            guard let changesetXMLElements = xmlDocument.root["changeset"].all else { return [] }
            
            return changesetXMLElements.compactMap { (xmlElement) -> Changeset? in
                return Changeset(xmlElement: xmlElement)
            }
        } catch {
            print("\(error)")
            
            return []
        }
    }
    
    private init?(xmlElement: AEXMLElement) {
        guard
            let idAsString = xmlElement.attributes["id"],
            let id = Int(idAsString),
            let userIdAsString = xmlElement.attributes["uid"],
            let userId = Int(userIdAsString),
            let username = xmlElement.attributes["user"],
            let createdDateTimestamp = xmlElement.attributes["created_at"],
            let numberOfCommentsAsString = xmlElement.attributes["comments_count"],
            let numberOfComments = Int(numberOfCommentsAsString)
        else {
            return nil
        }
        
        self.id = id
        self.userId = userId
        self.username = username
        self.boundingBox = Changeset.parseBoundingBox(from: xmlElement)
        self.tags = Changeset.parseTags(from: xmlElement)
        self.createdDateTimestamp = createdDateTimestamp
        self.numberOfComments = numberOfComments
        self.comments = Changeset.parseComments(from: xmlElement)
        self.closedDateTimestamp = xmlElement.attributes["closed_at"]
    }
    
    private static func parseBoundingBox(from changesetXMLElement: AEXMLElement) -> BoundingBox? {
        guard
            let minimumLatitudeAsString = changesetXMLElement.attributes["min_lat"],
            let minimumLatitude = Double(minimumLatitudeAsString),
            let minimumLongitudeAsString = changesetXMLElement.attributes["min_lon"],
            let minimumLongitude = Double(minimumLongitudeAsString),
            let maximumLatitudeAsString = changesetXMLElement.attributes["max_lat"],
            let maximumLatitude = Double(maximumLatitudeAsString),
            let maximumLongitudeAsString = changesetXMLElement.attributes["max_lon"],
            let maximumLongitude = Double(maximumLongitudeAsString)
        else {
            return nil
        }
        
        return BoundingBox(left: minimumLongitude,
                           bottom: minimumLatitude,
                           right: maximumLongitude,
                           top: maximumLatitude)
    }
    
    private static func parseTags(from changesetXMLElement: AEXMLElement) -> [Tag] {
        guard let tagXMLElements = changesetXMLElement["tag"].all else { return [] }
        
        return tagXMLElements.compactMap {
            guard let key = $0.attributes["k"], let value = $0.attributes["v"] else {
                return nil
            }
            
            return Tag(key: key, value: value)
        }
    }
    
    private static func parseComments(from changesetXMLElement: AEXMLElement) -> [Comment] {
        guard let commentXMLElements = changesetXMLElement["discussion"]["comment"].all else { return [] }
        
        return commentXMLElements.compactMap {
            guard
                let userIdAsString = $0.attributes["uid"],
                let userId = Int(userIdAsString),
                let username = $0.attributes["user"],
                let dateAsString = $0.attributes["date"],
                let content = $0.children.first(where: { child in
                    return child.name == "text"
                })?.value
            else {
                return nil
            }

            return Comment(userId: userId,
                           username: username,
                           dateAsString: dateAsString,
                           content: content)
        }
    }
    
}
