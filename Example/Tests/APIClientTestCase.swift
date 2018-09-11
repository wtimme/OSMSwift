//
//  APIClientTestCase.swift
//  OSMSwift_Tests
//
//  Created by Wolfgang Timme on 6/25/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest

import OSMSwift
import SwiftOverpass
import Require

class APIClientTestCase: XCTestCase {

    let baseURL = URL(string: "https://localhost/")!
    var keychainHandlerMock: KeychainHandlerMock!
    var oauthHandlerMock: OAuthHandlerMock!
    var httpRequestHandlerMock: HTTPRequestHandlerMock!
    var client: APIClientProtocol!

    override func setUp() {
        super.setUp()

        keychainHandlerMock = KeychainHandlerMock()
        oauthHandlerMock = OAuthHandlerMock()
        httpRequestHandlerMock = HTTPRequestHandlerMock()
        client = APIClient(baseURL: baseURL,
                           keychainHandler: keychainHandlerMock,
                           oauthHandler: oauthHandlerMock,
                           httpRequestHandler: httpRequestHandlerMock)
    }

    // MARK: Authentication Status

    func testIsAuthenticatedShouldReturnTrueWhenTheKeychainContainsCredentials() {
        keychainHandlerMock.mockedOAuthCredentials = OAuthCredentials(token: "sample-token",
                                                                      secret: "sample-secret")

        XCTAssertTrue(client.isAuthenticated)
    }

    func testIsAuthenticatedShouldReturnFalseWhenTheKeychainDoesNotContainCredentials() {
        keychainHandlerMock.mockedOAuthCredentials = nil

        XCTAssertFalse(client.isAuthenticated)
    }

    // MARK: OAuth

    func testStartOAuthFlowImmediatelyExecuteTheClosureIfTheOAuthHandlerExperiencedAnError() {
        let presentingViewController = UIViewController()

        // Set up the OAuth handler to execute the closure with a mocked error.
        let mockedError = MockError(code: 1)
        oauthHandlerMock.startOAuthFlowCredentialsError = mockedError

        let closureExpectation = expectation(description: "The closure should be executed.")
        client.addAccountUsingOAuth(from: presentingViewController) { (error) in
            XCTAssertEqual(error as? MockError, mockedError)

            closureExpectation.fulfill()
        }
        wait(for: [closureExpectation], timeout: 0.5)
    }

    func testStartOAuthFlowShouldStoreTheCredentialsInTheKeychainIfAuthenticationSucceeded() {
        let presentingViewController = UIViewController()

        // Act as if the OAuth handler responded with credentials.
        let mockedCredentials = OAuthCredentials(token: "sample-token",
                                                 secret: "sample-secret")
        oauthHandlerMock.startOAuthFlowCredentials = mockedCredentials

        let closureExpectation = expectation(description: "The closure should be executed.")
        client.addAccountUsingOAuth(from: presentingViewController) { (error) in
            XCTAssertNil(error)

            closureExpectation.fulfill()
        }
        wait(for: [closureExpectation], timeout: 0.5)

        XCTAssertEqual(keychainHandlerMock.oauthCredentials,
                       mockedCredentials,
                       "The client should store the credentials in the Keychain.")
    }

    func testLogoutShouldRemoveOAuthCredentialsFromKeychain() {
        keychainHandlerMock.mockedOAuthCredentials = OAuthCredentials(token: "sample-token",
                                                                      secret: "sample-secret")

        client.logout()

        XCTAssertNil(keychainHandlerMock.mockedOAuthCredentials)
    }

    // MARK: Permissions

    func testPermissionsShouldQueryTheCorrectURLResource() {

        // Mock credentials so that we're authenticated.
        keychainHandlerMock.mockedOAuthCredentials = OAuthCredentials(token: "sample-token",
                                                                      secret: "sample-secret")

        client.permissions { _, _ in }

        XCTAssertEqual(httpRequestHandlerMock.path, "/api/0.6/permissions")
    }

    func testPermissionsShouldResultInNotAuthorizedErrorWhenThereWereNoOAuthCredentials() {
        let closureExpectation = expectation(description: "The closure should be executed.")
        client.permissions { (permissions, error) in
            XCTAssertTrue(permissions.isEmpty)
            XCTAssertEqual(error as? APIClientError, .notAuthenticated)

            closureExpectation.fulfill()
        }

        wait(for: [closureExpectation], timeout: 0.5)
    }

