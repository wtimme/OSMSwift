//
//  Changeset_XMLTestCase.swift
//  OSMSwift_Tests
//
//  Created by Wolfgang Timme on 9/11/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest

@testable import OSMSwift
import Require

class Changeset_XMLTestCase: XCTestCase {
    
    func testInitWithChangesetThatIsMissingTheBoundingBoxShouldNotResultInNil() {
        let xmlData = dataFromXMLFile(named: "SingleChangesetWithoutBoundingBox").require()
        
        let resultingChangesets = Changeset.changesets(from: xmlData)
        XCTAssertFalse(resultingChangesets.isEmpty)
    }
    
}
