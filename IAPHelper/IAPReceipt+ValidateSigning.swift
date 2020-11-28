//
//  IAPReceipt+ValidateSigning.swift
//  IAPHelper
//
//  Created by Russell Archer on 06/07/2020.
//
//  Swift wrapper for OpenSSL functions.
//  Contains modified portions of code created by Bill Morefield copyright (c) 2018 Razeware LLC.
//  

import Foundation

extension IAPReceipt {
    
    /// Check the receipt has been correctly signed with a valid Apple X509 certificate.
    /// - Returns: Returns true if correctly signed, false otherwise.
    public func validateSigning() -> Bool {
        // Do we have cached PKCS7 data
        guard receiptData != nil else {
            IAPLog.event(.receiptValidateSigningFailure)
            return false
        }
        
        guard let rootCertUrl = Bundle.main.url(forResource: IAPConstants.Certificate(), withExtension: IAPConstants.CertificateExt()),
              let rootCertData = try? Data(contentsOf: rootCertUrl) else {
            
            IAPLog.event(.receiptValidateSigningFailure)
            return false
        }
        
        let rootCertBio = BIO_new(BIO_s_mem())
        let rootCertBytes: [UInt8] = .init(rootCertData)
        BIO_write(rootCertBio, rootCertBytes, Int32(rootCertData.count))
        let rootCertX509 = d2i_X509_bio(rootCertBio, nil)
        BIO_free(rootCertBio)
        
        let store = X509_STORE_new()
        X509_STORE_add_cert(store, rootCertX509)
        
        OPENSSL_init_crypto(UInt64(OPENSSL_INIT_ADD_ALL_DIGESTS), nil)
        
        // If PKCS7_NOCHAIN is set the signer's certificates are not chain verified.
        // This is required when using the local testing StoreKitTestCertificate.cer certificate.
        // See https://developer.apple.com/videos/play/wwdc2020/10659/ at the 16:30 mark.
        #if DEBUG
        let verificationResult = PKCS7_verify(receiptData, nil, store, nil, nil, PKCS7_NOCHAIN)
        #else
        let verificationResult = PKCS7_verify(receiptData, nil, store, nil, nil, nil)
        #endif
        
        guard verificationResult == 1  else {
            IAPLog.event(.receiptValidateSigningFailure)
            return false
        }
        
        isValidSignature = true
        IAPLog.event(.receiptValidateSigningSuccess)
        return true
    }
}