    func testPermissionsShouldCallTheClosureIfThereWasAnErrorDuringTheHTTPRequest() {

        // Mock credentials so that we're authenticated.
        keychainHandlerMock.mockedOAuthCredentials = OAuthCredentials(token: "sample-token",
                                                                      secret: "sample-secret")

        // Act as if the HTTP request handler experienced an error.
        let mockedError = MockError(code: 1)
        httpRequestHandlerMock.dataResponse = DataResponse(data: nil, error: mockedError)

        let closureExpectation = expectation(description: "The closure should be executed.")
        client.permissions { (permissions, error) in
            XCTAssertTrue(permissions.isEmpty)
            XCTAssertEqual(error as? MockError, mockedError)

            closureExpectation.fulfill()
        }

        wait(for: [closureExpectation], timeout: 0.5)
    }

    func testPermissionsShouldParseAListOfPermissions() {
        // Mock credentials so that we're authenticated.
        keychainHandlerMock.mockedOAuthCredentials = OAuthCredentials(token: "sample-token",
                                                                      secret: "sample-secret")

        guard let xmlData = dataFromXMLFile(named: "Permissions") else {
            XCTFail("Failed to read test XML data.")
            return
        }

        httpRequestHandlerMock.dataResponse = DataResponse(data: xmlData, error: nil)

        let closureExpectation = expectation(description: "The closure should be executed.")
        client.permissions { (permissions, error) in
            XCTAssertEqual(permissions.count, 3)
            XCTAssertTrue(permissions.contains(.allow_read_prefs))
            XCTAssertTrue(permissions.contains(.allow_read_gpx))
            XCTAssertTrue(permissions.contains(.allow_write_gpx))

            XCTAssertNil(error)

            closureExpectation.fulfill()
        }
        wait(for: [closureExpectation], timeout: 0.5)
    }

    // MARK: Map Data

    func testMapDataShouldQueryTheCorrectURLResource() {

        let box = BoundingBox(left: 13.386310, bottom: 52.524905, right: 13.407789, top: 52.530061)

        client.mapData(inside: box) { _, _ in }

        XCTAssertEqual(httpRequestHandlerMock.path, "/api/0.6/map?bbox=\(box.queryString)")
    }

    func testMapDataShouldCallTheClosureIfThereWasAnErrorDuringTheHTTPRequest() {

        let box = BoundingBox(left: 13.386310, bottom: 52.524905, right: 13.407789, top: 52.530061)

        // Act as if the HTTP request handler experienced an error.
        let mockedError = MockError(code: 1)
        httpRequestHandlerMock.dataResponse = DataResponse(data: nil, error: mockedError)

        let closureExpectation = expectation(description: "The closure should be executed.")
        client.mapData(inside: box) { (elements, error) in
            XCTAssertTrue(elements.isEmpty)
            XCTAssertEqual(error as? MockError, mockedError)

            closureExpectation.fulfill()
        }

        wait(for: [closureExpectation], timeout: 0.5)
    }
    
    // MARK: Authenticated User
    
    func testAuthenticatedUserShouldQueryTheCorrectURL() {
        
        client.authenticatedUser { _, _ in }
        
        XCTAssertEqual(httpRequestHandlerMock.path, "/api/0.6/user/details")
    }
    
    func testAuthenticatedUserShouldCallTheClosureIfThereWasAnErrorDuringTheHTTPRequest() {
        
        // Act as if the HTTP request handler experienced an error.
        let mockedError = MockError(code: 1)
        httpRequestHandlerMock.dataResponse = DataResponse(data: nil, error: mockedError)
        
        let closureExpectation = expectation(description: "The closure should be executed.")
        client.authenticatedUser { user, error in
            XCTAssertNil(user)
            XCTAssertEqual(error as? MockError, mockedError)
            
            closureExpectation.fulfill()
        }
        
        wait(for: [closureExpectation], timeout: 0.5)
    }
    
