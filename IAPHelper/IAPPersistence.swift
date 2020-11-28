//
//  IAPPersistence.swift
//  IAPHelper
//
//  Created by Russell Archer on 25/06/2020.
//

import Foundation

/// Contains static methods to load and save 'fallback' purchase information.
/// If a product is purchased a Bool is created in UserDefaults. Its key will be the ProductId.
/// The 'true' set of purchased ProductIds should be obtained from the App Store receipt.
public struct IAPPersistence: IAPPersistenceProtocol {
    
    /// Save the purchased state for a ProductId. A Bool is created in UserDefaults where the key is the ProductId.
    /// - Parameters:
    ///   - productId: ProductId for an in-app purchase that this app supports.
    ///   - purchased: True if the product has been purchased, false otherwise.
    public static func savePurchasedState(for productId: ProductId, purchased: Bool = true) {
        UserDefaults.standard.set(purchased, forKey: productId)
    }
    
    /// Save the purchased state for a set of ProductIds. For each ProductId a Bool is created in
    /// UserDefaults where the key is the ProductId.
    /// - Parameters:
    ///   - productIds: Set of ProductIds for all in-app purchases that this app supports.
    ///   - purchased:  True if the products have been purchased, false otherwise.
    public static func savePurchasedState(for productIds: Set<ProductId>, purchased: Bool = true) {
        productIds.forEach { productId in UserDefaults.standard.set(purchased, forKey: productId) }
    }
    
    /// Returns a Bool indicating if the ProductId has been purchased.
    /// - Parameter productId:  ProductId for an in-app purchase that this app supports.
    /// - Returns:              A Bool indicating if the ProductId has been purchased.
    public static func loadPurchasedState(for productId: ProductId) -> Bool {
        return UserDefaults.standard.bool(forKey: productId)
    }
    
    /// Returns the set of ProductIds that have been persisted to UserDefaults. The set will be nil
    /// if no products have been purchased previously. This 'fallback' set of ProductIds will be compared
    /// to the list of purchased products held in the App Store receipt and updated if necessary.
    /// - Parameter productIds: Set of all possible ProductIds that this app supports.
    /// - Returns:              Returns the set of ProductIds that have been persisted to UserDefaults.
    ///                         This will be an empty set if nothing has been purchased.
    public static func loadPurchasedProductIds(for productIds: Set<ProductId>) -> Set<ProductId> {
        var purchasedProductIds = Set<ProductId>()
        productIds.forEach { productId in
            let purchased = UserDefaults.standard.bool(forKey: productId)
            if purchased {
                purchasedProductIds.insert(productId)
                IAPLog.event("Loaded purchased product: \(productId)")
            }
        }
        
        return purchasedProductIds
    }
    
    /// Removes the UserDefaults objects for the set of ProductIds. Then re-creates UserDefaults objects using
    /// the provided set of ProductIds.
    /// - Parameters:
    ///   - oldProductIds:  ProductIds to remove from UserDefaults.
    ///   - productIds:     ProductIds to re-initialize UserDefaults with.
    ///   - purchased:      Whether the products are to be marked as purchased or not.
    public static func resetPurchasedProductIds(from oldProductIds: Set<ProductId>, to productIds: Set<ProductId>, purchased: Bool = true) {
        oldProductIds.forEach { pid in UserDefaults.standard.removeObject(forKey: pid) }
        savePurchasedState(for: productIds, purchased: purchased)
    }
}
