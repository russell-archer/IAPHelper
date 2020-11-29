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
    
    func testGetProductInfo() {
        // Create an expected outcome for an *asynchronous* test
        let productInfoExpectation = XCTestExpectation()
        
        iap.requestProductsFromAppStore { notification in
            
            if notification == IAPNotification.requestProductsSuccess {
                XCTAssertNotNil(self.iap.products)
            } else if notification == IAPNotification.requestProductsFailure {
                XCTFail()
            }
            
            productInfoExpectation.fulfill()
        }
        
        // Signal that we want to wait on one or more expectations for up to the specified timeout
        wait(for: [productInfoExpectation], timeout: 10.0)  // Wait up to 10 secs for the expectation to be fulfilled
    }
    
    func testPurchaseProduct() {
        let productId = "com.rarcher.flowers-large"
        let purchaseProductExpectation = XCTestExpectation()
        session.disableDialogs = true

        guard let product = iap.getStoreProductFrom(id: productId) else {
            XCTFail()
            return
        }
        
        iap.buyProduct(product) { notification in
            switch notification {
            case .purchaseSuccess(productId: let pid): XCTAssertNotNil(pid)
            case .purchaseFailure(productId:): XCTFail()
            default: break
            }
            
            purchaseProductExpectation.fulfill()
        }
        
        // Signal that we want to wait on one or more expectations for up to the specified timeout
        wait(for: [purchaseProductExpectation], timeout: 10.0)  // Wait up to 10 secs for the expectation to be fulfilled
    }
    
    func testValidateReceipt() {
        XCTAssertTrue(iap.processReceipt())
    }
}
