//
//  IAPConfiguration.swift
//  IAPHelper
//
//  Created by Russell Archer on 24/06/2020.
//

import UIKit

public enum IAPProductConfigurationType { case free, paid, all }

public protocol IAPProductConfiguration: class {
    func readProductConfiguration(type: IAPProductConfigurationType) -> Set<ProductId>?
}

/// Default implementation for reading .storekit and plist configuration files. Note that protocol extensions
/// can't be instantiated. Use IAPProductConfigurationDefault for default behaviour.
public extension IAPProductConfiguration {
    
    /// Read the appropriate configuration (.storekit or .plist file) and return a Set of ProductId
    func readProductConfiguration(type: IAPProductConfigurationType = .all) -> Set<ProductId>? {
        guard type == .all else {
            // The default implementation only supports find all products and doesn't
            // distinguish between "free" and "paid" products
            IAPLog.event(.configurationFailure)
            //notificationCompletion?(.configurationFailure)
            return nil
        }
        
        // Read our configuration file that contains the list of ProductIds that are available on the App Store.
        var allProductIds: Set<ProductId>?
        if IAPConstants.isRelease { allProductIds = readPropertyListFile() } else { allProductIds = readStoreKitFile() }
        
        let notification = allProductIds != nil ? IAPNotification.configurationSuccess : IAPNotification.configurationFailure
        IAPLog.event(notification)
        //notificationCompletion?(notification)
        return allProductIds
    }
    
    /// Read the .storekit file, extract the configuration data and return a Set of ProductId
    private func readStoreKitFile() -> Set<ProductId>? {
        let result = readFile(filename: IAPConstants.ConfigFile(), ext: IAPConstants.ConfigFileExt())
        switch result {
        case .failure(_):
            IAPLog.event(.configurationEmpty)
            return nil
            
        case .success(let configuration):
            guard let configuredProducts = configuration.products, configuredProducts.count > 0 else {
                IAPLog.event(.configurationEmpty)
                return nil
            }
            
            return Set<ProductId>(configuredProducts.compactMap { product in product.productID })
        }
    }
    
    /// Read a plist property file and return the dictionary of values as a Set of ProductId
    private func readPropertyListFile() -> Set<ProductId>? {
        guard let result = readFile(filename: IAPConstants.ConfigFile()) else {
            return nil
        }
        
        guard result.count > 0 else {
            IAPLog.event(.configurationEmpty)
            return nil
        }
        
        guard let values = result["Products"] as? [String] else {
            IAPLog.event(.configurationEmpty)
            return nil
        }
        
        return Set<ProductId>(values.compactMap { $0 })
    }
    
    private func readFile(filename: String, ext: String) -> Result<IAPConfigurationModel, IAPNotification> {
        
        guard let url = Bundle.main.url(forResource: filename, withExtension: ext) else { return .failure(.configurationCantFindInBundle) }
        guard let data = try? Data(contentsOf: url) else { return .failure(.configurationCantReadData) }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        
        guard let configuration = try? decoder.decode(IAPConfigurationModel.self, from: data) else { return .failure(.configurationCantDecode) }
        
        return .success(configuration)
    }
    
    private func readFile(filename: String) -> [String : AnyObject]? {
        if let path = Bundle.main.path(forResource: filename, ofType: "plist") {
            if let contents = NSDictionary(contentsOfFile: path) as? [String : AnyObject] {
                return contents
            }
        }

        return nil  // [:]
    }
}

/// Provides default behaviour for reading .storekit and plist configuration files.
public class IAPProductConfigurationDefault: IAPProductConfiguration { }
