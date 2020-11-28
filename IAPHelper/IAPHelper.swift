//
//  IAPHelper.swift
//  IAPHelper
//
//  Originally created by Russell Archer on 16/10/2016.
//  Copyright © 2016 Russell Archer. All rights reserved.
//

import UIKit
import StoreKit

public typealias ProductId = String

/// IAPHelper coordinates in-app purchases. Make sure to initiate IAPHelper early in the app's lifecycle so that
/// notifications from the App Store are not missed. For example, reference `IAPHelper.shared` in
/// `application(_:didFinishLaunchingWithOptions:)` in AppDelegate.
public class IAPHelper: NSObject  {

    // MARK:- Public Properties

    /// Singleton access. Use IAPHelper.shared to access all IAPHelper properties and methods.
    public static let shared: IAPHelper = IAPHelper()

    /// True if a purchase is in progress (excluding a deferred).
    public var isPurchasing = false

    /// List of products retrieved from the App Store and available for purchase.
    public var products: [SKProduct]?

    /// List of ProductIds that are read from the .storekit configuration file.
    public var configuredProductIdentifiers: Set<ProductId>?

    /// True if we have a list of ProductIds read from the .storekit configuration file. See configuredProductIdentifiers.
    public var haveConfiguredProductIdentifiers: Bool {
        guard configuredProductIdentifiers != nil else { return false }
        return configuredProductIdentifiers!.count > 0 ? true : false
    }

    /// This property is set automatically when IAPHelper is initialized and contains the set of
    /// all products purchased by the user. The collection is not persisted but is rebuilt from the
    /// product identifiers of purchased products stored individually in user defaults (see IAPPersistence).
    /// This is a 'fallback' collection of purchases designed to allow the user access to purchases
    /// in the event that the app receipt is missing and we can't contact the App Store to refresh it.
    /// This set will be empty if the user hasn't yet purchased any iap products.
    public var purchasedProductIdentifiers = Set<ProductId>()

    /// True if app store product info has been retrieved via requestProducts().
    public var isAppStoreProductInfoAvailable: Bool {
        guard products != nil else { return false }
        guard products!.count > 0 else { return false }
        return true
    }

    // MARK:- Internal Properties

    internal var receipt: IAPReceipt!  // Encapsulates the app store receipt located in the main bundle
    internal var productsRequest: SKProductsRequest?  // Used to request product info async from the App Store
    internal var receiptRequest: SKRequest?  // Used to request a receipt refresh async from the App Store

    internal var requestProductsCompletion:     ((IAPNotification) -> Void)? = nil  // Completion handler when requesting products from the app store
    internal var requestReceiptCompletion:      ((IAPNotification) -> Void)? = nil  // Completion handler when requesting a receipt refresh from the App Store
    internal var purchaseCompletion:            ((IAPNotification?) -> Void)? = nil // Completion handler when purchasing a product from the App Store
    internal var restorePurchasesCompletion:    ((IAPNotification?) -> Void)? = nil // Completion handler when requesting the app store to restore purchases
    internal var notificationCompletion:        ((IAPNotification?) -> Void)? = nil // Completion handler for general notifications

    // MARK:- Initialization of IAPHelper

    // Private initializer prevents more than a single instance of this class being created.
    // See the public static 'shared' property.
    private override init() {
        super.init()

        // Add ourselves as an observer of the StoreKit payments queue. This allows us to receive
        // notifications when payments are successful, fail, are restored, etc.
        // See the SKPaymentQueue notification handler paymentQueue(_:updatedTransactions:)
        // Add ourselves to the payment queue so we get App Store notifications
        SKPaymentQueue.default().add(self)

        setup()
    }

    // MARK:- Configuration

    /// Call this method to remove IAPHelper as an observer of the StoreKit payment queue.
    /// This should be done from the AppDelgate applicationWillTerminate(_:) method.
    public func removeFromPaymentQueue() {
        SKPaymentQueue.default().remove(self)
    }

    internal func setup() {
        readConfigFile()
        loadPurchasedProductIds()
    }

    internal func readConfigFile() {
        // Read our configuration file that contains the list of ProductIds that are available on the App Store.
        configuredProductIdentifiers = nil
        var success = false
        if IAPConstants.isRelease { success = readPropertyListFile() } else { success = readStoreKitFile() }
        
        let notification = success ? IAPNotification.configurationSuccess : IAPNotification.configurationFailure
        IAPLog.event(notification)
        notificationCompletion?(notification)
    }
    
    internal func readStoreKitFile() -> Bool {
        let result = IAPConfiguration.readStoreKitFile(filename: IAPConstants.ConfigFile(), ext: IAPConstants.ConfigFileExt())
        switch result {
        case .failure(_):
            IAPLog.event(.configurationEmpty)
            return false
            
        case .success(let configuration):
            guard let configuredProducts = configuration.products, configuredProducts.count > 0 else {
                IAPLog.event(.configurationEmpty)
                return false
            }
            
            configuredProductIdentifiers = Set<ProductId>(configuredProducts.compactMap { product in product.productID })
            return true
        }
    }
    
    internal func readPropertyListFile() -> Bool {
        guard let result = IAPConfiguration.readPropertyFile(filename: IAPConstants.ConfigFile()) else {
            return false
        }
        
        guard result.count > 0 else {
            IAPLog.event(.configurationEmpty)
            return false
        }
        
        guard let values = result["Products"] as? [String] else {
            IAPLog.event(.configurationEmpty)
            return false
        }
        
        configuredProductIdentifiers = Set<ProductId>(values.compactMap { $0 })
        return true
    }

