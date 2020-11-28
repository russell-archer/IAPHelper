//
//  IAPHelper+SKPaymentTransactionObserver.swift
//  IAPHelper
//
//  Created by Russell Archer on 06/07/2020.
//

import UIKit
import StoreKit

extension IAPHelper: SKPaymentTransactionObserver {
    
    /// This delegate allows us to receive notifications from the App Store when payments are successful, fail, are restored, etc.
    /// - Parameters:
    ///   - queue:          The payment queue object.
    ///   - transactions:   Transaction information.
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch (transaction.transactionState) {
            case .purchasing:   purchaseInProgress(transaction: transaction)
            case .purchased:    purchaseCompleted(transaction: transaction)
            case .failed:       purchaseFailed(transaction: transaction)
            case .restored:     purchaseCompleted(transaction: transaction, restore: true)
            case .deferred:     purchaseDeferred(transaction: transaction)
            default:            return
            }
        }
    }
    
    private func purchaseCompleted(transaction: SKPaymentTransaction, restore: Bool = false) {
        // The purchase (or restore) was successful. Allow the user access to the product

        defer {
            // The use of the defer block guarantees that no matter when or how the method exits,
            // the code inside the defer block will be executed when the method goes out of scope.
            // It's important we remove the completed transaction from the queue. If this isn't done
            // then when the app restarts the payment queue will attempt to process the same transaction
            SKPaymentQueue.default().finishTransaction(transaction)
        }
        
        isPurchasing = false
        guard let identifier = restore ?
            transaction.original?.payment.productIdentifier :
            transaction.payment.productIdentifier else {
            
            let upid = "Unknown ProductID"
            // The app store says the purchase successfully completed. However, we can't access
            // the product id of the product that was purchased. We'll signal that the purchase/restore
            // was successful and try and resolve the issue next time the receipt is refreshed
            IAPLog.event(restore ? .purchaseRestoreSuccess(productId: upid) : .purchaseSuccess(productId: upid))

            if restore { DispatchQueue.main.async { self.restorePurchasesCompletion?(.purchaseRestoreSuccess(productId: upid)) }}
            else { DispatchQueue.main.async { self.purchaseCompletion?(.purchaseSuccess(productId: upid)) }}
            
            return
        }

        // Persist the purchased product ID
        IAPPersistence.savePurchasedState(for: transaction.payment.productIdentifier)

        // Add the purchased product ID to our fallback list of purchased product IDs
        guard !purchasedProductIdentifiers.contains(transaction.payment.productIdentifier) else { return }
        purchasedProductIdentifiers.insert(transaction.payment.productIdentifier)

        // Tell the request originator about the purchase
        IAPLog.event(restore ? .purchaseRestoreSuccess(productId: identifier) : .purchaseSuccess(productId: identifier))
        if restore { DispatchQueue.main.async { self.restorePurchasesCompletion?(.purchaseRestoreSuccess(productId: identifier)) }}
        else { DispatchQueue.main.async { self.purchaseCompletion?(.purchaseSuccess(productId: identifier)) }}

        // Note that we do not present a confirmation alert to the user as StoreKit will have already done this
    }

    private func purchaseFailed(transaction: SKPaymentTransaction) {
        // The purchase failed. Don't allow the user access to the product

        defer {
            // The use of the defer block guarantees that no matter when or how the method exits,
            // the code inside the defer block will be executed when the method goes out of scope
            // Always call SKPaymentQueue.default().finishTransaction() for a failure
            SKPaymentQueue.default().finishTransaction(transaction)
        }

        isPurchasing = false
        let identifier = transaction.payment.productIdentifier

        if let e = transaction.error as NSError? {

            if e.code == SKError.paymentCancelled.rawValue {
                IAPLog.event(.purchaseCancelled(productId: identifier))
                DispatchQueue.main.async { self.purchaseCompletion?(.purchaseCancelled(productId: identifier)) }

            } else {

                IAPLog.event(.purchaseFailure(productId: identifier))
                DispatchQueue.main.async { self.purchaseCompletion?(.purchaseFailure(productId: identifier)) }
            }

        } else {

            IAPLog.event(.purchaseCancelled(productId: identifier))
            DispatchQueue.main.async { self.purchaseCompletion?(.purchaseCancelled(productId: identifier)) }
        }
    }

    private func purchaseDeferred(transaction: SKPaymentTransaction) {
        // The purchase is in the deferred state. This happens when a device has parental restrictions enabled such
        // that in-app purchases require authorization from a parent. Do not allow access to the product at this point
        // Apple recommeds that there be no spinners or blocking while in this state as it could be hours or days
        // before the purchase is approved or declined.

        isPurchasing = false
        IAPLog.event(.purchaseDeferred(productId: transaction.payment.productIdentifier))
        DispatchQueue.main.async { self.purchaseCompletion?(.purchaseDeferred(productId: transaction.payment.productIdentifier)) }

        // Do NOT call SKPaymentQueue.default().finishTransaction() for .deferred status
    }

    private func purchaseInProgress(transaction: SKPaymentTransaction) {
        // The product purchase transaction has started. Do not allow access to the product yet
        IAPLog.event(.purchaseInProgress(productId: transaction.payment.productIdentifier))
        DispatchQueue.main.async { self.purchaseCompletion?(.purchaseInProgress(productId: transaction.payment.productIdentifier)) }
        
        // Do NOT call SKPaymentQueue.default().finishTransaction() for .purchasing status
    }
    
    /// Tells the observer that the storefront for the payment queue has changed.
    /// For example, from the US store to the UK store. In practice this won't happen very much, but when it
    /// does we need to request refreshed product data from the app store so we have localized product descritions
    /// and prices.
    /// - Parameter queue: Payment queue.
    @available(iOS 13.0, *)
    public func paymentQueueDidChangeStorefront(_ queue: SKPaymentQueue) {
        IAPLog.event(.appStoreChanged)
        DispatchQueue.main.async { self.notificationCompletion?(.appStoreChanged) }
    }
    
    /// Sent when entitlements for a user have changed and access to the specified IAPs has been revoked.
    /// - Parameters:
    ///   - queue:              Payment queue.
    ///   - productIdentifiers: ProductId which should have user access revoked.
    @available(iOS 14.0, *)
    public func paymentQueue(_ queue: SKPaymentQueue, didRevokeEntitlementsForProductIdentifiers productIdentifiers: [String]) {
        productIdentifiers.forEach { productId in
            IAPLog.event(.appStoreRevokedEntitlements(productId: productId))
            DispatchQueue.main.async { self.notificationCompletion?(.appStoreRevokedEntitlements(productId: productId)) }
        }
    }
    
    /// Tells the observer that a user initiated an in-app purchase from the App Store, rather than via the app itself.
    ///
    ///  See: https://developer.apple.com/library/content/documentation/NetworkingInternet/Conceptual/StoreKitGuide/PromotingIn-AppPurchases/PromotingIn-AppPurchases.html#//apple_ref/doc/uid/TP40008267-CH11-SW1
    ///
    /// When a user taps or clicks Buy on an in-app purchase on the App Store, StoreKit automatically opens your app and
    /// sends the transaction information to your app through the delegate method paymentQueue(_:shouldAddStorePayment:for).
    /// Your app must complete the purchase transaction and any related actions that are specific to your app.
    ///
    /// If your app is not installed when the user taps or clicks Buy, the App Store automatically downloads the app or
    /// prompts the user to buy it. The user gets a notification when the app installation is complete. This method is
    /// called when the user taps the notification.
    ///
    /// Otherwise, if the user opens the app manually, this method is called only if the app is opened soon after the
    /// purchase was started.
    ///
    /// You should make sure not to show popups or any other UI that will get in the way of the user purchasing the in-app
    /// purchase.
    ///
    /// Return true to continue the transaction, false to defer or cancel the transaction.
    ///
    /// * You should cancel (and provide feedback to the user) if the user has already purchased the product
    /// * You may wish to defer the purchase if the user is in the middle of something else critcial in your app.
    ///
    /// If you defer, you can re-start the transaction later by:
    ///
    /// * saving the payment passed to paymentQueue(_:shouldAddStorePayment:for)
    /// * returning false from paymentQueue(_:shouldAddStorePayment:for)
    /// * calling SKPaymentQueue.default().add(savedPayment) later to re-start the purchase
    ///
    /// Testing
    /// -------
    /// To test your promoted in-app purchases before your app is available in the App Store, Apple provides a system
    /// URL that triggers your app using the itms-services:// protocol.
    ///
    ///     * Protocol: itms-services://
    ///     * Parameter action: purchaseIntent
    ///     * Parameter bundleId: bundle Id for your app (e.g. com.rarcher.writerly)
    ///     * Parameter productIdentifier: the in-app purchase product name you want to test
    ///
    /// The URL looks like this:
    ///
    /// itms-services://?action=purchaseIntent&bundleId=com.company.appname&productIdentifier=product_name
    ///
    /// Examples for testing Writerly:
    ///
    /// itms-services://?action=purchaseIntent&bundleId=com.rarcher.writerly&productIdentifier=com.rarcher.writerly.waysintocharacter
    /// itms-services://?action=purchaseIntent&bundleId=com.rarcher.writerly&productIdentifier=com.rarcher.writerly.ayearofprompts
    ///
    /// Send this URL to yourself in an email or iMessage and open it from your device. You will know the test is
    /// running when your app opens automatically. You can then test your promoted in-app purchase.
    /// - Parameters:
    ///   - queue:      Payment queue object.
    ///   - payment:    Payment info.
    ///   - product:    The product purchased.
    /// - Returns:      Return true to continue the transaction (will result in normal processing via paymentQueue(_:updatedTransactions:).
    ///                 Return false to indicate that the store not to proceed with purchase (i.e. it's already been purchased).
    @available(iOS 11.0, *)
    public func paymentQueue(_ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment, for product: SKProduct) -> Bool {        
        return !isProductPurchased(id: product.productIdentifier)
    }
}
