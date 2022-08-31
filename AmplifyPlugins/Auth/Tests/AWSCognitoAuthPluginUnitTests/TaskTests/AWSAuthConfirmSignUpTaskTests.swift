//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

//// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AWSCognitoAuthPlugin
@testable import AWSPluginsTestCommon
import ClientRuntime

import AWSCognitoIdentityProvider

class AWSAuthConfirmSignUpTaskTests: XCTestCase {

    var queue: OperationQueue?

    let initialState = AuthState.configured(.signedOut(.init(lastKnownUserName: nil)), .configured)

    override func setUp() {
        super.setUp()
        queue = OperationQueue()
        queue?.maxConcurrentOperationCount = 1
    }

    func testConfirmSignUpOperationSuccess() async throws {
        let functionExpectation = expectation(description: "API call should be invoked")
        let confirmSignUp: MockIdentityProvider.MockConfirmSignUpResponse = { _ in
            functionExpectation.fulfill()
            return try .init(httpResponse: MockHttpResponse.ok)
        }

        let statemachine = Defaults.makeDefaultAuthStateMachine(
            initialState: initialState,
            userPoolFactory: {MockIdentityProvider(mockConfirmSignUpResponse: confirmSignUp)})

        let request = AuthConfirmSignUpRequest(username: "jeffb",
                                               code: "213",
                                               options: AuthConfirmSignUpRequest.Options())
        let task = AWSAuthConfirmSignUpTask(request, authStateMachine: statemachine)
        let confirmSignUpResult = try await task.value
        print("Confirm Sign Up Result: \(confirmSignUpResult)")
        wait(for: [functionExpectation], timeout: 1)
    }

    func testConfirmSignUpOperationFailure() async throws {
        let functionExpectation = expectation(description: "API call should be invoked")
        let confirmSignUp: MockIdentityProvider.MockConfirmSignUpResponse = { _ in
            functionExpectation.fulfill()
            throw try ConfirmSignUpOutputError(httpResponse: MockHttpResponse.ok)
        }

        let statemachine = Defaults.makeDefaultAuthStateMachine(
            initialState: initialState,
            userPoolFactory: {MockIdentityProvider(mockConfirmSignUpResponse: confirmSignUp)})

        let request = AuthConfirmSignUpRequest(username: "jeffb",
                                               code: "213",
                                               options: AuthConfirmSignUpRequest.Options())

        do {
            let task = AWSAuthConfirmSignUpTask(request, authStateMachine: statemachine)
            _ = try await task.value
            XCTFail("Should not produce success response")
        } catch {
        }
        wait(for: [functionExpectation], timeout: 1)
    }
}