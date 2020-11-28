//
//  IAPReceipt+Validate.swift
//  IAPHelper
//
//  Created by Russell Archer on 06/07/2020.
//
//  Swift wrapper for OpenSSL functions.
//  Contains modified portions of code created by Bill Morefield copyright (c) 2018 Razeware LLC.
//  

import Foundation

extension IAPReceipt {
    
    /// Perform on-device (no network connection required) validation of the app's receipt.
    /// Returns false if the receipt is invalid or missing, in which case your app should call
    /// refreshReceipt(completion:) to request an updated receipt from the app store. This may
    /// result in the user being prompted for their App Store credentials.
    ///
    /// We validate the receipt to ensure that it was:
    ///
    /// * Created and signed using the Apple x509 root certificate via the App Store
    /// * Issued for the same version of this app and the user's device
    ///
    /// At this point a list of locally stored purchased product ids should have been loaded from the UserDefaults
    /// dictionary. We need to validate these product ids against the App Store receipt's collection of purchased
    /// product ids to see that they match. If there are no locally stored purchased product ids (i.e. the user
    /// hasn't purchased anything) then we don't attempt to validate the receipt. Note that if the user has previously
    /// purchased products then either using the Restore feature or attempting to re-purchase the product will
    /// result in a refreshed receipt and the product id of the product will be stored locally in the UserDefaults
    /// dictionary.
    /// - Returns: Returns true if the receipt is valid; false otherwise.
    public func validate() -> Bool {
        guard let idString = bundleIdString,
              let version = bundleVersionString,
              let _ = opaqueData,
              let hash = hashData else {
            
            IAPLog.event(.receiptValidationFailure)
            return false
        }
        
        guard let appBundleId = Bundle.main.bundleIdentifier else {
            IAPLog.event(.receiptValidationFailure)
            return false
        }
        
        guard idString == appBundleId else {
            IAPLog.event(.receiptValidationFailure)
            return false
        }
        
        guard let appVersionString = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String else {
            IAPLog.event(.receiptValidationFailure)
            return false
        }
        
        guard version == appVersionString else {
            IAPLog.event(.receiptValidationFailure)
            return false
        }
        
        guard hash == computeHash() else {
            IAPLog.event(.receiptValidationFailure)
            return false
        }
        
        if let expirationDate = expirationDate {
            if expirationDate < Date() {
                IAPLog.event(.receiptValidationFailure)
                return false
            }
        }
        
        isValid = true
        IAPLog.event(.receiptValidationSuccess)
        
        return true
    }
    
    /// Compare the set of fallback ProductIds with the receipt's validatedPurchasedProductIdentifiers.
    /// - Parameter fallbackPids:   Set of locally stored fallback ProductIds.
    /// - Returns:                  Returns true if both sets are the same, false otherwise.
    public func compareProductIds(fallbackPids: Set<ProductId>) -> Bool { fallbackPids == validatedPurchasedProductIdentifiers }
}
