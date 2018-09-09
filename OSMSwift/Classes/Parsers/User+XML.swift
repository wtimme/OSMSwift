//
//  User+XML.swift
//  OSMSwift
//
//  Created by Wolfgang Timme on 9/9/18.
//

import Foundation

import AEXML

extension User {
    init?(data: Data) {
        do {
            let xmlDocument = try AEXMLDocument(xml: data)
            
            guard
                let userIdAsString = xmlDocument.root["user"].attributes["id"],
                let userId = Int(userIdAsString),
                let displayName = xmlDocument.root["user"].attributes["display_name"]
            else {
                    return nil
            }
            
            self.id = userId
            self.displayName = displayName
        } catch {
            print("\(error)")
            
            return nil
        }
    }
}
