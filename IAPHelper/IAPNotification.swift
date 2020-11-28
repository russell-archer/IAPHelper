//
//  IAPHelperNotification.swift
//  IAPHelper
//
//  Created by Russell Archer on 07/12/2016.
//  Copyright © 2016 Russell Archer. All rights reserved.
//

import Foundation

/// Informational logging notifications issued by IAPHelper
public enum IAPNotification: Error, Equatable {
    
    case configurationCantFindInBundle
    case configurationCantReadData
    case configurationCantDecode
    case configurationNoProductIds
    case configurationEmpty
    case configurationSuccess
    case configurationFailure

    case purchasedProductsValidatedAgainstReceipt
    case purchasedProductsLoadSuccess
    case purchasedProductsLoadFailure

    case purchaseStarted
    case purchaseAbortPurchaseInProgress
    case purchaseProductUnavailable(productId: ProductId)
    case purchaseInProgress(productId: ProductId)
    case purchaseCancelled(productId: ProductId)
    case purchaseDeferred(productId: ProductId)
    case purchaseRestoreStarted
    case purchaseRestoreSuccess(productId: ProductId)
    case purchaseRestoreFailure(productId: ProductId)
    case purchaseSuccess(productId: ProductId)
    case purchaseFailure(productId: ProductId)

    case receiptValidationStarted
    case receiptBadUrl
    case receiptMissing
    case receiptLoadSuccess
    case receiptLoadFailure
    case receiptValidateSigningSuccess
    case receiptValidateSigningFailure
    case receiptReadSuccess
    case receiptReadFailure
    case receiptRefreshStarted
    case receiptRefreshSuccess
    case receiptRefreshFailure
    case receiptProcessingSuccess
    case receiptProcessingFailure
    case receiptValidationSuccess
    case receiptValidationFailure

    case requestProductsStarted
    case requestProductsDidFinish
    case requestProductsNoProducts
    case requestProductsInvalidProducts
    case requestProductsSuccess
    case requestProductsFailure

    case requestReceiptRefreshSuccess
    case requestReceiptRefreshFailure
    
    case appStoreChanged
    case appStoreRevokedEntitlements(productId: ProductId)
    case appStoreNoProductInfo
    
    /// A short description of the notification.
    /// - Returns: Returns a short description of the notification.
    public func shortDescription() -> String {
        switch self {
            
        case .configurationCantFindInBundle:            return "Can't find the .storekit configuration file in the main bundle"
        case .configurationCantReadData:                return "Can't read in-app purchase data from .storekit configuration file"
        case .configurationCantDecode:                  return "Can't decode in-app purchase data in the .storekit configuration file"
        case .configurationNoProductIds:                return "No preconfigured ProductIds. They should be defined in the .storekit config file"
        case .configurationEmpty:                       return "Configuration does not contain any product definitions"
        case .configurationSuccess:                     return "Configuration success"
        case .configurationFailure:                     return "Configuration failure"
        
        case .purchasedProductsValidatedAgainstReceipt: return "Purchased products validated against receipt"
        case .purchasedProductsLoadSuccess:             return "Purchased products load success"
        case .purchasedProductsLoadFailure:             return "Purchased products load failure"
        
        case .purchaseStarted:                          return "Purchase started"
        case .purchaseAbortPurchaseInProgress:          return "Purchase aborted because another purchase is already in progress"
        case .purchaseProductUnavailable:               return "Product unavailable for purchase"
        case .purchaseInProgress:                       return "Purchase in progress"
        case .purchaseDeferred:                         return "Purchase in progress. Awaiting authorization"
        case .purchaseCancelled:                        return "Purchase cancelled"
        case .purchaseRestoreStarted:                   return "Purchase restore started"
        case .purchaseRestoreSuccess:                   return "Purchase restore success"
        case .purchaseRestoreFailure:                   return "Purchase restore failure"
        case .purchaseSuccess:                          return "Purchase success"
        case .purchaseFailure:                          return "Purchase failure"

        case .receiptValidationStarted:                 return "Receipt validation started"
        case .receiptBadUrl:                            return "Receipt URL is invalid or missing"
        case .receiptMissing:                           return "Receipt missing"
        case .receiptLoadSuccess:                       return "Receipt load success"
        case .receiptLoadFailure:                       return "Receipt load failure"
        case .receiptValidateSigningSuccess:            return "Receipt validation of signing success"
        case .receiptValidateSigningFailure:            return "Receipt validation of signing failure"
        case .receiptReadSuccess:                       return "Receipt read success"
        case .receiptReadFailure:                       return "Receipt read failure"
        case .receiptRefreshStarted:                    return "Receipt refresh started"
        case .receiptRefreshSuccess:                    return "Receipt refresh success"
        case .receiptRefreshFailure:                    return "Receipt refresh failure"
        case .receiptProcessingSuccess:                 return "Receipt processing success"
        case .receiptProcessingFailure:                 return "Receipt processing failure"
        case .receiptValidationSuccess:                 return "Receipt validation success"
        case .receiptValidationFailure:                 return "Receipt validation failure"

        case .requestProductsStarted:                   return "Request products from the App Store started"
        case .requestProductsDidFinish:                 return "The request for products from the App Store completed"
        case .requestProductsNoProducts:                return "The App Store returned an empty list of products"
        case .requestProductsInvalidProducts:           return "The App Store returned a list of invalid (unrecognized) products"
        case .requestProductsSuccess:                   return "Request products from the App Store success"
        case .requestProductsFailure:                   return "Request products from the App Store failure"

        case .requestReceiptRefreshSuccess:             return "Request receipt refresh success"
        case .requestReceiptRefreshFailure:             return "Request receipt refresh failure"
            
        case .appStoreChanged:                          return "The App Store storefront has changed"
        case .appStoreRevokedEntitlements:              return "The App Store revoked user entitlements"
        case .appStoreNoProductInfo:                    return "No localized product information is available"
        }
    }
}
