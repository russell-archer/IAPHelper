//
//  IAPHelper+SKRequestDelegate.swift
//  IAPHelper
//
//  Created by Russell Archer on 13/07/2020.
//

import UIKit
import StoreKit

extension IAPHelper: SKRequestDelegate {

    /// This method is called for both SKProductsRequest (request product info) and
    /// SKRequest (request receipt refresh).
    /// - Parameters:
    ///   - request:    The request object.
    public func requestDidFinish(_ request: SKRequest) {
        
        if productsRequest != nil {
            productsRequest = nil  // Destroy the product info request object
            
            // Call the completion handler. The request for product info completed. See also productsRequest(_:didReceive:)
            IAPLog.event(.requestProductsDidFinish)
            DispatchQueue.main.async { self.requestProductsCompletion?(.requestProductsDidFinish) }
            return
        }
        
        if receiptRequest != nil {
            receiptRequest = nil  // Destory the receipt request object
            IAPLog.event(.requestReceiptRefreshSuccess)
            DispatchQueue.main.async { self.requestReceiptCompletion?(.requestReceiptRefreshSuccess) }
        }
    }
    
    /// Called by the App Store if a request fails.
    /// This method is called for both SKProductsRequest (request product info) and
    /// SKRequest (request receipt refresh).
    /// - Parameters:
    ///   - request:    The request object.
    ///   - error:      The error returned by the App Store.
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        
        if productsRequest != nil {
            productsRequest = nil  // Destroy the request object
            
            // Call the completion handler. The request for product info failed
            IAPLog.event(.requestProductsFailure)
            DispatchQueue.main.async { self.requestProductsCompletion?(.requestProductsFailure) }
            return
        }
        
        if receiptRequest != nil {
            receiptRequest = nil  // Destory the receipt request object
            IAPLog.event(.requestReceiptRefreshFailure)
            DispatchQueue.main.async { self.requestReceiptCompletion?(.requestReceiptRefreshFailure) }
        }
    }
}
