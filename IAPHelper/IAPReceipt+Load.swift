//
//  IAPReceipt+Load.swift
//  IAPHelper
//
//  Created by Russell Archer on 06/07/2020.
//
//  Swift wrapper for OpenSSL functions.
//  

import Foundation

extension IAPReceipt {
    
    /// Load the receipt data from the main bundle and cache it. Basic validation of the receipt is done.
    /// We check its format, if it has a signature and if contains data. After loading the receipt you
    /// should call validateSigning() to check the receipt has been correctly signed, then read its IAP
    /// data using read(). You can then validate() the receipt.
    /// - Returns: Returns true if loaded correctly, false otherwise.
    public func load() -> Bool {
        
        // Get the URL of the receipt file
        guard let receiptUrl = Bundle.main.appStoreReceiptURL else {
            IAPLog.event(.receiptLoadFailure)
            return false
        }
        
        // Read the encrypted receipt container file as Data
        guard let data = try? Data(contentsOf: receiptUrl) else {
            IAPLog.event(.receiptLoadFailure)
            return false
        }
        
        // Using OpenSSL create a buffer to read the PKCS #7 container into
        let receiptBIO = BIO_new(BIO_s_mem())  // The buffer we will write into
        let receiptBytes: [UInt8] = .init(data)  // The encrytped data as an array of bytes
        BIO_write(receiptBIO, receiptBytes, Int32(data.count))  // Write the data to the receiptBIO buffer
        let receiptPKCS7 = d2i_PKCS7_bio(receiptBIO, nil) // Now convert the buffer into the required PKCS7 struct
        BIO_free(receiptBIO)  // Free the buffer

        // Check the PKCS7 container exists
        guard receiptPKCS7 != nil else {
            IAPLog.event(.receiptLoadFailure)
            return false
        }
        
        // Check the PKCS7 container has a signature
        guard pkcs7IsSigned(pkcs7: receiptPKCS7!) else {
            IAPLog.event(.receiptLoadFailure)
            return false
        }
        
        // Check the PKCS7 container is of the correct data type
        guard pkcs7IsData(pkcs7: receiptPKCS7!) else {
            IAPLog.event(.receiptLoadFailure)
            return false
        }
        
        receiptData = receiptPKCS7  // Cache the PKCS7 data
        IAPLog.event(.receiptLoadSuccess)

        return true
    }
    
    func pkcs7IsSigned(pkcs7: UnsafeMutablePointer<PKCS7>) -> Bool {
        // Convert the object in the PKCS7 struct to an Int32 and compare it to the OpenSSL NID constant
        OBJ_obj2nid(pkcs7.pointee.type) == NID_pkcs7_signed
    }
    
    func pkcs7IsData(pkcs7: UnsafeMutablePointer<PKCS7>) -> Bool {
        // Convert the object in the PKCS7 struct to an Int32 and compare it to the OpenSSL NID constant
        OBJ_obj2nid(pkcs7.pointee.d.sign.pointee.contents.pointee.type) == NID_pkcs7_data
    }
}