    internal func loadPurchasedProductIds() {
        // Load our set of purchased ProductIds from UserDefaults
        guard haveConfiguredProductIdentifiers else {
            IAPLog.event(.purchasedProductsLoadFailure)
            notificationCompletion?(.purchasedProductsLoadFailure)
            return
        }

        purchasedProductIdentifiers = IAPPersistence.loadPurchasedProductIds(for: configuredProductIdentifiers!)
        IAPLog.event(.purchasedProductsLoadSuccess)
        notificationCompletion?(.purchasedProductsLoadSuccess)
    }

    // MARK:- Public Helpers

    /// Validates the receipt issued by the app store and reads in-app purchase records.
    /// When an app is first installed the receipt will be missing. A new receipt will be issued automatically by the
    /// App Store when an in-app purchase succeeds, the app is updated or previous in-app purchases are restored.
    /// This method should be called:
    ///     - on app start-up
    ///     - when a purchase succeeds (the new receipt is available when paymentQueue(_:updatedTransactions:) is called by StoreKit)
    ///     - when purchases are restored
    public func processReceipt() {
        IAPLog.event(.receiptValidationStarted)
        
        receipt = IAPReceipt()

        // If any of the following fail then this should be considered a non-fatal error.
        // A new receipt can be requested from the App Store if required (see refreshReceipt(completion:)).
        // However, we don't do this automatically because it will cause the user to be prompted
        // for their App Store credentials.
        guard receipt.isReachable,
              receipt.load(),
              receipt.validateSigning(),
              receipt.read(),
              receipt.validate() else {

            IAPLog.event(.receiptProcessingFailure)
            return
        }

        // Compare the "fallback" set of purchased product ids that are stored in UserDefaults with the validated
        // set of purchased product ids read from the app store receipt. If they differ, we reset the fallback
        // set to match the receipt and persist the new set to UserDefaults.
        createValidatedPurchasedProductIds(receipt: receipt)
        IAPLog.event(.receiptProcessingSuccess)
    }

    /// Register a completion block to receive general notifications for app store operations.
    /// - Parameter completion:     Completion block to receive asynchronous notifications for app store operations.
    /// - Parameter notification:   IAPNotification providing details on the event.
    public func receiveNotifications(completion: @escaping (_ notification: IAPNotification?) -> Void) {
        notificationCompletion = completion
    }

    /// Returns an SKProduct given a ProductId. Product info is only available if isStoreProductInfoAvailable is true.
    /// - Parameter id: The ProductId for the product.
    /// - Returns:      Returns an SKProduct object containing localized information about the product.
    public func getStoreProductFrom(id: ProductId) -> SKProduct? {
        guard isAppStoreProductInfoAvailable else {
            IAPLog.event(.appStoreNoProductInfo)
            return nil
        }

        let selectedProducts = products!.filter { product in product.productIdentifier == id }
        guard selectedProducts.count > 0 else {
            IAPLog.event(.purchaseProductUnavailable(productId: id))
            return nil
        }

        return selectedProducts.first
    }

    /// Returns a product's title given a ProductId. Only available if isStoreProductInfoAvailable is true.
    /// - Parameter id: The ProductId for the product.
    /// - Returns:      Returns a product's title.
    public func getProductTitleFrom(id: ProductId) -> String? {
        guard let p = getStoreProductFrom(id: id) else { return nil }
        return p.localizedTitle
    }

    /// Returns true if the product identified by the ProductId has been purchased.
    /// There are two strategies we use to determine if a product has been successfully purchased:
    ///
    ///   1. We validate the App Store-issued Receipt, which is stored in our main bundle. This receipt
    ///      is updated and reissued as necessary (for example, when there's a purchase) by the App Store.
    ///      The data in the receipt gives a list of purchased products.
    ///
    ///   2. We keep a 'fallback' list of ProductIDs for purchased products. This list is persisted to
    ///      UserDefaults. We use this list in case we can't use method 1. above. This can happen when
    ///      the receipt is missing, or hasn't yet been issued (i.e. the user hasn't purchased anything).
    ///      The fallback list is also useful when we can't validate the receipt and can't request a
    ///      new receipt from the App Store becuase of network connectivity issues, etc.
    ///
    /// When we validate the receipt we compare the fallback list of purchases with the more reliable
    /// data from the receipt. If they disagree we re-write the list using info from the receipt.
    /// - Parameter id: The ProductId for the product.
    /// - Returns:      Returns true if the product has previously been purchased, false otherwise.
    public func isProductPurchased(id: ProductId) -> Bool { purchasedProductIdentifiers.contains(id) }

    /// Get a localized price for a product.
    /// - Parameter product: SKProduct for which you want the local price.
    /// - Returns:           Returns a localized price String for a product.
    public class func getLocalizedPriceFor(product: SKProduct) -> String? {
        let priceFormatter = NumberFormatter()
        priceFormatter.formatterBehavior = .behavior10_4
        priceFormatter.numberStyle = .currency
        priceFormatter.locale = product.priceLocale
        return priceFormatter.string(from: product.price)
    }

    // MARK:- Internal Helpers

    internal func createValidatedPurchasedProductIds(receipt: IAPReceipt) {
        if purchasedProductIdentifiers == receipt.validatedPurchasedProductIdentifiers {
            IAPLog.event(.purchasedProductsValidatedAgainstReceipt)
            return
        }

        IAPPersistence.resetPurchasedProductIds(from: purchasedProductIdentifiers, to: receipt.validatedPurchasedProductIdentifiers)
        purchasedProductIdentifiers = receipt.validatedPurchasedProductIdentifiers
        IAPLog.event(.purchasedProductsValidatedAgainstReceipt)
    }
}
