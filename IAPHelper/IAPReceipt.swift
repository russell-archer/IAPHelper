//
//  IAPReceipt.swift
//  IAPHelper
//
//  Created by Russell Archer on 25/06/2020.
//
//  Swift wrapper for OpenSSL functions.
//  Contains modified portions of code created by Bill Morefield copyright (c) 2018 Razeware LLC.
//

import UIKit

/// IAPReceipt encapsulates an Apple App Store-issued receipt. App Store receipts are a complete
/// record of a user's in-app purchase history. The receipt will contain a list of any in-app
/// purchases the user has made. This list can be used to validate a locally stored fall-back
/// list of purchased products. The fall-back list should be used when a connection to the App
/// Store is not possible (i.e. no network connectivity).
///
/// Note that:
///
/// * The receipt is a single encrypted file stored locally on the device and is accessible
///   through the main bundle (Bundle.main.appStoreReceiptURL)
/// * When the app is newly installed the receipt will be missing
/// * We use OpenSSL to access data in the receipt
/// * A new receipt is issued automatically by the App Store when:
///
///     * an in-app purchase succeeds
///     * previous in-app purchases are restored
///     * an app update happens
///
public class IAPReceipt {
        
    // MARK:- Public properties
    
    /// The set of purchased ProductIds validated against the app's App Store receipt.
    /// The set of purchasedProductIdentifiers held by IAPHelper should always be the
    /// same as validatedPurchasedProductIdentifiers. If they differ, purchasedProductIdentifiers
    /// should be updated to be a copy of validatedPurchasedProductIdentifiers and persisted.
    public var validatedPurchasedProductIdentifiers = Set<ProductId>()
    
    /// Check to see if the receipt's URL is present and the receipt file itself is reachable.
    /// True if the receipt is available in the main bundle, false otherwise.
    public var isReachable: Bool {
        guard let receiptUrl = Bundle.main.appStoreReceiptURL else {
            IAPLog.event(.receiptBadUrl)
            return false
        }
        
        IAPLog.event("Receipt reachable at \(receiptUrl)")
        
        guard let _ = try? receiptUrl.checkResourceIsReachable() else {
            IAPLog.event(.receiptMissing)
            return false
        }
        
        return true
    }
    
    /// True if the receipt has been loaded and its data cached.
    public var isLoaded: Bool { receiptData == nil ? false : true }
    
    /// True if valid. If false then the host app should call refreshReceipt(completion:).
    public var isValid = false
    
    /// True if the receipt has been signed with a valid Apple X509 certificate.
    public var isValidSignature = false
    
    /// True if the receipt has been read and its metadata cached.
    public var hasBeenRead = false
    
    // MARK:- Private properties

    internal var inAppReceipts: [IAPReceiptProductInfo] = []  // Array of purchased product info stored in the receipt
    internal var receiptData: UnsafeMutablePointer<PKCS7>?    // Pointer to the receipt's cached PKCS7 data
    
    // Data read from the receipt:
    internal var bundleIdString: String?
    internal var bundleVersionString: String?
    internal var bundleIdData: Data?
    internal var hashData: Data?
    internal var opaqueData: Data?
    internal var expirationDate: Date?
    internal var receiptCreationDate: Date?
    internal var originalAppVersion: String?
    
    // MARK:- Internal methods
    
    internal func getDeviceIdentifier() -> Data {
        let device = UIDevice.current
        var uuid = device.identifierForVendor!.uuid
        let addr = withUnsafePointer(to: &uuid) { (p) -> UnsafeRawPointer in
            UnsafeRawPointer(p)
        }
        let data = Data(bytes: addr, count: 16)
        return data
    }
    
    internal func computeHash() -> Data {
        let identifierData = getDeviceIdentifier()
        var ctx = SHA_CTX()
        SHA1_Init(&ctx)
        
        let identifierBytes: [UInt8] = .init(identifierData)
        SHA1_Update(&ctx, identifierBytes, identifierData.count)
        
        let opaqueBytes: [UInt8] = .init(opaqueData!)
        SHA1_Update(&ctx, opaqueBytes, opaqueData!.count)
        
        let bundleBytes: [UInt8] = .init(bundleIdData!)
        SHA1_Update(&ctx, bundleBytes, bundleIdData!.count)
        
        var hash: [UInt8] = .init(repeating: 0, count: 20)
        SHA1_Final(&hash, &ctx)
        return Data(bytes: hash, count: 20)
    }
}



