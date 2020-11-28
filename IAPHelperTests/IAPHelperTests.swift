//
//  IAPHelperTests.swift
//  IAPHelperTests
//
//  Created by Russell Archer on 28/11/2020.
//

import XCTest
import StoreKitTest

// Import the IAPHelper module.
// This lets you write unit tests against *internal* properties and methods
@testable import IAPHelper

class IAPHelperTests: XCTestCase {
    private var iap = IAPHelper.shared
    private var session: SKTestSession! = try? SKTestSession(configurationFileNamed: IAPConstants.ConfigFile())
    
    func testConfiguration() {
        // If this is true then the StoreKit config file has been successfully read by IAPHelper
        XCTAssertTrue(iap.haveConfiguredProductIdentifiers)
    }
}