    func testAuthenticatedUserShouldParseASuccessfulResponseIntoAUser() {
        // Mock credentials so that we're authenticated.
        keychainHandlerMock.mockedOAuthCredentials = OAuthCredentials(token: "sample-token",
                                                                      secret: "sample-secret")
        
        guard let xmlData = dataFromXMLFile(named: "AuthenticatedUser") else {
            XCTFail("Failed to read test XML data.")
            return
        }
        
        httpRequestHandlerMock.dataResponse = DataResponse(data: xmlData, error: nil)
        
        let closureExpectation = expectation(description: "The closure should be executed.")
        client.authenticatedUser { user, error in
            guard let user = user else {
                XCTFail("The XML should've been properly parsed.")
                return
            }
            
            XCTAssertEqual(user.id, 42)
            XCTAssertEqual(user.displayName, "john.doe")
            
            XCTAssertNil(error)
            
            closureExpectation.fulfill()
        }
        wait(for: [closureExpectation], timeout: 0.5)
    }
    
    // MARK: Changesets by user ID
    
    func testOpenChangesetsByUserIdShouldQueryTheCorrectURL() {
        let userId = 42
        client.openChangesets(userId: userId, { _, _ in })
        
        XCTAssertEqual(httpRequestHandlerMock.path, "/api/0.6/changesets?open=true&user=\(userId)")
    }
    
    func testOpenChangesetsByUserIdShouldCallTheClosureIfThereWasAnErrorDuringTheHTTPRequest() {
        
        // Act as if the HTTP request handler experienced an error.
        let mockedError = MockError(code: 1)
        httpRequestHandlerMock.dataResponse = DataResponse(data: nil, error: mockedError)
        
        let closureExpectation = expectation(description: "The closure should be executed.")
        client.openChangesets(userId: 42) { changesets, error in
            XCTAssertTrue(changesets.isEmpty)
            XCTAssertEqual(error as? MockError, mockedError)
            
            closureExpectation.fulfill()
        }
        
        wait(for: [closureExpectation], timeout: 0.5)
    }
    
    func testOpenChangesetsByUserIdShouldParseASuccessfulResponse() {
        // Mock credentials so that we're authenticated.
        keychainHandlerMock.mockedOAuthCredentials = OAuthCredentials(token: "sample-token",
                                                                      secret: "sample-secret")
        
        guard let xmlData = dataFromXMLFile(named: "MultipleChangesets") else {
            XCTFail("Failed to read test XML data.")
            return
        }
        
        httpRequestHandlerMock.dataResponse = DataResponse(data: xmlData, error: nil)
        
        let closureExpectation = expectation(description: "The closure should be executed.")
        client.openChangesets(userId: 42) { changesets, error in
            XCTAssertNil(error)
            
            XCTAssertEqual(changesets.count, 2)
            
            // Make sure that the changesets are in the correct order.
            XCTAssertEqual(changesets.first.require().id, 58900328)
            XCTAssertEqual(changesets.last.require().id, 58291399)
            
            // Check one of the changesets to see whether the XML parsing was successful.
            let firstChangeset = changesets.first.require()
            
            XCTAssertEqual(firstChangeset.userId, 54247)
            XCTAssertEqual(firstChangeset.username, "dolphinling")
            
            XCTAssertEqual(firstChangeset.boundingBox.left, -73.2140236)
            XCTAssertEqual(firstChangeset.boundingBox.bottom, 44.4734714)
            XCTAssertEqual(firstChangeset.boundingBox.right, -73.2140236)
            XCTAssertEqual(firstChangeset.boundingBox.top, 44.4734714)
            
            XCTAssertEqual(firstChangeset.tags.count, 4)
            
            XCTAssertEqual(firstChangeset.tags.first(where: { $0.key == "source"})?.value,
                           "local_knowledge;website")
            XCTAssertEqual(firstChangeset.tags.first(where: { $0.key == "note"})?.value,
                           "Seems to be inconsistent about spelling their own name, so I put in two, not sure which should be primary")
            
            XCTAssertEqual(firstChangeset.createdDateTimestamp,
                           "2018-05-12T11:39:42Z")
            XCTAssertEqual(firstChangeset.closedDateTimestamp,
                           "2018-05-12T11:39:43Z")
            
            XCTAssertEqual(firstChangeset.numberOfComments, 2)
            XCTAssertEqual(firstChangeset.comments.count, 2)
            
            // Make sure that the changesets are in the correct order.
            XCTAssertEqual(firstChangeset.comments.first.require().userId, 1234)
            XCTAssertEqual(firstChangeset.comments.last.require().userId, 42)
            
            // Check one of the comments to see whether the XML parsing was successful.
            let firstComment = firstChangeset.comments.first.require()
            XCTAssertEqual(firstComment.username, "jane.doe")
            XCTAssertEqual(firstComment.content, "Lorem ipsum dolor sed amet.")
            
            closureExpectation.fulfill()
        }
        wait(for: [closureExpectation], timeout: 0.5)
    }
    
