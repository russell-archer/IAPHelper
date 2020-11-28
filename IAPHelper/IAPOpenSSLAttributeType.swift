//
//  OpenSSLAttributeType.swift
//  IAPHelper
//
//  Created by Russell Archer on 03/07/2020.
//
//  Swift wrapper for OpenSSL functions.
//

import Foundation

/// An attribute type used in the validation of app store receipts.
public enum IAPOpenSSLAttributeType: Int {

    case BundleIdentifier       = 2
    case BudleVersion           = 3
    case OpaqueValue            = 4
    case ComputedGuid           = 5
    case ReceiptCreationDate    = 12
    case IAPReceipt             = 17
    case OriginalAppVersion     = 19
    case ExpirationDate         = 21
}

