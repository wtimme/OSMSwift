//
//  XCTestCase+DataFromFile.swift
//  OSMSwift_Tests
//
//  Created by Wolfgang Timme on 9/11/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest

extension XCTestCase {
    
    func dataFromXMLFile(named fileName: String) -> Data? {
        let bundle = Bundle(for: type(of: self))
        guard let url = bundle.url(forResource: fileName, withExtension: "xml") else { return nil }
        
        return try? Data(contentsOf: url)
    }
    
}
