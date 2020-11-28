//
//  IAPPersistenceProtocol.swift
//  IAPHelper
//
//  Created by Russell Archer on 25/06/2020.
//

import Foundation

/// Defines the interface for loading and saving fallback product purchase data.
protocol IAPPersistenceProtocol {
    static func savePurchasedState(for productId: ProductId, purchased: Bool)
    static func savePurchasedState(for productIds: Set<ProductId>, purchased: Bool)
    static func loadPurchasedState(for productId: ProductId) -> Bool
    static func loadPurchasedProductIds(for productIds: Set<ProductId>) -> Set<ProductId>
}

