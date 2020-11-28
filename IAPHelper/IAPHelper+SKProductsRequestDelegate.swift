//
//  IAPHelper+SKProductsRequestDelegate.swift
//  IAPHelper
//
//  Created by Russell Archer on 06/07/2020.
//

import UIKit
import StoreKit

extension IAPHelper: SKProductsRequestDelegate {
    
    /// Receives a list of localized product info from the App Store.
    /// - Parameters:
    ///   - request:    The request object.
    ///   - response:   The response from the App Store.
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        guard !response.products.isEmpty else {
            IAPLog.event(.requestProductsNoProducts)
            DispatchQueue.main.async { self.requestProductsCompletion?(.requestProductsNoProducts) }
            return
        }

        guard response.invalidProductIdentifiers.isEmpty else {
            IAPLog.event(.requestProductsInvalidProducts)
            DispatchQueue.main.async { self.requestProductsCompletion?(.requestProductsInvalidProducts) }
            return
        }
        
        // Update our [SKProduct] set of all available products
        products = response.products
        IAPLog.event(.requestProductsSuccess)
        DispatchQueue.main.async { self.requestProductsCompletion?(.requestProductsSuccess) }
        
        // When this method returns StoreKit will immediately call the SKRequestDelegate method
        // requestDidFinish(_:) where we will destroy the productsRequest object
    }
}

