//
//  TopicsPresenterTests.swift
//  ExamEGERussianTests
//
//  Created by Ivan Magda on 23/07/2018.
//  Copyright © 2018 Alex Karpov. All rights reserved.
//

import XCTest
import PromiseKit
@testable import ExamEGERussian

class TopicsPresenterTests: XCTestCase {

    let userRegistrationService = UserRegistrationServiceMock()
    let graphService = GraphServiceMock()
    let topicsViewSpy = TopicsViewSpy()
    var topicsPresenter: TopicsPresenterImpl!

    override func setUp() {
        super.setUp()

        topicsPresenter = TopicsPresenterImpl(
            view: topicsViewSpy,
            model: KnowledgeGraph(),
            userRegistrationService: userRegistrationService,
            graphService: graphService
        )
    }

    func testSuccessResponseEqualCountTopics() {
        let exp = expectation(description: "Equal count of fetched and mapped topics")

        let resultToBeReturned = KnowledgeGraphPlainObject.createGraph()
        graphService.resultToBeReturned = .value(resultToBeReturned)
        topicsViewSpy.onSet = { [weak self] in
            guard let `self` = self else { return }
            XCTAssertTrue(self.topicsViewSpy.topics!.count == resultToBeReturned.topics.count, "not equal count of topics")
            exp.fulfill()
        }

        topicsPresenter.refresh()

        wait(for: [exp], timeout: 1.0)
    }

    func testFailureresponseDisplayError() {
        let exp = expectation(description: "Concreate error title and message")

        let expectedErrorTitle = "Error"
        let expectedErrorMessage = "Some error message"
        let errorToBeReturned = NSError.createError(withMessage: expectedErrorMessage)
        graphService.resultToBeReturned = Promise(error: errorToBeReturned)
        topicsViewSpy.onError = { [weak self] in
            guard let `self` = self else { return }
            XCTAssertEqual(expectedErrorTitle, self.topicsViewSpy.displayErrorTitle, "Error title doesn't match")
            XCTAssertEqual(expectedErrorMessage, self.topicsViewSpy.displayErrorMessage, "Error message doesn't match")
            exp.fulfill()
        }

        topicsPresenter.refresh()

        wait(for: [exp], timeout: 1.0)
    }
}
