//
//  ProductInfo.swift
//  IAPHelper
//
//  Created by Russell Archer on 09/07/2020.
//

import UIKit

/// Holds localized product data returned by teh App Store
public struct IAPProductInfo {
    public init(
        id: String,
        imageName: String,
        localizedTitle: String,
        localizedDescription: String,
        localizedPrice: String,
        purchased: Bool) {
        
        self.id = id
        self.imageName = imageName
        self.localizedTitle = localizedTitle
        self.localizedDescription = localizedDescription
        self.localizedPrice = localizedPrice
        self.purchased = purchased
    }
    
    public var id: String
    public var imageName: String
    public var localizedTitle: String
    public var localizedDescription: String
    public var localizedPrice: String
    public var purchased: Bool
}
