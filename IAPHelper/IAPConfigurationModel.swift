//
//  IAPConfigurationModel.swift
//  IAPHelper
//
//  Created by Russell Archer on 25/06/2020.
//

import Foundation

/// Model for the the .storekit configuration file. This model is used to decode the JSON data in the configuration file.
/// See also IAPConfiguration.
public struct IAPConfigurationModel: Decodable {
    let products: [IAPConfigurationModelProducts]?
    let settings: IAPConfigurationModelSettings?
    let subscriptionGroups: [String]?  // TODO: Placeholder. They're not Strings
    let version: IAPConfigurationModelVersion?
}

public struct IAPConfigurationModelProducts: Decodable {
    let displayPrice: String?
    let familyShareable: Bool?
    let internalID: String?
    let localizations: [IAPConfigurationModelLocalizations]?
    let productID: String?
    let referenceName: String?
    let type: String?
}

public struct IAPConfigurationModelLocalizations: Decodable {
    let description: String?
    let displayName: String?
    let locale: String?
}

public struct IAPConfigurationModelSettings: Decodable {
    let _askToBuyEnabled: Bool?
}

public struct IAPConfigurationModelVersion: Decodable {
    let major: Int?
    let minor: Int?
}


