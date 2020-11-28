//
//  IAPReceipt+Read.swift
//  IAPHelper
//
//  Created by Russell Archer on 06/07/2020.
//
//  Swift wrapper for OpenSSL functions.
//  Contains modified portions of code created by Bill Morefield copyright (c) 2018 Razeware LLC.
//  

import Foundation

extension IAPReceipt {
    
    /// Read internal receipt data into a cache.
    /// - Returns: Returns true if all expected data was present and correctly read from the receipt, false otherwise.
    public func read() -> Bool {
        // Get a pointer to the start and end of the ASN.1 payload
        let receiptSign = receiptData?.pointee.d.sign
        let octets = receiptSign?.pointee.contents.pointee.d.data
        var pointer = UnsafePointer(octets?.pointee.data)
        let end = pointer!.advanced(by: Int(octets!.pointee.length))
        
        var type: Int32 = 0
        var xclass: Int32 = 0
        var length: Int = 0
        
        ASN1_get_object(&pointer, &length, &type, &xclass, pointer!.distance(to: end))
        guard type == V_ASN1_SET else {
            IAPLog.event(.receiptReadFailure)
            return false
        }
        
        while pointer! < end {
            ASN1_get_object(&pointer, &length, &type, &xclass, pointer!.distance(to: end))
            guard type == V_ASN1_SEQUENCE else {
                IAPLog.event(.receiptReadFailure)
                return false
            }
            
            guard let attributeType = IAPOpenSSL.asn1Int(p: &pointer, expectedLength: length) else {
                IAPLog.event(.receiptReadFailure)
                return false
            }
            
            guard let _ = IAPOpenSSL.asn1Int(p: &pointer, expectedLength: pointer!.distance(to: end)) else {
                IAPLog.event(.receiptReadFailure)
                return false
            }
            
            ASN1_get_object(&pointer, &length, &type, &xclass, pointer!.distance(to: end))
            guard type == V_ASN1_OCTET_STRING else {
                IAPLog.event(.receiptReadFailure)
                return false
            }
            
            var p = pointer
            switch IAPOpenSSLAttributeType(rawValue: attributeType) {
                    
                case .BudleVersion: bundleVersionString         = IAPOpenSSL.asn1String(    p: &p, expectedLength: length)
                case .ReceiptCreationDate: receiptCreationDate  = IAPOpenSSL.asn1Date(      p: &p, expectedLength: length)
                case .OriginalAppVersion: originalAppVersion    = IAPOpenSSL.asn1String(    p: &p, expectedLength: length)
                case .ExpirationDate: expirationDate            = IAPOpenSSL.asn1Date(      p: &p, expectedLength: length)
                case .OpaqueValue: opaqueData                   = IAPOpenSSL.asn1Data(      p: p!, expectedLength: length)
                case .ComputedGuid: hashData                    = IAPOpenSSL.asn1Data(      p: p!, expectedLength: length)
                    
                case .BundleIdentifier:
                    bundleIdString                              = IAPOpenSSL.asn1String(    p: &pointer, expectedLength: length)
                    bundleIdData                                = IAPOpenSSL.asn1Data(      p: pointer!, expectedLength: length)
                    
                case .IAPReceipt:
                    var iapStartPtr = pointer
                    let receiptProductInfo = IAPReceiptProductInfo(with: &iapStartPtr, payloadLength: length)
                    if let rpi = receiptProductInfo {
                        inAppReceipts.append(rpi)  // Cache in-app purchase record
                        if let pid = rpi.productIdentifier { validatedPurchasedProductIdentifiers.insert(pid) }
                    }
                    
                default: break  // Ignore other attributes in receipt
            }
            
            // Advance pointer to the next item
            pointer = pointer!.advanced(by: length)
        }
        
        hasBeenRead = true
        IAPLog.event(.receiptReadSuccess)
        
        return true
    }
}