    // MARK: Create Changeset
    
    func testCreateChangesetShouldQueryTheCorrectURL() {
        let tags = [Tag(key: "man_made", value: "surveillance"),
                    Tag(key: "camera:mount", value: "pole")]
        
        client.createChangeset(tags: tags, { _, _ in })
        
        XCTAssertEqual(httpRequestHandlerMock.path, "/api/0.6/changeset/create")
    }
    
    func testCreateChangesetShouldUseHTTPMethodPut() {
        let tags = [Tag(key: "man_made", value: "surveillance"),
                    Tag(key: "camera:mount", value: "pole")]
        
        client.createChangeset(tags: tags, { _, _ in })
        
        XCTAssertEqual(httpRequestHandlerMock.method, "PUT")
    }
    
    func testCreateChangesetShouldPutTheXMLOfTheChangelogWrappedInOSMTags() {
        let tags = [Tag(key: "created_by", value: "OpenCCTV"),
                    Tag(key: "comment", value: "Lorem ipsum dolor sed amet.")]
        
        client.createChangeset(tags: tags, { _, _ in })
        
        // Load the XML string that we expect.
        let expectedXMLData = dataFromXMLFile(named: "ChangesetToCreate").require()
        let expectedXMLString = String(data: expectedXMLData, encoding: .utf8).require()
        
        // Trim the string, to avoid accidentally inserted whitespace or line breaks.
        let trimmedExpectedXMLString = expectedXMLString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Convert the data that was sent to a string for comparison.
        let dataThatWasSent = httpRequestHandlerMock.data.require(hint: "The client should have sent data.")
        let stringThatWasSent = String(data: dataThatWasSent, encoding: .utf8).require()
        
        XCTAssertEqual(stringThatWasSent, trimmedExpectedXMLString)
    }
    
    func testCreateChangesetForwardErrorsToTheCompletionClosure() {
        let tags = [Tag(key: "man_made", value: "surveillance"),
                    Tag(key: "camera:mount", value: "pole")]
        
        let mockedError = MockError(code: 42)
        httpRequestHandlerMock.dataResponse = DataResponse(data: nil, error: mockedError)
        
        let completionExpectation = expectation(description: "The `completion` closure should be executed.")
        client.createChangeset(tags: tags) { (changesetId, error) in
            XCTAssertNil(changesetId)
            XCTAssertEqual(error as? MockError, mockedError)
            
            completionExpectation.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testCreateChangesetShouldParseTheChangeseIdFromTheResponse() {
        let tags = [Tag(key: "man_made", value: "surveillance"),
                    Tag(key: "camera:mount", value: "pole")]
        
        let mockedChangesetId = 42
        let mockedResponseString = "\(mockedChangesetId)"
        let mockedResponseData = mockedResponseString.data(using: .utf8)
        httpRequestHandlerMock.dataResponse = DataResponse(data: mockedResponseData, error: nil)
        
        let completionExpectation = expectation(description: "The `completion` closure should be executed.")
        client.createChangeset(tags: tags) { (changesetId, error) in
            XCTAssertNil(error)
            XCTAssertEqual(changesetId, mockedChangesetId)
            
            completionExpectation.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    // MARK: Helper

    private func dataFromXMLFile(named fileName: String) -> Data? {
        let bundle = Bundle(for: type(of: self))
        guard let url = bundle.url(forResource: fileName, withExtension: "xml") else { return nil }

        return try? Data(contentsOf: url)
    }

}
